use strict;
use warnings;

use Test::More tests => 13;

use Params::Named;

{
  sub testme {
    MAPARGS my($foo, $bar, $baz);
    return $foo, $bar, $baz;
  }

  my($a,$b,$c) = eval { testme qw/ foo this bar that baz theother / };
  ok !$@, 'A basic MAPARGS call.';
  ok eq_array([$a,$b,$c], [qw/this that theother/]), 'Args match with values.';

  my %hash   = qw/ foo x bar y baz z /;
  ($a,$b,$c) = testme %hash;
  ok eq_array([$a,$b,$c], ['x' .. 'z']), 'A flattened hash works as expected.';
}

{
  sub testhis {
    MAPARGS \my($x, @y, %z);
    return $x, \@y, \%z;
  }

  my($x,$y,$z) = ('a string',[qw/an array/],{qw/a hash/});
  my($a,$b,$c) = eval { testhis x => $x, y => $y, z => $z };
  ok !$@, 'Mapped different data types ok.';
  is       $a, $x, 'The string matched normally.';
  ok eq_array($b, $y), 'The array mapped and matches correctly.';
  ok eq_hash( $c, $z), 'The hash mapped and matches correctly.';
}

{
  sub testtypes { MAPARGS \my($x); return $x }

  ($a) = eval { testtypes x => \\'thingie' };
  ok !$@, 'Mapped what is a REF in 5.8 without a problem.';
  is $$$a, 'thingie', 'The string in REF is as expected.';

  local $@;
  eval { testtypes x => {} };
  ok $@, 'Giving an incorrect type dies expectedly.';
  like $@, qr/\$x.*?HASH/, 'The error message looks about right.';
}

{
  local $SIG{__WARN__} = sub {
    like $_[0],
         qr/Parameter '\$wuzzle' not mapped to an argument/,
         'Complained appropriately for unmapped parameter.';
  };
  sub noparam {
    MAPARGS \my($woozle, $wuzzle);
    return $woozle, $wuzzle;
  }

  local $@;
  eval { noparam woozle => 'Map this!', wuzz1e => 'Not this!' };
  ok !$@, "Not mapping to every param doesn't die.";
}
