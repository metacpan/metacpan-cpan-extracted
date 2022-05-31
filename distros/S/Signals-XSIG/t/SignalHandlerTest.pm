# t::SignalHandlerTest
# some global routines to help the testing of
# Signals::XSIG.
##################################################

package t::SignalHandlerTest;
use Exporter;
use Config;
use strict;
use warnings;
our @ISA = qw(Exporter);
our @EXPORT = qw(trigger appropriate_signals alias_pair
    real_sig_handler xsig_sigaction);

my @no = split ' ', $Config{sig_num};
my @name = split ' ', $Config{sig_name};

# returns some signal names that are appropriate for testing
# on this platform
sub appropriate_signals {
    if (wantarray) {
	if ($^O eq "MSWin32") {
	    return qw(INT QUIT);
	} elsif ($^O eq 'freebsd') {
	    # are USR1, USR2 not available on freebsd sometimes?
	    return qw(USR1 USR2);
	} else {
	    return qw(USR1 USR2);
	}
    } else {
	if ($^O eq 'MSWin32') {
	    return 'INT';
	} else {
	    return 'USR1';
	}
    }
}

# returns a pair of aliased signal names (like CLD and CHLD)
# that is appropriate for this platform
sub alias_pair {
    my @seen = ();
    for (my $i=0; $i<@no; $i++) {
	if ($seen[$no[$i]]) {
	    return ($seen[$no[$i]], $name[$i]);
	} else {
	    $seen[$no[$i]] = $name[$i];
	}
    }
}

# raise a signal, trying to be platform-independent
sub trigger ($) {
    my ($signal) = @_;
    if ($^O eq "MSWin32" && $signal eq "ALRM") {
	if (0 && $Config{PERL_VERSION} <= 8) {
	    # is there a way to trigger a signal handler,
	    # any signal handler, on Strawberry 5.8?

	    # sleep, alarm may be incompatible
	    my $j=0;
	    my $t = time + 2;
	    alarm 1;
	    while (time < $t) {
		$j += rand() - 0.5;
	    }
	} elsif (eval { require Time::HiRes; Time::HiRes::alarm(0); 1 }) {
	    Time::HiRes::alarm(0.25);
	    Time::HiRes::sleep(0.75);
	    Time::HiRes::alarm(0);
	} else {
	    alarm 1;
	    sleep 2;
	    alarm 0;
	}
    } else {
	kill $signal, $$;
    }
    sleep 2 if $^O eq 'MSWin32';
}

sub real_sig_handler {
    # returns the "shadow" signal handler installed by Signals::XSIG
    # this is actually invoked when a signal is trapped.
    return $Signals::XSIG::OSIG{$_[0]};
}

sub xsig_sigaction {
    # returns the shadow signal handler associated with a signal
    return $Signals::XSIG::ZSIG{$_[0]} &&
	$Signals::XSIG::ZSIG{$_[0]}{sigacshun};
}

1;
