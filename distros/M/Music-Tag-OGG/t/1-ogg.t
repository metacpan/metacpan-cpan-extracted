#!/usr/bin/perl -w
use strict;

use Test::More tests => 9;
use Music::Tag::Test;
use 5.006;

BEGIN { use_ok('Music::Tag') }

ok(Music::Tag->LoadOptions("t/options.conf"), "Loading options file.");
my $c = filetest("t/elise.ogg", "t/elisetest.ogg", {},{
	values_in => {
        artist =>, "Beethoven", 
		album => "GPL",
		title => "Elise",
	},
	skip_write_tests => 1,
	random_write => [
            qw(title artist album genre comment mb_trackid asin
            mb_artistid mb_albumid albumartist  ) ],
	random_write_num => [ qw(track disc) ],
	count => 7,
	plugin => 'OGG'
});
