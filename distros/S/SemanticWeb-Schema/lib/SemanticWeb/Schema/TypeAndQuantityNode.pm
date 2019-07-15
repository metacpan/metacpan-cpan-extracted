use utf8;

package SemanticWeb::Schema::TypeAndQuantityNode;

# ABSTRACT: A structured value indicating the quantity

use Moo;

extends qw/ SemanticWeb::Schema::StructuredValue /;


use MooX::JSON_LD 'TypeAndQuantityNode';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.8.1';


has amount_of_this_good => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'amountOfThisGood',
);



has business_function => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'businessFunction',
);



has type_of_good => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'typeOfGood',
);



has unit_code => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'unitCode',
);



has unit_text => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'unitText',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::TypeAndQuantityNode - A structured value indicating the quantity

=head1 VERSION

version v3.8.1

=head1 DESCRIPTION

A structured value indicating the quantity, unit of measurement, and
business function of goods included in a bundle offer.

=head1 ATTRIBUTES

=head2 C<amount_of_this_good>

C<amountOfThisGood>

The quantity of the goods included in the offer.

A amount_of_this_good should be one of the following types:

=over

=item C<Num>

=back

=head2 C<business_function>

C<businessFunction>

The business function (e.g. sell, lease, repair, dispose) of the offer or
component of a bundle (TypeAndQuantityNode). The default is
http://purl.org/goodrelations/v1#Sell.

A business_function should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::BusinessFunction']>

=back

=head2 C<type_of_good>

C<typeOfGood>

The product that this structured value is referring to.

A type_of_good should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Product']>

=item C<InstanceOf['SemanticWeb::Schema::Service']>

=back

=head2 C<unit_code>

C<unitCode>

The unit of measurement given using the UN/CEFACT Common Code (3
characters) or a URL. Other codes than the UN/CEFACT Common Code may be
used with a prefix followed by a colon.

A unit_code should be one of the following types:

=over

=item C<Str>

=back

=head2 C<unit_text>

C<unitText>

=for html A string or text indicating the unit of measurement. Useful if you cannot
provide a standard unit code for <a href='unitCode'>unitCode</a>.

A unit_text should be one of the following types:

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
