use utf8;

package SemanticWeb::Schema::AggregateOffer;

# ABSTRACT: When a single product is associated with multiple offers (for example

use Moo;

extends qw/ SemanticWeb::Schema::Offer /;


use MooX::JSON_LD 'AggregateOffer';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.8.1';


has high_price => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'highPrice',
);



has low_price => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'lowPrice',
);



has offer_count => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'offerCount',
);



has offers => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'offers',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::AggregateOffer - When a single product is associated with multiple offers (for example

=head1 VERSION

version v3.8.1

=head1 DESCRIPTION

When a single product is associated with multiple offers (for example, the
same pair of shoes is offered by different merchants), then AggregateOffer
can be used.

=head1 ATTRIBUTES

=head2 C<high_price>

C<highPrice>

=for html The highest price of all offers available.<br/><br/> Usage
guidelines:<br/><br/> <ul> <li>Use values from 0123456789 (Unicode 'DIGIT
ZERO' (U+0030) to 'DIGIT NINE' (U+0039)) rather than superficially similiar
Unicode symbols.</li> <li>Use '.' (Unicode 'FULL STOP' (U+002E)) rather
than ',' to indicate a decimal point. Avoid using these symbols as a
readability separator.</li> </ul> 

A high_price should be one of the following types:

=over

=item C<Num>

=item C<Str>

=back

=head2 C<low_price>

C<lowPrice>

=for html The lowest price of all offers available.<br/><br/> Usage
guidelines:<br/><br/> <ul> <li>Use values from 0123456789 (Unicode 'DIGIT
ZERO' (U+0030) to 'DIGIT NINE' (U+0039)) rather than superficially similiar
Unicode symbols.</li> <li>Use '.' (Unicode 'FULL STOP' (U+002E)) rather
than ',' to indicate a decimal point. Avoid using these symbols as a
readability separator.</li> </ul> 

A low_price should be one of the following types:

=over

=item C<Num>

=item C<Str>

=back

=head2 C<offer_count>

C<offerCount>

The number of offers for the product.

A offer_count should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Integer']>

=back

=head2 C<offers>

An offer to provide this item&#x2014;for example, an offer to sell a
product, rent the DVD of a movie, perform a service, or give away tickets
to an event.

A offers should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Offer']>

=back

=head1 SEE ALSO

L<SemanticWeb::Schema::Offer>

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
