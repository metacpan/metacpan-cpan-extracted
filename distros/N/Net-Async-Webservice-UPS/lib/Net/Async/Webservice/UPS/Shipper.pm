package Net::Async::Webservice::UPS::Shipper;
$Net::Async::Webservice::UPS::Shipper::VERSION = '1.1.4';
{
  $Net::Async::Webservice::UPS::Shipper::DIST = 'Net-Async-Webservice-UPS';
}
use Moo;
use 5.010;
use Types::Standard qw(Str);
use Net::Async::Webservice::UPS::Types ':types';
extends 'Net::Async::Webservice::UPS::Contact';
use namespace::autoclean;

# ABSTRACT: a contact with an account number


has account_number => (
    is => 'ro',
    isa => Str,
);


sub as_hash {
    my ($self,$shape) = @_;

    my $ret = $self->next::method($shape);
    if ($self->account_number) {
        $ret->{ShipperNumber} = $self->account_number;
    }
    return $ret;
}


sub cache_id {
    my ($self) = @_;

    return join ':',
        ($self->account_number||''),
        $self->address->cache_id;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Async::Webservice::UPS::Shipper - a contact with an account number

=head1 VERSION

version 1.1.4

=head1 DESCRIPTION

A shipper is eithre the originator of a shipment, or someone to whose
account the shipment is billed. This class subclasses
L<Net::Async::Webservice::UPS::Contact> and adds the
L</account_number> field.

=head1 ATTRIBUTES

=head2 C<account_number>

Optional string, the UPS account number for this shipper.

=head1 METHODS

=head2 C<as_hash>

Returns a hashref that, when passed through L<XML::Simple>, will
produce the XML fragment needed in UPS requests to represent this
shipper.

=head2 C<cache_id>

Returns a string identifying this shipper.

=head1 AUTHORS

=over 4

=item *

Gianni Ceccarelli <gianni.ceccarelli@net-a-porter.com>

=item *

Sherzod B. Ruzmetov <sherzodr@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Gianni Ceccarelli <gianni.ceccarelli@net-a-porter.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
