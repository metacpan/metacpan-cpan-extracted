#!/usr/bin/perl
use Music::Abc::DT
  qw( _diatonic_interval _get_alter _get_chromatic_info _get_generic_info _get_ps
  _get_specifier_from_generic_chromatic _interval_from_generic_and_chromatic _notes_to_chromatic
  _notes_to_generic _notes_to_interval _convert_staff_distance_to_interval );
use Test::More tests => 11;
# use Test::Exception;
use strict;
use warnings;

subtest '_diatonic_interval' => sub {
  my @expected = (
                   {
                     name      => 'P4',
                     specifier => $Music::Abc::DT::PERFECT,
                     generic   => 4
                   },
                   {
                     name      => 'm3',
                     specifier => $Music::Abc::DT::MIN,
                     generic   => -3
                   },
                 );

  my $n_tests = ( scalar @expected );
  plan tests => $n_tests;

  for my $ix (0..$n_tests-1) {
    my $got = _diatonic_interval($expected[$ix]->{specifier}, $expected[$ix]->{generic});

    is_deeply( $got, $expected[$ix], '_diatonic_interval returns the expected structure' );
  }
};

subtest '_get_alter' => sub {
  my @accs = ( 0 .. 5 );
  my $n_tests = ( scalar @accs );

  plan tests => $n_tests;

  my @expected = ( 0, 1, 0, -1, 2, -2 );

  for my $ix (0..$n_tests-1) {
    is( _get_alter( $accs[$ix] ),
        $expected[$ix], "_get_alter returns the expected output with acc=$accs[$ix]" );
  }
};

subtest '_get_chromatic_info' => sub {
  plan tests => 3;

  my %value = (
                -7 => { d => $Music::Abc::DT::DESCENDING, mod => 5 },
                0  => { d => $Music::Abc::DT::OBLIQUE,    mod => 0 },
                13 => { d => $Music::Abc::DT::ASCENDING,  mod => 1 },
              );

  for my $v ( keys %value ) {
    my $expected_struct = {
                            semitones  => $v,
                            directed   => $v,
                            undirected => abs $v,
                            direction  => $value{$v}{d},
                            mod12      => $value{$v}{mod},
                          };

    my $got_struct = _get_chromatic_info($v);

    is_deeply( $got_struct, $expected_struct,
           "_get_chromatic_info returns the expected structure with c_int=$v" );
  }
};

subtest '_get_generic_info' => sub {
  plan tests => 3;

  my %value = (
                -8 => { su   => 1,
                        ssu  => 8,
                        uo   => 1,
                        d    => $Music::Abc::DT::DESCENDING,
                        sd   => 1,
                        ssd  => -8,
                        o    => -1,
                        p    => 1,
                        modi => 1,
                        mod  => 1,
                      },
                1 => { su  => 1,
                       ssu => 1,
                       uo  => 0,
                       d   => $Music::Abc::DT::OBLIQUE,
                       sd  => 1,
                       ssd => 1,
                       o   => 0,
                       p   => 1,
                       modi => 8,
                       mod  => 1,
                     },
                6 => { su  => 6,
                       ssu => 6,
                       uo  => 0,
                       d   => $Music::Abc::DT::ASCENDING,
                       sd  => 6,
                       ssd => 6,
                       o   => 0,
                       p   => 0,
                       modi => 3,
                       mod  => 6,
                     }
              );

  for my $v ( keys %value ) {
    my $expected_struct = {
                            directed             => $v,
                            undirected           => abs $v,
                            simpleUndirected     => $value{$v}{su},
                            semiSimpleUndirected => $value{$v}{ssu},
                            undirectedOctaves    => $value{$v}{uo},
                            direction            => $value{$v}{d},
                            simpleDirected       => $value{$v}{sd},
                            semiSimpleDirected   => $value{$v}{ssd},
                            octaves              => $value{$v}{o},
                            perfectable          => $value{$v}{p},
                            mod7inversion        => $value{$v}{modi},
                            mod7                 => $value{$v}{mod},
                          };

    my $got_struct = _get_generic_info($v);

    is_deeply( $got_struct, $expected_struct,
           "_get_generic_info returns the expected structure with g_int=$v" );
  }

#TODO don't know how to test a dying subroutine; didn't understand Test::Exception
  # my $v = 0;
  # my $got = _get_generic_info($v);

  # is($got, 'yay', "_get_generic_info dies with c_int=$v" );

  # dies_ok( is(1,1), "_get_generic_info dies with c_int=$v" );
};

