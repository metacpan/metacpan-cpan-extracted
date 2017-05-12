#!/usr/bin/perl
use Music::Abc::DT qw( _get_transformation _get_note_rest_bar_actuators
_get_null_info_clef_actuators $deco_tb %state_name $c_voice %voice_struct );
use Test::More tests => 1;
use strict;
use warnings;

subtest '_get_transformation' => sub {
  plan tests => 5;

  subtest 'when there is no actuator more specific than \'.\'' => sub {
    TODO: {
      todo_skip 'to be implemented', 1;
    }
  };

  subtest 'when there is no actuator more specific than a state' => sub {
    TODO: {
      todo_skip 'to be implemented', 1;
    }
  };

  subtest 'when symbol\'s type is pscom' => sub {
    my $sym = {
                text  => '%%MIDI program 1',
                type  => Music::Abc::DT::ABC_T_PSCOM,
                state => Music::Abc::DT::ABC_S_HEAD,
              };

    subtest '_get_pscom_actuators' => sub {
      _test_pscom_actuators($sym);
    };
  };

  subtest 'when symbol\'s type is either a note, a rest or a bar' => sub {
    subtest '_get_note_rest_bar_actuators' => sub {
      _test_note_rest_bar_actuators( Music::Abc::DT::ABC_T_NOTE, 'note', 'ff', { pits => 23, accs => 0, abc => q{c} } );
      _test_note_rest_bar_actuators( Music::Abc::DT::ABC_T_REST, 'rest', 'fermata' );
      _test_note_rest_bar_actuators( Music::Abc::DT::ABC_T_BAR, 'bar', 'fine', { type => 65, abc => q{:|} } );
    };
  };

  subtest 'when symbol\'s type is either a null, a info or a clef' => sub {
    subtest '_get_null_info_clef_actuators' => sub {
      my $info = {
                   text  => 'V:4',
                   state => Music::Abc::DT::ABC_S_HEAD,
                   info  => { id => 4, fname => "Tenor", voice => 3 },
                 };

      _test_null_info_clef_actuators( Music::Abc::DT::ABC_T_NULL, 'null', $info );
      _test_null_info_clef_actuators( Music::Abc::DT::ABC_T_INFO, 'info', $info );
      _test_null_info_clef_actuators( Music::Abc::DT::ABC_T_CLEF, 'clef', $info );
    };
  };
};

done_testing;

################################# PRIVATE FUNCTIONS ###############################

sub _test_pscom_actuators {
  my $sym = shift;

  subtest 'when the handler has only the actuator pscom and no other more specific than it' => sub {
    my $expected = 'actuator pscom is chosen';
    my %abch     = ( 'pscom' => sub { $expected }, );
    my $proc     = _get_transformation( \%abch, $sym );
    my $got      = $proc->();

    is( $got, $expected,
        '_get_transformation returns a subroutine belonging to actuator pscom' );
  };

  subtest 'when the symbol is an abcMIDI command' => sub {

    subtest 'when the handler has the actuators pscom and MIDI' => sub {
      my $expected = 'actuator MIDI is chosen';
      my %abch = (
                   'pscom' => sub { 'actuator pscom is chosen' },
                   'MIDI'  => sub { $expected },
                 );
      my $proc = _get_transformation( \%abch, $sym );
      my $got = $proc->();

      is( $got, $expected,
          '_get_transformation returns a subroutine belonging to actuator MIDI' );
    };

    subtest 'when the handler has the actuators pscom, MIDI and MIDI::program' => sub {
      my $expected = 'actuator MIDI::program is chosen';
      my %abch = (
                   'pscom'         => sub { 'actuator pscom is chosen' },
                   'MIDI'          => sub { 'actuator MIDI is chosen' },
                   'MIDI::program' => sub { $expected },
                 );
      my $proc = _get_transformation( \%abch, $sym );
      my $got = $proc->();

      is(
        $got,
        $expected,
        '_get_transformation returns a subroutine belonging to actuator MIDI::program'
      );
    };

  };

  subtest 'when the symbol is a formatting command' => sub {
    foreach ( 'staves', 'score' ) {
      my $actuator = $_;
      $sym->{text} = "%%$actuator SATB";
      my $expected = "actuator $actuator is chosen";
      my %abch     = ( $actuator => sub { $expected }, );
      my $proc     = _get_transformation( \%abch, $sym );
      my $got      = $proc->();

      is( $got, $expected,
          "_get_transformation returns a subroutine belonging to actuator $actuator" );
    }
  };

  return;
}

