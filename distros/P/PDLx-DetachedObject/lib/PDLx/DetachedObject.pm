# ABSTRACT: parent class for subclassing PDL 2.X from class frameworks
package PDLx::DetachedObject;

use strict;
use warnings;

our $VERSION = '0.02';

our @ISA = qw( PDL );
use PDL::Lite;

#pod =begin pod_coverage
#pod
#pod =head3 initialize
#pod
#pod =head3 new
#pod
#pod =end pod_coverage
#pod
#pod =cut

sub initialize { return PDL->null }

sub new {
    my $class = shift;
    bless { PDL => PDL->null }, $class;
}

1;

#
# This file is part of PDLx-DetachedObject
#
# This software is Copyright (c) 2016 by Smithsonian Astrophysical Observatory.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#

=pod

=encoding UTF-8

=head1 NAME

PDLx::DetachedObject - parent class for subclassing PDL 2.X from class frameworks

=head1 VERSION

version 0.02

=head1 SYNOPSIS

=head3 Moo

   # DEPRECATED; use MooX::PDL2 instead
   package MyPDL;

   use Moo;
   use PDL::Lite;

   extends 'PDLx::DetachedObject';

   has PDL => ( is => 'rw' );

=head3 Class::Tiny

    package MyPDL;

    use Class::Tiny qw[ PDL ];

    use parent 'PDLx::DetachedObject';

=head3 Object::Tiny

    package MyPDL;

    use Object::Tiny qw[ PDL ];

    use parent 'PDLx::DetachedObject';

=head3 Class::Accessor

    package MyPDL;

    use parent 'Class::Accessor', 'PDLx::DetachedObject';
    __PACKAGE__->follow_best_practice;
    __PACKAGE__->mk_accessors( 'PDL' );

or with Antlers:

    package MyPDL;
    use Class::Accessor "antlers";
    use parent 'PDLx::DetachedObject';

    has PDL => ( is => 'ro' );

=head1 DESCRIPTION

B<PDLx::DetachedObject> provides a minimal shim between L<PDL> and
object-orientation frameworks.  Directly subclassing B<PDL> is tricky,
as a B<PDL> object (a piddle) is a blessed scalar, not a blessed hash.
B<PDL> provides an L<alternate|PDL::Objects> means of subclassing; this
class encapsulates that prescription.

For L<Moo> based classes, see L<MooX::PDL2>, which provides a more
integrated approach.

=head2 Background

Because a B<PDL> object is a blessed scalar, outside of using
inside-out classes as the subclass, there is no easy means of adding
extra attributes to the object.

To work around this, B<PDL> will treat any hash blessed into a
subclass of PDL which has an entry with key C<PDL> whose value is a
real B<PDL> object as a B<PDL> object.

So far, here's a L<< B<Moo> >> version of the class

   package MyPDL;

   use Moo;

   extends 'PDL';

   # don't pass any constructor arguments to PDL->new; it confuses it
   sub FOREIGNBUILDARGS {}

   has PDL => ( is => 'rw' );
   has required_attr => ( is => 'ro', required =>1 );

When B<PDL> needs to instantiate an object from the subclass,
it doesn't call the subclass's constructor, rather it calls the
B<initialize> class method, which is expected to return a hash,
blessed into the subclass, containing the C<PDL> key as well as any
other attributes.

  sub initialize {
    my $class = shift;
    bless { PDL => PDL->null }, $class;
  }

The B<initialize> method is invoked in a variety of places.  For
instance, it's called in B<PDL::new>, which due to B<Moo>'s
inheritance scheme will be called by B<MyPDL>'s constructor:

  $mypdl = MyPDL->new( required_attr => 2 );

It's also called when B<PDL> needs to create an object to receive
the results of a B<PDL> operation on a B<MyPDL> object:

  $newpdl = $mypdl + 1;

There's one wrinkle, however.  B<PDL> I<must> create an object without
any extra attributes (it cannot know which values to give them) so
B<initialize()> is called with a I<single> argument, the class name.
This means that C<$newpdl> will be an I<incomplete> B<MyPDL> object,
i.e.  C<required_attr> is uninitialized. This can I<really> confuse
polymorphic code which operates differently when handed a B<PDL> or
B<MyPDL> object.

