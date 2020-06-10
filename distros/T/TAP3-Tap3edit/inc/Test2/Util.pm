#line 1
package Test2::Util;
use strict;
use warnings;

our $VERSION = '1.302175';

use POSIX();
use Config qw/%Config/;
use Carp qw/croak/;

BEGIN {
    local ($@, $!, $SIG{__DIE__});
    *HAVE_PERLIO = eval { require PerlIO; PerlIO->VERSION(1.02); } ? sub() { 1 } : sub() { 0 };
}

our @EXPORT_OK = qw{
    try

    pkg_to_file

    get_tid USE_THREADS
    CAN_THREAD
    CAN_REALLY_FORK
    CAN_FORK

    CAN_SIGSYS

    IS_WIN32

    ipc_separator

    gen_uid

    do_rename do_unlink

    try_sig_mask

    clone_io
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

my $UID = 1;
sub gen_uid() { join ipc_separator() => ($$, get_tid(), time, $UID++) }

sub _check_for_sig_sys {
    my $sig_list = shift;
    return $sig_list =~ m/\bSYS\b/;
}

BEGIN {
    if (_check_for_sig_sys($Config{sig_name})) {
        *CAN_SIGSYS = sub() { 1 };
    }
    else {
        *CAN_SIGSYS = sub() { 0 };
    }
}

my %PERLIO_SKIP = (
    unix => 1,
    via  => 1,
);

sub clone_io {
    my ($fh) = @_;
    my $fileno = eval { fileno($fh) };

    return $fh if !defined($fileno) || !length($fileno) || $fileno < 0;

    open(my $out, '>&' . $fileno) or die "Can't dup fileno $fileno: $!";

    my %seen;
    my @layers = HAVE_PERLIO ? grep { !$PERLIO_SKIP{$_} and !$seen{$_}++ } PerlIO::get_layers($fh) : ();
    binmode($out, join(":", "", "raw", @layers));

    my $old = select $fh;
    my $af  = $|;
    select $out;
    $| = $af;
    select $old;

    return $out;
}

BEGIN {
    if (IS_WIN32) {
        my $max_tries = 5;

        *do_rename = sub {
            my ($from, $to) = @_;

            my $err;
            for (1 .. $max_tries) {
                return (1) if rename($from, $to);
                $err = "$!";
                last if $_ == $max_tries;
                sleep 1;
            }

            return (0, $err);
        };
        *do_unlink = sub {
            my ($file) = @_;

            my $err;
            for (1 .. $max_tries) {
                return (1) if unlink($file);
                $err = "$!";
                last if $_ == $max_tries;
                sleep 1;
            }

            return (0, "$!");
        };
    }
    else {
        *do_rename = sub {
            my ($from, $to) = @_;
            return (1) if rename($from, $to);
            return (0, "$!");
        };
        *do_unlink = sub {
            my ($file) = @_;
            return (1) if unlink($file);
            return (0, "$!");
        };
    }
}

sub try_sig_mask(&) {
    my $code = shift;

    my ($old, $blocked);
    unless(IS_WIN32) {
        my $to_block = POSIX::SigSet->new(
            POSIX::SIGINT(),
            POSIX::SIGALRM(),
            POSIX::SIGHUP(),
            POSIX::SIGTERM(),
            POSIX::SIGUSR1(),
            POSIX::SIGUSR2(),
        );
        $old = POSIX::SigSet->new;
        $blocked = POSIX::sigprocmask(POSIX::SIG_BLOCK(), $to_block, $old);
        # Silently go on if we failed to log signals, not much we can do.
    }

    my ($ok, $err) = &try($code);

    # If our block was successful we want to restore the old mask.
    POSIX::sigprocmask(POSIX::SIG_SETMASK(), $old, POSIX::SigSet->new()) if defined $blocked;

    return ($ok, $err);
}

1;

__END__

#line 448