sub _test_note_rest_bar_actuators {
  my ( $type, $actuator, $deco, $info ) = @_;

  subtest "when the symbol's type is a $actuator" => sub {
    my $sym = {
                text  => q{},
                type  => $type,
                state => Music::Abc::DT::ABC_S_TUNE,
              };
    $c_voice                      = 0;
    $voice_struct{$c_voice}{id}   = 1;
    $voice_struct{$c_voice}{name} = 'Tenor';
    my $voice_id   = $voice_struct{$c_voice}{id};
    my $voice_name = $voice_struct{$c_voice}{name};

    if ( $type == Music::Abc::DT::ABC_T_BAR ) {
      $sym->{info}->{type} = $info->{type};
    }
    elsif ( $type == Music::Abc::DT::ABC_T_NOTE ) {
      $sym->{info}->{pits}->[0] = $info->{pits};
      $sym->{info}->{accs}->[0] = $info->{accs};
      $sym->{info}->{nhd} = 0;
    }

    subtest "when the handler has only the actuator $actuator and no other more specific than it" => sub {
      my $expected = "actuator $actuator is chosen";
      my %abch     = ( $actuator => sub { $expected }, );
      my $proc     = _get_note_rest_bar_actuators( \%abch, $sym, undef );
      my $got      = $proc->();

      is( $got, $expected,
          "_get_note_rest_bar_actuators returns a subroutine belonging to actuator $actuator" );
    };

    subtest "when the handler has the actuators $actuator and "
      . "V:$voice_name" . "::$actuator" => sub {
      my $expected = "actuator V:$voice_name" . "::$actuator is chosen";
      my %abch = (
                   $actuator => sub { "actuator $actuator is chosen" },
                   "V:$voice_name" . "::$actuator" => sub { $expected },
                 );
      my $proc     = _get_note_rest_bar_actuators( \%abch, $sym, undef );
      my $got      = $proc->();

      is( $got, $expected,
          "_get_note_rest_bar_actuators returns a subroutine belonging to actuator V:$voice_name" . "::$actuator" );
    };

    subtest "when the handler has the actuators $actuator, "
      . "V:$voice_name" . "::$actuator and "
      . "V:$voice_id" . "::$actuator" => sub {
      my $expected = "actuator V:$voice_id" . "::$actuator is chosen";
      my %abch = (
                   $actuator => sub { "actuator $actuator is chosen" },
                   "V:$voice_name" . "::$actuator" => sub { "actuator V:$voice_name" . "::$actuator is chosen" },
                   "V:$voice_id" . "::$actuator"   => sub { $expected },
                 );
      my $proc     = _get_note_rest_bar_actuators( \%abch, $sym, undef );
      my $got      = $proc->();

      is( $got, $expected,
          "_get_note_rest_bar_actuators returns a subroutine belonging to actuator V:$voice_id" . "::$actuator" );
    };

    if ( $type == Music::Abc::DT::ABC_T_NOTE ) {
      _test_gchord_actuators( $sym, $actuator );

      _test_note_pitch_actuators( $sym, $actuator, $voice_name, $voice_id, $info );
    }

    if ( $type == Music::Abc::DT::ABC_T_BAR ) {
      subtest "when the handler has the actuators $actuator and $info->{abc}" => sub {
        my $expected = "actuator $info->{abc} is chosen";
        my %abch = (
                     $actuator   => sub { "actuator $actuator is chosen" },
                     $info->{abc} => sub { $expected },
                   );
        my $proc     = _get_note_rest_bar_actuators( \%abch, $sym, undef );
        my $got      = $proc->();

        is( $got, $expected,
            "_get_note_rest_bar_actuators returns a subroutine belonging to actuator $info->{abc}" );
      };
    }

    _test_decorations( $type, $actuator, $sym, $deco, $info );
  };

  return;
}

