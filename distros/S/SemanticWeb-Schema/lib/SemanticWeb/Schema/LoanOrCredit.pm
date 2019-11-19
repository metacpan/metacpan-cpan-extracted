use utf8;

package SemanticWeb::Schema::LoanOrCredit;

# ABSTRACT: A financial product for the loaning of an amount of money under agreed terms and charges.

use Moo;

extends qw/ SemanticWeb::Schema::FinancialProduct /;


use MooX::JSON_LD 'LoanOrCredit';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v5.0.1';


has amount => (
    is        => 'rw',
    predicate => '_has_amount',
    json_ld   => 'amount',
);



has currency => (
    is        => 'rw',
    predicate => '_has_currency',
    json_ld   => 'currency',
);



has grace_period => (
    is        => 'rw',
    predicate => '_has_grace_period',
    json_ld   => 'gracePeriod',
);



has loan_repayment_form => (
    is        => 'rw',
    predicate => '_has_loan_repayment_form',
    json_ld   => 'loanRepaymentForm',
);



has loan_term => (
    is        => 'rw',
    predicate => '_has_loan_term',
    json_ld   => 'loanTerm',
);



has loan_type => (
    is        => 'rw',
    predicate => '_has_loan_type',
    json_ld   => 'loanType',
);



has recourse_loan => (
    is        => 'rw',
    predicate => '_has_recourse_loan',
    json_ld   => 'recourseLoan',
);



has renegotiable_loan => (
    is        => 'rw',
    predicate => '_has_renegotiable_loan',
    json_ld   => 'renegotiableLoan',
);



has required_collateral => (
    is        => 'rw',
    predicate => '_has_required_collateral',
    json_ld   => 'requiredCollateral',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::LoanOrCredit - A financial product for the loaning of an amount of money under agreed terms and charges.

=head1 VERSION

version v5.0.1

=head1 DESCRIPTION

A financial product for the loaning of an amount of money under agreed
terms and charges.

=head1 ATTRIBUTES

=head2 C<amount>

The amount of money.

A amount should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::MonetaryAmount']>

=item C<Num>

=back

=head2 C<_has_amount>

A predicate for the L</amount> attribute.

=head2 C<currency>

=for html <p>The currency in which the monetary amount is expressed.<br/><br/> Use
standard formats: <a href="http://en.wikipedia.org/wiki/ISO_4217">ISO 4217
currency format</a> e.g. "USD"; <a
href="https://en.wikipedia.org/wiki/List_of_cryptocurrencies">Ticker
symbol</a> for cryptocurrencies e.g. "BTC"; well known names for <a
href="https://en.wikipedia.org/wiki/Local_exchange_trading_system">Local
Exchange Tradings Systems</a> (LETS) and other currency types e.g. "Ithaca
HOUR".<p>

A currency should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_currency>

A predicate for the L</currency> attribute.

=head2 C<grace_period>

C<gracePeriod>

The period of time after any due date that the borrower has to fulfil its
obligations before a default (failure to pay) is deemed to have occurred.

A grace_period should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Duration']>

=back

=head2 C<_has_grace_period>

A predicate for the L</grace_period> attribute.

=head2 C<loan_repayment_form>

C<loanRepaymentForm>

A form of paying back money previously borrowed from a lender. Repayment
usually takes the form of periodic payments that normally include part
principal plus interest in each payment.

A loan_repayment_form should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::RepaymentSpecification']>

=back

=head2 C<_has_loan_repayment_form>

A predicate for the L</loan_repayment_form> attribute.

=head2 C<loan_term>

C<loanTerm>

The duration of the loan or credit agreement.

A loan_term should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::QuantitativeValue']>

=back

=head2 C<_has_loan_term>

A predicate for the L</loan_term> attribute.

=head2 C<loan_type>

C<loanType>

The type of a loan or credit.

A loan_type should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_loan_type>

A predicate for the L</loan_type> attribute.

=head2 C<recourse_loan>

C<recourseLoan>

The only way you get the money back in the event of default is the
security. Recourse is where you still have the opportunity to go back to
the borrower for the rest of the money.

A recourse_loan should be one of the following types:

=over

=item C<Bool>

=back

=head2 C<_has_recourse_loan>

A predicate for the L</recourse_loan> attribute.

=head2 C<renegotiable_loan>

C<renegotiableLoan>

Whether the terms for payment of interest can be renegotiated during the
life of the loan.

A renegotiable_loan should be one of the following types:

=over

=item C<Bool>

=back

=head2 C<_has_renegotiable_loan>

A predicate for the L</renegotiable_loan> attribute.

=head2 C<required_collateral>

C<requiredCollateral>

Assets required to secure loan or credit repayments. It may take form of
third party pledge, goods, financial instruments (cash, securities, etc.)

A required_collateral should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Thing']>

=item C<Str>

=back

=head2 C<_has_required_collateral>

A predicate for the L</required_collateral> attribute.

=head1 SEE ALSO

L<SemanticWeb::Schema::FinancialProduct>

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

This software is Copyright (c) 2018-2019 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
