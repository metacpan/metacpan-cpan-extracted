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
    my $mode = ($> == 0) ? "root" : "non-root $>";

    # run module & package detection tests
    Sys::OsPackage->clear_instance();
    my $ospkg = Sys::OsPackage->instance(quiet => 1);
    my $platform = Sys::OsPackage->platform();
    foreach my $module (@modules) {
        ok($ospkg->module_installed($module), "found $module in Perl path ($mode mode)");
        my $pkgname = $ospkg->call_pkg_driver(op => "modpkg", module => $module);
        SKIP: {
            if ($pkgname) {
                my $pkg_found = $ospkg->pkg_installed($pkgname);
                ok($pkg_found, "$module installed as $platform package $pkgname ($mode mode)");
            } else {
                SKIP: {
                    skip "$module not available as package on $platform ($mode mode)", 1;
                }
            }
        }
    }
    return;
}

# verify the test was started in the container root user
if ($< != 0) {
    croak "test must be started as root, and should be in a container";
}

# compute test count and generate plan for TAP output
plan tests => 4 * scalar @modules;

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
#my $su_bin = $ospkg->cmd_path("su");
#exec $su_bin, "-c", $0, "-", $user_id
# or croak "exec failed; $!";
