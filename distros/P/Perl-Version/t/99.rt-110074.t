#!/usr/bin/perl

# https://github.com/briandfoy/perl-version/issues/7

use strict;
use warnings;
use Perl::Version;
use Test::More;

my $class = 'Perl::Version';

subtest sanity => sub {
	use_ok $class;
	};

subtest "roundtrip" => sub {
	my $v1 = '5.011';
	my $v2 = '5.11';

	foreach my $v ( $v1, $v2 ) {
		subtest 'as string' => sub {
			my $perl_version = Perl::Version->new( $v );
			isa_ok $perl_version, $class;
			is "$perl_version", $v, "version $v round trips";
			};

		subtest 'as number' => sub {
			my $perl_version = Perl::Version->new( $v + 0 );
			isa_ok $perl_version, $class;
			is "$perl_version", $v + 0, "version $v round trips";
			};
		}

	cmp_ok( Perl::Version->new($v1), '==', Perl::Version->new($v2),
		"string versions $v1 and $v2 are the same" );
	cmp_ok( Perl::Version->new($v1+0), '==', Perl::Version->new($v2+0),
		"number versions $v1 and $v2 are the same" );
	};

done_testing;
