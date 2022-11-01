#!/usr/bin/perl
#===============================================================================
#         FILE: 003_driver.t
#  DESCRIPTION: test Sys::OsPackage::Driver and driver subclasses
#       AUTHOR: Ian Kluft (IKLUFT), 
#      CREATED: 04/30/2022 07:47:25 PM
#===============================================================================
# This tests computationally inexpensive parts of the packager interface as best we can.
# Containers are needed for a deeper dive. For that see author test scripts numbered 100+.

use strict;
use warnings;
use Sys::OsPackage;
use Test::More;

# constants
my @packagers = qw(Alpine Arch Debian RPM Suse);
my @required_methods = qw(ping sudo_check pkgcmd modpkg find install is_installed);

plan tests => (scalar @packagers) * (5 + scalar @required_methods);

my $ospkg = Sys::OsPackage->instance(quiet => 1);
foreach my $packager (sort @packagers) {
    my $driver = "Sys::OsPackage::Driver::$packager";

    # test that driver responds to ping
    # test this first to verify Sys::OsPackage::call_pkg_driver() can load the module
    $ospkg->sysenv("packager", $driver); # force value of packager to the driver class we want to test
    my $str = $ospkg->call_pkg_driver(op => "ping");
    is($str, $driver, "driver $driver responds to ping");

    # test that driver implements required methods
    require_ok($driver); # technically already done by Sys::OsPackage::call_pkg_driver()
    ok($driver->can("__notfound__") ? 0 : 1, "driver $driver does not implement __notfound__ method");
    foreach my $req (sort @required_methods) {
        ok($driver->can($req), "driver $driver implements $req method");
    }

    # run sudo_check() test with flag off and on
    $ospkg->sysenv("root", 0); # force root flag to false to prevent interference
    $ospkg->{_config}{sudo} = 0;
    my @list = $ospkg->call_pkg_driver(op => "sudo_check");
    is_deeply(\@list, [undef], "driver $driver receives sudo flag when off");
    $ospkg->{_config}{sudo} = 1;
    @list = $ospkg->call_pkg_driver(op => "sudo_check");
    is_deeply(\@list, ["sudo"], "driver $driver receives sudo flag when on");
}
