#!/usr/bin/perl
#===============================================================================
#         FILE: 002_basic.t
#  DESCRIPTION: basic/inexpensive tests for Sys::OsPackage 
#        NOTES: ---
#       AUTHOR: Ian Kluft (IKLUFT)
#      CREATED: 05/03/2022 05:10:40 PM
#===============================================================================

use strict;
use warnings;
use Sys::OsPackage;
use Test::More;

# test data
my @sysconf_keys = qw(common_id search_cmds search_path);
my %platconf_keys;
my %perlconf_keys = (
    sources => "HASH",
    module_deps => "ARRAY",
    cpan_deps => "ARRAY",
    skip => "HASH",
);

# count platconf tests
sub platconf_count
{
    my $_platconf_ref = Sys::OsPackage::_platconf();
    my $test_count = 0;
    foreach my $key (keys %$_platconf_ref) {
        my $platdata = {};
        foreach my $subkey (keys %{$_platconf_ref->{$key}}) {
            $test_count += 2;
            $platdata->{$subkey} = ref $_platconf_ref->{$key}{$subkey};
        }
        $platconf_keys{$key} = $platdata;
    }
    return $test_count;
}

# count tests
plan tests => 17
    + (2 * scalar @sysconf_keys)
    + platconf_count()
    + (2 * scalar keys %perlconf_keys);

# instantiation (4 tests)
is(Sys::OsPackage->defined_instance(), 0, "instance undefined before initialization");
my $ospkg = Sys::OsPackage->instance(quiet => 1);
isa_ok($ospkg, "Sys::OsPackage", "correct type from instance()");
my $ospkg2 = Sys::OsPackage->instance();
is($ospkg, $ospkg2, "same instance from 2nd call to instance()");
ok($ospkg->quiet(), "quiet flag was set as requested");

# system configuration (7 tests)
ok((defined Sys::OsPackage::sysconf("__notfound__")) ? 0 : 1, "sysconf(__notfound__) not found as expected");
foreach my $sysconf_key (@sysconf_keys) {
    my $value = Sys::OsPackage::sysconf($sysconf_key);
    ok((defined $value) ? 1 : 0, "sysconf($sysconf_key) returns defined value");
    isa_ok($value, "ARRAY", "sysconf($sysconf_key)");
}

# perl configuration (9 tests)
ok((defined Sys::OsPackage::perlconf("__notfound__")) ? 0 : 1, "perlconf(__notfound__) not found as expected");
foreach my $perlconf_key (sort keys %perlconf_keys) {
    my $value = Sys::OsPackage::perlconf($perlconf_key);
    ok((defined $value) ? 1 : 0, "perlconf($perlconf_key) returns defined value");
    isa_ok($value, $perlconf_keys{$perlconf_key}, "perlconf($perlconf_key)");
}

# system environment tests (9 tests)
my $test_str = "__test__";
$ospkg->sysenv("platform", $test_str);
is($ospkg->sysenv("platform"), $test_str, "sysenv(platform) returns same value written to it");
is($ospkg->platform(), $test_str, "ref->platform() returns same value as sysenv(platform)");
is(Sys::OsPackage->platform(), $test_str, "class->platform() returns same value as sysenv(platform)");
$ospkg->sysenv("packager", $test_str);
is($ospkg->sysenv("packager"), $test_str, "sysenv(packager) returns same value written to it");
is($ospkg->packager(), $test_str, "ref->packager() returns same value as sysenv(packager)");
is(Sys::OsPackage->packager(), $test_str, "class->packager() returns same value as sysenv(packager)");
ok(defined $ospkg->sysenv("perlbase"), "sysenv(perlbase) is defined");
ok(-d $ospkg->sysenv("perlbase"), "sysenv(perlbase) points to an existing directory");
ok(-d $ospkg->sysenv("perlbase")."/lib/perl5", "sysenv(perlbase)/lib/perl5 is an existing directory");

# platform configuration (n tests)
ok((defined Sys::OsPackage->platconf("__notfound__")) ? 0 : 1, "platconf(__notfound__) not found as expected");
foreach my $platconf_key (sort keys %platconf_keys) {
    foreach my $plat_key (sort keys %{$platconf_keys{$platconf_key}}) {
        $ospkg->sysenv("platform", $plat_key); # force platform to what we need platconf() to test
        my $value = Sys::OsPackage->platconf($platconf_key);
        my $reftype = $platconf_keys{$platconf_key}{$plat_key};
        ok((defined $value) ? 1 : 0, "platconf($platconf_key) returns defined value on $plat_key");
        if ($reftype eq "") {
            is(ref $value, "", "platconf($platconf_key) is scalar on $plat_key");
        } else {
            isa_ok($value, $reftype, "platconf($platconf_key) on $plat_key");
        }
    }
}

# capture command output (1 test)
is($ospkg->capture_cmd("echo", $test_str), $test_str, "capture_cmd test with echo");