sub _test_gchord_actuators {
  my ( $sym, $actuator ) = @_;

  subtest 'when the note has accompaniment chord(s)' => sub {
    my ( $gchord, $gchord2 ) = ( 'F', 'F7' );
    $sym->{text} = $gchord;

    subtest "when the handler has the actuators $actuator and gchord" => sub {
      my $expected = 'actuator gchord is chosen';
      my %abch = (
                   $actuator => sub { "actuator $actuator is chosen" },
                   'gchord'  => sub { $expected },
                 );
      my $proc     = _get_note_rest_bar_actuators( \%abch, $sym, undef );
      my $got      = $proc->();

      is( $got, $expected,
          '_get_note_rest_bar_actuators returns a subroutine belonging to actuator gchord' );
    };

    subtest "when the handler has the actuators $actuator, "
      . 'gchord and '
      . 'gchord::' . $gchord  => sub {

      subtest "when the symbol has gchords in the following order: $gchord, $gchord2" => sub {
        $sym->{text} = "$gchord;$gchord2";
        my $expected = 'actuator gchord::' . "$gchord is chosen";
        my %abch = (
                     $actuator => sub { "actuator $actuator is chosen" },
                     'gchord'  => sub { 'actuator gchord is chosen' },
                     'gchord::' . $gchord  => sub { $expected },
                   );
        my $proc     = _get_note_rest_bar_actuators( \%abch, $sym, undef );
        my $got      = $proc->();

        is( $got, $expected,
            '_get_note_rest_bar_actuators returns a subroutine belonging to actuator gchord::' . $gchord );
      };

      subtest "when the symbol has gchords in the following order: $gchord2, $gchord" => sub {
        $sym->{text} = "$gchord2;$gchord";
        my $expected = 'actuator gchord::' . "$gchord is chosen";
        my %abch = (
                     $actuator => sub { "actuator $actuator is chosen" },
                     'gchord'  => sub { 'actuator gchord is chosen' },
                     'gchord::' . $gchord  => sub { $expected },
                   );
        my $proc     = _get_note_rest_bar_actuators( \%abch, $sym, undef );
        my $got      = $proc->();

        is( $got, $expected,
            '_get_note_rest_bar_actuators returns a subroutine belonging to actuator gchord::' . $gchord );
      };
    };

    subtest "when the handler has the actuators $actuator, "
      . 'gchord::' . "$gchord and "
      . 'gchord::' . "$gchord2" => sub {

      subtest "when the symbol has gchords in the following order: $gchord, $gchord2" => sub {
        $sym->{text} = "$gchord;$gchord2";
        my $expected = 'actuator gchord::' . "$gchord is chosen";
        my %abch = (
                     $actuator => sub { "actuator $actuator is chosen" },
                     'gchord'  => sub { 'actuator gchord is chosen' },
                     'gchord::' . $gchord  => sub { $expected },
                     'gchord::' . $gchord2  => sub { 'actuator gchord::' . "$gchord2 is chosen" },
                   );
        my $proc     = _get_note_rest_bar_actuators( \%abch, $sym, undef );
        my $got      = $proc->();

        is( $got, $expected,
            '_get_note_rest_bar_actuators returns a subroutine belonging to actuator gchord::' . $gchord );
      };

      subtest "when the symbol has gchords in the following order: $gchord2, $gchord" => sub {
        $sym->{text} = "$gchord2;$gchord";
        my $expected = 'actuator gchord::' . "$gchord2 is chosen";
        my %abch = (
                     $actuator => sub { "actuator $actuator is chosen" },
                     'gchord'  => sub { 'actuator gchord is chosen' },
                     'gchord::' . $gchord  => sub { 'actuator gchord::' . "$gchord is chosen" },
                     'gchord::' . $gchord2  => sub { $expected },
                   );
        my $proc     = _get_note_rest_bar_actuators( \%abch, $sym, undef );
        my $got      = $proc->();

        is( $got, $expected,
            '_get_note_rest_bar_actuators returns a subroutine belonging to actuator gchord::' . $gchord2 );
      };
    };
  };

  #TODO not fully tested

  return;
}

