package Net::Async::Webservice::UPS::Rate;
$Net::Async::Webservice::UPS::Rate::VERSION = '1.1.4';
{
  $Net::Async::Webservice::UPS::Rate::DIST = 'Net-Async-Webservice-UPS';
}
use Moo;
use 5.010;
use Types::Standard qw(Str ArrayRef);
use Net::Async::Webservice::UPS::Types ':types';
use namespace::autoclean;

# ABSTRACT: shipment rate from UPS


has unit => (
    is => 'ro',
    isa => WeightMeasurementUnit,
    required => 1,
);


has billing_weight => (
    is => 'ro',
    isa => Measure,
    required => 0,
);


has total_charges_currency => (
    is => 'ro',
    isa => Currency,
    required => 1,
);


has total_charges => (
    is => 'ro',
    isa => Measure,
    required => 1,
);


has rated_package => (
    is => 'ro',
    isa => Package,
    required => 1,
);


has service => (
    is => 'rwp',
    isa => Service,
    weak_ref => 1,
    required => 0,
);


has from => (
    is => 'ro',
    isa => Address,
    required => 1,
);


has to => (
    is => 'ro',
    isa => Address,
    required => 1,
);

sub BUILDARGS {
    my ($class,@etc) = @_;
    my $hashref = $class->next::method(@etc);

    if ($hashref->{BillingWeight}) {
        return {
            billing_weight  => $hashref->{BillingWeight}{Weight},
            unit            => $hashref->{BillingWeight}{UnitOfMeasurement}{Code},
            total_charges   => $hashref->{TotalCharges}{MonetaryValue},
            total_charges_currency => $hashref->{TotalCharges}{CurrencyCode},
            weight          => $hashref->{Weight},
            rated_package   => $hashref->{rated_package},
            from            => $hashref->{from},
            to              => $hashref->{to},
        }
    }
    else {
        return $hashref,
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Async::Webservice::UPS::Rate - shipment rate from UPS

=head1 VERSION

version 1.1.4

=head1 DESCRIPTION

Objects of this class are usually only seen inside
L<Net::Async::Webservice::UPS::Response::Rate>, as returned by
L<Net::Async::Webservice::UPS/request_rate>.

=head1 ATTRIBUTES

=head2 C<unit>

Either C<KGS> or C<LBS>, unit for the L</billing_weight>.

=head2 C<billing_weight>

The weight that was used to generate the price, not necessarily the
actual weight of the shipment or package.

=head2 C<total_charges_currency>

Currency code for the L</total_charges>.

=head2 C<total_charges>

Total rated cost of the shipment.

=head2 C<rated_package>

The package that was used to provide this rate.

=head2 C<service>

I<Weak> reference to the L<Net::Async::Webservice::UPS::Service> this
rate is for. It's weak because the service holds references to rates,
and we really don't want cycles.

=head2 C<from>

Sender address for this shipment.

=head2 C<to>

Recipient address for this shipment.

=for Pod::Coverage BUILDARGS

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
