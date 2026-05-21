package TUI::toolkit::Types;
# ABSTRACT: Type constraints that are based heavily on Type::Nano

use 5.010;
use strict;
use warnings;

our $VERSION   = '0.07';
our $AUTHORITY = 'cpan:BRICKPOOL';

use Scalar::Util qw(
  blessed
  openhandle
  looks_like_number
  reftype
);

# ----------------------------------------------------------------------
# Export type constraints
# ----------------------------------------------------------------------

use Exporter 'import';

our @EXPORT_OK = qw(
  Maybe
  InstanceOf
);

our %EXPORT_TAGS = (
  # Standard Types
  Any         => [qw( Any       is_Any       )],
  Item        => [qw( Item      is_Item      )],
  Undef       => [qw( Undef     is_Undef     )],
  Defined     => [qw( Defined   is_Defined   )],
  Value       => [qw( Value     is_Value     )],
  Bool        => [qw( Bool      is_Bool      )],
  Str         => [qw( Str       is_Str       )],
  Num         => [qw( Num       is_Num       )],
  Int         => [qw( Int       is_Int       )],
  Object      => [qw( Object    is_Object    )],
  Ref         => [qw( Ref       is_Ref       )],
  ScalarRef   => [qw( ScalarRef is_ScalarRef )],
  ArrayRef    => [qw( ArrayRef  is_ArrayRef  )],
  HashRef     => [qw( HashRef   is_HashRef   )],
  CodeRef     => [qw( CodeRef   is_CodeRef   )],
  GlobRef     => [qw( GlobRef   is_GlobRef   )],

  # Special Types
  ClassName         => [qw( ClassName         is_ClassName         )],
  PositiveInt       => [qw( PositiveInt       is_PositiveInt       )],
  PositiveOrZeroInt => [qw( PositiveOrZeroInt is_PositiveOrZeroInt )],
  FileHandle        => [qw( FileHandle        is_FileHandle        )],
  ArrayLike         => [qw( ArrayLike         is_ArrayLike         )],
  HashLike          => [qw( HashLike          is_HashLike          )],

  # Additional groups
  types => [qw(
    Any
    Item
    Undef
    Defined
    Value
    Bool
    Str
    ClassName
    Num
    Int
    PositiveInt
    PositiveOrZeroInt
    Object
    Ref
    ScalarRef
    ArrayRef
    HashRef
    CodeRef
    GlobRef
    FileHandle
    ArrayLike
    HashLike
  )],

  is => [qw(
    is_Any
    is_Item
    is_Undef
    is_Defined
    is_Value
    is_Bool
    is_Str
    is_ClassName
    is_Num
    is_Int
    is_PositiveInt
    is_PositiveOrZeroInt
    is_Object
    is_Ref
    is_ScalarRef
    is_ArrayRef
    is_HashRef
    is_CodeRef
    is_GlobRef
    is_FileHandle
    is_ArrayLike
    is_HashLike
  )],
);

# add all the other %EXPORT_TAGS ":class" tags to the ":all" class and
# @EXPORT_OK, deleting duplicates
{
  my %seen;
  push
    @EXPORT_OK,
      grep {!$seen{$_}++} @{$EXPORT_TAGS{$_}}
        foreach keys %EXPORT_TAGS;
  push
    @{$EXPORT_TAGS{all}},
      @EXPORT_OK;
}

