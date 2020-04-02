use utf8;

package SemanticWeb::Schema::DataDownload;

# ABSTRACT: A dataset in downloadable form.

use Moo;

extends qw/ SemanticWeb::Schema::MediaObject /;


use MooX::JSON_LD 'DataDownload';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v7.0.2';


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

SemanticWeb::Schema::DataDownload - A dataset in downloadable form.

=head1 VERSION

version v7.0.2

=head1 DESCRIPTION

A dataset in downloadable form.

=head1 ATTRIBUTES

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

=head1 SEE ALSO

L<SemanticWeb::Schema::MediaObject>

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
