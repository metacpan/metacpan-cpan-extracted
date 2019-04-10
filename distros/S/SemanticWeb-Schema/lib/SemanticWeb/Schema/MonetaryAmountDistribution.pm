use utf8;

package SemanticWeb::Schema::MonetaryAmountDistribution;

# ABSTRACT: A statistical distribution of monetary amounts.

use Moo;

extends qw/ SemanticWeb::Schema::QuantitativeValueDistribution /;


use MooX::JSON_LD 'MonetaryAmountDistribution';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.5.0';


has currency => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'currency',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::MonetaryAmountDistribution - A statistical distribution of monetary amounts.

=head1 VERSION

version v3.5.0

=head1 DESCRIPTION

A statistical distribution of monetary amounts.

=head1 ATTRIBUTES

=head2 C<currency>

=for html The currency in which the monetary amount is expressed.<br/><br/> Use
standard formats: <a href="http://en.wikipedia.org/wiki/ISO_4217">ISO 4217
currency format</a> e.g. "USD"; <a
href="https://en.wikipedia.org/wiki/List_of_cryptocurrencies">Ticker
symbol</a> for cryptocurrencies e.g. "BTC"; well known names for <a
href="https://en.wikipedia.org/wiki/Local_exchange_trading_system">Local
Exchange Tradings Systems</a> (LETS) and other currency types e.g. "Ithaca
HOUR".

A currency should be one of the following types:

=over

=item C<Str>

=back

=head1 SEE ALSO

L<SemanticWeb::Schema::QuantitativeValueDistribution>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
