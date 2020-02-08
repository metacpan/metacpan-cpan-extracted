use utf8;

package SemanticWeb::Schema::PaymentCard;

# ABSTRACT: A payment method using a credit

use Moo;

extends qw/ SemanticWeb::Schema::FinancialProduct SemanticWeb::Schema::PaymentMethod /;


use MooX::JSON_LD 'PaymentCard';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v6.0.1';


has cash_back => (
    is        => 'rw',
    predicate => '_has_cash_back',
    json_ld   => 'cashBack',
);



has contactless_payment => (
    is        => 'rw',
    predicate => '_has_contactless_payment',
    json_ld   => 'contactlessPayment',
);



has floor_limit => (
    is        => 'rw',
    predicate => '_has_floor_limit',
    json_ld   => 'floorLimit',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::PaymentCard - A payment method using a credit

=head1 VERSION

version v6.0.1

=head1 DESCRIPTION

A payment method using a credit, debit, store or other card to associate
the payment with an account.

=head1 ATTRIBUTES

=head2 C<cash_back>

C<cashBack>

A cardholder benefit that pays the cardholder a small percentage of their
net expenditures.

A cash_back should be one of the following types:

=over

=item C<Bool>

=item C<Num>

=back

=head2 C<_has_cash_back>

A predicate for the L</cash_back> attribute.

=head2 C<contactless_payment>

C<contactlessPayment>

A secure method for consumers to purchase products or services via debit,
credit or smartcards by using RFID or NFC technology.

A contactless_payment should be one of the following types:

=over

=item C<Bool>

=back

=head2 C<_has_contactless_payment>

A predicate for the L</contactless_payment> attribute.

=head2 C<floor_limit>

C<floorLimit>

A floor limit is the amount of money above which credit card transactions
must be authorized.

A floor_limit should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::MonetaryAmount']>

=back

=head2 C<_has_floor_limit>

A predicate for the L</floor_limit> attribute.

=head1 SEE ALSO

L<SemanticWeb::Schema::PaymentMethod>

=head1 SOURCE

The development version is on github at L<https://github.com/robrwo/SemanticWeb-Schema>
and may be cloned from L<git://github.com/robrwo/SemanticWeb-Schema.git>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/robrwo/SemanticWeb-Schema/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018-2020 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
