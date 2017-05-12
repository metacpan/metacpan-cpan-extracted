use lib qw(blib/lib blib/arch);
use Sys::CpuAffinity;
use Test::More tests => 2;
use Math::BigInt;
use strict qw(vars subs);
use warnings;
$| = 1;

sub TWO () { goto &Sys::CpuAffinity::TWO }

#
# Exercise all of the methods in the toolbox to
# count processors on the system, get cpu affinity,
# and set cpu affinity. 
#
# Generally each tool is targeted to work on a
# single system. Since most of the tools are
# targeted at a different system than yours,
# most of these tools will fail on your system.
#
# Among the tools that are targeted to your
# system, some of them will depend on certain
# Perl modules or certain external programs
# being available, so those tools might also
# fail on your system.
#
# Hopefully, we'll find at least one tool for
# each task (count cpus, get affinity, set
# affinity) that will work for you, which is
# all we need.
#

my $pid = $$;
$Sys::CpuAffinity::IS_TEST = 1;

#########################################################
#
# get inventory of all Sys::CpuAffinity techniques 
# from the Sys::CpuAffinity source code.
#
# XXX - could also inspect %Sys::CpuAffinity:: symbol table.
#
#########################################################

{
    my (@SET, @GET, @NCPUS);

    open my $source, '<', $INC{"Sys/CpuAffinity.pm"}
      or die "failed to load Sys::CpuAffinity source. $!\n";
    while (<$source>) {
	next unless /^sub _/;
	next if /XXX/;         # method still under development
	if (/^sub _setAffinity_with_(\S+)/) {
	    push @SET, $1;
	} elsif (/^sub _getAffinity_with_(\S+)/) {
	    push @GET, $1;
	} elsif (/^sub _getNumCpus_from_(\S+)/) {
	    push @NCPUS, $1;
	}
    }
    close $source;

    sub inventory::getAffinity { sort { lc $a cmp lc $b } @GET }
    sub inventory::setAffinity { sort { lc $a cmp lc $b } @SET }
    sub inventory::getNumCpus { sort { lc $a cmp lc $b } @NCPUS }
}


select STDERR;

print "\n\n";

EXERCISE_COUNT_NCPUS();

my $n = Sys::CpuAffinity::getNumCpus();
if ($n <= 1) {
  SKIP: {
      if ($n == 1) {
	  skip "affinity exercise. Only one processor on this system", 2;
      } else {
	  skip "affinity exercise. Can't detect number of processors", 2;
      }
    }
    exit 0;
}

EXERCISE_GET_AFFINITY();
EXERCISE_SET_AFFINITY();
sleep 1;
ok(1);


# call all of the getAffinity_with_XXX methods
# method is successful if
#    at least one method returns > 0
#    all methods that return > 0 return the same value
sub EXERCISE_GET_AFFINITY {

    my $ok = 0;

    print "===============================================\n";

    print "Current affinity = \n";
    
    my $success = 0;
    for my $s (inventory::getAffinity()) {
	my $sub = 'Sys::CpuAffinity::_getAffinity_with_' . $s;
	printf "    %-30s ==> ", $s;
	my $z = eval { $sub->($pid) };
	printf "%s\n", $z || 0;
	$success += ($z||0) > 0;

	if ($z && $z > 0) {
	    if ($ok == 0) {
		$ok = $z;
	    } elsif ($ok != $z) {
		$ok = -1;
	    }
	}
    }

    if ($success == 0) {
      recommend($^O, 'getAffinity');
    }
    print "\n\n";
  SKIP: {
      if ($ok == 0 && $^O =~ /darwin|MacOS|openbsd/i) {
          skip "getAffinity/setAffinity not expected to be supported on $^O", 1;
      }
      ok($ok > 0, "at least one _getAffinity_XXX method works and "
         . "all other methods are consistent");
    }
}

#
# call all of the _getNumCpus_from_XXX functions.
# Passes if
#    at least one methods returns > 0
#    all methods that return > 0 return the same value
#
sub EXERCISE_COUNT_NCPUS {

    local $Sys::CpuAffinity::DEBUG = $ENV{DEBUG} || 0;
    if ($^O =~ /openbsd/i || $^O =~ /darwin/i) {
        $Sys::CpuAffinity::DEBUG = 1;
    }

    print "=================================================\n";

    print "Num processors =\n";

    my $ok = 0;

    for my $technique (inventory::getNumCpus()) {
	my $s = 'Sys::CpuAffinity::_getNumCpus_from_' . $technique;

	printf "    %-30s ", $technique;
	my $ncpus = eval { $s->() } || 0;
	printf "- %s -\n", $ncpus;

	if ($ncpus > 0) {
	    if ($ok eq 0) {
		$ok = $ncpus;
	    } elsif ($ok ne $ncpus) {
		$ok = -1;
	    }
	}
    }

    print "\n\n";
#    ok($ok > 0, "at least one _getNumCpus_XXX method works and "
#                . "all other methods are consistent");
}

