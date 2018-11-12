package MooX::Attributes::Shadow;

# ABSTRACT: shadow attributes of contained objects

use strict;
use warnings;

our $VERSION = '0.05';

use Carp ();
use Params::Check;
use Scalar::Util;

use Exporter 'import';

our %EXPORT_TAGS = ( all => [ qw( shadow_attrs shadowed_attrs xtract_attrs ) ],
                   );
Exporter::export_ok_tags('all');

my %MAP;

## no critic (ProhibitAccessOfPrivateData)

sub shadow_attrs {

    my $contained = shift;

    my $container = caller;

    my $args = Params::Check::check( {
            fmt => {
                allow => sub { ref $_[0] eq 'CODE' }
            },

            attrs => { allow => sub { 'ARRAY' eq ref $_[0] && @{ $_[0] }
                                        or 'HASH' eq ref $_[0] },
                     },
            private  => { default => 1 },
            instance => {},
        },
        {@_} ) or Carp::croak( "error parsing arguments: ", Params::Check::last_error, "\n" );


    unless ( exists $args->{attrs} ) {

        $args->{attrs} = [ eval { $contained->shadowable_attrs } ];

        Carp::croak( "must specify attrs or call shadowable_attrs in shadowed class" )
          if $@;

    }

    my $has = $container->can( 'has' )
      or Carp::croak( "container class $container does not have a 'has' function.",
                " Is it really a Moo class?" );

    my %attr =
      'ARRAY' eq ref $args->{attrs} ? ( map { $_ => undef } @{$args->{attrs}} )
                                   : %{$args->{attrs}};

    my %map;
    while( my ( $attr, $alias ) = each %attr ) {

        $alias = $args->{fmt} ? $args->{fmt}->( $attr ) : $attr
          unless defined $alias;

        my $priv  = $args->{private} ? "_shadow_${contained}_${alias}" : $alias;
        $priv =~ s/::/_/g;
        $map{$attr} = { priv => $priv, alias => $alias };

        ## no critic (ProhibitNoStrict)
        no strict 'refs';
        $has->(
            $priv => (
                is        => 'ro',
                init_arg  => $alias,
                predicate => "_has_${priv}",
            ) );

    }

    if ( defined $args->{instance} ) {

        $MAP{$contained}{$container}{instance}{ $args->{instance} } = \%map;

    }

    else {

        $MAP{$contained}{$container}{default} = \%map;

    }

    return;
}

sub _resolve_attr_env {

    my ( $contained, $container, $options ) = @_;

    # contained should be resolved into a class name
    my $containedClass = Scalar::Util::blessed $contained || $contained;

    # allow $container to be either a class or an object
    my $containerClass = Scalar::Util::blessed $container || $container;

    my $map = defined $options->{instance}
            ? $MAP{$containedClass}{$containerClass}{instance}{$options->{instance}}
            : $MAP{$containedClass}{$containerClass}{default};

    Carp::croak( "attributes must first be shadowed using ${containedClass}::shadow_attrs\n" )
      unless defined $map;

    return $map;
}

# call as
# shadowed_attrs( $ContainedClass, [ $container ], \%options)

sub shadowed_attrs {

    my $containedClass = shift;
    my $options = 'HASH' eq ref $_[-1] ? pop() : {};

    my $containerClass = @_ ? shift : caller();

    my $map = _resolve_attr_env( $containedClass, $containerClass, $options );

    return { map { $map->{$_}{alias}, $_ } keys %$map }
}

# call as
# xtract_attrs( $ContainedClass, $container_obj, \%options)
sub xtract_attrs {

    my $containedClass = shift;
    my $options = 'HASH' eq ref $_[-1] ? pop() : {};
    my $container = shift;
    my $containerClass = Scalar::Util::blessed $container or
      Carp::croak( "container_obj parameter is not a container object\n" );

    my $map = _resolve_attr_env( $containedClass, $containerClass, $options );

    my %attr;
    while( my ($attr, $names) = each %$map ) {

        my $priv = $names->{priv};
        my $has = "_has_${priv}";

        $attr{$attr} = $container->$priv
          if $container->$has;
    }

    return %attr;
}

1;

#
# This file is part of MooX-Attributes-Shadow
#
# This software is Copyright (c) 2018 by Smithsonian Astrophysical Observatory.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#

__END__

=pod

=for :stopwords Diab Jerius Smithsonian Astrophysical Observatory Inkster

=head1 NAME

MooX::Attributes::Shadow - shadow attributes of contained objects

=head1 VERSION

version 0.05

=head1 SYNOPSIS

  # shadow Foo's attributes in Bar
  package Bar;

  use Moo;
  use Foo;

  use MooX::Attributes::Shadow ':all';

  # create attributes shadowing class Foo's a and b attributes, with a
  # prefix to avoid collisions.
  shadow_attrs( Foo => attrs => { a => 'pfx_a', b => 'pfx_b' } );

  # create an attribute which holds the contained oject, and
  # delegate the shadowed accessors to it.
  has foo   => ( is => 'ro',
                 lazy => 1,
                 default => sub { Foo->new( xtract_attrs( Foo => shift ) ) },
                 handles => shadowed_attrs( Foo ),
               );

  $a = Bar->new( pfx_a => 3 );
  $a->pfx_a == $a->foo->a;

=head1 DESCRIPTION

If an object contains another object (i.e. the first object's
attribute is a reference to the second), it's often useful to access
the contained object's attributes as if they were in the container
object.

B<MooX::Attributes::Shadow> provides a means of registering the
attributes to be shadowed, automatically creating proxy attributes in
the container class, and easily extracting the shadowed attributes and
values from the container class for use in the contained class's
constructor.