subtest '_get_ps' => sub {
  my @note_refs = ( 
                    { pits => 16, accs => 0 },  # C
                    { pits => 35, accs => 3 },   # _a'
                  );
  my @expected = ( 60, 92 );

  my $n_tests = scalar @note_refs;
  plan tests => $n_tests;

  for my $ix (0..$n_tests-1) {
    my $got = _get_ps($note_refs[$ix]);

    is( $got, $expected[$ix],
        "_get_ps returns the expected result with pits=$note_refs[$ix]->{pits}"
          . " and accs=$note_refs[$ix]->{accs}" );
  }
};

subtest '_get_specifier_from_generic_chromatic' => sub {
  plan tests => 2;

  subtest 'when the interval is perfectable' => sub {
    my @expected = (
                     [4, 1, $Music::Abc::DT::QUADDIM],
                     [4, 2, $Music::Abc::DT::TRPDIM],
                     [4, 3, $Music::Abc::DT::DBLDIM],
                     [4, 4, $Music::Abc::DT::DIMINISHED],
                     [4, 5, $Music::Abc::DT::PERFECT],
                     [4, 6, $Music::Abc::DT::AUGMENTED],
                     [4, 7, $Music::Abc::DT::DBLAUG],
                     [4, 8, $Music::Abc::DT::TRPAUG],
                     [4, 9, $Music::Abc::DT::QUADAUG]
                   );

    my $n_tests = scalar @expected;
    plan tests => $n_tests;

    for my $ix (0..$n_tests-1) {
      my $got = _get_specifier_from_generic_chromatic($expected[$ix]->[0], $expected[$ix]->[1]);

      is( $got, $expected[$ix]->[2],
          "_get_specifier_from_generic_chromatic returns the expected result with gInt=$expected[$ix]->[0]"
            . " and cInt=$expected[$ix]->[1]" );
    }
  };

  subtest 'when the interval isn\'t perfectable' => sub {
    my @expected = (
                     [3, -1, $Music::Abc::DT::QUADDIM],
                     [3, 0 , $Music::Abc::DT::TRPDIM],
                     [3, 1 , $Music::Abc::DT::DBLDIM],
                     [3, 2 , $Music::Abc::DT::DIMINISHED],
                     [3, 3 , $Music::Abc::DT::MIN],
                     [3, 4 , $Music::Abc::DT::MAJ],
                     [3, 5 , $Music::Abc::DT::AUGMENTED],
                     [3, 6 , $Music::Abc::DT::DBLAUG],
                     [3, 7 , $Music::Abc::DT::TRPAUG],
                     [3, 8 , $Music::Abc::DT::QUADAUG]
                   );

    my $n_tests = scalar @expected;
    plan tests => $n_tests;

    for my $ix (0..$n_tests-1) {
      my $got = _get_specifier_from_generic_chromatic($expected[$ix]->[0], $expected[$ix]->[1]);

      is( $got, $expected[$ix]->[2],
          "_get_specifier_from_generic_chromatic returns the expected result with gInt=$expected[$ix]->[0]"
            . " and cInt=$expected[$ix]->[1]" );
    }
  };
};

subtest '_interval_from_generic_and_chromatic' => sub {
  my @expected = (
                   { generic   => -3,
                     chromatic => -2,
                     d_int     => {
                                name      => 'd3',
                                specifier => $Music::Abc::DT::DIMINISHED,
                                generic   => -3
                              }
                   },
                   { generic   => 2,
                     chromatic => 1,
                     d_int     => {
                                name      => 'm2',
                                specifier => $Music::Abc::DT::MIN,
                                generic   => 2
                              }
                   },
                   { generic   => 6,
                     chromatic => 9,
                     d_int     => {
                                name      => 'M6',
                                specifier => $Music::Abc::DT::MAJ,
                                generic   => 6
                              }
                   },
                   { generic   => 4,
                     chromatic => 5,
                     d_int     => {
                                name      => 'P4',
                                specifier => $Music::Abc::DT::PERFECT,
                                generic   => 4
                              }
                   },
                   { generic   => 5,
                     chromatic => 8,
                     d_int     => {
                                name      => 'A5',
                                specifier => $Music::Abc::DT::AUGMENTED,
                                generic   => 5
                              }
                   },
                 );

  my $n_tests = scalar @expected;
  plan tests => $n_tests * 2;

  for my $ix (0..$n_tests-1) {
    my ( $d_int_got, $c_int_got ) = _interval_from_generic_and_chromatic($expected[$ix]->{generic}, $expected[$ix]->{chromatic});

    is_deeply(
              $d_int_got,
              $expected[$ix]->{d_int},
              '_interval_from_generic_and_chromatic returns the expected diatonic interval'
             );

    is(
        $c_int_got,
        $expected[$ix]->{chromatic},
        '_interval_from_generic_and_chromatic returns the expected result chromatic interval'
      );
  }
};

