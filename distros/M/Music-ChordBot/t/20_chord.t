#! perl

use strict;
use warnings;
use Test::More tests => 7;

BEGIN { use_ok( 'Music::ChordBot::Opus::Section::Chord' ) }

is_deeply( Music::ChordBot::Opus::Section::Chord->new("D", "Min7", 4)->data,
	   { root => "D", type => "Min7", duration => 4 },
	   "D, Min7, 4" );

is_deeply( Music::ChordBot::Opus::Section::Chord->new("D Min7 4")->data,
	   { root => "D", type => "Min7", duration => 4 },
	   "D Min7 4" );

my $chord = Music::ChordBot::Opus::Section::Chord->new("D Min7 4");
is_deeply( $chord->root("B")->duration(6)->data,
	   { root => "B", type => "Min7", duration => 6 },
	   "D>Min7>4" );

$chord = Music::ChordBot::Opus::Section::Chord->new("D Min7 4");
is_deeply( $chord->root("B")->bass("F")->inversion(6)->data,
	   { root => "B", type => "Min7", duration => 4,
	     bass => "F", inversion => 6 },
	   "D>Min7>4 + inv + bass" );

is_deeply( Music::ChordBot::Opus::Section::Chord->new("D/F", "Maj", 4)->data,
	   { root => "D", type => "Maj", duration => 4, bass => "F" },
	   "D/F, Maj, 4" );

is_deeply( Music::ChordBot::Opus::Section::Chord->new("D/F Maj 4")->data,
	   { root => "D", type => "Maj", duration => 4, bass => "F" },
	   "D/F Maj 4" );
