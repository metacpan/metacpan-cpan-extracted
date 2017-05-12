#!/usr/bin/perl
use strict;
use warnings;

use Test::More;
use Parse::MIME 'parse_mime_type';

use lib 't/lib';
use TestParseMIME;
my $testcase = TestParseMIME::load_data $0;

plan tests => 0 + keys %$testcase;

while ( my ( $mime, $parsed ) = each %$testcase ) {
	is_deeply [ parse_mime_type $mime ], $parsed, $mime;
}
