use utf8;

package SemanticWeb::Schema::DatedMoneySpecification;

# ABSTRACT: A DatedMoneySpecification represents monetary values with optional start and end dates

use Moo;

extends qw/ SemanticWeb::Schema::StructuredValue /;


use MooX::JSON_LD 'DatedMoneySpecification';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.8.1';


has amount => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'amount',
);



has currency => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'currency',
);



has end_date => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'endDate',
);



has start_date => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'startDate',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::DatedMoneySpecification - A DatedMoneySpecification represents monetary values with optional start and end dates

=head1 VERSION

version v3.8.1

=head1 DESCRIPTION

=for html A DatedMoneySpecification represents monetary values with optional start
and end dates. For example, this could represent an employee's salary over
a specific period of time. <strong>Note:</strong> This type has been
superseded by <a class="localLink"
href="http://schema.org/MonetaryAmount">MonetaryAmount</a> use of that type
is recommended

=head1 ATTRIBUTES

=head2 C<amount>

The amount of money.

A amount should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::MonetaryAmount']>

=item C<Num>

=back

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

=head2 C<end_date>

C<endDate>

=for html The end date and time of the item (in <a
href="http://en.wikipedia.org/wiki/ISO_8601">ISO 8601 date format</a>).

A end_date should be one of the following types:

=over

=item C<Str>

=back

=head2 C<start_date>

C<startDate>

=for html The start date and time of the item (in <a
href="http://en.wikipedia.org/wiki/ISO_8601">ISO 8601 date format</a>).

A start_date should be one of the following types:

=over

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
