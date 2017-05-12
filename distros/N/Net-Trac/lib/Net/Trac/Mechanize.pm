use strict;
use warnings;

package Net::Trac::Mechanize;

=head1 NAME

Net::Trac::Mechanize - Provides persistent credentials for the Trac instance

=head1 DESCRIPTION

This class subclasses L<WWW::Mechanize> to provide persistent HTTP credentials
when accessing a Trac instance.

=cut

use Any::Moose;
extends 'WWW::Mechanize';

=head1 ACCESSORS / MUTATORS

=head2 trac_user

=head2 trac_password

=cut

has trac_user     => ( isa => 'Str', is => 'rw' );
has trac_password => ( isa => 'Str', is => 'rw' );

=head1 METHODS

=head2 get_basic_credentials

Returns the credentials that L<WWW::Mechanize> expects.

=cut

sub get_basic_credentials {
    my $self = shift;
    return ( $self->trac_user => $self->trac_password );
}

=head1 LICENSE

Copyright 2008-2009 Best Practical Solutions.

This package is licensed under the same terms as Perl 5.8.8.

=cut

# This is commented because it breaks the class, causing it to
# seemingly not follow HTTP redirects.
#__PACKAGE__->meta->make_immutable;
no Any::Moose;

1;
