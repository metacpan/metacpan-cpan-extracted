use utf8;

package SemanticWeb::Schema::BankAccount;

# ABSTRACT: A product or service offered by a bank whereby one may deposit

use Moo;

extends qw/ SemanticWeb::Schema::FinancialProduct /;


use MooX::JSON_LD 'BankAccount';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v7.0.3';


has account_minimum_inflow => (
    is        => 'rw',
    predicate => '_has_account_minimum_inflow',
    json_ld   => 'accountMinimumInflow',
);



has account_overdraft_limit => (
    is        => 'rw',
    predicate => '_has_account_overdraft_limit',
    json_ld   => 'accountOverdraftLimit',
);



has bank_account_type => (
    is        => 'rw',
    predicate => '_has_bank_account_type',
    json_ld   => 'bankAccountType',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::BankAccount - A product or service offered by a bank whereby one may deposit

=head1 VERSION

version v7.0.3

=head1 DESCRIPTION

A product or service offered by a bank whereby one may deposit, withdraw or
transfer money and in some cases be paid interest.

=head1 ATTRIBUTES

=head2 C<account_minimum_inflow>

C<accountMinimumInflow>

A minimum amount that has to be paid in every month.

A account_minimum_inflow should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::MonetaryAmount']>

=back

=head2 C<_has_account_minimum_inflow>

A predicate for the L</account_minimum_inflow> attribute.

=head2 C<account_overdraft_limit>

C<accountOverdraftLimit>

An overdraft is an extension of credit from a lending institution when an
account reaches zero. An overdraft allows the individual to continue
withdrawing money even if the account has no funds in it. Basically the
bank allows people to borrow a set amount of money.

A account_overdraft_limit should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::MonetaryAmount']>

=back

=head2 C<_has_account_overdraft_limit>

A predicate for the L</account_overdraft_limit> attribute.

=head2 C<bank_account_type>

C<bankAccountType>

The type of a bank account.

A bank_account_type should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_bank_account_type>

A predicate for the L</bank_account_type> attribute.

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

This software is Copyright (c) 2018-2020 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
