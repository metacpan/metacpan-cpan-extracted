package Music::Abc::DT;

  use 5.01400;
  use strict;
  use warnings FATAL => 'all';

BEGIN {

  use Data::Dumper;
  use Readonly;
  use feature 'state'; #state variables are enabled
  use Exporter 'import'; # gives you Exporter's import() method directly
  use POSIX ();
  use File::Temp ();
  use List::MoreUtils qw{any};

  our $VERSION = '0.01';

  our %EXPORT_TAGS = (
    'all' => [
      qw( _broken_rhythm _head_par _length_header_dump _meter_calc _pscom_to_abc _slur_dump
        _vover_to_abc _tuplet_to_abc _get_transformation _get_note_rest_bar_actuators
        _get_null_info_clef_actuators _bar_dump _deco_dump _step_dump _get_chord_notes
        _diatonic_interval _get_alter _get_chromatic_info _get_generic_info _get_ps
        _get_specifier_from_generic_chromatic _interval_from_generic_and_chromatic _notes_to_chromatic
        _notes_to_generic _notes_to_interval _convert_staff_distance_to_interval $brhythm @blen
        $deco_tb %state_name )
    ]
  );

  our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

  # If you are only exporting function names it is recommended to omit the ampersand, as the
  # implementation is faster this way.
  our @EXPORT =
    qw( &dt &dt_string &toabc &get_meter &get_length &get_wmeasure &get_gchords &get_key &get_time
    &get_time_ql &is_major_triad &is_minor_triad &is_dominant_seventh &get_chord_step &get_fifth
    &get_third &get_seventh &root &find_consecutive_notes_in_measure &get_pitch_class
    &get_pitch_name $c_voice $sym %voice_struct);

  use vars
    qw( $deco_tb $in_grace $brhythm $gbr @blen $micro_tb $c_voice %voice_struct $c_tune $c_sym_ix
    $c_abc $sym $c_bar %sym_name %state_name %info_name %STEPREF @key_shift @key_tonic $ly_st @clef_type
    $toabc_called_outside $toabc_called_inside $GLOBAL $IMPLICIT_VOICE $QUARTER_LENGTH $FIRST_MEASURE);

  Readonly our $GLOBAL         => 'global';   # identifies data that is applied to the entire score (voice independent)
  Readonly our $IMPLICIT_VOICE => 0;          # default voice
  Readonly our $QUARTER_LENGTH => 384;        # default value for quarter length (abcm2ps)
  Readonly our $FIRST_MEASURE  => 1;          # default value for the first measure

  use constant {    # info type
    ABC_T_NULL   => 0,
    ABC_T_INFO   => 1,   #  (first character of text gives the info type)
    ABC_T_PSCOM  => 2,
    ABC_T_CLEF   => 3,
    ABC_T_NOTE   => 4,
    ABC_T_REST   => 5,
    ABC_T_BAR    => 6,
    ABC_T_EOLN   => 7,
    ABC_T_MREST  => 8,   #  multi-measure rest
    ABC_T_MREP   => 9,   #  measure repeat
    ABC_T_V_OVER => 10,  #  voice overlay
    ABC_T_TUPLET => 11,
  };

  use constant { # symbol state in file/tune
    ABC_S_GLOBAL  => 0,      # global
    ABC_S_HEAD    => 1,      # in header (after X:)
    ABC_S_TUNE    => 2,       # in tune (after K:)
    ABC_S_EMBED   => 3     # embedded header (between [..])
  };


  use constant { # info flags
    ABC_F_ERROR       => 0x0001,  #  error around this symbol
    ABC_F_INVIS       => 0x0002,  #  invisible symbol
    ABC_F_SPACE       => 0x0004,  #  space before a note
    ABC_F_STEMLESS    => 0x0008,  #  note with no stem
    ABC_F_LYRIC_START => 0x0010,  #  may start a lyric here
    ABC_F_GRACE       => 0x0020,  #  grace note
    ABC_F_GR_END      => 0x0040,  #  end of grace note sequence
    ABC_F_SAPPO       => 0x0080   #  short appoggiatura
  };

  use constant { # key mode
    MAJOR   =>  7,
    MINOR   =>  8,
    BAGPIPE =>  9  #  bagpipe when >= 8
  };

  use constant { # clef type
    TREBLE =>  0,
    ALTO   =>  1,
    BASS   =>  2,
    PERC   =>  3
  };

  use constant { # voice overlay
    V_OVER_V  => 0,  #  &
    V_OVER_S  => 1,  #  (&
    V_OVER_E  => 2   #  &)
  };

  # key signatures
  use constant KEY_NAMES => qw(ionian dorian phrygian lydian mixolydian aeolian locrian major minor HP Hp);

  use constant { NONE     => 'none' };
  use constant { MAXVOICE => 32 }; # max number of voices
  use constant { BASE_LEN => 1536 }; # basic note length (semibreve or whole note - same as MIDI)
  use constant { DEFAULT_METER  => '4/4' };
  use constant { DEFAULT_LENGTH => '1/8' };

  use constant { # accidentals
    A_NULL  =>  0,  #  none
    A_SH    =>  1,  #  sharp
    A_NT    =>  2,  #  natural
    A_FT    =>  3,  #  flat
    A_DS    =>  4,  #  double sharp
    A_DF    =>  5   #  double flat
  };


  use constant { # bar types
    B_BAR   => 1,  #  |
    B_OBRA  => 2,  #  [
    B_CBRA  => 3,  #  ]
    B_COL   => 4   #  :
  };

  use constant { # slur/tie types (3 bits)
    SL_ABOVE  =>  0x01,
    SL_BELOW  =>  0x02,
    SL_AUTO   =>  0x03,
    SL_DOTTED =>  0x04  #  (modifier bit)
  };

  our ( $in_grace, $brhythm, $gbr, $ly_st, $c_voice, %voice_struct );
  our ( @blen, $micro_tb, $deco_tb );
  our ( $c_tune, $c_sym_ix, $c_abc, $toabc_called_outside, $toabc_called_inside );

  our %sym_name = (
    # the extra () around the constants are there to fool the auto quoting
    (ABC_T_NULL)    => 'null',
    (ABC_T_INFO)    => 'info',
    (ABC_T_PSCOM)   => 'pscom',
    (ABC_T_CLEF)    => 'clef',
    (ABC_T_NOTE)    => 'note',
    (ABC_T_REST)    => 'rest',
    (ABC_T_BAR)     => 'bar',
    (ABC_T_EOLN)    => 'eoln',
    (ABC_T_MREST)   => 'mrest',
    (ABC_T_MREP)    => 'mrep',
    (ABC_T_V_OVER)  => 'vover',
    (ABC_T_TUPLET)  => 'tuplet',
  );
  our %info_name = (
    'K'             => 'key',
    'L'             => 'length',
    'M'             => 'meter',
    'Q'             => 'tempo',
    'V'             => 'voice',
    'w'             => 'lyrics',
    'W'             => 'lyrics',
  );
  our %state_name = (
    (ABC_S_GLOBAL)  => 'in_global',
    (ABC_S_HEAD)    => 'in_header',
    (ABC_S_TUNE)    => 'in_tune',
    (ABC_S_EMBED)   => 'in_line',
  );

  our @key_tonic = qw(F C G D A E B);
  our @key_shift = (1, 3, 5, 0, 2, 4, 6, 1, 4); # [7 + 2]
  our @clef_type = qw(treble alto bass perc);

}


# Processes abc tunes;
# Receives the filename of an abc tune
# Receives a set of expressions (functions) defining the processing and associated values for each element
sub dt {
  my ( $abcfile, %abch ) = @_;
  my $abc_struct = eval `aux-abc2perl $abcfile`;

  my $return = _dt_processing( $abc_struct, %abch );
  return $return;
}

# Works in a similar way of dt but takes input from a string instead of a file name
sub dt_string {
  my ( $string, %abch ) = @_;

  my $tmp_abcfile = File::Temp->new( SUFFIX => '.abc' );
  print {$tmp_abcfile} $string;

  my $abc_struct = eval `aux-abc2perl $tmp_abcfile`;

  my $return = _dt_processing( $abc_struct, %abch );

  return $return;
}

# Returns a list of consecutive note structures belonging to the same measure
#
# A single undef is placed in the list at any point there is a discontinuity (such as if there is a
# rest between two pitches), unless the `no_undef` parameter is True.
#
# How to determine consecutive pitches is a little tricky and there are many options:  The
# `$args->{skip_unisons}` parameter uses the midi-note value (ps) to determine unisons, so enharmonic
# transitions (F# -> Gb) are also skipped if `$args->{skip_unisons}` is true. Music21 believes that
# this is the most common usage. However, because of this, you cannot completely be sure that the
# find_consecutive_notes_in_measure() - find_consecutive_notes_in_measure({$args->{skip_unisons} =>
# 1}) will give you the number of P1s (Perfect First) in the piece, because there could be d2's
# (Diminished Second) in there as well.
sub find_consecutive_notes_in_measure {
  my $args = shift;

  my $return_list    = [];
  my $n_symbols      = scalar( @{ $c_tune->{symbols} } ) - 1;
  my $last_start     = 0;
  my $last_end       = -1;
  my $last_was_undef = 0;
  my $c_sym_offset   = 0;
  my $last_note;

  if ( $args->{skip_octaves} ) { $args->{skip_unisons} = 1; }    # implied

  for my $ix ( $c_sym_ix .. $n_symbols ) {
    my $c_sym = $c_tune->{symbols}->[$ix];

    # stops searching if it reaches the end of the measure
    last if $c_sym->{type} == ABC_T_BAR;

    if (     not $last_was_undef
         and not $args->{skip_gaps}
         and $c_sym_offset > $last_end
         and not $args->{no_undef} )
    {
      push @{ $return_list }, undef;
      $last_was_undef = 1;
    }

    # if it's a single note
    if ( $c_sym->{type} == ABC_T_NOTE and $c_sym->{info}->{nhd} == 0 ) {
      _check_consecutive_note(
                               {
                                 return_list    => $return_list,
                                 main_args      => $args,
                                 c_sym_offset   => $c_sym_offset,
                                 c_sym          => $c_sym,
                                 last_start     => $last_start,
                                 last_end       => $last_end,
                                 last_was_undef => $last_was_undef,
                                 last_note      => $last_note
                               }
                             );
    }
    # it's a chord
    elsif ( $c_sym->{type} == ABC_T_NOTE and $c_sym->{info}->{nhd} > 0 ) {
      _check_consecutive_chord(
                                {
                                  return_list    => $return_list,
                                  main_args      => $args,
                                  c_sym_offset   => $c_sym_offset,
                                  c_sym          => $c_sym,
                                  last_start     => $last_start,
                                  last_end       => $last_end,
                                  last_was_undef => $last_was_undef,
                                  last_note      => $last_note
                                }
                              );
    }
    # it's a rest
    elsif (     not $args->{skip_rests}
            and $c_sym->{type} == ABC_T_REST
            and not $last_was_undef
            and not $args->{no_undef} )
    {
      push @{$return_list}, undef;
      $last_was_undef = 1;
      $last_note      = undef;
    }
    elsif ( $args->{skip_rests} and $c_sym->{type} == ABC_T_REST ) {
      $last_end = $c_sym_offset + $c_sym->{info}->{dur};
    }

    # increases the time offset
    if ( $c_sym->{info}->{dur} ) { $c_sym_offset += $c_sym->{info}->{dur} }
  }

  # removes the last-added element
  if ($last_was_undef) { pop @{$return_list} }

  return @{$return_list};
}

# Dumps a note's guitar/accompaniment chords
sub get_gchords {
  my $sym;
  if   ( not @_ ) { $sym = $Music::Abc::DT::sym; }
  else            { $sym = shift; }

  return "$sym->{text}\n";
  #FIXME return undef if not a note|rest|bar
}

# Dumps the current voice's key
sub get_key {
  return $voice_struct{$c_voice}{key}{text} || undef;
}

# Dumps the current voice's length
sub get_length {
  return $voice_struct{$c_voice}{length} || undef;
}

# Dumps the current voice's meter
sub get_meter {
  return $voice_struct{$c_voice}{meter}{text} || undef;
}

# Dumps the current voice's time elapsed until the current symbol (time offset)
sub get_time {
  return $voice_struct{$c_voice}{time};
  # return $sym->{info}->{time};
  #FIXME return undef if not in_tune or in_line
}

# Dumps the current voice's elapsed time until the current symbol (time offset) in quarter lengths (ql)
sub get_time_ql {
  # return $sym->{info}->{time} / $QUARTER_LENGTH;
  return $voice_struct{$c_voice}{time} / $QUARTER_LENGTH;
  #FIXME return undef if not in_tune or in_line
}

# Dumps the current voice's wmeasure
sub get_wmeasure {
  return $voice_struct{$c_voice}{meter}{wmeasure};
}

