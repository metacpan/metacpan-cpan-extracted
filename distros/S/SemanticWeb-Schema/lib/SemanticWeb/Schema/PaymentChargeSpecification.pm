use utf8;

package SemanticWeb::Schema::PaymentChargeSpecification;

# ABSTRACT: The costs of settling the payment using a particular payment method.

use Moo;

extends qw/ SemanticWeb::Schema::PriceSpecification /;


use MooX::JSON_LD 'PaymentChargeSpecification';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v0.0.4';


has applies_to_delivery_method => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'appliesToDeliveryMethod',
);



has applies_to_payment_method => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'appliesToPaymentMethod',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::PaymentChargeSpecification - The costs of settling the payment using a particular payment method.

=head1 VERSION

version v0.0.4

=head1 DESCRIPTION

The costs of settling the payment using a particular payment method.

=head1 ATTRIBUTES

=head2 C<applies_to_delivery_method>

C<appliesToDeliveryMethod>

The delivery method(s) to which the delivery charge or payment charge
specification applies.

A applies_to_delivery_method should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::DeliveryMethod']>

=back

=head2 C<applies_to_payment_method>

C<appliesToPaymentMethod>

The payment method(s) to which the payment charge specification applies.

A applies_to_payment_method should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::PaymentMethod']>

=back

=head1 SEE ALSO

L<SemanticWeb::Schema::PriceSpecification>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
