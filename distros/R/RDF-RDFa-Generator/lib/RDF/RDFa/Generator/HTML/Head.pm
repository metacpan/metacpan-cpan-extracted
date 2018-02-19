package RDF::RDFa::Generator::HTML::Head;

use 5.008;
use base qw'RDF::RDFa::Generator';
use strict;
use Encode qw'encode_utf8';
use URI::NamespaceMap 1.05;
use RDF::NS::Curated 0.006;
use XML::LibXML qw':all';
use Carp;
use Scalar::Util qw(blessed);

use warnings;
use Data::Dumper;

our $VERSION = '0.200';

sub new
{
   my ($class, %opts) = @_;

	unless (blessed($opts{namespacemap}) && $opts{namespacemap}->isa('URI::NamespaceMap')) {
	  if (defined $opts{namespaces}) {
		 $opts{namespacemap} = URI::NamespaceMap->new($opts{namespaces});
	  } else {
		 my $curated = RDF::NS::Curated->new;
		 $opts{namespacemap} = URI::NamespaceMap->new($curated->all);
	  }
	  
	  # handle deprecated {ns}.
	  if (defined($opts{ns})) {
		 carp "ns option is deprecated by the RDFa serializer";
	  }
	  while (my ($u,$p) = each %{ $opts{ns} }) {
		 $opts{namespacemap}->add_mapping($p => $u);
	  }

	  delete $opts{ns};
	  delete $opts{namespaces}
	}
	$opts{namespacemap}->guess_and_add('rdfa', 'rdf', 'rdfs', 'xsd');
	bless \%opts, $class;
}

sub injection_site
{
	return '//xhtml:head';
}

sub inject_document
{
	my ($proto, $html, $model, %opts) = @_;
	my $dom   = $proto->_get_dom($html);
	my @nodes = $proto->nodes($model, %opts);
	
	my $xc = XML::LibXML::XPathContext->new($dom);
	$xc->registerNs('xhtml', 'http://www.w3.org/1999/xhtml');
	my @sites = $xc->findnodes($proto->injection_site);
	
	die "No suitable place to inject this document." unless @sites;
	
	$sites[0]->appendChild($_) foreach @nodes;
	return $dom;
}

sub create_document
{
	my ($proto, $model, %opts) = @_;
	my $self = (ref $proto) ? $proto : $proto->new;
	
	my $html = sprintf(<<HTML, ($self->{'version'}||'1.0'), ($self->{'title'} || 'RDFa Document'), ref $self);
<html xmlns="http://www.w3.org/1999/xhtml" version="XHTML+RDFa %1\$s">
<head profile="http://www.w3.org/1999/xhtml/vocab">
<title>%2\$s</title>
<meta name="generator" value="%3\$s" />
</head>
<body />
</html>
HTML

	return $proto->inject_document($html, $model, %opts);
}

sub _get_dom
{
	my ($proto, $html) = @_;
	
	return $html if UNIVERSAL::isa($html, 'XML::LibXML::Document');
	
	my $p = XML::LibXML->new;
	return $p->parse_string($html);
}

sub nodes
{
	my ($proto, $model) = @_;
	my $self = (ref $proto) ? $proto : $proto->new;
	
	my $stream = $self->_get_stream($model);
	my @nodes;
	
	while (my $st = $stream->next)
	{
		my $node = $st->object->is_literal ?
			XML::LibXML::Element->new('meta') :
			XML::LibXML::Element->new('link');
		$node->setNamespace('http://www.w3.org/1999/xhtml', undef, 1);
		
		$self->_process_subject($st, $node)
		     ->_process_predicate($st, $node)
		     ->_process_object($st, $node);
		
		if (defined($self->{'version'}) && $self->{'version'} == 1.1
		and $self->{'prefix_attr'})
		{
		  if (defined($self->{namespacemap}->rdfa)) {
			 $node->setAttribute('prefix', $self->{namespacemap}->rdfa->as_string)
		  }
		} else {
		  while (my ($prefix, $nsURI) = $self->{namespacemap}->each_map) {
			 $node->setNamespace($nsURI->as_string, $prefix, 0);
		  }
		}
		
		push @nodes, $node;
	}
	
	return @nodes if wantarray;
	
	my $nodelist = XML::LibXML::NodeList->new;
	$nodelist->push(@nodes);
	return $nodelist;
}

