#! perl

use strict;
use warnings;
use Test::More tests => 2;
use utf8;

BEGIN { use_ok( 'Music::ChordBot::Song' ) }

song "I’m Yours";
tempo 75;

section "Section 1";
style "Hammered";

chord "C Maj 4";
chord "G Maj 4";
chord "A Min 4";
chord "F Maj 4";
chord "C Maj 4";
chord "G Maj 4";
chord "A Min 4";
chord "F Maj 4";
chord "D Maj 1";
chord "D Silence 7";

is( Music::ChordBot::Song::json()."\n", <<EOD, "resulting json" );
{"editMode":0,"fileType":"chordbot-song","sections":[{"chords":[{"duration":4,"root":"C","type":"Maj"},{"duration":4,"root":"G","type":"Maj"},{"duration":4,"root":"A","type":"Min"},{"duration":4,"root":"F","type":"Maj"},{"duration":4,"root":"C","type":"Maj"},{"duration":4,"root":"G","type":"Maj"},{"duration":4,"root":"A","type":"Min"},{"duration":4,"root":"F","type":"Maj"},{"duration":1,"root":"D","type":"Maj"},{"duration":7,"root":"D","type":"Silence"}],"name":"Section 1","style":{"chorus":4,"reverb":8,"tracks":[{"id":95,"volume":7},{"id":201,"volume":7}]}}],"songName":"I’m Yours","tempo":75}
EOD
