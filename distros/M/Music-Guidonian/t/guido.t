#!perl
#
# guido.t - tests for the main interface of Music::Guidonian and the
# various utility functions therein

use 5.24.0;
use Music::Guidonian qw(intervalize_scale_nums);
use Music::Scales 'get_scale_nums';
use Test2::V0;

plan(52);

# key2pitch is constructed from a set of inputs
my $mg = Music::Guidonian->new(
    key_set => {
        intervals => [ 2, 2, 1, 2, 2, 2, 1 ],
        keys      => [qw(a e i o u)],
        min       => 48,
        max       => 72
    }
);
# instead of a hand we must make do with a table in a text file that
# hopefully shows what that "Guidonian Hand" is up to
#
#    C  D  E  F  G  A  B  C  D  E  F  G  A  B  C
#   48 50 52 53 55 57 59 60 62 64 65 67 69 71 72
#    a  e  i  o  u  a  e  i  o  u  a  e  i  o  u
is( $mg->key2pitch,
    {   a => [ 48, 57, 65 ],
        e => [ 50, 59, 67 ],
        i => [ 52, 60, 69 ],
        o => [ 53, 62, 71 ],
        u => [ 55, 64, 72 ],
    }
);

#my @text   = qw(Lo rem ip sum do lor sit);
#my @vowels = map { m/([aeiou])/; $1 } @text;
#my $x   = $mg->iterator(\@vowels);
#use Data::Dumper::Concise::Aligned; diag DumperA P => $x->();

# key2pitch instead supplied by caller
my $roundtrip = { i => [ 30, 31 ], a => [ 32, 33 ], f => [34] };
$mg = Music::Guidonian->new( key2pitch => $roundtrip );
is( $mg->key2pitch, $roundtrip );

my $iter = $mg->iterator( [qw(i 35 a)] );
for ( 1 .. 4 ) {
    my $phrase = $iter->();
    is( $phrase->[1], 35 );
    # these are randomized due to the shuffle on the starting pitches
    ok(       ( $phrase->[0] == 30 or $phrase->[0] == 31 )
          and ( $phrase->[2] == 32 or $phrase->[2] == 33 ) );
}
is( scalar $iter->(), undef );    # out of iterations (changed from 0.02)

# for test coverage
$iter = $mg->iterator( [qw(i f)] );
my $phrase = $iter->();
is( $phrase->[1], 34 );

$iter   = $mg->iterator( [qw(34 i a)] );
$phrase = $iter->();
is( $phrase->[0], 34 );

# custom renew - replace the choices with something else
my $foo;
$iter = $mg->iterator(
    [qw(i a)],
    renew => sub { $_[0] = [ 42, 43, 44 ]; $foo = $_[3] },
    stash => 'bar'
);
$phrase = $iter->();
is( $phrase->[0], 42 );
is( $foo,         'bar' );

# undef means no renew code is run on update
$iter = $mg->iterator( [qw(i a i a)], renew => undef );
my @phrasen;
while ( my $phrase = $iter->() ) { push @phrasen, $phrase }
is( \@phrasen,
    [   [ 30, 32, 30, 32 ],
        [ 30, 32, 30, 33 ],
        [ 30, 32, 31, 32 ],
        [ 30, 32, 31, 33 ],
        [ 30, 33, 30, 32 ],
        [ 30, 33, 30, 33 ],
        [ 30, 33, 31, 32 ],
        [ 30, 33, 31, 33 ],
        [ 31, 32, 30, 32 ],
        [ 31, 32, 30, 33 ],
        [ 31, 32, 31, 32 ],
        [ 31, 32, 31, 33 ],
        [ 31, 33, 30, 32 ],
        [ 31, 33, 30, 33 ],
        [ 31, 33, 31, 32 ],
        [ 31, 33, 31, 33 ],
    ]
);