# Default function for the processor
# Dumps a symbol's ABC
sub toabc {
  # Returns the context of the current subroutine call
  my ( $package, $filename, $line ) = caller;

  # set to true if it has been called outside of the module
  $toabc_called_outside = $package ne 'Music::Abc::DT';
  $toabc_called_inside  = $package eq 'Music::Abc::DT';

  my $sym;
  if   ( not @_ ) { $sym = $Music::Abc::DT::sym; }
  else            { $sym = shift; }

  my ( $new_abc, $c, $nl_new ) = ( q{}, q{}, 0 );

  $c = $c_abc eq q{} ? "\n"
     :                 substr $c_abc, length($c_abc) - 1, 1; # last character
  # if   ( $c_abc eq q{} ) { $c = "\n"; }
  # else                   { $c = substr $c_abc, length($c_abc) - 1, 1; } # last character

  # put space when one is found
  if ( $sym->{flags} & ABC_F_SPACE ) { $new_abc .= q{ } }

  # if the last symbol was inside a grace note block
  if ( $in_grace
       && ( $sym->{type} != ABC_T_NOTE || !( $sym->{flags} & ABC_F_GRACE ) ) )
  {
    $in_grace = 0;      # out of grace note state
    $brhythm  = $gbr;
    $new_abc .= '}';    # close grace notes
  }

  given ($sym->{type}) { # symbol type
    when (ABC_T_INFO               )  { ($new_abc, $nl_new) = _info_to_abc($new_abc, $sym, $c, $nl_new) } # type: info
    when ([ABC_T_PSCOM, ABC_T_NULL])  { ($new_abc, $nl_new) = _pscom_to_abc($new_abc, $sym, $c) }         # type: pscom
    when (ABC_T_NOTE               )  { $new_abc = _pre_note_to_abc($new_abc, $sym); continue }           # type: note
    when ([ABC_T_NOTE,ABC_T_REST]  )  { $new_abc = _note_to_abc($new_abc, $sym) }                         # type: note | rest
    when (ABC_T_BAR                )  { $new_abc = _bar_to_abc($new_abc, $sym, $c) }                      # type: bar
    when (ABC_T_CLEF               )  { return $new_abc }                                                 # type: clef
    when (ABC_T_EOLN               )  { ($new_abc, $nl_new) = _eoln_to_abc($new_abc, $sym, $c, $nl_new) } # type: eoln
    when (ABC_T_MREST              )  { $new_abc .= sprintf 'Z%d', $sym->{info}->{len} }                  # type: mrest
    when (ABC_T_MREP               )  { foreach (0..$sym->{info}->{len}-1) { $new_abc .= q{/} } }         # type: mrep
    when (ABC_T_V_OVER             )  { $new_abc = _vover_to_abc($new_abc, $sym) }                        # type: v_over
    when (ABC_T_TUPLET             )  { $new_abc = _tuplet_to_abc($new_abc, $sym) }                       # type: tuplet
  }

  if ( $sym->{comment} ne q{} ) {
    if ( $new_abc ne q{} ) { $new_abc .= "\t" }
    $new_abc .= "%$sym->{comment}";
    $nl_new = 1;
  }
  if ( $nl_new || !ref( $c_tune->{symbols}->[ $c_sym_ix + 1 ] ) ) {
    $new_abc .= "\n";
    # _lyrics_dump( $new_abc, $sym );
  }

  return $new_abc;
}

########################################### PRIVATE FUNCTIONS ######################################33

# Adds a note/chord to the list of consecutive notes if it meets the criteria
sub _add_consecutive_note {
  my $args           = shift;
  my $c_sym_offset   = $args->{c_sym_offset};
  my $c_sym          = $args->{c_sym};
  my $return_list    = $args->{return_list};
  my $last_start     = $args->{last_start};
  my $last_end       = $args->{last_end};
  my $last_was_undef = $args->{last_was_undef};
  my $last_note      = $args->{last_note};

  if ( $args->{main_args}->{get_overlaps} or $c_sym_offset >= $last_end ) {
    if ( $c_sym_offset >= $last_end ) {    # is not an overlap...
      $last_start = $c_sym_offset;
      $last_end = $c_sym->{info}->{dur} ? $last_start + $c_sym->{info}->{dur}
                                        : $last_start;
      $last_was_undef = 0;
      $last_note      = $c_sym;
    }
    # else do not update anything for overlaps

    push @{$return_list}, $c_sym;
  }

  return;
}

# Checks if a chord meets the criteria to be added to a list of consecutive notes
sub _check_consecutive_chord {
  my $args           = shift;
  my $main_args      = $args->{main_args};
  my $c_sym_offset   = $args->{c_sym_offset};
  my $c_sym          = $args->{c_sym};
  my $return_list    = $args->{return_list};
  my $last_start     = $args->{last_start};
  my $last_end       = $args->{last_end};
  my $last_was_undef = $args->{last_was_undef};
  my $last_note      = $args->{last_note};

  if (     $main_args->{skip_chords}
       and not $last_was_undef
       and not $main_args->{no_undef} )
  {
    push @{$return_list}, undef;
    $last_was_undef = 1;
    $last_note      = undef;
  }

  # if we have a chord
  else {
    if (     $main_args->{skip_unisons}
         and ( $last_note and $last_note->{info}->{nhd} > 0 )
         and _get_ps($c_sym) == _get_ps($last_note) )
    { # pass
    } else {
      _add_consecutive_note(
                             {
                               return_list    => $return_list,
                               main_args      => $main_args,
                               c_sym_offset   => $c_sym_offset,
                               c_sym          => $c_sym,
                               last_start     => $last_start,
                               last_end       => $last_end,
                               last_was_undef => $last_was_undef,
                               last_note      => $last_note
                             }
                           );
    }
  }

  return;
}

# Checks if a note meets the criteria to be added to a list of consecutive notes
sub _check_consecutive_note {
  my $args           = shift;
  my $main_args      = $args->{main_args};
  my $c_sym_offset   = $args->{c_sym_offset};
  my $c_sym          = $args->{c_sym};
  my $return_list    = $args->{return_list};
  my $last_start     = $args->{last_start};
  my $last_end       = $args->{last_end};
  my $last_was_undef = $args->{last_was_undef};
  my $last_note      = $args->{last_note};

  if (
          not $main_args->{skip_unisons}
       or ( $last_note and $last_note->{info}->{nhd} > 0 )
       or not $last_note
       or get_pitch_class($c_sym) != get_pitch_class($last_note)
       or ( not $main_args->{skip_octaves}
            and _get_ps($c_sym) != _get_ps($last_note) )
     )
  {
    _add_consecutive_note(
                           {
                             return_list    => $return_list,
                             main_args      => $main_args,
                             c_sym_offset   => $c_sym_offset,
                             c_sym          => $c_sym,
                             last_start     => $last_start,
                             last_end       => $last_end,
                             last_was_undef => $last_was_undef,
                             last_note      => $last_note
                           }
                         );
  }

  return;
}

# -- dumps the bar symbol without decorations or guitar chords
sub _bar_dump {
  my ( $new_abc, $sym, $c ) = @_;

  if ( $sym->{info}->{dotted} ) { $new_abc .= q{.} }

  if ( !$sym->{info}->{repeat_bar} || $c ne q{|} ) {
    my($t, $v) = ($sym->{info}->{type}, 0);

    while ($t) {
      #NOTE this instruction replaced the next: $v <<= 4;
      $v = $v * ( 2**4 );    # left shift
      $v |= ( $t & 0x0f );
      $t >>= 4;
    }
    while ($v) {
      $new_abc .= qw(? | [ ] : ? ? ?)[$v & 0x07];
      $v >>= 4;
    }
  }

  if ( $sym->{info}->{repeat_bar} ) {
    # it has only one character and it is a digit
    if ( $sym->{text} =~ /^\d$/xms ) {
      $new_abc .= $sym->{text};    # repeat
    } else {
      $new_abc .= sprintf '"%s"', $sym->{text};
    }
  } elsif ( $sym->{info}->{type} == B_OBRA ) {
    $new_abc .= ']';
  }

  return $new_abc;
}

# -- return abc for bar symbol
sub _bar_to_abc {
  my ( $new_abc, $sym, $c ) = @_;
#FIXME PARSER should store the spaces that exist before a bar ('flags' => ABC_F_SPACE; it's always 0)

  if ( $sym->{info}->{dc}->{n} ) {
    $new_abc = _deco_dump( $sym->{info}->{dc}, $new_abc );
  }

  if ( $sym->{text} ne q{} && !$sym->{info}->{repeat_bar} ) {
    $new_abc = _gchord_dump( $new_abc, $sym->{text} );
  }

  $new_abc = _bar_dump( $new_abc, $sym, $c );

  return $new_abc;
}


# -- change length when broken rhythm --
sub _broken_rhythm {
  my $len = shift;

  given ($brhythm) {
    when (-3) { $len *= 8; }
    when (-2) { $len *= 4; }
    when (-1) { $len *= 2; }
    when (0 ) { return $len; }
    when (1 ) { $len = $len * 2 / 3; }
    when (2 ) { $len = $len * 4 / 7; }
    when (3 ) { $len = $len * 8 / 15; }
  }
  if ( $len % 24 != 0 ) { $len = ( $len + 12 ) / 24 * 24 }
  return $len;
}

# -- dumps the broken rhythm symbol
sub _broken_rhythm_dump {
  my $new_abc = shift;

  $brhythm = -$sym->{info}->{brhythm};
  if ( $brhythm != 0 ) {
    my ( $c, $n );
    if ( ( $n = $brhythm ) < 0 ) {
      $n = -$n;
      $c = '>';
    } else {
      $c = '<';
    }
    while ( --$n >= 0 ) { $new_abc .= $c }
  }

  return $new_abc;
}