sub _test_note_pitch_actuators {
  my ( $sym, $actuator, $voice_name, $voice_id, $info ) = @_;

  subtest "when the symbol's type is a $actuator" => sub {
    subtest "when the handler has the actuators $actuator, "
      . "V:$voice_name" . "::$actuator, "
      . "V:$voice_id" . "::$actuator and "
      . "$actuator" . "::$info->{abc}" => sub {
      my $expected = "actuator $actuator" . "::$info->{abc} is chosen";
      my %abch = (
                   $actuator                       => sub { "actuator $actuator is chosen" },
                   "V:$voice_name" . "::$actuator" => sub { "actuator V:$voice_name" . "::$actuator is chosen" },
                   "V:$voice_id"   . "::$actuator" => sub { "actuator V:$voice_id" . "::$actuator is chosen" },
                   "$actuator" . "::$info->{abc}"  => sub { $expected },
                 );
      my $proc     = _get_note_rest_bar_actuators( \%abch, $sym, undef );
      my $got      = $proc->();

      is( $got, $expected,
          "_get_note_rest_bar_actuators returns a subroutine belonging to actuator $actuator" . "::$info->{abc}" );
    };

    subtest "when the handler has the actuators $actuator, "
      . "V:$voice_name" . "::$actuator, "
      . "V:$voice_id" . "::$actuator, "
      . "$actuator" . "::$info->{abc} and "
      . "V:$voice_name" . "::$actuator" . "::$info->{abc}" => sub {
      my $expected = "V:$voice_name" . "::$actuator" . "::$info->{abc} is chosen";
      my %abch = (
                   $actuator                       => sub { "actuator $actuator is chosen" },
                   "V:$voice_name" . "::$actuator" => sub { "actuator V:$voice_name" . "::$actuator is chosen" },
                   "V:$voice_id"   . "::$actuator" => sub { "actuator V:$voice_id" . "::$actuator is chosen" },
                   "$actuator" . "::$info->{abc}"  => sub { "actuator V:$voice_name" . "::$actuator is chosen" },
                   "V:$voice_name" . "::$actuator" . "::$info->{abc}" => sub { $expected },
                 );
      my $proc = _get_note_rest_bar_actuators( \%abch, $sym, undef );
      my $got  = $proc->();

      is( $got, $expected,
          "_get_note_rest_bar_actuators returns a subroutine belonging to actuator V:$voice_name" . "::$actuator" . "::$info->{abc}" );
    };

    subtest "when the handler has the actuators $actuator, "
      . "V:$voice_name" . "::$actuator, "
      . "V:$voice_id" . "::$actuator, "
      . "$actuator" . "::$info->{abc}, "
      . "V:$voice_name" . "::$actuator" . "::$info->{abc} and "
      . "V:$voice_id" . "::$actuator" . "::$info->{abc}" => sub {
      my $expected = "V:$voice_id" . "::$actuator" . "::$info->{abc} is chosen";
      my %abch = (
                   $actuator                       => sub { "actuator $actuator is chosen" },
                   "V:$voice_name" . "::$actuator" => sub { "actuator V:$voice_name" . "::$actuator is chosen" },
                   "V:$voice_id"   . "::$actuator" => sub { "actuator V:$voice_id" . "::$actuator is chosen" },
                   "$actuator" . "::$info->{abc}"  => sub { "actuator V:$voice_name" . "::$actuator is chosen" },
                   "V:$voice_name" . "::$actuator" . "::$info->{abc}" => sub { "V:$voice_name" . "::$actuator" . "::$info->{abc} is chosen" },
                   "V:$voice_id" . "::$actuator" . "::$info->{abc}"   => sub { $expected },
                 );
      my $proc = _get_note_rest_bar_actuators( \%abch, $sym, undef );
      my $got  = $proc->();

      is( $got, $expected,
          "_get_note_rest_bar_actuators returns a subroutine belonging to actuator V:$voice_id" . "::$actuator" . "::$info->{abc}" );
    };
  };

  return;
}

