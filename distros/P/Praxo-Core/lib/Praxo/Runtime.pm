package Praxo::Runtime;

use strict;
use warnings;
use Exporter 'import';
use Cwd qw(abs_path);
use File::Basename qw(basename dirname);
use File::Spec;
use Praxo::Json ();
use Praxo::Models ();
use Praxo::Errors qw(praxo_error);

our @EXPORT_OK = qw(
    MultiSink FilterSink MemoryStore CheckpointAllowlist PathChecker
    ContextBudget estimate_tokens truncate_to_tokens compact_context
);

package Praxo::Runtime::MultiSink;

sub new {
    my ($class, $sinks) = @_;
    return bless { sinks => $sinks // [] }, $class;
}

sub emit {
    my ($self, $event) = @_;
    $_->emit($event) for @{ $self->{sinks} };
}

package Praxo::Runtime::FilterSink;

sub new {
    my ($class, $sink, $predicate) = @_;
    return bless { sink => $sink, predicate => $predicate }, $class;
}

sub emit {
    my ($self, $event) = @_;
    $self->{sink}->emit($event) if $self->{predicate}->($event);
}

package Praxo::Runtime::MemoryStore;

sub new {
    my ($class) = @_;
    return bless { records => {}, sequence => 0 }, $class;
}

sub put {
    my ($self, $session_id, $record) = @_;
    if (!defined($record->{id}) || $record->{id} eq '') {
        $record->{id} = 'mem-' . int(time() * 1000) . '-' . $self->{sequence}++;
    }
    if (!defined $record->{createdAt}) {
        my @now = gmtime();
        $record->{createdAt} = sprintf(
            '%04d-%02d-%02dT%02d:%02d:%02dZ',
            $now[5] + 1900, $now[4] + 1, $now[3], $now[2], $now[1], $now[0],
        );
    }
    push @{ $self->{records}{$session_id} //= [] }, $record;
    return $record;
}

sub search {
    my ($self, $session_id, $query, $limit) = @_;
    my $needle = lc($query // '');
    $needle =~ s/^\s+|\s+$//g;
    my @matches = grep {
        $needle eq '' || index(lc($_->{content} // ''), $needle) >= 0
    } @{ $self->{records}{$session_id} // [] };
    @matches = sort {
        ($b->{createdAt} // '') cmp ($a->{createdAt} // '')
    } @matches;
    @matches = @matches[0 .. $limit - 1] if $limit > 0 && @matches > $limit;
    return @matches;
}

package Praxo::Runtime::CheckpointAllowlist;

sub new {
    my ($class) = @_;
    return bless { registered => {} }, $class;
}

sub register {
    my ($self, $type) = @_;
    Praxo::Errors::praxo_error('CHECKPOINT_ERROR', 'checkpoint: type is required')
        unless defined($type) && length($type);
    $self->{registered}{$type} = 1;
}

sub marshal {
    my ($self, $type, $value) = @_;
    Praxo::Errors::praxo_error('CHECKPOINT_TYPE_NOT_ALLOWED', "checkpoint: payload type not allowed: $type")
        unless $self->{registered}{$type};
    return Praxo::Json::stringify({ type => $type, data => $value });
}

sub unmarshal {
    my ($self, $data) = @_;
    my $envelope = Praxo::Json::parse($data);
    Praxo::Errors::praxo_error('CHECKPOINT_ERROR', 'checkpoint: envelope must be an object')
        unless ref($envelope) eq 'HASH';
    my $type = $envelope->{type} // '';
    Praxo::Errors::praxo_error('CHECKPOINT_TYPE_NOT_ALLOWED', "checkpoint: payload type not allowed: $type")
        unless $self->{registered}{$type};
    return $envelope->{data};
}

package Praxo::Runtime::PathChecker;

sub new {
    my ($class, $grants) = @_;
    my @normalized;
    for my $grant (@{ $grants // [] }) {
        push @normalized, {
            root => _resolve_path($grant->{root} // ''),
            access => $grant->{access} // 'read',
        };
    }
    return bless { grants => \@normalized }, $class;
}

sub check {
    my ($self, $target, $need) = @_;
    Praxo::Errors::praxo_error('POLICY_ERROR', 'policy: invalid access')
        unless $need eq 'read' || $need eq 'write' || $need eq 'readwrite';
    return { allowed => 0, reason => 'no allowed roots' } unless @{ $self->{grants} };
    my $resolved = _resolve_path($target);
    my $matched = undef;
    for my $grant (@{ $self->{grants} }) {
        next unless _within($grant->{root}, $resolved);
        $matched = $grant->{root};
        if (_allows($grant->{access}, $need)) {
            return { allowed => 1, reason => "path within $grant->{root}" };
        }
    }
    return {
        allowed => 0,
        reason => defined($matched) ? 'insufficient grant' : 'outside roots',
    };
}

sub allowed {
    my ($self, $target, $need) = @_;
    my $decision = eval { $self->check($target, $need) };
    return $decision ? $decision->{allowed} : 0;
}

sub _resolve_path {
    my ($value) = @_;
    return '' unless defined $value;
    my $absolute = File::Spec->rel2abs($value);
    my $real = Cwd::abs_path($absolute);
    return $real if defined $real;
    my ($volume, $directories, $file) = File::Spec->splitpath($absolute);
    my $parent = File::Spec->catpath($volume, $directories, '');
    $parent =~ s{[\\/]+$}{};
    return $absolute if $parent eq '';
    my $resolved_parent = _resolve_path($parent);
    return File::Spec->catfile($resolved_parent, $file);
}

sub _within {
    my ($root, $target) = @_;
    my $sep = File::Spec->catfile('', '');
    $root =~ s{[\\/]+$}{};
    $target =~ s{[\\/]+$}{};
    if ($^O eq 'MSWin32') {
        $root = lc $root;
        $target = lc $target;
    }
    return 1 if $target eq $root;
    return index($target, $root . $sep) == 0 ? 1 : 0;
}

sub _allows {
    my ($grant, $need) = @_;
    return 1 if $need eq 'read' && ($grant eq 'read' || $grant eq 'readwrite');
    return 1 if $need eq 'write' && ($grant eq 'write' || $grant eq 'readwrite');
    return 1 if $need eq 'readwrite' && $grant eq 'readwrite';
    return 0;
}

package Praxo::Runtime::ContextBudget;

sub new {
    my ($class, %args) = @_;
    return bless {
        maxTokens => $args{max_tokens} // 0,
        keepRecent => $args{keep_recent} // 0,
    }, $class;
}

sub max_tokens { $_[0]->{maxTokens} }
sub keep_recent { $_[0]->{keepRecent} }

sub compact {
    my ($self, $messages) = @_;
    my $max = $self->{maxTokens};
    return ($messages, 1) if $max <= 0 || Praxo::Runtime::estimate_tokens($messages) <= $max;
    my (@system, @rest);
    for my $message (@$messages) {
        if (($message->{role} // '') eq Praxo::Models::SYSTEM) {
            next if ($message->{content} // '') =~ /^\[context compacted:/;
            push @system, $message;
        } else {
            push @rest, $message;
        }
    }
    if (Praxo::Runtime::estimate_tokens(\@system) > $max) {
        return ([], 0) unless @system;
        my $first = { %{ $system[0] } };
        $first->{content} = Praxo::Runtime::truncate_to_tokens(
            $system[0]{content} // '', $max - 4,
        );
        @system = ($first);
        return ([], 0) if Praxo::Runtime::estimate_tokens(\@system) > $max;
    }
    my $keep = $self->{keepRecent} > 0 ? $self->{keepRecent} : 4;
    my $start = @rest - $keep;
    $start = 0 if $start < 0;
    $start-- while $start > 0 && ($rest[$start]{role} // '') eq Praxo::Models::TOOL;
    my $marker = Praxo::Models::message_text(
        Praxo::Models::SYSTEM,
        "[context compacted: $start older messages omitted]",
    );
    my @kept = @rest[$start .. $#rest];
    my $output = _build_compacted(\@system, $marker, $start > 0, \@kept);
    while (Praxo::Runtime::estimate_tokens($output) > $max && @kept > 1) {
        last if ($kept[1]{role} // '') eq Praxo::Models::TOOL;
        shift @kept;
        $output = _build_compacted(\@system, $marker, $start > 0, \@kept);
    }
    return ($output, Praxo::Runtime::estimate_tokens($output) <= $max ? 1 : 0);
}

sub _build_compacted {
    my ($system, $marker, $include_marker, $kept) = @_;
    my @output = @$system;
    push @output, $marker if $include_marker;
    push @output, @$kept;
    return \@output;
}

package Praxo::Runtime;

sub estimate_tokens {
    my ($messages) = @_;
    my $total = 0;
    for my $message (@$messages) {
        $total += 4 + int(length($message->{content} // '') / 4)
            + int(length($message->{toolId} // '') / 4);
        for my $block (@{ $message->{contentBlocks} // [] }) {
            $total += 4 + int(length($block->{text} // '') / 4)
                + int(length($block->{image_url} // '') / 4)
                + int(length($block->{data} // '') / 4);
        }
        for my $call (@{ $message->{toolCalls} // [] }) {
            $total += 4 + int(length($call->{name} // '') / 4);
            $total += int(length(Praxo::Json::stringify($call->{arguments} // {})) / 4);
        }
    }
    return $total;
}

sub truncate_to_tokens {
    my ($value, $tokens) = @_;
    return '' if $tokens <= 0;
    my $limit = $tokens * 4;
    return $value if length($value) <= $limit;
    return substr($value, 0, $limit) if $limit <= 16;
    return substr($value, 0, $limit - 16) . "\n[truncated]";
}

sub compact_context {
    my ($budget, $messages) = @_;
    return $budget->compact($messages);
}

1;
