#!/usr/bin/perl -w

use strict;

use Test::More tests => 2;

BEGIN { use_ok('Music::Audioscrobbler::MPD') }

my %options = ( lastfm_username => "riemann42",
	            lastfm_password => "this is not my password" );

my $mpds = Music::Audioscrobbler::MPD->new( \%options );

ok ($mpds, 'Object Created');

