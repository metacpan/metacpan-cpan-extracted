#!/usr/bin/env perl -w
use strict;
use warnings;
use Test::More qw( no_plan );
use Scalar::Util::Reftype qw( reftype HAS_FORMAT_REF );

my $scalar;
my $sref    = \$scalar;
my $ioref   = *STDIN{IO};
my $re      = qr/ Testing /xmsi;
my $gref    = \*STDOUT;
my $lvalue  = \substr q{}, 0;

# normal refs
is( reftype( \$0     )->scalar   , 1, 'Testing SCALAR' );
is( reftype( []      )->array    , 1, 'Testing ARRAY'  );
is( reftype( {}      )->hash     , 1, 'Testing HASH'   );
is( reftype( sub{}   )->code     , 1, 'Testing CODE'   );
is( reftype($gref    )->glob     , 1, 'Testing GLOB'   );
is( reftype(\$sref   )->ref      , 1, 'Testing REF'    );
is( reftype($ioref   )->io       , 1, 'Testing IO'     );
is( reftype($ioref   )->io_object, 1, 'Testing IO'     );
is( reftype( $re     )->regexp   , 1, 'Testing Regexp' );
is( reftype( $lvalue )->lvalue   , 1, 'Testing LVALUE' );

is( reftype( []      )->hash     , 0, 'Testing hash   on ARRAY' );
is( reftype( {}      )->array    , 0, 'Testing array  on HASH'  );
is( reftype( \$0     )->code     , 0, 'Testing code   on SCALAR');
is( reftype( sub{}   )->scalar   , 0, 'Testing scalar on CODE'  );

my $scalaro = bless $sref   , 'Foo';
my $arrayo  = bless []      , 'Foo';
my $hasho   = bless {}      , 'Foo';
my $codeo   = bless sub {}  , 'Foo';
my $globo   = bless $gref, 'Foo';
my $refo    = bless \$sref  , 'Foo';
my $ioo     = bless $ioref  , 'Foo';
my $regexpo = bless $re     , 'Foo';
my $lvalueo = bless $lvalue , 'Foo';

# blessed refs
is( reftype( $scalaro )->scalar_object,     1, 'Object is a  SCALAR object' );
is( reftype( $arrayo  )->array_object,      1, 'Object is an ARRAY  object' );
is( reftype( $hasho   )->hash_object,       1, 'Object is a  HASH   object' );
is( reftype( $codeo   )->code_object,       1, 'Object is a  CODE   object' );
is( reftype( $globo   )->glob_object,       1, 'Object is a  GLOB   object' );
is( reftype( $refo    )->ref_object,        1, 'Object is a  REF    object' );
is( reftype( $ioo     )->io_object,         1, 'Object is a  IO object'     );
is( reftype( $ioo     )->io,                1, 'Object is a  IO object'     );
is( reftype( $regexpo )->regexp_object,     1, 'Object is a  Regexp object' );
is( reftype( $lvalueo )->lvalue_object,     1, 'Object is a  LVALUE object' );

is( reftype( $scalaro )->container    , 'Foo', 'Object is an instance of Foo (container)' );
is( reftype( $scalaro )->class        , 'Foo', 'Object is an instance of Foo (class)' );
is( reftype( \$0      )->container    ,   q{}, 'Non-blessed returns empty string');

# false tests
is( reftype(q{}       )->array        ,     0, 'Test non-ref (empty string)' );
is( reftype(undef     )->array        ,     0, 'Test non-ref (undef)'        );
is( reftype(0         )->array        ,     0, 'Test non-ref (zero)'         );

# non-ref tests
is( reftype('foobar'  )->array        ,     0, 'Test non-ref' );

my $ok = eval {
    if ( reftype( 'secrets of the universe' ) ) {
        my $pok = print '42';
    }
};

ok( $@, 'Error thrown' );

like(
    $@ => qr{can not be used in boolean contexts}ms,
    'Objects can not be used in boolean contexts'
);

SKIP: {
    skip('Skipping FORMAT tests under old perl',2) if ! HAS_FORMAT_REF;
    ## no critic (ProhibitFormats)
    format STDERR =
.
    ## use critic
    my $fref = *STDERR{FORMAT};
    is( reftype( $fref )->format       , 1, 'Testing FORMAT' );
    my $fobj = bless $fref, 'Foo';
    is( reftype( $fobj )->format_object, 1, 'Object is a FORMAT object' );
}

__END__