# ----------------------------------------------------------------------
# Built-in Type::API-compatible type object
# ----------------------------------------------------------------------
{
  package    # hides from CPAN
    TUI::Type::Object;

  use strict;
  use warnings;

  use B    ();
  use Carp ();

  my %roles = (
    'Type::API::Constraint'              => 1,
    'Type::API::Constraint::Constructor' => 1,
    'Type::API::Constraint::Inlinable'   => 1,
  );

  sub DOES {
    my ( $proto, $role ) = @_;
    return !!1 if $roles{$role};
    return $proto->SUPER::DOES( $role );
  }

  sub new {
    my ( $class, %spec ) = @_;
    die "missing name"       unless exists $spec{name};
    die "missing constraint" unless exists $spec{constraint};
    return bless \%spec => $class;
  }

  sub check {
    my ( $param, $value ) = ( shift, @_ );
    if ( $param->{parent} ) {
      return !!0 unless $param->{parent}->check( $value );
    }
    local $_ = $value;
    return $param->{constraint}->( $value );
  }

  sub get_message {
    my ( $param, $value ) = ( shift, @_ );
    $value = ref( $value )     ? ( "Reference " . $value )
           : defined( $value ) ? ( "Value " . B::perlstring( $value ) )
           :                       "Undef";
    return $value . ' did not pass type constraint "' . $param->{name} . '"';
  }

  sub can_be_inlined {
    my $param = shift;
    return ref( $param->{inlined} ) eq 'CODE';
  }

  sub inline_check {
    my ( $param, $name ) = ( shift, @_ );
    return unless defined( $name ) && !ref( $name ) && length( $name );
    return unless ref( $param->{inlined} ) eq 'CODE';
    return $param->{inlined}->( $param, $name );
  }

  sub name       { shift->{name} }
  sub parent     { shift->{parent} }
  sub constraint { shift->{constraint} }

  use overload
    'bool' => sub { 1 },
    '""'   => sub { shift->{name} },
    '&{}'  => sub {
        my $param = shift;
        return sub {
          my ( $value ) = @_;
          $param->check( $value ) 
            or Carp::croak( $param->get_message( $value ) );
        };
    },
    fallback => 1;

}

# ----------------------------------------------------------------------
# Primitive constraints
# ----------------------------------------------------------------------

sub is_Any               ($) { 1 }
sub is_Item              ($) { 1 }
sub is_Undef             ($) { !defined($_[0]) }
sub is_Defined           ($) { defined($_[0]) }
sub is_Value             ($) { defined($_[0]) && !ref($_[0]) }
sub is_Str               ($) { defined($_[0]) && ref(\$_[0]) eq 'SCALAR' }
sub is_Bool              ($) { !defined($_[0]) || $_[0] =~ /\A[01]?\z/ }
sub is_Num               ($) { looks_like_number($_[0]) }
sub is_Int               ($) { defined($_[0]) && $_[0] =~ /\A-?\d+\z/ }
sub is_PositiveInt       ($) { defined($_[0]) && $_[0] =~ /\A[1-9]\d*\z/ }
sub is_PositiveOrZeroInt ($) { defined($_[0]) && $_[0] =~ /\A\d+\z/ }
sub is_Object            ($) { blessed($_[0]) }

# ----------------------------------------------------------------------
# Ref constraints
# ----------------------------------------------------------------------

sub is_Ref               ($) { !!ref($_[0]) }
sub is_ScalarRef         ($) { ref($_[0]) eq 'SCALAR' || ref($_[0]) eq 'REF' }
sub is_ArrayRef          ($) { ref($_[0]) eq 'ARRAY' }
sub is_HashRef           ($) { ref($_[0]) eq 'HASH' }
sub is_CodeRef           ($) { ref($_[0]) eq 'CODE' }
sub is_GlobRef           ($) { ref($_[0]) eq 'GLOB' }

# ----------------------------------------------------------------------
# Special constraints
# ----------------------------------------------------------------------

sub is_ClassName ($) {
  my ( $value ) = @_;
  # is_Str and not empty (or zero)
  return !!0 unless $value && ref( \$value ) eq 'SCALAR';

  # We manually check the stash
  no strict 'refs';
  my $stash = \%{"$value\::"};

  # The Package must have @ISA ..
  return !!1 if exists $stash->{'ISA'} 
             && *{ $stash->{'ISA'} }{ARRAY} 
             && @{"$value\::ISA"};

  # .. or $VERSION ..
  return !!1 if exists $stash->{'VERSION'};

  # .. or must define at least one sub
  foreach my $symbol ( values %$stash ) {
    return !!1
      if is_GlobRef( \$symbol )
      ? *{$symbol}{CODE}
      : ref $symbol;    # const or sub ref
  }

  return !!0;
}

sub is_FileHandle ($) {
  return !!1 if ref($_[0]) && openhandle($_[0]);
  return !!1 if blessed($_[0]) && $_[0]->isa( "IO::Handle" );
  return !!0;
}

sub is_ArrayLike ($) { defined($_[0]) && reftype($_[0]) eq 'ARRAY' }
sub is_HashLike  ($) { defined($_[0]) && reftype($_[0]) eq 'HASH' }

# ----------------------------------------------------------------------
# Type constructors (non-parametric)
# ----------------------------------------------------------------------

our %TYPES;

sub Any () {
  $TYPES{Any} ||= TUI::Type::Object->new(
    name       => 'Any',
    constraint => \&is_Any,
    inlined    => sub { "1" },
  );
}

