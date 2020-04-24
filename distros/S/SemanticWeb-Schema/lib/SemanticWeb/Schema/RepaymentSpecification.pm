use utf8;

package SemanticWeb::Schema::RepaymentSpecification;

# ABSTRACT: A structured value representing repayment.

use Moo;

extends qw/ SemanticWeb::Schema::StructuredValue /;


use MooX::JSON_LD 'RepaymentSpecification';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v7.0.4';


has down_payment => (
    is        => 'rw',
    predicate => '_has_down_payment',
    json_ld   => 'downPayment',
);



has early_prepayment_penalty => (
    is        => 'rw',
    predicate => '_has_early_prepayment_penalty',
    json_ld   => 'earlyPrepaymentPenalty',
);



has loan_payment_amount => (
    is        => 'rw',
    predicate => '_has_loan_payment_amount',
    json_ld   => 'loanPaymentAmount',
);



has loan_payment_frequency => (
    is        => 'rw',
    predicate => '_has_loan_payment_frequency',
    json_ld   => 'loanPaymentFrequency',
);



has number_of_loan_payments => (
    is        => 'rw',
    predicate => '_has_number_of_loan_payments',
    json_ld   => 'numberOfLoanPayments',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::RepaymentSpecification - A structured value representing repayment.

=head1 VERSION

version v7.0.4

=head1 DESCRIPTION

A structured value representing repayment.

=head1 ATTRIBUTES

=head2 C<down_payment>

C<downPayment>

a type of payment made in cash during the onset of the purchase of an
expensive good/service. The payment typically represents only a percentage
of the full purchase price.

A down_payment should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::MonetaryAmount']>

=item C<Num>

=back

=head2 C<_has_down_payment>

A predicate for the L</down_payment> attribute.

=head2 C<early_prepayment_penalty>

C<earlyPrepaymentPenalty>

The amount to be paid as a penalty in the event of early payment of the
loan.

A early_prepayment_penalty should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::MonetaryAmount']>

=back

=head2 C<_has_early_prepayment_penalty>

A predicate for the L</early_prepayment_penalty> attribute.

=head2 C<loan_payment_amount>

C<loanPaymentAmount>

The amount of money to pay in a single payment.

A loan_payment_amount should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::MonetaryAmount']>

=back

=head2 C<_has_loan_payment_amount>

A predicate for the L</loan_payment_amount> attribute.

=head2 C<loan_payment_frequency>

C<loanPaymentFrequency>

Frequency of payments due, i.e. number of months between payments. This is
defined as a frequency, i.e. the reciprocal of a period of time.

A loan_payment_frequency should be one of the following types:

=over

=item C<Num>

=back

=head2 C<_has_loan_payment_frequency>

A predicate for the L</loan_payment_frequency> attribute.

=head2 C<number_of_loan_payments>

C<numberOfLoanPayments>

The number of payments contractually required at origination to repay the
loan. For monthly paying loans this is the number of months from the
contractual first payment date to the maturity date.

A number_of_loan_payments should be one of the following types:

=over

=item C<Num>

=back

=head2 C<_has_number_of_loan_payments>

A predicate for the L</number_of_loan_payments> attribute.

=head1 SEE ALSO

L<SemanticWeb::Schema::StructuredValue>

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
