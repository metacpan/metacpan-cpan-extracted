use strict;
use warnings;

use Test::More;
use Test::Exception;

use TUI::toolkit::Types qw(
  :types
  Maybe
  :is
);

sub type_api_ok {
  my ($type, $name) = @_;

  subtest "Type::API compliance for $name" => sub {
    ok( $type, "$name is defined" );
    ok( ref $type, "$name is a reference" );

    # Must implement Type::API::Constraint
    ok( $type->DOES('Type::API::Constraint'),
      "$name DOES Type::API::Constraint" );

    # Must behave like a Type::API::Constraint::Inlinable
    ok( $type->DOES('Type::API::Constraint::Inlinable'),
      "$name DOES Type::API::Constraint::Inlinable" );

    # Must provide the following methods
    can_ok( $type, 'can_be_inlined' );
    can_ok( $type, 'inline_check' );
  };
}

# Helper: human readable description for test diagnostics
sub desc {
  my ( $v ) = @_;
  return 'undef' unless defined $v;
  return 'ARRAY-ref'                 if ref( $v ) eq 'ARRAY';
  return 'HASH-ref'                  if ref( $v ) eq 'HASH';
  return 'CODE-ref'                  if ref( $v ) eq 'CODE';
  return 'GLOB-ref'                  if ref( $v ) eq 'GLOB';
  return 'SCALAR-ref'                if ref( $v ) eq 'SCALAR';
  return 'object(' . ref( $v ) . ')' if ref( $v );
  return qq{"$v"};
} #/ sub desc

# Generic helper: run behaviour tests against inline_check-generated code
sub inline_behavior_ok {
  my ( %args )  = @_;
  my $type      = $args{type};
  my $name      = $args{name};
  my $accept    = $args{accept} // [];
  my $reject    = $args{reject} // [];
  my $predicate = $args{predicate};    # optional: low-level is_* predicate

  subtest "Inline behaviour for $name" => sub {

    # Type must be inlinable
    ok(
      $type->can_be_inlined,
      "$name->can_be_inlined is true"
    );

    my $expr = $type->inline_check( '$x' );

    ok( defined $expr, "$name->inline_check('\$x') returned expression" );

    my $inline_checker;
    lives_ok {
      # Simulate a caller where the value is at $_[1]
      # (e.g. first arg could be invocant/context, second is the value).
      my $code = "sub { my (undef, \$x) = \@_; $expr }";
      $inline_checker = eval $code;
      die $@ if $@;
    } "$name inline expression compiles to code";

    ok(
      ref( $inline_checker ) eq 'CODE',
      "$name inline checker is a coderef"
    );

    # Now run the same style of tests as behaviour_ok,
    # but using the inline-generated checker instead of ->check
    for my $v ( @$accept ) {
      ok(
        $inline_checker->( $type, $v ),
        "$name inline accepts " . desc( $v )
      );
      if ( $predicate ) {
        ok(
          $predicate->( $v ),
          "$name predicate accepts " . desc( $v )
        );
      }
    } #/ for my $v ( @$accept )

    for my $v ( @$reject ) {
      ok(
        !$inline_checker->( $type, $v ),
        "$name inline rejects " . desc( $v )
      );
      if ( $predicate ) {
        ok(
          !$predicate->( $v ),
          "$name predicate rejects " . desc( $v )
        );
      }
    } #/ for my $v ( @$reject )
  }; #/ "Inline behaviour for $name" => sub
} #/ sub inline_behavior_ok

#
# Inline behaviour tests for primitive / core types with inlined support
#

subtest 'Inline: Any' => sub {
  my $t = Any;
  type_api_ok( $t, 'Any' );
  inline_behavior_ok(
    type      => $t,
    name      => 'Any',
    accept    => [ undef, 0, 1, 'x', [], {} ],
    reject    => [],
    predicate => \&is_Any,
  );
}; #/ 'Inline: Any' => sub

subtest 'Inline: Item' => sub {
  my $t = Item;
  type_api_ok( $t, 'Item' );
  inline_behavior_ok(
    type      => $t,
    name      => 'Item',
    accept    => [ undef, 0, 1, 'x', [], {} ],
    reject    => [],
    predicate => \&is_Item,
  );
}; #/ 'Inline: Item' => sub

subtest 'Inline: Undef' => sub {
  my $t = Undef;
  type_api_ok( $t, 'Undef' );
  inline_behavior_ok(
    type      => $t,
    name      => 'Undef',
    accept    => [undef],
    reject    => [ 0, '', 'x', [], {} ],
    predicate => \&is_Undef,
  );
}; #/ 'Inline: Undef' => sub

subtest 'Inline: Defined' => sub {
  my $t = Defined;
  type_api_ok( $t, 'Defined' );
  inline_behavior_ok(
    type      => $t,
    name      => 'Defined',
    accept    => [ 0, '', 'x', [], {} ],
    reject    => [undef],
    predicate => \&is_Defined,
  );
}; #/ 'Inline: Defined' => sub

subtest 'Inline: Value' => sub {
  my $t = Value;
  type_api_ok( $t, 'Value' );
  inline_behavior_ok(
    type      => $t,
    name      => 'Value',
    accept    => [ 0, 1, '', 'foo' ],
    reject    => [ undef, [], {} ],
    predicate => \&is_Value,
  );
}; #/ 'Inline: Value' => sub

subtest 'Inline: Bool' => sub {
  my $t = Bool;
  type_api_ok( $t, 'Bool' );
  inline_behavior_ok(
    type      => $t,
    name      => 'Bool',
    accept    => [ undef, '', '0', '1' ],
    reject    => [ 'yes', 2, [], {} ],
    predicate => \&is_Bool,
  );
}; #/ 'Inline: Bool' => sub