sub Item () {
  $TYPES{Item} ||= TUI::Type::Object->new(
    name       => 'Item',
    parent     => Any,
    constraint => \&is_Item,
    inlined    => sub { "1" },
  );
}

sub Undef () {
  $TYPES{Undef} ||= TUI::Type::Object->new(
    name       => 'Undef',
    parent     => Item,
    constraint => \&is_Undef,
    inlined    => sub { "!defined($_[1])" },
  );
}

sub Defined () {
  $TYPES{Defined} ||= TUI::Type::Object->new(
    name       => 'Defined',
    parent     => Item,
    constraint => \&is_Defined,
    inlined    => sub { "defined($_[1])" },
  );
}

sub Value () {
  $TYPES{Value} ||= TUI::Type::Object->new(
    name       => 'Value',
    parent     => Defined,
    constraint => \&is_Value,
    inlined    => sub { "defined($_[1]) && !ref($_[1])" },
  );
}

sub Bool () {
  $TYPES{Bool} ||= TUI::Type::Object->new(
    name       => 'Bool',
    parent     => Item,
    constraint => \&is_Bool,
    inlined    => sub { "do { local \$_ = $_[1]; !defined || /\\A[01]?\\z/ }" },
  );
}

sub Str () {
  $TYPES{Str} ||= TUI::Type::Object->new(
    name       => 'Str',
    parent     => Value,
    constraint => \&is_Str,
    inlined    => sub {
      "do { local \$_ = $_[1]; defined && ref \\\$_ eq 'SCALAR' }"
    },
  );
}

sub ClassName () {
  $TYPES{ClassName} ||= TUI::Type::Object->new(
    name       => 'ClassName',
    parent     => Str,
    constraint => \&is_ClassName,
  );
}

sub Num () {
  $TYPES{Num} ||= TUI::Type::Object->new(
    name       => 'Num',
    parent     => Value,
    constraint => \&is_Num,
    inlined    => sub { 
      "do { require Scalar::Util; Scalar::Util::looks_like_number($_[1]) }"
    },
  );
}

sub Int () {
  $TYPES{Int} ||= TUI::Type::Object->new(
    name       => 'Int',
    parent     => Num,
    constraint => \&is_Int,
    inlined    => sub { "do { local \$_ = $_[1]; defined && /\\A-?\\d+\\z/ }" },
  );
}

sub PositiveInt () {
  $TYPES{PositiveInt} ||= TUI::Type::Object->new(
    name       => 'PositiveInt',
    parent     => Int,
    constraint => \&is_PositiveInt,
    inlined    => sub {
      "do { local \$_ = $_[1]; defined && /\\A[1-9]\\d*\\z/ }"
    },
  );
}

sub PositiveOrZeroInt () {
  $TYPES{PositiveOrZeroInt} ||= TUI::Type::Object->new(
    name       => 'PositiveOrZeroInt',
    parent     => Int,
    constraint => \&is_PositiveOrZeroInt,
    inlined    => sub { "do { local \$_ = $_[1]; defined && /\\A\\d+\\z/ }" },
  );
}

sub Object () {
  $TYPES{Object} ||= TUI::Type::Object->new(
    name       => 'Object',
    parent     => Ref(),
    constraint => \&is_Object,
    inlined    => sub { 
      "do { require Scalar::Util; Scalar::Util::blessed($_[1]) }"
    },
  );
}

sub CodeRef () {
  $TYPES{CodeRef} ||= TUI::Type::Object->new(
    name       => 'CodeRef',
    parent     => Ref(),
    constraint => \&is_CodeRef,
    inlined    => sub { "ref($_[1]) eq 'CODE'" },
  );
}

sub GlobRef () {
  $TYPES{GlobRef} ||= TUI::Type::Object->new(
    name       => 'GlobRef',
    parent     => Ref(),
    constraint => \&is_GlobRef,
    inlined    => sub { "ref($_[1]) eq 'GLOB'" },
  );
}

sub FileHandle () {
  $TYPES{FileHandle} ||= TUI::Type::Object->new(
    name       => 'FileHandle',
    parent     => Ref(),
    constraint => \&is_FileHandle,
  );
}

# ----------------------------------------------------------------------
# Type constructors (parametric)
# ----------------------------------------------------------------------

