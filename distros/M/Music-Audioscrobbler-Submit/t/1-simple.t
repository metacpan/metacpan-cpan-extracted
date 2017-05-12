#!/usr/bin/perl -w
# Anything more than this will require submiting to last.fm...

use strict;

use Test::More tests => 2;

BEGIN { use_ok('Music::Audioscrobbler::Submit') }

my %options = ( lastfm_username => "riemann42",
	            lastfm_password => "this is not my password" );

my $mpds = Music::Audioscrobbler::Submit->new( \%options );

ok ($mpds, 'Object Created');

