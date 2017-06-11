package MooX::PDL2;

# ABSTRACT: A Moo based PDL 2.X object

use strict;
use warnings;

our $VERSION = '0.01';

use Scalar::Util qw[ blessed weaken ];
use PDL::Lite;
use Carp;

use Moo;
use MooX::ProtectedAttributes;

use namespace::clean;

# do not simply extend PDL on its own.

#  We want a standard Moo constructor, but everything else from
#  PDL. PDLx::DetachedObject gives us
#
#  * PDL inheritance;
#  * a generic initializer() class method; and
#  * a constructor.
#
# The constructor is ignored by Moo as Moo::Object is the first
# in the inheritance chain and it ignores upstream constructors.

extends 'Moo::Object', 'PDLx::DetachedObject';

#pod =attr _PDL
#pod
#pod The actual piddle associated with an object.  B<PDL> routines
#pod will transparently uses this when passed an object.
#pod
#pod This attribute is
#pod
#pod =over
#pod
#pod =item *
#pod
#pod lazy
#pod
#pod =item *
#pod
#pod has a builder which returns C<< PDL->null >>
#pod
#pod =item *
#pod
#pod will coerce its argument to be a piddle
#pod
#pod =item *
#pod
#pod has a clearer
#pod
#pod =back
#pod
#pod See L</EXAMPLES> for fun ways of combining it with Moo's facilities.
#pod
#pod =cut

protected_has _PDL => (
    is  => 'lazy',
    isa => sub {
        blessed $_[0] && blessed $_[0] eq 'PDL'
          or croak( "_PDL attribute must be of class 'PDL'" );
    },
    coerce  => sub { PDL->topdl( $_[0] ) },
    builder => sub { PDL->null },
    clearer => 1,
);

protected_has PDL => (
    is       => 'ro',
    init_arg => undef,
    default  => sub {
        my $self = shift;
        weaken $self;
        sub { $self->_PDL };
    },
);

namespace::clean->clean_subroutines( __PACKAGE__, 'PDL' );

#pod =method new
#pod
#pod   # null value
#pod   $pdl = MooX::PDL2->new;
#pod
#pod
#pod =cut

1;

#
# This file is part of MooX-PDL2
#
# This software is Copyright (c) 2017 by Smithsonian Astrophysical Observatory.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#

=pod

=head1 NAME

MooX::PDL2 - A Moo based PDL 2.X object

=head1 VERSION

version 0.01

=head1 SYNOPSIS

  use Moo;
  extends 'MooX::PDL2';

=head1 DESCRIPTION

This class provides the thinnest possible layer required to create a
L<Moo> object which is recognized by L<PDL>.

L<PDL> will treat a non-L<PDL> blessed hash as a L<PDL> object if it
has a hash element with a key of C<PDL>.  That element may be a
C<PDL> piddle or a I<subroutine> which returns a piddle.

This class provides a C<PDL> method (which must not be overridden!) which
returns the contents of the C<_PDL> attribute.  That attribute is yours
to manipulate.

=head2 Classes without required constructor parameters

B<PDL> does not pass any parameters to a class' B<initialize> method
when constructing a new object.  Because of this, the default
implementation of B<MooX::PDL2::initialize()> returns a bare piddle,
not an instance of B<MooX::PDL2>, as it cannot know whether your class
requires parameters during construction.

If your class does I<not> require parameters be passed to the constructor,
it is safe to overload the C<initialize> method to return a fully fledged
instance of your class:

 sub initialize { shift->new() }

=head2 Overloaded operators

L<PDL> overloads a number of the standard Perl operators.  For the most part it
does this using subroutines rather than methods, which makes it difficult to
manipulate them.  Consider using L<overload::reify> to wrap the overloads in
methods, e.g.:

  package MyPDL;
  use Moo;
  extends 'MooX::PDL2';
  use overload::reify;

=head1 ATTRIBUTES

=head2 _PDL

The actual piddle associated with an object.  B<PDL> routines
will transparently uses this when passed an object.

This attribute is

=over

=item *

lazy

=item *

has a builder which returns C<< PDL->null >>

=item *

will coerce its argument to be a piddle

=item *

has a clearer

=back

See L</EXAMPLES> for fun ways of combining it with Moo's facilities.

=head1 METHODS

=head2 new

  # null value
  $pdl = MooX::PDL2->new;

=head1 EXAMPLES

=head2 A class representing an evaluated polynomial

This class represents an evaluated polynomial.  The polynomial coefficients and
the values at which it is evaluated are attributes of the class.  When they are
changed they trigger a change in the underlying piddle.

