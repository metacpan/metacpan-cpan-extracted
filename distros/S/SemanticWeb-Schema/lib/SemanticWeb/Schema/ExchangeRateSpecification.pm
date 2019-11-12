use utf8;

package SemanticWeb::Schema::ExchangeRateSpecification;

# ABSTRACT: A structured value representing exchange rate.

use Moo;

extends qw/ SemanticWeb::Schema::StructuredValue /;


use MooX::JSON_LD 'ExchangeRateSpecification';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v5.0.0';


has currency => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'currency',
);



has current_exchange_rate => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'currentExchangeRate',
);



has exchange_rate_spread => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'exchangeRateSpread',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::ExchangeRateSpecification - A structured value representing exchange rate.

=head1 VERSION

version v5.0.0

=head1 DESCRIPTION

A structured value representing exchange rate.

=head1 ATTRIBUTES

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

=head2 C<current_exchange_rate>

C<currentExchangeRate>

The current price of a currency.

A current_exchange_rate should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::UnitPriceSpecification']>

=back

=head2 C<exchange_rate_spread>

C<exchangeRateSpread>

The difference between the price at which a broker or other intermediary
buys and sells foreign currency.

A exchange_rate_spread should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::MonetaryAmount']>

=item C<Num>

=back

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

This software is Copyright (c) 2018-2019 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
