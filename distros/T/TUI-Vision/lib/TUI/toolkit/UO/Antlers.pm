package TUI::toolkit::UO::Antlers;
# ABSTRACT: Moose-like sugar for the UNIVERSAL::Object based class

use strict;
use warnings;

our $VERSION   = '0.08';
our $AUTHORITY = 'cpan:BRICKPOOL';

use Carp              ();
use Scalar::Util      ();
use UNIVERSAL::Object ();

BEGIN { $] >= 5.010 ? require mro : require MRO::Compat }
BEGIN { 
  *CAN_HAZ_XS = ( !exists $ENV{PERL_ONLY} && !$ENV{PERL_ONLY} &&
                do { eval q[ use Class::XSAccessor ]; !$@ } )
              ? sub() { !!1 }
              : sub() { !!0 }
}

# ----------------------------------------------------------------------
# Export keywords
# ----------------------------------------------------------------------

use Importer ();

our @EXPORT = qw(
  has
  extends
  blessed
  confess
);

# ----------------------------------------------------------------------
# import/unimport for setting up the class and exporting the symbols
# ----------------------------------------------------------------------

sub import {
  my ( $class, @imports ) = @_;
  my $caller = caller(0);

  # Prevent double init per compilation unit
  return if $^H{ __PACKAGE__ . "/$caller" };
  $^H{ __PACKAGE__ . "/$caller" } = 1;

  # Turn on strict/warnings for caller
  strict->import;
  warnings->import;

  # When exporting 'extends', we assume that a class hierarchy exists and 
  # inject the base class if the class in the hierarchy has no parent
  my $exports = Importer->get( $class, @imports );
  if ( $exports->{extends} ) {
    require TUI::toolkit::UO::Base;
    no strict 'refs';
    unshift( @{"${caller}::ISA"}, 'TUI::toolkit::UO::Base' ) 
      unless ( @{"${caller}::ISA"} );
  }

  Importer->import_into( $class, $caller, @imports );
} #/ sub import

sub unimport {
  my ( $class, @imports ) = @_;
  my $caller = caller();

  # TODO: 'unimport' only takes effect one time, 
  # but at least it's consistent with 'import'
  return unless $^H{ __PACKAGE__ . "/$caller" };
  $^H{ __PACKAGE__ . "/$caller" } = 0;

  my $exports = Importer->get( $class, @imports );
  Importer->unimport_from( $caller, keys %$exports );
}

# ----------------------------------------------------------------------
# Public API functions for class setup and field management
# ----------------------------------------------------------------------

sub has {
  my $class = caller( 0 );
  Carp::croak( "has() requires at least one attribute name" )
    unless @_;

  # Case 1: has 'x'
  if ( @_ == 1 ) {
    my ( $name ) = @_;
    Carp::croak( "Attribute name must be a plain string" )
      unless defined $name && !ref $name;

    add_fields( $class, $name => undef );
    add_accessor( $class, $name => 'rw' );
    return;
  }

  # Case 2: has x => ( key => value, ... )
  my ( $name, @rest ) = @_;

  Carp::croak( "has($name) options must be key/value pairs" )
    unless @rest % 2 == 0;

  my %opts = @rest;

  # Check for unknown options and missing values. 
  my %allowed = map { $_ => 1 } qw(is default);
  for my $key ( keys %opts ) {
    Carp::croak("Unknown option '$key' for has($name)")
      unless $allowed{$key};
  }

  my $access = delete $opts{is};
  Carp::croak( "Option 'is' must be 'ro', 'rw' or 'bare' for has($name)" )
    if defined $access && !grep { $_ eq $access } qw( ro rw bare );

  # Prepare default value
  my $default;
  if ( exists $opts{default} ) {
    $default = do {
      my $d = delete $opts{default};
      my $r = ref $d;
      $r eq 'HASH'  ? sub { +{%$d} } :
      $r eq 'ARRAY' ? sub { [@$d] }  :
      $r eq 'CODE'  ? $d             :
                      sub { $d }     ;
    };
  }

  add_fields( $class, $name => $default );
  add_accessor( $class, $name => $access );

  return;
} #/ sub has

