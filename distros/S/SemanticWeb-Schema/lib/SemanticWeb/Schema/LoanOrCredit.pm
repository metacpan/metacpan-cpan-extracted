use utf8;

package SemanticWeb::Schema::LoanOrCredit;

# ABSTRACT: A financial product for the loaning of an amount of money under agreed terms and charges.

use Moo;

extends qw/ SemanticWeb::Schema::FinancialProduct /;


use MooX::JSON_LD 'LoanOrCredit';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v0.0.4';


has amount => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'amount',
);



has loan_term => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'loanTerm',
);



has required_collateral => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'requiredCollateral',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::LoanOrCredit - A financial product for the loaning of an amount of money under agreed terms and charges.

=head1 VERSION

version v0.0.4

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

=head2 C<loan_term>

C<loanTerm>

The duration of the loan or credit agreement.

A loan_term should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::QuantitativeValue']>

=back

=head2 C<required_collateral>

C<requiredCollateral>

Assets required to secure loan or credit repayments. It may take form of
third party pledge, goods, financial instruments (cash, securities, etc.)

A required_collateral should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Thing']>

=item C<Str>

=back

=head1 SEE ALSO

L<SemanticWeb::Schema::FinancialProduct>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