One way out of this dilemma is to have B<PDL> create a I<normal> piddle
instead of a B<MyPDL> object.  B<MyPDL> has explicitly indicated it wants to be
treated as a normal piddle in B<PDL> operations (by subclassing from B<PDL>) so
this doesn't break that contract.

  $newpdl = $mypdl + 1;

would result in C<$newpdl> being a normal B<PDL> object, not a B<MyPDL>
object.

Subclassing from B<PDLx::DetachedObject> effects this
behavior. B<PDLx::DetachedObject> provides a wrapper constructor and
an B<initialize> class method.  The constructor ensures returns a
properly subclassed hash with the C<PDL> key, keeping B<PDL> happy.
When B<PDL> calls the B<initialize> function it gets a normal B<PDL>.

=head2 Classes without required constructor parameters

If your class does I<not> require parameters be passed to the constructor,
it is safe to overload the C<initialize> method to return a fully fledged
instance of your class:

 sub initialize { shift->new() }

=head2 Using with Class Frameworks

The L</SYNOPSIS> shows how to use B<PDLx::DetachedObject> with various
class frameworks.  The key differentiation between frameworks is
whether or not they will call a superclass's constructor.  B<Moo>
always calls it, B<Class::Tiny> calls it only if it inherits from
B<Class::Tiny::Object>, and B<Object::Tiny> and B<Class::Accessor>
never will call the superclass' constructor.

=begin pod_coverage

=head3 initialize

=head3 new

=end pod_coverage

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to
C<bug-pdlx-detachedobject@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/Public/Dist/Display.html?Name=PDLx-DetachedObject>.

=head1 AUTHOR

Diab Jerius <djerius@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Smithsonian Astrophysical Observatory.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut

__END__


