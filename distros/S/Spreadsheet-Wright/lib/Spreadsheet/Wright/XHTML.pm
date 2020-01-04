package Spreadsheet::Wright::XHTML;

use 5.010;
use strict;
use warnings;
no warnings qw( uninitialized numeric );

BEGIN {
	$Spreadsheet::Wright::XHTML::VERSION   = '0.107';
	$Spreadsheet::Wright::XHTML::AUTHORITY = 'cpan:TOBYINK';
}

use Carp;
use XML::LibXML;

use parent qw(Spreadsheet::Wright);
use constant XHTML_NS => 'http://www.w3.org/1999/xhtml';

sub new
{
	my ($class, %args) = @_;
	
	$args{'title'} //= 'Data';
	
	my $self = bless { 'options' => \%args }, $class;
	
	$self->{'_FILENAME'} = $args{'file'} // $args{'filename'}
		or croak "Need filename.";

	return $self;
}

sub _prepare
{
	my $self = shift;
	
	return $self if $self->{'document'};
	
	$self->{'document'} = XML::LibXML->createDocument;
	$self->{'document'}->setDocumentElement(
		$self->{'document'}->createElementNS(XHTML_NS,'html')
		);
	$self->{'document'}->documentElement
		->addNewChild(XHTML_NS, 'head')
		->addNewChild(XHTML_NS, 'title')
		->appendText($self->{'options'}->{'title'});
	$self->{'body'} = $self->{'document'}->documentElement
		->addNewChild(XHTML_NS, 'body');
	$self->{'body'}->addNewChild(XHTML_NS, 'h1')
		->appendText($self->{'options'}->{'title'});
	$self->addsheet($self->{'options'}->{'sheet'});
	
	return $self;
}

sub addsheet
{
	my ($self, $caption) = @_;

	$self->{'worksheet'} = $self->{'body'}->addNewChild(XHTML_NS, 'table');

	if (defined $caption)
	{
		$self->{'worksheet'}->addNewChild(XHTML_NS, 'caption')->appendText($caption);
	}

	$self->{'tbody'}     = $self->{'worksheet'}->addNewChild(XHTML_NS, 'tbody');

	return $self;
}

sub _add_prepared_row
{
	my $self = shift;

	my $tr   = $self->{'tbody'}->addNewChild(XHTML_NS, 'tr');
	
	foreach my $cell (@_)
	{
		my $td;
		if ($cell->{'header'})
		{
			$td = $tr->addNewChild(XHTML_NS, 'th');
		}
		else
		{
			$td = $tr->addNewChild(XHTML_NS, 'td');
		}
		
		my $content = $cell->{'content'};
		$content = sprintf($cell->{'sprintf'}, $content)
			if defined $cell->{'sprintf'};
		
		$td->appendText($content);
		
		if (defined $cell->{'style'} && defined $self->{'options'}->{'styles'}->{ $cell->{'style'} })
		{
			while (my ($k, $v) = each %{ $self->{'options'}->{'styles'}->{ $cell->{'style'} } })
			{
				$cell->{$k} = $v
					unless defined $cell->{$k};
			}
		}
		
		my %styles;
		if ($cell->{'font_weight'} eq 'bold')
		{
			$styles{'font-weight'} = 'bold';
		}
		if ($cell->{'font_style'} eq 'italic')
		{
			$styles{'font-style'} = 'italics';
		}
		if ($cell->{'font_decoration'} =~ m'underline')
		{
			$styles{'text-decoration'} = 'underline';
		}
		if ($cell->{'font_decoration'} =~ m'strikeout')
		{
			$styles{'text-decoration'} = 'line-through';
		}
		if (defined $cell->{'font_color'})
		{
			$styles{'color'} = $cell->{'font_color'};
		}
		if (defined $cell->{'font_face'})
		{
			$styles{'font-family'}=sprintf('"%s"', $cell->{'font_face'});
		}
		if (defined $cell->{'font_size'})
		{
			$styles{'font-size'}=$cell->{'font_size'}.'pt';
		}
		if (defined $cell->{'align'})
		{
			$styles{'text-align'}=$cell->{'align'};
		}
		if (defined $cell->{'valign'})
		{
			$styles{'valign'}=$cell->{'valign'};
		}

		my $style;
		while (my ($k, $v) = each %styles)
		{
			$style .= sprintf('%s: %s; ', $k, $v);
		}
		$style =~ s/; $//;
		
		$td->setAttribute('style', $style) if length $style;
	}
	
	return $self;
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