# -- dumps a chord's ties
sub _chord_tie {
  my ( $new_abc, $all_tie ) = @_;

  if ($all_tie) {
    if ( $all_tie & SL_DOTTED ) { $new_abc .= q{.} }
    $new_abc .= q{-};
    given ($all_tie) {
      when (SL_ABOVE) { $new_abc .= q{'}; }
      when (SL_BELOW) { $new_abc .= q{,}; }
    }
  }

  return $new_abc;
}

# -- dumps a chords's notes, slurs, ties, ...
sub _chord_to_abc {
  my ( $sym, $new_abc, $all_tie ) = @_;
  my $len;

  # for each note in the symbol / chord(if nhd>0)
  for my $i ( 0 .. $sym->{info}->{nhd} ) {

    # the $i'th note of the chord has decorations
    if ( $sym->{info}->{decs}->[$i] ) {
      my ( $i1, $i2, $deco );

      $i1 = $sym->{info}->{decs}->[$i] >> 3;
      $i2 = $i1 + ( $sym->{info}->{decs}->[$i] & 0x07 );
      for ( ; $i1 < $i2 ; $i1++ ) {
        $deco = $sym->{info}->{dc}->t->[$i1];

        # prints single decoration character
        if ( $deco < 128 ) {
          if ($deco) { $new_abc .= chr $deco }
        }
        # prints the decoration name enclosed in !!
        else { $new_abc .= sprintf '!%s!', $deco_tb->{ $deco - 128 } }
      }
    }

    # start slur
    # sl1: slur start per head
    if ( $sym->{info}->{sl1}->[$i] ) {
      $new_abc = _slur_dump( $new_abc, $sym->{info}->{sl1}->[$i] );
    }

    # lens: note lengths
    $len = _broken_rhythm( $sym->{info}->{lens}->[$i] );

    # chlen: chord length
    if ( $sym->{info}->{chlen} ) {
      $len = $len * BASE_LEN / $sym->{info}->{chlen};
    }

    $new_abc = _note_dump(
                           $new_abc,
                           $sym->{info}->{pits}->[$i],
                           $sym->{info}->{accs}->[$i],
                           $len,
                           $sym->{flags} & ABC_F_STEMLESS
                         );

    # prints tie for individual notes only
    # ti1: flag to start tie here;
    if ( $sym->{info}->{ti1}->[$i] && $sym->{info}->{ti1}->[$i] != $all_tie ) {
      if ( $sym->{info}->{ti1}->[$i] & SL_DOTTED ) { $new_abc .= q{.} }
      $new_abc .= q{-};
      given ( $sym->{info}->{ti1}->[$i] ) {    # tie direction
        when (SL_ABOVE) { $new_abc .= q{'}; }
        when (SL_BELOW) { $new_abc .= q{,}; }
      }
    }

    # end slur
    # sl2: number of slur end per head
    for ( $len = $sym->{info}->{sl2}->[$i] ; --$len >= 0 ; ) {
      $new_abc .= ')';
    }
  }

  return $new_abc;
}


# -- dump a clef definition --
sub _clef_dump {
  my($abc, $sym) = @_;
  my($clef, $clef_line);

  if (($clef = $sym->{info}->{type}) >= 0) { # clef is defined
    $clef_line = $sym->{info}->{line};

    given ($clef) {
      when (TREBLE)             { continue }
      when ( [ PERC, TREBLE ] ) { if ( $clef_line == 2 ) { $clef_line = 0 } }
      when (ALTO)               { if ( $clef_line == 3 ) { $clef_line = 0 } }
      when (BASS)               { if ( $clef_line == 4 ) { $clef_line = 0 } }
    }

    #name
    if ( $sym->{info}->{name} ne q{} ) {
      $abc .= " clef=\"$sym->{info}->{name}\"";
    }
    #invis
    elsif ( $clef_line == 0 ) {
      $abc .= ' clef=' . ( $sym->{info}->{invis} ? NONE : $clef_type[$clef] );
    }
    #clef
    else { $abc .= ' clef=' . $clef_type[$clef] . $clef_line }

    #octave
    if ( $sym->{info}->{octave} != 0 ) {
      $abc .= ( $sym->{info}->{octave} > 0 ? q{+} : q{-} ) . '8';
    }
  }
  #stafflines
  if ( $sym->{info}->{stafflines} >= 0 ) {
    $abc .= " stafflines=$sym->{info}->{stafflines}";
  }
  #staffscale
  if ( $sym->{info}->{staffscale} != 0 ) {
    $abc .= ' staffscale=' . sprintf '%.2f', $sym->{info}->{staffscale};
  }

  return $abc;
}

# -- dump the decorations --
sub _deco_dump {
  my ( $dc, $abc ) = @_;
  my ( $deco, $i );

  for my $i ( 0 .. $dc->{n} - 1 ) {
    next if ( $i >= $dc->{h} && $i < $dc->{s} );    # skip the head decorations
    $deco = $dc->{t}->[$i];
    if ( $deco < 128 ) {    # prints single decoration character
      if ($deco) { $abc .= chr $deco }
    }
    else {    # prints the decoration name enclosed in !!
      $abc .= sprintf '!%s!', $deco_tb->{ $deco - 128 };
    }
  }
  return $abc;
}

sub _dt_processing {
  my ( $abc_struct, %abch ) = @_;

  my $return     = q{};
  my $tunes      = $abc_struct->{tunes};

  $deco_tb = $abc_struct->{deco_tb};

  foreach my $tune ( keys %{$tunes} ) {    # tune
    $in_grace = 0;                              # in grace note (state)
    $brhythm  = 0;                              # broken rhythm (state)
    $gbr      = 0;                              # (state)
    @blen     = (0) x MAXVOICE;                 # base length array
    $micro_tb = $tunes->{$tune}->{micro_tb};    # micro tones table
    $c_voice  = $IMPLICIT_VOICE;                # current voice
    $c_tune   = $tunes->{$tune};                # current tune
    $c_sym_ix = 0;                              # current symbol index
    $c_abc    = q{};                            # current abc
    %voice_struct = ();    # voice structure which stores each voice's stuff
    my $n_symbols = scalar( @{ $c_tune->{symbols} } ) - 1;

    #initialize voice stuff
    _initialize();

    # set the duration of all notes/rests/mrests - this is needed for tuplets
    _set_durations( \$tunes, $tune );

    _set_tuplet_time_and_bars( \$tunes, $tune );

    for ( 0 .. $n_symbols ) {    # tune symbols
      $c_sym_ix             = $_;
      $sym                  = $c_tune->{symbols}->[$c_sym_ix];
      $toabc_called_outside = 0;
      $toabc_called_inside  = 0;

      _update_score_variables(\$tunes, $tune, $sym);

      my $proc = _get_transformation( \%abch, $sym );
      $c_abc .= $proc->() || q{};

      _update_time_offset();

      # calls toabc in order to update global variables only if it has not already been called in
      # this iteration (either by being the default function or by being explicitily called inside one
      # of the subroutines of the handler)
      my $toabc_not_called = !$toabc_called_outside && !$toabc_called_inside;
      if ($toabc_not_called) { toabc() }
    }

    $return = $abch{'-end'} ? &{ $abch{'-end'} } : $c_abc;
  }

  return $return;
}

# -- dumps a chord's end symbol and updates the base length
sub _end_chord {
  my ( $sym, $new_abc ) = @_;

  if ( $sym->{info}->{nhd} > 0 ) {    # the current symbol is a chord
    $new_abc .= ']';                  # ends chord
    if ( $sym->{info}->{chlen} ) {    # chlen: chord length
      $blen[$c_voice] = BASE_LEN;

      # prints the chord length
      $new_abc = _length_dump( $new_abc, $sym->{info}->{chlen} );
    }
  }

  return $new_abc;
}


# -- returns the abc for the end of line
sub _eoln_to_abc {
  my($new_abc, $sym, $c, $nl_new) = @_;

  # tclabc.c => "FIXME:pb when info after line continuation"
  given ( $sym->{info}->{type} ) {
    when (1)          { $new_abc .= q{\\}; continue }         # continuation
    when ( [ 0, 1 ] ) { if ( $c ne "\n" ) { $nl_new = 1 } }   # normal
    when (2)          { $new_abc .= q{!} }                    # abc2win line break
  }

  return ( $new_abc, $nl_new );
}

# -- dump the guitar chords / annotations --
sub _gchord_dump {
  my($abc, $s) = @_;
  my $q;

  while (($q = index $s, "\n") != -1) { # appends all guitar chords except the last one
    $abc .= sprintf '"%.*s"', $q, $s;
    $s = substr $s, $q+1, length($s)-$q;
  }
  $abc .= "\"$s\""; # appends the last guitar chord

  return $abc;
}

# -- searches for a note's chord related actuators
sub _get_chord_actuator {
  my ( $abch, $sym, $proc ) = @_;
  my %abch = %{$abch};

  # it is a chord
  if ( $sym->{info}->{nhd} > 0 ) {
    $proc = $abch{'chord'} || $proc;

    if ( is_major_triad($sym) ) {
      $proc = $abch{'major_triad'} || $proc;
    }
    if ( is_minor_triad($sym) ) {
      $proc = $abch{'minor_triad'} || $proc;
    }
    if ( is_dominant_seventh($sym) ) {
      $proc = $abch{'dominant_seventh'} || $proc;
    }
  }

  return $proc;
}

# -- get the actuators that have a decoration --
sub _get_deco_actuators {
  my ( $abch, $sym, $proc ) = @_;
  my %abch = %{$abch};
  my $type = $sym->{type};
  my $bar  = $type == ABC_T_BAR;

  if ( $sym->{info}->{dc}->{n} ) {    # n is the whole number of decorations
    $proc = $abch{'deco'} || $proc;

    # note::deco is more specific than deco alone
    $proc = $abch{"$sym_name{$type}::deco"} || $proc;

    # the actual bar is more specific
    if ($bar) {
      $proc = $abch{ _bar_dump( q{}, $sym, q{} ) . '::deco' } || $proc;
    }

    my $dc = _deco_dump( $sym->{info}->{dc}, q{} );
#FIXME é possivel existir mais que uma deco por sym, logo a pesquisa no abch nao pode estar tal como está
    # the actual decoration is more specific
    $proc = $abch{$dc} || $proc;

    # note::!f! is more specific than !f! alone
    $proc = $abch{"$sym_name{$type}::$dc"} || $proc;

    # the actual bar with that actual deco is more specific
    if ($bar) {
      $proc = $abch{ _bar_dump( q{}, $sym, q{} ) . "::$dc" } || $proc;
    }
  }

  return $proc;
}

# -- searches for a note/rest/bar's gchord/accompaniment chord actuators
sub _get_gchord_actuator {
  my ( $abch, $sym, $proc ) = @_;
  my %abch = %{$abch};
  my $type = $sym->{type};
  my $element = $type == ABC_T_NOTE ? 'note'
              : $type == ABC_T_REST ? 'rest'
              :                       'bar';

  # it has at least one accompaniment chord (or guitar chord)
  if ($sym->{text}) {
    $proc = $abch{'gchord'} || $proc;

    # bar::gchord
    $proc = $abch{ $element . 'gchord' } || $proc;

    my $gchord = $sym->{text};
    # Multiple chords per element can be notated writing two or more consecutive
    # chords before the same element, or using the separating characters ; or \n
    $gchord =~ tr/;/\n/;
    my @gchords = split m/\n/xms, $gchord;

    # stops the search after the first match; the first gchords have priority
    # eg: 'gchord::F'
    foreach my $gc (@gchords) {
      $proc = $abch{ "gchord::$gc" } || $proc;
      last if $abch{ "gchord::$gc" };
    }

    # stops the search after the first match; the first gchords have priority
    # eg: 'bar::gchord::F'
    foreach my $gc (@gchords) {
      $proc = $abch{ $element . "::gchord::$gc" } || $proc;
      last if $abch{ $element . "::gchord::$gc" };
    }
  }

  return $proc;
}

sub _get_info {
  my $sym = shift;

  given ( substr $sym->{text}, 0, 1 ) {
    when ('V') { # Voice
      _get_voice($sym);
    }
    when ('K') { # Key (K)
      _get_key($sym);
    }
    when ('Q') { # Tempo (Q)
      # $voice_struct{$c_voice}{tempo} = substr _tempo_header_dump( q{}, $sym ), 2;
    }
    when ('M') { # Meter (M)
      _get_meter($sym);
    }
    when ('L') { # Length (L)
      _get_length($sym);
    }
  }

  return;
}

# -- updates the current voice's key info
sub _get_key {
  my $sym = shift;
  my $c_key;

  if ( $sym->{info}->{empty} ) {
    if ( $sym->{info}->{empty} == 2 ) { $c_key = NONE }
  } else {
    # extracts only the Key's note and mode, ignores explicit accidentals
    $c_key = _key_calc($sym);
  }

  _update_key($c_key);

  return;
}

sub _update_key {
  my $c_key = shift;
  my $v = $sym->{state} == ABC_S_HEAD ? $GLOBAL : $c_voice;

  $voice_struct{$v}{key}{text} = $c_key;
  $voice_struct{$v}{key}{sf}   = $sym->{info}->{sf};
  $voice_struct{$v}{key}{exp}  = $sym->{info}->{exp};
  $voice_struct{$v}{key}{nacc} = $sym->{info}->{nacc};
  $voice_struct{$v}{key}{pits} = $sym->{info}->{pits};
  $voice_struct{$v}{key}{accs} = $sym->{info}->{accs};

  return;
}

# -- updates the current voice's length info
sub _get_length {
  my $sym = shift;
  my $length = substr _length_header_dump( q{}, $sym ), 2;

  given ( $sym->{state} ) {
    when (ABC_S_GLOBAL) {
      #FIXME: keep the values and apply to all tunes??
    }
    when ( ABC_S_HEAD ) {
      $voice_struct{$GLOBAL}{length} = $length;
      continue;
    }
    when ( [ ABC_S_HEAD, ABC_S_TUNE ] ) {
      $voice_struct{$c_voice}{length} = $length;
    }
  }

  return;
}

# -- updates the current voice's meter info
sub _get_meter {
  my $sym = shift;
  my $meter_text = 'M:' . _meter_calc($sym);

  given ( $sym->{state} ) {
    when (ABC_S_GLOBAL) {
      #FIXME: keep the values and apply to all tunes??
    }
    when ( ABC_S_HEAD ) {
      $voice_struct{$GLOBAL}{meter}{text}     = $meter_text;
      $voice_struct{$GLOBAL}{meter}{wmeasure} = $sym->{info}->{wmeasure};
      continue;
    }
    when ( [ ABC_S_HEAD, ABC_S_TUNE ] ) {
      $voice_struct{$c_voice}{meter}{text}     = $meter_text;
      $voice_struct{$c_voice}{meter}{wmeasure} = $sym->{info}->{wmeasure};
    }
  }

  return;
}

# -- searches for note, rest and bar actuators
# -- it also gets decoration related actuators
sub _get_note_rest_bar_actuators {
  my ( $abch, $sym, $proc ) = @_;
  my %abch = %{$abch};
  my $type = $sym->{type};
  my ( $note, $bar ) = ( $type == ABC_T_NOTE, $type == ABC_T_BAR );
  my $voice_id   = $voice_struct{$c_voice}{id};
  my $voice_name = $voice_struct{$c_voice}{name};

  $proc = $abch{ $sym_name{$type} } || $proc;

  #searches for actuators of the like: V:1::note or V:Tenor::rest
  if ($voice_name) {
    $proc = $abch{ "V:$voice_name" . "::$sym_name{$type}" } || $proc;
  }
  if ($voice_id) {
    $proc = $abch{"V:$voice_id" . "::$sym_name{$type}"} || $proc;
  }

  if ($note) {
    # searches for chord related actuators
    $proc = _get_chord_actuator( $abch, $sym, $proc );

    my $pitch = _pitch_dump( $sym->{info}->{pits}->[0], $sym->{info}->{accs}->[0] );
    # removes the octave
    $pitch =~ tr/,'/ /;

    #searches for actuators of the like: note::c
    $proc = $abch{"$sym_name{$type}" . "::$pitch"} || $proc;

    #searches for actuators of the like: V:1::note::c or V:Tenor::note::^F
    if ($voice_name) {
      $proc = $abch{"V:$voice_name" . "::$sym_name{$type}" . "::$pitch"} || $proc;
    }
    if ($voice_id) {
      $proc = $abch{"V:$voice_id" . "::$sym_name{$type}" . "::$pitch"} || $proc;
    }
  }

  # the actual bar is more specific: :|
  if ($bar) { $proc = $abch{ _bar_dump( q{}, $sym, q{} ) } || $proc; }

  # searches for an actuator corresponding to a note/rest/bar with an accompaniment chord
  # gchords are more specific than the previous; equivalent to decorations although in this implementation it's less specific
  $proc = _get_gchord_actuator( $abch, $sym, $proc );

  # searches for an actuator corresponding to a note/rest/bar with a decoration
  # decorations are more specific than the previous; equivalent to gchords although in this implementation it's more specific
  $proc = _get_deco_actuators( $abch, $sym, $proc );

  return $proc;
}

# -- searches for null, info and clef actuators
# -- these three symbol's types have been separated from the others
#   -- because they are the only types that can be conjugated with
#   -- the state actuator
sub _get_null_info_clef_actuators {
  my ( $abch, $sym, $proc ) = @_;
  my %abch      = %{$abch};
  my $type      = $sym->{type};
  my $state     = $sym->{state};
  my $info_type = substr $sym->{text}, 0, 1;
  my $info      = $type == ABC_T_INFO;

  $proc = $abch{ $sym_name{$type} } || $proc;
  $proc = $abch{ $state_name{$state} . "::$sym_name{$type}" } || $proc;

  if ($info) {
    $proc = $abch{"$info_type:"} || $proc;
    $proc = $abch{ $state_name{$state} . "::$info_type:" } || $proc;

    if ( $info_type eq 'V' ) {
      my $voice_id   = $sym->{info}->{id};
      my $voice_name = $sym->{info}->{fname} || $voice_struct{$c_voice}{name};

      if ($voice_name) { $proc = $abch{"$info_type:$voice_name"} || $proc; }
      $proc = $abch{"$info_type:$voice_id"} || $proc;
      if ($voice_name) {
        $proc = $abch{ $state_name{$state} . "::$info_type:$voice_name" } || $proc;
      }
      $proc = $abch{ $state_name{$state} . "::$info_type:$voice_id" } || $proc;
    } elsif ( $info_type eq 'M' ) {
      $proc = $abch{ "$info_type:" . _meter_calc($sym) } || $proc;
      $proc = $abch{ $state_name{$state} . "::$info_type:" . _meter_calc($sym) } || $proc;
    }
  }

  return $proc;
}

# -- gets pscom actuators (abcMIDI's, PageFormat's, other)
sub _get_pscom_actuators {
  my ( $abch, $sym, $proc ) = @_;
  my %abch = %{$abch};
  my $type = $sym->{type};

  my $text = $sym->{text};
  if ( $text ne q{} ) { $text = substr $text, 2 }    # removes '%%' from text

  # pscom
  $proc = $abch{ $sym_name{$type} } || $proc;

  # MIDI is more specific than pscom
  if ( $text =~ /^MIDI.*/xms ) {
    $proc = $abch{'MIDI'} || $proc;                  # || $abch{'midi'}

    # MIDI::abcMIDI_command is more specific than MIDI
    if ( $text =~ /^MIDI\s+(\w+).*/xms ) {
      $proc = $abch{"MIDI::$1"} || $proc;
    }

    #TODO add PageFormats (see last pages from abcplus)
  } else {
    $proc = $abch{'FORMAT'} || $proc;

    if ( $text =~ /^(staves|score)/xms ) {
      $proc = $abch{$1} || $proc;
    }
  }

  return $proc;
}

# -- gets the transformation to be applied according to an abc symbol/element
# -- searches for an actuator that matches the abc symbol passed in as argument
# -- the most specific actuator is the one chosen
sub _get_transformation {
  my ( $abch, $sym ) = @_;
  my %abch  = %{$abch};
  my $type  = $sym->{type};
  my $state = $sym->{state};
  my $proc  = q{};

  # the second most general actuator is the state, ex: in_header
  $proc = $abch{ $state_name{$state} } || $proc;

  # searches for actuators
  if ( $type == ABC_T_PSCOM ) {
    # searches for pscom actuators
    $proc = _get_pscom_actuators( $abch, $sym, $proc );
  } elsif (    $type == ABC_T_NOTE
            || $type == ABC_T_REST
            || $type == ABC_T_BAR )
  {
    # searches for note, rest or bar actuators
    $proc = _get_note_rest_bar_actuators( $abch, $sym, $proc );
  } elsif (    $type == ABC_T_NULL
            || $type == ABC_T_INFO
            || $type == ABC_T_CLEF )
  {
    # searches for nul, info or clef actuators
    $proc = _get_null_info_clef_actuators( $abch, $sym, $proc );
  } else {
    # searches for the remaining actuators ( eoln, mrest, mrep, v_over, tuplet )
    $proc = $abch{ $sym_name{$type} } || $proc;
  }

  # if no actuator was found, it tries to apply the -default function
  # and if it doesn't exist either, it applies the identity function - toabc()
  $proc ||= $abch{'-default'} || \&toabc;

  return $proc;
}

#  -- Updates the current voice and some info related to it --
sub _get_voice {
  my $sym = shift;

  if ( $sym->{state} == ABC_S_TUNE || $sym->{state} == ABC_S_EMBED ) {
    $c_voice = $sym->{info}->{voice};

    #set voice stuff if not already set
    #TODO check abcm2ps-7.3.4/parse.c:2817 (do_tune)
    $voice_struct{$c_voice}{id}              ||= $sym->{info}->{id};
    $voice_struct{$c_voice}{name}            ||= $sym->{info}->{fname} || q{};
    $voice_struct{$c_voice}{time}            ||= 0;
    $voice_struct{$c_voice}{meter}{text}     ||= $voice_struct{$GLOBAL}{meter}{text}     || 'M:' . DEFAULT_METER;
    $voice_struct{$c_voice}{meter}{wmeasure} ||= $voice_struct{$GLOBAL}{meter}{wmeasure} || BASE_LEN;
    $voice_struct{$c_voice}{length}          ||= $voice_struct{$GLOBAL}{length}          || 'L:' . DEFAULT_LENGTH;
    $voice_struct{$c_voice}{key}{text}       ||= $voice_struct{$GLOBAL}{key}{text};
    $voice_struct{$c_voice}{key}{sf}         ||= $voice_struct{$GLOBAL}{key}{sf};
    $voice_struct{$c_voice}{key}{exp}        ||= $voice_struct{$GLOBAL}{key}{exp};
    $voice_struct{$c_voice}{key}{nacc}       ||= $voice_struct{$GLOBAL}{key}{nacc};
    $voice_struct{$c_voice}{key}{pits}       ||= $voice_struct{$GLOBAL}{key}{pits};
    $voice_struct{$c_voice}{key}{accs}       ||= $voice_struct{$GLOBAL}{key}{accs};
  }

  return;
}


# -- dump a header --
sub _header_dump {
  my ( $abc, $sym ) = @_;

  given (substr $sym->{text}, 0, 1) { # info type (first character)
    when ('K'      )  { $abc = _key_header_dump($abc, $sym) }            # Key
    when ('L'      )  { $abc = _length_header_dump($abc, $sym) }         # Length
    when ('M'      )  { $abc = _meter_header_dump($abc, $sym) }          # Meter
    when ('Q'      )  { $abc = _tempo_header_dump($abc, $sym) }          # Tempo
    when ('V'      )  { $abc = _voice_header_dump($abc, $sym) }          # Voice
    when (['d','s'])  { $abc .= q{%}; continue }                         # 's': decoration line # tclabc.c => "FIXME: already in notes"
    default           { $abc .= $sym->{text}; }
  }

  return $abc;
}

# -- return a 'up' / 'down' / auto' parameter value --
sub _head_par {
  my $v = shift;
  return 'down' if ($v < 0);
  return 'auto' if ($v == 2);
  return 'up';
}

# -- returns the abc for the info field and the new line flag
sub _info_to_abc {
  my ($new_abc, $sym, $c, $nl_new) = @_;

  if ($sym->{state} == ABC_S_EMBED) { $new_abc .= '[' }
  elsif ($c ne "\n")                { $new_abc .= "\\\n";
    # _lyrics_dump($new_abc, $sym);
  }
  $new_abc = _header_dump($new_abc, $sym);
  if ($sym->{state} == ABC_S_EMBED) { $new_abc .= ']' }
  else                              { $nl_new = 1; }

  return ($new_abc, $nl_new);
}

# Initializes voice variables
sub _initialize {

  $voice_struct{$c_voice}{id}              = q{};
  $voice_struct{$c_voice}{name}            = q{};
  $voice_struct{$c_voice}{meter}{text}     = 'M:' . DEFAULT_METER;
  $voice_struct{$c_voice}{meter}{wmeasure} = BASE_LEN;
  $voice_struct{$c_voice}{length}          = 'L:' . DEFAULT_LENGTH;
  $voice_struct{$c_voice}{time}            = 0;
  $voice_struct{$c_voice}{key}{text}       = q{};

  return;
}

# -- calculates key note and mode
sub _key_calc {
  my $sym = shift;
  my $abc = q{};

  # calculates Key
  if ( $sym->{info}->{mode} < BAGPIPE ) {
    #       ion dor phr lyd mix aeo loc
    #   7   C#  D#  E#  F#  G#  A#  B#
    #   6   F#  G#  A#  B   C#  D#  E#
    #   5   B   C#  D#  E   F#  G#  A#
    #   4   E   F#  G#  A   B   C#  D#
    #   3   A   B   C#  D   E   F#  G#
    #   2   D   E   F#  G   A   B   C#
    #   1   G   A   B   C   D   E   F#
    #   0   C   D   E   F   G   A   B
    #   -1  F   G   A   Bb  C   D   E
    #   -2  Bb  C   D   Eb  F   G   A
    #   -3  Eb  F   G   Ab  Bb  C   D
    #   -4  Ab  Bb  C   Db  Eb  F   G
    #   -5  Db  Eb  F   Gb  Ab  Bb  C
    #   -6  Gb  Ab  Bb  Cb  Db  Eb  F
    #   -7  Cb  Db  Eb  Fb  Gb  Ab  Bb

    my $i = $sym->{info}->{sf} + $key_shift[ $sym->{info}->{mode} ];
    $abc .= $key_tonic[ ( $i + 7 ) % 7 ];
    if    ( $i < 0 )  { $abc .= 'b' }
    elsif ( $i >= 7 ) { $abc .= q{#} }
  }

  # if it is a mode other than major it appends the first 3 characters of its name (mixolydian => mix)
  if ( $sym->{info}->{mode} != MAJOR ) {
    $abc .= substr( (KEY_NAMES)[ $sym->{info}->{mode} ], 0, 3 );
  }

  return $abc;
}

# -- dump the header key
sub _key_header_dump {
  my($abc, $sym) = @_;

  $abc .= 'K:';
  if ( $sym->{info}->{empty} ) {
    if ( $sym->{info}->{empty} == 2 ) { $abc .= NONE }
  }
  else {
    # calculates key note and mode
    $abc .= _key_calc($sym);

    # prints explicit accidentals
    if ( $sym->{info}->{nacc} != 0 ) {    # number  of explicit accidentals
      if   ( $sym->{info}->{exp} ) { $abc .= ' exp '; }   # Explicit accidentals
      else                         { $abc .= q{ }; }
      if ( $sym->{info}->{nacc} < 0 ) { $abc = NONE; }    # No accidental
      else {
        for ( 0 .. $sym->{info}->{nacc} - 1 ) {
          $abc = _note_dump(
                             $abc,
                             $sym->{info}->{pits}->[$_],
                             $sym->{info}->{accs}->[$_],
                             (
                                 $blen[$c_voice] != 0
                               ? $blen[$c_voice]
                               : BASE_LEN / 8
                             ),
                             0
                           );
        }
      }
    }
  }

  # tclabc.c => "FIXME: only if forced?"
  # prints the key's clef if it exists
  if ( ref( $c_tune->{symbols}->[ $c_sym_ix + 1 ] )
       && $c_tune->{symbols}->[ $c_sym_ix + 1 ]->{type} == ABC_T_CLEF )
  {
    $abc = _clef_dump( $abc, $c_tune->{symbols}->[ $c_sym_ix + 1 ] );
  }

  return $abc;
}

# -- dump the note/rest length --
sub _length_dump {
  my($abc, $len) = @_;
  my $div = 0;

  if ( $blen[$c_voice] == 0 ) { $blen[$c_voice] = BASE_LEN / 8 }

  while(1) {
    if (($len % $blen[$c_voice]) == 0) {
      $len /= $blen[$c_voice];
      if ($len != 1) { $abc .= $len }
      last;
    }
    $len *= 2;
    $div++;
  }

  while ( --$div >= 0 ) { $abc .= q{/} }

  return $abc;
}

# -- dump header length dump
sub _length_header_dump {
  my ( $abc, $sym ) = @_;

  # assigns base length
  if ( $sym->{state} == ABC_S_GLOBAL || $sym->{state} == ABC_S_HEAD ) {

    # assigns base length to all voices
    foreach ( reverse 0 .. MAXVOICE- 1 ) {
      $blen[$_] = $sym->{info}->{base_length};
    }
  } else {

    # assigns base length to current voice
    $blen[$c_voice] = $sym->{info}->{base_length};
  }
  $abc .= sprintf 'L:1/%d', BASE_LEN / $blen[$c_voice];    # prints length

  return $abc;
}

# -- dump the lyrics --
# sub _lyrics_dump {
#   my($abc,$as2) = @_;
#   my($as,$as1);
#   my $s;
#   my($i,$maxly);
#
#   # count the number of lyric lines
#   # return if (not defined($as1 = $ly_st));
#   return;
# #TODO verificar se isto é mesmo necessario. se sim terminar. é preciso ver a struct sym e lyrics que
# #estao no tclabc.h (linhas 17 e 12)
# }

# -- calculates meter info
sub _meter_calc {
  my $sym = shift;
  my $abc = q{};

  # iterates through each meter element
  # nmeter: number of meter elements
  if ($sym->{info}->{nmeter} == 0) { $abc .= NONE; }
  else { # prints meter elements
    foreach my $i (0..$sym->{info}->{nmeter}-1) {
      if (    $i > 0                                            # if there's more than one element
           && $sym->{info}->{meter}->[$i]->{top} =~ /^\d.*/xms  # if top starts with a number
           && substr( $abc, length($abc) - 1, 1 ) =~ /\d/xms )  # if last character is a number
      {
        $abc .= q{ };    # adds a space
      }
      $abc .= sprintf '%.8s', $sym->{info}->{meter}->[$i]->{top};    # truncates top to 8 characters

      if ( $sym->{info}->{meter}->[$i]->{bot} ne q{} ) {
        # truncates bottom to 2 characters
        $abc .= sprintf '/%.2s', $sym->{info}->{meter}->[$i]->{bot};
      }
    }
  }

  return $abc;
}

# -- dump meter
sub _meter_header_dump {
  my($abc, $sym) = @_;

#FIXME TCLABC o expdur nao é tratado aqui logo coisas como: M:C|=2/1 nao aparecem
  $abc .= 'M:';

  # prints Meter info
  $abc .= _meter_calc($sym);

  # assigns base length
  if ($blen[$c_voice] == 0) { # base length is not defined
    my $ulen;
    if (    $sym->{info}->{wmeasure} >= BASE_LEN * 3 / 4
         || $sym->{info}->{wmeasure} == 0 )
    {
      $ulen = BASE_LEN / 8;
    } else {
      $ulen = BASE_LEN / 16;
    }

    # assigns base length
    if ( $sym->{state} == ABC_S_GLOBAL || $sym->{state} == ABC_S_HEAD ) {

      # assigns base length to all voices
      foreach ( reverse 0 .. MAXVOICE- 1 ) { $blen[$_] = $ulen }
    } else {
      $blen[$c_voice] = $ulen;    # assigns base length to current voice
    }
  }

  return $abc;
}

# -- dump a note --
sub _note_dump {
  my ( $abc, $pitch, $acc, $len, $nostem ) = @_;

  # Note Pitch and Accidentals
  $abc = _pitch_dump( $pitch, $acc, $abc );

  # Note Length
  if ($nostem) { $abc .= '0' }    #stem

  return _length_dump( $abc, $len );
}

# -- returns the abc for rest and note and elements related to them (chord [], slurs (), ties -)
sub _note_to_abc {
  my($new_abc, $sym) = @_;

  # if there are slurs starting here; != 0
  if ( $sym->{info}->{slur_st} ) {
    $new_abc = _slur_dump( $new_abc, $sym->{info}->{slur_st} );
  }
  if ( $sym->{text} ne q{} ) {
    $new_abc = _gchord_dump( $new_abc, $sym->{text} );    # guitar chord
  }
  if ( $sym->{info}->{dc}->{n} ) {
    $new_abc = _deco_dump( $sym->{info}->{dc}, $new_abc );
  }

  # NOTE replaced bitwise operator (|)
  $brhythm ||= $sym->{info}->{brhythm};

  if ($sym->{type} == ABC_T_NOTE) { # the current symbol is a note
    my ( $all_tie, $blen_sav ) = ( 0, $blen[$c_voice] );

    # updates base length if the current symbol is grace note
    if ( $sym->{flags} & ABC_F_GRACE ) { $blen[$c_voice] = BASE_LEN / 4 }

    # start chord
    ( $new_abc, $all_tie ) = _start_chord( $sym, $new_abc, $all_tie );

    # prints chord's notes, slurs, ties, etc
    $new_abc = _chord_to_abc( $sym, $new_abc, $all_tie );

    # end chord
    $new_abc = _end_chord( $sym, $new_abc );

    # prints tie for chord
    $new_abc = _chord_tie( $new_abc, $all_tie );

    # restores the current voice's base length
    $blen[$c_voice] = $blen_sav;
  } else {

    # rests and additional spacings
    $new_abc = _rest_to_abc( $sym, $new_abc );
  }

  #end slurs
  foreach ( 0 .. $sym->{info}->{slur_end} - 1 ) { $new_abc .= ')' }

  # dumps broken rhythm symbol
  $new_abc = _broken_rhythm_dump($new_abc);

  return $new_abc;
}

# -- dumps a note's accidentals, microtones and pitch  --
sub _pitch_dump {
  my ( $pits, $acc, $abc ) = @_;

  # Note Accidentals
  given ( $acc & 0x07 ) {
    when (A_DS)             { $abc .= q{^}; continue; }
    when ( [ A_SH, A_DS ] ) { $abc .= q{^}; }
    when (A_DF)             { $abc .= '_'; continue; }
    when ( [ A_FT, A_DF ] ) { $abc .= '_'; }
    when (A_NT)             { $abc .= q{=}; }
  }

  # Note Microtones
  $acc >>= 3;
  if ($acc) {
    my ($n,$d);

    $n = $micro_tb->[$acc] >> 8;
    $d = $micro_tb->[$acc] & 0xff;
    if ( $n != 0 ) { $abc .= ( $n + 1 ) }
    if ($d != 0) {
      $abc .= q{/};
      if ( $d != 1 ) { $abc .= ( $d + 1 ) }
    }
  }

  # Note Step and Octave
  $abc .= _step_dump($pits);

  return $abc;
}

# -- Returns the note's step (A, B, c ...) and the octave
sub _step_dump {
  my $pits = shift;
  my $abc;
  my $j;

  if ( $pits >= 23 ) {                      # notes below c included
    $abc .= chr( ord('a') + ( $pits - 23 + 2 ) % 7 );
    $j = ( $pits - 23 ) / 7;
    while ( --$j >= 0 ) { $abc .= q{'} }    # octaves
  } else {                                  # notes above c excluded
    $abc .= chr( ord('A') + ( $pits + 49 ) % 7 );
    $j = ( 22 - $pits ) / 7;
    while ( --$j >= 0 ) { $abc .= q{,} }    # octaves
  }

  return $abc;
}

# -- returns the abc for the grace note symbol if it is one
sub _pre_note_to_abc {
  my($new_abc, $sym) = @_;

  if ( !( $sym->{flags} & ABC_F_GRACE ) ) {    # not a grace note
    if ( not defined $ly_st ) { $ly_st = $sym }    # set $ly_st if not defined
  } else {                                          # grace note
    if ( !$in_grace ) {
#NOTE when there's something like ({AB} c), because this function is called
#before _note_to_abc - where slurs are dumped - it changes the order of the first 2 characters
      $in_grace = 1;
      $gbr      = $brhythm;
      $brhythm  = 0;
      $new_abc .= '{';
      if ( $sym->{flags} & ABC_F_SAPPO ) { $new_abc .= q{/} } #short appoggiatura
    }
  }

  return $new_abc;
}

# -- returns the abc for the info field and the new line flag
sub _pscom_to_abc {
  my ( $new_abc, $sym, $c ) = @_;

  my $nl_new = 1;
  if ( $sym->{text} ne q{} ) {
    if ( $c ne "\n" ) { $new_abc .= "\\\n" }

    # _lyrics_dump($new_abc, $sym) if ($new_abc ne "");
    $new_abc .= $sym->{text};
  }

  return ( $new_abc, $nl_new );
}

# -- dumps rests and additional spacings to abc
sub _rest_to_abc {
  my ( $sym, $new_abc ) = @_;

  if ( $sym->{info}->{lens}->[0] ) {

    # rests
    $new_abc .= $sym->{flags} & ABC_F_INVIS ? 'x' : 'z';
    $new_abc =
      _length_dump( $new_abc, _broken_rhythm( $sym->{info}->{lens}->[0] ) );
  } else {

    # additional spacing
    $new_abc .= 'y';
    if ( $sym->{info}->{lens}->[1] >= 0 ) {
      $new_abc .= $sym->{info}->{lens}->[1];
    }
  }

  return $new_abc;
}

# -- set the duration of all notes/rests/mrests
sub _set_durations {
  my ( $tunes_ref, $tune ) = @_;
  my $n_symbols = scalar( @{ ${$tunes_ref}->{$tune}->{symbols} } ) - 1;
  my %v_i = ();                 # current voice's info
  my $c   = $IMPLICIT_VOICE;    # current voice

#FIXME ver se consigo deixar de usar o ${$s} e passar a usar so $s
  # sets the duration of all notes/rests without regard for tuplets - this is needed for tuplets
  for my $ix ( 0 .. $n_symbols ) {
    my $s = \${$tunes_ref}->{$tune}->{symbols}->[$ix];
    given ( ${$s}->{type} ) {
      when (ABC_T_INFO) {
        given ( substr ${$s}->{text}, 0, 1 ) {
          when ('V') {    # Voice
            if ( ${$s}->{state} ~~ [ABC_S_TUNE, ABC_S_EMBED] ) {
              $c = ${$s}->{info}->{voice};
              $v_i{$c}{meter}{wmeasure} ||= BASE_LEN;
            }
          }
          when ('M') {    # Meter
            if ( ${$s}->{state} ~~ [ ABC_S_HEAD, ABC_S_TUNE ] ) {
              $v_i{$c}{meter}{wmeasure} = ${$s}->{info}->{wmeasure};
            }
          }
        }
      }
      when ( [ ABC_T_NOTE, ABC_T_REST ] ) {
        ${$s}->{info}->{dur} = ${$s}->{info}->{lens}->[0]
      }
      when (ABC_T_MREST) {
        my $dur = $v_i{$c}{meter}{wmeasure} * ${$s}->{info}->{len};
        ${$s}->{info}->{dur} = $dur;
      }
    }
  }

  return;
}

# sets the real duration for notes and rests inside a tuplet
# updates the time offset
# sets bar numbers on notes, rests, mrests and bars
sub _set_tuplet_time_and_bars {
  my ( $tunes_ref, $tune ) = @_;
  my $n_symbols = scalar( @{ ${$tunes_ref}->{$tune}->{symbols} } ) - 1;
  my $c   = $IMPLICIT_VOICE;    # current voice
  my %v_i = ();                 # current voice's info
  $v_i{$c}{meter}{wmeasure} ||= BASE_LEN;
  $v_i{$c}{bar}{num}        ||= int $FIRST_MEASURE;
  $v_i{$c}{bar}{time}       ||= 0;
  $v_i{$c}{time}            ||= 0;

  for my $ix ( 0 .. $n_symbols ) {
    my $s = ${$tunes_ref}->{$tune}->{symbols}->[$ix];

    given ( $s->{type} ) {
      when (ABC_T_INFO) {
        given ( substr $s->{text}, 0, 1 ) {
          when ('V') {    # Voice
            if ( $s->{state} ~~ [ABC_S_TUNE, ABC_S_EMBED] ) {
              $c = $s->{info}->{voice};
              $v_i{$c}{meter}{wmeasure} ||= BASE_LEN;
              $v_i{$c}{bar}{num}        ||= int $FIRST_MEASURE;
              $v_i{$c}{bar}{time}       ||= 0;
              $v_i{$c}{time}            ||= 0;
            }
          }
          when ('M') {    # Meter
            if ( $s->{state} ~~ [ ABC_S_HEAD, ABC_S_TUNE ] ) {
              $v_i{$c}{meter}{wmeasure} = $s->{info}->{wmeasure};
            }
          }
        }
      }
      when (ABC_T_TUPLET) {
        _set_tuplet( $tunes_ref, $tune, $ix, $s );
      }
    }

    # sets the time offset on notes/rest/mrests/bars
    _set_time_offset(\$s, \$v_i{$c}{bar}{time});

    given ( $s->{type} ) {
      when (ABC_T_BAR) {
        # for incomplete measures
        $v_i{$c}{bar}{time} ||= $v_i{$c}{meter}{wmeasure};

        # increments bar number only if it isn't an incomplete measure
        if ( $s->{info}->{type} != B_OBRA and $s->{info}->{time} >= $v_i{$c}{bar}{time} ) { $v_i{$c}{bar}{num}++ }
        $s->{info}->{bar_num} = $v_i{$c}{bar}{num};

        # updates the new measure's bar time
        $v_i{$c}{bar}{time} = $s->{info}->{time} + $v_i{$c}{meter}{wmeasure};
      }
      when ( [ ABC_T_NOTE, ABC_T_REST ] ) {
        $s->{info}->{bar_num} = $v_i{$c}{bar}{num};
      }
      when (ABC_T_MREST) {
        $s->{info}->{bar_num} = $v_i{$c}{bar}{num};
        $v_i{$c}{bar}{num} += ($s->{info}->{len} - 1);
      }
    }
  }

  return;
}

# -- set the duration of notes/rests in a tuplet
# FIXME: KO if voice change
# FIXME: KO if in a grace sequence
# TODO : finish nested tuples (there's a detail in the C version that i don't understand)
sub _set_tuplet {
  my ( $tunes_ref, $tune, $sym_ix, $sym ) = @_;

  my $as;
  my $s;
  my $lplet;
  my $r            = $sym->{info}->{r_plet};
  my $grace        = $sym->{flags} & ABC_F_GRACE;
  my $c_tune_local = ${$tunes_ref}->{$tune};

  my $l = 0;
  my $ix = $sym_ix + 1;
  for ( $as = $c_tune_local->{symbols}->[$ix] ;
        ref $as ;
        $as = $c_tune_local->{symbols}->[ ++$ix ] )
  {
    # nested tuplet
    # if ( $as->{info}->{type} == ABC_T_TUPLET ) {
    #   my $as2;
    #   my $r2 = $as->{info}->{r_plet};
    #   my $l2 = 0;
    #   my $ix2 = $ix;

    #   for ( $as2 = $c_tune_local->{symbols}->[$ix2] ;
    #         ref $as2 ;
    #         $as2 = $c_tune_local->{symbols}->[ ++$ix2 ] )
    #   {
    #     # checks for EOL in a tuplet
    #     # switch (as2->type) {
    #     #   case ABC_T_NOTE:
    #     #   case ABC_T_REST:
    #     #     last;
    #     #   case ABC_T_EOLN:
    #     #     if (as2->u.eoln.type != 1) {
    #     #       error(1, t, "End of line found inside a nested tuplet");
    #     #       return;
    #     #     }
    #     #     continue;
    #     #   default:
    #     #     continue;
    #     # }
    #     next if ($as2->{info}->{lens}->[0] == 0); # space ('y')
    #     next if ($grace ^ ($as2->{flags} & ABC_F_GRACE));
    #     $s = $as2;
    #     $l2 += $s->{info}->{dur};
    #     last if (--$r2 <= 0);
    #   }
    #   $l2 = $l2 * $as->{info}->{q_plet} / $as->{info}->{p_plet};
    #   #FIXME nao percebi o que faz a linha seguinte
      #((struct SYMBOL *) as)->u = l2;
    #   $as->{info} = $l2;
    #   $l += $l2;
    #   #FIXME nao percebi a linha seguinte. O $as->u nao é um inteiro neste momento?
      #r -= as->u.tuplet.r_plet;
    #   $r -= $as->{info}->{r_plet};
    #   last if ($r == 0);
    #   # if ($r < 0) {
    #   #   error(1, t, "Bad nested tuplet");
    #   #   last;
    #   # }
    #   $as = $as2;
    #   next;
    # }
    # checks for eol inside of tuplet
    # switch (as->type) {
    #   case ABC_T_NOTE:
    #   case ABC_T_REST:
    #     last;
    #   case ABC_T_EOLN:
    #     if (as->u.eoln.type != 1) {
    #       error(1, t, "End of line found inside a tuplet");
    #       return;
    #     }
    #     continue;
    #   default:
    #     continue;
    # }
    next if ($as->{info}->{lens}->[0] == 0); # space ('y')
    next if ($grace ^ ($as->{flags} & ABC_F_GRACE));
    $s = $as;
    $l += $s->{info}->{dur};
    last if (--$r <= 0);
  }
  # if ( not ref $as ) {
  #   error(1, t, "End of tune found inside a tuplet");
  #   return;
  # }
  # if (t->u != 0)    # if nested tuplet */
  #   lplet = t->u;
  # else
    $lplet = ($l * $sym->{info}->{q_plet}) / $sym->{info}->{p_plet};

  $r = $sym->{info}->{r_plet};
  $ix = $sym_ix + 1;
  for ( $as = $c_tune_local->{symbols}->[$ix] ;
        ref $as ;
        $as = $c_tune_local->{symbols}->[ ++$ix ] )
  {
    my $olddur;

    # nested tuplet
    # if ($as->{type} == ABC_T_TUPLET) {
    #   int r2;

    #   r2 = as->u.tuplet.r_plet;
    #   s = (struct SYMBOL *) as;
    #   olddur = s->u;
    #   s->u = (olddur * lplet) / l;
    #   l -= olddur;
    #   lplet -= s->u;
    #   r -= r2;
    #   for (;;) {
    #     as = as->next;
    #     if (as->type != ABC_T_NOTE && as->type != ABC_T_REST)
    #       continue;
    #     if (as->u.note.lens[0] == 0)
    #       continue;
    #     if (grace ^ (as->flags & ABC_F_GRACE))
    #       continue;
    #     if (--r2 <= 0)
    #       last;
    #   }
    #   if (r <= 0)
    #     goto done;
    #   continue;
    # }
    next if ( $as->{type} != ABC_T_NOTE && $as->{type} != ABC_T_REST );
    next if ( $as->{info}->{lens}->[0] == 0 );             # space ('y')
    next if ( $grace ^ ( $as->{flags} & ABC_F_GRACE ) );

    $s                = $as;
    $olddur           = $s->{info}->{dur};
    $s->{info}->{dur} = ( $olddur * $lplet ) / $l;

    #updates the real symbol
    ${ $tunes_ref }->{$tune}->{symbols}->[$ix]->{info}->{dur} = $s->{info}->{dur};

    last if ( --$r <= 0 );

    $l -= $olddur;
    $lplet -= $s->{info}->{dur};
  }
# done:
  if ($grace) {
    # error(1, t, "Tuplets in grace note sequence not yet treated");
  }

  return;
}


# -- dump the slurs --
sub _slur_dump {
  my ( $abc, $sl ) = @_;
# FIXME when the slur is '(.(' it prints wrong, in other words, $sl is 31 so ($sl & SL_DOTTED = 4)
# and it prints the '.' before the first '(';
# moreover when the slur is '.((' then $sl = 59 and it prints '(.('
  do {
    if ( $sl & SL_DOTTED ) { $abc .= q{.} }
    $abc .= '(';
    given ( $sl & 0x03 ) {
      when (SL_ABOVE) { $abc .= q{'} }
      when (SL_BELOW) { $abc .= q{,} }
    }
    $sl >>= 3;    # in case there's more than are consecutive slurs
  } while ($sl);

  return $abc;
}

# -- dump chord start's symbol
sub _start_chord {
  my ( $sym, $new_abc, $all_tie ) = @_;

  if ( $sym->{info}->{nhd} > 0 ) {    # the current symbol is a chord
    my $i;
    # for each note in the chord
    for ( $i = $sym->{info}->{nhd} ; $i >= 0 ; $i-- ) {
    # for my $i ( reverse 0 .. $sym->{info}->{nhd} ) {

      # exits loop if there are no ties starting at the note
      last if ( !$sym->{info}->{ti1}->[$i] );
    }

    # ties all notes from the chord if there are no ties starting in an individual note
    if ( $i < 0 ) { $all_tie = $sym->{info}->{ti1}->[0] }
    $new_abc .= '[';
  }

  return ( $new_abc, $all_tie );
}

# -- dump tempo
sub _tempo_header_dump {
  my ( $abc, $sym ) = @_;

  # FIXME PARSER when Q: is defined in the header, length and value of the generated structure are
  # not being set. they are only when Q: is defined in the body like [Q: "Allegro" 1/4=120]
  # FIXME ver o que acontece quando se deixa um espaco entre Q: e o resto
  $abc .= 'Q:';

  #prints string before
  if ( $sym->{info}->{str1} ne q{} ) {
    $abc .= sprintf '"%s" ', $sym->{info}->{str1};
  }

  #prints tempo value
  if ( $sym->{info}->{value} ne q{} ) {
    my ( $top, $bot );

    foreach my $i ( 0 .. ( scalar @{ $sym->{info}->{length} } ) - 1 ) {
      next if ( ( $top = $sym->{info}->{length}->[$i] ) == 0 );
      $bot = 1;
      while (1) {
        if ( $top % BASE_LEN == 0 ) {
          $top /= BASE_LEN;
          last;
        }
        $top *= 2;
        $bot *= 2;
      }
      $abc .= sprintf '%d/%d ', $top, $bot;    # prints top/bot
    }

    # removes last character if it is a white space
    if ( substr( $abc, length($abc) - 1, 1 ) eq q{ } ) {
      $abc = substr $abc, 0, -1;
    }
    $abc .= sprintf '=%s ', $sym->{info}->{value};
  }

  # prints string after
  if ( $sym->{info}->{str2} ne q{} ) {
    $abc .= sprintf '"%s"', $sym->{info}->{str2};
  } elsif ( substr( $abc, length($abc) - 1, 1 ) eq q{ } ) {

    # erases white space at the end
    $abc = substr $abc, 0, -1;
  }

  return $abc;
}

# -- return abc of tuplet
sub _tuplet_to_abc {
  my ( $new_abc, $sym ) = @_;

  my ( $pp, $qp, $rp ) =
    ( $sym->{info}->{p_plet}, $sym->{info}->{q_plet}, $sym->{info}->{r_plet} );

  $new_abc .= sprintf '(%d', $pp;

  if (    ( $pp != 2 || $qp != 3 || $rp != 2 )    # (2ab  <=> (2:3:2ab
       && ( $pp != 3 || $qp != 2 || $rp != 3 ) )  # (3abc <=> (3:2:3abc
  {
    $new_abc .= sprintf ':%d:%d', $qp, $rp;
  }

  return $new_abc;
}

# -- update global variables of the score (voice, key, tempo, length and meter)
sub _update_score_variables {
  my ( $tunes_ref, $tune, $sym ) = @_;

  given ( $sym->{type} ) {
    when (ABC_T_INFO) {
      _get_info($sym);
    }
    when (ABC_T_MREP) {
      #Moine: mrep was an experimental extension done by "|/|" or "|//|". It does not appear in any
      #ABC standard and should be removed.
    }
    when (ABC_T_V_OVER) {
      #abcm2ps-7.3.4/parse.c:3011
      #TODO fazer vover
    }
    default {}
  }

  return;
}

# Sets the time offset into the symbol
sub _set_time_offset {
  my ( $s, $time ) = @_;

  given ( ${$s}->{type} ) {
    when ( [ ABC_T_NOTE, ABC_T_REST ] ) {
      if ( !( ${$s}->{flags} & ABC_F_GRACE ) ) {
        ${$s}->{info}->{time} = $$time;
        $$time += ${$s}->{info}->{dur};
      }
      # FIXME atencao ao v_over, nao pode contar da mesma maneira
    }
    when (ABC_T_MREST) {
      #abcm2ps-7.3.4/parse.c:2953
      ${$s}->{info}->{time} = $$time;
      $$time += ${$s}->{info}->{dur};
    }
    when (ABC_T_BAR) {
      ${$s}->{info}->{time} = $$time;
    }
  }

  return;
}

# Updates the time offset for voice $c_voice
sub _update_time_offset {
  if ( $sym->{type} ~~ [ ABC_T_NOTE, ABC_T_REST ] ) {
    if ( !( $sym->{flags} & ABC_F_GRACE ) ) {
      $voice_struct{$c_voice}{time} += $sym->{info}->{dur};
    }
    # FIXME atencao ao v_over, nao pode contar da mesma maneira
  }
  if ( $sym->{type} == ABC_T_MREST ) {
    #abcm2ps-7.3.4/parse.c:2953
    $voice_struct{$c_voice}{time} += $sym->{info}->{dur};
  }

  return;
}

# -- dump voice
sub _voice_header_dump {
  my ( $abc, $sym ) = @_;

# FIXME PARSER quando no abc a voz de uma melodia está no formato "V: id\nABCD|z4" (note-se o espaço
# entre "V:" e id), a voz nao é identificada logo o id e a voice nao sao definidos
  $abc .= sprintf 'V:%s', $sym->{info}->{id};
  if ( $sym->{info}->{fname} ne q{} ) {
    $abc .= sprintf ' name="%s"', $sym->{info}->{fname};
  }
  if ( $sym->{info}->{nname} ne q{} ) {
    $abc .= sprintf ' sname="%s"', $sym->{info}->{nname};
  }
  if ( $sym->{info}->{merge} ) { $abc .= ' merge' }
  if ( $sym->{info}->{stem} ) {
    $abc .= sprintf ' stem=%s', _head_par( $sym->{info}->{stem} );
  }
  if ( $sym->{info}->{gstem} ) {
    $abc .= sprintf ' gstem=%s', _head_par( $sym->{info}->{gstem} );
  }
  if ( $sym->{info}->{dyn} ) {
    $abc .= sprintf ' dyn=%s', _head_par( $sym->{info}->{dyn} );
  }
  if ( $sym->{info}->{lyrics} ) {
    $abc .= sprintf ' lyrics=%s', _head_par( $sym->{info}->{lyrics} );
  }
  if ( $sym->{info}->{gchord} ) {
    $abc .= sprintf ' gchord=%s', _head_par( $sym->{info}->{gchord} );
  }
  if ( $sym->{info}->{scale} ) {
    $abc .= sprintf ' scale=%.2f', $sym->{info}->{scale};
  }

  #  print next symbol if it is a clef
  if ( ref( $c_tune->{symbols}->[ $c_sym_ix + 1 ] )
       && $c_tune->{symbols}->[ $c_sym_ix + 1 ]->{type} == ABC_T_CLEF )
  {
    $abc = _clef_dump( $abc, $c_tune->{symbols}->[ $c_sym_ix + 1 ] );
  }

  return $abc;
}

# -- return abc of voice overlay
sub _vover_to_abc {
  my ( $new_abc, $sym ) = @_;

  given ( $sym->{info}->{type} ) {
    when (V_OVER_V) { $new_abc .= q{&}; }
    when (V_OVER_S) { $new_abc .= '(&'; }
    when (V_OVER_E) { $new_abc .= '&)'; }
  }

  return $new_abc;
}


################################### Chord.pm ################################

# -- Returns the (first) pitch at the provided scaleDegree (chordStep)
#    Returns undef if none can be found.
sub get_chord_step {
  my ( $sym, $chord_step, $test_root ) = @_;

  if ( !$test_root ) {
    $test_root = root($sym);
    if ( !$test_root ) {
      die "Cannot run get_chord_step without a root\n";
    }
  }

  for my $note_ref ( _get_chord_notes($sym) ) {
    my ( $d_int, $c_int ) = _notes_to_interval( $test_root, $note_ref );
    my $g_int_info = _get_generic_info( $d_int->{generic} );
    if ( $g_int_info->{mod7} == $chord_step ) {
      return $note_ref;
    }
  }

  return;
}

# -- Shortcut for getChordStep(5)
sub get_fifth {
  my $sym = shift;

  return get_chord_step($sym, 5);
}

# -- Shortcut for getChordStep(7)
sub get_seventh {
  my $sym = shift;

  return get_chord_step($sym, 7);
}

# -- Shortcut for getChordStep(3)
sub get_third {
  my $sym = shift;

  return get_chord_step($sym, 3);
}


# -- Returns True if chord is a Dominant Seventh, that is, if it contains only notes that are
#      either in unison with the root, a major third above the root, a perfect fifth, or a major
#      seventh above the root. Additionally, must contain at least one of each third and fifth
#      above the root. Chord must be spelled correctly. Otherwise returns false.
sub is_dominant_seventh {
  my $sym = shift;

  my $third   = get_third($sym);
  my $fifth   = get_fifth($sym);
  my $seventh = get_seventh($sym);

  return 0 if ( not $third or not $fifth or not $seventh );

  for my $note_ref ( _get_chord_notes($sym) ) {
    my ( $d_int, $c_int ) = _notes_to_interval( root($sym), $note_ref );
    my $c_int_info = _get_chromatic_info($c_int);
    # if there's a note that doesn't belong to a dominant seventh (root:0, major third:4, a perfect
    # fifth:7 and a minor seventh:10) then returns false
    if (    ( $c_int_info->{mod12} != 0 )
         && ( $c_int_info->{mod12} != 4 )
         && ( $c_int_info->{mod12} != 7 )
         && ( $c_int_info->{mod12} != 10 ) )
    {
      return 0;
    }
  }

  return 1;
}

# -- Returns True if chord is a Minor Triad, that is, if it contains only notes that are
#      either in unison with the root, a minor third above the root, or a perfect fifth above the
#      root. Additionally, must contain at least one of each third and fifth above the root.
#      Chord must be spelled correctly. Otherwise returns false.
sub is_minor_triad {
  my $sym = shift;

  my $third = get_third($sym);
  my $fifth = get_fifth($sym);

  return 0 if ( not $third or not $fifth );

  for my $note_ref ( _get_chord_notes($sym) ) {
    my ( $d_int, $c_int ) = _notes_to_interval( root($sym), $note_ref );
    my $c_int_info = _get_chromatic_info($c_int);
    # if there's a note that doesn't belong to a major triad (root:0, minor third:3 and a perfect
    # fifth:7) then returns false
    if (    ( $c_int_info->{mod12} != 0 )
         && ( $c_int_info->{mod12} != 3 )
         && ( $c_int_info->{mod12} != 7 ) )
    {
      return 0;
    }
  }

  return 1;
}

# -- Returns True if chord is a Major Triad, that is, if it contains only notes that are
#      either in unison with the root, a major third above the root, or a perfect fifth above the
#      root. Additionally, must contain at least one of each third and fifth above the root.
#      Chord must be spelled correctly. Otherwise returns false.
sub is_major_triad {
  my $sym = shift;

  my $third = get_third($sym);
  my $fifth = get_fifth($sym);

  return 0 if ( not $third or not $fifth );

  for my $note_ref ( _get_chord_notes($sym) ) {
    my ( $d_int, $c_int ) = _notes_to_interval( root($sym), $note_ref );
    my $c_int_info = _get_chromatic_info($c_int);
    # if there's a note that doesn't belong to a major triad (root:0, major third:4 and a perfect
    # fifth:7) then returns false
    if (    ( $c_int_info->{mod12} != 0 )
         && ( $c_int_info->{mod12} != 4 )
         && ( $c_int_info->{mod12} != 7 ) )
    {
      return 0;
    }
  }

  return 1;
}

# -- Looks for the root by finding the note with the most 3rds above it
sub root {
  my $sym = shift;
  my @old_roots = _get_chord_notes($sym); # note_refs
  my @new_roots = ();
  my $roots     = 0;
  my $n         = 3;

  while (1) {
    if ( scalar @old_roots == 1 ) {
      return $old_roots[0];
    } elsif ( scalar @old_roots == 0 ) {
      die "No notes in chord\n";
    }
    for my $test_root (@old_roots) {
      if ( get_chord_step( $sym, $n, $test_root ) ) {    ##n>7 = bug
        push @new_roots, $test_root;
        $roots++;
      }
    }
    if    ( $roots == 1 ) { return pop @new_roots; }
    elsif ( $roots == 0 ) { return $old_roots[0]; }
    @old_roots = @new_roots;
    @new_roots = ();
    $n += 2;
    if ( $n > 7 ) { $n -= 7; }
    if ( $n == 6 ) {
      die "looping chord with no root: comprises all notes in the scale\n";
    }
    $roots = 0;
  }

  return;
}

########## Chord.pm PRIVATE FUNCTIONS ##########

# -- Returns an array containing a chord's notes
#    Each note is composed of its pits and accs
sub _get_chord_notes {
  my $sym = shift;

  my @notes = ();
  for my $ix ( 0 .. $sym->{info}->{nhd} ) {
    push @notes,
      {
        pits => $sym->{info}->{pits}->[$ix],
        accs => $sym->{info}->{accs}->[$ix]
      };
  }

  return @notes;
}

################################### Interval.pm ################################

our %STEPREF = (
                 'C' => 0,
                 'D' => 2,
                 'E' => 4,
                 'F' => 5,
                 'G' => 7,
                 'A' => 9,
                 'B' => 11,
               );
our @STEPNAMES = qw(C D E F G A B);
our @PREFIXSPECS =
  ( undef, 'P', 'M', 'm', 'A', 'd', 'AA', 'dd', 'AAA', 'ddd', 'AAAA', 'dddd' );

Readonly our $OBLIQUE => 0;
Readonly our $ASCENDING => 1;
Readonly our $DESCENDING => -1;

# constants provide the common numerical representation of an interval.
# this is not the number of half tone shift.

Readonly our $PERFECT    => 1;
Readonly our $MAJ        => 2;
Readonly our $MIN        => 3;
Readonly our $AUGMENTED  => 4;
Readonly our $DIMINISHED => 5;
Readonly our $DBLAUG     => 6;
Readonly our $DBLDIM     => 7;
Readonly our $TRPAUG     => 8;
Readonly our $TRPDIM     => 9;
Readonly our $QUADAUG    => 10;
Readonly our $QUADDIM    => 11;

# ordered list of perfect specifiers
our @PERFSPECIFIERS = (
                        $QUADDIM,    $TRPDIM,  $DBLDIM,
                        $DIMINISHED, $PERFECT, $AUGMENTED,
                        $DBLAUG,     $TRPAUG,  $QUADAUG,
                      );
Readonly our $PERFOFFSET => 4;    # that is, Perfect is third on the list.s

# ordered list of imperfect specifiers
our @IMPERFSPECIFIERS = (
                          $QUADDIM, $TRPDIM, $DBLDIM,    $DIMINISHED,
                          $MIN,     $MAJ,    $AUGMENTED, $DBLAUG,
                          $TRPAUG,  $QUADAUG,
                        );
Readonly our $MAJOFFSET => 5;    # index of Major

# -- Returns an integer of the generic interval number
#      (P5 = 5, M3 = 3, minor 3 = 3 also) etc. from the given staff distance
sub _convert_staff_distance_to_interval {
  my $staff_dist = shift;

  my $gen_dist  = $staff_dist == 0 ? 1
                : $staff_dist > 0  ? $staff_dist + 1
                :                    $staff_dist - 1;

  return $gen_dist;
}

# -- Returns a diatonic interval, composed of a specifier followed by a generic interval
sub _diatonic_interval {
  my ( $specifier, $generic ) = @_;
  my $name = q{};

  if ( $specifier && $generic ) {
    $name = "$PREFIXSPECS[$specifier]" . abs $generic;
  }

  my $d_int = { name => $name, specifier => $specifier, generic => $generic };

  return $d_int;
}

# -- Returns the pitch alteration as a numeric value, where 1 is the space of one half step and all
#      base pitch values are given by step alone.
sub _get_alter {
  my $acc = shift;
  my $alter;

  given ($acc) {
    when ( [ 0, 2 ] ) { $alter = 0; }
    when (1)          { $alter = 1; }
    when (3)          { $alter = -1; }
    when (4)          { $alter = 2; }
    when (5)          { $alter = -2; }
  }

  return $alter;
}

# -- Extracts information related to a chromatic interval
sub _get_chromatic_info {
  my $c_int = shift;
  my $c_int_info = {};

  my $directed   = $c_int;
  my $undirected = abs $c_int;

  $c_int_info->{semitones}  = $directed;
  $c_int_info->{directed}   = $directed;
  $c_int_info->{undirected} = $undirected;

  my $direction = $directed == 0            ? $OBLIQUE
                : $directed == $undirected  ? $ASCENDING
                :                             $DESCENDING;
  $c_int_info->{direction} = $direction;

  $c_int_info->{mod12} = $c_int_info->{semitones} % 12;

  return $c_int_info;
}

# -- Extracts information related to a generic interval
sub _get_generic_info {
  my $g_int       = shift;
  my $g_int_info = {};

  my $directed   = $g_int;
  my $undirected = abs $g_int;
  $g_int_info->{directed}   = $directed;
  $g_int_info->{undirected} = $undirected;

  if ( $directed == 0 ) { die "The Zeroth is not an interval\n"; }
  my $direction = $directed == 1           ? $OBLIQUE
                : $directed == $undirected ? $ASCENDING
                :                            $DESCENDING;
  $g_int_info->{direction} = $direction;

  # unisons (even augmented) are neither steps nor skips.
  my ( $steps, $octaves ) = POSIX::modf( $undirected / 7 );
  $steps   = int( $steps * 7 + .001 );
  $octaves = int $octaves;
  if ( $steps == 0 ) {
    $octaves--;
    $steps = 7;
  }
  $g_int_info->{simpleUndirected}  = $steps;

  # semiSimpleUndirected, same as simple, but P8 != P1
  $g_int_info->{semiSimpleUndirected} = $steps;
  $g_int_info->{undirectedOctaves}    = $octaves;

  if ($steps == 1 and $octaves >= 1) {
    $g_int_info->{semiSimpleUndirected} = 8;
  }

  if ($g_int_info->{direction} == $DESCENDING) {
      $g_int_info->{octaves} = -1 * $octaves;
      if ($steps != 1) {
          $g_int_info->{simpleDirected} = -1 * $steps;
      } else {
          $g_int_info->{simpleDirected} = 1;  # no descending unisons...
      }
      $g_int_info->{semiSimpleDirected} = -1 * $g_int_info->{semiSimpleUndirected};
  } else {
      $g_int_info->{octaves}            = $octaves;
      $g_int_info->{simpleDirected}     = $steps;
      $g_int_info->{semiSimpleDirected} = $g_int_info->{semiSimpleUndirected};
  }

  my $perfectable;
  if ( $steps == 1 || $steps == 4 || $steps == 5 ) {
    $perfectable = 1;
  } else {
    $perfectable = 0;
  }
  $g_int_info->{perfectable} = $perfectable;

  #  2 -> 7; 3 -> 6; 8 -> 1 etc.
  $g_int_info->{mod7inversion} = 9 - $g_int_info->{semiSimpleUndirected};

  $g_int_info->{mod7} =
      $g_int_info->{direction} == $DESCENDING
    ? $g_int_info->{mod7inversion}
    : $g_int_info->{simpleDirected};

  return $g_int_info;
}

# -- Given a generic interval and a chromatic interval (scalar values),
#      returns a specifier (i.e. MAJ, MIN, etc...).
sub _get_specifier_from_generic_chromatic {
  my ( $g_int, $c_int ) = @_;
  my $specifier;

  my $g_int_info = _get_generic_info($g_int);
  my $c_int_info = _get_chromatic_info($c_int);

  my @note_vals = (undef, 0, 2, 4, 5, 7, 9, 11);
  my $normal_semis = $note_vals[ $g_int_info->{simpleUndirected} ] + 12 * $g_int_info->{undirectedOctaves};

  my $these_semis;
  if (    $g_int_info->{direction} != $c_int_info->{direction}
       && $g_int_info->{direction} != $OBLIQUE
       && $c_int_info->{direction} != $OBLIQUE )
  {
    # intervals like d2 (second diminished) and dd2 (second double diminished) etc. (the last test
    # doesn't matter, since -1*0 == 0, but in theory it should be there)
    $these_semis = -1 * $c_int_info->{undirected};
  } else {
    # all normal intervals
    $these_semis = $c_int_info->{undirected};
  }

  # round out microtones
  my $semis_rounded = int( sprintf( '%.0f', $these_semis ) );

  if ( $g_int_info->{perfectable} ) {
    $specifier = $PERFSPECIFIERS[ $PERFOFFSET + $semis_rounded - $normal_semis ];
    # raise IntervalException("cannot get a specifier for a note with this many semitones off of Perfect: " + str(these_semis - normal_semis))
  } else {
    $specifier = $IMPERFSPECIFIERS[ $MAJOFFSET + $semis_rounded - $normal_semis ];
    # raise IntervalException("cannot get a specifier for a note with this many semitones off of Major: " + str(these_semis - normal_semis))
  }

  return $specifier;
}

# -- Given a generic interval and a chromatic interval, returns a diatonic interval and a chromatic interval
sub _interval_from_generic_and_chromatic {
  my ( $g_int, $c_int ) = @_;

  my $specifier = _get_specifier_from_generic_chromatic( $g_int, $c_int );
  my $d_int = _diatonic_interval( $specifier, $g_int );

  return ($d_int, $c_int);
}

# -- Given two notes, it returns the chromatic interval
#    It treats interval spaces in half-steps. So Major 3rd and Diminished 4th are the same.
sub _notes_to_chromatic {
  my ( $note1_ref, $note2_ref ) = @_;

  my $ps1 = _get_ps($note1_ref);
  my $ps2 = _get_ps($note2_ref);

  # returns chromatic interval in ps
  return $ps2 - $ps1;
}

# -- Given two notes, it returns the generic interval
sub _notes_to_generic {
  my ( $note1_ref, $note2_ref ) = @_;

  my $pits1 = $note1_ref->{pits};
  my $pits2 = $note2_ref->{pits};

  return _convert_staff_distance_to_interval( $pits2 - $pits1 );
}

# -- Given two notes, it returns an interval
sub _notes_to_interval {
  my ( $note1_ref, $note2_ref ) = @_;

  if (!ref $note2_ref) {
    #default note => C
    $note2_ref->{pits} = 16;
    $note2_ref->{accs} = 0;
  }
  my $g_int = _notes_to_generic($note1_ref, $note2_ref);
  my $c_int = _notes_to_chromatic($note1_ref, $note2_ref);

  # returns ( diatonic_interval, chromatic_interval)
  return _interval_from_generic_and_chromatic($g_int, $c_int);
}

# -- Creates a simpler note structure than abc's
sub _simplify_note {
  my $abc_note = shift;
  my $simplified_note = {
                          pits => $abc_note->{info}->{pits}->[0],
                          accs => $abc_note->{info}->{accs}->[0]
                        };

  return $simplified_note;
}


######################## Pitch.pm #########################

# basic accidental code and string definitions
our %ACCIDENTAL_NAME_TO_MODIFIER = (
                                     -4   => 'quadruple-flat',
                                     -3   => 'triple-flat',
                                     -2   => 'double-flat',
                                     -1.5 => 'one-and-a-half-flat',
                                     -1   => 'flat',
                                     -0.5 => 'half-flat',
                                     0    => 'natural',
                                     0.5  => 'half-sharp',
                                     1    => 'sharp',
                                     1.5  => 'one-and-a-half-sharp',
                                     2    => 'double-sharp',
                                     3    => 'triple-sharp',
                                     4    => 'quadruple-sharp',
                                   );

# How many significant digits to keep in pitch space resolution where 1 is a half
# step. this means that 4 significant digits of cents will be kept
Readonly our $PITCH_SPACE_SIG_DIGITS => 6;


# -- Returns the pitch class of the note.
#    The pitch_class is a number from 0-11, where 0 = C, 1 = C#/D-, etc.
sub get_pitch_class {
  my $note_ref = shift;

  my $pitch_class = _get_ps($note_ref);

  return $pitch_class % 12;
}


# Returns the pitch name of a note: A-flat, C-sharp
sub get_pitch_name {
  my $note = shift;

  my ( $step, $acc, $micro ) = _convert_ps_to_step( _get_ps($note) );

  my $pitch_name = "$step-$ACCIDENTAL_NAME_TO_MODIFIER{$acc}";

  return $pitch_name;
}


########## Chord.pm PRIVATE FUNCTIONS ##########

sub _calculate_alter_micro {
  my $micro = shift;
  my $alter;

  # if close enough to a quarter tone
  if ( sprintf( '%.1f', $micro ) == 0.5 ) {
    # if can round to .5, than this is a quartertone accidental
    $alter = 0.5;
    # need to find microtonal alteration around this value
    # of alter is 0.5 and micro is .7 than  micro should be .2
    # of alter is 0.5 and micro is .4 than  micro should be -.1
    $micro = $micro - $alter;
  }
  # if greater than .5
  elsif ( $micro > 0.25 and $micro < 0.75 ) {
    $alter = 0.5;
    $micro = $micro - $alter;
  }
  # if closer to 1, than go to the higher alter and get negative micro
  elsif ( $micro >= 0.75 and $micro < 1 ) {
    $alter = 1;
    $micro = $micro - $alter;
  }
  # not greater than .25
  elsif ( $micro > 0 ) {
    $alter = 0;
    $micro = $micro;    # no change necessary
  } else {
    $alter = 0;
    $micro = 0;
  }

  return ( $alter, $micro );
}

sub _calculate_name_acc {
  my ( $pc, $alter ) = @_;
  my $pc_name = 0;
  my $acc = 0;

  # check for unnecessary enharmonics
  if ( ( any { $_ == $pc } ( 4, 11 ) ) and $alter == 1 ) {
    $acc     = 0;
    $pc_name = ( $pc + 1 ) % 12;
  }
  # its a natural; nothing to do
  elsif ( ( any { $_ == $pc } values %STEPREF ) ) {
    $acc     = $alter;
    $pc_name = $pc;
  }
  # if we take the pc down a half-step, do we get a stepref (natural) value
  elsif ( ( any { $_ == ( $pc - 1 ) } ( 0, 5, 7 ) ) ) {    # c, f, g: can be sharped
    # then we need an accidental to accommodate; here, a sharp
    $acc     = 1 + $alter;
    $pc_name = $pc - 1;
  }
  # if we take the pc up a half-step, do we get a stepref (natural) value
  elsif ( ( any { $_ == ( $pc + 1 ) } ( 11, 4 ) ) ) {  # b, e: can be flattened
    # then we need an accidental to accommodate; here, a flat
    $acc     = (-1) + $alter;
    $pc_name = $pc + 1;
  }
  else {die "cannot match condition for pc: $pc\t($sym->{linenum}:$sym->{colnum})\n";}

  return ( $acc, $pc_name );
}

# Takes in a pitch space floating-point value
# Returns a tuple of Step, an Accidental and a Microtone
sub _convert_ps_to_step {
  my $ps = shift;
  my $alter;
  my $name;

  # rounding here is essential
  $ps = sprintf q{%.}.$PITCH_SPACE_SIG_DIGITS.'f', $ps;
  my $pc_real = $ps % 12;

  # micro here will be between 0 and 1
  my ( $pc, $micro ) = ( $pc_real / 1, POSIX::fmod( $pc_real, 1 ) );

  ( $alter, $micro ) = _calculate_alter_micro($micro);

  $pc = int $pc;

  my ( $acc, $pc_name ) = _calculate_name_acc( $pc, $alter );

  for my $key ( keys %STEPREF ) {
    if ( $pc_name == $STEPREF{$key} ) {
      $name = $key;
      last;
    }
  }

  # if a micro is present, create object, else return None
  $micro = $micro ? $micro * 100    # provide cents value; these are alter values
                  : 0;

  return ($name, $acc, $micro);
}

# -- Calculates the pitch space number.
#    Returns a pitch space value as a floating point MIDI note number.
sub _get_ps {
  my $note_ref = shift;

  # Simplifies the note symbol
  if ( $note_ref->{info} ) { $note_ref = _simplify_note($note_ref); }

  my $step_oct = _step_dump( $note_ref->{pits} );    # eg: C' g,,
  my $step     = uc $step_oct;
  $step =~ s/[',]//gxms;                             # removes octave

  # default octave is 4 <=> C (pits 16)
  # if it's upper case ('C') then octave 4, else 5
  my $octave = $step_oct !~ /\p{IsLower}/xms ? 4 : 5;
  my @down = $step_oct =~ /,/gxms;
  $octave -= scalar @down;
  my @up = $step_oct =~ /'/gxms;
  $octave += scalar @up;

  my $ps = ( ( $octave + 1 ) * 12 ) + $STEPREF{$step};

  my $acc = $note_ref->{accs};
  if ($acc) { $ps += _get_alter($acc); }
  #FIXME ver como é com os microtones
  # if self.microtone is not None:
  #     ps = ps + self.microtone.alter

  # FIXME ter em atencao os acidentes provenientes da armacao de clave (key) (usar info->{sf}),
  #  compasso (talvez usar current measure in voice) e notas ligadas
  # TODO ver _key_header_dump para ver como lidar com explicit accidentals

  return $ps;
}

1; # End of Music::Abc::DT

__END__

=head1 VERSION

Version 0.01

=cut

=head1 NAME

Music::Abc::DT - The great new Music::Abc::DT!

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use Music::Abc::DT;

    my $file = "adeste.abc";
    my %measures = ();

    dt (
      $file,
      (
        'bar'   =>  sub{ $measures{$c_voice}++ },
        '-end'  =>  sub { foreach (sort keys %measures) {
                            print "$_ has $measures{$_} bar(s).\n"
                          }
                        }
      )
    );


=head1 DESCRIPTION

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

# voice structure which stores each voice's stuff
$voice_struct = (
  abcm2ps_voice_id => (
    id => original_abc_voice_id,      # text
    name => original_abc_voice_name,  # text
    time => current_voice_offset,     # int; to obtain values in quarter lengths, time must be divided by 384
    meter => (
      text => meter_original_abc,       # text
      wmeasure => measure_duration      # int
    ),
    length => length_original_abc,      # text
    key => (
      text => key_original_abc,         # text
      sf => key_sf,                     # int
      exp => key_exp,                   # int
      nacc => key_nacc,                 # int
      pits => key_pits,                 # int
      accs => key_accs,                 # int
    ),
  )
)

=head1 SUBROUTINES/METHODS

=head2 dt

=cut

=head2 dt_string

=cut

=head2 get_length

=cut

=head2 get_meter

=cut

=head2 get_wmeasure

=cut

=head2 get_gchords

=cut

=head2 get_key

=cut

=head2 get_time

=cut

=head2 get_time_ql

=cut

=head2 toabc

=cut

=head2 find_consecutive_notes_in_measure

=cut

=head2 is_dominant_seventh

=cut

=head2 is_major_triad

=cut

=head2 is_minor_triad

=cut

=head2 get_chord_step

=cut

=head2 get_fifth

=cut

=head2 get_third

=cut

=head2 get_seventh

=cut

=head2 root

=cut

=head2 get_pitch_class

=cut

=head2 get_pitch_name

=cut

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=head1 INCOMPATIBILITIES

=head1 AUTHOR

Bruno Azevedo, C<< <azevedo.252 at gmail.com> >>

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to C<bug-music-abc-dt at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Music-Abc-DT>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Music::Abc::DT


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Music-Abc-DT>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Music-Abc-DT>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Music-Abc-DT>

=item * Search CPAN

L<http://search.cpan.org/dist/Music-Abc-DT/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2013 Bruno Azevedo.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut
