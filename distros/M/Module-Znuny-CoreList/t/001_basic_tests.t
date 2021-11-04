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

my @otrs_versions = Module::Znuny::CoreList->shipped(
   '6.0.x',
   'Kernel::System::DB',
);

my @check_otrs_version = map{ "6.0." . $_ } ( 31 .. 37 );

is_deeply( \@otrs_versions, \@check_otrs_version, 'Kernel::System::DB in 6.0.x' );

my @cpan_modules = Module::Znuny::CoreList->cpan_modules( '6.0.1' );

my @no_modules =  Module::Znuny::CoreList->cpan_modules( '6.0.0' );
is scalar @no_modules, 0, 'no cpan modules in "6.0.0"';

my @modules = Module::Znuny::CoreList->modules( '6.0.31' );
ok grep{ $_ eq 'Kernel::Language::de' }@modules, 'Found Kernel::Language::de';

@no_modules =  Module::Znuny::CoreList->cpan_modules();
is scalar @no_modules, 0, 'cpan_modules() - no version';

@no_modules =  Module::Znuny::CoreList->modules();
is scalar @no_modules, 0, 'modules() - no version';

done_testing();