# The C<extends> function adds the given parent classes to the caller's C<@ISA>. 
# For example:
#  package Foo; 
#  use TUI::toolkit::UO::Antlers; 
#  extends 'Bar', 'Baz';
sub extends {    # void (@parents)
  my ( @parents ) = @_;
  my $class = caller(0);
  Carp::croak( "No parent classes provided to extends" ) unless @_;

  # like the parent pragma we check if the parents are already loaded and load 
  # them if not. This is required to ensure that the fields are inherited 
  # correctly.
  foreach my $parent ( @parents ) {
    # sanity check for parent class names
    Carp::croak( "Parent class names must be plain strings" )
      unless defined $parent and !ref $parent;

    ( my $file = "$parent.pm" ) =~ s{::}{/}g;
    eval { require $file; 1 }
      or Carp::croak("Failed to load parent class $parent: $@");
  }

  my $isa = do {
    no strict 'refs';
    \@{"${class}::ISA"};
  };

  # Base is always injected by import() as the first entry in @ISA.
  # extends() may remove this early injection if a parent already provides Base.
  if ( grep { $_->isa( 'TUI::toolkit::UO::Base' ) } @parents ) {
    shift( @$isa ) if @$isa && $isa->[0] eq 'TUI::toolkit::UO::Base';
  }

  # get reference to %HAS (create new %HAS if necessary)
  my $has = get_fields( $class );

  # %a: %HAS from this $class (without parents)
  my %b = ();
  %b = ( %b, %{ get_fields( $_ ) } ) 
    for grep { has_fields( $_ ) } reverse @$isa;
  my %a = map { $_ => $has->{$_} } 
    grep { !exists $b{$_} } keys %$has;

  # Add the new parents to @ISA.
  push @$isa, @parents;

  # %b: %HAS from all superclasses (including new parents)
  %b = ();
  %b = ( %b, %{ get_fields( $_ ) } ) 
    for grep { has_fields( $_ ) } reverse @$isa;

  # We have new parent classes, so %HAS must be regenerated
  %$has = ( %b, %a );

  return;
} #/ sub extends

# Alias for re-export 'blessed' and 'confess' like Moo/se does. 
BEGIN {
  *blessed = \&Scalar::Util::blessed;
  *confess = \&Carp::confess;
}

# ----------------------------------------------------------------------
# Utility functions for class setup and field management
# ----------------------------------------------------------------------

# A simple check to see if the given C<$class> has a C<%HAS> hash defined. A 
# simple test like C<defined %{"${class}::HAS"}> will sometimes produce typo 
# warnings because it would create the hash if it was not present before.
sub has_fields {    # $bool ($class)
  my ( $proto ) = @_;
  my $class = ref $proto || $proto;
  Carp::croak( "[ARGS] class must be an object or a plain string" )
    unless defined $class and !ref $class;

  no strict 'refs';
  no warnings 'once';
  return defined *{"${class}::HAS"}{HASH};
}

# Gets a reference to the C<%HAS> hash for the given C<$class>. It will 
# autogenerate a C<%HAS> hash if one doesn't already exist. If you don't want 
# this behavior, be sure to check beforehand with L</has_fields>.
sub get_fields {    # \%HAS ($class)
  my ( $proto ) = @_;
  my $class = ref $proto || $proto;
  Carp::croak( "[ARGS] class must be an object or a plain string" )
    unless defined $class and !ref $class;

  # avoid possible typo warnings
  no strict 'refs';
  %{"${class}::HAS"} = () unless %{"${class}::HAS"};
  return \%{"${class}::HAS"};
}

# Adds a bunch of C<%slots> to the given C<$class>. For example:
#  # Add the public slots 'this' and 'that' to the class Foo
#  require TUI::toolkit::UO::Antlers;
#  TUI::toolkit::UO::Antlers::add_fields( 'Foo', 
#    this => sub { 'foo' },
#    that => sub { 'bar' },
#  );
sub add_fields {    # void ($class, %slots)
  my ( $proto, @slots ) = @_;
  my $class = ref $proto || $proto;
  Carp::croak( "[ARGS] class must be an object or a plain string" )
    unless defined $class and !ref $class;
  Carp::croak( "[ARGS] slots must be provided as key/value pairs" )
    unless @slots % 2 == 0;

  # Quick bail out if nothing is to be added.
  return unless @slots;

  # if %HAS does not exist, it is a base class for which %HAS must be created.
  unless ( has_fields( $class ) ) {
    # Create empty %HAS and get the reference
    my $has = get_fields( $class );

    my $isa = do {
      no strict 'refs';
      \@{"${class}::ISA"};
    };

    # copy all superclass entries to %HAS
    %$has = ( %$has, %{ get_fields( $class ) } ) 
      for grep { has_fields( $_ ) } reverse @$isa;
  }

  my %slots = @slots;
  my $has = get_fields( $class );
  foreach ( keys %slots ) {
    $has->{$_} = ref $slots{$_} eq 'CODE' ? $slots{$_} : eval 'sub { }';
  }

  return;
} #/ sub add_fields

