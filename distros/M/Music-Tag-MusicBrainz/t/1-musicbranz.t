#!/usr/bin/perl -w
use strict;

use Test::More tests => 6;
use 5.006;

BEGIN { use_ok('Music::Tag') }

my $tag = Music::Tag->new( undef,  { artist => "Sarah Slean",
								     album => "Orphan Music",
									 title => "Mary",
									 ANSIColor => 0,
									 quiet => 1,
									 locale => "ca" } , "Option" );

ok( $tag, 'Object created');
ok( $tag->add_plugin("MusicBrainz"));
ok( $tag->get_tag, 'get_tag called' );
is ( $tag->track , 4, 'track set');
is ( $tag->mb_albumid , "c2174ef2-de71-4f54-be69-af60091ac2f4", 'mb_albumid set');