sub _test_null_info_clef_actuators {
  my ( $type, $actuator, $info ) = @_;

  subtest "when the symbol's type is a $actuator" => sub {
    my $sym = {
                text  => $info->{text},
                type  => $type,
                state => $info->{state},
                info  => $info->{info},
              };
    my $state = $sym->{state};

    $c_voice = $info->{info}->{voice};
    $voice_struct{$c_voice}{id}   ||= $sym->{info}->{id};
    $voice_struct{$c_voice}{name} ||= $sym->{info}->{fname} || q{};


    subtest "when the handler has only the actuator $actuator and no other more specific than it" => sub {
      my $expected = "actuator $actuator is chosen";
      my %abch     = ( $actuator => sub { $expected }, );
      my $proc     = _get_null_info_clef_actuators( \%abch, $sym, undef );
      my $got      = $proc->();

      is( $got, $expected,
          "_get_null_info_clef_actuators returns a subroutine belonging to actuator $actuator" );
    };

    subtest "when the handler has the actuators $actuator and $state_name{$state}::$actuator" => sub {
      my $expected = "actuator $state_name{$state}::$actuator is chosen";
      my %abch = (
                   $actuator => sub { "actuator $actuator is chosen" },
                   "$state_name{$state}::$actuator" => sub { $expected },
                 );
      my $proc = _get_null_info_clef_actuators( \%abch, $sym, undef );
      my $got = $proc->();

      is( $got, $expected,
          "_get_null_info_clef_actuators returns a subroutine belonging to actuator $state_name{$state}::$actuator" );
    };

    if ( $type == Music::Abc::DT::ABC_T_INFO ) {
      _test_info_symbol( $sym, $actuator, $info );
    }
  };

  return;
}

sub _test_info_symbol {
  my ( $sym, $actuator, $info ) = @_;
  my $state = $sym->{state};
  my $info_type = substr $sym->{text}, 0, 1;

  subtest "when the handler has the actuators $actuator, $state_name{$state}::$actuator and $info_type:" => sub {
    my $expected = "actuator $info_type: is chosen";
    my %abch = (
                 $actuator                        => sub { "actuator $actuator is chosen" },
                 "$state_name{$state}::$actuator" => sub { "actuator $state_name{$state}::$actuator is chosen" },
                 "$info_type:"                    => sub { $expected },
               );
    my $proc = _get_null_info_clef_actuators( \%abch, $sym, undef );
    my $got = $proc->();

    is( $got, $expected,
        "_get_null_info_clef_actuators returns a subroutine belonging to actuator $info_type:" );
  };

  subtest "when the handler has the actuators $actuator, "
    . "$state_name{$state}::$actuator, "
    . "$info_type: and "
    . "$state_name{$state}::$info_type:" => sub {

    my $expected = "actuator $state_name{$state}::$info_type: is chosen";
    my %abch = (
                 $actuator                          => sub { "actuator $actuator is chosen" },
                 "$state_name{$state}::$actuator"   => sub { "actuator $state_name{$state}::$actuator is chosen" },
                 "$info_type:"                      => sub { "actuator $info_type: is chosen" },
                 "$state_name{$state}::$info_type:" => sub { $expected },
               );
    my $proc = _get_null_info_clef_actuators( \%abch, $sym, undef );
    my $got = $proc->();

    is( $got, $expected,
        "_get_null_info_clef_actuators returns a subroutine belonging to actuator $state_name{$state}::$info_type:" );
  };

  if ( $info_type eq 'V' ) {
    _test_voice_symbol( $sym, $actuator, $info );
  }

  if ( $info_type eq 'M' ) {
    # TODO
  }

  return;
}

