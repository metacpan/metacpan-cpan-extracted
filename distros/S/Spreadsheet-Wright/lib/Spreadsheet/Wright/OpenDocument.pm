package Spreadsheet::Wright::OpenDocument;

use 5.010;
use strict;
use warnings;
no warnings qw( uninitialized numeric );

BEGIN {
	$Spreadsheet::Wright::OpenDocument::VERSION   = '0.105';
	$Spreadsheet::Wright::OpenDocument::AUTHORITY = 'cpan:TOBYINK';
}

use Archive::Zip qw':CONSTANTS';
use Carp;
use DateTime;

use parent qw(Spreadsheet::Wright::OpenDocumentXML);

our $MANIFEST_XML = <<MANIFEST;
<?xml version="1.0" encoding="UTF-8"?>
<manifest:manifest xmlns:manifest="urn:oasis:names:tc:opendocument:xmlns:manifest:1.0">
	<manifest:file-entry manifest:media-type="application/vnd.oasis.opendocument.spreadsheet" manifest:full-path="/"/>
	<manifest:file-entry manifest:media-type="text/xml" manifest:full-path="content.xml"/>
	<manifest:file-entry manifest:media-type="text/xml" manifest:full-path="meta.xml"/>
	<manifest:file-entry manifest:media-type="text/xml" manifest:full-path="settings.xml"/>
	<manifest:file-entry manifest:media-type="text/xml" manifest:full-path="styles.xml"/>
</manifest:manifest>
MANIFEST

our $SETTINGS_XML = <<SETTINGS;
<?xml version="1.0" ?>
<office:document-settings office:version="1.0"
	xmlns:office="urn:oasis:names:tc:opendocument:xmlns:office:1.0" />
SETTINGS

our $STYLES_XML = <<STYLES;
<office:document-styles office:version="1.0"
	xmlns:fo="urn:oasis:names:tc:opendocument:xmlns:xsl-fo-compatible:1.0"
	xmlns:office="urn:oasis:names:tc:opendocument:xmlns:office:1.0"
	xmlns:style="urn:oasis:names:tc:opendocument:xmlns:style:1.0">
	<!-- These don't work. Hopefully in a future version. -->
	<office:styles>
		<style:style style:family="paragraph" style:name="Bold" style:display-name="Bold" style:class="text">
			<style:text-properties fo:font-weight="bold" />
		</style:style>
		<style:style style:family="paragraph" style:name="Italic" style:display-name="Italic" style:class="text">
			<style:text-properties fo:font-style="italic" />
		</style:style>
		<style:style style:family="paragraph" style:name="BoldItalic" style:display-name="Bold Italic" style:class="text">
			<style:text-properties fo:font-weight="bold" fo:font-style="italic" />
		</style:style>
	</office:styles>
</office:document-styles>
STYLES

sub close
{
	my $self=shift;
	return if $self->{'_CLOSED'};

	my $CONTENT_XML = $self->_make_output;
	my $META_XML    = $self->_make_meta;
	my $zip = Archive::Zip->new;
	$zip->addString($MANIFEST_XML, 'META-INF/manifest.xml');
	$zip->addString($STYLES_XML,   'styles.xml');
	$zip->addString($META_XML,     'meta.xml');
	$zip->addString($SETTINGS_XML, 'settings.xml');
	$zip->addString($CONTENT_XML,  'content.xml')->desiredCompressionLevel(9);
	$zip->addString('application/vnd.oasis.opendocument.spreadsheet', 'mimetype');
	$zip->writeToFileHandle( $self->{'_FH'} );
	$self->{'_FH'}->close;
	
	$self->{'_CLOSED'}=1;
	return $self;
}

sub _make_meta
{
	my $self = shift;
	
	my $title = $self->{'options'}->{'title'};
	$title =~ s/[^A-Za-z0-9 -]/sprintf('&#%d;', ord($1))/eg;
	
	my $date = DateTime->now;
	
	return sprintf(<<'META', $title, $date, $date, __PACKAGE__, $self->VERSION);
<?xml version="1.0" ?>
<office:document-meta office:version="1.0"
	xmlns:dc="http://purl.org/dc/elements/1.1/"
	xmlns:meta="urn:oasis:names:tc:opendocument:xmlns:meta:1.0"
	xmlns:office="urn:oasis:names:tc:opendocument:xmlns:office:1.0">
	<office:meta>
		<dc:title>%s</dc:title>
		<dc:date>%s</dc:date>
		<meta:creation-date>%s</meta:creation-date>
		<meta:generator>%s/%s</meta:generator>
	</office:meta>
</office:document-meta>
META
}

1;