package Net::LDAP::Class::Loader;
use strict;
use warnings;
use Carp;
use Data::Dump qw( dump );
use base qw( Rose::Object );
use Net::LDAP::Class::MethodMaker (
    scalar => [qw( base_dn ldap object_classes )], );

our $VERSION = '0.27';

=head1 NAME

Net::LDAP::Class::Loader - interrogate an LDAP schema

=head1 SYNOPSIS

 package MyLDAPClass;
 use strict;
 use base qw( Net::LDAP::Class );
 
 __PACKAGE__->metadata->setup(
    use_loader      => 1,
    ldap            => $ldap,
    object_classes  => [qw( posixAccount )],    # optional
 );
 
 1;

=head1 DESCRIPTION

Net::LDAP::Class:Loader inspects a Net::LDAP::Schema
object and determines which attributes are available and which
are unique.

=head1 METHODS

=head2 init

Checks that ldap() and object_classes() are defined.

=cut

sub init {
    my $self = shift;
    $self->SUPER::init(@_);

    if ( !$self->ldap ) {
        croak "must set a Net::LDAP object";
    }

    if ( !$self->object_classes or ref( $self->object_classes ) ne 'ARRAY' ) {
        croak "must set an ARRAY ref of object_classes";
    }

    return $self;
}

=head2 interrogate

Inspects the Net::LDAP::Schema object and returns hashref of C<attributes>
and C<unique_attributes>.

=cut

sub interrogate {
    my $self = shift;

    if ( $self->ldap->version < 3 ) {
        croak "LDAP v3 required in order to interrogate the LDAP server";
    }

    #dump $self;

    my %OC;
    my $schema = $self->ldap->schema;
    for my $oc ( @{ $self->object_classes } ) {

        #warn "interrogating $oc";

        my ( @attributes, @unique );

        for my $may ( $schema->may($oc) ) {

            #warn "may: " . dump($may);
            push( @attributes, $may->{name} );

        }
    MUST: for my $must ( $schema->must($oc) ) {

            #warn "must: " . dump($must);
            my $name = $must->{name};
            next MUST if $name eq 'objectClass';

            push( @attributes, $name );

            # TODO how to speed up fetching only one search result?
            # or better, how to determine which attributes must be unique.
            if ( !@unique ) {
                my $filter = "(&($name=*) (objectClass=$oc))";
                my $res    = $self->ldap->search(
                    base      => $self->base_dn,
                    scope     => 'sub',
                    filter    => $filter,
                    sizelimit => 1,
                );

                if ( !$res->count ) {
                    #warn "no match for $filter";
                    next MUST;
                }

                my $entry = $res->pop_entry;
                if ($entry) {

                    my $dn = $entry->dn;
                    my @rdn = split( m/,/, $dn );
                    my ( $attr, $val ) = split( m/=/, $rdn[0] );
                    push( @unique, $attr );

                }
                $res->abandon;

            }

        }

        $OC{$oc}
            = { attributes => \@attributes, unique_attributes => \@unique };
    }

    return \%OC;

}

=head2 base_dn

Get/set the base DN used by interrogate().

=head2 ldap

Get/set the Net::LDAP object.

=head2 object_classes

Get/set the array ref of object classes to be used by interrogate().

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

=head1 COPYRIGHT

Copyright 2008 by the Regents of the University of Minnesota.
All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

Net::LDAP

=cut
