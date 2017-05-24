# emulate default behaviors for the various signals.

package Signals::XSIG::Default;

## no critic (RequireLocalizedPunctuationVars)

use strict;
use warnings;
use Config;
use Carp;
use POSIX ();
use Exporter;

our @ISA = qw(Exporter);
our @EXPORT = qw(%DEFAULT_BEHAVIOR);

our %DEFAULT_BEHAVIOR;
our $VERSION = '0.15';

my @snam = split ' ', $Config{sig_name};
my @snum = split ' ', $Config{sig_num};

sub import {
    my $ignore = 1;
    while (<DATA>) {
	next if /^#/;
	next unless /\S/;
	if (/^\[(.+)\]/) {
	    if ($1 eq 'default' || $1 eq $^O) {
		$ignore = 0;
	    } else {
		$ignore = 1;
	    }
	} elsif (/\{(.+)\/(\d+)\}/) {
	    if ($1 eq $^O && $2 <= int($] * 1000)) {
		$ignore = 0;
	    } else {
		$ignore = 1;
	    }
	} elsif (!$ignore) {
	    s/^\d+\. //;
	    s/^SIG//;
	    my ($sig, $num, $behavior) = /^(\w+)\s+\[(\d*)\]\s+=>\s+(.+)/;
	    if (defined $sig) {
		$DEFAULT_BEHAVIOR{$sig} = $behavior;
	    }
	}
    }
    return;
}

sub perform_default_behavior {
    my ($signal, @args) = @_;

    my $funcname = 'default_SIG' . $signal;
    if (defined &$funcname) {
	no strict 'refs';                    ## no critic (NoStrict)
	return if $funcname->($signal, @args);
    }

    my $behavior = $DEFAULT_BEHAVIOR{$signal};
    if (!defined $behavior) {
	if ($signal =~ /^NUM(\d+)/) {
	    my $signum = 0 + $1;
	    $behavior = $DEFAULT_BEHAVIOR{"NUMxx"};
	    $behavior =~ s/xx/$signum/;
	}
	if (!defined $behavior) {
	    croak "Signals::XSIG: no default behavior is specified ",
	        "for SIG$signal. Terminating this program.\n";
	}
    }

    if (ref($behavior) eq 'CODE') {
	if (defined &$behavior) {
	    $behavior->($signal);
	    return;
	} else {
	    carp "Signals::XSIG: Default behavior for SIG$signal ",
	        "is not set to a valid subroutine.";
	    return;
	}
    }

    if ($behavior eq 'IGNORE') {
	return;
    }

    if ($behavior eq 'SUSPEND') {
	suspend($signal);
	# ... then wait for the SIGCONT ... 
	return;
    }

    if ($behavior =~ /^ABORT/) {
	untie %SIG;
	%SIG = ();
	$SIG{$signal} = $SIG{"ABRT"} = "DEFAULT";
	killprog_with_signal("ABRT");
	POSIX::abort();
	croak "Abort\n";
    }
    if ($behavior =~ /^SIGSEGV/) {
	killprog_with_signal('SEGV');
	croak "Abort\n";
    }

    if ($behavior =~ /^EXIT (\d+)/) {
	my $exit_code = $1;
	exit($exit_code);
    }

    if ($behavior =~ /^TERMINATE/) {
	my $number;
	for (my $i=0; $i<@snum; $i++) {
	    $number = $snum[$i] if $signal eq $snam[$i];
	}

	killprog_with_signal($signal, $number);
	croak "default behavior for SIG$signal should have killed script ",
            "but for some reason it didn't  :-(\n";
    }

    croak "Signals::XSIG: unknown behavior \"$behavior\" ",
        "for SIG$signal. Terminating this program.\n";
}

sub killprog_with_signal {
    my ($sig,$sig_no) = @_;
    untie %SIG;
    %SIG = ();
    $SIG{$sig} = 'DEFAULT';

    unless ($sig_no) {
	my @sig_name = split ' ', $Config{sig_name};
	($sig_no) = grep { $sig eq $sig_name[$_] } split ' ',$Config{sig_num};
    }

    kill $sig, $$;
    sleep 1 if $^O eq 'MSWin32';
    eval {
	use POSIX ();
	if ($sig_no) {
	    # this is needed for Linux
	    POSIX::sigaction($sig_no, &POSIX::SIG_DFL);
	    POSIX::sigprocmask(&POSIX::SIG_UNBLOCK, 
			       POSIX::SigSet->new($sig_no));
	}
    } or ();
    kill $sig, $$;
    sleep 1 if $^O eq 'MSWin32';

    my $miniprog = q[$SIG{'__SIGNAL__'}='DEFAULT';
                     kill '__SIGNAL__',$$;sleep 1+"MSWin32"eq$^O;die];
    $miniprog =~ s/__SIGNAL__/$sig/g;
    exec($^X, "-e", $miniprog);
}

