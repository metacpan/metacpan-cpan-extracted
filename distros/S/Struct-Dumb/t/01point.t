#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Scalar::Util qw( refaddr );

use Struct::Dumb;

struct Point => [qw( x y )];

my $point = Point(10, 20);
ok( ref $point, '$point is a ref' );

can_ok( $point, "x" );

is( $point->x, 10, '$point->x is 10' );

$point->y = 30;
is( $point->y, 30, '$point->y is 30 after mutation' );

like( exception { $point->z },
      qr/^main::Point does not have a 'z' field at \S+ line \d+\.?\n/,
      '$point->z throws exception' );

like( exception { $point->z = 40 },
      qr/^main::Point does not have a 'z' field at \S+ line \d+\.?\n/,
      '$point->z :lvalue throws exception' );

like( exception { Point(30) },
      qr/^usage: main::Point\(\$x, \$y\) at \S+ line \d+\.?\n/,
      'Point(30) throws usage exception' );

like( exception { @{ Point(0, 0) } },
      qr/^Cannot use main::Point as an ARRAY reference at \S+ line \d+\.?\n/,
      'Array deref throws exception' );

ok( !( local $@ = exception {
      no warnings 'redefine';
      local *Point::_forbid_arrayification = sub {};
      @{ Point(2, 2) };
   } ),
   'Array deref succeeds with locally-overridden forbid function' ) or
   diag( "Exception was $@" );

like( exception { $point->x(50) },
      qr/^main::Point->x invoked with arguments at \S+ line \d+\.?\n/,
      'Accessor with arguments throws exception' );

ok( !( local $@ = exception { !! Point(0, 0) } ),
    'Point is boolean true' ) or diag( "Exception was $@" );

is( $point + 0, refaddr $point,
    'Point numifies to its reference address' );

like( "$point", qr/^main::Point=Struct::Dumb\(0x[0-9a-fA-F]+\)$/,
    'Point stringifies to something sensible' );

done_testing;
