#!/usr/bin/perl
# $Id$

use strict;
use Test::More tests => 45;
use FindBin qw($Bin);
use File::Path;
use File::Temp qw(tempdir);
use RPM4;
use RPM4::Transaction::Problems;

# Test on wrong db
RPM4::add_macro("_dbpath /dev/null");
ok(RPM4::rpmdbverify != 0, "Verify non existing database (get error)");

my $tempdir = tempdir();
my $testdir = "$tempdir/testdb";
mkdir $testdir || die $!;

RPM4::add_macro("_dbpath $testdir");

ok(RPM4::rpmdbinit == 0 || -f "$testdir/Packages", "initdb works");
ok(RPM4::rpmdbrebuild == 0, "rebuild database");
ok(RPM4::rpmdbverify == 0, "Verify empty");

my $ts;
ok($ts = RPM4::Transaction->new, "Open a new transaction");
ok($ts->traverse(sub { print STDERR $_[0]->tag(1000) . "\n" }) != -1, "ts->traverse");

ok($ts->importpubkey("$Bin/gnupg/test-key.gpg") == 0, "Importing a public key");

my $hd = RPM4::rpm2header("$Bin/test-dep-1.0-1mdk.noarch.rpm");
ok($hd, "Reading the header works");

ok($ts->transadd($hd, "$Bin/test-dep-1.0-1mdk.noarch.rpm") == 0, "Adding a package to transaction works");
ok($ts->transcheck == 0, "Checking transaction works");
ok($ts->transorder == 0, "Run transaction order");

if (0) {
my $pbs = RPM4::Transaction::Problems->new($ts);
isa_ok(
    $pbs,
    'RPM4::Db::Problems',
    'Can retrieve pb from transaction'
);

ok($pbs->count, "Can get number of problems");

ok($pbs->init || 1, "Resetting problems counter");
my $strpb;
while ($pbs->hasnext) {
    $strpb .= $pbs->problem;
}
ok($strpb, "Can get problem description");
}

ok(defined($ts->transflag([qw(TEST)])), "Set transflags");
#ok($ts->transrun([ qw(LABEL PERCENT) ]) == 0, "Running transaction justdb");
ok(!defined($ts->transreset), "Resetting transaction");

my $h = RPM4::rpm2header("$Bin/test-rpm-1.0-1mdk.noarch.rpm");
ok($h, "Reading the header works");

ok($ts->transadd($h, "$Bin/test-rpm-1.0-1mdk.noarch.rpm") == 0, "Adding a package to transaction works");
ok($ts->traverse_transaction(sub { 
    ok($_[0]->fullname, "Can get name from te");
    ok($_[0]->type, "Can get type from te");
}), "traverse_transaction works");

ok($ts->transcheck == 0, "Checking transaction works");
ok($ts->transorder == 0, "Run transaction order");

ok(defined($ts->transflag([qw(JUSTDB)])), "Set transflags");
ok($ts->transrun(sub { my %a = @_; print STDERR "$a{what} $a{amount} / $a{total}\n" }) == 0, "Running transaction justdb");

my $found = 0;
my $roffset;
ok($ts->traverse(sub {
        my ($hf, $offset) = @_;
        scalar($hf->fullname) eq "test-rpm-1.0-1mdk.noarch" and do {
            $found++;
            (undef, $roffset) = ($hf, $offset);
        };
        1;
    }), "Running traverse");

ok($found, "Can find header in db");

$ts = undef; # explicitely calling DESTROY to close database

ok($ts = RPM4::newdb(1), "Open existing database");
$found = 0;

$roffset = undef;
ok($ts->traverse(sub {
        my ($hf, $offset) = @_;
        scalar($hf->fullname) eq "test-rpm-1.0-1mdk.noarch" and do {
            $found++;
            (undef, $roffset) = ($hf, $offset);
        };
    }), "Running traverse");

ok($found == 1, "The previously installed rpm is found");
ok($roffset > 0, "Retrieve offset db");

ok($ts->transremove_pkg("test-rpm(1.0-1mdk)") == 1, "Try to remove a rpm");
ok($ts->transcheck == 0, "Checking transaction works");
ok(!defined($ts->transreset), "Reseting current transaction");

ok($ts->transremove($roffset), "Removing pkg from header and offset");
ok($ts->transorder == 0, "Run transaction order");
ok($ts->transcheck == 0, "Checking transaction works");
ok(defined($ts->transflag([qw(JUSTDB)])), "Set transflags");
#ok($ts->transrun([ qw(LABEL PERCENT) ]) == 0, "Running transaction justdb");

$found = 0;

ok($ts->traverse(sub {
        my ($hf, $offset) = @_;
        scalar($hf->fullname) eq "test-rpm-1.0-1mdk.noarch" and do {
            $found++;
            (undef, $roffset) = ($hf, $offset);
        };
    }), "Running traverse");

#ok($found == 0, "The previously removed rpm is not found");

ok($ts->transadd($h, "test-rpm-1.0-1mdk.noarch.rpm", 1, "/usr", 1) == 0, "Adding a package to transaction with prefix");
ok($ts->transorder == 0, "Run transaction order");
ok($ts->transcheck == 0, "Checking transaction works");
ok(!defined($ts->transreset), "Reseting current transaction");

ok($ts->transadd($h, "test-rpm-1.0-1mdk.noarch.rpm", 1, {"/etc" => "/usr" }, 1) == 0, "Adding a package to transaction with relocation works");
ok($ts->transorder == 0, "Run transaction order");
ok($ts->transcheck == 0, "Checking transaction works");
ok(!defined($ts->transreset), "Reseting current transaction");

{
my $spec = $ts->newspec("$Bin/test-rpm.spec");
isa_ok($spec, 'RPM4::Spec', 'ts->newspec');
}

$ts = undef; # explicitely calling DESTROY to close database
rmtree($tempdir);
