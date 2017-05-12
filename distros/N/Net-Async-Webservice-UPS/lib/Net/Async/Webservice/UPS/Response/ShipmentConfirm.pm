package Net::Async::Webservice::UPS::Response::ShipmentConfirm;
$Net::Async::Webservice::UPS::Response::ShipmentConfirm::VERSION = '1.1.4';
{
  $Net::Async::Webservice::UPS::Response::ShipmentConfirm::DIST = 'Net-Async-Webservice-UPS';
}
use Moo;
use Types::Standard qw(Str ArrayRef);
use Net::Async::Webservice::UPS::Types qw(:types);
use namespace::autoclean;

extends 'Net::Async::Webservice::UPS::Response::ShipmentBase';

# ABSTRACT: UPS response to a ShipConfirm request


has shipment_digest => (
    is => 'ro',
    isa => Str,
    required => 1,
);


has packages => (
    is => 'ro',
    isa => ArrayRef[Package],
    required => 1,
);

sub BUILDARGS {
    my ($class,$hashref) = @_;
    if (@_>2) { shift; $hashref={@_} };

    my $ret = $class->next::method($hashref);

    if ($hashref->{BillingWeight}) {

        my $weight = $hashref->{BillingWeight};
        my $charges = $hashref->{ShipmentCharges};

        return {
            %$ret,
            unit => $weight->{UnitOfMeasurement}{Code},
            billing_weight => $weight->{Weight},
            currency => $charges->{TotalCharges}{CurrencyCode},
            service_option_charges => $charges->{ServiceOptionsCharges}{MonetaryValue},
            transportation_charges => $charges->{TransportationCharges}{MonetaryValue},
            total_charges => $charges->{TotalCharges}{MonetaryValue},
            shipment_digest => $hashref->{ShipmentDigest},
            shipment_identification_number => $hashref->{ShipmentIdentificationNumber},
            packages => $hashref->{packages},
        };
    }
    else {
        return $ret;
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Async::Webservice::UPS::Response::ShipmentConfirm - UPS response to a ShipConfirm request

=head1 VERSION

version 1.1.4

=head1 DESCRIPTION

This class is returned by
L<Net::Async::Webservice::UPS/ship_confirm>. It's a sub-class of
L<Net::Async::Webservice::UPS::Response::ShipmentBase>.

=head1 ATTRIBUTES

=head2 C<shipment_digest>

A string with encoded information needed by UPS in the ShipAccept call.

=head2 C<packages>

For internal use: the list of packages passed into the
L<Net::Async::Webservice::UPS/ship_confirm> call.

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
