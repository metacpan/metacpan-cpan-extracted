use strict;
use warnings;

use Test::More;
use Test::Exception;

use TUI::toolkit::Types qw(
  Any Item Undef Defined Value Bool Str ClassName
  Num Int PositiveInt PositiveOrZeroInt
  Object Ref ScalarRef ArrayRef HashRef CodeRef GlobRef FileHandle
  Maybe InstanceOf
  :is
);

#use Types::Standard qw( InstanceOf Str );

BEGIN {
  package Foo;
  $INC{"Foo.pm"} = 1;
}

BEGIN {
  package Bar;
  our @ISA = qw( Foo );
  $INC{"Bar.pm"} = 1;
}

sub type_api_ok {
  my ($type, $name, $parent_name) = @_;

  subtest "Type::API compliance for $name" => sub {
    ok( $type, "$name is defined" );
    ok( is_Object( $type ), "$name is an object" );

    # Must provide the following methods
    can_ok( $type, 'check' );
    can_ok( $type, 'get_message' );

    is( $type->name, $name, "$name->name matches" );

    if ( defined $parent_name ) {
      my $parent = $type->parent;
      ok( $parent, "$name has a parent" );
      is( $parent->name, $parent_name,
          "$name parent name is $parent_name" );
    }
    else {
      ok( !defined $type->parent, "$name has no parent" );
    }

    # Boolean overload should be true
    ok( $type, "$name is true in boolean context" );

    # &{} overload: should produce a coderef that croaks on failure
    my $check = \&{$type};
    ok( ref($check) eq 'CODE', "$name &{} overload returns a coderef" );
  };
}

sub desc {
  my ($v) = @_;
  return 'undef'      unless defined $v;
  return 'ARRAY-ref'  if ref($v) eq 'ARRAY';
  return 'HASH-ref'   if ref($v) eq 'HASH';
  return 'CODE-ref'   if ref($v) eq 'CODE';
  return 'GLOB-ref'   if ref($v) eq 'GLOB';
  return 'SCALAR-ref' if ref($v) eq 'SCALAR';
  return 'object(' . ref($v) . ')' if ref($v);
  return qq{"$v"};
}

sub behavior_ok {
  my (%args) = @_;
  my $type      = $args{type};
  my $name      = $args{name};
  my $accept    = $args{accept}   || [];
  my $reject    = $args{reject}   || [];
  my $predicate = $args{predicate};

  subtest "Behaviour checks for $name" => sub {
    for my $v (@$accept) {
      ok( $type->check($v), "$name->check accepts " . desc($v) );
      if ($predicate) {
          ok( $predicate->($v), "$name predicate accepts " . desc($v) );
      }
      lives_ok { $type->($v) }
          "$name coderef call lives for " . desc($v);
    }

    for my $v (@$reject) {
      ok( !$type->check($v), "$name->check rejects " . desc($v) );
      if ($predicate) {
          ok( !$predicate->($v),
              "$name predicate rejects " . desc($v) );
      }
      dies_ok { $type->($v) }
          "$name coderef call dies for " . desc($v);
    }
  };
}

subtest 'Type::API compliance and behavior: Any' => sub {
  my $t = Any;
  type_api_ok( $t, 'Any', undef );
  behavior_ok(
    type      => $t,
    name      => 'Any',
    accept    => [ undef, 0, 1, 'x', [], {} ],
    reject    => [],
    predicate => \&is_Any,
  );
};

subtest 'Type::API compliance and behavior: Item' => sub {
  my $t = Item;
  type_api_ok( $t, 'Item', 'Any' );
  behavior_ok(
    type      => $t,
    name      => 'Item',
    accept    => [ undef, 0, 1, 'x', [], {} ],
    reject    => [],
    predicate => \&is_Item,
  );
};

subtest 'Undef' => sub {
  my $t = Undef;
  type_api_ok( $t, 'Undef', 'Item' );
  behavior_ok(
    type      => $t,
    name      => 'Undef',
    accept    => [ undef ],
    reject    => [ 0, '', 'x', [], {} ],
    predicate => \&is_Undef,
  );
};

subtest 'Defined' => sub {
  my $t = Defined;
  type_api_ok( $t, 'Defined', 'Item' );
  behavior_ok(
    type      => $t,
    name      => 'Defined',
    accept    => [ 0, '', 'x', [], {} ],
    reject    => [ undef ],
    predicate => \&is_Defined,
  );
};