Here's the definition:

 package PolyNomial;
 
 use PDL::Lite;
 
 use Moo;
 extends 'MooX::PDL2';
 
 has x => (
     is       => 'rw',
     required => 1,
     trigger  => sub { $_[0]->_clear_PDL },
 );
 
 has coeffs => (
     is       => 'rw',
     required => 1,
     trigger  => sub { $_[0]->_clear_PDL },
 );
 
 sub _build__PDL {
 
     my $self = shift;
 
     my $x     = $self->x;
     my $coeff = $self->coeffs;
 
     # this calculation is not robust at all
     my $pdl = $x->ones;
     $pdl *= $coeff->[0];
 
     for ( my $exp = 1 ; $exp < @$coeff + 1 ; ++$exp ) {
         $pdl += $coeff->[$exp] * $x**$exp;
     }
     $pdl;
 }
 
 1;

Note that the attributes use triggers to clear C<_PDL> so that it will
be recalculated when it is next accessed through the C<_PDL> attribute
accessor.

And here's how to use it

 use PDL::Lite;
 use PolyNomial;
 
 my $m = PolyNomial->new( coeffs => [ 3, 4 ], x => PDL->sequence(10) );
 print $m, "\n";
 
 $m *= 2;
 print $m, "\n";
 
 $m->x( PDL->sequence( 5 ) );
 print $m, "\n";

With sample output:

 [3 7 11 15 19 23 27 31 35 39]
 [6 14 22 30 38 46 54 62 70 78]
 [3 7 11 15 19]


=head1 BUGS AND LIMITATIONS

You can make new bug reports, and view existing ones, through the
web interface at L<https://rt.cpan.org/Public/Dist/Display.html?Name=MooX-PDL2>.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<PDLx::DetachedObject>

=back

=head1 AUTHOR

Diab Jerius <djerius@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Smithsonian Astrophysical Observatory.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut

__END__


#pod =head1 SYNOPSIS
#pod
#pod   use Moo;
#pod   extends 'MooX::PDL2';
#pod
#pod =head1 DESCRIPTION
#pod
#pod This class provides the thinnest possible layer required to create a
#pod L<Moo> object which is recognized by L<PDL>.
#pod
#pod L<PDL> will treat a non-L<PDL> blessed hash as a L<PDL> object if it
#pod has a hash element with a key of C<PDL>.  That element may be a
#pod C<PDL> piddle or a I<subroutine> which returns a piddle.
#pod
#pod This class provides a C<PDL> method (which must not be overridden!) which
#pod returns the contents of the C<_PDL> attribute.  That attribute is yours
#pod to manipulate.
#pod
#pod
#pod =head2 Classes without required constructor parameters
#pod
#pod B<PDL> does not pass any parameters to a class' B<initialize> method
#pod when constructing a new object.  Because of this, the default
#pod implementation of B<MooX::PDL2::initialize()> returns a bare piddle,
#pod not an instance of B<MooX::PDL2>, as it cannot know whether your class
#pod requires parameters during construction.
#pod
#pod If your class does I<not> require parameters be passed to the constructor,
#pod it is safe to overload the C<initialize> method to return a fully fledged
#pod instance of your class:
#pod
#pod  sub initialize { shift->new() }
#pod
#pod =head2 Overloaded operators
#pod
#pod L<PDL> overloads a number of the standard Perl operators.  For the most part it
#pod does this using subroutines rather than methods, which makes it difficult to
#pod manipulate them.  Consider using L<overload::reify> to wrap the overloads in
#pod methods, e.g.:
#pod
#pod   package MyPDL;
#pod   use Moo;
#pod   extends 'MooX::PDL2';
#pod   use overload::reify;
#pod
#pod
#pod =head1 EXAMPLES
#pod
#pod =head2 A class representing an evaluated polynomial
#pod
#pod This class represents an evaluated polynomial.  The polynomial coefficients and
#pod the values at which it is evaluated are attributes of the class.  When they are
#pod changed they trigger a change in the underlying piddle.
#pod
#pod Here's the definition:
#pod
#pod # EXAMPLE: examples/PolyNomial.pm
#pod
#pod Note that the attributes use triggers to clear C<_PDL> so that it will
#pod be recalculated when it is next accessed through the C<_PDL> attribute
#pod accessor.
#pod
#pod And here's how to use it
#pod
#pod # EXAMPLE: examples/poly.pl
#pod
#pod With sample output:
#pod
#pod # COMMAND: perl -Ilib -Iexamples examples/poly.pl
#pod
#pod =head1 SEE ALSO
#pod
#pod L<PDLx::DetachedObject>
