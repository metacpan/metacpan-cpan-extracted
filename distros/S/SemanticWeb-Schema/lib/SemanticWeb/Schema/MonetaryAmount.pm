use utf8;

package SemanticWeb::Schema::MonetaryAmount;

# ABSTRACT: A monetary value or range

use Moo;

extends qw/ SemanticWeb::Schema::StructuredValue /;


use MooX::JSON_LD 'MonetaryAmount';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.8.1';


has currency => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'currency',
);



has max_value => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'maxValue',
);



has min_value => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'minValue',
);



has valid_from => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'validFrom',
);



has valid_through => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'validThrough',
);



has value => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'value',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::MonetaryAmount - A monetary value or range

=head1 VERSION

version v3.8.1

=head1 DESCRIPTION

=for html A monetary value or range. This type can be used to describe an amount of
money such as $50 USD, or a range as in describing a bank account being
suitable for a balance between Â£1,000 and Â£1,000,000 GBP, or the value of
a salary, etc. It is recommended to use <a class="localLink"
href="http://schema.org/PriceSpecification">PriceSpecification</a> Types to
describe the price of an Offer, Invoice, etc.

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

=head2 C<max_value>

C<maxValue>

The upper value of some characteristic or property.

A max_value should be one of the following types:

=over

=item C<Num>

=back

=head2 C<min_value>

C<minValue>

The lower value of some characteristic or property.

A min_value should be one of the following types:

=over

=item C<Num>

=back

=head2 C<valid_from>

C<validFrom>

The date when the item becomes valid.

A valid_from should be one of the following types:

=over

=item C<Str>

=back

=head2 C<valid_through>

C<validThrough>

The date after when the item is not valid. For example the end of an offer,
salary period, or a period of opening hours.

A valid_through should be one of the following types:

=over

=item C<Str>

=back

=head2 C<value>

=for html The value of the quantitative value or property value node.<br/><br/> <ul>
<li>For <a class="localLink"
href="http://schema.org/QuantitativeValue">QuantitativeValue</a> and <a
class="localLink"
href="http://schema.org/MonetaryAmount">MonetaryAmount</a>, the recommended
type for values is 'Number'.</li> <li>For <a class="localLink"
href="http://schema.org/PropertyValue">PropertyValue</a>, it can be
'Text;', 'Number', 'Boolean', or 'StructuredValue'.</li> <li>Use values
from 0123456789 (Unicode 'DIGIT ZERO' (U+0030) to 'DIGIT NINE' (U+0039))
rather than superficially similiar Unicode symbols.</li> <li>Use '.'
(Unicode 'FULL STOP' (U+002E)) rather than ',' to indicate a decimal point.
Avoid using these symbols as a readability separator.</li> </ul> 

A value should be one of the following types:

=over

=item C<Bool>

=item C<InstanceOf['SemanticWeb::Schema::StructuredValue']>

=item C<Num>

=item C<Str>

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
