use utf8;

package SemanticWeb::Schema::Ticket;

# ABSTRACT: Used to describe a ticket to an event

use Moo;

extends qw/ SemanticWeb::Schema::Intangible /;


use MooX::JSON_LD 'Ticket';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v5.0.1';


has date_issued => (
    is        => 'rw',
    predicate => '_has_date_issued',
    json_ld   => 'dateIssued',
);



has issued_by => (
    is        => 'rw',
    predicate => '_has_issued_by',
    json_ld   => 'issuedBy',
);



has price_currency => (
    is        => 'rw',
    predicate => '_has_price_currency',
    json_ld   => 'priceCurrency',
);



has ticket_number => (
    is        => 'rw',
    predicate => '_has_ticket_number',
    json_ld   => 'ticketNumber',
);



has ticket_token => (
    is        => 'rw',
    predicate => '_has_ticket_token',
    json_ld   => 'ticketToken',
);



has ticketed_seat => (
    is        => 'rw',
    predicate => '_has_ticketed_seat',
    json_ld   => 'ticketedSeat',
);



has total_price => (
    is        => 'rw',
    predicate => '_has_total_price',
    json_ld   => 'totalPrice',
);



has under_name => (
    is        => 'rw',
    predicate => '_has_under_name',
    json_ld   => 'underName',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::Ticket - Used to describe a ticket to an event

=head1 VERSION

version v5.0.1

=head1 DESCRIPTION

Used to describe a ticket to an event, a flight, a bus ride, etc.

=head1 ATTRIBUTES

=head2 C<date_issued>

C<dateIssued>

The date the ticket was issued.

A date_issued should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_date_issued>

A predicate for the L</date_issued> attribute.

=head2 C<issued_by>

C<issuedBy>

The organization issuing the ticket or permit.

A issued_by should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Organization']>

=back

=head2 C<_has_issued_by>

A predicate for the L</issued_by> attribute.

=head2 C<price_currency>

C<priceCurrency>

=for html <p>The currency of the price, or a price component when attached to <a
class="localLink"
href="http://schema.org/PriceSpecification">PriceSpecification</a> and its
subtypes.<br/><br/> Use standard formats: <a
href="http://en.wikipedia.org/wiki/ISO_4217">ISO 4217 currency format</a>
e.g. "USD"; <a
href="https://en.wikipedia.org/wiki/List_of_cryptocurrencies">Ticker
symbol</a> for cryptocurrencies e.g. "BTC"; well known names for <a
href="https://en.wikipedia.org/wiki/Local_exchange_trading_system">Local
Exchange Tradings Systems</a> (LETS) and other currency types e.g. "Ithaca
HOUR".<p>

A price_currency should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_price_currency>

A predicate for the L</price_currency> attribute.

=head2 C<ticket_number>

C<ticketNumber>

The unique identifier for the ticket.

A ticket_number should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_ticket_number>

A predicate for the L</ticket_number> attribute.

=head2 C<ticket_token>

C<ticketToken>

Reference to an asset (e.g., Barcode, QR code image or PDF) usable for
entrance.

A ticket_token should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_ticket_token>

A predicate for the L</ticket_token> attribute.

=head2 C<ticketed_seat>

C<ticketedSeat>

The seat associated with the ticket.

A ticketed_seat should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Seat']>

=back

=head2 C<_has_ticketed_seat>

A predicate for the L</ticketed_seat> attribute.

=head2 C<total_price>

C<totalPrice>

=for html <p>The total price for the reservation or ticket, including applicable
taxes, shipping, etc.<br/><br/> Usage guidelines:<br/><br/> <ul> <li>Use
values from 0123456789 (Unicode 'DIGIT ZERO' (U+0030) to 'DIGIT NINE'
(U+0039)) rather than superficially similiar Unicode symbols.</li> <li>Use
'.' (Unicode 'FULL STOP' (U+002E)) rather than ',' to indicate a decimal
point. Avoid using these symbols as a readability separator.</li> </ul> <p>

A total_price should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::PriceSpecification']>

=item C<Num>

=item C<Str>

=back

=head2 C<_has_total_price>

A predicate for the L</total_price> attribute.

=head2 C<under_name>

C<underName>

The person or organization the reservation or ticket is for.

A under_name should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Organization']>

=item C<InstanceOf['SemanticWeb::Schema::Person']>

=back

=head2 C<_has_under_name>

A predicate for the L</under_name> attribute.

=head1 SEE ALSO

L<SemanticWeb::Schema::Intangible>

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
