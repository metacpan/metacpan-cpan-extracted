#! perl

use strict;
use warnings;
use Test::More tests => 6;
use utf8;

BEGIN {
    use_ok( 'Music::ChordBot::Opus' );
    use_ok( 'Music::ChordBot::Opus::Section' );
    use_ok( 'Music::ChordBot::Opus::Section::Chord' );
    use_ok( 'Music::ChordBot::Opus::Section::Style' );
    use_ok( 'Music::ChordBot::Opus::Section::Style::Track' );
}

my $x = Music::ChordBot::Opus->new( "songName" => "I’m Yours" );

my $s = Music::ChordBot::Opus::Section->new;

$s->name("First");

$s->add_chord( Music::ChordBot::Opus::Section::Chord->new( qw( C Maj 4 ) ) );

my $c = Music::ChordBot::Opus::Section::Chord->new;

$c->root("G")->type("Maj")->duration(4);

$s->add_chord($c);

my $style = Music::ChordBot::Opus::Section::Style->new;
$style->chorus(5)->reverb(7);
my $track = Music::ChordBot::Opus::Section::Style::Track->new;
$track->volume(8)->id(80);
$style->add_track($track);
$style->add_track
  ( Music::ChordBot::Opus::Section::Style::Track->new->volume(7)->id(221) );

$s->set_style($style);
$x->add_section($s);
$x->name("Funky Canon");

is( $x->json . "\n", <<EOD, "resulting json" );
{"editMode":0,"fileType":"chordbot-song","sections":[{"chords":[{"duration":4,"root":"C","type":"Maj"},{"duration":4,"root":"G","type":"Maj"}],"name":"First","style":{"chorus":5,"reverb":7,"tracks":[{"id":80,"volume":8},{"id":221,"volume":7}]}}],"songName":"Funky Canon","tempo":80}
EOD