subtest '_notes_to_chromatic' => sub {
  plan tests => 1;

  my $note1_ref = { pits => 16, accs => 0 };  # 'C';  ps: 60
  my $note2_ref = { pits => 27, accs => 3 };  # '_g'; ps: 78
  my $expected = 18;

  my $got = _notes_to_chromatic( $note1_ref, $note2_ref );

    is( $got, $expected, "_notes_to_chromatic returns the expected result" );
};

subtest '_notes_to_generic' => sub {
  plan tests => 2;

  my $note1_ref = { pits => 16, accs => 0 };  # 'C';  ps: 60
  my $note2_ref = { pits => 27, accs => 3 };  # '_g'; ps: 78
  my $expected = 12;

  my $got = _notes_to_generic( $note1_ref, $note2_ref );
  is( $got, $expected, "_notes_to_generic returns the expected result" );

  my $note3_ref = { pits => 14, accs => 0 };  # 'A,'; ps: 57
  $expected = -3;

  $got = _notes_to_generic( $note1_ref, $note3_ref );
  is( $got, $expected, "_notes_to_generic returns the expected result" );
};

subtest '_notes_to_interval' => sub {
  plan tests => 2;

  my $note1_ref = { pits => 16, accs => 0 };  # 'C'
  my @note2_refs = (
                     { pits => 15, accs => 0 },  # B,
                     { pits => 18, accs => 5 },  # __E
                     { pits => 19, accs => 0 },  # F
                     { pits => 20, accs => 1 },  # ^G
                     { pits => 42, accs => 0 },  # a''
                   );

  subtest 'when notes2_ref is not null' => sub {
    my @expected = (
                     { d_int => { name      => 'm2',
                                  specifier => $Music::Abc::DT::MIN,
                                  generic   => -2
                                },
                       chromatic => -1
                     },
                     { d_int => { name      => 'd3',
                                  specifier => $Music::Abc::DT::DIMINISHED,
                                  generic   => 3
                                },
                       chromatic => 2
                     },
                     { d_int => { name      => 'P4',
                                  specifier => $Music::Abc::DT::PERFECT,
                                  generic   => 4
                                },
                       chromatic => 5
                     },
                     { d_int => { name      => 'A5',
                                  specifier => $Music::Abc::DT::AUGMENTED,
                                  generic   => 5
                                },
                       chromatic => 8
                     },
                     { d_int => { name      => 'M27',
                                  specifier => $Music::Abc::DT::MAJ,
                                  generic   => 27
                                },
                       chromatic => 45
                     },
                   );

    my $n_tests = scalar @expected;
    plan tests => $n_tests * 2;

    for my $ix (0..$n_tests-1) {
      my ( $d_int_got, $c_int_got ) = _notes_to_interval( $note1_ref, $note2_refs[$ix] );

        is_deeply(
            $d_int_got,
            $expected[$ix]->{d_int},
            '_notes_to_interval returns the expected diatonic interval'
          );

        is(
            $c_int_got,
            $expected[$ix]->{chromatic},
            '_notes_to_interval returns the expected chromatic interval'
          );
    }
  };

  subtest 'when notes2_ref is null' => sub {
    my @expected = (
                     { d_int => { name      => 'P1',
                                  specifier => $Music::Abc::DT::PERFECT,
                                  generic   => 1
                                },
                       chromatic => 0
                     }
                   );

    my $n_tests = scalar @expected;
    plan tests => $n_tests * 2;

    for my $ix (0..$n_tests-1) {
      my ( $d_int_got, $c_int_got ) = _notes_to_interval( $note1_ref, undef );

        is_deeply(
            $d_int_got,
            $expected[$ix]->{d_int},
            '_notes_to_interval returns the expected diatonic interval'
          );

        is(
            $c_int_got,
            $expected[$ix]->{chromatic},
            '_notes_to_interval returns the expected chromatic interval'
          );
    }
  };
};

subtest '_convert_staff_distance_to_interval' => sub {
  my @expected = (
                   [ 0,  1  ],
                   [ 3,  4  ],
                   [ -2, -3 ],
                 );

  my $n_tests = scalar @expected;
  plan tests => $n_tests;

  for my $ix (0..$n_tests-1) {
    my $got = _convert_staff_distance_to_interval( $expected[$ix]->[0] );

    is(
        $got,
        $expected[$ix]->[1],
        "_convert_staff_distance_to_interval returns the expected result with staff_dist=$expected[$ix]->[0]"
      );

  }
};
