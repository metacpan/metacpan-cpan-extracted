#!/usr/bin/perl
# $Id$

use strict;
use Test::More;
use FindBin qw($Bin);
use File::Path;
use File::Temp qw(tempdir);
use RPM4;
use RPM4::Transaction::Problems;

if (-e '/etc/debian_version' || `uname -a` =~ /BSD/i) {
    plan skip_all => "*BSD/Debian/Ubuntu do not have a system wide rpmdb";
}

# For debugging:
#RPM4::setverbosity('DEBUG');

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
ok($ts = RPM4::Transaction->new, "Create a new transaction");
ok($ts->traverse(sub { print STDERR $_[0]->tag(1000) . "\n" }) != -1, "ts->traverse");

ok($ts->importpubkey("$Bin/gnupg/test-key.gpg") == 0, "Importing a public key");

my $hd = RPM4::rpm2header("$Bin/test-dep-1.0-1mdk.noarch.rpm");
ok($hd, "Reading the header works");

ok($ts->transadd($hd, "$Bin/test-dep-1.0-1mdk.noarch.rpm") == 0, "Adding a package to transaction works");
ok($ts->transcheck == 0, "Checking transaction works");
ok($ts->transorder == 0, "Run transaction order");

process_problems();

ok(defined($ts->transflag([qw(TEST)])), "Set transflags");
ok($ts->transrun(\&callback) == 1, "Running test transaction with pkg obsoleting its deps");
process_problems();
ok(!defined($ts->transreset), "Resetting transaction");

my $h = RPM4::rpm2header("$Bin/test-rpm-1.0-1mdk.noarch.rpm");
ok($h, "Reading the header works");

ok($ts->transadd($h, "$Bin/test-rpm-1.0-1mdk.noarch.rpm") == 0, "Adding a package to transaction works");
ok($ts->traverse_transaction(sub { 
    ok($_[0]->fullname, "Can get name from te");
SKIP: {
# segfault on mga[2-7], aka with rpm-4.9 & rpm-4.1[04], status is unknown for 4.15
skip 'segfault on older rpm', 1  if `rpm --version` =~ /4\.(9|1[0-5])\./;
    ok($_[0]->files, "Can get files from te");
}
    ok($_[0]->type, "Can get type from te");
}), "traverse_transaction works");

ok($ts->transcheck == 0, "Checking transaction works");
ok($ts->transorder == 0, "Run transaction order");

ok(defined($ts->transflag([qw(JUSTDB)])), "Set transflags");
ok($ts->transrun(\&callback) == 0, "Running transaction justdb");
process_problems();

my $found = 0;
my $roffset;
ok($ts->traverse(sub {
        my ($hf, $offset) = @_;
        scalar($hf->fullname) eq "test-rpm-1.0-1mdk.noarch" and do {
            $found++;
            (undef, $roffset) = ($hf, $offset);
        };
        1;
    }), "Running traverse on transaction");

ok($found, "Can find header in transaction");

$ts = undef; # explicitely calling DESTROY to close database

# FIXME/TODO: rename as $db?
ok($ts = RPM4::newdb(1), "Open existing database");
$found = 0;

$roffset = undef;
ok($ts->traverse(sub {
        my ($hf, $offset) = @_;
        scalar($hf->fullname) eq "test-rpm-1.0-1mdk.noarch" and do {
            $found++;
            (undef, $roffset) = ($hf, $offset);
        };
        1;
    }), "Running traverse on DB");

ok($found == 1, "The previously installed rpm is found");
ok($roffset > 0, "Retrieve offset db");

ok($ts->transremove_pkg("foobar") == 0, "Try to remove a non existing rpm");
ok($ts->transremove_pkg("test-rpm(1.0-1mdk)") == 1, "Try to remove a rpm");
ok($ts->transcheck == 0, "Checking transaction works");
ok(!defined($ts->transreset), "Reseting current transaction");

ok($ts->transremove($roffset), "Removing pkg from header and offset");
ok($ts->transorder == 0, "Run transaction order");
ok($ts->transcheck == 0, "Checking transaction works");
ok(defined($ts->transflag([qw(JUSTDB)])), "Set transflags");
SKIP: {
# rpmal.c:293: rpmalAdd: Assertion `dspool == ((void *)0) || dspool == al->pool' failed.
# on at least mga[3-7], aka with rpm-4.1[14], status is unknown for 4.10 & 4.15
skip 'assertion failure on older rpm', 1  if `rpm --version` =~ /4\.1[0-5]\./;
ok($ts->transrun(\&callback) == 0, "Running transaction justdb");
process_problems();

$found = 0;

ok($ts->traverse(sub {
        my ($hf, $offset) = @_;
        scalar($hf->fullname) eq "test-rpm-1.0-1mdk.noarch" and do {
            $found++;
            (undef, $roffset) = ($hf, $offset);
        };
        1;
    }), "Running traverse");

ok($found == 0, "The previously removed rpm is not found");
};

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

done_testing();

sub callback {
    my %a = @_;
    print STDERR "$a{what} $a{amount} / $a{total}\n";
}

sub process_problems() {
    my $pbs = RPM4::Transaction::Problems->new($ts);
    return if !$pbs;
    isa_ok(
	$pbs,
	'RPM4::Transaction::Problems',
	'Can retrieve pb from transaction'
	);

    ok($pbs->count, "Can get number of problems");

    ok($pbs->init || 1, "Resetting problems counter");
    my $strpb;
    while ($pbs->hasnext) {
	$strpb .= $pbs->problem;
    }
    warn "Transaction problems: $strpb\n";
    ok($strpb, "Can get problem description");
}
