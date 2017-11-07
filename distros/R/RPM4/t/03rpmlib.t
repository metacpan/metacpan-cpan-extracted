#!/usr/bin/perl
# $Id$

use strict;
use Test::More tests => 52;
use FindBin qw($Bin);
use RPM4;

ok(! defined(RPM4::setverbosity("DEBUG")), "Set verbosity works");
{
my $marker =  0;
ok(!defined(RPM4::setlogcallback(sub { my %m = @_; $marker = 1; print "$m{priority}: $m{msg}\n" })),
    "Setting log callback function works");
 SKIP: {
     skip 'segfault in rpm-4.1[12]', 2 if `rpm --version` =~ /4\.1[12]\./;
     ok(!defined(RPM4::rpmlog("ERR", "This is a rpm debug message")), "rpmlog function works");
     ok($marker == 1, "rpmlogcallback has been called");
};
}
ok(! defined(RPM4::setlogcallback(undef)), "remove callback function");
ok(RPM4::setlogfile("logfile"), "set a log file");
ok(!defined(RPM4::rpmlog(7, "This is a rpm debug message")), "rpmlog function works");
ok(RPM4::setlogfile(undef), "set a log file");
unlink("logfile");

# Generic query:
open(my $null, ">", "/dev/null");
ok(!RPM4::dumprc($null), "Can dumprc");
ok(!RPM4::dumpmacros($null), "Can dumpmacros");
close($null);
ok(length(RPM4::getosname), "Return OS name");
ok(length(RPM4::getarchname), "Return arch name");
ok(length(RPM4::buildhost), "Return buildhost");

# Playing with macros
my $target_cpu = RPM4::expand("%_target_cpu");
ok($target_cpu !~ /^\%/, "Getting _target_cpu macro");
# setting test_macro to test
ok(RPM4::expand("%test_macro") eq "%test_macro", '%test_macro is no set');
RPM4::add_macro("test_macro test");
ok(RPM4::expand("%test_macro") eq "test", "add_macro works");
RPM4::del_macro("test_macro");
ok(RPM4::expand("%test_macro") eq "%test_macro", "del_macro works");
RPM4::add_macro("test_macro test");
ok(RPM4::expand("%test_macro") eq "test", "add_macro works");
ok(!RPM4::resetmacros(), "Reset macro works");
ok(!RPM4::resetrc(), "Reset rc works");
ok(RPM4::expand("%test_macro") eq "%test_macro", "resetmacros works");
RPM4::loadmacrosfile("$Bin/rpmmacros");
ok(RPM4::expand("%RPM4") eq "perl-RPM4", "Checking macros define in our rpmmacros");
ok(!RPM4::add_macro("_numeric 1"), "Add numeric macro");
ok(RPM4::expandnumeric("%_numeric"), "expandnumeric works");

ok(RPM4::readconfig("t/rpmrc") == 0, "Reading alternate config file");
ok(RPM4::readconfig(undef, "xtentas-MandrakeSoft-osf1") == 0, "Reading conf for xtentas-MandrakeSoft-osf1");
is(RPM4::expand("%_target_cpu"), "xtentas", "the conf is properly load");
ok(RPM4::readconfig() == 0, "Re-Reading the conf, reset to default");
SKIP: {
    skip "seems there is an internal rpm bug", 1;
is(RPM4::expand("%_target_cpu"), $target_cpu, "the conf is properly load");
}


ok(RPM4::tagName(1000) eq "Name", "tagName works");
ok(RPM4::tagValue("NAME") == 1000, "tagValue works");
ok(RPM4::tagtypevalue("STRING"), "Get tage type value");

# Version comparison
ok(RPM4::rpmvercmp("1mdk", "1mdk") ==  0, "rpmvercmp with =");
ok(RPM4::rpmvercmp("1mdk", "2mdk") == -1, "rpmvercmp with <");
ok(RPM4::rpmvercmp("2mdk", "1mdk") ==  1, "rpmvercmp with >");

ok(RPM4::compare_evr("1", "1") ==  0, "comparing version only, equal");
ok(RPM4::compare_evr("2", "1") ==  1, "comparing version only, higther");
ok(RPM4::compare_evr("1", "2") == -1, "comparing version only, lesser");
ok(RPM4::compare_evr("1-1mdk", "1-1mdk") ==  0, "comparing version-release only, equal");
ok(RPM4::compare_evr("2-1mdk", "1-1mdk") ==  1, "comparing version-release only, higther");
ok(RPM4::compare_evr("1-1mdk", "2-1mdk") == -1, "comparing version-release only, lesser");
ok(RPM4::compare_evr("1:1-1mdk", "1:1-1mdk") ==  0, "comparing epoch:version-release only, equal");
ok(RPM4::compare_evr("2:1-1mdk", "1:1-1mdk") ==  1, "comparing epoch:version-release only, higther");
ok(RPM4::compare_evr("1:1-1mdk", "2:1-1mdk") == -1, "comparing epoch:version-release only, lesser");

ok(RPM4::compare_evr("0:1-1mdk", "1-1mdk") ==  1, "comparing epoch 0 vs no epoch");
ok(RPM4::compare_evr("1:1-1mdk", "1-1mdk") ==  1, "comparing epoch 1 vs no epoch");
ok(RPM4::compare_evr("1.0-1mdk", "1.0") ==  1, "comparing version-release vs version only");
ok(RPM4::compare_evr("0:1-1mdk", "1.0") ==  1, "comparing epoch:version-release vs no version");

ok(RPM4::osscore("osf1") == 0, "get os score");
ok(RPM4::osscore("osf1", 1) == 0, "get build os score");

ok(RPM4::archscore("noarch") != 0, "get arch score");
ok(RPM4::archscore("noarch", 1) != 0, "get arch score");

