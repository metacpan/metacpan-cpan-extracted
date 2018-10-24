use utf8;

package SemanticWeb::Schema::DepositAccount;

# ABSTRACT: A type of Bank Account with a main purpose of depositing funds to gain interest or other benefits.

use Moo;

extends qw/ SemanticWeb::Schema::BankAccount SemanticWeb::Schema::InvestmentOrDeposit /;


use MooX::JSON_LD 'DepositAccount';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v0.0.2';




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::DepositAccount - A type of Bank Account with a main purpose of depositing funds to gain interest or other benefits.

=head1 VERSION

version v0.0.2

=head1 DESCRIPTION

A type of Bank Account with a main purpose of depositing funds to gain
interest or other benefits.

=head1 SEE ALSO

L<SemanticWeb::Schema::InvestmentOrDeposit>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