sub Maybe ($) {
  my ( $param ) = @_;
  my $type = $TYPES{Maybe} ||= TUI::Type::Object->new(
    name       => 'Maybe',
    parent     => Item,
    constraint => \&is_Any,
  );

  return _param_type(
    name      => 'Maybe',
    param      => $param, 
    parent     => $type,
    constraint_generator => sub {
      my ( $inner ) = @_;
      return sub {
        my ( $value ) = @_;
        return !!1 unless defined $value;
        return $inner->check( $value );
      };
    },
  );
}

sub Ref (;$) {
  my $type = $TYPES{Ref} ||= TUI::Type::Object->new(
    name       => 'Ref',
    parent     => Defined,
    constraint => \&is_Ref,
    inlined    => sub { "!!ref($_[1])" },
  );
  return $type unless @_;

  my ( $param ) = @_;
  return _param_type(
    name      => 'Ref',
    param      => $param, 
    parent     => $type,
    constraint_generator => sub {
      my ( $inner ) = @_;
      return sub {
        my ( $ref ) = @_;
        SWITCH: for ( ref $ref ) {
          /SCALAR/ and do {
            return !!0 unless $inner->check( $$ref );
            last;
          };
          /ARRAY/ and do {
            foreach ( @$ref ) { 
              return !!0 unless $inner->check( $_ );
            }
            last;
          };
          /HASH/ and do {
            foreach ( values %$ref ) { 
              return !!0 unless $inner->check( $_ );
            }
            last;
          };
          DEFAULT: {
            return !!0;
          }
        };
        return !!1;
      };
    },
  );
}

sub ScalarRef (;$) {
  my $type = $TYPES{ScalarRef} ||= TUI::Type::Object->new(
    name       => 'ScalarRef',
    parent     => Ref,
    constraint => \&is_ScalarRef,
    inlined    => sub { "ref($_[1]) eq 'SCALAR' || ref($_[1]) eq 'REF'" },
  );
  return $type unless @_;

  my ( $param ) = @_;
  return _param_type(
    name       => 'ScalarRef',
    param      => $param, 
    parent     => $type,
    constraint_generator => sub {
      my ( $inner ) = @_;
      return sub {
        my ( $ref ) = @_;
        return !!0 unless is_ScalarRef( $ref );
        return !!0 unless $inner->check( $$ref );
        return !!1;
      };
    },
  );
}

sub ArrayRef (;$) {
  my $type = $TYPES{ArrayRef} ||= TUI::Type::Object->new(
    name       => 'ArrayRef',
    parent     => Ref,
    constraint => \&is_ArrayRef,
    inlined    => sub { "ref($_[1]) eq 'ARRAY'" },
  );
  return $type unless @_;

  my ( $param ) = @_;
  return _param_type( 
    name       => 'ArrayRef',
    param      => $param,
    parent     => $type,
    constraint_generator => sub {
      my ( $inner ) = @_;
      return sub {
        my ( $ref ) = @_;
        return !!0 unless is_ArrayRef( $ref );
        foreach ( @$ref ) { 
          return !!0 unless $inner->check( $_ );
        }
        return !!1;
      };
    },
  );
}

sub HashRef (;$) {
  my $type = $TYPES{HashRef} ||= TUI::Type::Object->new(
    name       => 'HashRef',
    parent     => Ref,
    constraint => \&is_HashRef,
    inlined    => sub { "ref($_[1]) eq 'HASH'" },
  );
  return $type unless @_;

  my ( $param ) = @_;
  return _param_type( 
    name       => 'HashRef',
    param      => $param,
    parent     => $type,
    constraint_generator => sub {
      my ( $inner ) = @_;
      return sub {
        my ( $ref ) = @_;
        return !!0 unless is_HashRef( $ref );
        foreach ( values %$ref ) { 
          return !!0 unless $inner->check( $_ );
        }
        return !!1;
      };
    },
  );
}

sub ArrayLike (;$) {
  my $type = $TYPES{ArrayLike} ||= TUI::Type::Object->new(
    name       => 'ArrayLike',
    parent     => Ref,
    constraint => \&is_ArrayLike,
    inlined    => sub { 
      "do { require Scalar::Util; Scalar::Util::reftype($_[1]) eq 'ARRAY' }"
    },
  );
  return $type unless @_;

  my ( $param ) = @_;
  return _param_type(
    name       => 'ArrayLike',
    param      => $param,
    parent     => $type,
    constraint_generator => sub {
      my ( $inner ) = @_;
      return sub {
        my ( $ref ) = @_;
        return !!0 unless is_ArrayLike( $ref );
        foreach ( @$ref ) { 
          return !!0 unless $inner->check( $_ );
        }
        return !!1;
      };
    },
  );
}

