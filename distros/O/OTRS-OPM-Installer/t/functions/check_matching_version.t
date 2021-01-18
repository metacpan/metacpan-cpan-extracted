#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use OTRS::OPM::Installer;

{
    package
        MyTest;
    use Moo;

    sub framework {
        my ($self, $values) = @_;
        $self->{frameworks} = $values if $values;
        return ($self->{frameworks} || []);
    }
}

my $otrs = '3.3.19';

my $test = MyTest->new;

$test->framework( [ qw/2.4.x 3.0.x/ ] );
ok( !( OTRS::OPM::Installer->_check_matching_versions( $test, $otrs ) ) );

$test->framework( [ qw/2.4.x 3.0.x 3.1.x 3.2.x 3.3.x/ ] );
ok( OTRS::OPM::Installer->_check_matching_versions( $test, $otrs ) );

$test->framework( [ qw/2.4.x 3.0.x 3.1.x 3.2.x 3.3.19/ ] );
ok( OTRS::OPM::Installer->_check_matching_versions( $test, $otrs ) );

$test->framework( [ qw/2.4.x 3.0.x 3.1.x 3.2.x 3.3.18/ ] );
ok( !(OTRS::OPM::Installer->_check_matching_versions( $test, $otrs ) ) );

$test->framework( [ qw/2.4.x 3.0.x 3.1.x 3.2.x 3.3.20/ ] );
ok( !(OTRS::OPM::Installer->_check_matching_versions( $test, $otrs ) ) );

$test->framework( [ qw/3.4.x 4.0.x/ ] );
ok( !( OTRS::OPM::Installer->_check_matching_versions( $test, $otrs ) ) );

$test->framework( [ qw/3.x.x/ ] );
ok( OTRS::OPM::Installer->_check_matching_versions( $test, $otrs ) );

$test->framework( [ qw/2.x.x/ ] );
ok( !(OTRS::OPM::Installer->_check_matching_versions( $test, $otrs ) ) );

done_testing();