A contained class can use B<MooX::Attributes::Shadow::Role> to
simplify things even further, so that container classes using it need
not know the names of the attributes to shadow.  This is the preferred
approach.

=head2 The Problem

An object in class C<A> (C<$a>) has an attribute (C<< $a->b >>) which
contains a reference to an object in class C<B> (C<$b>), which itself
has an attribute C<< $b->attr >>, which you want to transparently
access from C<$a>, e.g.

  $a->attr => $a->b->attr;

One approach might be to use method delegation:

  package B;

  has attr => ( is => 'rw' );

  package A;

  has b => (
     is => 'ro',
     default => sub { B->new },
     handles => [ 'attr' ]
   );

  $a = A->new;

  $a->attr( 3 ); # works!

But, what if C<attr> is a required parameter to C<B>'s constructor?  The
default generator might look something like this:

  has b => (
     is => 'ro',
     lazy => 1,
     default => sub { B->new( shift->attr ) },
     handles => [ 'attr' ]
   );

  $a = A->new( attr => 3 );  # doesn't work!

(Note that C<b> now must be lazily created, so that C<$a> is in a
deterministic state when asked for the value of C<attr>).

However, this doesn't work, because C<$a> doesn't have an attribute
called C<attr>; that's just a method delegated to C<< $a->b >>. Oops.

If you don't mind explicitly calling C<< B->new >> in C<A>'s constructor,
this works:

  sub BUILDARGS {

    my $args = shift->SUPER::BUILDARGS(@_);

    $args->{b} //= B->new( attr => delete $args->{attr} );

    return $args;
  }

  $a = A->new( attr => 3 );  # works!

but now C<b> can't be lazily constructed.  To achieve that requires
actually storing C<attr> in C<$a>.  We can do that with a proxy
attribute which masquerades as C<attr> in C<A>'s constructor:

  has _attr => ( is => 'ro', init_arg => 'attr' );

  has b => (
     is => 'ro',
     lazy => 1,
     default => sub { B->new( shift->_attr ) },
     handles => [ 'attr' ]
   );

  $a = A->new( attr => 3 );  #  works!

Simple, but what happens if

=over

=item *

there's more than one attribute, or

=item *

there's more than one instance of C<B> to construct, or

=item *

C<A> has it's own attribute named C<attr>?

=back

Endless tedium and no laziness, that's what.  Hence this module.

=head1 INTERFACE

=over

=item B<shadow_attrs>

   shadow_attrs( $contained_class, attrs => \%attrs, %options );
   shadow_attrs( $contained_class, attrs => \@attrs, %options );

Create read-only attributes for the attributes in C<attrs> and
associate them with C<$contained_class>.  There is no means of
specifying additional attribute options.

If C<attrs> is a hash, the keys are the attribute names in the
contained class and the values are the shadowed names in the container
class.  Set the value to C<undef> to retain the original name.  For
example,

  { a => 'pfx_a', b => undef }

The contained class's C<a> attribute is shadowed as C<pfx_a> in the
container class, while the C<b> attribute is named the same in both
classes.

If C<attrs> is an array, the attributes in the container class are
named the same as in the contained class.

The following options are available:

=over

=item fmt

This is a reference to a subroutine which should return a modified
attribute name (e.g. to prevent attribute collisions).  It is passed
the attribute name as its first parameter.  If the C<attrs> parameter
was passed as a hash, attributes with defined shadowed names are
not passed to C<fmt>

=item instance

In the case where more than one instance of an object is contained,
this (string) is used to identify an individual instance.

=item private

If true, the actual attribute name is mangled; the attribute
initialization name is left untouched (see the C<init_arg> option to
the B<Moo> C<has> subroutine).  This defaults to true.

=back

=item B<shadowed_attrs>

  $attrs = shadowed_attrs( $contained, [ $container,] \%options );

Return a hash of attributes shadowed from C<$contained> into
C<$container>.  C<$contained> and C<$container> may either be a class
name or an object. If C<$container> is not specified, the package name
of the calling routine is used.

It takes the following options:

=over

=item instance

In the case where more than one instance of an object is contained,
this (string) is used to identify an individual instance.

=back

The keys in the returned hash are the attribute initialization names
(not the mangled ones) in the I<container> class; the hash values are
the attribute names in the I<contained> class.  This makes it easy to
delegate accessors to the contained class:

  has foo => (
     is => 'ro',
     lazy => 1,
     default => sub { Foo->new( xtract_attrs( Foo => shift ) ) },
     handles => shadowed_attrs( 'Foo' ),
  );

=item B<xtract_attrs>

  %attrs = xtract_attrs( $contained, $container_obj, \%options );

After the container class is instantiated, B<xtract_attrs> is used to
extract attributes for the contained object from the container object.
C<$contained> may be either a class name or an object in the contained
class.

It takes the following options:

=over

=item instance

In the case where more than one instance of an object is contained,
this (string) is used to identify an individual instance.

=back

=back

=head1 THANKS

Toby Inkster for the C<BUILDARGS> approach.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://rt.cpan.org/Public/Dist/Display.html?Name=MooX-Attributes-Shadow>
or by email to
L<bug-MooX-Attributes-Shadow@rt.cpan.org|mailto:bug-MooX-Attributes-Shadow@rt.cpan.org>.

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SOURCE

The development version is on github at L<https://github.com/djerius/moox-attributes-shadow>
and may be cloned from L<git://github.com/djerius/moox-attributes-shadow.git>

=head1 AUTHOR

Diab Jerius <djerius@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Smithsonian Astrophysical Observatory.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
