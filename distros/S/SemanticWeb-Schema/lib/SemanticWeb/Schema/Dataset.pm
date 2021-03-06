use utf8;

package SemanticWeb::Schema::Dataset;

# ABSTRACT: A body of structured information describing some topic(s) of interest.

use Moo;

extends qw/ SemanticWeb::Schema::CreativeWork /;


use MooX::JSON_LD 'Dataset';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v9.0.0';


has catalog => (
    is        => 'rw',
    predicate => '_has_catalog',
    json_ld   => 'catalog',
);



has dataset_time_interval => (
    is        => 'rw',
    predicate => '_has_dataset_time_interval',
    json_ld   => 'datasetTimeInterval',
);



has distribution => (
    is        => 'rw',
    predicate => '_has_distribution',
    json_ld   => 'distribution',
);



has included_data_catalog => (
    is        => 'rw',
    predicate => '_has_included_data_catalog',
    json_ld   => 'includedDataCatalog',
);



has included_in_data_catalog => (
    is        => 'rw',
    predicate => '_has_included_in_data_catalog',
    json_ld   => 'includedInDataCatalog',
);



has issn => (
    is        => 'rw',
    predicate => '_has_issn',
    json_ld   => 'issn',
);



has measurement_technique => (
    is        => 'rw',
    predicate => '_has_measurement_technique',
    json_ld   => 'measurementTechnique',
);



has variable_measured => (
    is        => 'rw',
    predicate => '_has_variable_measured',
    json_ld   => 'variableMeasured',
);



has variables_measured => (
    is        => 'rw',
    predicate => '_has_variables_measured',
    json_ld   => 'variablesMeasured',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::Dataset - A body of structured information describing some topic(s) of interest.

=head1 VERSION

version v9.0.0

=head1 DESCRIPTION

A body of structured information describing some topic(s) of interest.

=head1 ATTRIBUTES

=head2 C<catalog>

A data catalog which contains this dataset.

A catalog should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::DataCatalog']>

=back

=head2 C<_has_catalog>

A predicate for the L</catalog> attribute.

=head2 C<dataset_time_interval>

C<datasetTimeInterval>

The range of temporal applicability of a dataset, e.g. for a 2011 census
dataset, the year 2011 (in ISO 8601 time interval format).

A dataset_time_interval should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_dataset_time_interval>

A predicate for the L</dataset_time_interval> attribute.

=head2 C<distribution>

A downloadable form of this dataset, at a specific location, in a specific
format.

A distribution should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::DataDownload']>

=back

=head2 C<_has_distribution>

A predicate for the L</distribution> attribute.

=head2 C<included_data_catalog>

C<includedDataCatalog>

A data catalog which contains this dataset (this property was previously
'catalog', preferred name is now 'includedInDataCatalog').

A included_data_catalog should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::DataCatalog']>

=back

=head2 C<_has_included_data_catalog>

A predicate for the L</included_data_catalog> attribute.

=head2 C<included_in_data_catalog>

C<includedInDataCatalog>

A data catalog which contains this dataset.

A included_in_data_catalog should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::DataCatalog']>

=back

=head2 C<_has_included_in_data_catalog>

A predicate for the L</included_in_data_catalog> attribute.

=head2 C<issn>

The International Standard Serial Number (ISSN) that identifies this serial
publication. You can repeat this property to identify different formats of,
or the linking ISSN (ISSN-L) for, this serial publication.

A issn should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_issn>

A predicate for the L</issn> attribute.

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
href="http://schema.org/measurementTechnique">measurementTechnique</a>.<p>

A measurement_technique should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_measurement_technique>

A predicate for the L</measurement_technique> attribute.

=head2 C<variable_measured>

C<variableMeasured>

The variableMeasured property can indicate (repeated as necessary) the
variables that are measured in some dataset, either described as text or as
pairs of identifier and description using PropertyValue.

A variable_measured should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::PropertyValue']>

=item C<Str>

=back

=head2 C<_has_variable_measured>

A predicate for the L</variable_measured> attribute.

=head2 C<variables_measured>

C<variablesMeasured>

=for html <p>Originally named <a class="localLink"
href="http://schema.org/variablesMeasured">variablesMeasured</a>, The <a
class="localLink"
href="http://schema.org/variableMeasured">variableMeasured</a> property can
indicate (repeated as necessary) the variables that are measured in some
dataset, either described as text or as pairs of identifier and description
using PropertyValue.<p>

A variables_measured should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::PropertyValue']>

=item C<Str>

=back

=head2 C<_has_variables_measured>

A predicate for the L</variables_measured> attribute.

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