sub _test_voice_symbol {
  my ( $sym, $actuator, $info ) = @_;
  my $state     = $sym->{state};
  my $info_type = substr $sym->{text}, 0, 1;
  my $voice_id  = $sym->{info}->{id};
  my $voice_name = $sym->{info}->{fname} || $voice_struct{$c_voice}{name};

  subtest "when the handler has the actuators $actuator, "
    . "$state_name{$state}::$actuator, "
    . "$info_type:, "
    . "$state_name{$state}::$info_type: and "
    . "$info_type:$voice_name" => sub {

    my $expected = "actuator $info_type:$voice_name is chosen";
    my %abch = (
                $actuator                           => sub { "actuator $actuator is chosen" },
                "$state_name{$state}::$actuator"    => sub { "actuator $state_name{$state}::$actuator is chosen" },
                "$info_type:"                       => sub { "actuator $info_type: is chosen" },
                "$state_name{$state}::$info_type:"  => sub { "actuator $state_name{$state}::$info_type: is chosen" },
                "$info_type:$voice_name"            => sub { $expected },
               );
    my $proc = _get_null_info_clef_actuators( \%abch, $sym, undef );
    my $got = $proc->();

    is( $got, $expected,
        "_get_null_info_clef_actuators returns a subroutine belonging to actuator $info_type:$voice_name" );
  };

  subtest "when the handler has the actuators $actuator, "
    . "$state_name{$state}::$actuator, "
    . "$info_type:, "
    . "$state_name{$state}::$info_type:, "
    . "$info_type:$voice_name and "
    . "$info_type:$voice_id" => sub {

    my $expected = "actuator $info_type:$voice_id is chosen";
    my %abch = (
                $actuator                           => sub { "actuator $actuator is chosen" },
                "$state_name{$state}::$actuator"    => sub { "actuator $state_name{$state}::$actuator is chosen" },
                "$info_type:"                       => sub { "actuator $info_type: is chosen" },
                "$state_name{$state}::$info_type:"  => sub { "actuator $state_name{$state}::$info_type: is chosen" },
                "$info_type:$voice_name"            => sub { "actuator $info_type:$voice_name is chosen" },
                "$info_type:$voice_id"              => sub { $expected },
               );
    my $proc = _get_null_info_clef_actuators( \%abch, $sym, undef );
    my $got = $proc->();

    is( $got, $expected,
        "_get_null_info_clef_actuators returns a subroutine belonging to actuator $info_type:$voice_id" );
  };

  subtest "when the handler has the actuators $actuator, "
    . "$state_name{$state}::$actuator, "
    . "$info_type:, "
    . "$state_name{$state}::$info_type:, "
    . "$info_type:$voice_name, "
    . "$info_type:$voice_id and "
    . "$state_name{$state}::$info_type:$voice_name" => sub {

    my $expected = "actuator $state_name{$state}::$info_type:$voice_name is chosen";
    my %abch = (
                $actuator                                     => sub { "actuator $actuator is chosen" },
                "$state_name{$state}::$actuator"              => sub { "actuator $state_name{$state}::$actuator is chosen" },
                "$info_type:"                                 => sub { "actuator $info_type: is chosen" },
                "$state_name{$state}::$info_type:"            => sub { "actuator $state_name{$state}::$info_type: is chosen" },
                "$info_type:$voice_name"                      => sub { "actuator $info_type:$voice_name is chosen" },
                "$info_type:$voice_id"                        => sub { "actuator $info_type:$voice_id is chosen" },
                "$state_name{$state}::$info_type:$voice_name" => sub { $expected },
               );
    my $proc = _get_null_info_clef_actuators( \%abch, $sym, undef );
    my $got = $proc->();

    is( $got, $expected,
        "_get_null_info_clef_actuators returns a subroutine belonging to actuator $state_name{$state}::$info_type:$voice_name" );
  };

  subtest "when the handler has the actuators $actuator, "
    . "$state_name{$state}::$actuator, "
    . "$info_type:, "
    . "$state_name{$state}::$info_type:, "
    . "$info_type:$voice_name, "
    . "$info_type:$voice_id, "
    . "$state_name{$state}::$info_type:$voice_name and "
    . "$state_name{$state}::$info_type:$voice_id" => sub {

    my $expected = "actuator $state_name{$state}::$info_type:$voice_id is chosen";
    my %abch = (
                $actuator                                     => sub { "actuator $actuator is chosen" },
                "$state_name{$state}::$actuator"              => sub { "actuator $state_name{$state}::$actuator is chosen" },
                "$info_type:"                                 => sub { "actuator $info_type: is chosen" },
                "$state_name{$state}::$info_type:"            => sub { "actuator $state_name{$state}::$info_type: is chosen" },
                "$info_type:$voice_name"                      => sub { "actuator $info_type:$voice_name is chosen" },
                "$info_type:$voice_id"                        => sub { "actuator $info_type:$voice_id is chosen" },
                "$state_name{$state}::$info_type:$voice_name" => sub { "actuator $state_name{$state}::$info_type:$voice_name is chosen" },
                "$state_name{$state}::$info_type:$voice_id"   => sub { $expected },
               );
    my $proc = _get_null_info_clef_actuators( \%abch, $sym, undef );
    my $got = $proc->();

    is( $got, $expected,
        "_get_null_info_clef_actuators returns a subroutine belonging to actuator $state_name{$state}::$info_type:$voice_name" );
  };

  return;
}