# If you want to create a new accessor, use L</add_accessor>. It ensures that 
# a read/write accessor sub is created (if not already present; 
# C<unless __PACKAGE__->can($field)>). C<$access> is an optional parameter that
# supports the values C<'ro'>, C<'rw'> and C<'bare'>. If not specified, the 
# C<'rw'> access is used.
sub add_accessor {    # void ($class, $field, |$access)
  my ( $class, $field, $access ) = @_;
  $class = ref $class if blessed $class;
  $access = 'rw' unless defined $access;
  Carp::croak( "[ARGS] class must be an object or a plain string" )
    unless defined $class and !ref $class;
  Carp::croak( "[ARGS] field must be a plain string" )
    unless defined $field and !ref $field;
  Carp::croak( "[ARGS] access must be 'ro', 'rw' or 'bare'" )
    if !defined $access 
    || ( $access ne 'ro' && $access ne 'rw' && $access ne 'bare' );

  # Only create accessors unless is 'bare'
  return if $access eq 'bare';

  # Only create accessors unless exists
  return if $class->can( $field );

  # create the accessor and use the XS version if available
  if ( CAN_HAZ_XS ) {
    my $mutator = $access eq 'ro' ? 'getters' : 'accessors';
    Class::XSAccessor->import(
      class => $class,
      $mutator => { $field => $field },
    );
  }
  else {
    my $acc = "${class}::${field}";
    unless ( exists &$acc ) {
      no strict 'refs';
      *$acc = $access eq 'ro'
            ? sub {
                $#_
                  ? Carp::croak( "Usage: ${class}::${field}(self)" )
                  : $_[0]->{$field};
              }
            : sub {
                $#_
                  ? $_[0]->{$field} = $_[1]
                  : $_[0]->{$field};
              }
    } #/ unless ( exists &$acc )
  } #/ else [ if ( CAN_HAZ_XS ) ]

  return;
} #/ sub add_accessor

1;

__END__

=pod

=head1 NAME

TUI::toolkit::UO::Antlers - Moose-like sugar for UNIVERSAL::Object

=head1 VERSION

version 0.08

=head1 DESCRIPTION

L<UNIVERSAL::Object> is a wonderful base class. The author I<Stevan Little> has 
added the pragma L<slots> for practical use, which is based on the L<MOP> 
distribution. In my opinion, this combination made the usage not as 
I<light-footed> as it could be. 

This is why this Module was developed, which does not require the L<MOP> 
distribution.

Similar to the L<fields> pragma, C<TUI::toolkit::UO::Antlers> declares 
individual fields (stored in a global variable C<%HAS>). L<UNIVERSAL::Object> 
is used as the base class, and access methods can be created using an C<has> 
keyword.

This module also recognizes the superclasses of a class and ensures that their 
fields are inherited correctly. Inheritance occurs automatically if you use 
C<extends> to set up the class hierarchy.

=head1 FUNCTIONS

=head2 has

An Moose-like form: C<< has name => ( key => value, ... ) >>, allowing 
additional slot options such as read/write accessors and custom default 
generators.

  has x => ( is => 'rw', default => sub { 1 } );
  has y => ( is => 'ro', default => sub { 2 } );

The form always begins with the has keyword and the name, followed by an 
odd-length list of option/value pairs. Supported options are:

=over 4

=item C<is>

Specifies the accessor type. Allowed values are C<'ro'>, C<'rw'> and C<'bare'>.
If omitted, C<'rw'> is assumed. When available, L<Class::XSAccessor> is used to 
generate the class accessors. If environment variable C<PERL_ONLY> is set, the 
pure Perl implementation will be used.

=item C<default>

A CODE reference that generates the default value for the slot.

=back

=head2 extends

The C<extends> function adds the given parent classes to the caller's C<@ISA>. 
For example:

  package Foo;
  use TUI::toolkit::UO::Antlers;
  extends 'Bar', 'Baz';

=head1 EXPORTS

The following functions are exported by default:

=over 4

=item * L</has>

=item * L</extends>

=item * C<blessed> from L<Scalar::Util>

=item * C<confess> from L<Carp>

=back

It uses L<Exporter> to export the functions C<has>, C<extends>, C<blessed> and 
C<confess>.

=head1 DEPENDENCIES

=over 4

=item * L<Carp>

=item * L<Exporter>

=item * L<MRO::Compat> when using perl < v5.10 

=item * L<Scalar::Util>

=item * L<UNIVERSAL::Object>

=back

=head1 LIMITATIONS

This Module creates the global variable C<%HAS> used by C<UNIVERSAL::Objects>. 
This means that all derived classes will require C<%HAS> (including inherited 
entries), even if no new fields are added. 

The simplest way to achieve this is by consistently using 
C<use TUI::toolkit::UO::Antlers>. The import routine creates the global 
variable C<%HAS> and initializes the necessary entries.

=head1 SEE ALSO

L<UNIVERSAL::Object>, L<Class::Fields::Fuxor>, L<Class::Fields::Inherit>.

=head1 AUTHOR

J. Schneider <brickpool@cpan.org>

=head1 CONTRIBUTORS

Stevan Little <stevan@cpan.org>

Michael G Schwern <schwern@pobox.com>

=head1 LICENSE

Copyright (c) 2024-2026 the L</AUTHORS> and L</CONTRIBUTORS> as listed above.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
