#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
  use_ok(
    'Music::Abc::DT',
    qw( dt dt_string toabc get_meter get_length get_wmeasure get_gchords get_key get_time get_time_ql
    is_major_triad is_minor_triad is_dominant_seventh get_chord_step get_fifth get_third get_seventh
    root find_consecutive_notes_in_measure get_pitch_class get_pitch_name $c_voice $sym
    %voice_struct )
    )
    || print "Bail out!\n";
}

diag("Testing Music::Abc::DT $Music::Abc::DT::VERSION, Perl $], $^X");
