=head1 NAME

RDF::RDFa::Generator - Generate data for RDFa serialization

=cut

package RDF::RDFa::Generator;

use 5.008;
use strict;

use warnings;


our $VERSION = '0.204';

use RDF::RDFa::Generator::HTML::Head;
use RDF::RDFa::Generator::HTML::Hidden;
use RDF::RDFa::Generator::HTML::Pretty;
use Carp;


=head1 DESCRIPTION

=head2 Constructor

=over 4

=item C<< $gen = RDF::RDFa::Generator->new(style => $style, %options) >>

Creates a new generator object. $style is one of the following case-sensitive strings:
'HTML::Head' (the default), 'HTML::Hidden' or 'HTML::Pretty'. You can also construct
an object like this:

  $gen = RDF::RDFa::Generator::HTML::Head->new(%options);

Options include:

=over 4

=item * B<base> - the base URL where the output data will be published. This allows in some cases for the generated RDFa to include relative URIs.

=item * B<data_context> - if non-null, an L<Attean> Blank or IRI object or an L<RDF::Trine::Node> which indicates the context (named graph) containing the data to generate RDFa for.

=item * B<namespacemap> - a L<URI::NamespaceMap> object containing preferred CURIE prefixes. This is the preferred method, see note below. 

=item * B<namespaces> - a {prefix=>uri} hashref of preferred CURIE prefixes. 

=item * B<ns> - a {uri=>prefix} hashref of preferred CURIE prefixes. DEPRECATED - use B<namespaces> instead.

=item * B<prefix_attr> - use the @prefix attribute for CURIE prefixes (RDFa 1.1 only).  Boolean, defaults to false.

=item * B<safe_xml_literals> - prevents XML literals from injecting arbitrary XHTML into the output. Boolean, B<defaults to FALSE>.

=item * B<title> - assign a <title> element for generated XHTML documents.

=item * B<version> - set generated RDFa version. Valid values are '1.0' (the default) or '1.1'.

=back

=back

=cut

sub new
{
	my ($class, %opts) = @_;
	my $implementation = sprintf('%s::%s', __PACKAGE__, $opts{'style'} || 'HTML::Head');
	return $implementation->new(%opts);
}

=head2 Public Methods

=over 4

=item C<< $gen->create_document($model, %opts) >>

Creates a new RDFa file containing triples. $model is an L<Attean::QuadModel> (where the graph name is not used) object
providing the triples. Returns an L<XML::LibXML::Document> object suitable
for serializing using its C<toString> method.

If you're planning on serving the RDFa with the text/html media type, then
it is recommended that you use HTML::HTML5::Writer to serialize the
document rather than C<toString>.

Can also be called as a class method:

 $document = RDF::RDFa::Generator->create_document($model)
 # Same as:
 # $document = RDF::RDFa::Generator->new->create_document($model)

Options can also be passed as a HASH. This is typically used for style-specific options.

=cut

sub create_document
{
	my $proto = shift;
	my $self = (ref $proto) ? $proto : $proto->new;
	return $self->create_document(@_);
}

=item C<< $gen->inject_document($document, $model) >>

Injects an existing document with triples. $document is an L<XML::LibXML::Document>
to inject, or a well-formed XML string. $model is an L<Attean::QuadModel> (where the graph name is not used) object providing
the triples. Returns an L<XML::LibXML::Document> object suitable
for serializing using its C<toString> method.

See C<create_document> for information about serving the RDFa with the
text/html media type.

Can also be called as a class method. See C<create_document> for details.

=cut

sub inject_document
{
	my $proto = shift;
	my $self = (ref $proto) ? $proto : $proto->new;
	return $self->inject_document(@_);
}

=item C<< $gen->nodes($model) >>

Provides triple-laden L<XML::LibXML::Elements> to be added to a document.
$model is an L<Attean::QuadModel> (where the graph name is not used) object providing the triples. If called in
list context, returns a list of L<XML::LibXML::Element> objects which can be
added to a document; otherwise returns an L<XML::LibXML::NodeList> containing
a list of such elements.

