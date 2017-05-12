#! perl

use strict;
use warnings;
use Test::More tests => 7;

BEGIN {
    use_ok( 'Music::ChordBot::Opus::Section::Style' );
    use_ok( 'Music::ChordBot::Opus::Section::Style::Track' );
}

is_deeply( Music::ChordBot::Opus::Section::Style->new->data,
	   { chorus => 4, reverb => 8, tracks => [] },
	   "no args" );

is_deeply( Music::ChordBot::Opus::Section::Style->new( reverb => 6 )->data,
	   { chorus => 4, reverb => 6, tracks => [] },
	   "init args" );

my $t = Music::ChordBot::Opus::Section::Style->new;

$t->chorus(1)->reverb(2)->legacy(3)->beats(4)->divider(5);

is_deeply( $t->data,
	   { chorus => 1, reverb => 2, tracks => [],
	     legacy => 3, beats => 4, divider => 5 },
	   "1 2 [] 3 4 5" );

is_deeply( Music::ChordBot::Opus::Section::Style->preset("Rhododendron")->data,
	   { chorus => 5, reverb => 7,
	     tracks => [ { id => 258, volume => 7 },
			 { id => 278, volume => 7 },
			 { id => 302, volume => 7 } ] },
	   "preset Rhododendron" );

$t = Music::ChordBot::Opus::Section::Style->new;
$t->chorus(5)->reverb(7);
$t->add_track( Music::ChordBot::Opus::Section::Style::Track->new( id => 258, volume => 7 ) );
$t->add_track( Music::ChordBot::Opus::Section::Style::Track->new( id => 278, volume => 7 ) );
$t->add_track( Music::ChordBot::Opus::Section::Style::Track->new( id => 302, volume => 7 ) );

is_deeply( $t->data,
	   { chorus => 5, reverb => 7,
	     tracks => [ { id => 258, volume => 7 },
			 { id => 278, volume => 7 },
			 { id => 302, volume => 7 } ] },
	   "explicit Rhododendron" );
