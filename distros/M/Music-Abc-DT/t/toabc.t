#!/usr/bin/perl
use Music::Abc::DT
  qw( _broken_rhythm _head_par _length_header_dump _meter_calc _pscom_to_abc _slur_dump
      _tuplet_to_abc _vover_to_abc $c_voice $brhythm @blen );
use Test::More tests => 9;


######################## _bar_to_abc ########################

TODO: {
  local $TODO = "not yet tested";
  subtest '_bar_to_abc' => sub {
  };
}


######################## _broken_rhythm ########################

subtest '_broken_rhythm' => sub {
  plan tests => 7;

  _test_broken_rhythm( -3, "<<<", [ 12, 24, 48 ], "* 8" );
  _test_broken_rhythm( -2, "<<",  [ 12, 24, 48 ], "* 4" );
  _test_broken_rhythm( -1, "<",   [ 12, 24, 48 ], "* 2" );

  subtest '$brhythm == 0 (no dots)' => sub {
    $brhythm = 0;

    my @lens = ( 12, 24, 48, 144 );    #
    plan tests => scalar @lens;
    foreach $len (@lens) {
      my $result = _broken_rhythm($len);
      is( $result, $len, "_broken_rhythm (no dots)" );
    }
  };

  _test_broken_rhythm( 1, ">", [ 144, 288, 576 ], "* 2 / 3" );    # c/4>d/4, c/2>d/2 , c>d
  _test_broken_rhythm( 2, ">>", [ 168, 336, 672 ], "* 4 / 7" );   # c/4>>d/4, c/2>>d/2 , c>>d
  _test_broken_rhythm( 3, ">>>", [ 180, 360, 720 ], "* 8 / 15" ); # c/4>>>d/4, c/2>>>d/2 , c>>>d
};


######################## _head_par ########################

subtest '_head_par' => sub {
  plan tests => 3;

  subtest 'returns down' => sub {
    my $v         = -1;
    my $direction = _head_par($v);
    is( $direction, "down", "_head_par returns down" );
  };

  subtest 'returns up' => sub {
    my $v         = 1;
    my $direction = _head_par($v);
    is( $direction, "up", "_head_par returns up" );
  };

  subtest 'returns auto' => sub {
    my $v         = 2;
    my $direction = _head_par($v);
    is( $direction, "auto", "_head_par returns auto" );
  };
};


######################## _length_header_dump ########################

subtest "_length_header_dump" => sub {
  plan tests => 2;

  my $abc           = q{};
  my $bl            = 384;
  my @blen_expected = (0) x Music::Abc::DT::MAXVOICE;

  $c_voice = 0;
  @blen    = (0) x Music::Abc::DT::MAXVOICE;

  subtest "state == ABC_S_GLOBAL || state == ABC_S_HEAD" => sub {
    $blen_expected[$_] = $bl foreach ( reverse 0..Music::Abc::DT::MAXVOICE-1 );
    my $sym = { state => 0, info => { base_length => $bl } };

    my $length = _length_header_dump( $abc, $sym );
    my $length_expected = "L:1/" . ( Music::Abc::DT::BASE_LEN / $blen[$c_voice] );

    is_deeply( \@blen, \@blen_expected, "_length_header_dump assigns new values to \@blen" );
    is($length, $length_expected, "_length_header_dump returns the base length in a fraction");
  };

  subtest "state != ABC_S_GLOBAL && state != ABC_S_HEAD" => sub {
    $blen_expected[$c_voice] = $bl;
    my $sym = { state => 3, info => { base_length => $bl } };

    my $length = _length_header_dump( $abc, $sym );
    my $length_expected = "L:1/" . ( Music::Abc::DT::BASE_LEN / $blen[$c_voice] );

    is_deeply( \@blen, \@blen_expected, "_length_header_dump assigns a new value to \@blen to the current voice" );
    is($length, $length_expected, "_length_header_dump returns the base length in a fraction");
  };
};

######################## _meter_calc ########################

subtest "_meter_calc" => sub {
  plan tests => 2;

  subtest "doesn't have meter elements (nmeter==0)" => sub {
    my $sym = { info => { nmeter => 0 } };
    is( _meter_calc($sym), Music::Abc::DT::NONE, "_meter_calc returns NONE" );
  };

  subtest "has meter elements (nmeter!=0)" => sub {

    subtest "has only top element" => sub {
      my $sym =
        { info => { nmeter => 1, meter => [ { top => "C", bot => q{} } ] } };
      is( _meter_calc($sym), "C", "_meter_calc returns only the top" );
    };

    subtest "has top and bottom elements" => sub {
      my $sym =
        { info => { nmeter => 1, meter => [ { top => "3", bot => "4" } ] } };
      is( _meter_calc($sym), "3/4", "_meter_calc returns top and bottom" );
    };

    subtest "has more than one element" => sub {
      my $sym = {
        info => {
          nmeter => 2,
          meter => [ { top => "7", bot => "8" }, { top => "3+2+2", bot => q{} } ]
        }
      };
      is( _meter_calc($sym), "7/8 3+2+2",
          "_meter_calc returns two elements separated with a whitespace" );
    };
  };
};


######################## _pscom_to_abc ########################

