package Net::UPS::Rate;

# $Id: Rate.pm,v 1.3 2005/09/07 00:09:14 sherzodr Exp $

use strict;
use Class::Struct;
use Carp ( 'croak');

struct(
    billing_weight  => '$',
    total_charges   => '$',
    rated_package   => 'Net::UPS::Package',
    service         => 'Net::UPS::Service',
    from            => 'Net::UPS::Address',
    to              => 'Net::UPS::Address',
);

1;

__END__;

=pod

=head1 NAME

Net::UPS::Rate - Class representing a UPS Rate

=head1 SYNOPSIS

    $rate = $ups->rate($from, $to, $package);
    printf("Rate: \$.2f\n", $rate->total_charges);

=head1 DESCRIPTION

Net::UPS::Rate is a class representing a Rate object, as returned from C<rate()|Net::UPS/"rate"> and C<shop_for_rates()|Net::UPS/"shop_for_rates"> methods

=head1 ATTRIBUTES

Following attributes are available in all Net::UPS::Rate instances:

=over 4

=item billing_weight()

Billing weight used by UPS.com in calculating your rate. Return value is float.

=item total_charges()

Monetary value of your total charges. Return value is float

=item rated_package()

Reference to the Net::UPS::Package instance used to provide this rate.

=item service()

Reference to Net::UPS::Service used in providing this rate

=item from()

=item to()

Reference to Net::UPS::Address objects used in providing this rate

=back

=head1 AUTHOR AND LICENSING

For support and licensing information refer to L<Net::UPS|Net::UPS/"AUTHOR">

=cut
