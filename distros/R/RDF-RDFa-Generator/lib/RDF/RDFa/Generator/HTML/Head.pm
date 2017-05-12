package RDF::RDFa::Generator::HTML::Head;

use 5.008;
use base qw'RDF::RDFa::Generator';
use strict;
use Encode qw'encode_utf8';
use RDF::Prefixes;
use XML::LibXML qw':all';

our $VERSION = '0.103';

sub new
{
	my ($class, %opts) = @_;
	
	if (!defined $opts{namespaces})
	{
		$opts{namespaces} = {};
		while (<DATA>)
		{
			chomp;
			my ($p, $u)  = split /\s+/;
			$opts{namespaces}->{$p} ||= $u;
		}
	}
	
	# handle deprecated {ns}.
	while (my ($u,$p) = each %{ $opts{ns} })
	{
		$opts{namespaces}->{$p} ||= $u;
	}
	
	delete $opts{ns};
	
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
		
		my $prefixes = RDF::Prefixes->new($self->{namespaces});
		$self->_process_subject($st, $node, $prefixes)
		     ->_process_predicate($st, $node, $prefixes)
		     ->_process_object($st, $node, $prefixes);
		
		use Data::Dumper; Dumper($prefixes);
		
		if ($self->{'version'} == 1.1
		and $self->{'prefix_attr'})
		{
			$node->setAttribute('prefix', $prefixes->rdfa)
				if %$prefixes;
		}
		else
		{
			while (my ($u,$p) = each(%$prefixes))
			{
				$node->setNamespace($p, $u, 0);
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
	if (defined $self->{'data_context'})
	{
		$data_context = ( $self->{'data_context'} =~ /^_:(.*)$/ ) ?
			RDF::Trine::Node::Blank->new($1) :
			RDF::Trine::Node::Resource->new($self->{'data_context'});
	}
	
	return $model->get_statements(undef, undef, undef, $data_context);
}

sub _process_subject
{
	my ($self, $st, $node, $prefixes) = @_;
	
	if (defined $self->{'base'} 
	and $st->subject->is_resource
	and $st->subject->uri eq $self->{'base'})
	{
		return $self;
	}
	
	if ($st->subject->is_resource) 
		{ $node->setAttribute('about', $st->subject->uri); }
	else
		{ $node->setAttribute('about', '[_:'.$st->subject->blank_identifier.']'); }
	
	return $self;
}

sub _process_predicate
{
	my ($self, $st, $node, $prefixes) = @_;

	my $attr = $st->object->is_literal ? 'property' : 'rel';

	if ($attr eq 'rel'
	and $st->predicate->uri =~ m'^http://www\.w3\.org/1999/xhtml/vocab\#
										(alternate|appendix|bookmark|cite|
										chapter|contents|copyright|first|glossary|help|icon|
										index|last|license|meta|next|p3pv1|prev|role|section|
										stylesheet|subsection|start|top|up)$'x)
	{
		$node->setAttribute($attr, $1);
		return $self;
	}
	elsif ($attr eq 'rel'
	and $st->predicate->uri =~ m'^http://www\.w3\.org/1999/xhtml/vocab#(.*)$')
	{
		$node->setAttribute($attr, ':'.$1);
		return $self;
	}
	elsif ($self->{'version'} == 1.1)
	{
		$node->setAttribute($attr, $st->predicate->uri);
		return $self;
	}
	
	$node->setAttribute($attr, 
		$self->_make_curie($st->predicate->uri, $prefixes));
	
	return $self;
}

sub _process_object
{
	my ($self, $st, $node, $prefixes) = @_;
	
	if (defined $self->{'base'} 
	and $st->subject->is_resource
	and $st->subject->uri eq $self->{'base'}
	and $st->object->is_resource)
	{
		$node->setAttribute('href', $st->object->uri);
		return $self;
	}
	elsif (defined $self->{'base'} 
	and $st->object->is_resource
	and $st->object->uri eq $self->{'base'})
	{
		$node->setAttribute('resource', '');
		return $self;
	}
	elsif ($st->object->is_resource)
	{
		$node->setAttribute('resource', $st->object->uri);
		return $self;
	}
	elsif ($st->object->is_blank)
	{
		$node->setAttribute('resource', '[_:'.$st->object->blank_identifier.']');
		return $self;
	}
	
	$node->setAttribute('content',  encode_utf8($st->object->literal_value));
	
	if (defined $st->object->literal_datatype)
	{
		$node->setAttribute('datatype', 
			$self->_make_curie($st->object->literal_datatype, $prefixes));
	}
	else
	{
		$node->setAttribute('xml:lang', ''.$st->object->literal_value_language);
	}
	
	return $self;
}

sub _make_curie
{
	my ($self, $uri, $prefixes) = @_;	
	use Data::Dumper; Dumper($prefixes); # this shouldn't do anything, but it fixes a bug!!
	return $prefixes->get_qname($uri);
}

1;

__DATA__
bibo    http://purl.org/ontology/bibo/
cc      http://creativecommons.org/ns#
ctag    http://commontag.org/ns#
dbp     http://dbpedia.org/property/
dc      http://purl.org/dc/terms/
doap    http://usefulinc.com/ns/doap#
fb      http://developers.facebook.com/schema/
foaf    http://xmlns.com/foaf/0.1/
geo     http://www.w3.org/2003/01/geo/wgs84_pos#
gr      http://purl.org/goodrelations/v1#
ical    http://www.w3.org/2002/12/cal/ical#
og      http://opengraphprotocol.org/schema/
owl     http://www.w3.org/2002/07/owl#
rdf     http://www.w3.org/1999/02/22-rdf-syntax-ns#
rdfa    http://www.w3.org/ns/rdfa#
rdfs    http://www.w3.org/2000/01/rdf-schema#
rel     http://purl.org/vocab/relationship/
rev     http://purl.org/stuff/rev#
rss     http://purl.org/rss/1.0/
sioc    http://rdfs.org/sioc/ns#
skos    http://www.w3.org/2004/02/skos/core#
tag     http://www.holygoat.co.uk/owl/redwood/0.1/tags/
v       http://rdf.data-vocabulary.org/#
vann    http://purl.org/vocab/vann/
vcard   http://www.w3.org/2006/vcard/ns#
void    http://rdfs.org/ns/void#
xfn     http://vocab.sindice.com/xfn#
xhv     http://www.w3.org/1999/xhtml/vocab#
xsd     http://www.w3.org/2001/XMLSchema#
