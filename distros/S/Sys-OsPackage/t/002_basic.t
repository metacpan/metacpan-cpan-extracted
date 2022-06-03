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
use Config;

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

# count tests for plan
sub basic_tests_count
{
    return 16
        + (2 * scalar @sysconf_keys)
        + platconf_count()
        + (2 * scalar keys %perlconf_keys);
}

# run basic tests
sub basic_tests_run
{
    my $container_name = shift;
    my $env_prefix = (defined $container_name) ? "$container_name: " : "";

    # instantiation (4 tests)
    is(Sys::OsPackage->defined_instance(), 0, $env_prefix."instance undefined before initialization");
    my $ospkg = Sys::OsPackage->instance(quiet => 1);
    isa_ok($ospkg, "Sys::OsPackage", $env_prefix."correct type from instance()");
    my $ospkg2 = Sys::OsPackage->instance();
    is($ospkg, $ospkg2, $env_prefix."same instance from 2nd call to instance()");
    ok($ospkg->quiet(), $env_prefix."quiet flag was set as requested");

    # system configuration (7 tests)
    ok((defined Sys::OsPackage::sysconf("__notfound__")) ? 0 : 1,
        $env_prefix."sysconf(__notfound__) not found as expected");
    foreach my $sysconf_key (@sysconf_keys) {
        my $value = Sys::OsPackage::sysconf($sysconf_key);
        ok((defined $value) ? 1 : 0, $env_prefix."sysconf($sysconf_key) returns defined value");
        isa_ok($value, "ARRAY", $env_prefix."sysconf($sysconf_key)");
    }

    # perl configuration (9 tests)
    ok((defined Sys::OsPackage::perlconf("__notfound__")) ? 0 : 1,
        $env_prefix."perlconf(__notfound__) not found as expected");
    foreach my $perlconf_key (sort keys %perlconf_keys) {
        my $value = Sys::OsPackage::perlconf($perlconf_key);
        ok((defined $value) ? 1 : 0, $env_prefix."perlconf($perlconf_key) returns defined value");
        isa_ok($value, $perlconf_keys{$perlconf_key}, $env_prefix."perlconf($perlconf_key)");
    }

    # system environment tests (9 tests)
    my $test_str = "__test__";
    $ospkg->sysenv("platform", $test_str);
    is($ospkg->sysenv("platform"), $test_str, $env_prefix."sysenv(platform) returns same value written to it");
    is($ospkg->platform(), $test_str, $env_prefix."ref->platform() returns same value as sysenv(platform)");
    is(Sys::OsPackage->platform(), $test_str, $env_prefix."class->platform() returns same value as sysenv(platform)");
    $ospkg->sysenv("packager", $test_str);
    is($ospkg->sysenv("packager"), $test_str, $env_prefix."sysenv(packager) returns same value written to it");
    is($ospkg->packager(), $test_str, $env_prefix."ref->packager() returns same value as sysenv(packager)");
    is(Sys::OsPackage->packager(), $test_str, $env_prefix."class->packager() returns same value as sysenv(packager)");
    SKIP: {
        if ($Config{osname} eq "MSWin32") {
            # perlbase is never defined on Windows
            skip $env_prefix."perlbase not defined on Win32", 2
        } elsif (not defined $ospkg->sysenv("perlbase")) {
            # not realistic to expect perlbase to be defined on all platforms
            skip $env_prefix."perlbase not defined on ".$ospkg->sysenv("platform"), 2
        }
        ok(-d $ospkg->sysenv("perlbase"), $env_prefix."sysenv(perlbase) points to an existing directory");
        ok(-d $ospkg->sysenv("perlbase")."/lib/perl5" or -d $ospkg->sysenv("perlbase")."/lib/perl",
            $env_prefix."sysenv(perlbase) contains lib/perl5 or lib/perl subdirectory");
    }

    # platform configuration (n tests)
    ok((defined Sys::OsPackage->platconf("__notfound__")) ? 0 : 1,
        $env_prefix."platconf(__notfound__) not found as expected");
    foreach my $platconf_key (sort keys %platconf_keys) {
        foreach my $plat_key (sort keys %{$platconf_keys{$platconf_key}}) {
            $ospkg->sysenv("platform", $plat_key); # force platform to what we need platconf() to test
            my $value = Sys::OsPackage->platconf($platconf_key);
            my $reftype = $platconf_keys{$platconf_key}{$plat_key};
            ok((defined $value) ? 1 : 0, $env_prefix."platconf($platconf_key) returns defined value on $plat_key");
            if ($reftype eq "") {
                is(ref $value, "", $env_prefix."platconf($platconf_key) is scalar on $plat_key");
            } else {
                isa_ok($value, $reftype, $env_prefix."platconf($platconf_key) on $plat_key");
            }
        }
    }

    # capture command output (1 test)
    is($ospkg->capture_cmd("echo", $test_str), $test_str, $env_prefix."capture_cmd test with echo");
}

# run tests under normal conditions
# except when BASIC_TESTS_CONTAINER is set - then let the test script which included this call functions as needed
if (not exists $ENV{BASIC_TESTS_CONTAINER}) {
    # count tests
    plan tests => basic_tests_count();

    # run tests
    basic_tests_run();
}

1;
