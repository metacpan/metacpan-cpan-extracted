#!/usr/bin/perl -w
use strict;
use Test::More tests => 62;
use Music::Tag::Test;
use 5.006;

BEGIN { use_ok('Music::Tag') }

ok(Music::Tag->LoadOptions("t/options.conf"), "Loading options file.");
my $c = filetest("t/elise.mp3", "t/elisetest.mp3", {},{
	values_in => {
        artist =>, "Beethoven", 
		album => "GPL",
		title => "Elise",
		sha1 => '39cd05447fa9ab6d6db08f41a78ac8628874c37e',
	},
	skip_write_tests => 0,
	random_write => [
            qw(title artist album genre sortname mb_trackid lyrics encoded_by asin
            sortname albumartist_sortname albumartist mb_artistid mb_albumid album_type
            artist_type mip_puid mip_puid mip_fingerprint ) ],

	random_write_date => [ qw(releaseepoch) ],
	random_write_num => [ qw(track) ],
	picture_in => 0,
	picture_file => 'beethoven.jpg',
	picture_sha1 => 'b2bf4b2f71bf01e12473dd0ebe295777127589f4',
	picture_read => 1,
	count => 60,
	plugin => 'MP3'
});


