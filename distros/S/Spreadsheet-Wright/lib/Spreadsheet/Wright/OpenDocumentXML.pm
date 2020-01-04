package Spreadsheet::Wright::OpenDocumentXML;

use 5.010;
use strict;
use warnings;
no warnings qw( uninitialized numeric );

BEGIN {
	$Spreadsheet::Wright::OpenDocumentXML::VERSION   = '0.107';
	$Spreadsheet::Wright::OpenDocumentXML::AUTHORITY = 'cpan:TOBYINK';
}

use Carp;
use XML::LibXML;

use parent qw(Spreadsheet::Wright);
use constant {
	OFFICE_NS => "urn:oasis:names:tc:opendocument:xmlns:office:1.0",
	STYLE_NS  => "urn:oasis:names:tc:opendocument:xmlns:style:1.0",
	TEXT_NS   => "urn:oasis:names:tc:opendocument:xmlns:text:1.0",
	TABLE_NS  => "urn:oasis:names:tc:opendocument:xmlns:table:1.0",
	META_NS   => "urn:oasis:names:tc:opendocument:xmlns:meta:1.0",
	NUMBER_NS => "urn:oasis:names:tc:opendocument:xmlns:datastyle:1.0",
	};

sub new
{
	my ($class, %args) = @_;
	
	my $self = bless { 'options' => \%args }, $class;
	
	$self->{'_FILENAME'} = $args{'file'} // $args{'filename'}
		or croak "Need filename.";

	return $self;
}

sub _prepare
{
	my $self = shift;
	
	return $self if $self->{'document'};
	
	my $namespaces = {
		office  => OFFICE_NS,
		style   => STYLE_NS,
		text    => TEXT_NS,
		table   => TABLE_NS,
		meta    => META_NS,
		number  => NUMBER_NS,
		};
	
	$self->{'document'} = XML::LibXML->createDocument;
	$self->{'document'}->setDocumentElement(
		$self->{'document'}->createElement('root')
		);
	while (my ($prefix, $nsuri) = each %$namespaces)
	{
		$self->{'document'}->documentElement->setNamespace($nsuri, $prefix, $prefix eq 'office' ? 1 : 0);
	}
	$self->{'document'}->documentElement->setNodeName('office:document-content');
	$self->{'document'}->documentElement->setAttributeNS(OFFICE_NS, 'version', '1.0');
	$self->{'body'} = $self->{'document'}->documentElement
		->addNewChild(OFFICE_NS, 'body')
		->addNewChild(OFFICE_NS, 'spreadsheet');
	$self->addsheet($self->{'options'}->{'sheet'} // 'Sheet 1');
	
	return $self;
}

sub addsheet
{
	my ($self, $caption) = @_;

	$self->_open() or return;

	$self->{'tbody'} = $self->{'body'}->addNewChild(TABLE_NS, 'table');

	if (defined $caption)
	{
		$self->{'tbody'}->setAttributeNS(TABLE_NS, 'name', $caption);
	}
	
	return $self;
}

sub _add_prepared_row
{
	my $self = shift;

	my $tr = $self->{'tbody'}->addNewChild(TABLE_NS, 'table-row');
	
	foreach my $cell (@_)
	{
		my $tcell = $tr->addNewChild(TABLE_NS, 'table-cell');
		$tcell->setAttributeNS(OFFICE_NS, 'value-type', 'string');
		
		my $td = $tcell->addNewChild(TEXT_NS, 'p');
		
		my $content = $cell->{'content'};
		$content = sprintf($cell->{'sprintf'}, $content)
			if defined $cell->{'sprintf'};
		
		$td->appendText($content);
		
		if ($cell->{'font_weight'} eq 'bold'
		&&  $cell->{'font_style'} eq 'italic')
		{
			$td->setAttributeNS(TEXT_NS, 'style-name', 'BoldItalic');
		}
		elsif ($cell->{'font_weight'} eq 'bold')
		{
			$td->setAttributeNS(TEXT_NS, 'style-name', 'Bold');
		}
		elsif ($cell->{'font_style'} eq 'italic')
		{
			$td->setAttributeNS(TEXT_NS, 'style-name', 'Italic');
		}
	}
}

sub close
{
	my $self=shift;
	return if $self->{'_CLOSED'};
	$self->{'_FH'}->print( $self->_make_output );
	$self->{'_FH'}->close;
	$self->{'_CLOSED'}=1;
	return $self;
}

sub _make_output
{
	my $self = shift;
	return $self->{'document'}->toString;
}

1;
