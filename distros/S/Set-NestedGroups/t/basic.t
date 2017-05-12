# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..9\n"; }
END {print "not ok $loaded\n" unless $loaded;}
use Set::NestedGroups;
$loaded = 1;
print "ok 1\n";
#
# New
$acl=new Set::NestedGroups;
print "ok 2\n";

# Add some data
$acl->add('joe','manager');
$acl->add('manager','hr');

# Some basic sanity checks
if($acl->member('joe')){
  print "ok 3\n";
} else {
  print "not ok 3\n";
}

unless($acl->member('jim')){
  print "ok 4\n";
} else {
  print "not ok 4\n";
}

if($acl->group('hr')){
  print "ok 5\n";
} else {
  print "not ok 5\n";
}

unless($acl->group('payroll')){
  print "ok 6\n";
} else {
  print "not ok 6\n";
}

# Check the recusion & stuff (I often seem to get this wrong when programming,
# so it's well worth testing)

# Directly belong to
@groups=$acl->groups('joe',-norecurse=>1);
if(@groups == 1 && $groups[0] eq "manager"){
  print "ok 7\n";
} else {
  print "not ok 7\n";
}

# Final groups only
@groups=$acl->groups('joe',-nomiddles=>1);
if(@groups == 1 && $groups[0] eq "hr"){
  print "ok 8\n";
} else {
  print "not ok 8\n";
}

# Both !
@groups=$acl->groups('joe');
if(@groups == 2 && join("",sort @groups) eq "hrmanager"){
  print "ok 9\n";
} else {
  print "not ok 9\n";
}
