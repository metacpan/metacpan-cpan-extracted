#!/usr/bin/perl

# https://github.com/briandfoy/perl-version/issues/8

use strict;
use warnings;
use version 0.77;
use Perl::Version;
use Test::More;

my $class = 'Perl::Version';

subtest sanity => sub {
	use_ok $class;
	};

subtest "dev version" => sub {
	my $v1 = 'v0.10.1_01';
	my $v2 = 'v0.10.2';

	my $perl_version = Perl::Version->new( $v1 );
	isa_ok $perl_version, $class;
	is "$perl_version", $v1, "version $v1 round trips";
	cmp_ok $perl_version, '<', $v2, "version $v1 is less than $v2";

	TODO: {
		$TODO = 'version.pm is weird';
		is( version->parse( $v1 ), $v1, "version $v1 round trips in version.pm" );
		cmp_ok( version->parse( $v1 ), '<', $v2 );
		};
	};


#is( Perl::Version->new( $v1 ) <=> $v2, version->parse( $v1 ) <=> $v2 );

done_testing;
