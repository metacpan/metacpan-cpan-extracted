#!/usr/bin/perl
use Music::Abc::DT
  qw( _get_chord_notes get_chord_step get_fifth get_third is_major_triad root );
use Test::More tests => 6;
use strict;
use warnings;

my ( $c4, $e, $g, $b_flat, $c5 ) = (
                               { pits => 16, accs => 0 },
                               { pits => 18, accs => 0 },
                               { pits => 20, accs => 0 },
                               { pits => 22, accs => 3 },
                               { pits => 23, accs => 0 },
                             );

my $no_third_chord = {
                       info => {
                                 nhd  => 2,
                                 pits => [ 16, 19, 22 ],    # [CFB]
                                 accs => [ 0, 0, 0 ]
                               }
                     };

my $no_fifth_chord = {
                       info => {
                                 nhd  => 2,
                                 pits => [ 18, 19, 20 ],    # [EFG]
                                 accs => [ 0, 0, 0 ]
                               }
                     };

my $jazz_sus_chord = {
                       info => {
                                 nhd  => 4,
                                 pits => [ 16, 20, 22, 24, 26 ],    # [CG_Bdf] Jazz suspended chord
                                 accs => [ 0, 0, 3, 0, 0  ]
                               }
                     };

# major chords
my $cmaj = {
            info => {
                      nhd  => 2,
                      pits => [ 16, 18, 20 ],    # [CEG]
                      accs => [ 0, 0, 0 ]
                    }
          };

my $cmaj6 = {
              info => {
                        nhd  => 2,
                        pits => [ 11, 13, 16 ],    # [E,G,C] CMaj (1st inversion) (3rd in bass)
                        accs => [ 0, 0, 0 ]
                      }
            };

my $cmaj64 = {
              info => {
                        nhd  => 2,
                        pits => [ 13, 16, 18 ] ,    # [G,CE] CMaj (2nd inversion) (5th in bass)
                        accs => [ 0, 0, 0 ]
                      }
             },
          
# seventh chords
my $cmaj7 = {
              info => {
                        nhd  => 2,
                        pits => [ 16, 18, 20, 22 ],    # [CEG_B] CMaj7 (Root in bass)
                        accs => [ 0, 0, 0, 3 ]
                      }
            };

my $cmaj65 = {
               info => {
                         nhd  => 3,
                         pits => [ 18, 20, 22, 23 ],    # [EG_Bc] CMaj (1st inversion) (3rd in bass)
                         accs => [ 0, 0, 3, 0 ]
                       }
             };


subtest '_get_chord_notes' => sub {
  plan tests => 1;

  my $expected_struct = [ $c4, $e, $g ];

  my @got_struct = _get_chord_notes($cmaj);

  is_deeply( \@got_struct, $expected_struct,
             '_get_chord_notes returns the expected structure' );
};

subtest 'get_chord_step' => sub {
  plan tests => 2;

  subtest 'test_root is undefined' => sub {
    my @expected = (
                     { step => 3, note => $e },
                     { step => 5, note => $g },
                     { step => 6, note => undef },
                     { step => 7, note => $b_flat },
                   );

    my $n_tests = scalar @expected;
    plan tests => $n_tests;

    for my $ix (0..$n_tests-1) {
      my $got_note = get_chord_step( $cmaj65, $expected[$ix]->{step} );

      is_deeply( $got_note, $expected[$ix]->{note},
                 "get_chord_step returns the expected note with step $expected[$ix]->{step}" );
    }
  };

  subtest 'test_root is defined' => sub {
    my @expected = (
                     { step => 3, test_root => $e, note => $g },
                     { step => 5, test_root => $e, note => $b_flat },
                     { step => 6, test_root => $e, note => $c5 },
                     { step => 7, test_root => $e, note => undef },
                   );

    my $n_tests = scalar @expected;
    plan tests => $n_tests;

    for my $ix (0..$n_tests-1) {
      my $got_note = get_chord_step( $cmaj65, $expected[$ix]->{step}, $expected[$ix]->{test_root} );

      is_deeply(
                 $got_note,
                 $expected[$ix]->{note},
                 "get_chord_step returns the expected note with "
                   . "step:$expected[$ix]->{step} and "
                   . "test_root:$expected[$ix]->{test_root}"
               );
    }
  };
};

subtest 'get_fifth' => sub {
  plan tests => 2;

  my $got = get_fifth($cmaj65);
  is_deeply( $got, $g, 'get_fifth returns the expected fifth' );

  $got = get_fifth($no_fifth_chord);
  is_deeply( $got, undef, 'get_fifth returns undef' );
};

# subtest '_get_generic' => sub {
#   plan tests => 1;
# 
#   my $d_int = 'P4';
# 
#   my $expected = 4;
# 
#   my $got = _get_generic($d_int);
# 
#   is( $got, $expected, '_get_generic returns the expected output' );
# };

subtest 'get_third' => sub {
  plan tests => 2;

  my $got = get_third($cmaj65);
  is_deeply( $got, $e, 'get_third returns the expected third' );

  $got = get_third($no_third_chord);
  is_deeply( $got, undef, 'get_third returns undef' );
};


subtest 'is_major_triad' => sub {
  plan tests => 4;

  my $got = is_major_triad($cmaj);
  is( $got, 1, 'is_major_triad returns true when a major triad is passed' );

  $got = is_major_triad($no_third_chord);
  is( $got, 0, 'is_major_triad returns false when a chord with no third is passed' );

  $got = is_major_triad($no_fifth_chord);
  is( $got, 0, 'is_major_triad returns false when a chord with no fifth is passed' );

  $got = is_major_triad($jazz_sus_chord);
  is(
      $got,
      0,
      'is_major_triad returns false '
        . 'when a chord with notes other than '
        . 'the root, major 3rd and perfect fifth is passed'
    );
};

subtest 'root' => sub {
  plan tests => 2;

  subtest 'a root is found' => sub {
    plan tests => 2;

    subtest 'when the chord has only one note' => sub {
      plan tests => 1;

      my $sym = { info => { nhd  => 0,
                            pits => [16],
                            accs => [0]
                          }
                };

      my $expected = $c4;
      my $got = root($sym);
      is_deeply( $got, $expected, 'root returns the expected structure' );
    };

    subtest 'when the chord has more than one note' => sub {
      my @syms = ( $cmaj7, $cmaj6, $cmaj64 );

      my $n_tests = scalar @syms;
      plan tests => $n_tests;

      my $expected = $c4;

      for my $ix (0..$n_tests-1) {
        my $got = root($syms[$ix]);

        is_deeply( $got, $expected, "root returns the expected structure in test no. $ix" );
      }
    };
  };

  subtest 'a root isn\'t found' => sub {
    plan skip_all => "don't know how to test a dying subroutine; didn't understand Test::Exception";
    #TODO don't know how to test a dying subroutine; didn't understand Test::Exception
  };
};
