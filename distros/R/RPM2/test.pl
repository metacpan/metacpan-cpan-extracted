#!/usr/bin/perl -w
use strict;

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';
# comment to test checkin

use Test;
use strict;
BEGIN { plan tests => 62 };
use RPM2;
use POSIX;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

ok(RPM2::rpmvercmp("1.0", "1.1") == -1);
ok(RPM2::rpmvercmp("1.1", "1.0") == 1);
ok(RPM2::rpmvercmp("1.0", "1.0") == 0);

# UPDATE: the vercmp bug was finally fixed, and broke this test, heh
#  this is a bug case in rpmvervmp; good one for testing
#  ok(RPM2::rpmvercmp("1.a", "1.0") == RPM2::rpmvercmp("1.0", "1.a"));

my $db = RPM2->open_rpm_db();
ok(defined $db);

my @pkg;
my $i = $db->find_all_iter();

ok($i);
while (my $pkg = $i->next) {
  push @pkg, $pkg;
}

ok(@pkg);
ok($pkg[0]->name);

@pkg = ();
$i = $db->find_by_name_iter("filesystem");
ok($i);
while (my $pkg = $i->next) {
  push @pkg, $pkg;
}
if (@pkg) {
  ok($pkg[0]->name);
} else {
  skip('package filesystem not installed');
}

@pkg = ();

$i = $db->find_by_provides_iter("filesystem");
ok($i);
while (my $pkg = $i->next) {
  push @pkg, $pkg;
}
if (@pkg) {
  ok($pkg[0]->name);
} else {
  skip('package providing filesystem not installed');
}

@pkg = ();
foreach my $pkg ($db->find_by_file("/bin/sh")) {
  push @pkg, $pkg;
}
if (@pkg) {
  ok($pkg[0]->name);
} else {
  skip('package with /bin/sh not installed');
}

@pkg = ();
foreach my $pkg ($db->find_by_requires("/bin/bash")) {
  push @pkg, $pkg;
}
if (@pkg) {
  ok($pkg[0]->name);
  ok(not defined $pkg[0]->filename);
} else {
  for (1..2) { skip('no package requiring /bin/bash installed') }
}

my $pkg = RPM2->open_package("test-rpm-1.0-1.noarch.rpm");
ok($pkg);
ok($pkg->name eq 'test-rpm');
ok($pkg->tagformat("--%{NAME}%{VERSION}--") eq '--test-rpm1.0--');
ok($pkg->tagformat("--%{NAME}%{VERSION}--") ne 'NOT A MATCH');
ok(!$pkg->is_source_package);

my @cl = $pkg->changelog();
ok(scalar(@cl) == 1);
ok($cl[0]->{time} == 1018735200); # Sun Apr 14 2002
ok($cl[0]->{name} eq 'Chip Turner <cturner@localhost.localdomain>');
ok($cl[0]->{text} eq '- Initial build.');


$pkg = RPM2->open_package("test-rpm-1.0-1.src.rpm");
ok($pkg);
ok($pkg->name eq 'test-rpm');
ok($pkg->tagformat("--%{NAME}--") eq '--test-rpm--');
ok($pkg->is_source_package);

my $pkg2 = RPM2->open_package("test-rpm-1.0-1.noarch.rpm");
ok($pkg2->filename);
ok($pkg->compare($pkg2) == 0);
ok(($pkg <=> $pkg2) == 0);
ok(!($pkg < $pkg2));
ok(!($pkg > $pkg2));

my $other_rpm_dir = getcwd() . '/rpmdb';
# another rpm, handily provided by the rpmdb-redhat package
# ... is no longer shipped. Create a new one:
system( "rm -rf rpmdb; mkdir rpmdb; /usr/bin/rpmdb --dbpath $other_rpm_dir --initdb" );
my $db2 = RPM2->open_rpm_db(-path => $other_rpm_dir);
ok(defined $db2);
$db2 = undef;

ok(RPM2->expand_macro("%%foo") eq "%foo");
RPM2->add_macro("rpm2_test_macro", "testval $$");
ok(RPM2->expand_macro("%rpm2_test_macro") eq "testval $$");
RPM2->delete_macro("rpm2_test_macro");
ok(RPM2->expand_macro("%rpm2_test_macro") eq "%rpm2_test_macro");

ok(RPM2->rpm_api_version =~ /4.\d+/);

#
# Clean up before transaction tests (close the database
$db  = undef;
$i   = undef;

#
# Transaction tests.
my $t = RPM2->create_transaction();
ok(ref($t) eq 'RPM2::Transaction');
ok(ref($t) eq 'RPM2::Transaction');
$pkg = RPM2->open_package("test-rpm-1.0-1.noarch.rpm");
# Make sure we still can open packages.
ok($pkg);
# Add package to transaction
ok($t->add_install($pkg));
# Check element count
ok($t->element_count() == 1);
# Test depedency checks
ok($t->check());
# Order the transaction...see if we get our one transaction.
ok($t->order());
my @rpms = $t->elements();
ok($rpms[0] eq  $pkg->as_nvre());
ok(scalar(@rpms) == 1);
skip( ( $< == 0 ) ? undef : ': must be root to create RPM transaction.',  ( $< == 0 ) ? $t->run() : undef );
$t = undef;
# See if we can find the rpm in the database now...
$db = RPM2->open_rpm_db();
ok(defined $db);
@pkg = ();
$i = $db->find_by_name_iter("test-rpm");
ok($i);
while (my $pkg = $i->next) {
  push @pkg, $pkg;
}
skip( ( $< == 0 ) ? undef : ': package not added as not root.',  ( $< == 0 ) ? scalar(@pkg) == 1 : undef );
$i  = undef;
$db = undef;

#
# OK, lets remove that rpm with a new transaction
$t = RPM2->create_transaction();
ok(ref($t) eq 'RPM2::Transaction');
# We need to find the package we installed, and try to erase it
skip( ( $< == 0 ) ? undef : ': package not erased as not root.', ( $< == 0 ) ? $t->add_erase($pkg[0]) : undef );
# Check element count
skip( ( $< == 0 ) ? undef : ': no transaction as not root.', ( $< == 0 ) ? ($t->element_count() == 1) : undef );
# Test depedency checks
ok($t->check());
# Order the transaction...see if we get our one transaction.
ok($t->order());
#my @rpms = $t->elements();
ok($rpms[0] eq  $pkg->as_nvre());
ok(scalar(@rpms) == 1);
# Install package
skip( ( $< == 0 ) ? undef : ': cannot run RPM transaction as not root.', ( $< == 0 ) ? $t->run() : undef );
# Test closing the database
ok($t->close_db());

my @headers = RPM2->open_hdlist("hdlist-test.hdr");
ok(scalar @headers, 3, 'found three headers in hdlist-test.hdr');
ok(grep { $_->tag('name') eq 'mod_perl' } @headers);
