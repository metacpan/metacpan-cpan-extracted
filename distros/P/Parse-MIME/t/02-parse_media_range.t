#!/usr/bin/perl
use strict;
use warnings;

use Test::More;
use Parse::MIME 'parse_media_range';

use lib 't/lib';
use TestParseMIME;
my $testcase = TestParseMIME::load_data $0;

plan tests => 0 + keys %$testcase;

while ( my ( $range, $parsed ) = each %$testcase ) {
	is_deeply [ parse_media_range $range ], $parsed, $range;
}
