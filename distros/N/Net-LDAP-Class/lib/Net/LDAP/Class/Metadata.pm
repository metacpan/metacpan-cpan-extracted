package Net::LDAP::Class::Metadata;
use strict;
use warnings;
use Carp;
use base qw( Rose::Object );
use Clone ();
use Net::LDAP::Class::Loader;

our $VERSION = '0.27';

#
# much of this stolen verbatim from RDBO::Metadata
#

use Net::LDAP::Class::MethodMaker (
    scalar => [
        qw(
            attributes
            unique_attributes
            base_dn
            ldap
            class
            object_classes
            error
            )
    ],
    boolean => [
        'is_initialized' => { default => 0 },
        'use_loader'     => { default => 0 },
    ],
);

our %Objects;

=head1 NAME

Net::LDAP::Class::Metadata - LDAP class metadata

=head1 SYNOPSIS

 package MyLDAPClass;
 use strict;
 use base qw( Net::LDAP::Class );
 
 __PACKAGE__->metadata->setup(
    base_dn             => 'dc=mycompany,dc=local',
    attributes          => [qw( name phone email )],
    unique_attributes   => [qw( email )],
 );
 
 1;

=head1 DESCRIPTION

Instances of this class hold all the attribute information
for a Net::LDAP::Class-derived object.

=head1 METHODS

=head2 new( class => 'NetLDAPClassName' )

Returns a new instance. The C<class> argument is required.

=cut
 
sub new {
    my ( $this_class, %args ) = @_;
    my $class = $args{'class'}
        or croak "Missing required 'class' parameter";
    return $Objects{$class} ||= shift->SUPER::new(@_);
}

=head2 loader_class

Returns 'Net::LDAP::Class::Loader' by default.

=cut

sub loader_class {'Net::LDAP::Class::Loader'}

=head2 setup( I<args> )

Initialize the Metadata object.

I<args> must be key/value pairs. The keys should be the names
of methods, and the values will be set on those method names
in the order given.

setup() will call the Net::LDAP::Class::MethodMaker make_methods()
method to create accessor methods for all the attributes()
on the class indicated in new().

=cut

sub setup {
    my $self = shift;
    my @args = @_;
    if ( @args % 2 ) {
        croak "setup() arguments must be key/value pairs";
    }
    while ( scalar @args ) {
        my $method = shift @args;
        my $value  = shift @args;
        $self->$method($value);
    }

    if ( !$self->base_dn ) {
        croak "base_dn required in Metadata";
    }

    if ( $self->use_loader ) {

        unless ( $self->ldap ) {
            croak "must define ldap() in order to use_loader";
        }

        my $loader = $self->loader_class->new(
            ldap           => $self->ldap,
            object_classes => $self->object_classes
                || [ map { $_->{name} }
                    $self->ldap->schema->all_objectclasses ],
            base_dn => $self->base_dn,
        );

        my $info = $loader->interrogate;

        $self->unique_attributes(
            [ map { @{ $info->{$_}->{unique_attributes} } } keys %$info ] );
        $self->attributes(
            [ map { @{ $info->{$_}->{attributes} } } keys %$info ] );

    }

    if ( !defined $self->unique_attributes
        or ref( $self->unique_attributes ) ne 'ARRAY' )
    {
        croak "unique_attributes() must be set to an ARRAY ref";
    }
    if ( !defined $self->attributes or ref( $self->attributes ) ne 'ARRAY' ) {
        croak "attributes() must be set to an ARRAY ref";
    }

    Net::LDAP::Class::MethodMaker->make_methods(
        {   target_class      => $self->class,
            preserve_existing => 1,
        },
        'ldap_entry' => [ @{ $self->attributes } ],
    );

    $self->is_initialized(1);

    return $self;
}

=head2 clone

Returns a clone of the Metadata object. Uses Clone::clone().

=cut

sub clone {
    my $self = shift;
    return Clone::clone($self);
}

=head2 for_class( I<class_name> )

Returns a Metadata object for I<class_name>. Used primarily
by the metadata() method in Net::LDAP::Class.

=cut

sub for_class {
    my ( $meta_class, $class ) = ( shift, shift );
    return $Objects{$class} if ( $Objects{$class} );

    # Clone an ancestor meta object
    foreach my $parent_class ( __get_parents($class) ) {
        if ( my $parent_meta = $Objects{$parent_class} ) {
            my $meta = $parent_meta->clone;

            $meta->is_initialized(0);
            $meta->class($class);

            return $Objects{$class} = $meta;
        }
    }

    return $Objects{$class} = $meta_class->new( class => $class );
}

sub __get_parents {
    my ($class) = shift;
    my @parents;

    no strict 'refs';
    foreach my $sub_class ( @{"${class}::ISA"} ) {
        push( @parents, __get_parents($sub_class) )
            if ( $sub_class->isa('Net::LDAP::Class') );
    }

    return $class, @parents;
}

=head2 attributes

Get/set the array ref of attributes for the class.

=head2 base_dn

Get/set the base DN for the class.

=head2 error

Get/set the current error message.

=head2 ldap

Get/set the internal Net::LDAP object.

=head2 object_classes

Get/set the object_classes to be used by the Loader. Ignored if
you are not using Net::LDAP::Class::Loader.

=head2 unique_attributes

Get/set the array ref of unique attributes for the class.
These are attributes which may be used to uniquely identify
a LDAP entry.

=cut

1;

__END__

=head1 AUTHOR

Peter Karman, C<< <karman at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-net-ldap-class at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-LDAP-Class>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::LDAP::Class

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-LDAP-Class>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net-LDAP-Class>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-LDAP-Class>

=item * Search CPAN

L<http://search.cpan.org/dist/Net-LDAP-Class>

=back

=head1 ACKNOWLEDGEMENTS

The Minnesota Supercomputing Institute C<< http://www.msi.umn.edu/ >>
sponsored the development of this software.

The idea and much of the code for this class was stolen
directly from John Siracusa's Rose::DB::Object::Metadata module.

=head1 COPYRIGHT

Copyright 2008 by the Regents of the University of Minnesota.
All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

Net::LDAP::Class, Rose::DB::Object

=cut
