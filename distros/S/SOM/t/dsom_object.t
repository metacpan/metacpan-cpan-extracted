#!/usr/bin/perl
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..30\n"; }
END {print "not ok 1\n" unless $loaded;}

use SOM ':types', ':class', ':dsom', ':environment';

$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

$daemonUp = IsSOMDDReady();
print "ok 2\n";

# RestartSOMDD(1) or die "Could not restart SOMDD: $^E" unless $daemonUp;
Ensure_SOMDD_Up(100,0,1);				# Verbose
print "ok 3\n";

die "Daemon did not start, when reported as started" unless IsSOMDDReady();
print "ok 4\n";

$serverUp = IsWPDServerReady();

$daemonUp = $serverUp = 1 unless $ENV{PERLTEST_SHUTDOWN_SERVERS};

$server = eval {Ensure_WPDServer_Up(100,0,1), 1};	# Verbose
print "not " unless $server;
print "ok 5\n";

($daemonUp or Ensure_SOMDD_Down(100,1)), exit
  unless $server;		# Verbose

# Will it help here?  No...
print "# 10-sec sleep...\n" unless $serverUp;
sleep 10 unless $serverUp;

$ev = SOM::CreateLocalEnvironment();
print "not " unless $ev;
print "ok 6\n";

SOM::SOMDeamon::Init($ev);
print "ok 7\n";

sub EnvironmentPtr::CheckAndWarn {
  my $err; $err = $ev->Check and warn "Got exception $err";
  !$err
}

$ev->CheckAndWarn or print "not ";
print "ok 8\n";

$SOM_ClassMgr = SOM::SOMDeamon::ClassMgrObject() or print "not ";
print "ok 9\n";
$WPS_ClassMgr = SOM::SOMDeamon::WPClassManagerNew() or print "not ";
print "ok 10\n";

$SOM_ClassMgr->MergeInto($WPS_ClassMgr); # In fact opposite direction
print "ok 11\n";

# Init_WP_Classes();		# Otherwise cannot GetClassObj('WPFolder')
print "ok 12\n";

$server = SOM::SOMDeamon::ObjectMgr->FindServerByName($ev, "wpdServer")
  or print "not ";
print "ok 13\n";

$ev->CheckAndWarn or print "not ";
print "ok 14\n";

$classObj = $server->GetClassObj($ev, "SOMObject")
  or print "not ";
print "ok 15\n";

$ev->CheckAndWarn or print "not ";
print "ok 16\n";

sub make_template_oidl {
  join '', 'o', map chr(33 + $_), @_;
}

# XXXX	Here is the fragile place.  If we do not put this delay, then
#	we time out during this call, and eventually segfault...

# No, it does not help the second time in the row...
#sleep 5 unless $serverUp;

$classObj and $obj1 = $classObj->NewObject;
print "not " unless $obj1;

print "ok 17\n";

print "not " unless $obj1 and $obj1->GetClassName eq "SOMObject";

print "ok 18\n";
print "# Name: '", ($obj1 and $obj1->GetClassName), "'.\n";

print "ok $_\n" for 19..22;

# sleep 2;			# Otherwise Server would not yet start?

SOM::SOMDeamon::ObjectMgr->ReleaseObject($ev, $server);
print "ok 23\n";

$ev->CheckAndWarn or print "not ";
print "ok 24\n";

SOM::SOMDeamon::Uninit($ev);
print "ok 25\n";

# $ev->CheckAndWarn or print "not ";
print "ok 26\n";

Ensure_WPDServer_Down(100,1) unless $serverUp;		# Verbose
#RestartWPDServer(0) or print "# Could not shutdown WPDServer: $^E\nnot "
#  unless $serverUp;
print "ok 27\n";

Ensure_SOMDD_Down(100,1) unless $daemonUp;		# Verbose
print "ok 28\n";
print "ok 29\n";
print "ok 30\n";


