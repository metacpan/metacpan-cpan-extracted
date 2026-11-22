package Mogura::ResultStream;
use strict;
use warnings;
use parent 'JSON::SL::Tuba';

# Retain the envelope and one result at a time. Tool metadata outside the
# descriptor is validated by the parser but never materialized in Perl.
sub read {
    my ($class, $file, $kind, $consume, $digest) = @_;
    my %arrays = (syft => 'artifacts', grype => 'matches', cdx => 'components');
    die 'Unknown result kind' unless $arrays{$kind};
    my $parser = $class->new(utf8 => 1, cb_unified => 1);
    $parser->{array} = $arrays{$kind};
    $parser->{consume} = $consume;
    $parser->{stack} = [];
    open my $handle, '<:raw', $file or die "Open result: $!";

    while (1) {
        my $size = CORE::read($handle, my $chunk, 65536);
        die "Read result: $!" unless defined $size;
        last unless $size;
        $digest->add($chunk) if $digest;
        $parser->{offset} += $size;

        # Tuba accumulates scalar tokens across chunks. Bound unfinished tokens
        # and projected records before accepting another chunk.
        my $start = $parser->{collect_start} // $parser->{last_event} // 0;
        die 'Result record or token exceeds 8 MiB' if $parser->{offset} - $start > 8 * 1024 * 1024;
        $parser->parse($chunk);
    }
    close $handle or die "Close result: $!";
    die 'Incomplete JSON result' unless $parser->{finished} && !@{$parser->{stack}};
    return $parser->{envelope};
}

sub on_any {
    my ($self, $info, $data) = @_;
    $self->{last_event} = $self->{offset};
    my ($type, $mode) = ("$info->{Type}", "$info->{Mode}");
    if ($type eq 'D') {
        if ($mode eq '+') {
            die 'Multiple JSON documents' if $self->{started}++;
        }
        else {
            $self->{finished} = 1;
        }
        return;
    }
    my $stack = $self->{stack};
    if ($mode eq '-') {
        my $frame = pop @$stack;
        delete $self->{collect_start} if $frame->{bounded};
        $self->{consume}->($frame->{value}) if $frame->{item} && $self->{consume};
        return;
    }
    my $depth = @$stack;
    my $key = $info->{Key};
    my $item = $depth == 2 && ($stack->[1]{key} // '') eq $self->{array};
    my $collect =
        !$depth
        || ($depth == 1 && ($key // '') eq 'descriptor')
        || ($depth > 1 && $stack->[-1]{collect})
        || ($item && $self->{consume});
    my $container = $type eq '{' || $type eq '[';
    my $value = $container ? ($type eq '{' ? {} : []) : ($type eq '?' ? ($data ? 1 : 0) : $data);
    if (!$depth) {
        die 'Invalid JSON result envelope' unless $type eq '{';
        $self->{envelope} = $value;
    }
    elsif (
        !$item
        && (
            (
                $depth == 1
                && ($key // '') =~
                /\A(?:artifacts|matches|components|descriptor|source|bomFormat|specVersion)\z/
            )
            || ($depth > 1 && $stack->[-1]{collect})
        )
        )
    {
        my $parent = $stack->[-1]{value};
        if (ref $parent eq 'HASH') { $parent->{$key} = $value; }
        else { push @$parent, $value; }
    }
    if ($container) {
        my $bounded = ($depth == 1 && ($key // '') eq 'descriptor') || ($item && $self->{consume});
        $self->{collect_start} = $self->{offset} if $bounded;
        push @$stack,
            {bounded => $bounded, key => $key, collect => $collect, item => $item, value => $value};
    }
    elsif ($item && $self->{consume}) {
        $self->{consume}->($value);
    }
}

sub valid_artifact {
    my ($self, $file, $kind) = @_;

    my $data = $self->read($file, $kind);
    die "Invalid $kind JSON" unless ref $data eq 'HASH';

    # Validate the envelope before publishing or using an output as another
    # tool's input. A syntactically valid JSON document alone is insufficient.
    if ($kind eq 'syft') {
        die 'Invalid Syft SBOM' unless ref($data->{artifacts}) eq 'ARRAY';
        die 'Invalid Syft SBOM' unless ref($data->{descriptor}) eq 'HASH';
        die 'Invalid Syft SBOM' unless ($data->{descriptor}{name} // '') eq 'syft';
        die 'Invalid Syft SBOM' unless ref($data->{source}) eq 'HASH';
    }
    elsif ($kind eq 'cdx') {
        die 'Invalid CycloneDX SBOM' unless ($data->{bomFormat} // '') eq 'CycloneDX';
        die 'Invalid CycloneDX SBOM' unless $data->{specVersion};
        die 'Invalid CycloneDX SBOM'
            if exists $data->{components} && ref($data->{components}) ne 'ARRAY';
    }
    elsif ($kind eq 'grype') {
        die 'Invalid Grype result' unless ref($data->{matches}) eq 'ARRAY';
        die 'Invalid Grype result' unless ref($data->{descriptor}) eq 'HASH';
        die 'Invalid Grype result' unless ($data->{descriptor}{name} // '') eq 'grype';
    }
    return $data;
}

1;
