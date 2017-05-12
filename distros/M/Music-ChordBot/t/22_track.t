#! perl

use strict;
use warnings;
use Test::More tests => 7;

BEGIN { use_ok( 'Music::ChordBot::Opus::Section::Style::Track' ) }

is_deeply( Music::ChordBot::Opus::Section::Style::Track->new( id => 1, volume => 7)->data,
	   { id => 1, volume => 7 },
	   "init args" );

is_deeply( Music::ChordBot::Opus::Section::Style::Track->new->id(1)->volume(7)->data,
	   { id => 1, volume => 7 },
	   "setters" );

my $chord = Music::ChordBot::Opus::Section::Style::Track->new->id(1)->volume(7);
is( $chord->instrument, "Synth",  "instrument 1" );
is( $chord->pattern,    "Arp 01", "pattern 1" );

$chord->id(307);
is( $chord->instrument, "Drums",         "instrument 307" );
is( $chord->pattern,    "Soft 12 - 6/8", "pattern 307" );
