package RDF::RDFa::Parser::OpenDocumentObjectModel;

BEGIN {
	$RDF::RDFa::Parser::OpenDocumentObjectModel::AUTHORITY = 'cpan:TOBYINK';
	$RDF::RDFa::Parser::OpenDocumentObjectModel::VERSION   = '1.097';	
}

our @Types = qw(
	application/vnd.oasis.opendocument.chart
	application/vnd.oasis.opendocument.database
	application/vnd.oasis.opendocument.formula
	application/vnd.oasis.opendocument.graphics
	application/vnd.oasis.opendocument.graphics-template
	application/vnd.oasis.opendocument.image
	application/vnd.oasis.opendocument.presentation
	application/vnd.oasis.opendocument.presentation-template
	application/vnd.oasis.opendocument.spreadsheet
	application/vnd.oasis.opendocument.spreadsheet-template
	application/vnd.oasis.opendocument.text
	application/vnd.oasis.opendocument.text-master
	application/vnd.oasis.opendocument.text-template
	application/vnd.oasis.opendocument.text-web
	);

use File::Temp qw':seekable';
use Scalar::Util qw'blessed';
use URI;
use URI::file;
use XML::LibXML qw':all';

use constant DOM_NS => 'http://purl.org/NET/cpan-uri/dist/RDF-RDFa-Parser/opendocument-dom-wrapper';
use constant XHTML_NS => 'http://www.w3.org/1999/xhtml';

BEGIN
{
	eval 'use Archive::Zip;';
}

sub new
{
	my ($class) = @_;
	die "Need Archive::Zip installed to parse OpenDocument files.\n"
		unless $class->usable;
	return bless {}, $class;
}

sub usable
{
	return Archive::Zip->can('new');
}

sub parse_archive
{
	my ($self, $zip, $baseurl) = @_;
	my $dom = XML::LibXML::Document->new;
	
	$dom->setDocumentElement(
		$dom->createElement('ROOT'),
		);
	$dom->documentElement->setNamespace(XHTML_NS, 'xhtml');
	$dom->documentElement->setNamespace(DOM_NS, 'od', 1);
	$dom->documentElement->setNodeName('od:Document');
	
	foreach my $file (qw{content.xml settings.xml styles.xml meta.xml META-INF/manifest.xml})
	{
		my $data = $zip->contents($file);
		if (defined $data)
		{
			$self->_handle_content($dom, $baseurl, $file, $data);
		}
	}
	
	my @rdf = $zip->membersMatching('^/?meta/.+\.rdf');
	unshift @rdf, 'manifest.rdf';
	foreach my $file (@rdf)
	{
		my $data = $zip->contents($file);
		if (defined $data)
		{
			$self->_handle_content($dom, $baseurl, $file, $data, 'Meta');
		}
	}
	
	return $dom;
}

sub _handle_content
{
	my ($self, $dom, $baseurl, $filename, $content, $class) = @_;
	$class ||= 'Data';
	
	my $content_dom;
	eval { $content_dom = XML::LibXML->new->parse_string($content); };
	return unless $content_dom;

	my $content_base = sprintf('jar:%s!/%s', $baseurl, $filename);
	my $wrapper = $dom->documentElement->addNewChild(DOM_NS, $class);
	$wrapper->setAttributeNS(XHTML_NS, 'about', $content_base);
	$wrapper->setAttributeNS(XML_XML_NS, 'base', $content_base);
	$wrapper->setAttributeNS(DOM_NS, 'graph', $content_base);
	$wrapper->setAttributeNS(DOM_NS, 'file', $filename);
	
	$wrapper->appendChild( $content_dom->documentElement );
	return $wrapper;
}

sub parse_string
{
	my ($self, $content, $baseurl) = @_;
	my ($tmp,$file) = File::Temp::tempfile;
	binmode $tmp;
	print $tmp $content;
	close $tmp;
	my $zip = Archive::Zip->new($file);
	my $dom = $self->parse_archive($zip, $baseurl);
	unlink $file;
	return $dom;
}

sub parse_fh
{
	my ($self, $handle, $baseurl) = @_;
	my $zip = Archive::Zip->new;
	$zip->readFromFileHandle($handle);
	return $self->parse_archive($zip, $baseurl);
}

sub parse_file
{
	my ($self, $file, $baseurl) = @_;

	unless (blessed($file) && $file->isa('URI'))
	{
		if ($file =~ /^[a-z0-9_\.-]+:\S+$/i)
		{
			$file = URI->new($file);
		}
		else
		{
			$baseurl ||= URI::file->new_abs($file);
			my $zip = Archive::Zip->new($file);
			return $self->parse_archive($zip, $baseurl);
		}
	}
	$baseurl ||= $file;
	
	my $ua = LWP::UserAgent->new;
	$ua->agent(__PACKAGE__.$VERSION." ");
	$ua->default_header('Accept' => (join ', ', @Types));
	$ua->parse_head(0);
	
	my $response = $ua->get($file);
	die "HTTP response code was not 200 OK."
		unless $response->code == 200;
	
	my $content = $response->decoded_content;
	return $self->parse_string($content, $baseurl);
}

__PACKAGE__
__END__

=head1 NAME

RDF::RDFa::Parser::OpenDocumentObjectModel - DOM representation of an OpenDocument Format 1.2 file

=head1 DESCRIPTION

You should hopefully not need to use this module to be able to use RDF::RDFa::Parser. It's
used internally by the parser to deal with OpenDocument Format input.

This class provides a C<new> constructor and C<parse_file>, C<parse_fh> and C<parse_string>
methods offering rought compatibility with the parsing interface described in L<XML::LibXML::Parser>.

It represents an OpenDocument Format 1.2 file (internally a ZIP file containing various XML,
RDF/XML and other files) into a single L<XML::LibXML::Document> with a root element
C<od:Document>. The root element has several child elements with tag names C<od:Data>
and C<od:Meta> which each contain a single child corresponding to the root element of
(respectively) an XML or RDF/XML file found inside the ZIP. (C<od:Data> and C<od:Meta> elements
each have a C<file> attribute indicating which file.) This representation is necessarily
different to the "Flat XML" format offered by OpenOffice - trust me.

The "od" namespace URI is L<http://purl.org/NET/cpan-uri/dist/RDF-RDFa-Parser/opendocument-dom-wrapper>.

=head1 SEE ALSO

L<RDF::RDFa::Parser>.

L<XML::LibXML::Parser>,
L<HTML::HTML5::Parser>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

Copyright 2008-2012 Toby Inkster

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