sub HashLike (;$) {
  my $type = $TYPES{HashLike} ||= TUI::Type::Object->new(
    name       => 'HashLike',
    parent     => Ref,
    constraint => \&is_HashLike,
    inlined    => sub { 
      "do { require Scalar::Util; Scalar::Util::reftype($_[1]) eq 'HASH' }"
    },
  );
  return $type unless @_;

  my ( $param ) = @_;
  return _param_type( 
    kind       => 'HashLike', 
    param      => $param, 
    parent     => $type,
    constraint_generator => sub {
      my ( $inner ) = @_;
      return sub {
        my ( $ref ) = @_;
        return !!0 unless is_HashLike( $ref );
        foreach ( values %$ref ) { 
          return !!0 unless $inner->check( $_ );
        }
        return !!1;
      };
    },
  );
}

sub InstanceOf (;$) {
  my $type = $TYPES{InstanceOf} ||= TUI::Type::Object->new(
    name       => 'InstanceOf',
    parent     => Object,
    constraint => \&is_Object,
    inlined    => sub { 
      "do { require Scalar::Util; Scalar::Util::blessed($_[1]) }"
    },
  );
  return $type unless @_;

  my ( $param ) = @_;
  Carp::croak "Expects param to be an array reference"
    unless is_ArrayRef( $param );
  Carp::croak "Expects a string as inner type"
    if grep { not is_Str( $_ ) } @$param;

  # If only one parameter is given, we can generate a simple type
  if ( @$param == 1 ) {
    my $class = shift @$param;
    return $TYPES{CLASS}{$class} ||= TUI::Type::Object->new(
      name       => $class,
      parent     => Object,
      constraint => sub { $_->isa( $class ) },
      inlined    => sub {
        "do { require Scalar::Util; " .
            "Scalar::Util::blessed($_[1]) && $_[1]->isa(q[$class]) }"
      },
    );
  }

  # Generate a union type that accepts any of the given classes
  my @classes = @$param;
  return TUI::Type::Object->new(
    name       => '__ANON__',
    parent     => Object,
    constraint => sub {
      !! grep { $_[0]->isa( $_ ) } @classes;
    },
  );
}

# ----------------------------------------------------------------------
# Parametric core
# ----------------------------------------------------------------------

sub _param_type {
  my ( %args ) = @_;
  my $kind    = $args{name};
  my $ref     = $args{param};
  my $parent  = $args{parent};
  my $builder = $args{constraint_generator};

  # Basic checks
  Carp::croak "Missing required argument 'name'"
    unless defined $kind;
  Carp::croak "Missing required argument 'param'"
    unless defined $ref;
  Carp::croak "Missing required argument 'constraint_generator'"
    unless defined $builder;

  # Check argument types
  Carp::croak "Expects name to be a string"
    unless is_Str( $kind );
  Carp::croak "Expects constraint_generator to be a code ref" 
    unless is_CodeRef( $builder );
  Carp::croak "Expects param to be an array reference"
    unless is_ArrayRef( $ref );
  Carp::croak "Expects param array ref to hold exactly one type"
    unless @$ref == 1;

  # Check if inner is a Type-API style object
  my ( $inner ) = @$ref;
  Carp::croak "Expects a type constraint object as inner type"
    unless blessed( $inner ) && $inner->can( 'check' );

  my $a = $inner->{name} || '__ANON__';

  # Generate the type object
  return TUI::Type::Object->new(
    name       => "$kind\[$a\]",
    parent     => $parent,
    constraint => $builder->( $inner ),
  );
}

1

__END__

=pod

=head1 NAME

TUI::toolkit::Types - Type constraints without non-core Perl dependencies

=head1 SYNOPSIS

Simple type check

  use TUI::toolkit::Types qw( Int );
  
  my $t = Int;
  say $t->check(42);      # true
  say $t->check("no");    # false

Parametric usage

  use TUI::toolkit::Types qw( ArrayRef Int );
  
  my $t = ArrayRef([ Int ]);
  $t->check([1,2,3]);    # ok
  $t->check([1,"x"]);    # fails
  
