#!/usr/bin/env perl

use v5.10;

use strict;
use warnings;

use Test::More;

use File::Basename;
use File::Spec;

use OPM::Installer::Utils::TS;

diag "Testing *::TS version " . OPM::Installer::Utils::TS->VERSION();

my $linux = OPM::Installer::Utils::TS->new;
isa_ok $linux, 'OPM::Installer::Utils::TS';
is $linux->os_env, 'OPM::Installer::Utils::Linux';

$ENV{OPMINSTALLERTEST} = 'opt';

my $otrs_dir =  File::Spec->rel2abs( File::Spec->catdir( dirname(__FILE__), 'opt' ) );
my $test = OPM::Installer::Utils::TS->new( path => $otrs_dir );
isa_ok $test, 'OPM::Installer::Utils::TS';
is $test->os_env, 'OPM::Installer::Utils::Test';

is $test->path, $otrs_dir;
is $test->framework_version, '5.0.8';

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
