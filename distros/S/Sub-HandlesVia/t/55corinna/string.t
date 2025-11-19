use Test::Requires '5.038';
use 5.038;
use strict;
use warnings;
use feature 'class';
no warnings 'experimental::class';
use Test::More;
use Test::Fatal;
## skip Test::Tabs

class My::Class {
  use Types::Standard 'Str';
  field $attr :param = q[];
  method attr ()         { $attr }
  method _set_attr($new) { $attr = $new }
  use Sub::HandlesVia::Declare [ 'attr', '_set_attr', sub { q[] } ],
    String => (
      'my_append' => 'append',
      'my_chomp' => 'chomp',
      'my_chop' => 'chop',
      'my_clear' => 'clear',
      'my_cmp' => 'cmp',
      'my_cmpi' => 'cmpi',
      'my_contains' => 'contains',
      'my_contains_i' => 'contains_i',
      'my_ends_with' => 'ends_with',
      'my_ends_with_i' => 'ends_with_i',
      'my_eq' => 'eq',
      'my_eqi' => 'eqi',
      'my_fc' => 'fc',
      'my_ge' => 'ge',
      'my_gei' => 'gei',
      'my_get' => 'get',
      'my_gt' => 'gt',
      'my_gti' => 'gti',
      'my_inc' => 'inc',
      'my_lc' => 'lc',
      'my_le' => 'le',
      'my_lei' => 'lei',
      'my_length' => 'length',
      'my_lt' => 'lt',
      'my_lti' => 'lti',
      'my_match' => 'match',
      'my_match_i' => 'match_i',
      'my_ne' => 'ne',
      'my_nei' => 'nei',
      'my_prepend' => 'prepend',
      'my_replace' => 'replace',
      'my_replace_globally' => 'replace_globally',
      'my_reset' => 'reset',
      'my_set' => 'set',
      'my_starts_with' => 'starts_with',
      'my_starts_with_i' => 'starts_with_i',
      'my_substr' => 'substr',
      'my_trim' => 'trim',
      'my_uc' => 'uc',
    );
}

## append

can_ok( 'My::Class', 'my_append' );

subtest 'Testing my_append' => sub {
  my $e = exception {
    my $object = My::Class->new( attr => 'foo' );
    $object->my_append( 'bar' );
    is( $object->attr, 'foobar', q{$object->attr is 'foobar'} );
  };
  is( $e, undef, 'no exception thrown running append example' );
};

## chomp

can_ok( 'My::Class', 'my_chomp' );

## chop

can_ok( 'My::Class', 'my_chop' );

## clear

can_ok( 'My::Class', 'my_clear' );

subtest 'Testing my_clear' => sub {
  my $e = exception {
    my $object = My::Class->new( attr => 'foo' );
    $object->my_clear;
    note $object->attr; ## nothing
  };
  is( $e, undef, 'no exception thrown running clear example' );
};

## cmp

can_ok( 'My::Class', 'my_cmp' );

## cmpi

can_ok( 'My::Class', 'my_cmpi' );

## contains

can_ok( 'My::Class', 'my_contains' );

## contains_i

can_ok( 'My::Class', 'my_contains_i' );

## ends_with

can_ok( 'My::Class', 'my_ends_with' );

## ends_with_i

can_ok( 'My::Class', 'my_ends_with_i' );

## eq

can_ok( 'My::Class', 'my_eq' );

## eqi

can_ok( 'My::Class', 'my_eqi' );

## fc

can_ok( 'My::Class', 'my_fc' );

## ge

can_ok( 'My::Class', 'my_ge' );

## gei

can_ok( 'My::Class', 'my_gei' );

## get

can_ok( 'My::Class', 'my_get' );

subtest 'Testing my_get' => sub {
  my $e = exception {
    my $object = My::Class->new( attr => 'foo' );
    is( $object->my_get, 'foo', q{$object->my_get is 'foo'} );
  };
  is( $e, undef, 'no exception thrown running get example' );
};

## gt

can_ok( 'My::Class', 'my_gt' );

