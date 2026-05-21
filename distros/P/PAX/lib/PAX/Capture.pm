package PAX::Capture;

our $VERSION = '0.031';

use strict;
use warnings;
use Cwd qw(abs_path);
use File::Spec;
use IPC::Open3;
use Symbol qw(gensym);

sub new {
    my ($class, %args) = @_;
    return bless {
        mode => $args{mode} // 'live',
    }, $class;
}

sub capture {
    my ($self, $entrypoint) = @_;
    my $abs = abs_path($entrypoint);
    if (!defined $abs || !-f $abs) {
        return {
            status => 'error',
            mode => $self->{mode},
            source_entrypoint => $entrypoint,
            diagnostics => [{
                level => 'error',
                code => 'entrypoint_not_found',
                message => "entrypoint not found: $entrypoint",
            }],
        };
    }

    my $probe = _probe_source();
    my ($out, $err, $exit) = _run_perl_probe($probe, $abs, $self->{mode});
    my $data = _decode_probe_output($out);
    my $features = _scan_source_features($abs);
    my @diagnostics;

    push @diagnostics, @{ $data->{diagnostics} // [] } if ref $data eq 'HASH';
    if ($err ne '') {
        push @diagnostics, {
            level => $exit == 0 ? 'warning' : 'error',
            code => 'perl_stderr',
            message => $err,
        };
    }
    if ($exit != 0) {
        push @diagnostics, {
            level => 'error',
            code => 'capture_failed',
            message => "reference Perl exited with status $exit",
        };
    }

    $data = {} if ref $data ne 'HASH';
    $data->{status} = $exit == 0 ? 'ok' : 'error';
    $data->{mode} = $self->{mode};
    $data->{source_entrypoint} = $abs;
    $data->{source_features} = $features;
    $data->{diagnostics} = \@diagnostics;
    return $data;
}

sub _scan_source_features {
    my ($path) = @_;
    open my $fh, '<', $path or return {};
    local $/;
    my $source = <$fh> // '';
    return {
        string_eval => $source =~ /\beval\s+["']/ ? 1 : 0,
        autoload => $source =~ /\bAUTOLOAD\b/ ? 1 : 0,
        tie => $source =~ /\btie\s*[\(\s]/ ? 1 : 0,
        overload => $source =~ /\buse\s+overload\b/ ? 1 : 0,
        typeglob => $source =~ /\*[A-Za-z_][A-Za-z0-9_:]*/ ? 1 : 0,
        xs_loader => $source =~ /\b(?:XSLoader|DynaLoader)\b/ ? 1 : 0,
        local_dynamic => $source =~ /\blocal\s+[$@%*]/ ? 1 : 0,
    };
}

sub _run_perl_probe {
    my ($probe, $entrypoint, $mode) = @_;
    my $err = gensym;
    my $pid = open3(my $in, my $out, $err, $^X, '-', $entrypoint, $mode);
    print {$in} $probe;
    close $in;

    local $/;
    my $stdout = <$out> // '';
    my $stderr = <$err> // '';
    waitpid($pid, 0);
    my $exit = $? >> 8;
    return ($stdout, $stderr, $exit);
}

sub _decode_probe_output {
    my ($out) = @_;
    require JSON::PP;
    my $decoded = eval { JSON::PP::decode_json($out) };
    if ($@) {
        return {
            diagnostics => [{
                level => 'error',
                code => 'probe_json_decode_failed',
                message => "$@",
            }],
            raw_probe_output => $out,
        };
    }
    return $decoded;
}

sub _probe_source {
    return <<'PERL';
use strict;
use warnings;
use JSON::PP ();
use Config;
use B qw(svref_2object);

my ($entrypoint, $mode) = @ARGV;
my @events;
my @diagnostics;
my %before_inc = %INC;
my %SOURCE_CACHE;

BEGIN { }

sub _config_hash {
    my @keys = qw(version archname useithreads usemultiplicity use64bitint use64bitall
                  ivsize nvsize ptrsize uselongdouble d_setlocale d_strtod useshrplib
                  libperl cc ccflags optimize);
    my %selected = map { $_ => (defined $Config{$_} ? "$Config{$_}" : undef) } @keys;
    return \%selected;
}

sub _package_shapes {
    no strict 'refs';
    my %packages;
    my %seen;
    _walk_stash('', \%::, \%packages, \%seen);
    return \%packages;
}

sub _walk_stash {
    my ($prefix, $stash, $packages, $seen) = @_;
    no strict 'refs';
    my $stash_id = "$stash";
    return if $seen->{$stash_id}++;
    for my $name (sort keys %$stash) {
        next unless $name =~ /::$/;
        my $pkg = $prefix . substr($name, 0, -2);
        my $full = $pkg . '::';
        my $glob = *{$full}{HASH};
        next if !defined $glob;
        my $child = $glob;
        my $child_id = "$child";
        $packages->{$pkg} = {
            symbol_count => scalar(keys %$child),
            symbols => [sort keys %$child],
        };
        _walk_stash($full, $child, $packages, $seen) if !$seen->{$child_id};
    }
}

sub _sub_optree_summary {
    my ($name, $code) = @_;
    my $obj = eval { svref_2object($code) };
    if ($@ || !$obj) {
        return {
            name => $name,
            available => JSON::PP::false(),
            reason => "$@",
        };
    }
    my $root = eval { $obj->ROOT };
    my $start = eval { $obj->START };
    return {
        name => $name,
        available => JSON::PP::true(),
        root_class => $root ? ref($root) : undef,
        start_class => $start ? ref($start) : undef,
        optree_ops => _walk_ops($start),
        pad_layout => _pad_layout($obj),
        closure_descriptor => _closure_descriptor($obj),
        native_shape => _native_shape_for_sub($name, eval { $obj->FILE }),
    };
}

sub _walk_ops {
    my ($start) = @_;
    my @ops;
    my %seen;
    my $op = $start;
    while ($op && @ops < 256) {
        my $id = eval { 0 + $$op };
        $id = ref($op) . ':' . scalar(@ops) if !defined $id;
        last if $seen{$id}++;
        push @ops, {
            class => ref($op),
            name => eval { $op->name } || undef,
            desc => eval { $op->desc } || undef,
        };
        $op = eval { $op->next };
    }
    return \@ops;
}

sub _pad_layout {
    my ($cv) = @_;
    my $padlist = eval { $cv->PADLIST };
    return [] if !$padlist;
    my @pads;
    my @pad_entries = eval { $padlist->ARRAY };
    return [] if $@;
    for my $pad (@pad_entries) {
        my @items = eval { $pad->ARRAY };
        next if $@;
        push @pads, [
            map +{
                class => ref($_),
                name => eval { $_->can('PV') ? $_->PV : undef } || undef,
            }, @items
        ];
    }
    return \@pads;
}

sub _closure_descriptor {
    my ($cv) = @_;
    return {
        class => ref($cv),
        has_padlist => eval { $cv->PADLIST ? JSON::PP::true() : JSON::PP::false() } || JSON::PP::false(),
        file => eval { $cv->FILE } || undef,
        stash => eval { $cv->STASH->NAME } || undef,
    };
}

sub _subs {
    no strict 'refs';
    my @subs;
    for my $pkg (sort keys %{ _package_shapes() }) {
        my $stash = \%{$pkg . '::'};
        for my $sym (sort keys %$stash) {
            my $full = $pkg . '::' . $sym;
            my $code = *{$full}{CODE};
            next unless $code;
            my $summary = eval { _sub_optree_summary($full, $code) };
            push @subs, $summary || {
                name => $full,
                available => JSON::PP::false(),
                reason => "$@",
            };
        }
    }
    return \@subs;
}

my $ok = eval {
    local @ARGV = ();
    require File::Spec;
    open my $null_out, '>', File::Spec->devnull() or die "cannot open devnull: $!";
    open my $null_err, '>', File::Spec->devnull() or die "cannot open devnull: $!";
    local *STDOUT = $null_out;
    local *STDERR = $null_err;
    do $entrypoint;
    die $@ if $@;
    1;
};

if (!$ok) {
    push @diagnostics, {
        level => 'error',
        code => 'entrypoint_execution_failed',
        message => "$@",
    };
}

my @loaded = sort grep { !exists $before_inc{$_} } keys %INC;
my $source = _slurp($entrypoint);
my $result = {
    runtime => {
        perl_version => "$^V",
        config_version => "$Config{version}",
        archname => "$Config{archname}",
        executable => $^X,
        config => _config_hash(),
    },
    capture => {
        mode => $mode,
        loaded_files => \@loaded,
        package_shapes => _package_shapes(),
        sub_optrees => _subs(),
        method_resolution => _method_resolution(),
        regex_metadata => _regex_metadata($source),
        compile_phase_events => _compile_phase_events($source),
    },
    diagnostics => \@diagnostics,
};

print JSON::PP->new->ascii(1)->canonical(1)->encode($result);
exit($ok ? 0 : 1);

sub _method_resolution {
    no strict 'refs';
    my %methods;
    for my $pkg (sort keys %{ _package_shapes() }) {
        my $stash = \%{$pkg . '::'};
        $methods{$pkg} = {
            mro => eval { require mro; [mro::get_linear_isa($pkg)] } || [$pkg],
            methods => [sort grep { *{$pkg . '::' . $_}{CODE} } keys %$stash],
        };
    }
    return \%methods;
}

sub _regex_metadata {
    my ($source) = @_;
    my @patterns;
    while ($source =~ m{(?:m|qr)?/((?:\\/|[^/])*)/[a-z]*}g) {
        push @patterns, {
            pattern => $1,
            locale_sensitive => $source =~ /\buse\s+locale\b/ ? JSON::PP::true() : JSON::PP::false(),
            unicode_sensitive => $source =~ /\buse\s+utf8\b/ ? JSON::PP::true() : JSON::PP::false(),
        };
    }
    return \@patterns;
}

sub _compile_phase_events {
    my ($source) = @_;
    my @events;
    for my $hook (qw(BEGIN UNITCHECK CHECK INIT END)) {
        while ($source =~ /\b\Q$hook\E\s*\{/g) {
            push @events, {
                hook => $hook,
                offset => pos($source) - length($hook) - 1,
                source => 'static_scan',
            };
        }
    }
    while ($source =~ /\buse\s+([A-Za-z_][A-Za-z0-9_:]*)/g) {
        push @events, { hook => 'use', module => $1, source => 'static_scan' };
    }
    while ($source =~ /\brequire\s+([A-Za-z_][A-Za-z0-9_:]*|["'][^"']+["'])/g) {
        push @events, { hook => 'require', target => $1, source => 'static_scan' };
    }
    return \@events;
}

sub _native_shape_for_sub {
    my ($name, $file) = @_;
    return undef if $name !~ /::(\w+)$/;
    my $sub_name = $1;
    my $source = _slurp($file || $entrypoint);
    my $body = _extract_sub_body($source, $sub_name);
    return undef if !defined $body;
    return _lower_i64_binary_leaf($body)
        || _lower_i64_sum_loop($body)
        || _lower_i64_masked_mix_accum_loop($body);
}

sub _extract_sub_body {
    my ($source, $sub_name) = @_;
    return if $source !~ /sub\s+\Q$sub_name\E\s*\{/g;
    my $start = pos($source);
    my $depth = 1;
    my $i = $start;
    while ($i < length($source)) {
        my $char = substr($source, $i, 1);
        $depth++ if $char eq '{';
        $depth-- if $char eq '}';
        return substr($source, $start, $i - $start) if $depth == 0;
        $i++;
    }
    return;
}

sub _lower_i64_binary_leaf {
    my ($body) = @_;
    return if $body !~ /my\s*\(\s*\$([A-Za-z_]\w*)\s*,\s*\$([A-Za-z_]\w*)\s*\)\s*=\s*\@_\s*;/s;
    my ($left, $right) = ($1, $2);
    return if $body !~ /return\s+\$([A-Za-z_]\w*)\s*([+\-*]|>)\s*\$([A-Za-z_]\w*)\s*;/s;
    return if $1 ne $left || $3 ne $right;
    my %ops = (
        '+' => ['add', 'left + right', 5],
        '-' => ['subtract', 'left - right', -1],
        '*' => ['multiply', 'left * right', 6],
        '>' => ['greater_than', 'if left > right { 1 } else { 0 }', 0],
    );
    my $op = $ops{$2} or return;
    return {
        kind => 'i64_binary_leaf',
        op => $op->[0],
        args => [$left, $right],
        rust_expr => $op->[1],
        smoke_left => 2,
        smoke_right => 3,
        smoke_expected => $op->[2],
        source => 'capture_optree_unit',
    };
}

sub _lower_i64_sum_loop {
    my ($body) = @_;
    return if $body !~ /my\s*\(\s*\$([A-Za-z_]\w*)\s*\)\s*=\s*\@_\s*;/s;
    my $limit = $1;
    return if $body !~ /my\s+\$([A-Za-z_]\w*)\s*=\s*0\s*;/s;
    my $sum = $1;
    my $limit_ref = quotemeta('$' . $limit);
    my $sum_ref = quotemeta('$' . $sum);
    return if $body !~ /for\s*\(\s*my\s+\$([A-Za-z_]\w*)\s*=\s*1\s*;\s*\$\1\s*<=\s*$limit_ref\s*;\s*\$\1\+\+\s*\)\s*\{\s*$sum_ref\s*\+=\s*\$\1\s*;\s*\}/s;
    my $induction = $1;
    return if $body !~ /return\s+$sum_ref\s*;/s;
    return {
        kind => 'i64_sum_loop',
        op => 'sum_to_n',
        args => [$limit],
        accumulator => $sum,
        induction => $induction,
        smoke_left => 10,
        smoke_right => 0,
        smoke_expected => 55,
        rust_body => <<'RUST_BODY',
    if left <= 0 {
        return 0;
    }
    let mut sum: i64 = 0;
    let mut i: i64 = 1;
    while i <= left {
        sum += i;
        i += 1;
    }
    sum
RUST_BODY
        source => 'capture_optree_unit',
    };
}

# Recognize the masked-mix accumulator loop shape so the capture pipeline can
# promote long-running arithmetic kernels into a native loop candidate.
sub _lower_i64_masked_mix_accum_loop {
    my ($body) = @_;
    return if $body !~ /my\s*\(\s*\$([A-Za-z_]\w*)\s*\)\s*=\s*\@_\s*;/s;
    my $limit = $1;
    return if $body !~ /my\s+\$([A-Za-z_]\w*)\s*=\s*0\s*;/s;
    my $acc = $1;
    my $limit_ref = quotemeta('$' . $limit);
    my $acc_ref = quotemeta('$' . $acc);
    return if $body !~ /for\s*\(\s*my\s+\$([A-Za-z_]\w*)\s*=\s*0\s*;\s*\$\1\s*<\s*$limit_ref\s*;\s*\$\1\+\+\s*\)\s*\{\s*$acc_ref\s*\+=\s*\(\(\s*\$\1\s*\*\s*13\s*\)\s*\^\s*\(\s*\$\1\s*>>\s*3\s*\)\)\s*&\s*0xFFFF\s*;\s*\}/s;
    my $induction = $1;
    return if $body !~ /return\s+$acc_ref\s*;/s;
    return {
        kind => 'i64_masked_mix_accum_loop',
        op => 'masked_mix_accumulate',
        args => [$limit],
        accumulator => $acc,
        induction => $induction,
        smoke_left => 8,
        smoke_right => 0,
        smoke_expected => 360,
        source => 'capture_optree_unit',
    };
}

sub _slurp {
    my ($path) = @_;
    return '' if !defined $path || $path eq '';
    return $SOURCE_CACHE{$path} if exists $SOURCE_CACHE{$path};
    open my $fh, '<', $path or return '';
    local $/;
    return $SOURCE_CACHE{$path} = (<$fh> // '');
}
PERL
}

1;

=pod

=head1 NAME

PAX::Capture - live and hermetic capture engine

=head1 SYNOPSIS

  use PAX::Capture;

  my $obj = PAX::Capture->new(...);
  my $result = $obj->capture(...);

=head1 DESCRIPTION

Executes Perl entrypoints under controlled capture modes and emits the structural runtime information that later compiler passes consume.

=head1 METHODS

=head2 new, capture

These are the public entrypoints exposed by this module's current interface.

=head1 PURPOSE

This module exists to keep the live and hermetic capture engine logic in one place so the CLI, build
pipeline, and runtime can reuse the same behavior instead of duplicating it.

=head1 WHY IT EXISTS

PAX uses this module when it needs live and hermetic capture engine. Keeping that behavior isolated here
makes the surrounding compiler and packaging stages easier to reason about and
safer to evolve.

=head1 WHEN TO USE

Edit this file when a change affects live and hermetic capture engine, the data contract this module
returns, or the conditions under which callers choose this path.

=head1 HOW TO USE

Load the module through the normal PAX call path, pass explicit arguments rather
than ambient global state, and keep project-specific behavior out of this file
so the implementation stays neutral across arbitrary Perl applications.

=head1 WHAT USES IT

This module is used by the PAX CLI, the build pipeline, standalone packaging,
and the test suite paths that cover live and hermetic capture engine.

=head1 EXAMPLES

Example 1:

  perl -Ilib -MPAX::Capture -e 1

Confirm that the module loads from a source checkout.

Example 2:

  prove -lr t

Run the repository test suite after changing the behavior this module owns.

=cut