Can also be called as a class method. See C<create_document> for details.

The HTML::Pretty generator can be passed a couple of additional options:

  $gen->nodes($model, notes_heading=>'Additional Info', notes=>\@notes);

The notes are a list of L<RDF::RDFa::Generator::HTML::Pretty::Note> objects
which are added as notes to the end of each subject's data.

=cut

sub nodes
{
	my $proto = shift;
	my $self = (ref $proto) ? $proto : $proto->new;
	return $self->nodes(@_);
}

=back

=head1 UPGRADING TO 0.200

The recommended upgrade path is to migrate your application to use
L<Attean> rather than L<RDF::Trine> as your RDF library. If that is
not an option, you may continue to use L<RDF::Trine>, by using a
compatibility layer.  If you are using this module directly, to
upgrade from earlier releases, you would simply add

 use RDF::TrineX::Compatibility::Attean;

alongside the import of this module. It is in a separate distribution
that needs to be installed. If you use the L<RDF::Trine::Serializer>
methods, you should instead use L<RDF::Trine::Serializer::RDFa>.

=head1 NOTE

Version 0.200 introduced a large number of changes to be compatible
with both L<Attean> and L<RDF::Trine>. Some of these were
backwards-incompatible, some were to support new features, such as the
use of L<URI::NamespaceMap>.

=head2 Backwards-incompatible changes

The methods C<serialize_model_to_file>, C<serialize_model_to_string>,
C<serialize_iterator_to_file> and C<serialize_iterator_to_string> that
were provided for compatibility with the L<RDF::Trine::Serializer>
interface have been moved to a module L<RDF::Trine::Serializer::RDFa>
that has to be installed separately to use this with L<RDF::Trine>.

C<data_context> previously accepted a plain-text string URI. Now, it
requires an appropriate object, as documented.

Since RDF 1.1 abandons untyped literals, this module also ceases to
emit them.

=head2 Namespace mappings

The way namespace mappings are handled have been rewritten. Now, the
preferred method to add them is to pass an L<URI::NamespaceMap> object
to C<namespacemap>. This will override any other options.

The namespace mappings for the following prefixes will always be
added: C<rdfa>, C<rdf>, C<rdfs> and C<xsd>.

If L<URI::NamespaceMap> is not used, but C<namespaces> is given as a
hashref of prefix-URI pairs, the pairs will be added. If neither are
given, all mappings from L<RDF::NS::Curated>, which includes all if
RDFa Initial Context will be added. Finally, any pairs from the
deprecated C<ns> option will be added, but a warning will be emitted.

=cut

sub serialize_model_to_string {
  croak 'serialize_model_to_string have been to moved RDF::Trine::Serializer::RDFa';
}

sub serialize_model_to_file {
  croak 'serialize_model_to_file have been to moved RDF::Trine::Serializer::RDFa';
}

sub serialize_iterator_to_string {
  croak 'serialize_iterator_to_string have been to moved RDF::Trine::Serializer::RDFa';
}

sub serialize_iterator_to_file {
  croak 'serialize_iterator_to_string have been to moved RDF::Trine::Serializer::RDFa';
}

1;

__END__

=head1 BUGS

Please report any bugs to L<https://github.com/kjetilk/p5-rdf-rdfa-generator/issues>.

=head1 SEE ALSO

You may want to use the framework-specific frontends: L<RDF::Trine::Serializer::RDFa> or L<AtteanX::Serializer::RDFa>.

Other relevant modules:

L<HTML::HTML5::Writer>, L<XML::LibXML>, L<RDF::RDFa::Parser>, L<RDF::Trine>,
L<URI::NamespaceMap>, L<Attean>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

Kjetil Kjernsmo E<lt>kjetilk@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

Copyright (C) 2010 by Toby Inkster, 2017, 2018 Kjetil Kjernsmo

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8 or,
at your option, any later version of Perl 5 you may have available.

=head2 Icons

RDF::RDFa::Generator::HTML::Pretty uses the FamFamFam Silk icons;
see L<http://famfamfam.com/lab/icons/silk/>.

=cut