# in principle, SIGSTOP cannot be trapped.
sub suspend {
    if ($^O eq 'MSWin32') {
	# MSWin32 doesn't have signals as such.
	# Win32::API->SuspendProcess / SuspendThread ?
	# Win32::Process->suspend ?
	# Win32::Thread->suspend ?
	if ($$ > 0) {
	    # suspend process
	    #   enumerate all threads in process
	    #   suspend each thread
	} else {
	    # suspend thread
	}
    }
    return kill 'STOP', $$;
}

##################################################################

# system specific and other special behaviors.
# Signals that don't fall into the terminate/suspend/ignore
# paradigm or that have other special needs can be implemented
# below.
# Return true if the signal is "handled" and no further 
# processing is necessary.

sub default_SIG__WARN__ {          ## no critic (Unpacking)
    CORE::warn @_;
    return 1;
}

sub default_SIG__DIE__ {          ## no critic (Unpacking)
    CORE::die @_;
    return 1;
}

1;

=head1 NAME

Signals::XSIG::Default

=head1 DESCRIPTION

Module for emulating the default behavior for all
signals in your system. The emulator is used when you have
used L<Signals::XSIG> to register more than one 
handler for a signal, and at least one of those 
handlers is C<DEFAULT>.

See L<Signals::XSIG> for much more information.

=cut



# see  spike/analyze_default_signal_behavior.pl

# for each new system that is available to us, run
#    spike/analyze_default_signal_behavior.pl
# and include that data at the end of this file ...
#
# we can also infer behavior from CPAN tester results,
# see t/20-defaults.t
#
__DATA__
[default]
ABRT [] => ABORT
ALRM [] => TERMINATE
BREAK [] => TERMINATE
BUS [] => TERMINATE
CHLD [] => IGNORE
CLD [] => IGNORE
CONT [] => IGNORE
EMT [] => TERMINATE
FPE [] => TERMINATE
HUP [] => TERMINATE
ILL [] => TERMINATE
INT [] => TERMINATE
IO [] => TERMINATE
IOT [] => TERMINATE
KILL [] => TERMINATE
LOST [] => TERMINATE
NUMxx [] => TERMINATE xx
PIPE [] => TERMINATE
POLL [] => TERMINATE
PROF [] => TERMINATE
PWR [] => TERMINATE
QUIT [] => TERMINATE
SEGV [] => ABORT
STKFLT [] => TERMINATE
STOP [] => SUSPEND
SYS [] => TERMINATE
TERM [] => TERMINATE
TRAP [] => TERMINATE
TSTP [] => SUSPEND
TTIN [] => SUSPEND
TTOU [] => SUSPEND
URG [] => IGNORE
USR1 [] => TERMINATE
USR2 [] => TERMINATE
VTALRM [] => TERMINATE
WINCH [] => IGNORE
XCPU [] => TERMINATE
XFSZ [] => TERMINATE
ZERO [] => IGNORE
__DIE__ [] => IGNORE
__WARN__ [] => IGNORE

[MSWin32]
ABRT    [22] => EXIT 22
ALRM    [14] => EXIT 14
BREAK   [21] => TERMINATE 21
CHLD    [20] => EXIT 20
CLD     [20] => EXIT 20
CONT    [25] => EXIT 25
FPE     [8] => EXIT 8
HUP     [1] => EXIT 1
ILL     [4] => EXIT 4
INT     [2] => IGNORE
KILL    [9] => EXIT 9
NUMxx   [] => EXIT xx
PIPE    [13] => EXIT 13
QUIT    [21] => IGNORE
SEGV    [11] => EXIT 11
STOP    [23] => EXIT 23
TERM    [15] => IGNORE
ZERO    [] => IGNORE
__DIE__ [] => IGNORE
__WARN__ [] => IGNORE

