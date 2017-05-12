#!/usr/bin/perl
use strict;
use warnings;

use Test::More 0.95;

my $class = 'Module::Release';

subtest setup => sub {
	use_ok( $class );
	can_ok( $class, 'dist_version_format' );
	can_ok( $class, 'dist_version' );
	};

subtest 'remote not set' => sub {
	my $mock = bless {  }, $class;

	my $got = eval { $mock->dist_version };
	my $at = $@;

	ok( ! defined $got, "Without remote set, dist_version croaks" );
	like( $at, qr/\QIt's not set/, "Without remote set, get right error message" );
	};


subtest 'formatting dev version' => sub {
	my $mock = bless { remote_file => 'Foo-1.12_03.tar.gz' }, $class;

	is(
		$mock->dist_version_format( 1, 12, "_03" ), '1.12_03',
		'Development version stays in there'
		);

	is(
		$mock->dist_version_format( 1, 12 ), '1.12',
		"Without development version it's fine"
		);

	is(
		$mock->dist_version, '1.12_03',
		'Development version stays in there'
		);

	};

subtest 'formatting release version' => sub {
	my $mock = bless { remote_file => 'Foo-3.45.tar.gz' }, $class;
	my $got = $mock->dist_version;
	is( $mock->dist_version, '3.45',
		"Without development version it's fine"
		);
	};

subtest 'formatting integer version' => sub {
	my $mock = bless { remote_file => 'Foo-20160101.tar.gz' }, $class;
	my $got = $mock->dist_version;
	is( $mock->dist_version, '20160101',
		"Single integer version extracts correct number"
		);
	};

subtest 'formatting three digit minor version' => sub {
	my $mock = bless { remote_file => 'Foo-3.045.tar.gz' }, $class;
	my $got = $mock->dist_version;
	is( $mock->dist_version, '3.045',
		"Without development version it's fine"
		);
	};

subtest 'three part versions' => sub {
    # Test three-part version numbers.  Module::Build (at least)
    # generates them with a leading 'v'

    # (I am relying on CPANTS to test these cases with version.pm pre-
    # and post-v0.77, and with earlier versions of Perl without any
    # version.pm.  Mocking that here would be more tricksy than I have
    # time for right now).

    my @cases = (
        ['Foo-v3.45.tar.gz'    => 'v3.45.0', "Two-part version string with leading 'v'"],
        ['Foo-v3.45.1.tar.gz'  => 'v3.45.1', "Three-part version string with leading 'v'"],

        # Capitalisation, various suffixes
        ['Foo-V3.45.1.tar.gz'  => 'v3.45.1', "Three-part version string with capitalised leading 'V'"],
        ['Foo-v3.45.1.TAR.GZ'  => 'v3.45.1', "...with capitalised suffix"],
        ['Foo-v3.45.1'         => 'v3.45.1', "...with no suffix"],

        # Test three-part version numbers with no leading 'v'.  Not sure if
        # this occurs in the wild, but presumably this should result in the
        # same as above.
        ['Foo-3.45.1.tar.gz'   => 'v3.45.1', "Three-part version string with no leading 'v'"],
        ['Foo-3.45.1.TAR.GZ'   => 'v3.45.1', "...with capitalised suffix"],
        ['Foo-3.45.1'          => 'v3.45.1', "...with no suffix"],

        # Test four-part version development numbers with no leading 'v'.
        # (Note, four, since the three case must be backward compatible and return
        # the same as the earlier test above.)
        ['Foo-3.45.1.1.tar.gz' => 'v3.45.1.1', "Four-part version string with no leading 'v'"],

        # Test distros with no version
        ['Foo.tar.gz' => '', "No version"],
        ['Foo'        => '', "...with no suffix"],
    );

    my $case;
    foreach $case (@cases) {
        my ($dist_name, $expected_version, $descr) = @$case;
        my $mock = bless { remote_file => $dist_name }, $class;
        my $got_version = $mock->dist_version;
        is $got_version, $expected_version, $descr;
    	}
	};

done_testing();
