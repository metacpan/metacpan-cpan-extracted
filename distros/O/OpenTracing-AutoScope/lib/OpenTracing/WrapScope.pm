package OpenTracing::WrapScope;
our $VERSION = 'v0.106.6';
use strict;
use warnings;
use warnings::register;
use B::Hooks::OP::Check::LeaveEval;
use Caller::Hide qw/hide_package/;
use Carp qw/croak/;
use List::Util qw/uniq/;
use OpenTracing::GlobalTracer;
use PerlX::Maybe;
use Scalar::Util qw/blessed/;
use Sub::Info qw/sub_info/;

hide_package(__PACKAGE__);

my %subs_to_install;    # sub => warn about undetected subs toggle
END {
    foreach my $sub (keys %subs_to_install) {
        next unless $subs_to_install{$sub};
        warnings::warn "OpenTracing::WrapScope couldn't find sub: $sub";
    }
}

sub _register_to_install {
    my ($subs, $warn_undetected) = @_;
    $subs_to_install{$_} = $warn_undetected foreach @$subs;
}

# try to install any available subs whenever we get new code
B::Hooks::OP::Check::LeaveEval::register(sub {
    return unless %subs_to_install;

    foreach my $sub (keys %subs_to_install) {
        next unless defined &$sub;
        install_wrapped($sub);
        delete $subs_to_install{$sub};
    }
    return;
});

sub import {
    shift;    # __PACKAGE__
    my $target_package = caller;

    my $warn_undetected = 1;
    my ($use_env, @subs, @files);
    while (my (undef, $arg) = each @_) {
        if ($arg eq '-env') {
            $use_env = 1;
        }
        elsif ($arg eq '-file') {
            my (undef, $next) = each @_ or last;
            push @files, ref $next eq 'ARRAY' ? @$next : $next;
        }
        elsif ($arg eq '-quiet') {
            $warn_undetected = 0;
        }
        else {
            push @subs, _qualify_sub($arg, $target_package);
        }
    }
    if ($use_env and $ENV{OPENTRACING_WRAPSCOPE_FILE}) {
        push @files, split ':', $ENV{OPENTRACING_WRAPSCOPE_FILE};
    }
    push @subs, map { _load_sub_spec($_) } grep { -f } map { glob } uniq @files;

    _register_to_install(\@subs, $warn_undetected);

    return;
}

sub install_wrapped {
    foreach my $sub (@_) {
        my $full_sub = _qualify_sub($sub, scalar caller);

        if (not defined &$sub) {
            warnings::warn "Couldn't find sub: $sub";
            next;
        }

        my $wrapped = wrapped(\&$sub);

        my ($class, $method) = split /(?:'|::)(?=\w+\z)/, $sub;
        if (_is_moose_class($class)) {   # Moose complains about replaced subs
            if ($class->meta->is_immutable) {
                warnings::warn "Can't wrap Moose method $sub from an immutable class";
                next;
            }
            $class->meta->add_method($method => $wrapped);
        }
        else {
            no strict 'refs';
            no warnings 'redefine';
            *$sub = $wrapped;
        }
    }
    return;
}

sub _is_moose_class {
    my ($class) = @_;
    my $meta = eval { $class->meta } or return;
    return blessed $meta && $meta->isa('Moose::Meta::Class');
}

sub wrapped {
    my ($coderef) = @_;
    my $info = sub_info($coderef);

    return sub {
        my ($call_package, $call_filename, $call_line) = caller(0);
        my $call_sub = (caller(1))[3];
        my $tracer = OpenTracing::GlobalTracer->get_global_tracer; 
        my $scope = $tracer->start_active_span(
            "$info->{package}::$info->{name}",
            tags => {
                'source.subname' => $info->{name},
                'source.file'    => $info->{file},
                'source.line'    => $info->{start_line},
                'source.package' => $info->{package},
                maybe
                'caller.subname' => $call_sub,
                'caller.file'    => $call_filename,
                'caller.line'    => $call_line,
                'caller.package' => $call_package,
            },
        );

        my $result;
        my $wantarray = wantarray;    # eval will have its own
        my $ok = eval {
            if (defined $wantarray) {
                $result = $wantarray ? [&$coderef] : &$coderef;
            }
            else {
                &$coderef;
            }
            1;
        };
        # TODO: message should go to logs but we don't have those yet
        $scope->get_span->add_tags(error => 1, message => "$@") unless $ok;
        $scope->close();

        die $@ unless $ok;
        return if not defined wantarray;
        return wantarray ? @$result : $result;
    };
}

sub _qualify_sub {
    my ($sub, $pkg) = @_;
    return $sub if $sub =~ /'|::/;
    return "${pkg}::$sub";
}

sub _load_sub_spec {
    my ($filename) = @_;

    open my $fh_subs, '<', $filename or die "$filename: $!";

    my @subs;
    while (<$fh_subs>) {
        next if /^\s*#/;    # commented-out line
        s/\s*#.*\Z//;       # trailing comment
        chomp;
        croak "Unqualified subroutine: $_" if !/'|::/;
        push @subs, $_;
    }
    close $fh_subs;

    return @subs;
}

sub wrap_from_file {
    my ($filename) = @_;
    install_wrapped( _load_sub_spec($filename) );
    return;
}


1;
