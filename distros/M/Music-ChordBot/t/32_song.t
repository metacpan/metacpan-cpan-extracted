#! perl

use strict;
use warnings;
use Test::More tests => 2;
use utf8;

BEGIN { use_ok( 'Music::ChordBot::Song' ) }

song "All Of Me";
tempo 105;

section "All Of Me 1";
style "Chicago";

C 4; C; E7; E7; A7; A7; Dm7; Dm7; E7; E7; Am7; Am7; D7; D7; Dm7; G7;

section "All Of Me 2";
style "Swingatron";

C 4; C; E7; E7; A7; A7; Dm7; Dm7; Dm7; Ebdim7; Em7; A9; Dm7b5; G13;
C 2; Ebdim7; Dm7; G7;

is( Music::ChordBot::Song::json()."\n", <<EOD, "resulting json" );
{"editMode":1,"fileType":"chordbot-song","sections":[{"chords":[{"duration":4,"root":"C","type":"Maj"},{"duration":4,"root":"C","type":"Maj"},{"duration":4,"root":"E","type":"7"},{"duration":4,"root":"E","type":"7"},{"duration":4,"root":"A","type":"7"},{"duration":4,"root":"A","type":"7"},{"duration":4,"root":"D","type":"Min7"},{"duration":4,"root":"D","type":"Min7"},{"duration":4,"root":"E","type":"7"},{"duration":4,"root":"E","type":"7"},{"duration":4,"root":"A","type":"Min7"},{"duration":4,"root":"A","type":"Min7"},{"duration":4,"root":"D","type":"7"},{"duration":4,"root":"D","type":"7"},{"duration":4,"root":"D","type":"Min7"},{"duration":4,"root":"G","type":"7"}],"name":"All Of Me 1","style":{"chorus":4,"reverb":8,"tracks":[{"id":271,"volume":7},{"id":269,"volume":7},{"id":272,"volume":7}]}},{"chords":[{"duration":4,"root":"C","type":"Maj"},{"duration":4,"root":"C","type":"Maj"},{"duration":4,"root":"E","type":"7"},{"duration":4,"root":"E","type":"7"},{"duration":4,"root":"A","type":"7"},{"duration":4,"root":"A","type":"7"},{"duration":4,"root":"D","type":"Min7"},{"duration":4,"root":"D","type":"Min7"},{"duration":4,"root":"D","type":"Min7"},{"duration":4,"root":"Eb","type":"Dim7"},{"duration":4,"root":"E","type":"Min7"},{"duration":4,"root":"A","type":"9"},{"duration":4,"root":"D","type":"Min7(b5)"},{"duration":4,"root":"G","type":"13"},{"duration":2,"root":"C","type":"Maj"},{"duration":2,"root":"Eb","type":"Dim7"},{"duration":2,"root":"D","type":"Min7"},{"duration":2,"root":"G","type":"7"}],"name":"All Of Me 2","style":{"chorus":3,"reverb":6,"tracks":[{"id":130,"volume":7},{"id":91,"volume":7},{"id":364,"volume":7}]}}],"songName":"All Of Me","tempo":105}
EOD