subtest "_pscom_to_abc" => sub {
  plan tests => 2;
  my $abc = q{};

  subtest "ps comment text is empty" => sub {
    my $sym = { text => q{} };
    my ( $pscom, $nl ) = _pscom_to_abc( $abc, $sym, q{} );
    is( $pscom, $abc, "_pscom_to_abc returns the same abc passed as argument" );
    is( $nl, 1, "_pscom_to_abc returns new line = 1" );
  };
  
  subtest "ps comment text isn't empty" => sub {
    my $pc = "%%MIDI program 1";
    my $sym = { text => $pc };

    subtest "\$c is \\n" => sub {
      my $c = "\n";
      my ($pscom, $nl) = _pscom_to_abc ($abc, $sym, $c);
      is($pscom, $abc.$pc, "_pscom_to_abc returns the ps comment appended");
      is( $nl, 1, "_pscom_to_abc returns new line = 1" );
    };

    subtest "\$c isn't \\n" => sub {
      my $c = q{};
      my ($pscom, $nl) = _pscom_to_abc ($abc, $sym, $c);
      is($pscom, $abc."\\\n".$pc, "_pscom_to_abc returns the ps comment appended to \\\n");
      is( $nl, 1, "_pscom_to_abc returns new line = 1" );
    };
  };
};


######################## _slur_dump ########################

subtest '_slur_dump' => sub {
  plan tests => 7;
  my $abc = q{};

  _test_slur_dump( $abc, 1,  "('" );
  _test_slur_dump( $abc, 2,  "(," );
  _test_slur_dump( $abc, 3,  "(" );
  _test_slur_dump( $abc, 5,  ".('" );
  _test_slur_dump( $abc, 27, "((" );

TODO: {
  local $TODO = "tclabc.c's or abcparse.c's bug";
  subtest 'slur start: 31' => sub {
    my $sl = 31;
    my $slur = _slur_dump( $abc, $sl );
    is( $slur, "(.(", "_tuplet_to_abc returns (.(" );
    isnt( $slur, ".((", "_tuplet_to_abc doesn't return .((" );
  };

  subtest 'slur start: 59' => sub {
    my $sl = 59;
    my $slur = _slur_dump( $abc, $sl );
    is( $slur, ".((", "_tuplet_to_abc returns .((" );
    isnt( $slur, "(.(", "_tuplet_to_abc doesn't return (.(" );
  };
}
};


######################## _tuplet_to_abc ########################

subtest '_tuplet_to_abc' => sub {
  plan tests => 4;
  my $abc = q{};

  _test_tuplet_to_abc( $abc, 2, 3, 2, "(2" );
  _test_tuplet_to_abc( $abc, 3, 2, 3, "(3" );
  _test_tuplet_to_abc( $abc, 3, 2, 2, "(3:2:2" );
  _test_tuplet_to_abc( $abc, 6, 2, 6, "(6:2:6" );
};


######################## _vover_to_abc ########################

subtest '_vover_to_abc' => sub {
  plan tests => 3;
  my $abc = q{};

  _test_vover_to_abc( $abc, "&", Music::Abc::DT::V_OVER_V);
  _test_vover_to_abc( $abc, "(&", Music::Abc::DT::V_OVER_S);
  _test_vover_to_abc( $abc, "&)", Music::Abc::DT::V_OVER_E);
};

done_testing;

######################## test's subroutines ########################

# --
sub _test_broken_rhythm {
  my ( $br, $abc, $lens, $expr ) = @_;

  subtest "\$brhythm == $br ($abc)" => sub {
    $brhythm = $br;

    subtest '$len % 24 == 0' => sub {
      my @lens = @$lens;
      plan tests => scalar @lens;
      foreach $len (@lens) {
        my $result = _broken_rhythm($len);
        is( $result, eval( $len . $expr ), "_broken_rhythm ($abc)" );
      }
    };

  TODO: {
      local $TODO = "don't know an example whose \$len % 24 != 0";
      subtest '$len % 24 != 0' => sub {
        my $len    = 12;
        my $result = _broken_rhythm($len);
        is( $result,
            ( ( eval( $len . $expr ) ) + 12 ) / 24 * 24,
            "_broken_rhythm ($abc)" );
      };
    }
  };
}

# --
sub _test_slur_dump {
  my ( $abc, $sl, $slur_expected ) = @_;

  subtest "slur start: $sl" => sub {
    my $slur = _slur_dump( $abc, $sl );
    is( $slur, $slur_expected, "_slur_dump returns $slur_expected" );
  };
}

# --
sub _test_tuplet_to_abc {
  my ( $abc, $pp, $qp, $rp, $tuplet_expected ) = @_;

  subtest "tuplet: ($pp:$qp:$rp" => sub {
    my $sym = { info => { p_plet => $pp, q_plet => $qp, r_plet => $rp } };
    my $tuplet = _tuplet_to_abc( $abc, $sym );
    is( $tuplet, $tuplet_expected, "_tuplet_to_abc returns $tuplet_expected" );
  };
}

# --
sub _test_vover_to_abc {
  my ( $abc, $vover_expected, $type ) = @_;
  
  subtest "voice over: $vover_expected" => sub {
    my $sym = { info => { type => $type } };
    my $vover = _vover_to_abc( $abc, $sym );
    is( $vover, $vover_expected, "_vover_to_abc returns $vover_expected" );
  };
}
