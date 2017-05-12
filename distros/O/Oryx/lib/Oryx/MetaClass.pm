package Oryx::MetaClass;

# okay, so it's not really a meta-class in the true sense since it
# doesn't get instantiated. Instead, it gets subclassed, but we use
# inheritable class data to achieve the same effect. This is 
# because we're not trying to create our own meta-model so much as
# trying to squeeze a relational data model into Perl's in-built
# meta-model.  Subclassing this via Perl's inheritance mechanism
# preserves class state as if the sub class were a Class instance of a
# MetaClass (which it is, just not this one... Perl's). There is
# meta-data associated with the class which is in the form of a DOM
# Node which was used to define the schema in the first place (and
# which is passed into the constructor of whichever entity derives
# from this class).

use Carp qw(carp croak cluck);
use base qw(Class::Data::Inheritable);

__PACKAGE__->mk_classdata("storage");
__PACKAGE__->mk_classdata("schema");

=head1 NAME

Oryx::MetaClass - abstract base class for all Oryx meta types

=head1 INTERFACE

All Oryx components implement the interface defined herein. This
is the basis for all Oryx components to share a common interface.
All this really means is that when an object is created, retrieved,
deleted etc. then each meta-instance (L<Oryx::Attribute>, L<Oryx::Association> etc.)
associated with the class or instance can decide what it wants to do
during each call. So when we say:

    CMS::Page->create({ ... });

then in the C<create()> method inherited from L<Oryx::Class> we
do something similar to:

    sub create {
        my ($class, $params) = @_;
        
        # do a few things with $params, exactly what would depend
        # on whether we're using DBI or DBM back-end
        
        $_->create($query, $params, ...) foreach $class->members;
        
        # return a newly created instance
    }

Here the C<members> method (defined in L<Oryx::Class> returns
all meta-instances hanging off the class, and to each on is the
C<create> method delegated; hence the common interface.

=over

=item create

meta object's C<create()> hook

=item retrieve

meta object's C<retrieve()> hook

=item update

meta object's C<update()> hook

=item delete

meta object's C<delete()> hook

=item search

meta object's C<search()> hook

=item construct

meta object's C<construct()> hook

=head1 META-DATA ACCESS

Each meta-type (with the exception of L<Oryx::Value> types) has
meta-data associated with it which is usually defined in the
C<$schema> class variable used in your persistent classes.

The following are accessors for this meta-data:

=item meta

usually returns a hash reference which corresponds to the meta-data
described in C<$schema>.

=item getMetaAttribute( $name )

get a value from the meta-data hash ref keyed by C<$name>

=item setMetaAttribute( $name, $value )

set a value from the meta-data hash ref keyed by C<$name>

=back

=cut

sub create    { }
sub retrieve  { }
sub update    { }
sub delete    { }
sub search    { }
sub construct { }

sub meta {
    my $class = shift;
    $class->{meta} = shift if @_;
    $class->{meta};
}

sub setMetaAttribute {
    my ($class, $key, $value) = @_;
    $class->meta->{$key} = $value;
}

sub getMetaAttribute {
    my ($class, $key) = @_;
    unless ($class->meta) {
	cluck("$class has no meta");
    }
    return $class->meta->{$key};
}

sub _carp {
    my $thing = ref($_[0]) ? ref($_[0]) : $_[0];
    carp("[$thing] $_[1]");
}

sub _croak {
    my $thing = ref($_[0]) ? ref($_[0]) : $_[0];
    croak("[$thing] $_[1]");
}

1;

=head1 SEE ALSO

L<Oryx>, L<Oryx::Class>

=head1 AUTHOR

Copyright (C) 2005 Richard Hundt <richard NO SPAM AT protea-systems.com>

=head1 LICENSE

This library is free software and may be used under the same terms as Perl itself.

=cut
