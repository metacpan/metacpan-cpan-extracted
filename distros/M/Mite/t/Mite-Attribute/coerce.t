#!/usr/bin/perl

use lib 't/lib';
use Test::Mite;

use Mite::Attribute;

tests "Simple coercion" => sub {
    mite_load <<'CODE';
package Foo;
use Mite::Shim;
has truth =>
  accessor => 1,
  writer => 1,
  reader => 1,
  isa => 'Bool',
  coerce => 1,
  builder => sub { [] },
  lazy => 1;
1;
CODE

    {
        my $obj = Foo->new( truth => [] );
        is( $obj->truth, !!1, 'coerced in constructor' );
    }

    {
        my $obj = Foo->new( truth => '' );
        $obj->truth( [] );
        is( $obj->truth, !!1, 'coerced in accessor' );
    }

    {
        my $obj = Foo->new( truth => '' );
        $obj->set_truth( [] );
        is( $obj->truth, !!1, 'coerced in writer' );
    }

    {
        my $obj = Foo->new();
        is( $obj->get_truth, !!1, 'coerced in reader+builder' );
    }
};

done_testing;
