use utf8;

package SemanticWeb::Schema::FinancialProduct;

# ABSTRACT: A product provided to consumers and businesses by financial institutions such as banks

use Moo;

extends qw/ SemanticWeb::Schema::Service /;


use MooX::JSON_LD 'FinancialProduct';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.8.1';


has annual_percentage_rate => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'annualPercentageRate',
);



has fees_and_commissions_specification => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'feesAndCommissionsSpecification',
);



has interest_rate => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'interestRate',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::FinancialProduct - A product provided to consumers and businesses by financial institutions such as banks

=head1 VERSION

version v3.8.1

=head1 DESCRIPTION

A product provided to consumers and businesses by financial institutions
such as banks, insurance companies, brokerage firms, consumer finance
companies, and investment companies which comprise the financial services
industry.

=head1 ATTRIBUTES

=head2 C<annual_percentage_rate>

C<annualPercentageRate>

The annual rate that is charged for borrowing (or made by investing),
expressed as a single percentage number that represents the actual yearly
cost of funds over the term of a loan. This includes any fees or additional
costs associated with the transaction.

A annual_percentage_rate should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::QuantitativeValue']>

=item C<Num>

=back

=head2 C<fees_and_commissions_specification>

C<feesAndCommissionsSpecification>

Description of fees, commissions, and other terms applied either to a class
of financial product, or by a financial service organization.

A fees_and_commissions_specification should be one of the following types:

=over

=item C<Str>

=back

=head2 C<interest_rate>

C<interestRate>

The interest rate, charged or paid, applicable to the financial product.
Note: This is different from the calculated annualPercentageRate.

A interest_rate should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::QuantitativeValue']>

=item C<Num>

=back

=head1 SEE ALSO

L<SemanticWeb::Schema::Service>

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