sub _test_decorations {
  my ( $type, $actuator, $sym, $deco, $bar ) = @_;

  subtest "when the $actuator has decorations" => sub {
    $sym->{info}->{dc} = {
                           n => 1,
                           h => 1,
                           s => 1,
                           t => [
                                  129, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                                  0,   0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                                  0,   0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                                  0,   0, 0, 0, 0, 0, 0, 0, 0
                                ]
                         };
    $deco_tb = { 1 => $deco };

    # decorations are more specific
    _test_deco_actuator( $type, $actuator, $sym, $bar );

    # the actual decoration is more specific
    _test_actual_decoration_actuator( $type, $actuator, $sym, $deco, $bar );
  };

  return;
}

sub _test_deco_actuator {
  my ( $type, $actuator, $sym, $bar ) = @_;

  subtest "when the handler has the actuators $actuator and deco" => sub {
    my $expected = 'actuator deco is chosen';
    my %abch = (
                 $actuator => sub { "actuator $actuator is chosen" },
                 'deco'    => sub { $expected },
               );
    my $proc = _get_note_rest_bar_actuators( \%abch, $sym, undef );
    my $got = $proc->();

    is( $got, $expected,
        '_get_note_rest_bar_actuators returns a subroutine belonging to actuator deco' );
  };

  subtest "when the handler has the actuators $actuator, deco and $actuator" . '::deco' => sub {
    my $expected = "actuator $actuator" . '::deco is chosen';
    my %abch = (
                 $actuator            => sub { "actuator $actuator is chosen" },
                 'deco'               => sub { 'actuator deco is chosen' },
                 $actuator . '::deco' => sub { $expected },
               );
    my $proc = _get_note_rest_bar_actuators( \%abch, $sym, undef );
    my $got = $proc->();

    is( $got, $expected,
        "_get_note_rest_bar_actuators returns a subroutine belonging to actuator $actuator" . '::deco' );
  };

  if ( $type == Music::Abc::DT::ABC_T_BAR ) {
    subtest "when the handler has the actuators $actuator, deco, $actuator" . "::deco and $bar->{abc}" . '::deco' => sub {
      my $expected = "actuator $bar->{abc}" . '::deco is chosen';
      my %abch = (
                   $actuator              => sub { "actuator $actuator is chosen" },
                   $bar->{abc}            => sub { "actuator $bar->{abc} is chosen" },
                   'deco'                 => sub { 'actuator deco is chosen' },
                   $actuator . '::deco'   => sub { "actuator $actuator" . '::deco is chosen' },
                   $bar->{abc} . '::deco' => sub { $expected },
                 );
      my $proc = _get_note_rest_bar_actuators( \%abch, $sym, undef );
      my $got = $proc->();

      is( $got, $expected,
          "_get_note_rest_bar_actuators returns a subroutine belonging to actuator $bar->{abc}" . '::deco' );
    };
  }

  return;
}

