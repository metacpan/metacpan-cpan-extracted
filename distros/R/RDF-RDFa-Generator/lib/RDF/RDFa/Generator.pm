=head1 NAME

RDF::RDFa::Generator - generate some data in RDFa

=cut

package RDF::RDFa::Generator;

use 5.008;
use strict;

our $VERSION = '0.103';

use RDF::RDFa::Generator::HTML::Head;
use RDF::RDFa::Generator::HTML::Hidden;
use RDF::RDFa::Generator::HTML::Pretty;
use RDF::Trine;

BEGIN
{
	$RDF::Trine::Serializer::serializer_names{ 'rdfa' }   = __PACKAGE__;
	foreach my $type (qw(application/xhtml+xml text/html))
	{
		$RDF::Trine::Serializer::media_types{ $type }   = __PACKAGE__;
	}
}

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

=item * B<data_context> - if non-null, a URI (string) which indicates the context (named graph) containing the data to generate RDFa for.

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

=item C<< $gen->create_document($model) >>

Creates a new RDFa file containing triples. $model is an RDF::Trine::Model object
providing the triples. Returns an XML::LibXML::Document object suitable
for serialising using its C<toString> method.

If you're planning on serving the RDFa with the text/html media type, then
it is recommended that you use HTML::HTML5::Writer to serialise the
document rather than C<toString>.

Can also be called as a class method:

 $document = RDF::RDFa::Generator->create_document($model)
 # Same as:
 # $document = RDF::RDFa::Generator->new->create_document($model)

=cut

sub create_document
{
	my $proto = shift;
	my $self = (ref $proto) ? $proto : $proto->new;
	return $self->create_document(@_);
}

=item C<< $gen->inject_document($document, $model) >>

Injects an existing document with triples. $document is an XML::LibXML::Document
to inject, or a well-formed XML string. $model is an RDF::Trine::Model object providing
the triples. Returns an XML::LibXML::Document object suitable
for serialising using its C<toString> method.

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

Provides triple-laden XML::LibXML::Elements to be added to a document.
$model is an RDF::Trine::Model object providing the triples. If called in
list context, returns a list of XML::LibXML::Element objects which can be
added to a document; otherwise returns an XML::LibXML::NodeList containing
a list of such elements.

Can also be called as a class method. See C<create_document> for details.

The HTML::Pretty generator can be passed a couple of additional options:

  $gen->nodes($model, notes_heading=>'Additional Info', notes=>\@notes);

The notes are a list of RDF::RDFa::Generator::HTML::Pretty::Note objects
which are added as notes to the end of each subject's data.

=cut

sub nodes
{
	my $proto = shift;
	my $self = (ref $proto) ? $proto : $proto->new;
	return $self->nodes(@_);
}

=back

Additionally the methods C<serialize_model_to_file>, C<serialize_model_to_string>,
C<serialize_iterator_to_file> and C<serialize_iterator_to_string> are provided for
compatibility with the L<RDF::Trine::Serializer> interface.

=cut

sub serialize_model_to_string
{
	my ($proto, $model) = @_;
	return $proto->create_document($model)->toString;
}

sub serialize_model_to_file
{
	my ($proto, $fh, $model) = @_;
	print {$fh} $proto->create_document($model)->toString;
}

sub serialize_iterator_to_string
{
	my ($proto, $iter) = @_;
	my $model = RDF::Trine::Model->temporary_model;
	while (my $st = $iter->next)
	{
		$model->add_statement($st);
	}
	return $proto->serialize_model_to_string($model);
}

sub serialize_iterator_to_file
{
	my ($proto, $fh, $iter) = @_;
	my $model = RDF::Trine::Model->temporary_model;
	while (my $st = $iter->next)
	{
		$model->add_statement($st);
	}
	return $proto->serialize_model_to_file($fh, $model);
}

1;

__END__

=head1 BUGS

Please report any bugs to L<http://rt.cpan.org/>.

=head1 SEE ALSO

L<HTML::HTML5::Writer>, L<XML::LibXML>, L<RDF::RDFa::Parser>, L<RDF::Trine>,
L<RDF::Prefixes>.

L<http://www.perlrdf.org/>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

Copyright (C) 2010 by Toby Inkster

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8 or,
at your option, any later version of Perl 5 you may have available.

=head2 Icons

RDF::RDFa::Generator::HTML::Pretty uses the FamFamFam Silk icons;
see L<http://famfamfam.com/lab/icons/silk/>.

=cut