subtest 'Value' => sub {
  my $t = Value;
  type_api_ok( $t, 'Value', 'Defined' );
  behavior_ok(
    type      => $t,
    name      => 'Value',
    accept    => [ 0, 1, '', 'foo' ],
    reject    => [ undef, [], {} ],
    predicate => \&is_Value,
  );
};

subtest 'Bool' => sub {
  my $t = Bool;
  type_api_ok( $t, 'Bool', 'Item' );
  behavior_ok(
    type      => $t,
    name      => 'Bool',
    accept    => [ undef, '', '0', '1' ],
    reject    => [ 'yes', 2, [], {} ],
    predicate => \&is_Bool,
  );
};

subtest 'Str' => sub {
  my $t = Str;
  type_api_ok( $t, 'Str', 'Value' );
  behavior_ok(
    type      => $t,
    name      => 'Str',
    accept    => [ '', 'foo', "bar\t" ],
    reject    => [ [], {}, \*STDOUT ],
    predicate => \&is_Str,
  );
};

subtest 'ClassName' => sub {
  my $t = ClassName;
  type_api_ok( $t, 'ClassName', 'Str' );

  {
    package Local::ClassNameTest;
    our $VERSION = 1;
  }

  behavior_ok(
    type   => $t,
    name   => 'ClassName',
    accept => [
      'TUI::toolkit::Types',
      'Local::ClassNameTest',
    ],
    reject => [
      'This::Does::Not::Exist::At::All',
      '',
      [],
    ],
    # no direct is_ClassName predicate exported in your list, so skip
    predicate => undef,
  );
};

subtest 'Num / Int / PositiveInt / PositiveOrZeroInt' => sub {
  my $num  = Num;
  my $int  = Int;
  my $pint = PositiveInt;
  my $pz   = PositiveOrZeroInt;

  type_api_ok( $num,  'Num',  'Value' );
  type_api_ok( $int,  'Int',  'Num' );
  type_api_ok( $pint, 'PositiveInt',        'Int' );
  type_api_ok( $pz,   'PositiveOrZeroInt',  'Int' );

  behavior_ok(
    type      => $int,
    name      => 'Int',
    accept    => [ -1, 0, 1, 42 ],
    reject    => [ 'x', 1.5, [], {} ],
    predicate => \&is_Int,
  );

  behavior_ok(
    type   => $pint,
    name   => 'PositiveInt',
    accept => [ 1, 42 ],
    reject => [ 0, -1, 'x', [] ],
    predicate => \&is_PositiveInt,
  );

  behavior_ok(
    type   => $pz,
    name   => 'PositiveOrZeroInt',
    accept => [ 0, 1, 42 ],
    reject => [ -1, 'x', [] ],
    predicate => \&is_PositiveOrZeroInt,
  );
};

