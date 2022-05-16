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
use Sys::OsPackage;
use Test::More;
use YAML;

# list of modules to check whether they were loaded with OS packages
my @modules = qw(CPAN Sys::OsPackage Test::More YAML);

plan tests => 2 * scalar @modules;

my $ospkg = Sys::OsPackage->instance(quiet => 1);
my $platform = Sys::OsPackage->platform();
foreach my $module (@modules) {
    ok($ospkg->module_installed($module), "found $module in Perl path");
    my $pkgname = $ospkg->call_pkg_driver(op => "modpkg", module => $module);
    SKIP: {
        if ($pkgname) {
            my $pkg_found = $ospkg->pkg_installed($pkgname);
            ok($pkg_found, "$module installed as $platform package $pkgname");
        } else {
            SKIP: {
                skip "$module not available as package on $platform", 1;
            }
        }
    }
}
