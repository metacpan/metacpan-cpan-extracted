package RDF::RDFa::Linter::Error;

use 5.008;
use base qw(RDF::RDFa::Generator::HTML::Pretty::Note);
use strict;
use constant XHTML_NS => 'http://www.w3.org/1999/xhtml';
use XML::LibXML qw(:all);

our $VERSION = '0.053';

sub new
{
	my ($class, %self) = @_;
	return bless \%self, $class;
}

sub node
{
	my ($self, $namespace, $element) = @_;
	die "unknown namespace" unless $namespace eq XHTML_NS;
	
	my $node = XML::LibXML::Element->new($element);
	$node->setNamespace($namespace, undef, 1);

	my @categories = qw(Notice Notice Warning Warning Error Error);
	my $b = $node->addNewChild($namespace, 'b');
	$b->appendTextNode($categories[$self->{'level'}].': ');
	
	$node->appendTextNode($self->{'text'});
	
	if ($self->{'link'})
	{
		$node->appendTextNode(' [');
		my $a = $node->addNewChild($namespace, 'a');
		$a->setAttribute( href => $self->{'link'} );
		$a->appendTextNode('more info');
		$node->appendTextNode(']');
	}

	return $node;
}

1;
