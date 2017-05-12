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

$s->set_style("Triplepicker");
$x->add_section($s);
$x->name("Funky Canon");

is( $x->json . "\n", <<EOD, "resulting json" );
{"editMode":0,"fileType":"chordbot-song","sections":[{"chords":[{"duration":4,"root":"C","type":"Maj"},{"duration":4,"root":"G","type":"Maj"}],"name":"First","style":{"beats":3,"chorus":5,"divider":4,"reverb":7,"tracks":[{"id":307,"volume":7},{"id":286,"volume":7},{"id":221,"volume":7}]}}],"songName":"Funky Canon","tempo":80}
EOD
