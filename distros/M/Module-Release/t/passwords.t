#!/usr/bin/env perl

use strict;
use warnings;

use Test::More 1.0;
use Capture::Tiny qw(capture_stderr);

use lib qw(t/lib);
require 'setup_common.pl';

my $class = 'Module::Release';
subtest setup => sub {
	use_ok( $class );
	can_ok( $class, 'new' );
	};

my $release = $class->new;

$release->turn_debug_on;

{
    my $output = capture_stderr { $release->check_for_passwords };
    is(
        $output,
        "CPAN pass is \n",
        "Debug output shows empty password when password unset"
    );
}

{
    $ENV{'CPAN_PASS'} = 's3cr3t';
    my $output = capture_stderr { $release->check_for_passwords };
    is( $release->config->cpan_pass,
        undef, "Password is unset when cpan username is not set" );
    is(
        $output,
        "CPAN pass is \n",
        'Debug output shows unset password when cpan username is not set'
    );
}

{
    $ENV{'CPAN_PASS'} = 's3cr3t';
    $release->config->set( 'cpan_user', 'BDFOY' );
    my $output = capture_stderr { $release->check_for_passwords };
    is( $release->config->cpan_pass,
        's3cr3t', "Password is set when CPAN_PASS is set" );
    is(
        $output,
        "CPAN pass is s3cr3t\n",
        'Debug output shows password when set'
    );
}

done_testing();
