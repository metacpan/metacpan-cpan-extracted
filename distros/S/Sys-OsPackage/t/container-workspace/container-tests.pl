#!/usr/bin/env perl 
#===============================================================================
#         FILE: container-tests.pl
#        USAGE: ./container-tests.pl  
#  DESCRIPTION: run Sys::OsPackage tests inside a container
#       AUTHOR: Ian Kluft (IKLUFT), 
#      CREATED: 05/03/2022 08:54:50 PM
#===============================================================================

use strict;
use warnings;
use utf8;
use autodie;
use Sys::OsPackage;
use Test::More;
use Carp qw(croak);

# list of modules to check whether they were loaded with OS packages
my @modules = qw(CPAN Sys::OsPackage Test::More YAML);

# function to run tests will be called once as root, once as non-root
sub run_tests
{
    # check if running as root
    my $mode = ($> == 0) ? "root" : "uid=$>";

    # run module & package detection tests
    Sys::OsPackage->clear_instance();
    my $ospkg = Sys::OsPackage->instance(quiet => 1);
    my $platform = Sys::OsPackage->platform();
    foreach my $module (@modules) {
        ok($ospkg->module_installed($module), "found $module in Perl path ($mode)");
        my $pkgname = $ospkg->call_pkg_driver(op => "modpkg", module => $module);
        SKIP: {
            if ($pkgname) {
                my $pkg_found = $ospkg->pkg_installed($pkgname);
                ok($pkg_found, "$module installed as $platform package $pkgname ($mode)");
            } else {
                SKIP: {
                    skip "$module not available as package on $platform ($mode)", 1;
                }
            }
        }
    }

    # run basic tests inside the container
    Sys::OsPackage->clear_instance(); # reset instance for tests
    basic_tests_run("$platform($mode)");
    return;
}

# verify the test was started in the container root user
if ($< != 0) {
    croak "test must be started as root, and should be in a container";
}

# verify 002_basic.t was copied into the container and then load it
my $basic_tests_script = "./002_basic.t";
if (not -f $basic_tests_script) {
    croak "test script $basic_tests_script must be copied into the container";
}
{
    local $ENV{BASIC_TESTS_CONTAINER}=1;
    unless (my $do_status = do $basic_tests_script) {
        if ($@) {
            croak "couldn't parse $basic_tests_script: $@";
        }
        if (defined $do_status) {
            croak "couldn't do $basic_tests_script: $!";
        }
        croak "couldn't load $basic_tests_script";
    }
}

# compute test count and generate plan for TAP output
plan tests => 4 * (scalar @modules) + 2 * basic_tests_count();

# run module & package detection tests as container root
run_tests();

#
# re-run tests as a non-root user
#

# make a user id and create home directory in the container
my $user_id = 1337;
my $home = "/home/$user_id";
foreach my $dir ("/home", $home) {
    if (not -d $dir) {
        no autodie;
        mkdir $dir
            or croak "mkdir($dir) failed; $!";
    }
}
chown $user_id, $user_id, $home;
chmod 0750, $home;
chdir $home;
$ENV{HOME} = $home;
$ENV{USER} = $user_id;
$ENV{LOGNAME} = $user_id;

# set gid & uid to container $user_id
# we start as root so change gid & uid to avoid loading user management utility packages for each different OS
$) = $user_id;
$( = $user_id;
$< = $user_id;
$> = $user_id;
run_tests();
