# $Id: test.pl,v 1.5 1999/01/07 19:21:37 carrigad Exp $

# Copyright (C), 1998, 1999 Enbridge Inc.

BEGIN { $| = 1; }
END {print "not ok 1\n" unless $loaded;}
eval "use Data::Dumper;";
if ($@) {
  sub Dumper {""};
}

use SecurID::ACEdb qw(:all);
$loaded = 1;
eval 'require ".testparms"';
getparms();

my $verbose = $ENV{TEST_VERBOSE} == 1;

printf "%-26s%s", "Load module...", "ok 1\n";

printf "%-26s", "ApiInit...";
if (!ApiInit("commitFlag" => 1)) {
  print "not ok 2\n";
  exit 1;
}
$tn = 2;
print "ok ", $tn++, "\n";

printf "%-26s", "ApiRev...";
$rev = ApiRev();

print "not " unless defined $rev;
print "ok ", $tn++, "\n";

print STDERR "ACE Admin API revision is $rev\n" if $verbose;

printf "%-26s", "ListTokens...";
@tokens = ListTokens();
if (!@tokens) {
  print STDERR Result(), "\n" if $verbose;
  print "not ";
  
}
print "ok ", $tn++, "\n";

if ($testtoken ne "") {
  printf "%-26s", "AssignToken...";
  if (!AssignToken($fname, $lname, $uid, "/bin/sh", $testtoken)) {
    print STDERR Result(), "\n" if $verbose;
    print "not ";
  }
  print "ok ", $tn++, "\n";
} else {
  printf "%-26s%s", "AssignToken...", "skipped\n";
}

$luitok = $testtoken eq ""? $realtoken : $testtoken;
if ($luitok ne "") {
  printf "%-26s", "ListUserInfo...";
  if ($userinfo = ListUserInfo($luitok)) {
    print STDERR Dumper($userinfo) if $verbose;
  } else {
    print STDERR Result(), "\n" if $verbose;
    print "not ";
  }
  print "ok ", $tn++, "\n";
} else {
  printf "%-26s%s", "ListUserInfo...", "skipped\n";
}