Using types with L<TUI::toolkit::Params> signatures

  use TUI::toolkit::Types qw( :Int );
  use Type::Params qw( signature );
  
  sub add_numbers {
    state $sig = signature(
      pos => [
        Int,                # our Type::API compatible type object
        sub { /^\d+$/ },    # custom CODE
      ],
    );

    my ($x, $y) = $sig->(@_);
    return $x + $y;
  }
  
  say add_numbers(40, 2);  # 42

=head1 DESCRIPTION

C<TUI::toolkit::Types> provides a set of lightweight type constraints that are
compatible with C<Type::API> and mimic much of the behavior of L<MooseX::Types> 
and L<Types::Standard>, but without depending on XS or any non-core Perl 
modules.

All types behave as true type objects: they support checking a value, 
generating error messages, stringification, and executable-code overloading. 
The implementation avoids all non-core modules.

For each type, two function forms may exist:

=over 4

=item * Constructor - returns a type object (e.g. C<Int>)

=item * Predicate - low-level boolean checker (e.g. C<is_Int>)

=back

Beside that collection of primitive, reference, and numeric type constraints, 
this module including basic support for parameterized types such as 
C<ArrayRef[Int]> or C<Maybe[Str]>.

=head1 INCLUDED TYPES

The following types correspond closely to the types found in
L<Types::Standard> and L<MooseX::Types::Common::Numeric>.

=head2 Primitive Types

=over 4

=item * C<Any>

Accepts any Perl value.

=item * C<Item>

Synonym for C<Any>; matches any single Perl value.

=item * C<Undef>

Accepts only C<undef>.

=item * C<Defined>

Accepts any defined value.

=item * C<Value>

Accepts defined, non-reference scalar values.

=item * C<Bool>

Accepts C<undef>, the empty string C<"">, C<"0">, or C<"1">.

=item * C<Str>

Accepts normal Perl strings; excludes globs and v-strings.

=item * C<ClassName>

Accepts valid Perl package names, either because C<@ISA> or C<$VERSION> exist, 
or because it exists with at least one subroutine in the symbol table.

=item * C<Num>

Accepts values for which C<looks_like_number> is true.

=item * C<Int>

Accepts integer values (including negative numbers and zero).

=back

=head2 Numeric Special Types

Modeled after L<MooseX::Types::Common::Numeric>:

=over 4

=item * C<PositiveInt>

Integer strictly greater than zero.

=item * C<PositiveOrZeroInt>

Integer greater than or equal to zero.

=back

=head2 Reference Types

=over 4

=item * C<Ref>

Any reference.

=item * C<ArrayRef>

Array reference. Parameterizable.

=item * C<HashRef>

Hash reference. Parameterizable.

=item * C<ScalarRef>

Accepts scalar references. Parameterizable.

=item * C<CodeRef>

Subroutine reference.

=item * C<GlobRef>

Glob reference.

=item * C<FileHandle>

Matches Perl filehandle-like entities or L<IO::Handle>-based objects.

=item * C<Object>

Any blessed reference.

=item * C<HashLike>

Accepts hash and blessed hash references.

=item * C<ArrayLike>

Accepts array and blessed array references.

=back

=head2 Parameterized Types

The following parameterized types accept exactly one constraint as parameter:

=over 4

=item * C<Maybe[$type]>

Accepts C<undef> or a value satisfying C<$type>.

=item * C<Ref[$type]>

Checks each referenced element (useful for array-like structures).

=item * C<ArrayRef[$type]>

Checks each array element.

=item * C<HashRef[$type]>

Checks each hash I<value> (keys are not verified).

=item * C<ScalarRef[$type]>

Checks the referent.

=back

Additional parameterized types:

=over 4

=item * C<Instance[$packages]>

Checks whether at least one package is an object instance of these classes.

=back

=head1 TYPE RELATIONSHIPS

A simplified, L<Types::Tiny>-compatible parent-child hierarchy is used:

  Any
   +-- Item
        +-- Undef
        +-- Defined
        |    +-- Value
        |    |    +-- Bool
        |    |    +-- Str
        |    |    |    +-- ClassName
        |    |    +-- Num
        |    |         +-- Int
        |    |              +-- PositiveInt
        |    |              +-- PositiveOrZeroInt
        |    +-- Ref
        |         +-- ScalarRef
        |         +-- ArrayRef
        |         +-- HashRef
        |         +-- CodeRef
        |         +-- GlobRef
        |         +-- Object
        |              +-- InstanceOf
        |         +-- FileHandle
        |         +-- ArrayLike
        |         +-- HashLike
        +-- Maybe

