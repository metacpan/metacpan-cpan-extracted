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
    my @otrs_versions = Module::Znuny::CoreList->shipped(
       '6.0.x',
       'Kernel::System::DB',
    );

    my @check_otrs_version = map{ "6.0." . $_ } ( 31 .. 48 );

    is_deeply( \@otrs_versions, \@check_otrs_version, 'Kernel::System::DB in 6.0.x' );
}

{
    my @otrs_versions = Module::Znuny::CoreList->shipped(
       '6.0.38',
       'CGI',
    );

    is scalar @otrs_versions, 1, 'shipped() - CPAN module';
}

{
    my @otrs_versions = Module::Znuny::CoreList->shipped(
       '6.0.38',
       'CPAN::Audit',
    );

    is scalar @otrs_versions, 1, 'shipped() - CPAN module is shipped with 6.0.38';
}

{
    my @otrs_versions = Module::Znuny::CoreList->shipped(
       '7.0.1',
       'CPAN::Audit',
    );

    is scalar @otrs_versions, 0, 'shipped() - CPAN module removed in Znuny 7.0.1';
}

{
    my @no_modules = Module::Znuny::CoreList->shipped('6.0.105', 'Kernel::System::DB');
    is scalar @no_modules, 0, 'shipped() - version does not exist';
}

{
    my @no_modules = Module::Znuny::CoreList->shipped('6.0.x', 'Does::Not::Exist');
    is scalar @no_modules, 0, 'shipped() - invalid module';
}

{
    my @no_modules = Module::Znuny::CoreList->shipped('6.0.x');
    is scalar @no_modules, 0, 'shipped() - version, but no module';
}

{
    my @no_modules = Module::Znuny::CoreList->shipped();
    is scalar @no_modules, 0, 'shipped() - no version';
}

{
    my @no_modules = Module::Znuny::CoreList->shipped('test');
    is scalar @no_modules, 0, 'shipped() - invalid version - string';
}

{
    my @no_modules = Module::Znuny::CoreList->shipped('7.0');
    is scalar @no_modules, 0, 'shipped() - invalid version - no patchlevel';
}


done_testing();