sub _get_stream
{
	my ($self, $model) = @_;
	
	my $data_context = undef;
	if (defined($self->{'data_context'})) {
	  if (! blessed($self->{'data_context'})) {
		 croak "data_context can't be a string anymore, must be a Attean blank or IRI or an RDF::Trine::Node";
	  } elsif ($self->{'data_context'}->does('Attean::API::BlankOrIRI')
				  || $self->{'data_context'}->isa('RDF::Trine::Node')) {
		 croak "data_context must be a Attean blank or IRI or an RDF::Trine::Node, not " . ref($self->{'data_context'});
	  }
	}
	
	return $model->get_quads(undef, undef, undef, $data_context);
}

sub _process_subject
{
	my ($self, $st, $node) = @_;
	
	if (defined $self->{'base'} 
	and $st->subject->is_resource
	and $st->subject->abs eq $self->{'base'})
	{
		return $self;
	}
	
	if ($st->subject->is_resource) 
		{ $node->setAttribute('about', $st->subject->abs); }
	else
		{ $node->setAttribute('about', '[_:'.$st->subject->value.']'); }
	
	return $self;
}

sub _process_predicate
{
	my ($self, $st, $node) = @_;

	my $attr = $st->object->is_literal ? 'property' : 'rel';

	if ($attr eq 'rel'
	and $st->predicate->abs =~ m'^http://www\.w3\.org/1999/xhtml/vocab\#
										(alternate|appendix|bookmark|cite|
										chapter|contents|copyright|first|glossary|help|icon|
										index|last|license|meta|next|p3pv1|prev|role|section|
										stylesheet|subsection|start|top|up)$'x)
	{
		$node->setAttribute($attr, $1);
		return $self;
	}
	elsif ($attr eq 'rel'
	and $st->predicate->abs =~ m'^http://www\.w3\.org/1999/xhtml/vocab#(.*)$')
	{
		$node->setAttribute($attr, ':'.$1);
		return $self;
	}
	elsif (defined($self->{'version'}) && $self->{'version'} == 1.1)
	{
		$node->setAttribute($attr, $st->predicate->abs);
		return $self;
	}
	
	$node->setAttribute($attr, $self->_make_curie($st->predicate));
	
	return $self;
}

sub _process_object
{
	my ($self, $st, $node) = @_;
	
	if (defined $self->{'base'} 
	and $st->subject->is_resource
	and $st->subject->abs eq $self->{'base'}
	and $st->object->is_resource)
	{
		$node->setAttribute('href', $st->object->abs);
		return $self;
	}
	elsif (defined $self->{'base'} 
	and $st->object->is_resource
	and $st->object->abs eq $self->{'base'})
	{
		$node->setAttribute('resource', '');
		return $self;
	}
	elsif ($st->object->is_resource)
	{
		$node->setAttribute('resource', $st->object->abs);
		return $self;
	}
	elsif ($st->object->is_blank)
	{
		$node->setAttribute('resource', '[_:'.$st->object->value.']');
		return $self;
	}
	
	$node->setAttribute('content',  encode_utf8($st->object->value));
	
	if (defined $st->object->datatype)
	{
		$node->setAttribute('datatype', $self->_make_curie($st->object->datatype));
	}
	else
	{
		$node->setAttribute('xml:lang', ''.$st->object->language);
	}
	
	return $self;
}

sub _make_curie {
  my ($self, $uri) = @_;
  my $curie = $self->{namespacemap}->abbreviate($uri);
  unless (defined($curie)) {
	 $uri->value =~ m!(.*)(\#|/)(.*?)$!;
	 my $trim = $1.$2;
	 $self->{namespacemap}->guess_and_add($trim);
	 $curie = $self->{namespacemap}->abbreviate($uri);
  }
  unless (defined($curie)) {
	 $curie = $uri->value;
  }
  return $curie;
}

1;
