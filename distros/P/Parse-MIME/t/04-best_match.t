#!/usr/bin/perl
use strict;
use warnings;

use Test::More;
use Parse::MIME 'best_match';

use lib 't/lib';
use TestParseMIME;
my $testcase = TestParseMIME::load_data $0;

use constant { RANGE => 0, RESULT => 1, DESC => 2 };

use List::Util 'sum';
plan tests => 0 + sum map { 0 + @{ $_->{testcases} } } @$testcase;

for my $group ( @$testcase ) {
	my $mime_types_supported = $group->{ supported };

	for my $case ( @{ $group->{ testcases } } ) {
		is best_match( $mime_types_supported, $case->[ RANGE ] ), $case->[ RESULT ], $case->[ DESC ];
	}
}
