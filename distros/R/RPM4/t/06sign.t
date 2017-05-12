#!/usr/bin/perl
# $Id$

use strict;
use Test::More tests => 6;
use FindBin qw($Bin);
use File::Temp qw(tempdir);
use File::Copy;
use RPM4;

my $passphrase = "RPM4";

my $testdir = tempdir(CLEANUP => 1);

RPM4::add_macro("_dbpath $testdir");

copy("$Bin/test-rpm-1.0-1mdk.noarch.rpm", $testdir);

RPM4::add_macro("_signature gpg");
RPM4::add_macro("_gpg_name RPM4 test key");
RPM4::add_macro("_gpg_path $Bin/gnupg");

ok(RPM4::rpmresign($passphrase, "$testdir/test-rpm-1.0-1mdk.noarch.rpm") == 0, "can resign a rpm");

ok(my $db = RPM4::newdb(1), "Open a new database");

ok($db->checkrpm("$testdir/test-rpm-1.0-1mdk.noarch.rpm") != 0, "checking a rpm, key is missing");
ok($db->checkrpm("$testdir/test-rpm-1.0-1mdk.noarch.rpm", [ "NOSIGNATURES" ]) == 0, "checking a rpm, no checking the key");

ok($db->importpubkey("$Bin/gnupg/test-key.gpg") == 0, "Importing a public key");

ok($db->checkrpm("$testdir/test-rpm-1.0-1mdk.noarch.rpm") == 0, "checking a rpm file");

$db = undef;
