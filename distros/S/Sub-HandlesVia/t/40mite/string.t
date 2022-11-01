use strict;
use warnings;
## skip Test::Tabs
use Test::More;
use Test::Requires '5.008001';
use Test::Fatal;
use FindBin qw($Bin);
use lib "$Bin/lib";

use MyTest::TestClass::String;
my $CLASS = q[MyTest::TestClass::String];

## append

can_ok( $CLASS, 'my_append' );

subtest 'Testing my_append' => sub {
  my $e = exception {
    my $object = $CLASS->new( attr => 'foo' );
    $object->my_append( 'bar' );
    is( $object->attr, 'foobar', q{$object->attr is 'foobar'} );
  };
  is( $e, undef, 'no exception thrown running append example' );
};

## chomp

can_ok( $CLASS, 'my_chomp' );

## chop

can_ok( $CLASS, 'my_chop' );

## clear

can_ok( $CLASS, 'my_clear' );

subtest 'Testing my_clear' => sub {
  my $e = exception {
    my $object = $CLASS->new( attr => 'foo' );
    $object->my_clear;
    note $object->attr; ## nothing
  };
  is( $e, undef, 'no exception thrown running clear example' );
};

## cmp

can_ok( $CLASS, 'my_cmp' );

## cmpi

can_ok( $CLASS, 'my_cmpi' );

## contains

can_ok( $CLASS, 'my_contains' );

## contains_i

can_ok( $CLASS, 'my_contains_i' );

## ends_with

can_ok( $CLASS, 'my_ends_with' );

## ends_with_i

can_ok( $CLASS, 'my_ends_with_i' );

## eq

can_ok( $CLASS, 'my_eq' );

## eqi

can_ok( $CLASS, 'my_eqi' );

## fc

can_ok( $CLASS, 'my_fc' );

## ge

can_ok( $CLASS, 'my_ge' );

## gei

can_ok( $CLASS, 'my_gei' );

## get

can_ok( $CLASS, 'my_get' );

subtest 'Testing my_get' => sub {
  my $e = exception {
    my $object = $CLASS->new( attr => 'foo' );
    is( $object->my_get, 'foo', q{$object->my_get is 'foo'} );
  };
  is( $e, undef, 'no exception thrown running get example' );
};

## gt

can_ok( $CLASS, 'my_gt' );

## gti

can_ok( $CLASS, 'my_gti' );

## inc

can_ok( $CLASS, 'my_inc' );

## lc

can_ok( $CLASS, 'my_lc' );

## le

can_ok( $CLASS, 'my_le' );

## lei

can_ok( $CLASS, 'my_lei' );

## length

can_ok( $CLASS, 'my_length' );

subtest 'Testing my_length' => sub {
  my $e = exception {
    my $object = $CLASS->new( attr => 'foo' );
    is( $object->my_length, 3, q{$object->my_length is 3} );
  };
  is( $e, undef, 'no exception thrown running length example' );
};

## lt

can_ok( $CLASS, 'my_lt' );

## lti

can_ok( $CLASS, 'my_lti' );

## match

can_ok( $CLASS, 'my_match' );

subtest 'Testing my_match' => sub {
  my $e = exception {
    my $object = $CLASS->new( attr => 'foo' );
    if ( $object->my_match( '^f..$' ) ) {
      note 'matched!';
    }
  };
  is( $e, undef, 'no exception thrown running match example' );
};

## match_i

can_ok( $CLASS, 'my_match_i' );

subtest 'Testing my_match_i' => sub {
  my $e = exception {
    my $object = $CLASS->new( attr => 'foo' );
    if ( $object->my_match_i( '^F..$' ) ) {
      note 'matched!';
    }
  };
  is( $e, undef, 'no exception thrown running match_i example' );
};

## ne

can_ok( $CLASS, 'my_ne' );

## nei

can_ok( $CLASS, 'my_nei' );

## prepend

can_ok( $CLASS, 'my_prepend' );

subtest 'Testing my_prepend' => sub {
  my $e = exception {
    my $object = $CLASS->new( attr => 'foo' );
    $object->my_prepend( 'bar' );
    is( $object->attr, 'barfoo', q{$object->attr is 'barfoo'} );
  };
  is( $e, undef, 'no exception thrown running prepend example' );
};

## replace

can_ok( $CLASS, 'my_replace' );

subtest 'Testing my_replace' => sub {
  my $e = exception {
    my $object = $CLASS->new( attr => 'foo' );
    $object->my_replace( 'o' => 'a' );
    is( $object->attr, 'fao', q{$object->attr is 'fao'} );
  
    my $object2 = $CLASS->new( attr => 'foo' );
    $object2->my_replace( qr/O/i => sub { return 'e' } );
    is( $object2->attr, 'feo', q{$object2->attr is 'feo'} );
  };
  is( $e, undef, 'no exception thrown running replace example' );
};

## replace_globally

can_ok( $CLASS, 'my_replace_globally' );

subtest 'Testing my_replace_globally' => sub {
  my $e = exception {
    my $object = $CLASS->new( attr => 'foo' );
    $object->my_replace_globally( 'o' => 'a' );
    is( $object->attr, 'faa', q{$object->attr is 'faa'} );
  
    my $object2 = $CLASS->new( attr => 'foo' );
    $object2->my_replace_globally( qr/O/i => sub { return 'e' } );
    is( $object2->attr, 'fee', q{$object2->attr is 'fee'} );
  };
  is( $e, undef, 'no exception thrown running replace_globally example' );
};

## reset

can_ok( $CLASS, 'my_reset' );

## set

can_ok( $CLASS, 'my_set' );

subtest 'Testing my_set' => sub {
  my $e = exception {
    my $object = $CLASS->new( attr => 'foo' );
    $object->my_set( 'bar' );
    is( $object->attr, 'bar', q{$object->attr is 'bar'} );
  };
  is( $e, undef, 'no exception thrown running set example' );
};

## starts_with

can_ok( $CLASS, 'my_starts_with' );

## starts_with_i

can_ok( $CLASS, 'my_starts_with_i' );

## substr

can_ok( $CLASS, 'my_substr' );

## uc

can_ok( $CLASS, 'my_uc' );

done_testing;
