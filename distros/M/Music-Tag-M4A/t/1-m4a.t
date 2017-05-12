#!/usr/bin/perl -w
use strict;
use Test::More tests => 25;
use lib 't';
use Music::Tag::Test;
use 5.006;

BEGIN { use_ok('Music::Tag') }

ok(Music::Tag->LoadOptions("t/options.conf"), "Loading options file.");
my $c = filetest("t/elise.m4a", "t/elisetest.m4a", {'write_m4a' => 1, quiet => 1},{
	values_in => {
        artist =>, "Beethoven", 
		album => "GPL",
		title => "Elise",
	},
	skip_write_tests => 0,
	count => 23,
	picture_in => 1,
	random_write => [ qw(title album comment artist  ) ],
	random_write_num => [ qw(track totaltracks) ],
	count => 32,
	plugin => 'M4A'
});


