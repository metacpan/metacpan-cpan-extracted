use utf8;

package SemanticWeb::Schema::DataCatalog;

# ABSTRACT: A collection of datasets.

use Moo;

extends qw/ SemanticWeb::Schema::CreativeWork /;


use MooX::JSON_LD 'DataCatalog';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v7.0.0';


has dataset => (
    is        => 'rw',
    predicate => '_has_dataset',
    json_ld   => 'dataset',
);



has measurement_technique => (
    is        => 'rw',
    predicate => '_has_measurement_technique',
    json_ld   => 'measurementTechnique',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::DataCatalog - A collection of datasets.

=head1 VERSION

version v7.0.0

=head1 DESCRIPTION

A collection of datasets.

=head1 ATTRIBUTES

=head2 C<dataset>

A dataset contained in this catalog.

A dataset should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Dataset']>

=back

=head2 C<_has_dataset>

A predicate for the L</dataset> attribute.

=head2 C<measurement_technique>

C<measurementTechnique>

=for html <p>A technique or technology used in a <a class="localLink"
href="http://schema.org/Dataset">Dataset</a> (or <a class="localLink"
href="http://schema.org/DataDownload">DataDownload</a>, <a
class="localLink" href="http://schema.org/DataCatalog">DataCatalog</a>),
corresponding to the method used for measuring the corresponding
variable(s) (described using <a class="localLink"
href="http://schema.org/variableMeasured">variableMeasured</a>). This is
oriented towards scientific and scholarly dataset publication but may have
broader applicability; it is not intended as a full representation of
measurement, but rather as a high level summary for dataset
discovery.<br/><br/> For example, if <a class="localLink"
href="http://schema.org/variableMeasured">variableMeasured</a> is: molecule
concentration, <a class="localLink"
href="http://schema.org/measurementTechnique">measurementTechnique</a>
could be: "mass spectrometry" or "nmr spectroscopy" or "colorimetry" or
"immunofluorescence".<br/><br/> If the <a class="localLink"
href="http://schema.org/variableMeasured">variableMeasured</a> is
"depression rating", the <a class="localLink"
href="http://schema.org/measurementTechnique">measurementTechnique</a>
could be "Zung Scale" or "HAM-D" or "Beck Depression Inventory".<br/><br/>
If there are several <a class="localLink"
href="http://schema.org/variableMeasured">variableMeasured</a> properties
recorded for some given data object, use a <a class="localLink"
href="http://schema.org/PropertyValue">PropertyValue</a> for each <a
class="localLink"
href="http://schema.org/variableMeasured">variableMeasured</a> and attach
the corresponding <a class="localLink"
href="http://schema.org/measurementTechnique">measurementTechnique</a>.]]><
/rdfs:comment> <schema:domainIncludes
rdf:resource="http://schema.org/Dataset"/> <schema:isPartOf
rdf:resource="http://pending.schema.org"/> <schema:domainIncludes
rdf:resource="http://schema.org/DataDownload"/>
<schema:category>issue-1425</schema:category> </rdf:Property>
<schema:HealthAspectEnumeration
rdf:about="http://schema.org/LivingWithHealthAspect"> <schema:isPartOf
rdf:resource="http://pending.schema.org"/>
<rdfs:label>LivingWithHealthAspect</rdfs:label>
<schema:category>issue-2374</schema:category> <rdfs:comment>Information
about coping or life related to the topic.</rdfs:comment> <dct:source
rdf:resource="https://github.com/schemaorg/schemaorg/issues/2374"/>
</schema:HealthAspectEnumeration> <rdf:Property
rdf:about="http://schema.org/termsOfService"> <rdfs:comment>Human-readable
terms of service documentation.</rdfs:comment> <schema:isPartOf
rdf:resource="http://pending.schema.org"/>
<schema:category>issue-1423</schema:category> <dct:source
rdf:resource="https://github.com/schemaorg/schemaorg/issues/1423"/>
<schema:domainIncludes rdf:resource="http://schema.org/Service"/>
<schema:rangeIncludes rdf:resource="http://schema.org/URL"/>
<schema:rangeIncludes rdf:resource="http://schema.org/Text"/>
<rdfs:label>termsOfService</rdfs:label> </rdf:Property>
<schema:ReturnFeesEnumeration
rdf:about="http://schema.org/OriginalShippingFees">
<rdfs:comment>OriginalShippingFees ...</rdfs:comment>
<rdfs:label>OriginalShippingFees</rdfs:label> <schema:isPartOf
rdf:resource="http://pending.schema.org"/>
<schema:category>issue-2288</schema:category> <dct:source
rdf:resource="https://github.com/schemaorg/schemaorg/issues/2288"/>
</schema:ReturnFeesEnumeration> <rdf:Property
rdf:about="http://schema.org/timeToComplete"> <dct:source
rdf:resource="https://github.com/schemaorg/schemaorg/issues/2289"/>
<schema:rangeIncludes rdf:resource="http://schema.org/Duration"/>
<rdfs:label>timeToComplete</rdfs:label> <schema:domainIncludes
rdf:resource="http://schema.org/EducationalOccupationalProgram"/>
<schema:category>issue-2289</schema:category> <rdfs:comment>The expected
length of time to complete the program if attending
full-time.</rdfs:comment> <schema:isPartOf
rdf:resource="http://pending.schema.org"/> </rdf:Property> <rdfs:Class
rdf:about="http://schema.org/PodcastSeason"> <rdfs:subClassOf
rdf:resource="http://schema.org/CreativeWorkSeason"/> <dct:source
rdf:resource="https://github.com/schemaorg/schemaorg/issues/373"/>
<schema:category>issue-373</schema:category> <schema:isPartOf
rdf:resource="http://pending.schema.org"/> <rdfs:comment>A single season of
a podcast. Many podcasts do not break down into separate seasons. In that
case, PodcastSeries should be used.</rdfs:comment>
<rdfs:label>PodcastSeason</rdfs:label> </rdfs:Class> <rdf:Property
rdf:about="http://schema.org/phoneticText"> <dct:source
rdf:resource="https://github.com/schemaorg/schemaorg/issues/2108"/>
<schema:domainIncludes rdf:resource="http://schema.org/PronounceableText"/>
<rdfs:label>phoneticText</rdfs:label> <schema:rangeIncludes
rdf:resource="http://schema.org/Text"/>
<schema:category>issue-2108</schema:category> <schema:isPartOf
rdf:resource="http://pending.schema.org"/>
<rdfs:comment><![CDATA[Representation of a text <a class="localLink"
href="http://schema.org/textValue">textValue</a> using the specified <a
class="localLink"
href="http://schema.org/speechToTextMarkup">speechToTextMarkup</a>. For
example the city name of Houston in IPA: /ËhjuËstÉn/.<p>

A measurement_technique should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_measurement_technique>

A predicate for the L</measurement_technique> attribute.

=head1 SEE ALSO

L<SemanticWeb::Schema::CreativeWork>

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

This software is Copyright (c) 2018-2020 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