## gti

can_ok( 'My::Class', 'my_gti' );

## inc

can_ok( 'My::Class', 'my_inc' );

## lc

can_ok( 'My::Class', 'my_lc' );

## le

can_ok( 'My::Class', 'my_le' );

## lei

can_ok( 'My::Class', 'my_lei' );

## length

can_ok( 'My::Class', 'my_length' );

subtest 'Testing my_length' => sub {
  my $e = exception {
    my $object = My::Class->new( attr => 'foo' );
    is( $object->my_length, 3, q{$object->my_length is 3} );
  };
  is( $e, undef, 'no exception thrown running length example' );
};

## lt

can_ok( 'My::Class', 'my_lt' );

## lti

can_ok( 'My::Class', 'my_lti' );

## match

can_ok( 'My::Class', 'my_match' );

subtest 'Testing my_match' => sub {
  my $e = exception {
    my $object = My::Class->new( attr => 'foo' );
    if ( $object->my_match( '^f..$' ) ) {
      note 'matched!';
    }
  };
  is( $e, undef, 'no exception thrown running match example' );
};

## match_i

can_ok( 'My::Class', 'my_match_i' );

subtest 'Testing my_match_i' => sub {
  my $e = exception {
    my $object = My::Class->new( attr => 'foo' );
    if ( $object->my_match_i( '^F..$' ) ) {
      note 'matched!';
    }
  };
  is( $e, undef, 'no exception thrown running match_i example' );
};

## ne

can_ok( 'My::Class', 'my_ne' );

## nei

can_ok( 'My::Class', 'my_nei' );

## prepend

can_ok( 'My::Class', 'my_prepend' );

subtest 'Testing my_prepend' => sub {
  my $e = exception {
    my $object = My::Class->new( attr => 'foo' );
    $object->my_prepend( 'bar' );
    is( $object->attr, 'barfoo', q{$object->attr is 'barfoo'} );
  };
  is( $e, undef, 'no exception thrown running prepend example' );
};

## replace

can_ok( 'My::Class', 'my_replace' );

subtest 'Testing my_replace' => sub {
  my $e = exception {
    my $object = My::Class->new( attr => 'foo' );
    $object->my_replace( 'o' => 'a' );
    is( $object->attr, 'fao', q{$object->attr is 'fao'} );
  
    my $object2 = My::Class->new( attr => 'foo' );
    $object2->my_replace( qr/O/i => sub { return 'e' } );
    is( $object2->attr, 'feo', q{$object2->attr is 'feo'} );
  };
  is( $e, undef, 'no exception thrown running replace example' );
};

## replace_globally

can_ok( 'My::Class', 'my_replace_globally' );

subtest 'Testing my_replace_globally' => sub {
  my $e = exception {
    my $object = My::Class->new( attr => 'foo' );
    $object->my_replace_globally( 'o' => 'a' );
    is( $object->attr, 'faa', q{$object->attr is 'faa'} );
  
    my $object2 = My::Class->new( attr => 'foo' );
    $object2->my_replace_globally( qr/O/i => sub { return 'e' } );
    is( $object2->attr, 'fee', q{$object2->attr is 'fee'} );
  };
  is( $e, undef, 'no exception thrown running replace_globally example' );
};

## reset

can_ok( 'My::Class', 'my_reset' );

## set

can_ok( 'My::Class', 'my_set' );

subtest 'Testing my_set' => sub {
  my $e = exception {
    my $object = My::Class->new( attr => 'foo' );
    $object->my_set( 'bar' );
    is( $object->attr, 'bar', q{$object->attr is 'bar'} );
  };
  is( $e, undef, 'no exception thrown running set example' );
};

## starts_with

can_ok( 'My::Class', 'my_starts_with' );

## starts_with_i

can_ok( 'My::Class', 'my_starts_with_i' );

## substr

can_ok( 'My::Class', 'my_substr' );

## trim

can_ok( 'My::Class', 'my_trim' );

## uc

can_ok( 'My::Class', 'my_uc' );

done_testing;