subtest 'Inline: Str' => sub {
  my $t = Str;
  type_api_ok( $t, 'Str' );
  inline_behavior_ok(
    type      => $t,
    name      => 'Str',
    accept    => [ '', 'foo', "bar\t" ],
    reject    => [ [], {}, *STDOUT ],
    predicate => \&is_Str,
  );
}; #/ 'Inline: Str' => sub

subtest 'Inline: Num / Int / PositiveInt / PositiveOrZeroInt' => sub {
  my $num  = Num;
  my $int  = Int;
  my $pint = PositiveInt;
  my $pz   = PositiveOrZeroInt;

  type_api_ok( $num,  'Num' );
  type_api_ok( $int,  'Int' );
  type_api_ok( $pint, 'PositiveInt' );
  type_api_ok( $pz,   'PositiveOrZeroInt' );

  inline_behavior_ok(
    type      => $num,
    name      => 'Num',
    accept    => [ 0, 1, 1.5, -2 ],
    reject    => [ 'x', [], {} ],
    predicate => \&is_Num,
  );

  inline_behavior_ok(
    type      => $int,
    name      => 'Int',
    accept    => [ -1,  0, 1, 42 ],
    reject    => [ 'x', 1.5, [], {} ],
    predicate => \&is_Int,
  );

  inline_behavior_ok(
    type      => $pint,
    name      => 'PositiveInt',
    accept    => [ 1, 42 ],
    reject    => [ 0, -1, 'x', [] ],
    predicate => \&is_PositiveInt,
  );

  inline_behavior_ok(
    type      => $pz,
    name      => 'PositiveOrZeroInt',
    accept    => [ 0, 1, 42 ],
    reject    => [ -1, 'x', [] ],
    predicate => \&is_PositiveOrZeroInt,
  );
};

subtest 'Inline: Ref/ScalarRef/ArrayRef/HashRef/CodeRef/GlobRef/Object' => sub {
  my $ref_t  = Ref();
  my $sref_t = ScalarRef();
  my $aref_t = ArrayRef();
  my $href_t = HashRef();
  my $code_t = CodeRef();
  my $glob_t = GlobRef();
  my $obj_t  = Object;

  type_api_ok( $ref_t,  'Ref' );
  type_api_ok( $sref_t, 'ScalarRef' );
  type_api_ok( $aref_t, 'ArrayRef' );
  type_api_ok( $href_t, 'HashRef' );
  type_api_ok( $code_t, 'CodeRef' );
  type_api_ok( $glob_t, 'GlobRef' );
  type_api_ok( $obj_t,  'Object' );

  my $scalar = 10;
  my $sref   = \$scalar;
  my $aref   = [ 1, 2 ];
  my $href   = { a => 1 };
  my $code   = sub { };
  my $glob   = \*STDOUT;
  my $obj    = bless {};

  inline_behavior_ok(
    type      => $ref_t,
    name      => 'Ref',
    accept    => [ $sref, $aref, $href, $code, $glob, $obj ],
    reject    => [ undef, 0, 'x' ],
    predicate => \&is_Ref,
  );

  inline_behavior_ok(
    type      => $sref_t,
    name      => 'ScalarRef',
    accept    => [$sref],
    reject    => [ $aref, $href, $code, $glob, 1 ],
    predicate => \&is_ScalarRef,
  );

  inline_behavior_ok(
    type      => $aref_t,
    name      => 'ArrayRef',
    accept    => [$aref],
    reject    => [ $sref, $href, $code, $glob, 1 ],
    predicate => \&is_ArrayRef,
  );

  inline_behavior_ok(
    type      => $href_t,
    name      => 'HashRef',
    accept    => [$href],
    reject    => [ $sref, $aref, $code, $glob, 1 ],
    predicate => \&is_HashRef,
  );

  inline_behavior_ok(
    type      => $code_t,
    name      => 'CodeRef',
    accept    => [$code],
    reject    => [ $sref, $aref, $href, $glob, 1 ],
    predicate => \&is_CodeRef,
  );

  inline_behavior_ok(
    type      => $glob_t,
    name      => 'GlobRef',
    accept    => [$glob],
    reject    => [ $sref, $aref, $href, $code, 1 ],
    predicate => \&is_GlobRef,
  );

  inline_behavior_ok(
    type      => $obj_t,
    name      => 'Object',
    accept    => [$obj],
    reject    => [ $sref, $aref, $href, $code, $glob, 1 ],
    predicate => \&is_Object,
  );
};

#
# Types without inline support (sanity check: can_be_inlined must be false)
#

subtest 'Types without inline support' => sub {
  my @types = (
    [ ClassName,          'ClassName' ],
    [ FileHandle,         'FileHandle' ],
    [ Maybe( [Int] ),     'Maybe[Int]' ],
    [ Ref( [Int] ),       'Ref[Int]' ],
    [ ArrayRef( [Int] ),  'ArrayRef[Int]' ],
    [ HashRef( [Int] ),   'HashRef[Int]' ],
    [ ScalarRef( [Int] ), 'ScalarRef[Int]' ],
  );

  for my $entry ( @types ) {
    my ( $t, $name ) = @$entry;
    subtest "No inline for $name" => sub {
      ok( !$t->can_be_inlined, "$name->can_be_inlined is false" );
      my $expr = $t->inline_check( '$x' );
      ok( !defined $expr, "$name->inline_check('\$x') returns undef" );
    };
  }
};

done_testing();
