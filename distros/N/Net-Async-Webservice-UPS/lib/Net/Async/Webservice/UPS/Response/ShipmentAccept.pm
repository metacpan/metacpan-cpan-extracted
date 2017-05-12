package Net::Async::Webservice::UPS::Response::ShipmentAccept;
$Net::Async::Webservice::UPS::Response::ShipmentAccept::VERSION = '1.1.4';
{
  $Net::Async::Webservice::UPS::Response::ShipmentAccept::DIST = 'Net-Async-Webservice-UPS';
}
use Moo;
use Types::Standard qw(Str ArrayRef);
use Net::Async::Webservice::UPS::Types qw(:types);
use Net::Async::Webservice::UPS::Response::Utils ':all';
use List::AllUtils 'pairwise';
use namespace::autoclean;

extends 'Net::Async::Webservice::UPS::Response::ShipmentBase';

# ABSTRACT: UPS response to a ShipAccept request


has pickup_request_number => (
    is => 'ro',
    isa => Str,
    required => 0,
);


has control_log => (
    is => 'ro',
    isa => Image,
    required => 0,
);


has package_results => (
    is => 'ro',
    isa => ArrayRef[PackageResult],
    required => 0,
);

sub BUILDARGS {
    my ($class,$hashref) = @_;
    if (@_>2) { shift; $hashref={@_} };

    my $ret = $class->next::method($hashref);

    if ($hashref->{ShipmentResults}) {
        require Net::Async::Webservice::UPS::Response::PackageResult;

        my $results = $hashref->{ShipmentResults};
        my $weight = $results->{BillingWeight};
        my $charges = $results->{ShipmentCharges};

        $ret = {
            %$ret,
            unit => $weight->{UnitOfMeasurement}{Code},
            billing_weight => $weight->{Weight},
            currency => $charges->{TotalCharges}{CurrencyCode},
            service_option_charges => $charges->{ServiceOptionsCharges}{MonetaryValue},
            transportation_charges => $charges->{TransportationCharges}{MonetaryValue},
            total_charges => $charges->{TotalCharges}{MonetaryValue},
            shipment_identification_number => $results->{ShipmentIdentificationNumber},
            pair_if( pickup_request_number => $results->{PickupRequestNumber} ),
            img_if( control_log => $results->{ControlLogReceipt} ),
            package_results => [ pairwise {
                my ($pr,$pack) = ($a, $b);

                Net::Async::Webservice::UPS::Response::PackageResult->new({
                    %$pr,
                    package => $pack,
                });
            } @{$results->{PackageResults}//[]},@{$hashref->{packages}//[]} ],
        };
    }

    return $ret;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Async::Webservice::UPS::Response::ShipmentAccept - UPS response to a ShipAccept request

=head1 VERSION

version 1.1.4

=head1 DESCRIPTION

This class is returned by
L<Net::Async::Webservice::UPS/ship_accept>. It's a sub-class of
L<Net::Async::Webservice::UPS::Response::ShipmentBase>.

=head1 ATTRIBUTES

=head2 C<pickup_request_number>

Not sure what this means.

=head2 C<control_log>

An instance of L<Net::Async::Webservice::UPS::Response::Image>, not
sure what this means.

=head2 C<package_results>

Array ref of L<Net::Async::Webservice::UPS::Response::PackageResult>.

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