B<Note>: Although conceptually similar, C<Item> and C<Any> are implemented in
a parent-child relationship.

=head1 PREDICATE FUNCTIONS

Every type also has a low-level predicate function C<is_*>.

Predicates:

=over 4

=item * accept a single value,

=item * return a boolean,

=item * do not throw exceptions.

=back

=head2 Predicate example

Predicate functions are well-suited for assertion frameworks or any
situation where a simple boolean check is needed without throwing
exceptions.

For example, using L<PerlX::Assert> or L<Devel::Assert>:

  use PerlX::Assert -check;
  # use Devel::Assert 'on';
  use TUI::toolkit::Types qw( is_Int );

  my $value = 123;

  # predicate types inside an assertion
  assert ( is_Int $value );    # passes

  $value = 'x';
  assert ( is_Int $value );    # fails with an assertion error

=head1 EXPORT TAGS

This module supports the following export groups:

=over 4

=item * C<:types>

Exports all type constructor functions.

=item * C<:is>

Exports all C<is_*> low-level predicate functions.

=item * C<:all>

Exports everything this module provides.

=item * Type-specific (e.g. C<:Str>, C<:Object>, ...)

Each individual type constructor also has its own export group containing: 

  Type constructor, Checker, Predicate

For example:

  :Str       # exports Str, is_Str
  :Object    # exports Object, is_Object
  :Int       # exports Int, is_Int
  :ArrayRef  # exports ArrayRef, is_ArrayRef

This allows importing exactly one type without its siblings.

=back

=head1 LIMITATIONS

Despite being conceptually similar to L<Types::Standard>, this module 
intentionally keeps its feature set simple:

=head2 Only single-parameter parametric types are supported

No multi-parameter types such as C<Map[Key,Value]> or C<Tuple[A,B,C]>.

=head2 No coercion system

No coercions are implemented. All checks are strict boolean validations.

=head2 Parameterized validation is shallow

ArrayRef and HashRef validate elements only one level deep unless the
user nests parameterized types manually.

=head2 Keys of HashRef are not validated

Only values are checked.

=head2 ClassName detection is minimalistic

It relies on:

=over 4

=item * package has been loaded, or

=item * symbol table existence,

=item * presence of C<@ISA>, C<$VERSION>, or any subroutine.

=back

No advanced object or meta introspection is performed.

=head2 FileHandle detection is conservative

User-defined file handle-like objects must be based on L<IO::Handle>.

=head2 Overloading is not interpreted as a type hint

Overloaded stringification, boolean context, or code reification does not
influence type acceptance. Only concrete Perl data types are recognized.

=head2 Compared to other, this module is intentionally smaller but slower

L<Type::Tiny> provides many advanced features such as:

=over 4

=item * comprehensive type libraries

=item * deep coercion systems

=item * complex parameterized types (Tuple, Dict, Map, etc.)

=item * fully integration with Moose, Moo, and other ecosystems

=item * performance optimizations

=back

Because L<Type::Tiny> uses XS for many fast paths, it is significantly faster 
than this module in most scenarios. However, this also introduces additional 
installation requirements and non-core dependencies.

In contrast, C<TUI::toolkit::Types> is:

=over 4

=item * fully pure-Perl

=item * dependency-free

=item * deliberately minimalistic

=item * optimized for portability over raw speed

If maximum performance or advanced type features are required, L<Type::Tiny> is 
the more capable option.

=back

=head1 REQUIRES

Only core modules are used:

=over 4

=item * Perl 5.10+

=item * L<B>

=item * L<Carp>

=item * L<Exporter>

=item * L<Scalar::Util>

=back

=head1 SEE ALSO

=over 4

=item * L<Type::API>

=item * L<Types::Standard>

=item * L<Types::TypeTiny>

=item * L<MooseX::Types::Common::Numeric>

=back

=head1 AUTHOR

J. Schneider E<lt>brickpool@cpan.orgE<gt>

=head1 CONTRIBUTORS

Toby Inkster E<lt>tobyink@cpan.orgE<gt>

=head1 LICENSE

Copyright (c) 2013-2014, 2017-2026 the L</AUTHORS> and L</CONTRIBUTORS> as 
listed above.

This is free software; you may redistribute it and/or modify it under the
same terms as the Perl 5 programming language system itself.

=cut
