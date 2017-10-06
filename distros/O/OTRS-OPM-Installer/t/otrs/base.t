#!/usr/bin/env perl

use v5.10;

use strict;
use warnings;

use Test::More;

use File::Basename;
use File::Spec;

use OTRS::OPM::Installer::Utils::OTRS;

diag "Testing *::OTRS version " . OTRS::OPM::Installer::Utils::OTRS->VERSION();

my $linux = OTRS::OPM::Installer::Utils::OTRS->new;
isa_ok $linux, 'OTRS::OPM::Installer::Utils::OTRS';
is $linux->os_env, 'OTRS::OPM::Installer::Utils::OTRS::Linux';

$ENV{OTRSOPMINSTALLERTEST} = 'opt';

my $otrs_dir =  File::Spec->rel2abs( File::Spec->catdir( dirname(__FILE__), 'opt' ) );
my $test = OTRS::OPM::Installer::Utils::OTRS->new( path => $otrs_dir );
isa_ok $test, 'OTRS::OPM::Installer::Utils::OTRS';
is $test->os_env, 'OTRS::OPM::Installer::Utils::OTRS::Test';

is $test->path, $otrs_dir;

is $test->obj_env, 'OTRS::OPM::Installer::Utils::OTRS::OTRS4';
is $test->otrs_version, '5.0.8';

is_deeply $test->inc, [
    File::Spec->catdir( $otrs_dir, '' ) . '/',
    File::Spec->catdir( $otrs_dir, 'Kernel', 'cpan-lib' ),
];

isa_ok $test->manager, 'Kernel::System::Package';
isa_ok $test->db, 'Kernel::System::DB';

ok $test->is_installed( package => 'TicketOverviewHooked', version => '5.0.6' );
ok $test->is_installed( package => 'TicketOverviewHooked', version => '5.0.8' );

my $result =  $test->is_installed( package => 'TicketOverviewHooks', version => '5.0.6' );
is $result, undef;

$result = $test->is_installed( package => 'TicketOverviewHooked', version => '5.0.33' );
is $result, undef;

done_testing();