[linux]
ABRT    [6] => TERMINATE 6
ALRM    [14] => TERMINATE 14
BUS     [7] => TERMINATE 7
CHLD    [17] => IGNORE
CLD     [17] => IGNORE
CONT    [18] => IGNORE
FPE     [8] => TERMINATE 8
HUP     [1] => TERMINATE 1
ILL     [4] => TERMINATE 4
INT     [2] => TERMINATE 2
IO      [29] => TERMINATE 29
IOT     [6] => TERMINATE 6
KILL    [9] => TERMINATE 9
NUMxx   [] => TERMINATE xx
PIPE    [13] => TERMINATE 13
POLL    [29] => TERMINATE 29
PROF    [27] => TERMINATE 27
PWR     [30] => TERMINATE 30
QUIT    [3] => TERMINATE 3
RTMAX   [64] => TERMINATE 64
RTMIN   [34] => TERMINATE 34
SEGV    [11] => TERMINATE 11
STKFLT  [16] => TERMINATE 16
STOP    [19] => SUSPEND
SYS     [31] => TERMINATE 31
TERM    [15] => TERMINATE 15
TRAP    [5] => TERMINATE 5
TSTP    [20] => SUSPEND
TTIN    [21] => SUSPEND
TTOU    [22] => SUSPEND
UNUSED  [31] => TERMINATE 31
URG     [23] => IGNORE
USR1    [10] => TERMINATE 10
USR2    [12] => TERMINATE 12
VTALRM  [26] => TERMINATE 26
WINCH   [28] => IGNORE
XCPU    [24] => TERMINATE 24
XFSZ    [25] => TERMINATE 25
ZERO    [0] => IGNORE
__DIE__ [] => IGNORE
__WARN__ [] => IGNORE

[aix]
AIO	[]   => IGNORE
IOINT   []   => IGNORE
POLL	[]   => IGNORE
SEGV    [11] => TERMINATE 11
URG	[]   => URG

[cygwin]
ABRT    [6] => TERMINATE 134
ALRM    [14] => TERMINATE 14
BUS     [10] => TERMINATE 10
CHLD    [20] => IGNORE
CLD     [20] => IGNORE
CONT    [19] => IGNORE
EMT     [7] => TERMINATE 7
FPE     [8] => TERMINATE 8
HUP     [1] => TERMINATE 1
ILL     [4] => TERMINATE 4
INT     [2] => TERMINATE 2
IO      [23] => IGNORE
KILL    [9] => TERMINATE 9
LOST    [29] => TERMINATE 29
PIPE    [13] => TERMINATE 13
POLL    [23] => IGNORE
PROF    [27] => TERMINATE 27
PWR     [29] => TERMINATE 29
QUIT    [3] => TERMINATE 131
RTMAX   [32] => TERMINATE 32
RTMIN   [32] => TERMINATE 32
SEGV    [11] => TERMINATE 11
STOP    [17] => SUSPEND
SYS     [12] => TERMINATE 12
TERM    [15] => TERMINATE 15
TRAP    [5] => TERMINATE 5
TSTP    [18] => SUSPEND
TTIN    [21] => SUSPEND
TTOU    [22] => SUSPEND
URG     [16] => IGNORE
USR1    [30] => TERMINATE 30
USR2    [31] => TERMINATE 31
VTALRM  [26] => TERMINATE 26
WINCH   [28] => IGNORE
XCPU    [24] => TERMINATE 24
XFSZ    [25] => TERMINATE 25
ZERO    [] => IGNORE
__DIE__ [] => IGNORE
__WARN__ [] => IGNORE

# www.cpantesters.org/cpan/report/4d60a820-e5c2-11df-bf62-5eb33ef6c52e
[darwin]
ABRT   [6] => TERMINATE 6
EMT    [7] => TERMINATE 7
SEGV   [11] => TERMINATE 11
IO     [] => IGNORE
IOT    [6] => TERMINATE 6
TSTP    [18] => IGNORE
TTIN    [21] => IGNORE
TTOU    [22] => IGNORE

# www.cpantesters.org/cpan/report/4b99dd2a-e60f-11df-bb29-ad544afd17af
[dragonfly]
ABRT [6] => TERMINATE 134
EMT [7] => TERMINATE 135
SEGV [11] => TERMINATE 139
IO [] => IGNORE
IOT [] => TERMINATE 134

