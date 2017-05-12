#!/usr/bin/perl -w
use strict;

use Test::More tests => 5;

use 5.006;

BEGIN { use_ok('Music::Tag') }

my $tag = Music::Tag->new( undef,  { artist => "Sarah Slean",
								     title => "Eliot",
									 ANSIColor => 0,
									 quiet => 1,
									 #lyricsfetchers	=> "LyricWiki",
								   } , "Option" );

ok( $tag, 'Object created');
ok( $tag->add_plugin("LyricsFetcher"), "Plugin Added");
ok( $tag->get_tag, 'get_tag called' );
ok ( $tag->lyrics =~ /I dream of Eliot/, 'Lyrics found');

