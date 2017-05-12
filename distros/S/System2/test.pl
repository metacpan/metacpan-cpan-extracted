# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..4\n"; }
END {print "not ok 1\n" unless $loaded;}
use POSIX;
use System2;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

use strict;

if (0)
{
  print "testing $System2::VERSION\n";
  $System2::debug++;
  print "debug is $System2::debug\n";
}

my $tmpout = POSIX::tmpnam();
my $tmperr = POSIX::tmpnam();

# Run some deterministic program to generate stdout as well as stderr
# (We're going to run this twice, and the results have to match,
# so no time-dependant code).  (Foolish people might run this as
# root, so try to keep this nondestructive.)

my @command = qw( perl -w ./io_test.pl);

# run it once via system(), isolating STDOUT and STDERR into separate files
my @system_wrap = ( 'sh', '-c', "( ".  join(' ', @command).
	            " > $tmpout ) > $tmperr 2>&1");
system ( @system_wrap );
my $stat = $?;

# read the results into scalars; clean up
my ($Out, $Err);
open(TMP, $tmpout); while(<TMP>) { $Out .= $_ } close TMP;
open(TMP, $tmperr); while(<TMP>) { $Err .= $_ } close TMP;
unlink $tmpout, $tmperr;

# run that same command, this time via system2()
my ($out, $err) = system2(@command);
my $Stat = $?; 

# and compare.  this will make sure that we didn't lose any output.
if ($Stat eq $stat) { print "ok 2\n"; } else { print "not ok 2\n"; }
if ($Out eq $out) { print "ok 3\n"; } else { print "not ok 3\n"; }
if ($Err eq $err) { print "ok 4\n"; } else { print "not ok 4\n"; }