if ($testtoken ne "") {
  printf "%-26s", "SetUser...";
  if (!SetUser($lname, $fname, 
			 $userinfo->{defaultLogin}, $userinfo->{defaultShell},
			 $testtoken)) {
    print STDERR Result(), "\n" if $verbose;
    print "not ";
  }
  print "ok ", $tn++, "\n";

  printf "%-26s", "SetCreatePin...";
  if (!SetCreatePin("SYSTEM", $testtoken)) {
    print STDERR Result(), "\n" if $verbose;
    print "not ";
  }
  print "ok ", $tn++, "\n";

  $userinfo = ListUserInfo($testtoken);
  print STDERR Dumper($userinfo) if $verbose;

  printf "%-26s", "AddUserExtension...";
  if (!AddUserExtension("ext", "extension data", $testtoken)) {
    print STDERR Result(), "\n" if $verbose;
    print "not ";
  }
  print "ok ", $tn++, "\n";

  printf "%-26s", "ListUserExtension...";
  $ed = ListUserExtension("ext", $testtoken);
  if (defined $ed) {
    print "not " unless $ed eq "extension data";
  } else {
    print STDERR Result(), "\n" if $verbose;
    print "not ";
  }
  print "ok ", $tn++, "\n";

  printf "%-26s", "SetUserExtension...";
  if (SetUserExtension("ext", "new data", $testtoken)) {
    $ed = ListUserExtension("ext", $testtoken);
    if (defined $ed) {
      print "not " unless $ed eq "new data";
    } else {
      print STDERR Result(), "\n" if $verbose;
      print "not ";
    }
    print "ok ", $tn++, "\n";
  } else {
    print STDERR Result(), "\n" if $verbose;
    print "not ok ", $tn++, "\n";
  }

  printf "%-26s", "DelUserExtension...";
  if (DelUserExtension("ext", $testtoken)) {
    $ed = ListUserExtension("ext", $testtoken);
    print "not " if defined $ed;
    print "ok ", $tn++, "\n";
  } else {
    print STDERR Result(), "\n" if $verbose;
    print "not ok", $tn++, "\n";
  }

  printf "%-26s", "DisableToken...";
  if (!DisableToken($testtoken)) {
    print STDERR Result(), "\n" if $verbose;
    print "not ";
  }
  print "ok ", $tn++, "\n";

  printf "%-26s", "EnableToken...";
  if (!EnableToken($testtoken)) {
    print STDERR Result(), "\n" if $verbose;
    print "not ";
  }
  print "ok ", $tn++, "\n";

  printf "%-26s", "ResetToken...";
  if (!ResetToken($testtoken)) {
    print STDERR Result(), "\n" if $verbose;
    print "not ";
  }
  print "ok ", $tn++, "\n";

  printf "%-26s", "NewPin...";
  if (!NewPin($testtoken)) {
    print STDERR Result(), "\n" if $verbose;
    print "not ";
  }
  print "ok ", $tn++, "\n";

  printf "%-26s", "ListTokenInfo...";
  $tokeninfo = ListTokenInfo($testtoken);
  if (defined $tokeninfo) {
    print STDERR Dumper($tokeninfo) if $verbose;
  } else {
    print STDERR Result(), "\n" if $verbose;
    print "not ";
  }
  print "ok ", $tn++, "\n";

  printf "%-26s", "ListSerialByLogin...";
  $serial = ListSerialByLogin($uid);
  if (!defined $serial) {
    print STDERR Result(), "\n" if $verbose;
    print "not ";
  } else {
    print "not " unless sprintf("%012d", $testtoken) eq $serial->[0];
  }
  print "ok ", $tn++, "\n";
} else {
  printf "%-26s%s", "SetUser...", "skipped\n";
  printf "%-26s%s", "SetCreatePin...", "skipped\n";
  printf "%-26s%s", "AddUserExtension...", "skipped\n";
  printf "%-26s%s", "ListUserExtension...", "skipped\n";
  printf "%-26s%s", "SetUserExtension...", "skipped\n";
  printf "%-26s%s", "DelUserExtension...", "skipped\n";
  printf "%-26s%s", "DisableToken...", "skipped\n";
  printf "%-26s%s", "EnableToken...", "skipped\n";
  printf "%-26s%s", "ResetToken...", "skipped\n";
  printf "%-26s%s", "NewPin...", "skipped\n";
  printf "%-26s%s", "ListTokenInfo...", "skipped\n";
  printf "%-26s%s", "ListSerialByLogin...", "skipped\n";
}

printf "%-26s", "ListGroups...";
$groups = ListGroups();
if (!defined $groups) {
  print STDERR Result(), "\n" if $verbose;
  print "not ";
}
print "ok ", $tn++, "\n";
print STDERR Dumper($groups) if $verbose;

$tstgrp = $groups->[0]->{group};

printf "%-26s", "ListClients...";
$clients = ListClients();
if (!defined $clients) {
  print STDERR Result(), "\n" if $verbose;
  print "not ";
}
print "ok ", $tn++, "\n";
print STDERR Dumper($clients) if $verbose;

$tstclnt = $clients->[0]->{clientName};

