use utf8;

package SemanticWeb::Schema::MoneyTransfer;

# ABSTRACT: The act of transferring money from one place to another place

use Moo;

extends qw/ SemanticWeb::Schema::TransferAction /;


use MooX::JSON_LD 'MoneyTransfer';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v7.0.4';


has amount => (
    is        => 'rw',
    predicate => '_has_amount',
    json_ld   => 'amount',
);



has beneficiary_bank => (
    is        => 'rw',
    predicate => '_has_beneficiary_bank',
    json_ld   => 'beneficiaryBank',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::MoneyTransfer - The act of transferring money from one place to another place

=head1 VERSION

version v7.0.4

=head1 DESCRIPTION

The act of transferring money from one place to another place. This may
occur electronically or physically.

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

=head2 C<beneficiary_bank>

C<beneficiaryBank>

A bank or bankâs branch, financial institution or international financial
institution operating the beneficiaryâs bank account or releasing funds
for the beneficiary

A beneficiary_bank should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::BankOrCreditUnion']>

=item C<Str>

=back

=head2 C<_has_beneficiary_bank>

A predicate for the L</beneficiary_bank> attribute.

=head1 SEE ALSO

L<SemanticWeb::Schema::TransferAction>

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