#pod =pod
#pod
#pod =head1 SYNOPSIS
#pod
#pod =head3 Moo
#pod
#pod    # DEPRECATED; use MooX::PDL2 instead
#pod    package MyPDL;
#pod
#pod    use Moo;
#pod    use PDL::Lite;
#pod
#pod    extends 'PDLx::DetachedObject';
#pod
#pod    has PDL => ( is => 'rw' );
#pod
#pod
#pod =head3 Class::Tiny
#pod
#pod     package MyPDL;
#pod
#pod     use Class::Tiny qw[ PDL ];
#pod
#pod     use parent 'PDLx::DetachedObject';
#pod
#pod =head3 Object::Tiny
#pod
#pod     package MyPDL;
#pod
#pod     use Object::Tiny qw[ PDL ];
#pod
#pod     use parent 'PDLx::DetachedObject';
#pod
#pod =head3 Class::Accessor
#pod
#pod     package MyPDL;
#pod
#pod     use parent 'Class::Accessor', 'PDLx::DetachedObject';
#pod     __PACKAGE__->follow_best_practice;
#pod     __PACKAGE__->mk_accessors( 'PDL' );
#pod
#pod or with Antlers:
#pod
#pod     package MyPDL;
#pod     use Class::Accessor "antlers";
#pod     use parent 'PDLx::DetachedObject';
#pod
#pod     has PDL => ( is => 'ro' );
#pod
#pod
#pod
#pod =head1 DESCRIPTION
#pod
#pod B<PDLx::DetachedObject> provides a minimal shim between L<PDL> and
#pod object-orientation frameworks.  Directly subclassing B<PDL> is tricky,
#pod as a B<PDL> object (a piddle) is a blessed scalar, not a blessed hash.
#pod B<PDL> provides an L<alternate|PDL::Objects> means of subclassing; this
#pod class encapsulates that prescription.
#pod
#pod For L<Moo> based classes, see L<MooX::PDL2>, which provides a more
#pod integrated approach.
#pod
#pod =head2 Background
#pod
#pod Because a B<PDL> object is a blessed scalar, outside of using
#pod inside-out classes as the subclass, there is no easy means of adding
#pod extra attributes to the object.
#pod
#pod To work around this, B<PDL> will treat any hash blessed into a
#pod subclass of PDL which has an entry with key C<PDL> whose value is a
#pod real B<PDL> object as a B<PDL> object.
#pod
#pod So far, here's a L<< B<Moo> >> version of the class
#pod
#pod    package MyPDL;
#pod
#pod    use Moo;
#pod
#pod    extends 'PDL';
#pod
#pod    # don't pass any constructor arguments to PDL->new; it confuses it
#pod    sub FOREIGNBUILDARGS {}
#pod
#pod    has PDL => ( is => 'rw' );
#pod    has required_attr => ( is => 'ro', required =>1 );
#pod
#pod When B<PDL> needs to instantiate an object from the subclass,
#pod it doesn't call the subclass's constructor, rather it calls the
#pod B<initialize> class method, which is expected to return a hash,
#pod blessed into the subclass, containing the C<PDL> key as well as any
#pod other attributes.
#pod
#pod   sub initialize {
#pod     my $class = shift;
#pod     bless { PDL => PDL->null }, $class;
#pod   }
#pod
#pod The B<initialize> method is invoked in a variety of places.  For
#pod instance, it's called in B<PDL::new>, which due to B<Moo>'s
#pod inheritance scheme will be called by B<MyPDL>'s constructor:
#pod
#pod   $mypdl = MyPDL->new( required_attr => 2 );
#pod
#pod It's also called when B<PDL> needs to create an object to receive
#pod the results of a B<PDL> operation on a B<MyPDL> object:
#pod
#pod   $newpdl = $mypdl + 1;
#pod
#pod There's one wrinkle, however.  B<PDL> I<must> create an object without
#pod any extra attributes (it cannot know which values to give them) so
#pod B<initialize()> is called with a I<single> argument, the class name.
#pod This means that C<$newpdl> will be an I<incomplete> B<MyPDL> object,
#pod i.e.  C<required_attr> is uninitialized. This can I<really> confuse
#pod polymorphic code which operates differently when handed a B<PDL> or
#pod B<MyPDL> object.
#pod
#pod One way out of this dilemma is to have B<PDL> create a I<normal> piddle
#pod instead of a B<MyPDL> object.  B<MyPDL> has explicitly indicated it wants to be
#pod treated as a normal piddle in B<PDL> operations (by subclassing from B<PDL>) so
#pod this doesn't break that contract.
#pod
#pod   $newpdl = $mypdl + 1;
#pod
#pod would result in C<$newpdl> being a normal B<PDL> object, not a B<MyPDL>
#pod object.
#pod
#pod Subclassing from B<PDLx::DetachedObject> effects this
#pod behavior. B<PDLx::DetachedObject> provides a wrapper constructor and
#pod an B<initialize> class method.  The constructor ensures returns a
#pod properly subclassed hash with the C<PDL> key, keeping B<PDL> happy.
#pod When B<PDL> calls the B<initialize> function it gets a normal B<PDL>.
#pod
#pod =head2 Classes without required constructor parameters
#pod
#pod If your class does I<not> require parameters be passed to the constructor,
#pod it is safe to overload the C<initialize> method to return a fully fledged
#pod instance of your class:
#pod
#pod  sub initialize { shift->new() }
#pod
#pod =head2 Using with Class Frameworks
#pod
#pod The L</SYNOPSIS> shows how to use B<PDLx::DetachedObject> with various
#pod class frameworks.  The key differentiation between frameworks is
#pod whether or not they will call a superclass's constructor.  B<Moo>
#pod always calls it, B<Class::Tiny> calls it only if it inherits from
#pod B<Class::Tiny::Object>, and B<Object::Tiny> and B<Class::Accessor>
#pod never will call the superclass' constructor.
#pod
#pod =head1 BUGS AND LIMITATIONS
#pod
#pod
#pod Please report any bugs or feature requests to
#pod C<bug-pdlx-detachedobject@rt.cpan.org>, or through the web interface at
#pod L<http://rt.cpan.org/Public/Dist/Display.html?Name=PDLx-DetachedObject>.
#pod
#pod =cut