#
# call each of the _setAffinity_with_XXX methods.
# passes if at least one method works
#
sub EXERCISE_SET_AFFINITY {

    print "==================================================\n";


    my $np = Sys::CpuAffinity::getNumCpus();
    if ($np <= 1) {
      SKIP: {
#	  skip "skip set affinity test on single-processor sys", 1;
	  1;
	}
	return 0;
    }
    my $ok = 0;

    my ($TARGET,$LAST_TARGET) = (0,0);
    my @mask = ();
    my $_2_np_1 = TWO ** $np - 1;
    my $nc = $np > 10 ? 10 : $np;
    while (@mask < 100) {
        $TARGET = 0;
        for my $i (0 .. @mask) {
            my $c = int(rand() * $np);
            $TARGET ^= TWO ** $c;
        }
        redo if $TARGET == 0;
        redo if $TARGET == $LAST_TARGET && $np > 1;
        $LAST_TARGET = $TARGET;
	push @mask, $TARGET;
    }

    # print "@mask\n";
    my $success = 0;

    print "Set affinity =\n";

    for my $technique (inventory::setAffinity()) {
	my $rr = Sys::CpuAffinity::getAffinity($pid) || 0;
	if ($rr == 0) {
	  printf "   %-30s => %s ==> FAIL\n", $technique,
	    "no affinity";
	  next;
	}
	my $mask;
	do {
	    $mask = shift @mask;
	} while $mask == $rr;

	my $s = "Sys::CpuAffinity::_setAffinity_with_$technique";
	eval { $s->($pid,$mask) };
	printf "    %-30s => %3s ==> ", $technique, $mask;
	my $r = Sys::CpuAffinity::getAffinity($pid);
	my $result = $r==$rr ? "FAIL" : " ok ";
	if ($r != $rr) {
	  $success++;
	}
	printf "%3s   [%s]\n", $r, $result;
    }

    if ($success == 0) {
      recommend($^O, 'setAffinity');
    }

    print "\n\n";
#    ok($success != 0, "at least one _setAffinity_XXX method works");
}

sub recommend {
    use Config;

    my ($sys, $function) = @_;

    print "\n\n==========================================\n\n";
    print "The function 'Sys::CpuAffinity::$function' does\n";
    print "not seem to work on this system.\n\n";

    my @recommendations;
    if ($Config{"cc"}) {
	@recommendations = ("install a C compiler (preferrably $Config{cc})");
    } else {
	@recommendations = ("install a C compiler");
    }

    if ($sys eq 'cygwin') {
	push @recommendations, "install the  Win32  module";
	push @recommendations, "install the  Win32::API  module";
	push @recommendations, "install the  Win32::Process  module";
    } elsif ($sys eq 'MSWin32') {
	push @recommendations, "install the  Win32  module";
	push @recommendations, "install the  Win32::API  module";
	push @recommendations, "install the  Win32::Process  module";
    } elsif ($sys =~ /openbsd/i) {
	@recommendations = ();
	print "OpenBSD does not provide (as far as I can tell)\n";
	print "a way to manipulate the CPU affinities of processes.\n";
	print "\n\n==========================================\n\n\n";
	return;
    } elsif ($sys =~ /netbsd/i) {

	if ($> != 0) {
	    push @recommendations, "run as super-user";
	    push @recommendations, 
	    	"\t(the available methods for manipulating CPU affinities "
		    . "on NetBSD only work for super-user)";
	}

    } elsif ($sys =~ /freebsd/i) {
	push @recommendations, "install the  BSD::Process::Affinity  module";
	push @recommendations, "make sure the  cpuset  program is in the PATH";
    } elsif ($sys =~ /solaris/i) {
	push @recommendations, "make sure the  pbind  program is in the PATH";
    } elsif ($sys =~ /irix/i) {
	# still need to learn to use the  cpuset_XXX  functions
    } elsif ($sys =~ /darwin/i || $sys =~ /MacOS/i) {
	@recommendations = ();
	print "The Mac OS does not provide (as far as I can tell)\n";
	print "a way to manipulate the CPU affinities of processes.\n";
	print "\n\n==========================================\n\n\n";
	return;
    } elsif ($sys =~ /aix/i) {
	push @recommendations, 
		"make sure the  bindprocessor  program is in the PATH";
    } else {
	push @recommendations, 
      "don't know what else to recommend for system $sys";
    }

    if (@recommendations > 0) {
	print "To make this module work, you may want to install:\n\n";
	foreach (@recommendations) {
	    print "\t$_\n";
	}
	print "\n\n";
	print "If these recommendations do not help, drop a note\n";
	print "to mob\@cpan.org with details about your\n";
	print "system configuration.\n";
    }

    print "\n\n==========================================\n\n\n";
}