if ($testtoken ne "") {
  printf "%-26s", "AddLoginToGroup...";
  if (!AddLoginToGroup($uid, $tstgrp, 
				 $userinfo->{defaultShell}, 
				 $testtoken)) {
    print STDERR Result(), "\n" if $verbose;
    print "not ";
  }
  print "ok ", $tn++, "\n";

  printf "%-26s", "ListGroupMembership...";
  if ($gm = ListGroupMembership($testtoken)) {
    print "not " unless $gm->[0]->{group} eq $tstgrp;
  } else {
    print STDERR Result(), "\n" if $verbose;
    print "not ";
  }
  print "ok ", $tn++, "\n";

  printf "%-26s", "DelLoginFromGroup...";
  if (!DelLoginFromGroup($uid, $tstgrp)) {
    print STDERR Result(), "\n" if $verbose;
    print "not ";
  }
  print "ok ", $tn++, "\n";

  printf "%-26s", "EnableLoginOnClient...";
  if (!EnableLoginOnClient($uid, $tstclnt,
				     $userinfo->{defaultShell}, 
				     $testtoken)) {
    print STDERR Result(), "\n" if $verbose;
    print "not ";
  }
  print "ok ", $tn++, "\n";

  printf "%-26s", "ListClientActivations...";
  if ($gm = ListClientActivations($testtoken)) {
    print "not " unless $gm->[0]->{clientName} eq $tstclnt;
  } else {
    print STDERR Result(), "\n" if $verbose;
    print "not ";
  }
  print "ok ", $tn++, "\n";

  printf "%-26s", "DelLoginFromClient...";
  if (!DelLoginFromClient($uid, $tstclnt)) {
    print STDERR Result(), "\n" if $verbose;
    print "not ";
  }
  print "ok ", $tn++, "\n";
} else {
  printf "%-26s%s", "AddLoginToGroup...", "skipped\n";
  printf "%-26s%s", "ListGroupMembership...", "skipped\n";
  printf "%-26s%s", "DelLoginFromGroup...", "skipped\n";
  printf "%-26s%s", "EnableLoginOnClient...", "skipped\n";
  printf "%-26s%s", "ListClientActivations...", "skipped\n";
  printf "%-26s%s", "DelLoginFromClient...", "skipped\n";
}

printf "%-26s", "ListClientsForGroup...";
$grcllist = ListClientsForGroup($tstgrp);
if (!defined $grcllist) {
  print STDERR Result(), "\n" if $verbose;
  print "not ";
}
print "ok ", $tn++, "\n";
print STDERR Dumper($grcllist) if $verbose;

my $lhtok = $testtoken eq ""? $realtoken : $testtoken;
if ($lhtok ne "") {
  printf "%-26s", "ListHistory...";
  $hist= ListHistory(999, $lhtok);
  if (!defined $hist) {
    print STDERR Result(), "\n" if $verbose;
    print "not ";
  }
  print "ok ", $tn++, "\n";
} else {
  printf "%-26s%s", "ListHistory...", "skipped\n";
}

if ($testtoken ne "") {
  printf "%-26s", "UnassignToken...";
  if (!UnassignToken($testtoken)) {
    print STDERR Result(), "\n" if $verbose;
    print "not ";
  }
  print "ok ", $tn++, "\n";
} else {
  printf "%-26s%s", "UnassignToken...", "skipped\n";
}

sub getparms {
  my $ans;

  print "\nI need some information before I can run the tests\n";
  print "Enter the serial number of an unused token for user creation \n";
  print "tests (or NONE to disable test)";
  print " [$testtoken]" if $testtoken ne "";
  print ": ";
  $ans = <>; chomp $ans;
  $testtoken = $ans unless $ans eq "";
  $testtoken = "" if $ans eq "NONE";

  if ($testtoken ne "") {
    print "Enter a dummy userid";
    print " [$uid]" if $uid ne "";
    print ": ";
    $ans = <>; chomp $ans;
    $uid = $ans unless $ans eq "";

    print "Enter a dummy first name";
    print " [$fname]" if $fname ne "";
    print ": ";
    $ans = <>; chomp $ans;
    $fname = $ans unless $ans eq "";
    
    print "And a dummy last name";
    print " [$lname]" if $lname ne "";
    print ": ";
    $ans = <>; chomp $ans;
    $lname = $ans unless $ans eq "";
  } else {
    print "Enter the serial number of an assigned token for read-only tests";
    print " [$realtoken]" if $realtoken ne "";
    print ": ";
    $ans = <>; chomp $ans;
    $realtoken = $ans unless $ans eq "";
  }

  if (open(TP, ">.testparms")) {
    print TP "\$testtoken = \"$testtoken\";\n";
    print TP "\$realtoken = \"$realtoken\";\n";
    print TP "\$uid = \"$uid\";\n";
    print TP "\$fname = \"$fname\";\n";
    print TP "\$lname = \"$lname\";\n";
    close TP;
  } else {
    warn "Counldn't save test parameters to .testparms: $!\n";
  }
  print "Thankyou.\n\n";
}
