use utf8;

package SemanticWeb::Schema::PropertyValue;

# ABSTRACT: A property-value pair, e

use Moo;

extends qw/ SemanticWeb::Schema::StructuredValue /;


use MooX::JSON_LD 'PropertyValue';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.8.1';


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



has property_id => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'propertyID',
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



has value => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'value',
);



has value_reference => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'valueReference',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::PropertyValue - A property-value pair, e

=head1 VERSION

version v3.8.1

=head1 DESCRIPTION

=for html A property-value pair, e.g. representing a feature of a product or place.
Use the 'name' property for the name of the property. If there is an
additional human-readable version of the value, put that into the
'description' property.<br/><br/> Always use specific schema.org properties
when a) they exist and b) you can populate them. Using PropertyValue as a
substitute will typically not trigger the same effect as using the
original, specific property.

=head1 ATTRIBUTES

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

=head2 C<property_id>

C<propertyID>

A commonly used identifier for the characteristic represented by the
property, e.g. a manufacturer or a standard code for a property. propertyID
can be (1) a prefixed string, mainly meant to be used with standards for
product properties; (2) a site-specific, non-prefixed string (e.g. the
primary key of the property or the vendor-specific id of the property), or
(3) a URL indicating the type of the property, either pointing to an
external vocabulary, or a Web resource that describes the property (e.g. a
glossary entry). Standards bodies should promote a standard prefix for the
identifiers of properties from their standards.

A property_id should be one of the following types:

=over

=item C<Str>

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

=head2 C<value_reference>

C<valueReference>

A pointer to a secondary value that provides additional information on the
original value, e.g. a reference temperature.

A value_reference should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Enumeration']>

=item C<InstanceOf['SemanticWeb::Schema::PropertyValue']>

=item C<InstanceOf['SemanticWeb::Schema::QualitativeValue']>

=item C<InstanceOf['SemanticWeb::Schema::QuantitativeValue']>

=item C<InstanceOf['SemanticWeb::Schema::StructuredValue']>

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
