use utf8;

package SemanticWeb::Schema::BrokerageAccount;

# ABSTRACT: An account that allows an investor to deposit funds and place investment orders with a licensed broker or brokerage firm.

use Moo;

extends qw/ SemanticWeb::Schema::InvestmentOrDeposit /;


use MooX::JSON_LD 'BrokerageAccount';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v4.0.1';




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::BrokerageAccount - An account that allows an investor to deposit funds and place investment orders with a licensed broker or brokerage firm.

=head1 VERSION

version v4.0.1

=head1 DESCRIPTION

An account that allows an investor to deposit funds and place investment
orders with a licensed broker or brokerage firm.

=head1 SEE ALSO

L<SemanticWeb::Schema::InvestmentOrDeposit>

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
