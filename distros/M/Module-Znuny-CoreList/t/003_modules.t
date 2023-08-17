#!/usr/bin/perl

use strict;
use warnings;
use 5.008;
use Test::More;

use File::Basename;
use File::Spec;

my $dir;
BEGIN {
   $dir = File::Spec->catdir( dirname( __FILE__ ), '..', 'lib' );
}

use lib $dir;

use Module::Znuny::CoreList;

{
    my @modules = Module::Znuny::CoreList->modules( '6.0.31' );
    ok grep{ $_ eq 'Kernel::Language::de' }@modules, 'Found Kernel::Language::de';
}

{
    my @no_modules =  Module::Znuny::CoreList->modules('test');
    is scalar @no_modules, 0, 'modules() - invalid version - string';
}

{
    my @no_modules =  Module::Znuny::CoreList->modules('6.0.1721');
    is scalar @no_modules, 0, 'modules() - version does not exist';
}

{
    my @all_patchlevel_modules =  Module::Znuny::CoreList->modules('6.0.x');
    ok scalar @all_patchlevel_modules, 'modules() - all patchlevel version';
}

{
    my @no_modules =  Module::Znuny::CoreList->modules();
    is scalar @no_modules, 0, 'modules() - no version';
}

done_testing();
