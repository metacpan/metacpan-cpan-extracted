#line 1
package Test2::Util;
use strict;
use warnings;

our $VERSION = '1.302073';


use Config qw/%Config/;

our @EXPORT_OK = qw{
    try

    pkg_to_file

    get_tid USE_THREADS
    CAN_THREAD
    CAN_REALLY_FORK
    CAN_FORK

    IS_WIN32

    ipc_separator
};
BEGIN { require Exporter; our @ISA = qw(Exporter) }

BEGIN {
    *IS_WIN32 = ($^O eq 'MSWin32') ? sub() { 1 } : sub() { 0 };
}

sub _can_thread {
    return 0 unless $] >= 5.008001;
    return 0 unless $Config{'useithreads'};

    # Threads are broken on perl 5.10.0 built with gcc 4.8+
    if ($] == 5.010000 && $Config{'ccname'} eq 'gcc' && $Config{'gccversion'}) {
        my @parts = split /\./, $Config{'gccversion'};
        return 0 if $parts[0] > 4 || ($parts[0] == 4 && $parts[1] >= 8);
    }

    # Change to a version check if this ever changes
    return 0 if $INC{'Devel/Cover.pm'};
    return 1;
}

sub _can_fork {
    return 1 if $Config{d_fork};
    return 0 unless IS_WIN32 || $^O eq 'NetWare';
    return 0 unless $Config{useithreads};
    return 0 unless $Config{ccflags} =~ /-DPERL_IMPLICIT_SYS/;

    return _can_thread();
}

BEGIN {
    no warnings 'once';
    *CAN_THREAD      = _can_thread()   ? sub() { 1 } : sub() { 0 };
}
my $can_fork;
sub CAN_FORK () {
    return $can_fork
        if defined $can_fork;
    $can_fork = !!_can_fork();
    no warnings 'redefine';
    *CAN_FORK = $can_fork ? sub() { 1 } : sub() { 0 };
    $can_fork;
}
my $can_really_fork;
sub CAN_REALLY_FORK () {
    return $can_really_fork
        if defined $can_really_fork;
    $can_really_fork = !!$Config{d_fork};
    no warnings 'redefine';
    *CAN_REALLY_FORK = $can_really_fork ? sub() { 1 } : sub() { 0 };
    $can_really_fork;
}

sub _manual_try(&;@) {
    my $code = shift;
    my $args = \@_;
    my $err;

    my $die = delete $SIG{__DIE__};

    eval { $code->(@$args); 1 } or $err = $@ || "Error was squashed!\n";

    $die ? $SIG{__DIE__} = $die : delete $SIG{__DIE__};

    return (!defined($err), $err);
}

sub _local_try(&;@) {
    my $code = shift;
    my $args = \@_;
    my $err;

    no warnings;
    local $SIG{__DIE__};
    eval { $code->(@$args); 1 } or $err = $@ || "Error was squashed!\n";

    return (!defined($err), $err);
}

# Older versions of perl have a nasty bug on win32 when localizing a variable
# before forking or starting a new thread. So for those systems we use the
# non-local form. When possible though we use the faster 'local' form.
BEGIN {
    if (IS_WIN32 && $] < 5.020002) {
        *try = \&_manual_try;
    }
    else {
        *try = \&_local_try;
    }
}

BEGIN {
    if (CAN_THREAD) {
        if ($INC{'threads.pm'}) {
            # Threads are already loaded, so we do not need to check if they
            # are loaded each time
            *USE_THREADS = sub() { 1 };
            *get_tid     = sub() { threads->tid() };
        }
        else {
            # :-( Need to check each time to see if they have been loaded.
            *USE_THREADS = sub() { $INC{'threads.pm'} ? 1 : 0 };
            *get_tid     = sub() { $INC{'threads.pm'} ? threads->tid() : 0 };
        }
    }
    else {
        # No threads, not now, not ever!
        *USE_THREADS = sub() { 0 };
        *get_tid     = sub() { 0 };
    }
}

sub pkg_to_file {
    my $pkg = shift;
    my $file = $pkg;
    $file =~ s{(::|')}{/}g;
    $file .= '.pm';
    return $file;
}

sub ipc_separator() { "~" }

1;

__END__

#line 258
