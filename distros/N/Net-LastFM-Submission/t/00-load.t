#!/usr/bin/perl

use lib '../lib';
use Test::More tests => 1;

BEGIN {
	use_ok( 'Net::LastFM::Submission' );
}

# diag( "Testing Net::LastFM::Submission $Net::LastFM::Submission::VERSION, Perl $], $^X" );