subtest 'Ref/ScalarRef/ArrayRef/HashRef/CodeRef/GlobRef/Object' => sub {
  my $ref_t      = Ref();
  my $sref_t     = ScalarRef();
  my $aref_t     = ArrayRef();
  my $href_t     = HashRef();
  my $code_t     = CodeRef();
  my $glob_t     = GlobRef();
  my $obj_t      = Object();
  my $instance_t = InstanceOf();

  type_api_ok( $ref_t,      'Ref',        'Defined' );
  type_api_ok( $sref_t,     'ScalarRef',  'Ref' );
  type_api_ok( $aref_t,     'ArrayRef',   'Ref' );
  type_api_ok( $href_t,     'HashRef',    'Ref' );
  type_api_ok( $code_t,     'CodeRef',    'Ref' );
  type_api_ok( $glob_t,     'GlobRef',    'Ref' );
  type_api_ok( $obj_t,      'Object',     'Ref' );
  type_api_ok( $instance_t, 'InstanceOf', 'Object' );

  my $scalar = 10;
  my $sref   = \$scalar;
  my $aref   = [ 1, 2 ];
  my $href   = { a => 1 };
  my $code   = sub { };
  my $glob   = \*STDOUT;
  my $obj    = bless {};

  behavior_ok(
    type      => $ref_t,
    name      => 'Ref',
    accept    => [ $sref, $aref, $href, $code, $glob, $obj ],
    reject    => [ undef, 0, 'x' ],
    predicate => \&is_Ref,
  );

  behavior_ok(
    type      => $sref_t,
    name      => 'ScalarRef',
    accept    => [ $sref ],
    reject    => [ $aref, $href, $code, $glob, 1 ],
    predicate => \&is_ScalarRef,
  );

  behavior_ok(
    type      => $aref_t,
    name      => 'ArrayRef',
    accept    => [ $aref ],
    reject    => [ $sref, $href, $code, $glob, 1 ],
    predicate => \&is_ArrayRef,
  );

  behavior_ok(
    type      => $href_t,
    name      => 'HashRef',
    accept    => [ $href ],
    reject    => [ $sref, $aref, $code, $glob, 1 ],
    predicate => \&is_HashRef,
  );

  behavior_ok(
    type      => $code_t,
    name      => 'CodeRef',
    accept    => [ $code ],
    reject    => [ $sref, $aref, $href, $glob, 1 ],
    predicate => \&is_CodeRef,
  );

  behavior_ok(
    type      => $glob_t,
    name      => 'GlobRef',
    accept    => [ $glob ],
    reject    => [ $sref, $aref, $href, $code, 1 ],
    predicate => \&is_GlobRef,
  );

  behavior_ok(
    type      => $obj_t,
    name      => 'Object',
    accept    => [ $obj ],
    reject    => [ $sref, $aref, $href, $code, $glob, 1 ],
    predicate => \&is_Object,
  );

  behavior_ok(
    type      => $instance_t,
    name      => 'InstanceOf',
    accept    => [ $obj ],
    reject    => [ $sref, $aref, $href, $code, $glob, 1 ],
    predicate => \&is_Object,
  );
};

subtest 'FileHandle' => sub {
  my $fh_type = FileHandle;
  type_api_ok( $fh_type, 'FileHandle', 'Ref' );

  open my $fh, '<', $0 or die "Cannot open self: $!";
  behavior_ok(
    type      => $fh_type,
    name      => 'FileHandle',
    accept    => [ $fh ],
    reject    => [ 1, 'x', [], {} ],
    predicate => \&is_FileHandle,
  );
  close $fh;
};

subtest 'Parametric types: Maybe[Int] and ArrayRef[Int]' => sub {
  my $maybe_int = Maybe( [ Int ] );
  type_api_ok( $maybe_int, $maybe_int->name, 'Maybe' );

  ok( $maybe_int->check(undef), 'Maybe[Int] accepts undef' );
  ok( $maybe_int->check(42),    'Maybe[Int] accepts Int' );
  ok( !$maybe_int->check('x'),  'Maybe[Int] rejects non-Int' );

  my $aref_of_int = ArrayRef( [ Int ] );
  type_api_ok( $aref_of_int, $aref_of_int->name, 'ArrayRef' );

  ok( $aref_of_int->check( [ 1, 2, 3 ] ), 'ArrayRef[Int] accepts all Int' );
  ok( !$aref_of_int->check( [ 1, "x", 3 ] ),
    'ArrayRef[Int] rejects non-Int element' );
};

subtest 'Parametric types: InstanceOf[..]' => sub {
  my $obj   = InstanceOf( [''] );
  my $foo   = InstanceOf( ['Foo'] );
  my $union = InstanceOf( [ 'Foo', 'Baz' ] );

  type_api_ok( $obj,   $obj->name,   'Object' );
  type_api_ok( $foo,   $foo->name,   'Object' );
  type_api_ok( $union, $union->name, 'Object' );

  ok( $obj->check( bless( {} ) ),          'InstanceOf[""] accepts main' );
  ok( $foo->check( bless( {}, 'Foo' ) ),   'InstanceOf["Foo"] accepts Foo' );
  ok( $foo->check( bless( {}, 'Bar' ) ),   'InstanceOf["Foo"] accepts Bar' );
  ok( $union->check( bless( {}, 'Foo' ) ), 'InstanceOf[..] accepts Foo' );
  ok( !$foo->check( bless( {} ) ),         'InstanceOf["Foo"] rejects non-Foo');
  ok( !$foo->check( 'x' ),                 'InstanceOf["Foo"] rejects string' );
  ok( !$union->check( bless( {} ) ),       'InstanceOf[..] rejects non-Foo' );
};

done_testing();
