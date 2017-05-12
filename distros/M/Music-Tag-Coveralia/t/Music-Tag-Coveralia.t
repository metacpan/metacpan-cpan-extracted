#!/usr/bin/perl
use strict;
use warnings;

use Test::RequiresInternet qw/www.coveralia.com 80/;
use Test::More tests => 3;
use Music::Tag traditional => 1;
BEGIN { use_ok('Music::Tag::Coveralia') };

sub test {
	my ($artist, $album, $expect) = @_;
	my $mt = Music::Tag->new('t/empty.flac', {$ENV{TEST_VERBOSE} ? (verbose => 1) : (quiet => 1)});
	$mt->artist($artist);
	$mt->album($album);
	$mt->add_plugin('Coveralia');
	$mt->get_tag;
	my $exists = $expect ? 'exists' : 'does not exist';
	is $mt->has_data('picture'), $expect, "$artist - $album $exists"
}

test 'Metallica', 'Ride The Lightning', 1;
test 'Metal', 'Ride The Lightning', 0;
