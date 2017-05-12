package Net::Async::Webservice::UPS::Response::ShipmentBase;
$Net::Async::Webservice::UPS::Response::ShipmentBase::VERSION = '1.1.4';
{
  $Net::Async::Webservice::UPS::Response::ShipmentBase::DIST = 'Net-Async-Webservice-UPS';
}
use Moo;
use Types::Standard qw(Str);
use Net::Async::Webservice::UPS::Types qw(:types);
use namespace::autoclean;

extends 'Net::Async::Webservice::UPS::Response';

# ABSTRACT: base class for UPS shipment responses


has unit => (
    is => 'ro',
    isa => WeightMeasurementUnit,
    required => 1,
);


has billing_weight => (
    is => 'ro',
    isa => Measure,
    required => 1,
);


has currency => (
    is => 'ro',
    isa => Str,
    required => 1,
);


has service_option_charges => (
    is => 'ro',
    isa => Measure,
    required => 1,
);


has transportation_charges => (
    is => 'ro',
    isa => Measure,
    required => 1,
);


has total_charges => (
    is => 'ro',
    isa => Measure,
    required => 1,
);


has shipment_identification_number => (
    is => 'ro',
    isa => Str,
    required => 1,
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Async::Webservice::UPS::Response::ShipmentBase - base class for UPS shipment responses

=head1 VERSION

version 1.1.4

=head1 ATTRIBUTES

=head2 C<unit>

Either C<KGS> or C<LBS>, unit of measurement for the
L</billing_weight>. Required.

=head2 C<billing_weight>

Number, the shipment weight you're being billed for, measured in
kilograms or pounds accourding to L</unit>.

=head2 C<currency>

String, the currency code for all the charges.

=head2 C<service_option_charges>

Number, how much the service option costs (in L</currency>).

=head2 C<transportation_charges>

Number, how much the transport costs (in L</currency>).

=head2 C<total_charges>

Number, how much you're being billed for (in L</currency>).

=head2 C<shipment_identification_number>

Unique string that UPS will use to identify this shipment.

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
