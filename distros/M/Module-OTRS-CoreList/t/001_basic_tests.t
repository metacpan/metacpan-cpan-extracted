#!/usr/bin/perl

use strict;
use warnings;
use Test::More;

use File::Basename;
use File::Spec;

my $dir;
BEGIN {
   $dir = File::Spec->catdir( dirname( __FILE__ ), '..', 'lib' );
}

use lib $dir;

use Module::OTRS::CoreList;

my @otrs_versions = Module::OTRS::CoreList->shipped(
   '2.4.x',
   'Kernel::System::DB',
);

my @check_otrs_version = qw(2.4.1 2.4.10 2.4.11 2.4.12 2.4.13 2.4.14 2.4.15 2.4.2 2.4.3 2.4.4 2.4.5 2.4.6 2.4.7 2.4.8 2.4.9);

is_deeply( \@otrs_versions, \@check_otrs_version, 'Kernel::System::DB in 2.4.x' );

my @cpan_modules = Module::OTRS::CoreList->cpan_modules( '3.0.1' );

my @no_modules =  Module::OTRS::CoreList->cpan_modules( '3.0.0' );
is scalar @no_modules, 0, 'no cpan modules in "3.0.0"';

my @modules = Module::OTRS::CoreList->modules( '2.3.1' );
ok grep{ $_ eq 'Kernel::Language::bb' }@modules, 'Found Kernel::Language::bb';

@no_modules =  Module::OTRS::CoreList->cpan_modules();
is scalar @no_modules, 0, 'cpan_modules() - no version';

@no_modules =  Module::OTRS::CoreList->modules();
is scalar @no_modules, 0, 'modules() - no version';

done_testing();