# output pitch names in Lilypond form
$mg = Music::Guidonian->new(
    key2pitch  => { c => [ 60, 72 ], d => [ 74, 62 ] },
    pitchstyle => 'Music::PitchNum::Dutch'
);
$iter = $mg->iterator( [qw(c d)], renew => undef );
is( $iter->(), [qw(c' d'')] );

########################################################################
#
# FUNCTION

# intervalize_scale_nums
{
    my $intervals = intervalize_scale_nums( [ get_scale_nums('major') ] );
    #                  C D E F G A B C - Major
    is( $intervals, [qw(2 2 1 2 2 2 1)] );
    $intervals = intervalize_scale_nums( [ get_scale_nums('minor') ], 12 );
    #                  A B C D E F G A - Minor
    is( $intervals, [qw(2 1 2 2 1 2 2)] );
}

########################################################################
#
# INVALIDITY
#
# NOTE that it is still possible for bad values to be accepted from
# inside the 'keys' or 'sequence' provided, but these should prevent
# obviously invalid inputs from causing problems

# ->new
like( dies { Music::Guidonian->new }, qr/need key2pitch or key_set/ );
like( dies { Music::Guidonian->new( key2pitch => {}, key_set => {} ) },
    qr/cannot specify both key2pitch and key_set/ );

# key2pitch
like( dies { Music::Guidonian->new( key2pitch => undef ) },
    qr/key2pitch must be a hash reference/ );
like(
    dies { Music::Guidonian->new( key2pitch => [] ) },
    qr/key2pitch must be a hash reference/
);
like(
    dies { Music::Guidonian->new( key2pitch => {} ) },
    qr/key2pitch must be a hash reference with keys/
);

# key_set
like( dies { Music::Guidonian->new( key_set => undef ) },
    qr/key_set must be a hash reference/ );
like( dies { Music::Guidonian->new( key_set => [] ) },
    qr/key_set must be a hash reference/ );
like(
    dies { Music::Guidonian->new( key_set => {} ) },
    qr/key_set must be a hash reference with keys/
);

like( dies { Music::Guidonian->new( key_set => { intervals => undef } ) },
    qr/intervals must be an array with elements/ );
like( dies { Music::Guidonian->new( key_set => { intervals => {} } ) },
    qr/intervals must be an array with elements/ );
like( dies { Music::Guidonian->new( key_set => { intervals => [] } ) },
    qr/intervals must be an array with elements/ );

like(
    dies { Music::Guidonian->new( key_set => { intervals => [2], keys => undef } ) }
    ,
    qr/keys must be an array with elements/
);
like(
    dies { Music::Guidonian->new( key_set => { intervals => [2], keys => {} } ) },
    qr/keys must be an array with elements/ );
like(
    dies { Music::Guidonian->new( key_set => { intervals => [2], keys => [] } ) },
    qr/keys must be an array with elements/ );

like(
    dies {
        Music::Guidonian->new(
            key_set => { intervals => [2], keys => ['a'], min => undef } )
    },
    qr/min must be an integer/
);
like(
    dies {
        Music::Guidonian->new(
            key_set => { intervals => [2], keys => ['a'], min => "vore" } )
    },
    qr/min must be an integer/
);

like(
    dies {
        Music::Guidonian->new(
            key_set => { intervals => [2], keys => ['a'], min => 42, max => undef } )
    },
    qr/max must be an integer/
);
like(
    dies {
        Music::Guidonian->new(
            key_set => { intervals => [2], keys => ['a'], min => 42, max => "xano" } )
    },
    qr/max must be an integer/
);

like(
    dies {
        Music::Guidonian->new(
            key_set => { intervals => [2], keys => ['a'], min => 42, max => 42 } )
    },
    qr/min must be less than max/
);

# ->interator
$mg->key2pitch(
    { i => [ 60, 66 ], a => [ 61, 67 ], unset => undef, hash => {}, empty => [] } );

like( dies { $mg->iterator() },        qr/sequence is not an array reference/ );
like( dies { $mg->iterator( {} ) },    qr/sequence is not an array reference/ );
like( dies { $mg->iterator( ['i'] ) }, qr/sequence is too short/ );
like( dies { $mg->iterator( [ 'i', undef ] ) },
    qr/sequence element is undefined/ );
like( dies { $mg->iterator( [qw(lol no)] ) },   qr/choices are not an array/ );
like( dies { $mg->iterator( [qw(42 unset)] ) }, qr/choices are not an array/ );
like( dies { $mg->iterator( [qw(42 unknown)] ) },
    qr/choices are not an array/ );
like(
    dies { $mg->iterator( [qw(42 hash)] ) },
    qr/choices are not an array reference/
);
like( dies { $mg->iterator( [qw(42 empty)] ) }, qr/no choices for/ );

like( dies { $mg->iterator( [ 60, 66 ] ) }, qr/no choices in/ );

like( dies { $mg->iterator( [qw(i a)], renew => {} ) },
    qr/renew is not a code reference/ );

$mg->key2pitch(undef);
like( dies { $mg->iterator( [qw(i a i a)] ) }, qr/no key2pitch map is set/ );
$mg->key2pitch( [] );
like( dies { $mg->iterator( [qw(i a i a)] ) }, qr/no key2pitch map is set/ );
$mg->key2pitch( {} );
like( dies { $mg->iterator( [qw(i a i a)] ) }, qr/no key2pitch map is set/ );

done_testing;