# www.cpantesters.org/cpan/report/62d0832e-e621-11df-858d-e879df34a846a
[freebsd]
ABRT [6] => TERMINATE 134
EMT [7] => TERMINATE 135
SEGV [11] => TERMINATE 139
IO [] => IGNORE
IOT [] => TERMINATE 134
TSTP [] => IGNORE
TTIN [] => IGNORE
TTOU [] => IGNORE

[gnukfreebsd]
ABRT [6] => TERMINATE 134
EMT [7] => TERMINATE 135
SEGV [11] => TERMINATE 139
IO [23] => IGNORE
IOT [] => TERMINATE 134
POLL [23] => IGNORE
TSTP [] => IGNORE
TTIN [] => IGNORE
TTOU [] => IGNORE

# www.cpantesters.org/cpan/report/c8635a72-e5d6-11df-a833-d9c7245fd73a
[irix]
ABRT [6] => TERMINATE 134
EMT [7] => TERMINATE 135
SEGV [11] => TERMINATE 139
RTMIN [49] => TERMINATE 49
RTMAX [64] => TERMINATE 64
IOT [] => TERMINATE 134

# www.cpantesters.org/cpan/report/8da6fe76-26f2-11e1-953f-bc4e84dee9ce
[mirbsd]
ILL [4] => TERMINATE 132
BUS [10] => TERMINATE 138
SEGV [11] => TERMINATE 139

# www.cpantesters.org/cpan/report/209fd0b6-e61e-11df-bb29-ad544afd17af
[netbsd]
ABRT [6] => TERMINATE 134
EMT [7] => TERMINATE 135
SEGV [11] => TERMINATE 139
IO [] => IGNORE
IOT [6] = TERMINATE 134
TSTP [] => IGNORE
TTIN [] => IGNORE
TTOU [] => IGNORE

[openbsd]
ILL [4] => TERMINATE 132
ABRT [6] => TERMINATE 134
EMT [7] => TERMINATE 135
BUS [10] => TERMINATE 138
SEGV [11] => TERMINATE 139
IO [] => IGNORE

[mirbsd]
ILL [4] => TERMINATE 132
BUS [10] => TERMINATE 138
SEGV [11] => TERMINATE 139
IO [] => IGNORE

[solaris]
ABRT    [6] => TERMINATE 134
ALRM    [14] => TERMINATE 14
BUS     [10] => TERMINATE 138
CANCEL  [36] => IGNORE
CHLD    [18] => IGNORE
CLD     [18] => IGNORE
CONT    [25] => IGNORE
EMT     [7] => TERMINATE 135
FPE     [8] => TERMINATE 136
FREEZE  [34] => IGNORE
HUP     [1] => TERMINATE 1
ILL     [4] => TERMINATE 132
INT     [2] => TERMINATE 2
IO      [22] => TERMINATE 22
IOT     [6] => TERMINATE 134
JVM1    [39] => IGNORE
JVM2    [40] => IGNORE
KILL    [9] => TERMINATE 9
LOST    [37] => TERMINATE 37
LWP     [33] => IGNORE
NUMxx   [42] => TERMINATE xx
PIPE    [13] => TERMINATE 13
POLL    [22] => TERMINATE 22
PROF    [29] => TERMINATE 29
PWR     [19] => IGNORE
QUIT    [3] => TERMINATE 131
RTMAX   [48] => TERMINATE 48
RTMIN   [41] => TERMINATE 41
SEGV    [11] => TERMINATE 139
STOP    [23] => SUSPEND
SYS     [12] => TERMINATE 140
TERM    [15] => TERMINATE 15
THAW    [35] => IGNORE
TRAP    [5] => TERMINATE 5
TSTP    [24] => SUSPEND
TTIN    [26] => SUSPEND
TTOU    [27] => SUSPEND
URG     [21] => IGNORE
USR1    [16] => TERMINATE 16
USR2    [17] => TERMINATE 17
VTALRM  [28] => TERMINATE 28
WAITING [32] => IGNORE
WINCH   [20] => IGNORE
XCPU    [30] => TERMINATE 30
XFSZ    [31] => TERMINATE 159
XRES    [38] => IGNORE
ZERO    [] => IGNORE
__DIE__ [] => IGNORE
__WARN__ [] => IGNORE
