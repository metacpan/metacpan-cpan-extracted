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
    my @cpan_modules = Module::Znuny::CoreList->cpan_modules( '6.0.41' );
    ok scalar @cpan_modules, 'Found CPAN modules for 6.0.41';
    ok grep { $_ eq 'CGI' } @cpan_modules;
}

{
    my @cpan_modules = Module::Znuny::CoreList->cpan_modules( '6.0.x' );
    ok scalar @cpan_modules, 'Found CPAN modules for 6.0.x';
    ok grep { $_ eq 'CGI' } @cpan_modules;
}

{
    my @no_modules =  Module::Znuny::CoreList->cpan_modules( '6.0.0' );
    is scalar @no_modules, 0, 'no cpan modules in "6.0.0"';
}

{
    my @no_modules =  Module::Znuny::CoreList->cpan_modules( 'test' );
    is scalar @no_modules, 0, 'no cpan modules - invalid version';
}

{
    my @no_modules =  Module::Znuny::CoreList->cpan_modules();
    is scalar @no_modules, 0, 'no cpan modules - no version';
}

done_testing();
