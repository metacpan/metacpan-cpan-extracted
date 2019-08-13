use utf8;

package SemanticWeb::Schema::MortgageLoan;

# ABSTRACT: A loan in which property or real estate is used as collateral

use Moo;

extends qw/ SemanticWeb::Schema::LoanOrCredit /;


use MooX::JSON_LD 'MortgageLoan';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.9.0';


has domiciled_mortgage => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'domiciledMortgage',
);



has loan_mortgage_mandate_amount => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'loanMortgageMandateAmount',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::MortgageLoan - A loan in which property or real estate is used as collateral

=head1 VERSION

version v3.9.0

=head1 DESCRIPTION

A loan in which property or real estate is used as collateral. (A loan
securitized against some real estate.)

=head1 ATTRIBUTES

=head2 C<domiciled_mortgage>

C<domiciledMortgage>

Whether borrower is a resident of the jurisdiction where the property is
located.

A domiciled_mortgage should be one of the following types:

=over

=item C<Bool>

=back

=head2 C<loan_mortgage_mandate_amount>

C<loanMortgageMandateAmount>

Amount of mortgage mandate that can be converted into a proper mortgage at
a later stage.

A loan_mortgage_mandate_amount should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::MonetaryAmount']>

=back

=head1 SEE ALSO

L<SemanticWeb::Schema::LoanOrCredit>

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