sub _test_actual_decoration_actuator {
  my ( $type, $actuator, $sym, $deco, $bar ) = @_;

  subtest "when the handler has the actuators $actuator, deco, $actuator" . "::deco and !$deco!" => sub {
    my $expected = "actuator !$deco! is chosen";
    my %abch = (
          $actuator            => sub { "actuator $actuator is chosen" },
          'deco'               => sub { 'actuator deco is chosen' },
          $actuator . '::deco' => sub { "actuator $actuator" . '::deco is chosen' },
          "!$deco!"            => sub { $expected },
    );
    my $proc = _get_note_rest_bar_actuators( \%abch, $sym, undef );
    my $got = $proc->();

    is( $got, $expected,
        "_get_note_rest_bar_actuators returns a subroutine belonging to actuator !$deco!" );
  };

  subtest "when the handler has the actuators $actuator, deco, $actuator" . "::deco, !$deco! and $actuator" . "::!$deco!" => sub {
    my $expected = "actuator $actuator" . "::!$deco! is chosen";
    my %abch = (
          $actuator               => sub { "actuator $actuator is chosen" },
          'deco'                  => sub { 'actuator deco is chosen' },
          $actuator . '::deco'    => sub { "actuator $actuator" . '::deco is chosen' },
          "!$deco!"               => sub { "actuator !$deco! is chosen" },
          $actuator . "::!$deco!" => sub { $expected },
    );
    my $proc = _get_note_rest_bar_actuators( \%abch, $sym, undef );
    my $got = $proc->();

    is( $got, $expected,
        "_get_note_rest_bar_actuators returns a subroutine belonging to actuator $actuator" . "::!$deco!" );
  };

  if ( $type == Music::Abc::DT::ABC_T_BAR ) {
    subtest "when the handler has the actuators $actuator, deco, $actuator"
      . "::deco,  $bar->{abc}"
      . "::deco, !$deco!, $actuator"
      . "::!$deco! and $bar->{abc}"
      . '::!deco!' => sub {
      my $expected = "actuator $bar->{abc}" . "::!$deco! is chosen";
      my %abch = (
            $actuator                 => sub { "actuator $actuator is chosen" },
            $bar->{abc}               => sub { "actuator $bar->{abc} is chosen" },
            'deco'                    => sub { 'actuator deco is chosen' },
            $actuator . '::deco'      => sub { "actuator $actuator" . '::deco is chosen' },
            $bar->{abc} . '::deco'    => sub { "actuator $bar->{abc}" . '::deco is chosen' },
            "!$deco!"                 => sub { "actuator !$deco! is chosen" },
            $actuator . "::!$deco!"   => sub { "actuator $actuator" . "::!$deco! is chosen" },
            $bar->{abc} . "::!$deco!" => sub { $expected },
      );
      my $proc = _get_note_rest_bar_actuators( \%abch, $sym, undef );
      my $got = $proc->();

      is( $got, $expected,
          "_get_note_rest_bar_actuators returns a subroutine belonging to actuator $bar->{abc}" . "::!$deco!" );
    };
  }

  return;
}
