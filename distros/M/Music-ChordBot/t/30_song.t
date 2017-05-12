#! perl

use strict;
use warnings;
use Test::More tests => 2;

BEGIN { use_ok( 'Music::ChordBot::Song' ) }

song "Perl Canon";
tempo 120;

section "Funky Section";
style "Kubiac";
chord "D Min7 4";
chord "A Min7 4";
chord "D Min7 4";
chord "D Min7 4";

is( Music::ChordBot::Song::json()."\n", <<EOD, "resulting json" );
{"editMode":0,"fileType":"chordbot-song","sections":[{"chords":[{"duration":4,"root":"D","type":"Min7"},{"duration":4,"root":"A","type":"Min7"},{"duration":4,"root":"D","type":"Min7"},{"duration":4,"root":"D","type":"Min7"}],"name":"Funky Section","style":{"chorus":4,"reverb":8,"tracks":[{"id":158,"volume":7},{"id":136,"volume":7},{"id":141,"volume":7}]}}],"songName":"Perl Canon","tempo":120}
EOD
