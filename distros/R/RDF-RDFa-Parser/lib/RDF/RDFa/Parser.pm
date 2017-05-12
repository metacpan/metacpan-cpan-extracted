package RDF::RDFa::Parser;

BEGIN {
	$RDF::RDFa::Parser::AUTHORITY = 'cpan:TOBYINK';
	$RDF::RDFa::Parser::VERSION   = '1.097';	
}

use Carp qw();
use Data::UUID;
use File::ShareDir qw(dist_file);
use HTML::HTML5::Parser;
use HTML::HTML5::Sanity qw(fix_document);
use LWP::UserAgent;
use RDF::RDFa::Parser::Config;
use RDF::RDFa::Parser::InitialContext;
use RDF::RDFa::Parser::OpenDocumentObjectModel;
use RDF::Trine 0.130;
use Scalar::Util qw(blessed);
use Storable qw(dclone);
use URI::Escape;
use URI;
use XML::LibXML qw(:all);
use XML::RegExp;

use constant {
	ERR_WARNING  => 'w',
	ERR_ERROR    => 'e',
	};
use constant {
	ERR_CODE_HOST                  =>  'HOST01',
	ERR_CODE_RDFXML_MUDDLE         =>  'RDFX01',
	ERR_CODE_RDFXML_MESS           =>  'RDFX02',
	ERR_CODE_PREFIX_BUILTIN        =>  'PRFX01',
	ERR_CODE_PREFIX_ILLEGAL        =>  'PRFX02',
	ERR_CODE_PREFIX_DISABLED       =>  'PRFX03',
	ERR_CODE_INSTANCEOF_USED       =>  'INST01',
	ERR_CODE_INSTANCEOF_OVERRULED  =>  'INST02',
	ERR_CODE_CURIE_FELLTHROUGH     =>  'CURI01',
	ERR_CODE_CURIE_UNDEFINED       =>  'CURI02',
	ERR_CODE_BNODE_WRONGPLACE      =>  'BNOD01',
	ERR_CODE_VOCAB_DISABLED        =>  'VOCA01',
	ERR_CODE_LANG_INVALID          =>  'LANG01',
	};
use constant {
	RDF_XMLLIT   => 'http://www.w3.org/1999/02/22-rdf-syntax-ns#XMLLiteral',
	RDF_TYPE     => 'http://www.w3.org/1999/02/22-rdf-syntax-ns#type',
	RDF_FIRST    => 'http://www.w3.org/1999/02/22-rdf-syntax-ns#first',
	RDF_REST     => 'http://www.w3.org/1999/02/22-rdf-syntax-ns#rest',
	RDF_NIL      => 'http://www.w3.org/1999/02/22-rdf-syntax-ns#nil',
	};
use common::sense;
use 5.010;

our $HAS_AWOL;

BEGIN
{
	local $@;
	eval "use XML::Atom::OWL;";
	$HAS_AWOL = $@ ? 0 : 1;
}

sub new
{
	my ($class, $markup, $base_uri, $config, $store)= @_;
	
	# Rationalise $config
	# ===================
	# If $config is undefined, then use the default configuration
	if (!defined $config)
		{ $config = RDF::RDFa::Parser::Config->new; }
	# If $config is something sensible, then use it.
	elsif (blessed($config) && $config->isa('RDF::RDFa::Parser::Config'))
		{ 1; }
	# If it's a hashref (for backcompat), then use default plus those options
	elsif ('HASH' eq ref $config)
		{ $config = RDF::RDFa::Parser::Config->new(undef, undef, %$config); }
	# If it's something odd, then bail.
	else
		{ die "Unrecognised configuration\n"; }

	# Rationalise $base_uri
	# =====================
	unless ($base_uri =~ /^[a-z][a-z0-9\+\-\.]*:/i)
		{ die "Need a valid base URI.\n"; }

	# Rationalise $markup and set $dom
	# ================================
	Carp::croak("Need to provide markup to parse.") unless defined $markup;
	
	my $dom;
	eval {
		if (blessed($markup) && $markup->isa('XML::LibXML::Document'))
		{
			$dom    = $markup;
			$markup = $dom->toString;
		}
		elsif ($config->{'dom_parser'} =~ /^(opendocument|opendoc|odf|od|odt)$/i)
		{
			my $parser = RDF::RDFa::Parser::OpenDocumentObjectModel->new;
			$dom = $parser->parse_string($markup, $base_uri);
		}
		elsif ($config->{'dom_parser'} =~ /^(html|tagsoup|soup)$/i)
		{
			my $parser = HTML::HTML5::Parser->new;
			$dom = fix_document( $parser->parse_string($markup) );
		}
		else
		{
			my $parser  = XML::LibXML->new;
			
			my $catalogue = dist_file('RDF-RDFa-Parser', 'catalogue/index.xml');
			$parser->load_catalog($catalogue)
				if -r $catalogue;
			$parser->validation(0);
			#$parser->recover(1);
			
			$dom = $parser->parse_string($markup);
		}
	};
	
	# Rationalise $store
	# ==================
	$store = RDF::Trine::Store::Memory->temporary_store
		unless defined $store;

	my $self = bless {
		baseuri  => $base_uri,
		origbase => $base_uri,
		dom      => $dom,
		model    => RDF::Trine::Model->new($store),
		bnodes   => 0,
		sub      => {},
		options  => $config,
		Graphs   => {},
		errors   => [],
		consumed => 0,
		}, $class;
	
	$config->auto_config($self);
	
	$self->{options} = $config = $config->guess_rdfa_version($self)
		if $config->{guess_rdfa_version};

	# HTML <base> element.
	if ($dom and $self->{options}{xhtml_base})
	{
		my @bases = $self->dom->getElementsByTagName('base');
		my $base;
		foreach my $b (@bases)
		{
			if ($b->hasAttribute('href'))
			{
				$base = $b->getAttribute('href');
				$base =~ s/#.*$//g;
			}
		}
		$self->{baseuri} = $self->uri($base)
			if defined $base && length $base;
	}
	
	return $self;
}

sub new_from_url
{
	my ($class, $url, $config, $store)= @_;

	my $response = do
		{
			if (blessed($url) && $url->isa('HTTP::Message'))
			{
				$url;
			}
			else
			{
				my $ua;
				if (blessed($config) and $config->isa('RDF::RDFa::Parser::Config'))
					{ $ua = $config->lwp_ua; }
				elsif (ref $config eq 'HASH')
					{ $ua = RDF::RDFa::Parser::Config->new('xml', undef, %$config)->lwp_ua; }
				else
					{ $ua = RDF::RDFa::Parser::Config->new('xml', undef)->lwp_ua; }
				$ua->get($url);
			}
		};
	my $host = $response->content_type;

	if (blessed($config) and $config->isa('RDF::RDFa::Parser::Config'))
		{ $config = $config->rehost($host); }
	elsif (ref $config eq 'HASH')
		{ $config = RDF::RDFa::Parser::Config->new($host, undef, %$config); }
	else
		{ $config = RDF::RDFa::Parser::Config->new($host, undef); }

	return $class->new(
		$response->decoded_content,
		($response->base || $url).'',
		$config,
		$store,
		);
}

*new_from_uri = \&new_from_url;

*new_from_response = \&new_from_url;

sub graph
{
	my $self  = shift;
	my $graph = shift;
	
	$self->consume;
	
	if (defined($graph))
	{
		my $tg;
		if ($graph =~ m/^_:(.*)/)
		{
			$tg = RDF::Trine::Node::Blank->new($1);
		}
		else
		{
			$tg = RDF::Trine::Node::Resource->new($graph, $self->{baseuri});
		}
		my $m = RDF::Trine::Model->temporary_model;
		my $i = $self->{model}->get_statements(undef, undef, undef, $tg);
		while (my $statement = $i->next)
		{
			$m->add_statement($statement);
		}
		return $m;
	}
	else
	{
		return $self->{model};
	}
}

sub output_graph
{
	shift->graph;
}

sub graphs
{
	my $self = shift;
	$self->consume;
	
	my @graphs = keys(%{$self->{Graphs}});	
	my %result;
	foreach my $graph (@graphs)
	{
		$result{$graph} = $self->graph($graph);
	}
	return \%result;
}

sub opengraph
{
	my ($self, $property, %opts) = @_;
	$self->consume;
	
	$property = $1
		if defined $property && $property =~ m'^http://opengraphprotocol\.org/schema/(.*)$';
	$property = $1
		if defined $property && $property =~ m'^http://ogp\.me/ns#(.*)$';
		
	my $rtp;
	if (defined $property && $property =~ /^[a-z][a-z0-9\-\.\+]*:/i)
	{
		$rtp = [ RDF::Trine::Node::Resource->new($property) ];
	}
	elsif (defined $property)
	{
		$rtp = [ 
			RDF::Trine::Node::Resource->new('http://ogp.me/ns#'.$property),
			RDF::Trine::Node::Resource->new('http://opengraphprotocol.org/schema/'.$property),
			];
	}
	
	my $data = {};
	if ($rtp)
	{
		foreach my $rtp2 (@$rtp)
		{
			my $iter = $self->graph->get_statements(
				RDF::Trine::Node::Resource->new($self->uri), $rtp2, undef);
			while (my $st = $iter->next)
			{
				my $propkey = $st->predicate->uri;
				$propkey = $1
					if $propkey =~ m'^http://ogp\.me/ns#(.*)$'
					|| $propkey =~ m'^http://opengraphprotocol\.org/schema/(.*)$';
				
				if ($st->object->is_resource)
					{ push @{ $data->{$propkey} }, $st->object->uri; }	
				elsif ($st->object->is_literal)
					{ push @{ $data->{$propkey} }, $st->object->literal_value; }
			}
		}
	}
	else
	{
		my $iter = $self->graph->get_statements(
			RDF::Trine::Node::Resource->new($self->uri), undef, undef);
		while (my $st = $iter->next)
		{
			my $propkey = $st->predicate->uri;
			$propkey = $1
				if $propkey =~ m'^http://ogp\.me/ns#(.*)$'
				|| $propkey =~ m'^http://opengraphprotocol\.org/schema/(.*)$';
			
			if ($st->object->is_resource)
				{ push @{ $data->{$propkey} }, $st->object->uri; }	
			elsif ($st->object->is_literal)
				{ push @{ $data->{$propkey} }, $st->object->literal_value; }
		}
	}
	
	my @return;
	if (defined $property)
		{ @return = @{$data->{$property}} if defined $data->{$property}; }
	else
		{ @return = keys %$data; }
	
	return wantarray ? @return : $return[0];
}

sub dom
{
	my $self = shift;
	return $self->{dom};
}

sub uri
{
	my $self  = shift;
	my $param = shift || '';
	my $opts  = shift || {};
	
	if ((ref $opts) =~ /^XML::LibXML/)
	{
		my $x = {'element' => $opts};
		$opts = $x;
	}
	
	if ($param =~ /^([a-z][a-z0-9\+\.\-]*)\:/i)
	{
		# seems to be an absolute URI, so can safely return "as is".
		return $param;
	}
	elsif ($opts->{'require-absolute'})
	{
		return undef;
	}
	
	my $base = $self->{baseuri};
	if ($self->{'options'}->{'xml_base'})
	{
		$base = $opts->{'xml_base'} || $self->{baseuri};
	}
	
	my $rv = $self->{options}{uri_class}->new_abs($param, $base);
	return "$rv";
}

sub errors
{
	my $self = shift;
	return @{$self->{errors}};
}

sub processor_graph
{
	my ($self, $model, $context) = @_;
	$model ||= RDF::Trine::Model->new( RDF::Trine::Store->temporary_store );

	my $RDF   = RDF::Trine::Namespace->new('http://www.w3.org/1999/02/22-rdf-syntax-ns#');
	my $RDFA  = RDF::Trine::Namespace->new('http://www.w3.org/ns/rdfa#');
	my $CNT   = RDF::Trine::Namespace->new('http://www.w3.org/2011/content#');
	my $PTR   = RDF::Trine::Namespace->new('http://www.w3.org/2009/pointers#');
	my $DC    = RDF::Trine::Namespace->new('http://purl.org/dc/terms/');
	my $ERR   = RDF::Trine::Namespace->new('tag:buzzword.org.uk,2010:RDF-RDFa-Parser:error:');

	my $uuid  = Data::UUID->new;
	my $mkuri = sub
	{
		my $id = $uuid->create_str;
		return $ERR->$id;
	};

	my $st = sub
	{
		my @n = map
			{ blessed($_) ? $_ : RDF::Trine::Node::Literal->new($_); }
			@_;
		if ($context)
		{
			$model->add_statement(
				RDF::Trine::Statement::Quad->new(@n, $context)
				);
		}
		else
		{
			$model->add_statement(
				RDF::Trine::Statement->new(@n)
				);
		}
	};

	my $typemap = {(
		ERR_CODE_HOST                  , 'DocumentError',
		ERR_CODE_RDFXML_MUDDLE         , '',
		ERR_CODE_RDFXML_MESS           , 'DocumentError',
		ERR_CODE_PREFIX_BUILTIN        , 'DocumentError',
		ERR_CODE_PREFIX_ILLEGAL        , 'DocumentError',
		ERR_CODE_PREFIX_DISABLED       , '',
		ERR_CODE_INSTANCEOF_USED       , '',
		ERR_CODE_INSTANCEOF_OVERRULED  , '',
		ERR_CODE_CURIE_FELLTHROUGH     , '',
		ERR_CODE_CURIE_UNDEFINED       , 'UnresolvedCURIE',
		ERR_CODE_BNODE_WRONGPLACE      , '',
		ERR_CODE_VOCAB_DISABLED        , '',
		ERR_CODE_LANG_INVALID          ,	'DocumentError',
		)};
		
	foreach my $err ($self->errors)
	{
		my $iri = $mkuri->();
		my ($level, $code, $message, $args) = @$err;
		
		if ($level eq ERR_WARNING)
		{
			$st->($iri, $RDF->type, $RDFA->Warning);
		}
		elsif ($level eq ERR_ERROR)
		{
			$st->($iri, $RDF->type, $RDFA->Error);
		}
		if (my $class = $typemap->{$code})
		{
			$st->($iri, $RDF->type, $RDFA->$class);
		}
		
		$st->($iri, $DC->description, $message);
		
		if (blessed($args->{element}) and $args->{element}->can('nodePath'))
		{
			my $p_iri = $mkuri->();
			$st->($iri, $RDFA->context, $p_iri);
			$st->($p_iri, $RDF->type, $PTR->XPathPointer);
			$st->($p_iri, $PTR->expression, $args->{element}->nodePath);
		}
	}
	
	return $model;
}

sub processor_and_output_graph
{
	my $self  = shift;
	my $model = RDF::Trine::Model->new;
	$self->$_->get_statements->each(sub { $model->add_statement(+shift) })
		foreach qw( processor_graph graph );
	return $model;
}

sub _log_error
{
	my ($self, $level, $code, $message, %args) = @_;
	
	if (defined $self->{'sub'}->{'onerror'})
	{
		$self->{'sub'}->{'onerror'}(@_);
	}
	elsif ($level eq ERR_ERROR)
	{
		Carp::carp(sprintf("%04X: %s\n", $code, $message));
		Carp::carp(sprintf("... with URI <%s>\n", $args{'uri'}))
			if defined $args{'uri'};
		Carp::carp(sprintf("... on element '%s' with path '%s'\n", $args{'element'}->localname, $args{'element'}->nodePath))
			if blessed($args{'element'}) && $args{'element'}->isa('XML::LibXML::Node');
	}
	
	push @{$self->{errors}}, [$level, $code, $message, \%args];
}

sub consume
{
	my ($self, %args) = @_;
	
	return if $self->{'consumed'};
	$self->{'consumed'}++;
	
	if (!$self->{dom})
	{
		if ($args{survive})
		{
			$self->_log_error(
				ERR_ERROR,
				ERR_CODE_HOST,
				'Input could not be parsed into a DOM!',
				);
		}
		else
		{
			Carp::croak("Input could not be parsed into a DOM!");
		}
		return $self;
	}
	
	if ($self->{options}{graph})
	{
		$self->{options}{graph_attr} = 'graph'
			unless defined $self->{options}{graph_attr};
		$self->{options}{graph_type} = 'about'
			unless defined $self->{options}{graph_type};
		$self->{options}{graph_default} = $self->bnode
			unless defined $self->{options}{graph_default};		
	}

	local *XML::LibXML::Element::getAttributeNsSafe = sub
	{
		my ($element, $nsuri, $attribute) = @_;
		return defined $nsuri ? $element->getAttributeNS($nsuri, $attribute) : $element->getAttribute($attribute);
	};
	local *XML::LibXML::Element::hasAttributeNsSafe = sub
	{
		my ($element, $nsuri, $attribute) = @_;
		return defined $nsuri ? $element->hasAttributeNS($nsuri, $attribute) : $element->hasAttribute($attribute);
	};

	$self->_consume_element($self->dom->documentElement, { init => 1});
	
	if ($self->{options}{atom_parser} && $HAS_AWOL)
	{
		my $awol = XML::Atom::OWL->new( $self->dom , $self->uri , undef, $self->{'model'} );
		$awol->{'bnode_generator'} = $self;
		$awol->set_callbacks( $self->{'sub'} );
		$awol->consume;
	}
	
	return $self;
}

sub _consume_element
# http://www.w3.org/TR/rdfa-syntax/#sec_5.5.
{
	my $self = shift;
	
	# Processing begins by applying the processing rules below to the document
	# object, in the context of this initial [evaluation context]. All elements
	# in the tree are also processed according to the rules described below,
	# depth-first, although the [evaluation context] used for each set of rules
	# will be based on previous rules that may have been applied.
	my $current_element = shift;

	# shouldn't happen, but return 0 if it does.
	return 0 unless $current_element->nodeType == XML_ELEMENT_NODE;
	
	# The evaluation context.
	my $args = shift;
	my ($base, $parent_subject, $parent_subject_elem, $parent_object, $parent_object_elem, 
		$list_mappings, $uri_mappings, $term_mappings, $incomplete_triples, $language,
		$graph, $graph_elem, $xml_base);
		
	if ($args->{'init'})
	{
		my $init = RDF::RDFa::Parser::InitialContext->new(
			$self->{options}{initial_context},
		);
		# At the beginning of processing, an initial [evaluation context] is created
		$base                = $self->uri;
		$parent_subject      = $base;
		$parent_subject_elem = $self->dom->documentElement;
		$parent_object       = undef;
		$parent_object_elem  = undef;
		$uri_mappings        = +{ insensitive => $init->uri_mappings  };
		$term_mappings       = +{ insensitive => $init->term_mappings };
		$incomplete_triples  = [];
		$list_mappings       = {};
		$language            = undef;
		$graph               = $self->{options}{graph} ? $self->{options}{graph_default} : undef;
		$graph_elem          = undef;
		$xml_base            = undef;
		
		if ($self->{options}{vocab_default})
		{
			$uri_mappings->{'(VOCAB)'} = $self->{options}{vocab_default};
		}
		
		if ($self->{options}{prefix_default})
		{
			$uri_mappings->{'(DEFAULT PREFIX)'} = $self->{options}{prefix_default};
		}
	}
	else
	{
		$base                = $args->{'base'};
		$parent_subject      = $args->{'parent_subject'};
		$parent_subject_elem = $args->{'parent_subject_elem'};
		$parent_object       = $args->{'parent_object'};
		$parent_object_elem  = $args->{'parent_object_elem'};
		$uri_mappings        = dclone($args->{'uri_mappings'});
		$term_mappings       = dclone($args->{'term_mappings'});
		$incomplete_triples  = $args->{'incomplete_triples'};
		$list_mappings       = $args->{'list_mappings'};
		$language            = $args->{'language'};
		$graph               = $args->{'graph'};
		$graph_elem          = $args->{'graph_elem'};
		$xml_base            = $args->{'xml_base'};
	}	

	# Used by OpenDocument, otherwise usually undef.
	my $rdfans = $self->{options}{ns} || undef;

	# First, the local values are initialized
	my $recurse                      = 1;
	my $skip_element                 = 0;
	my $new_subject                  = undef;
	my $new_subject_elem             = undef;
	my $current_object_resource      = undef;
	my $current_object_resource_elem = undef;
	my $typed_resource               = undef;
	my $typed_resource_elem          = undef;	
	my $local_uri_mappings           = $uri_mappings;
	my $local_term_mappings          = $term_mappings;
	my $local_incomplete_triples     = [];
	my $current_language             = $language;
	
	my $activity = 0;

	# MOVED THIS SLIGHTLY EARLIER IN THE PROCESSING so that it can apply
	# to RDF/XML chunks.
	#
	# The [current element] is also parsed for any language information, and
	# if present, [current language] is set accordingly.
	# Language information can be provided using the general-purpose XML
	# attribute @xml:lang .
	if ($self->{options}{xhtml_lang}
	&& $current_element->hasAttribute('lang'))
	{
		if ($self->_valid_lang( $current_element->getAttribute('lang') ))
		{
			$current_language = $current_element->getAttribute('lang');
		}
		else
		{
			$self->_log_error(
				ERR_WARNING,
				ERR_CODE_LANG_INVALID,
				sprintf('Language code "%s" is not valid.', $current_element->getAtrribute('lang')),
				element => $current_element,
				lang    => $current_element->getAttribute('lang'),
				) if $@;
		}
	}
	if ($self->{options}{xml_lang}
	&& $current_element->hasAttributeNsSafe(XML_XML_NS, 'lang'))
	{
		if ($self->_valid_lang( $current_element->getAttributeNsSafe(XML_XML_NS, 'lang') ))
		{
			$current_language = $current_element->getAttributeNsSafe(XML_XML_NS, 'lang');
		}
		else
		{
			$self->_log_error(
				ERR_WARNING,
				ERR_CODE_LANG_INVALID,
				sprintf('Language code "%s" is not valid.', $current_element->getAttributeNsSafe(XML_XML_NS, 'lang')),
				element => $current_element,
				lang    => $current_element->getAttributeNsSafe(XML_XML_NS, 'lang'),
				) if $@;
		}
	}

	# EXTENSION
	# xml:base - important for RDF/XML extension
	if ($current_element->hasAttributeNsSafe(XML_XML_NS, 'base'))
	{
		my $old_base = $xml_base;
		$xml_base = $current_element->getAttributeNsSafe(XML_XML_NS, 'base');
		$xml_base =~ s/#.*$//g;
		$xml_base = $self->uri($xml_base,
			{'element'=>$current_element,'xml_base'=>$old_base});
	}
	my $hrefsrc_base = $base;
	if ($self->{options}{xml_base}==2 && defined $xml_base)
	{
		$hrefsrc_base = $xml_base;
	}

	# EXTENSION
	# Parses embedded RDF/XML - mostly useful for non-XHTML documents, e.g. SVG.
	if ($self->{options}{embedded_rdfxml}
	&& $current_element->localname eq 'RDF'
	&& $current_element->namespaceURI eq 'http://www.w3.org/1999/02/22-rdf-syntax-ns#')
	{
		return 1 if $self->{options}{embedded_rdfxml}==2;

		my $g = $graph;
		unless ($self->{options}{embedded_rdfxml} == 3)
		{
			$g = $self->bnode;
		}
		
		my $fake_lang = 0;
		unless ($current_element->hasAttributeNsSafe(XML_XML_NS, 'lang'))
		{
			$current_element->setAttributeNS(XML_XML_NS, 'lang', $current_language);
			$fake_lang = 1;
		}
		
		my $rdfxml_base = $self->{'origbase'};
		$rdfxml_base = $base
			if $self->{options}{xhtml_base}==2;
		$rdfxml_base = $xml_base
			if defined $xml_base;
		
		eval {
			my $_map;
			my $bnode_mapper = sub {
				my $orig = shift;
				$_map->{$orig} = $self->bnode
					unless defined $_map->{$orig};
				return $_map->{$orig};
			};
			my $parser  = RDF::Trine::Parser->new('rdfxml');
			my $r       = $parser->parse(
				$rdfxml_base,
				$current_element->toStringEC14N,
				sub {
					my $st = shift;
					my ($s, $p, @o);
					
					$s = $st->subject->is_blank ?
						$bnode_mapper->($st->subject->blank_identifier) :
						$st->subject->uri_value ;
					$p = $st->predicate->uri_value ;
					if ($st->object->is_literal)
					{
						@o = (
							$st->object->literal_value,
							$st->object->literal_datatype,
							$st->object->literal_value_language,
						);
						$self->_insert_triple_literal({current=>$current_element},
							$s, $p, @o,
							($self->{options}{graph} ? $g : undef));
					}
					else
					{
						push @o, $st->object->is_blank ?
							$bnode_mapper->($st->object->blank_identifier) :
							$st->object->uri_value;
						$self->_insert_triple_resource({current=>$current_element},
							$s, $p, @o,
							($self->{options}{graph} ? $g : undef));
					}				
				});
		};
		
		$self->_log_error(
			ERR_ERROR,
			ERR_CODE_RDFXML_MESS,
			"Could not parse embedded RDF/XML content: ${@}",
			element => $current_element,
			) if $@;
		
		$current_element->removeAttributeNS(XML_XML_NS, 'lang')
			if ($fake_lang);
			
		return 1;
	}
	elsif ($current_element->localname eq 'RDF'
	and    $current_element->namespaceURI eq 'http://www.w3.org/1999/02/22-rdf-syntax-ns#')
	{
		$self->_log_error(
			ERR_WARNING,
			ERR_CODE_RDFXML_MUDDLE,
			'Encountered embedded RDF/XML content, but not configured to parse or skip it.',
			element => $current_element,
			);
	}
	
	# Next the [current element] is parsed for [URI mapping]s and these are
	# added to the [local list of URI mappings]. Note that a [URI mapping] 
	# will simply overwrite any current mapping in the list that has the same
	# name
	#
	# Mappings are provided by @xmlns. The value to be mapped is set by
	# the XML namespace prefix, and the value to map is the value of the
	# attribute - a URI. Note that the URI is not processed in any way;
	# in particular if it is a relative path it is not resolved against
	# the current [base]. Authors are advised to follow best practice
	# for using namespaces, which includes not using relative paths.
	if ($self->{'options'}->{'xmlns_attr'})
	{
		foreach my $A ($current_element->getAttributes)
		{
			my $attr = $A->getName;
			
			if ($attr =~ /^xmlns\:(.+)$/i)
			{
				my $pfx = $self->{'options'}->{'prefix_nocase_xmlns'} ? (lc $1) : $1;
				my $cls = $self->{'options'}->{'prefix_nocase_xmlns'} ? 'insensitive' : 'sensitive';
				my $uri = $A->getValue;
				
				if ($pfx =~ /^(xml|xmlns|_)$/i)
				{
					$self->_log_error(
						ERR_ERROR,
						ERR_CODE_PREFIX_BUILTIN,
						"Attempt to redefine built-in CURIE prefix '$pfx' not allowed.",
						element => $current_element,
						prefix  => $pfx,
						uri     => $uri,
						);
				}
				elsif ($pfx !~ /^($XML::RegExp::NCName)$/)
				{
					$self->_log_error(
						ERR_ERROR,
						ERR_CODE_PREFIX_ILLEGAL,
						"Attempt to define non-NCName CURIE prefix '$pfx' not allowed.",
						element => $current_element,
						prefix  => $pfx,
						uri     => $uri,
						);
				}
				elsif ($uri eq XML_XML_NS || $uri eq XML_XMLNS_NS)
				{
					$self->_log_error(
						ERR_ERROR,
						ERR_CODE_PREFIX_BUILTIN,
						"Attempt to define any CURIE prefix for '$uri' not allowed using \@xmlns.",
						element => $current_element,
						prefix  => $pfx,
						uri     => $uri,
						);
				}
				else
				{
					$self->{'sub'}->{'onprefix'}($self, $current_element, $pfx, $uri, $cls)
						if defined $self->{'sub'}->{'onprefix'};
					
					$local_uri_mappings->{$cls}->{$pfx} = $uri;
				}
			}
		}
	}
	
	# RDFa 1.1 - @prefix support.
	# Note that this overwrites @xmlns:foo.
	if ($self->{'options'}->{'prefix_attr'}
	&& $current_element->hasAttributeNsSafe($rdfans, 'prefix'))
	{
		my $pfx_attr = $current_element->getAttributeNsSafe($rdfans, 'prefix') . ' ';
		my @bits     = split /[\s\r\n]+/, $pfx_attr;
		while (@bits)
		{
			my ($bit1, $bit2, @rest) = @bits;
			@bits = @rest;
			$bit1 =~ s/:$//;
			
			my $pfx = $self->{'options'}->{'prefix_nocase_attr'} ? (lc $bit1) : $bit1;
			my $cls = $self->{'options'}->{'prefix_nocase_attr'} ? 'insensitive' : 'sensitive';
			my $uri = $bit2;
			
			unless ($pfx =~ /^$XML::RegExp::NCName$/)
			{
				$self->_log_error(
					ERR_ERROR,
					ERR_CODE_PREFIX_ILLEGAL,
					"Attempt to define non-NCName CURIE prefix '$pfx' not allowed.",
					element => $current_element,
					prefix  => $pfx,
					uri     => $uri,
					);
				next;
			}
			
			$self->{'sub'}->{'onprefix'}($self, $current_element, $pfx, $uri, $cls)
				if defined $self->{'sub'}->{'onprefix'};
			$local_uri_mappings->{$cls}->{$pfx} = $uri;
		}
	}
	elsif ($current_element->hasAttributeNsSafe($rdfans, 'prefix'))
	{
		$self->_log_error(
			ERR_WARNING,
			ERR_CODE_PREFIX_DISABLED,
			"\@prefix found, but support disabled.",
			element => $current_element,
			);
	}
	
	# RDFa 1.1 - @vocab support
	if ($self->{options}{vocab_attr}
	&& $current_element->hasAttributeNsSafe($rdfans, 'vocab'))
	{
		if ($current_element->getAttributeNsSafe($rdfans, 'vocab') eq '')
		{
			$local_uri_mappings->{'(VOCAB)'} = $self->{options}{vocab_default};
		}
		else
		{
			$local_uri_mappings->{'(VOCAB)'} = $self->uri(
				$current_element->getAttributeNsSafe($rdfans, 'vocab'),
				{'element'=>$current_element,'xml_base'=>$xml_base});
		}
	}
	elsif ($current_element->hasAttributeNsSafe($rdfans, 'vocab'))
	{
		$self->_log_error(
			ERR_WARNING,
			ERR_CODE_VOCAB_DISABLED,
			"\@vocab found, but support disabled.",
			element => $current_element,
			uri     => $self->uri(
				$current_element->getAttributeNsSafe($rdfans, 'vocab'),
				{'element'=>$current_element,'xml_base'=>$xml_base}),
			);
	}
	
	# EXTENSION
	# KjetilK's named graphs.
	if ($self->{'options'}->{'graph'})
	{
		my ($xmlns, $attr) = ($self->{'options'}->{'graph_attr'} =~ /^(?:\{(.+)\})?(.+)$/);
		unless ($attr)
		{
			$xmlns = $rdfans;
			$attr  = 'graph';
		}
		
		if ($self->{'options'}->{'graph_type'} eq 'id'
		&&  $current_element->hasAttributeNsSafe($xmlns, $attr))
		{
			$graph = $self->uri('#' . $current_element->getAttributeNsSafe($xmlns, $attr),
				{'element'=>$current_element,'xml_base'=>$hrefsrc_base});
		}
		elsif ($self->{'options'}->{'graph_type'} eq 'about'
		&&  $current_element->hasAttributeNsSafe($xmlns, $attr))
		{
			$graph = $self->_expand_curie(
				$current_element->getAttributeNsSafe($xmlns, $attr),
				element   => $current_element,
				attribute => 'graph',
				prefixes  => $local_uri_mappings,
				terms     => $local_term_mappings,
				xml_base  => $xml_base,
				);			
			$graph = $self->{'options'}->{'graph_default'}
				unless defined $graph;
		}
	}

	if ($self->{options}{vocab_triple}
	and $self->{options}{vocab_attr}
	and $current_element->hasAttributeNsSafe($rdfans, 'vocab')
	and defined $local_uri_mappings->{'(VOCAB)'})
	{
		$self->_insert_triple_resource({
			current   => $current_element,
			subject   => $current_element->ownerDocument->documentElement,
			predicate => $current_element,
			object    => $current_element,
			graph     => $graph_elem,
			},
			$base,
			'http://www.w3.org/ns/rdfa#usesVocabulary',
			$local_uri_mappings->{'(VOCAB)'},
			$graph);
	}
		
	# EXTENSION: @role
	if ($self->{'options'}->{'role_attr'}
	&&  $current_element->hasAttributeNsSafe($rdfans, 'role'))
	{
		my @role = $self->_split_tokens( $current_element->getAttributeNsSafe($rdfans, 'role') );
		my @ROLE = map {
			my $x = $self->_expand_curie(
				$_,
				element   => $current_element,
				attribute => 'role',
				prefixes  => $local_uri_mappings,
				terms     => $local_term_mappings,
				xml_base  => $xml_base,
				);
			defined $x ? ($x) : ();
			} @role;	
		if (@ROLE)
		{
			if ($current_element->hasAttribute('id')
			and !defined $self->{element_subjects}->{$current_element->nodePath})
			{
				$self->{element_subjects}->{$current_element->nodePath} = $self->uri(sprintf('#%s',
					$current_element->getAttribute('id')),
					{'element'=>$current_element,'xml_base'=>$hrefsrc_base});
			}
			elsif (!defined $self->{element_subjects}->{$current_element->nodePath})
			{
				$self->{element_subjects}->{$current_element->nodePath} = $self->bnode;
			}

			foreach my $r (@ROLE)
			{
				my $E = {
					current   => $current_element,
					subject   => $current_element,
					predicate => $current_element,
					object    => $current_element,
					graph     => $graph_elem,
					};
				$self->_insert_triple_resource($E, $self->{element_subjects}->{$current_element->nodePath}, 'http://www.w3.org/1999/xhtml/vocab#role', $r, $graph);
			}
		}
	}
	
	# EXTENSION: @cite
	if ($self->{'options'}->{'cite_attr'}
	&&  $current_element->hasAttributeNsSafe($rdfans, 'cite'))
	{
		my $citation = $self->uri(
			$current_element->getAttributeNsSafe($rdfans, 'cite'),
			{'element'=>$current_element,'xml_base'=>$hrefsrc_base}
			);
		if (defined $citation)
		{
			if ($current_element->hasAttribute('id')
			and !defined $self->{element_subjects}->{$current_element->nodePath})
			{
				$self->{element_subjects}->{$current_element->nodePath} = $self->uri(sprintf('#%s',
					$current_element->getAttribute('id')),
					{'element'=>$current_element,'xml_base'=>$hrefsrc_base});
			}
			elsif (!defined $self->{element_subjects}->{$current_element->nodePath})
			{
				$self->{element_subjects}->{$current_element->nodePath} = $self->bnode;
			}
			
			my $E = {
				current   => $current_element,
				subject   => $current_element,
				predicate => $current_element,
				object    => $current_element,
				graph     => $graph_elem,
				};
			$self->_insert_triple_resource($E, $self->{element_subjects}->{$current_element->nodePath}, 'http://www.w3.org/1999/xhtml/vocab#cite', $citation, $graph);
		}
	}
	
	my @rel = $self->_split_tokens( $current_element->getAttributeNsSafe($rdfans, 'rel') );
	my @rev = $self->_split_tokens( $current_element->getAttributeNsSafe($rdfans, 'rev') );

	# EXTENSION: rel="alternate stylesheet"
	if ($self->{options}{alt_stylesheet}
	&&  (grep /^alternate$/i, @rel)
	&&  (grep /^stylesheet$/i, @rel))
	{
		@rel = grep !/^(alternate|stylesheet)$/i, @rel;
		push @rel, ':ALTERNATE-STYLESHEET';
	}
	
	my @REL = map {
		my $x = $self->_expand_curie(
			$_,
			element   => $current_element,
			attribute => 'rel',
			prefixes  => $local_uri_mappings,
			terms     => $local_term_mappings,
			xml_base  => $xml_base,
			);
		defined $x ? ($x) : ();
		} @rel;	
	my @REV = map {
		my $x = $self->_expand_curie(
			$_,
			element   => $current_element,
			attribute => 'rev',
			prefixes  => $local_uri_mappings,
			terms     => $local_term_mappings,
			xml_base  => $xml_base,
			);
		defined $x ? ($x) : ();
		} @rev;

	my $NEW_SUBJECT_ATTR_ABOUT = sub
	{
		if ($current_element->hasAttributeNsSafe($rdfans, 'about'))
		{
			my $s = $self->_expand_curie(
				$current_element->getAttributeNsSafe($rdfans, 'about'),
				element   => $current_element,
				attribute => 'about',
				prefixes  => $local_uri_mappings,
				terms     => $local_term_mappings,
				xml_base  => $xml_base,
				);
			my $e = $current_element;
			return ($s, $e);
		}
		return;
	};
	
	my $NEW_SUBJECT_ATTR_SRC = sub
	{
		if ($current_element->hasAttributeNsSafe($rdfans, 'src'))
		{
			my $s = $self->uri(
				$current_element->getAttributeNsSafe($rdfans, 'src'),
				{'element'=>$current_element,'xml_base'=>$hrefsrc_base}
				);
			my $e = $current_element;
			return ($s, $e);
		}
		return;
	};
	
	my $NEW_SUBJECT_DEFAULTS = sub
	{
		if ($current_element == $current_element->ownerDocument->documentElement)
		{
			return ($self->uri(undef, {'element'=>$current_element,'xml_base'=>$hrefsrc_base}), $current_element);
		}
		
		# if the element is the head or body element then act as if
		# there is an empty @about present, and process it according to
		# the rule for @about, above; 
		if ($self->{options}{xhtml_elements}
		&& ($current_element->namespaceURI eq 'http://www.w3.org/1999/xhtml')
		&& ($current_element->tagName eq 'head' || $current_element->tagName eq 'body'))
		{
			return ($parent_object, $parent_object_elem)
				if $self->{options}{xhtml_elements}==2;
			return ($self->uri(undef, {'element'=>$current_element,'xml_base'=>$hrefsrc_base}), $current_element);
		}

		# EXTENSION: atom elements
		if ($self->{options}{atom_elements}
		&& ($current_element->namespaceURI eq 'http://www.w3.org/2005/Atom')
		&& ($current_element->tagName eq 'feed' || $current_element->tagName eq 'entry'))
		{
			return ($self->_atom_magic($current_element), $current_element);
		}
		
		return;
	};
	
	my $NEW_SUBJECT_INHERIT = sub
	{
		$skip_element = 1
			if shift
			&& not $current_element->hasAttributeNsSafe($rdfans, 'property');

		return ($parent_object, $parent_object_elem) if $parent_object;
		return;
	};
	
	my $NEW_SUBJECT_ATTR_RESOURCE = sub
	{
		if ($current_element->hasAttributeNsSafe($rdfans, 'resource'))
		{
			my $s = $self->_expand_curie(
				$current_element->getAttributeNsSafe($rdfans, 'resource'), 
				element   => $current_element,
				attribute => 'resource',
				prefixes  => $local_uri_mappings,
				terms     => $local_term_mappings,
				xml_base  => $xml_base,
				);
			return ($s, $current_element);
		}
		return;
	};

	my $NEW_SUBJECT_ATTR_HREF = sub
	{
		if ($current_element->hasAttributeNsSafe($rdfans, 'href'))
		{
			my $s = $self->uri(
				$current_element->getAttributeNsSafe($rdfans, 'href'),
				{'element'=>$current_element,'xml_base'=>$hrefsrc_base}
				);
			return ($s, $current_element);
		}
		return;
	};

	my $NEW_SUBJECT_ATTR_TYPEOF = sub
	{
		if ($current_element->hasAttributeNsSafe($rdfans, 'typeof')
		or  $current_element->hasAttributeNsSafe($rdfans, 'instanceof'))
		{
			if ($current_element->hasAttributeNsSafe($rdfans, 'instanceof')
			and not $current_element->hasAttributeNsSafe($rdfans, 'typeof'))
			{
				$self->_log_error(
					ERR_WARNING,
					ERR_CODE_INSTANCEOF_USED,
					"Deprecated \@instanceof found; using it anyway.",
					element => $current_element,
					);
			}
			
			return ($self->bnode($current_element), $current_element);
		}
		return;
	};

	# If the current element contains no @rel or @rev attribute, then the
	# next step is to establish a value for new subject. This step has two
	# possible alternatives.
	#
	# If the current element contains the @property attribute, but does not
	# contain either the @content or @datatype attributes, then
	#
	if (!$current_element->hasAttributeNsSafe($rdfans, 'rel')
	and !$current_element->hasAttributeNsSafe($rdfans, 'rev')
	and  $current_element->hasAttributeNsSafe($rdfans, 'property')
	and !$current_element->hasAttributeNsSafe($rdfans, 'datatype')
	and !$current_element->hasAttributeNsSafe($rdfans, 'content')
	and  $self->{options}{property_resources})
	{
		# new subject is set to the resource obtained from the first match
		# from the following rule:
		#
		#   - by using the resource from @about, if present, obtained according
		#     to the section on CURIE and IRI Processing;
		#   - otherwise, if the element is the root element of the document, then
		#     act as if there is an empty @about present, and process it according
		#     to the rule for @about, above;
		#   - otherwise, if parent object is present, new subject is set to the
		#     value of parent object.
		#
		# TOBYINK: we add @src to that for RDFa 1.0/1.1 mish-mashes.
		#
		foreach my $code (
			$NEW_SUBJECT_ATTR_ABOUT,
			($NEW_SUBJECT_ATTR_SRC) x!$self->{options}{src_sets_object},
			$NEW_SUBJECT_DEFAULTS,
			$NEW_SUBJECT_INHERIT,
		) {
			($new_subject, $new_subject_elem) = $code->() unless $new_subject;
		}
		
		# If @typeof is present then typed resource is set to the resource
		# obtained from the first match from the following rules:
		#
		if ($current_element->hasAttributeNsSafe($rdfans, 'typeof')
		or  $current_element->hasAttributeNsSafe($rdfans, 'instanceof'))
		{
			#   - by using the resource from @about, if present, obtained
			#     according to the section on CURIE and IRI Processing;
			#   - otherwise, if the element is the root element of the
			#     document, then act as if there is an empty @about present
			#     and process it according to the previous rule;
			#
			foreach my $code (
				$NEW_SUBJECT_ATTR_ABOUT,
				($NEW_SUBJECT_ATTR_SRC) x!$self->{options}{src_sets_object},
				$NEW_SUBJECT_DEFAULTS,
			) {
				($typed_resource, $typed_resource_elem) = $code->() unless $typed_resource;
			}
			
			#   - otherwise,
			unless ($typed_resource)
			{
				#     + by using the resource from @resource, if present,
				#       obtained according to the section on CURIE and IRI
				#       Processing;
				#     + otherwise, by using the IRI from @href, if present,
				#       obtained according to the section on CURIE and IRI
				#       Processing;
				#     + otherwise, by using the IRI from @src, if present,
				#       obtained according to the section on CURIE and IRI
				#       Processing;
				#
				foreach my $code (
					$NEW_SUBJECT_ATTR_RESOURCE,
					$NEW_SUBJECT_ATTR_HREF,
					($NEW_SUBJECT_ATTR_SRC) x!!$self->{options}{src_sets_object},
				) {
					($typed_resource, $typed_resource_elem) = $code->() unless $typed_resource;
				}
				
				#     + otherwise, the value of typed resource is set to a
				#       newly created bnode.
				#
				unless ($typed_resource)
				{
					($typed_resource, $typed_resource_elem) =
						($self->bnode($current_element), $current_element);
				}
				
				#     + The value of the current object resource is then set
				#       to the value of typed resource.
				#
				($current_object_resource, $current_object_resource_elem) = 
					($typed_resource, $typed_resource_elem);
			}
		}
	}
	
	# otherwise
	elsif (!$current_element->hasAttributeNsSafe($rdfans, 'rel')
	   and !$current_element->hasAttributeNsSafe($rdfans, 'rev'))
	{
		#   - If the element contains an @about, @href, @src, or @resource
		#     attribute, new subject is set to the resource obtained as
		#     follows:
		#     + by using the resource from @about, if present, obtained
		#       according to the section on CURIE and IRI Processing;
		#     + otherwise, by using the resource from @resource, if
		#       present, obtained according to the section on CURIE and
		#       IRI Processing;
		#     + otherwise, by using the IRI from @href, if present,
		#       obtained according to the section on CURIE and IRI
		#       Processing;
		#     + otherwise, by using the IRI from @src, if present,
		#       obtained according to the section on CURIE and IRI
		#       Processing.
		#   - otherwise, if no resource is provided by a resource
		#     attribute, then the first match from the following rules
		#     will apply: 
		#     + if the element is the root element of the document,
		#       then act as if there is an empty @about present, and
		#       process it according to the rule for @about, above;
		#     + otherwise, if @typeof is present, then new subject is
		#       set to be a newly created bnode;
		#     + otherwise, if parent object is present, new subject is
		#       set to the value of parent object. Additionally, if
		#       @property is not present then the skip element flag is
		#       set to 'true'.
		#
		my $i;
		foreach my $code (
			$NEW_SUBJECT_ATTR_ABOUT,
			($NEW_SUBJECT_ATTR_SRC) x!$self->{options}{src_sets_object},
			$NEW_SUBJECT_ATTR_RESOURCE,
			$NEW_SUBJECT_ATTR_HREF,
			($NEW_SUBJECT_ATTR_SRC) x!!$self->{options}{src_sets_object},
			$NEW_SUBJECT_DEFAULTS,
			$NEW_SUBJECT_ATTR_TYPEOF,
			sub { $NEW_SUBJECT_INHERIT->(1) },
		) {
			last if $new_subject;
			($new_subject, $new_subject_elem) = $code->();
		}

#		if ($current_element->{'x-foo'})
#		{
#			use Data::Dumper;
#			print Dumper \%args;
#		}
		
		#   - Finally, if @typeof is present, set the typed resource
		#     to the value of new subject.
		#
		if ($current_element->hasAttributeNsSafe($rdfans, 'typeof')
		or  $current_element->hasAttributeNsSafe($rdfans, 'instanceof'))
		{
			($typed_resource, $typed_resource_elem) = ($new_subject, $new_subject_elem);
		}		
	}
	
	# If the [current element] does contain a valid @rel or @rev URI, obtained 
	# according to the section on CURIE and URI Processing, then the next step 
	# is to establish both a value for [new subject] and a value for [current
	# object resource]:
	else
	{
		foreach my $code (
			$NEW_SUBJECT_ATTR_ABOUT,
			($NEW_SUBJECT_ATTR_SRC)    x!$self->{options}{src_sets_object},
			($NEW_SUBJECT_ATTR_TYPEOF) x!$self->{options}{typeof_resources},
			$NEW_SUBJECT_DEFAULTS,
			$NEW_SUBJECT_INHERIT,
		) {
			($new_subject, $new_subject_elem) = $code->() unless $new_subject;
		}

		foreach my $code (
			$NEW_SUBJECT_ATTR_RESOURCE,
			$NEW_SUBJECT_ATTR_HREF,
			($NEW_SUBJECT_ATTR_SRC) x!!$self->{options}{src_sets_object},
		) {
			($current_object_resource, $current_object_resource_elem) = $code->() unless $current_object_resource;
		}
		
		if ($current_element->hasAttributeNsSafe($rdfans, 'typeof')
		or  $current_element->hasAttributeNsSafe($rdfans, 'instanceof'))
		{
			if ($current_element->hasAttributeNsSafe($rdfans, 'about'))
			{
				($typed_resource, $typed_resource_elem) = ($new_subject, $new_subject_elem);
			}
			elsif ($self->{options}{typeof_resources})
			{
				($current_object_resource, $current_object_resource_elem) =
					($self->bnode($current_element), $current_element)
					unless $current_object_resource;
						
				($typed_resource, $typed_resource_elem) = ($current_object_resource, $current_object_resource_elem);
			}
			else
			{
				($typed_resource, $typed_resource_elem) = ($new_subject, $new_subject_elem);
			}
		}
	}
	
#	# NOTE: x876587
#	if (!defined $new_subject
#	and $current_element->nodePath eq $self->dom->documentElement->nodePath)
#	{
#		$new_subject = $self->uri('');
#		$new_subject_elem = $self->dom->documentElement;
#		$skip_element = 1
#		unless $current_element->hasAttributeNsSafe($rdfans, 'property');
#	}
	
	# If in any of the previous steps a [typed resource] was set to a non-null
	# value, it is now used to provide a subject for type values
	if ($typed_resource
	&& (  $current_element->hasAttributeNsSafe($rdfans, 'instanceof')
		|| $current_element->hasAttributeNsSafe($rdfans, 'typeof')))
	{

		if ($current_element->hasAttributeNsSafe($rdfans, 'instanceof')
		&&  $current_element->hasAttributeNsSafe($rdfans, 'typeof'))
		{
			$self->_log_error(
				ERR_WARNING,
				ERR_CODE_INSTANCEOF_OVERRULED,
				"Deprecated \@instanceof found; ignored because \@typeof also present.",
				element => $current_element,
				);
		}
		elsif ($current_element->hasAttributeNsSafe($rdfans, 'instanceof'))
		{
			$self->_log_error(
				ERR_WARNING,
				ERR_CODE_INSTANCEOF_USED,
				"Deprecated \@instanceof found; using it anyway.",
				element => $current_element,
				);
		}

		# One or more 'types' for the [ new subject ] can be set by using
		# @instanceof. If present, the attribute must contain one or more
		# URIs, obtained according to the section on URI and CURIE Processing...
	
		my @instanceof = $self->_split_tokens(  $current_element->getAttributeNsSafe($rdfans, 'typeof')
			|| $current_element->getAttributeNsSafe($rdfans, 'instanceof') );
		
		foreach my $curie (@instanceof)
		{
			my $rdftype = $self->_expand_curie(
				$curie,
				element   => $current_element,
				attribute => 'typeof',
				prefixes  => $local_uri_mappings,
				terms     => $local_term_mappings,
				xml_base  => $xml_base,
				);				
			next unless defined $rdftype;
		
			# ... each of which is used to generate a triple as follows:
			#
			# subject
			#     [new subject] 
			# predicate
	    	#     http://www.w3.org/1999/02/22-rdf-syntax-ns#type 
			# object
			#     full URI of 'type' 

			my $E = { # provenance tracking
				current   => $current_element,
				subject   => $typed_resource_elem,
				predicate => $current_element,
				object    => $current_element,
				graph     => $graph_elem,
				};
			$self->_insert_triple_resource($E, $typed_resource, RDF_TYPE, $rdftype, $graph);
			$activity++;
		}
	}

	# EXTENSION: @longdesc
	if ($self->{'options'}->{'longdesc_attr'}
	&&  $current_element->hasAttributeNsSafe($rdfans, 'longdesc'))
	{
		my $longdesc = $self->uri(
			$current_element->getAttributeNsSafe($rdfans, 'longdesc'),
			{'element'=>$current_element,'xml_base'=>$hrefsrc_base}
			);
		if (defined $longdesc)
		{
			my $E = {
				current   => $new_subject_elem,
				subject   => $current_element,
				predicate => $current_element,
				object    => $current_element,
				graph     => $graph_elem,
				};
			$self->_insert_triple_resource($E, $new_subject, 'http://www.w3.org/2007/05/powder-s#describedby', $longdesc, $graph);
		}
	}	

	# If in any of the previous steps a new subject was set to a non-null value
	# different from the parent object; The list mapping taken from the
	# evaluation context is set to a new, empty mapping.
	if (defined $new_subject
	and $new_subject ne $parent_subject || !%$list_mappings)
	{
		$list_mappings = {
			'::meta' => {
				id    => Data::UUID->new->create_str,
				owner => $current_element,
			},
		};
	}

	# If in any of the previous steps a [current object resource] was set to
	# a non-null value, it is now used to generate triples and add entries to
	# the local list mapping
	if ($current_object_resource)
	{
		# If the element contains both the inlist and the rel attributes: the
		# rel may contain one or more IRIs, obtained according to the section
		# on CURIE and IRI Processing each of which is used to add an entry to
		# the list mapping as follows:
		if ($current_element->hasAttributeNsSafe($rdfans, 'inlist')
		and $current_element->hasAttributeNsSafe($rdfans, 'rel'))
		{
			foreach my $r (@REL)
			{
				# if the local list mapping does not contain a list associated with
				# the IRI, instantiate a new list and add to local list mappings
				$list_mappings->{$r} = [] unless defined $list_mappings->{$r};
				
				# add the current object resource to the list associated with the IRI
				# in the local list mapping
				push @{ $list_mappings->{$r} }, [resource => $current_object_resource];
				$activity++;
			}
		}
		
# XXX:@inlist doesn't support @rev?
#
#		if ($current_element->hasAttributeNsSafe($rdfans, 'inlist')
#		and $current_element->hasAttributeNsSafe($rdfans, 'rev'))
#		{
#			foreach my $r (@REV)
#			{
#				# if the local list mapping does not contain a list associated with
#				# the IRI, instantiate a new list and add to local list mappings
#				$list_mappings->{'REV:'.$r} = [] unless defined $list_mappings->{'REV:'.$r};
#				
#				# add the current object resource to the list associated with the IRI
#				# in the local list mapping
#				push @{ $list_mappings->{'REV:'.$r} }, [resource => $current_object_resource];
#			}
#		}
		
		my $E = { # provenance tracking
			current   => $current_element,
			subject   => $new_subject_elem,
			predicate => $current_element,
			object    => $current_object_resource_elem,
			graph     => $graph_elem,
			};
		
		# Predicates for the [ current object resource ] can be set by
		# using one or both of the @rel and @rev attributes, but, in
		# case of the @rel attribute, only if the @inlist is not present:
		#
		#    * If present, @rel will contain one or more URIs, obtained
		#      according to the section on CURIE and URI Processing each
		#      of which is used to generate a triple as follows:
		#
		#      subject
		#          [new subject] 
		#      predicate
		#          full URI 
		#      object
		#          [current object resource] 
		
		unless ($current_element->hasAttributeNsSafe($rdfans, 'inlist'))
		{
			foreach my $r (@REL)
			{
				$self->_insert_triple_resource($E, $new_subject, $r, $current_object_resource, $graph);
				$activity++;
			}
		}
		
		#    * If present, @rev will contain one or more URIs, obtained
		#      according to the section on CURIE and URI Processing each
		#      of which is used to generate a triple as follows:
		#
		#      subject
		#          [current object resource] 
		#      predicate
		#          full URI 
		#      object
		#          [new subject] 
		
		$E = { # provenance tracking
			current   => $current_element,
			subject   => $current_object_resource_elem,
			predicate => $current_element,
			object    => $new_subject_elem,
			graph     => $graph_elem,
			};
		foreach my $r (@REV)
		{
			$self->_insert_triple_resource($E, $current_object_resource, $r, $new_subject, $graph);
			$activity++;
		}
	}
	
	# If however [current object resource] was set to null, but there are 
	# predicates present, then they must be stored as [incomplete triple]s, 
	# pending the discovery of a subject that can be used as the object. Also, 
	# [current object resource] should be set to a newly created [bnode]
	elsif ((scalar @REL) || (scalar @REV))
	{
		# Predicates for [incomplete triple]s can be set by using one or
		# both of the @rel and @rev attributes:
		#
		#    * If present, @rel must contain one or more URIs, obtained 
		#      according to the section on CURIE and URI Processing each
		#      of which is added to the [local list of incomplete triples]
		#      as follows:
		#
		#      predicate
		#          full URI 
		#      direction
		#          forward 
		
		push @$local_incomplete_triples,
			map {
				$current_element->hasAttributeNsSafe($rdfans, 'inlist')
				?{
					list              => do { $list_mappings->{$_} = [] unless defined $list_mappings->{$_}; $list_mappings->{$_} },
					direction         => 'none',
				}
				:{
					predicate         => $_,
					direction         => 'forward',
					graph             => $graph,
 					predicate_element => $current_element,
					graph_element     => $graph_elem,
				}
			} @REL;
		
		#    * If present, @rev must contain one or more URIs, obtained
		#      according to the section on CURIE and URI Processing, each
		#      of which is added to the [local list of incomplete triples]
		#      as follows:
		#
		#      predicate
		#          full URI 
		#      direction
		#          reverse 
		
		push @$local_incomplete_triples,
			map {
#				$current_element->hasAttributeNsSafe($rdfans, 'inlist')
#				?{
#					list              => do { $list_mappings->{'REV:'.$_} = [] unless defined $list_mappings->{'REV:'.$_}; $list_mappings->{'REV:'.$_}; },
#					direction         => 'none',
#				}
#				:{
				+{
					predicate         => $_,
					direction         => 'reverse',
					graph             => $graph,
					predicate_element => $current_element,
					graph_element     => $graph_elem,
				}
			} @REV;
		
		$current_object_resource = $self->bnode;
		$current_object_resource_elem = $current_element;
	}

	# The next step of the iteration is to establish any [current 
	# property value]
	my @current_property_value;
	
	my @prop = $self->_split_tokens( $current_element->getAttributeNsSafe($rdfans, 'property') );

	my $has_datatype = 0;
	my $datatype = undef;
	if ($current_element->hasAttributeNsSafe($rdfans, 'datatype'))
	{
		$has_datatype = 1;
		$datatype = $self->_expand_curie(
			$current_element->getAttributeNsSafe($rdfans, 'datatype'),
			element   => $current_element,
			attribute => 'datatype',
			prefixes  => $local_uri_mappings,
			terms     => $local_term_mappings,
			xml_base  => $xml_base,
			);
	}
		
	if (@prop)
	{
		# Predicates for the [current object literal] can be set by using
		# @property. If present, one or more URIs are obtained according
		# to the section on CURIE and URI Processing and then the actual
		# literal value is obtained as follows:
		
		# HTML+RDFa
		if ($self->{options}{datetime_attr}
		and (
			$current_element->hasAttributeNsSafe($rdfans, 'datetime')
			or $current_element->namespaceURI eq 'http://www.w3.org/1999/xhtml'
				&& lc($current_element->tagName) eq 'time'
		)) {
			@current_property_value = (
				$current_element->hasAttributeNsSafe($rdfans, 'datetime')
					? $current_element->getAttributeNsSafe($rdfans, 'datetime')
					: $self->_element_to_string($current_element)
			);
						
			push @current_property_value, do
			{
				local $_ = $current_property_value[0];
				
				if (!!$has_datatype == !!1)
					{ $datatype }
				elsif (/^(\-?\d{4,})-(\d{2})-(\d{2})T(\d{2}):(\d{2})(:(\d{2})(?:\.\d+)?)?(Z|(?:[\+\-]\d{2}:?\d{2}))?$/i)
					{ 'http://www.w3.org/2001/XMLSchema#dateTime' }
				elsif (/^(\d{2}):(\d{2})(:(\d{2})(?:\.\d+)?)?(Z|(?:[\+\-]\d{2}:?\d{2}))?$/i)
					{ 'http://www.w3.org/2001/XMLSchema#time' }
				elsif (/^(\-?\d{4,})-(\d{2})-(\d{2})(Z|(?:[\+\-]\d{2}:?\d{2}))?$/i)
					{ 'http://www.w3.org/2001/XMLSchema#date' }
				elsif (/^(\-?\d{4,})-(\d{2})(Z|(?:[\+\-]\d{2}:?\d{2}))?$/i)
					{ 'http://www.w3.org/2001/XMLSchema#gYearMonth' } # XXX: not in spec!
				elsif (/^(\-?\d{4,})(Z|(?:[\+\-]\d{2}:?\d{2}))?$/i)
					{ 'http://www.w3.org/2001/XMLSchema#gYear' } # XXX: not in spec!
				elsif (/^--(\d{2})-(\d{2})(Z|(?:[\+\-]\d{2}:?\d{2}))?$/i)
					{ 'http://www.w3.org/2001/XMLSchema#gMonthDay' } # XXX: not in spec!
				elsif (/^---(\d{2})(Z|(?:[\+\-]\d{2}:?\d{2}))?$/i)
					{ 'http://www.w3.org/2001/XMLSchema#gDay' } # XXX: not in spec!
				elsif (/^--(\d{2})(Z|(?:[\+\-]\d{2}:?\d{2}))?$/i)
					{ 'http://www.w3.org/2001/XMLSchema#gMonth' } # XXX: not in spec!
				elsif (/^P([\d\.]+Y)?([\d\.]+M)?([\d\.]+D)?(T([\d\.]+H)?([\d\.]+M)?([\d\.]+S)?)?$/i)
					{ 'http://www.w3.org/2001/XMLSchema#duration' }
				else
					{ undef }
			}, $current_language;
		}

		# HTML+RDFa
		elsif ($self->{options}{value_attr}
		and $current_element->hasAttributeNsSafe($rdfans, 'value'))
		{
			@current_property_value = (
				$current_element->getAttributeNsSafe($rdfans, 'value'),
				($has_datatype ? $datatype : undef),
				$current_language,
			);
		}

		# as a [ plain literal ] if: 
		#
		# @content is present; 
		elsif ($current_element->hasAttributeNsSafe($rdfans, 'content'))
		{
			@current_property_value = (
				$current_element->getAttributeNsSafe($rdfans, 'content'),
				($has_datatype ? $datatype : undef),
				$current_language,
			);
		}
		
		# OpenDocument 1.2 extension
		elsif (defined $self->{options}{bookmark_end}
		and    defined $self->{options}{bookmark_name}
		and    sprintf('{%s}%s', $current_element->namespaceURI, $current_element->localname)
		         ~~ ['{}'.$self->{options}{bookmark_start}, $self->{options}{bookmark_start}]
		) {
			@current_property_value = (
				$self->_element_to_bookmarked_string($current_element),
				($has_datatype ? $datatype: undef),
				$current_language,
			);
		}
		
		# Additionally, if there is a value for [current language] then
		# the value of the [plain literal] should include this language
		# information, as described in [RDF-CONCEPTS]. The actual literal
		# is either the value of @content (if present) or a string created
		# by concatenating the text content of each of the descendant
		# elements of the [current element] in document order. 
		
		# or all children of the [current element] are text nodes;
		# or there are no child nodes;
		# or the body of the [ current element ] does have non-text
		#    child nodes but @datatype is present, with an empty value. 
		elsif ($has_datatype and $datatype eq '')
		{
			@current_property_value = (
				$self->_element_to_string($current_element),
				($has_datatype ? $datatype: undef),
				$current_language,
			);
		}

		# as an [XML literal] if: explicitly rdf:XMLLiteral.
		elsif ($datatype eq RDF_XMLLIT)
		{
			@current_property_value = (
				$self->_element_to_xml($current_element, $current_language),
				RDF_XMLLIT,
				$current_language,
			);
			$recurse = $self->{options}{xmllit_recurse};
		}
		
		# as a [typed literal] if:
		#
		#     * @datatype is present, and does not have an empty value.
		#
		# The actual literal is either the value of @content (if present)
		# or a string created by concatenating the value of all descendant
		# text nodes, of the [current element] in turn. The final string
		# includes the datatype URI, as described in [RDF-CONCEPTS], which
		# will have been obtained according to the section on CURIE and URI
		# Processing.
		elsif ($has_datatype)
		{
			if ($current_element->hasAttributeNsSafe($rdfans, 'content'))
			{
				@current_property_value = (
					$current_element->getAttributeNsSafe($rdfans, 'content'),
					$datatype,
					$current_language,
				);
			}
			else
			{
				@current_property_value = (
					$self->_element_to_string($current_element),
					$datatype,
					$current_language,
				);
			}
		}
		
		elsif ($self->{options}{property_resources}
		and    !$current_element->hasAttributeNsSafe($rdfans, 'datatype')
		and    !$current_element->hasAttributeNsSafe($rdfans, 'content')
		and    !$current_element->hasAttributeNsSafe($rdfans, 'rel')
		and    !$current_element->hasAttributeNsSafe($rdfans, 'rev')
		and (
			   $current_element->hasAttributeNsSafe($rdfans, 'resource')
			or $current_element->hasAttributeNsSafe($rdfans, 'href')
			or $current_element->hasAttributeNsSafe($rdfans, 'src')
				&& $self->{options}{src_sets_object}
			))
		{
			my $resource;
			foreach my $attr (qw(resource href src))
			{
				next unless $current_element->hasAttributeNsSafe($rdfans, $attr);
				$resource = $self->_expand_curie(
					$current_element->getAttributeNsSafe($rdfans, $attr),
					element   => $current_element,
					attribute => $attr,
					prefixes  => $local_uri_mappings,
					terms     => $local_term_mappings,
					xml_base  => $xml_base,
				);
				last if defined $resource;
			}
			@current_property_value = ([ $resource ]) if defined $resource;
		}
		
		elsif ($self->{options}{property_resources}
		and    defined $typed_resource
		and    $current_element->hasAttributeNsSafe($rdfans, 'typeof')
		and   !$current_element->hasAttributeNsSafe($rdfans, 'about'))
		{
			@current_property_value = ([ $typed_resource ]);
		}

		# or all children of the [current element] are text nodes;
		# or there are no child nodes;
		# or the body of the [ current element ] does have non-text
		#    child nodes but @datatype is present, with an empty value. 
		elsif (not $current_element->getElementsByTagName('*'))
		{
			@current_property_value = (
				$self->_element_to_string($current_element),
				($has_datatype ? $datatype: undef),
				$current_language,
			);
		}

		# In RDFa 1.0 by default generate an XML Literal;
		# in RDFa 1.1 by default generate a plain literal.
		elsif (!$has_datatype and $current_element->getElementsByTagName('*'))
		{
			if ($self->{options}{xmllit_default})
			{
				@current_property_value = ($self->_element_to_xml($current_element, $current_language),
					RDF_XMLLIT,
					$current_language);
				$recurse = $self->{options}{xmllit_recurse};
			}
			else
			{
				@current_property_value = ($self->_element_to_string($current_element),
					undef,
					$current_language);
			}
		}

		else
		{
			die("How did we get here??\n");
		}
	}
	
	my $E = { # provenance tracking
		current   => $current_element,
		subject   => $new_subject_elem,
		predicate => $current_element,
		object    => $current_element,
		graph     => $graph_elem,
		};
	foreach my $property (@prop)
	{
		next unless defined $current_property_value[0];
		
		# The [current property value] is then used with each predicate to
		# generate a triple as follows:
		# 
		# subject
		#     [new subject] 
		# predicate
		#     full URI 
		# object
		#     [current object literal] 

		my $p = $self->_expand_curie(
			$property,
			element   => $current_element,
			attribute => 'property',
			prefixes  => $local_uri_mappings,
			terms     => $local_term_mappings,
			xml_base  => $xml_base,
			);
		next unless defined $p;
		
		if (ref $current_property_value[0] eq 'ARRAY')
		{
			if ($current_element->hasAttributeNsSafe($rdfans, 'inlist'))
			{
				$list_mappings->{$p} = [] unless defined $list_mappings->{$p};
				push @{ $list_mappings->{$p} }, [resource => $current_property_value[0][0]];
			}
			else
			{
				$self->_insert_triple_resource($E, $new_subject, $p, $current_property_value[0][0], $graph);
				$activity++;
			}
		}
		else
		{
			if ($current_element->hasAttributeNsSafe($rdfans, 'inlist'))
			{
				$list_mappings->{$p} = [] unless defined $list_mappings->{$p};
				push @{ $list_mappings->{$p} }, [literal => @current_property_value];
			}
			else
			{
				$self->_insert_triple_literal($E, $new_subject, $p, @current_property_value, $graph);
				$activity++;
			}
		}
		# Once the triple has been created, if the [datatype] of the
		# [current object literal] is rdf:XMLLiteral, then the [recurse]
		# flag is set to false.
#		$recurse = 0
#			if $datatype eq RDF_XMLLIT;
	}

#	# If the [skip element] flag is 'false', and either: the previous step
#	# resulted in a 'true' flag, or [new subject] was set to a non-null and
#	# non-bnode value, then any [incomplete triple]s within the current context
#	# should be completed:
#	if (!$skip_element && ($flag || ((defined $new_subject) && ($new_subject !~ /^bnodeXXX:/))))
#	{

	if (!$skip_element && defined $new_subject)
	{
		# Loop through list of incomplete triples...
		foreach my $it (@$incomplete_triples)
		{
			my $direction    = $it->{direction};
			my $predicate    = $it->{predicate};
			my $parent_graph = $it->{graph};

			if ($direction eq 'none' and defined $it->{list})
			{
				push @{$it->{list}}, [resource => $new_subject];
			}
			elsif ($direction eq 'forward')
			{
				my $E = { # provenance tracking
					current   => $current_element,
					subject   => $parent_subject_elem,
					predicate => $it->{predicate_element},
					object    => $new_subject_elem,
					graph     => $it->{graph_element},
					};

				$self->_insert_triple_resource($E, $parent_subject, $predicate, $new_subject, $parent_graph);
				$activity++;
			}
			elsif ($direction eq 'reverse')
			{
				my $E = { # provenance tracking
					current   => $current_element,
					subject   => $new_subject_elem,
					predicate => $it->{predicate_element},
					object    => $parent_subject_elem,
					graph     => $it->{graph_element},
					};
				
				$self->_insert_triple_resource($E, $new_subject, $predicate, $parent_subject, $parent_graph);
				$activity++;
			}
			else
			{
				die "Direction is '$direction'??";
			}
		}
	}

	# If the [recurse] flag is 'true', all elements that are children of the 
	# [current element] are processed using the rules described here, using a 
	# new [evaluation context], initialized as follows
	my $flag = 0;
	if ($recurse)
	{
		my $evaluation_context;
		
		# If the [skip element] flag is 'true' then the new [evaluation context]
		# is a copy of the current context that was passed in to this level of
		# processing, with the [language] and [list of URI mappings] values
		# replaced with the local values; 
		if ($skip_element)
		{
			$evaluation_context = {
				%$args,
				base                => $base,
				language            => $current_language,
				uri_mappings        => $uri_mappings,
				term_mappings       => $term_mappings,
				list_mappings       => $list_mappings,
#				parent_subject      => $parent_subject,
#				parent_subject_elem => $parent_subject_elem,
#				parent_object       => $parent_object,
#				parent_object_elem  => $parent_object_elem,
#				incomplete_triples  => $incomplete_triples,
				graph               => $graph,
				graph_elem          => $graph_elem,
				xml_base            => $xml_base,
				parent              => $args,
			};
		}
		
		# Otherwise, the values are: 
		else
		{
			$evaluation_context = {
				base                => $base,
				parent_subject      => $new_subject,
				parent_subject_elem => $new_subject_elem,
				parent_object       => (defined $current_object_resource ? $current_object_resource : (defined $new_subject ? $new_subject : $parent_subject)),
				parent_object_elem  => (defined $current_object_resource_elem ? $current_object_resource_elem : (defined $new_subject_elem ? $new_subject_elem : $parent_subject_elem)),
				uri_mappings        => $local_uri_mappings,
				term_mappings       => $local_term_mappings,
				incomplete_triples  => $local_incomplete_triples,
				list_mappings       => $list_mappings,
				language            => $current_language,
				graph               => $graph,
				graph_elem          => $graph_elem,
				xml_base            => $xml_base,
				parent              => $args,
			};
		}
		
		foreach my $kid ($current_element->getChildrenByTagName('*'))
		{
			$flag = $self->_consume_element($kid, $evaluation_context) || $flag;
		}
	}

	# Once all the child elements have been traversed, list triples are 
	# generated, if necessary.
	if ($list_mappings->{'::meta'}{owner} == $current_element)
	{
	foreach my $iri (keys %$list_mappings)
	{
		next if $iri eq '::meta';
		
		# For each IRI in the local list mapping, if the equivalent list does
		# not exist in the evaluation context, indicating that the list was
		# originally defined on the current element, use the list as follows:
		if ($args->{list_mappings}{$iri} == $list_mappings->{$iri}
		and ref $args->{list_mappings}{$iri} eq 'HASH'
		and %{ $args->{list_mappings}{$iri} })
		{
			next;
		}
				
		# Create a new 'bnode' array containing newly created bnodes, one for
		# each element in the list
		my @bnode = map { $self->bnode; } @{ $list_mappings->{$iri} };		
		my $first = @bnode ? $bnode[0] : undef;
		
		while (my $bnode = shift @bnode)
		{
			my $value = shift @{ $list_mappings->{$iri} };
			my $type  = shift @$value;
			
			my $E = { # provenance tracking
				current   => $current_element,
				graph     => $graph_elem,
				};
			if ($type eq 'literal')
			{
				$self->_insert_triple_literal($E, $bnode, RDF_FIRST, @$value, $graph);
			}
			else
			{
				$self->_insert_triple_resource($E, $bnode, RDF_FIRST, @$value, $graph);
			}

			if (exists $bnode[0])
			{
				$self->_insert_triple_resource($E, $bnode, RDF_REST, $bnode[0], $graph);
			}
			else
			{
				$self->_insert_triple_resource($E, $bnode, RDF_REST, RDF_NIL, $graph);
			}
		}
		
		my $E = { # provenance tracking
			current   => $current_element,
			subject   => $new_subject_elem,
			predicate => $current_element,
			graph     => $graph_elem,
		};
		
		#my ($attr, $iri) = split /:/, $iri, 2;
		my $attr = 'REL';
		
		if (defined $first)
		{
			$attr eq 'REV'
				? $self->_insert_triple_resource($E, $first, $iri, $new_subject, $graph)
				: $self->_insert_triple_resource($E, $new_subject, $iri, $first, $graph);
		}
		else
		{
			$attr eq 'REV'
				? $self->_insert_triple_resource($E, RDF_NIL, $iri, $new_subject, $graph)
				: $self->_insert_triple_resource($E, $new_subject, $iri, RDF_NIL, $graph);
		}
			
		$activity++;
	}
	}
	
	return 1 if $activity || $new_subject || $flag;
	return 0;
}

sub set_callbacks
# Set callback functions for handling RDF triples.
{
	my $self = shift;

	if ('HASH' eq ref $_[0])
	{
		$self->{'sub'} = $_[0];
		$self->{'sub'}->{'pretriple_resource'} = \&_print0
			if lc ($self->{'sub'}->{'pretriple_resource'}||'') eq 'print';
		$self->{'sub'}->{'pretriple_literal'} = \&_print1
			if lc ($self->{'sub'}->{'pretriple_literal'}||'') eq 'print';
	}
	else
	{
		die "Unsupported set_callbacks call.\n";
	}
	
	return $self;
}

sub _print0
# Prints a Turtle triple.
{
	my $self    = shift;
	my $element = shift;
	my $subject = shift;
	my $pred    = shift;
	my $object  = shift;
	my $graph   = shift;
	
	if ($graph)
	{
		print "# GRAPH $graph\n";
	}
	if ($element)
	{
		printf("# Triple on element %s.\n", $element->nodePath);
	}
	else
	{
		printf("# Triple.\n");
	}

	printf("%s %s %s .\n",
		($subject =~ /^_:/ ? $subject : "<$subject>"),
		"<$pred>",
		($object =~ /^_:/ ? $object : "<$object>"));
	
	return;
}

sub _print1
# Prints a Turtle triple.
{
	my $self    = shift;
	my $element = shift;
	my $subject = shift;
	my $pred    = shift;
	my $object  = shift;
	my $dt      = shift;
	my $lang    = shift;
	my $graph   = shift;
	
	# Clumsy, but probably works.
	$object =~ s/\\/\\\\/g;
	$object =~ s/\n/\\n/g;
	$object =~ s/\r/\\r/g;
	$object =~ s/\t/\\t/g;
	$object =~ s/\"/\\\"/g;
	
	if ($graph)
	{
		print "# GRAPH $graph\n";
	}
	if ($element)
	{
		printf("# Triple on element %s.\n", $element->nodePath);
	}
	else
	{
		printf("# Triple.\n");
	}

	printf("%s %s %s%s%s .\n",
		($subject =~ /^_:/ ? $subject : "<$subject>"),
		"<$pred>",
		"\"$object\"",
		(length $dt ? "^^<$dt>" : ''),
		((length $lang && !length $dt) ? "\@$lang" : '')
		);
	
	return;
}

sub element_subjects
{
	my ($self) = shift;
	$self->consume;
	$self->{element_subjects} = shift if @_;
	return $self->{element_subjects};
}

sub _insert_triple_resource
{
	my $self = shift;

	my $element   = shift;  # A reference to the XML::LibXML element being parsed
	my $subject   = shift;  # Subject URI or bnode
	my $predicate = shift;  # Predicate URI
	my $object    = shift;  # Resource URI or bnode
	my $graph     = shift;  # Graph URI or bnode (if named graphs feature is enabled)

	my $suppress_triple = 0;
	$suppress_triple = $self->{'sub'}->{'pretriple_resource'}(
		$self,
		ref $element ? $element->{current} : undef,
		$subject,
		$predicate,
		$object,
		$graph,
		)
		if defined $self->{'sub'}->{'pretriple_resource'};
	return if $suppress_triple;
	
	# First make sure the object node type is ok.
	my $to;
	if ($object =~ m/^_:(.*)/)
	{
		$to = RDF::Trine::Node::Blank->new($1);
	}
	else
	{
		$to = RDF::Trine::Node::Resource->new($object);
	}

	# Run the common function
	return $self->_insert_triple_common($element, $subject, $predicate, $to, $graph);
}

sub _insert_triple_literal
{
	my $self = shift;

	my $element   = shift;  # A reference to the XML::LibXML element being parsed
	my $subject   = shift;  # Subject URI or bnode
	my $predicate = shift;  # Predicate URI
	my $object    = shift;  # Resource Literal
	my $datatype  = shift;  # Datatype URI (possibly undef or '')
	my $language  = shift;  # Language (possibly undef or '')
	my $graph     = shift;  # Graph URI or bnode (if named graphs feature is enabled)

	my $suppress_triple = 0;
	$suppress_triple = $self->{'sub'}->{'pretriple_literal'}(
		$self,
		ref $element ? $element->{current} : undef,
		$subject,
		$predicate,
		$object,
		$datatype,
		$language,
		$graph,
		)
		if defined $self->{'sub'}->{'pretriple_literal'};
	return if $suppress_triple;

	# Now we know there's a literal
	my $to;
	
	# Work around bad Unicode handling in RDF::Trine.
	# $object = encode_utf8($object);

	if (defined $datatype)
	{
		if ($datatype eq RDF_XMLLIT)
		{
			if ($self->{options}{use_rtnlx})
			{
				eval
				{
					require RDF::Trine::Node::Literal::XML;
					$to = RDF::Trine::Node::Literal::XML->new($element->childNodes);
				};
			}
			
			if ( $@ || !defined $to)
			{
				my $orig = $RDF::Trine::Node::Literal::USE_XMLLITERALS;
				$RDF::Trine::Node::Literal::USE_XMLLITERALS = 0;
				$to = RDF::Trine::Node::Literal->new($object, undef, $datatype);
				$RDF::Trine::Node::Literal::USE_XMLLITERALS = $orig;
			}
		}
		else
		{
			$to = RDF::Trine::Node::Literal->new($object, undef, $datatype);
		}
	}
	else
	{
		$to = RDF::Trine::Node::Literal->new($object, $language, undef);
	}

	# Run the common function
	$self->_insert_triple_common($element, $subject, $predicate, $to, $graph);
}

sub _insert_triple_common
{
	my $self      = shift;  # A reference to the RDF::RDFa::Parser object
	my $element   = shift;  # A reference to the XML::LibXML element being parsed
	my $subject   = shift;  # Subject URI or bnode
	my $predicate = shift;  # Predicate URI
	my $to        = shift;  # RDF::Trine::Node Resource URI or bnode
	my $graph     = shift;  # Graph URI or bnode (if named graphs feature is enabled)

	# First, make sure subject and predicates are the right kind of nodes
	my $tp = RDF::Trine::Node::Resource->new($predicate);
	my $ts;
	if ($subject =~ m/^_:(.*)/)
	{
		$ts = RDF::Trine::Node::Blank->new($1);
	}
	else
	{
		$ts = RDF::Trine::Node::Resource->new($subject);
	}

	my $statement;

	# If we are configured for it, and graph name can be found, add it.
	if ($self->{'options'}->{'graph'} && $graph)
	{
		$self->{Graphs}->{$graph}++;
		
		my $tg;
		if ($graph =~ m/^_:(.*)/)
		{
			$tg = RDF::Trine::Node::Blank->new($1);
		}
		else
		{
			$tg = RDF::Trine::Node::Resource->new($graph);
		}

		$statement = RDF::Trine::Statement::Quad->new($ts, $tp, $to, $tg);
	}
	# If no graph name, just add triples
	else
	{
		$statement = RDF::Trine::Statement->new($ts, $tp, $to);
	}

	my $suppress_triple = 0;
	$suppress_triple = $self->{'sub'}->{'ontriple'}($self, $element, $statement)
		if ($self->{'sub'}->{'ontriple'});
	return if $suppress_triple;

	$self->{model}->add_statement($statement);
}

sub _atom_magic
{
	my $self    = shift;
	my $element = shift;
	
	return $self->bnode($element, 1);
}

# Splits things like property="foaf:name rdfs:label"
sub _split_tokens
{
	my ($self, $string) = @_;
	$string ||= '';
	$string =~ s/(^\s+|\s+$)//g;
	my @return = split /\s+/, $string;
	return @return;
}

sub _element_to_bookmarked_string
{
	my ($self, $bookmark) = @_;

	my @name_attribute;
	if ($self->{'options'}->{'bookmark_name'} =~ /^\{(.*)\}(.+)$/)
	{
		@name_attribute = $1 ? ($1, $2) : (undef, $2);
	}
	else
	{
		@name_attribute = (undef, $self->{'options'}->{'bookmark_name'});
	}
	
	my ($endtag_namespace, $endtag_localname);
	if ($self->{'options'}->{'bookmark_end'} =~ /^\{(.*)\}(.+)$/)
	{
		($endtag_namespace, $endtag_localname) = $1 ? ($1, $2) : (undef, $2);
	}
	else
	{
		($endtag_namespace, $endtag_localname) = (undef, $self->{'options'}->{'bookmark_end'});
	}

	my $string = '';
	my $current = $bookmark;
	while ($current)
	{
		$current = $self->_find_next_node($current);
		
		if (defined $current
		&& $current->nodeType == XML_TEXT_NODE)
		{
			$string .= $current->getData;
		}
		if (defined $current
		&& $current->nodeType == XML_ELEMENT_NODE
		&& $current->localname eq $endtag_localname
		&& $current->namespaceURI eq $endtag_namespace
		&& $current->getAttributeNsSafe(@name_attribute) eq $bookmark->getAttributeNsSafe(@name_attribute))
		{
			$current = undef;
		}
	}
	
	return $string;
}

sub _find_next_node
{
	my ($self, $node) = @_;
	
	if ($node->nodeType == XML_ELEMENT_NODE)
	{
		my @kids = $node->childNodes;
		return $kids[0] if @kids;
	}
	
	my $ancestor = $node;
	while ($ancestor)
	{
		return $ancestor->nextSibling if $ancestor->nextSibling;
		$ancestor = $ancestor->parentNode;
	}
	
	return undef;
}

sub _element_to_string
{
	my $self = shift;
	my $dom  = shift;
	
	if ($dom->nodeType == XML_TEXT_NODE)
	{
		return $dom->getData;
	}
	elsif ($dom->nodeType == XML_ELEMENT_NODE)
	{
		my $rv = '';
		foreach my $kid ($dom->childNodes)
			{ $rv .= $self->_element_to_string($kid); }
		return $rv;
	}

	return '';
}

sub _element_to_xml
{
	my $self = shift;
	my $dom  = shift;
	my $lang = shift;
	my $rv;
	
	foreach my $kid ($dom->childNodes)
	{
		my $fakelang = 0;
		if (($kid->nodeType == XML_ELEMENT_NODE) && defined $lang)
		{
			unless ($kid->hasAttributeNS(XML_XML_NS, 'lang'))
			{
				$kid->setAttributeNS(XML_XML_NS, 'lang', $lang);
				$fakelang++;
			}
		}
		
		$rv .= $kid->toStringEC14N(1);
		
		if ($fakelang)
		{
			$kid->removeAttributeNS(XML_XML_NS, 'lang');
		}
	}
	
	return $rv;
}

sub bnode
{
	my $self    = shift;
	my $element = shift;
	my $save_me = shift || 0;
	my $ident   = shift || undef;
	
	if (defined $element
	and $self->{'saved_bnodes'}->{ $element->nodePath })
	{
		return $self->{'saved_bnodes'}->{ $element->nodePath };
	}

	elsif (defined $ident
	and $self->{'saved_bnodes'}->{ $ident })
	{
		return $self->{'saved_bnodes'}->{ $ident };
	}

	return sprintf('http://thing-described-by.org/?%s#%s',
		$self->uri,
		$self->{element}->getAttribute('id'))
		if ($self->{options}->{tdb_service} && $element && length $element->getAttribute('id'));

	unless (defined $self->{bnode_prefix})
	{
		$self->{bnode_prefix} = Data::UUID->new->create_str;
		$self->{bnode_prefix} =~ s/-//g;
	}

	my $rv;
	if ($self->{options}->{skolemize})
	{
		$rv = sprintf('tag:buzzword.org.uk,2010:RDF-RDFa-Parser:skolem:%s:%04d', $self->{bnode_prefix}, $self->{bnodes}++);
	}
	else
	{
		$rv = sprintf('_:rdfa%snode%04d', $self->{bnode_prefix}, $self->{bnodes}++);
	}
	
	if ($save_me and defined $element)
	{
		$self->{'saved_bnodes'}->{ $element->nodePath } = $rv;
	}

	if (defined $ident)
	{
		$self->{'saved_bnodes'}->{ $ident } = $rv;
	}

	return $rv;
}

sub _valid_lang
{
	my ($self, $value_to_test) = @_;

	return 1 if (defined $value_to_test) && ($value_to_test eq '');
	return 0 unless defined $value_to_test;
	
	# Regex for recognizing RFC 4646 well-formed tags
	# http://www.rfc-editor.org/rfc/rfc4646.txt
	# http://tools.ietf.org/html/draft-ietf-ltru-4646bis-21

	# The structure requires no forward references, so it reverses the order.
	# It uses Java/Perl syntax instead of the old ABNF
	# The uppercase comments are fragments copied from RFC 4646

	# Note: the tool requires that any real "=" or "#" or ";" in the regex be escaped.

	my $alpha      = '[a-z]';      # ALPHA
	my $digit      = '[0-9]';      # DIGIT
	my $alphanum   = '[a-z0-9]';   # ALPHA / DIGIT
	my $x          = 'x';          # private use singleton
	my $singleton  = '[a-wyz]';    # other singleton
	my $s          = '[_-]';       # separator -- lenient parsers will use [_-] -- strict will use [-]

	# Now do the components. The structure is slightly different to allow for capturing the right components.
	# The notation (?:....) is a non-capturing version of (...): so the "?:" can be deleted if someone doesn't care about capturing.

	my $language   = '([a-z]{2,8}) | ([a-z]{2,3} $s [a-z]{3})';
	
	# ABNF (2*3ALPHA) / 4ALPHA / 5*8ALPHA  --- note: because of how | works in regex, don't use $alpha{2,3} | $alpha{4,8} 
	# We don't have to have the general case of extlang, because there can be only one extlang (except for zh-min-nan).

	# Note: extlang invalid in Unicode language tags

	my $script = '[a-z]{4}' ;   # 4ALPHA 

	my $region = '(?: [a-z]{2}|[0-9]{3})' ;    # 2ALPHA / 3DIGIT

	my $variant    = '(?: [a-z0-9]{5,8} | [0-9] [a-z0-9]{3} )' ;  # 5*8alphanum / (DIGIT 3alphanum)

	my $extension  = '(?: [a-wyz] (?: [_-] [a-z0-9]{2,8} )+ )' ; # singleton 1*("-" (2*8alphanum))

	my $privateUse = '(?: x (?: [_-] [a-z0-9]{1,8} )+ )' ; # "x" 1*("-" (1*8alphanum))

	# Define certain grandfathered codes, since otherwise the regex is pretty useless.
	# Since these are limited, this is safe even later changes to the registry --
	# the only oddity is that it might change the type of the tag, and thus
	# the results from the capturing groups.
	# http://www.iana.org/assignments/language-subtag-registry
	# Note that these have to be compared case insensitively, requiring (?i) below.

	my $grandfathered  = '(?:
			  (en [_-] GB [_-] oed)
			| (i [_-] (?: ami | bnn | default | enochian | hak | klingon | lux | mingo | navajo | pwn | tao | tay | tsu ))
			| (no [_-] (?: bok | nyn ))
			| (sgn [_-] (?: BE [_-] (?: fr | nl) | CH [_-] de ))
			| (zh [_-] min [_-] nan)
			)';

	# old:         | zh $s (?: cmn (?: $s Hans | $s Hant )? | gan | min (?: $s nan)? | wuu | yue );
	# For well-formedness, we don't need the ones that would otherwise pass.
	# For validity, they need to be checked.

	# $grandfatheredWellFormed = (?:
	#         art $s lojban
	#     | cel $s gaulish
	#     | zh $s (?: guoyu | hakka | xiang )
	# );

	# Unicode locales: but we are shifting to a compatible form
	# $keyvalue = (?: $alphanum+ \= $alphanum+);
	# $keywords = ($keyvalue (?: \; $keyvalue)*);

	# We separate items that we want to capture as a single group

	my $variantList   = $variant . '(?:' . $s . $variant . ')*' ;     # special for multiples
	my $extensionList = $extension . '(?:' . $s . $extension . ')*' ; # special for multiples

	my $langtag = "
			($language)
			($s ( $script ) )?
			($s ( $region ) )?
			($s ( $variantList ) )?
			($s ( $extensionList ) )?
			($s ( $privateUse ) )?
			";

	# Here is the final breakdown, with capturing groups for each of these components
	# The variants, extensions, grandfathered, and private-use may have interior '-'
	
	my $r = ($value_to_test =~ 
		/^(
			($langtag)
		 | ($privateUse)
		 | ($grandfathered)
		 )$/xi);
	return $r;
}

sub _expand_curie
{
	my ($self, $token, %args) = @_;	
	my $r = $self->__expand_curie($token, %args);
	
	if (defined $self->{'sub'}->{'ontoken'})
	{
		return $self->{'sub'}->{'ontoken'}($self, $args{element}, $token, $r);
	}

	return $r;
}

sub __expand_curie
{
	my ($self, $token, %args) = @_;

	# Blank nodes
	{
		my $bnode;
		if ($token eq '_:' || $token eq '[_:]')
			{ $bnode = $self->bnode(undef, undef, '_:'); }
		elsif ($token =~ /^_:(.+)$/i || $token =~ /^\[_:(.+)\]$/i)
			{ $bnode = $self->bnode(undef, undef, '_:'.$1); }
		
		if (defined $bnode)
		{
			if ($args{'attribute'} =~ /^(rel|rev|property|datatype)$/i)
			{
				$self->_log_error(
					ERR_ERROR,
					ERR_CODE_BNODE_WRONGPLACE,
					"Blank node found in $args{attribute} where URIs are expected as values.",
					token     => $token,
					element   => $args{element},
					attribute => $args{attribute},
					);
				
				return $1 if $token =~ /^\[_:(.+)\]$/i;
				return $token;
			}

			return $bnode;
		}
	}
	
	my $is_safe = 0;
	if ($token =~ /^\[(.*)\]$/)
	{
		$is_safe = 1;
		$token   = $1;
	}
	
	# CURIEs - default vocab
	if ($token =~ /^($XML::RegExp::NCName)$/
	and ($is_safe || $args{'attribute'} =~ /^(rel|rev|property|typeof|datatype|role)$/i || $args{'allow_unsafe_default_vocab'}))
	{
		my $suffix = $token;
		
		if ($args{'attribute'} eq 'role')
			{ return 'http://www.w3.org/1999/xhtml/vocab#' . $suffix; }
		elsif (defined $args{'prefixes'}{'(VOCAB)'})
			{ return $args{'prefixes'}{'(VOCAB)'} . $suffix; }
	
		return undef if $is_safe;
	}

	
	# Keywords / terms / whatever-they're-called
	if ($token =~ /^($XML::RegExp::NCName)$/
	and ($is_safe || $args{'attribute'} =~ /^(rel|rev|property|typeof|datatype|role)$/i || $args{'allow_unsafe_term'}))
	{
		my $terms = $args{'terms'};
		my $attr  = $args{'attribute'};
		
		return $terms->{'sensitive'}{$attr}{$token}
			if defined $terms->{'sensitive'}{ $attr }{$token};
			
		return $terms->{'sensitive'}{'*'}{$token}
			if defined $terms->{'sensitive'}{'*'}{$token};
			
		return $terms->{'insensitive'}{$attr}{lc $token}
			if defined $terms->{'insensitive'}{$attr}{lc $token};
			
		return $terms->{'insensitive'}{'*'}{lc $token}
			if defined $terms->{'insensitive'}{'*'}{lc $token};
	}

	# CURIEs - prefixed
	if ($token =~ /^($XML::RegExp::NCName)?:(\S*)$/
	and (
		$is_safe
		or $args{attribute} =~ /^(rel|rev|property|typeof|datatype|role)$/i
		or $self->{options}{safe_optional}
	))
	{
		$token =~ /^($XML::RegExp::NCName)?:(\S*)$/;
		my $prefix = (defined $1 && length $1) ? $1 : '(DEFAULT PREFIX)';
		my $suffix = $2;
		
		if (defined $args{'prefixes'}{'(DEFAULT PREFIX)'} && $prefix eq '(DEFAULT PREFIX)')
			{ return $args{'prefixes'}{'(DEFAULT PREFIX)'} . $suffix; }
		elsif (defined $args{'prefixes'}{'sensitive'}{$prefix})
			{ return $args{'prefixes'}{'sensitive'}{$prefix} . $suffix; }
		elsif (defined $args{'prefixes'}{'insensitive'}{lc $prefix})
			{ return $args{'prefixes'}{'insensitive'}{lc $prefix} . $suffix; }

		if ($is_safe)
		{
			$prefix = ($prefix eq '(DEFAULT PREFIX)') ? '' : $prefix;
			$self->_log_error(
				ERR_WARNING,
				ERR_CODE_CURIE_UNDEFINED,
				"CURIE '$token' used in safe CURIE, but '$prefix' is undefined.",
				token     => $token,
				element   => $args{element},
				attribute => $args{attribute},
				prefix    => $prefix,
				);
			return undef;
		}
	}

	# CURIEs - bare prefixes
	if ($self->{options}{prefix_bare}
	and $token =~ /^($XML::RegExp::NCName)$/
	and (
		$is_safe
		or $args{attribute} =~ /^(rel|rev|property|typeof|datatype|role)$/i
		or $self->{options}{safe_optional}
	))
	{
		my $prefix = $token;
		my $suffix = '';
		
		if (defined $args{'prefixes'}{'sensitive'}{$prefix})
			{ return $args{'prefixes'}{'sensitive'}{$prefix} . $suffix; }
		elsif (defined $args{'prefixes'}{'insensitive'}{lc $prefix})
			{ return $args{'prefixes'}{'insensitive'}{lc $prefix} . $suffix; }
	}

	# Absolute URIs
	if ($token =~ /^[A-Z][A-Z0-9\.\+-]*:/i and !$is_safe
	and ($self->{'options'}{'full_uris'} || $args{'attribute'} =~ /^(about|resource|graph)$/i))
	{
		return $token;
	}

	# Relative URIs
	if (!$is_safe and ($args{'attribute'} =~ /^(about|resource|graph)$/i || $args{'allow_relative'}))
	{
		return $self->uri($token, {'element'=>$args{'element'}, 'xml_base'=>$args{'xml_base'}});
	}
	
	$self->_log_error(
		ERR_WARNING,
		ERR_CODE_CURIE_FELLTHROUGH,
		"Couldn't make sense of token '$token'.",
		token     => $token,
		element   => $args{element},
		attribute => $args{attribute},
		);

	return undef;
}

__PACKAGE__
__END__

=head1 NAME

RDF::RDFa::Parser - flexible RDFa parser

=head1 SYNOPSIS

If you're wanting to work with an RDF::Trine::Model that can be queried with SPARQL, etc:

 use RDF::RDFa::Parser;
 my $url     = 'http://example.com/document.html';
 my $options = RDF::RDFa::Parser::Config->new('xhtml', '1.1');
 my $rdfa    = RDF::RDFa::Parser->new_from_url($url, $options);
 my $model   = $rdfa->graph;

For dealing with local data:

 use RDF::RDFa::Parser;
 my $base_url = 'http://example.com/document.html';
 my $options  = RDF::RDFa::Parser::Config->new('xhtml', '1.1');
 my $rdfa     = RDF::RDFa::Parser->new($markup, $base_url, $options);
 my $model    = $rdfa->graph;

A simple set of operations for working with Open Graph Protocol data:

 use RDF::RDFa::Parser;
 my $url     = 'http://www.rottentomatoes.com/m/net/';
 my $options = RDF::RDFa::Parser::Config->tagsoup;
 my $rdfa    = RDF::RDFa::Parser->new_from_url($url, $options);
 print $rdfa->opengraph('title') . "\n";
 print $rdfa->opengraph('image') . "\n";

=head1 DESCRIPTION

L<RDF::TrineX::Parser::RDFa> provides a saner interface for this module.
If you are new to parsing RDFa with Perl, then that's the best place to
start.

=head2 Forthcoming API Changes

Some of the logic regarding host language and RDFa version guessing
is likely to be removed from RDF::RDFa::Parser and
RDF::RDFa::Parser::Config, and shifted into RDF::TrineX::Parser::RDFa
instead.

=head2 Constructors

=over 4

=item C<< $p = RDF::RDFa::Parser->new($markup, $base, [$config], [$storage]) >>

This method creates a new RDF::RDFa::Parser object and returns it.

The $markup variable may contain an XHTML/XML string, or a
XML::LibXML::Document. If a string, the document is parsed using
XML::LibXML::Parser or HTML::HTML5::Parser, depending on the
configuration in $config. XML well-formedness errors will cause the
function to die.

$base is a URL used to resolve relative links found in the document.

$config optionally holds an RDF::RDFa::Parser::Config object which
determines the set of rules used to parse the RDFa. It defaults to
XHTML+RDFa 1.1.

B<Advanced usage note:> $storage optionally holds an RDF::Trine::Store
object. If undef, then a new temporary store is created.

=item C<< $p = RDF::RDFa::Parser->new_from_url($url, [$config], [$storage]) >>

=item C<< $p = RDF::RDFa::Parser->new_from_uri($url, [$config], [$storage]) >>

$url is a URL to fetch and parse, or an HTTP::Response object.

$config optionally holds an RDF::RDFa::Parser::Config object which
determines the set of rules used to parse the RDFa. The default is
to determine the configuration by looking at the HTTP response
Content-Type header; it's probably sensible to keep the default.

$storage optionally holds an RDF::Trine::Store object. If undef, then
a new temporary store is created.

This function can also be called as C<new_from_url> or C<new_from_uri>.
Same thing.

=item C<< $p = RDF::RDFa::Parser->new_from_response($response, [$config], [$storage]) >>

$response is an C<HTTP::Response> object.

Otherwise the same as C<new_from_url>. 

=back

=head2 Public Methods

=over 4

=item C<< $p->graph  >>

This will return an RDF::Trine::Model containing all the RDFa
data found on the page.

B<Advanced usage note:> If passed a graph URI as a parameter,
will return a single named graph from within the page. This
feature is only useful if you're using named graphs.

=item C<< $p->graphs >>

B<Advanced usage only.>

Will return a hashref of all named graphs, where the graph name is a
key and the value is a RDF::Trine::Model tied to a temporary storage.

This method is only useful if you're using named graphs.

=item C<< $p->opengraph([$property])  >>

If $property is provided, will return the value or list of values (if
called in list context) for that Open Graph Protocol property. (In pure
RDF terms, it returns the non-bnode objects of triples where the
subject is the document base URI; and the predicate is $property,
with non-URI $property strings taken as having the implicit prefix
'http://ogp.me/ns#'. There is no distinction between literal and
non-literal values; literal datatypes and languages are dropped.)

If $property is omitted, returns a list of possible properties.

Example:

  foreach my $property (sort $p->opengraph)
  {
    print "$property :\n";
    foreach my $val (sort $p->opengraph($property))
    {
      print "  * $val\n";
    }
  }

See also: L<http://opengraphprotocol.org/>.

=item C<< $p->dom >>

Returns the parsed XML::LibXML::Document.

=item C<< $p->uri( [$other_uri] ) >>

Returns the base URI of the document being parsed. This will usually be the
same as the base URI provided to the constructor, but may differ if the
document contains a <base> HTML element.

Optionally it may be passed a parameter - an absolute or relative URI - in
which case it returns the same URI which it was passed as a parameter, but
as an absolute URI, resolved relative to the document's base URI.

This seems like two unrelated functions, but if you consider the consequence
of passing a relative URI consisting of a zero-length string, it in fact makes
sense.

=item C<< $p->errors >>

Returns a list of errors and warnings that occurred during parsing.

=item C<< $p->processor_graph >>

As per C<< $p->errors >> but returns data as an RDF model.

=item C<< $p->output_graph >>

An alias for C<graph>, but does not accept a parameter.

=item C<< $p->processor_and_output_graph >>

Union of the above two graphs.

=item C<< $p->consume >>

B<Advanced usage only.>

The document is parsed for RDFa. As of RDF::RDFa::Parser 1.09x,
this is called automatically when needed; you probably don't need
to touch it unless you're doing interesting things with callbacks.

Calling C<< $p->consume(survive => 1) >> will avoid crashing (e.g.
when the markup provided cannot be parsed), and instead make more
errors available in C<< $p->errors >>.

=item C<< $p->set_callbacks(\%callbacks) >>

B<Advanced usage only.>

Set callback functions for the parser to call on certain events. These are only necessary if
you want to do something especially unusual.

  $p->set_callbacks({
    'pretriple_resource' => sub { ... } ,
    'pretriple_literal'  => sub { ... } ,
    'ontriple'           => undef ,
    'onprefix'           => \&some_function ,
    });

Either of the two pretriple callbacks can be set to the string 'print' instead of a coderef.
This enables built-in callbacks for printing Turtle to STDOUT.

For details of the callback functions, see the section CALLBACKS. If used, C<set_callbacks>
must be called I<before> C<consume>. C<set_callbacks> returns a reference to the parser
object itself.

=item C<< $p->element_subjects >>

B<Advanced usage only.>

Gets/sets a hashref of { xpath => RDF::Trine::Node } mappings.

This is not touched during normal RDFa parsing, only being used by the @role and
@cite features where RDF resources (i.e. URIs and blank nodes) are needed to
represent XML elements themselves.

=back

=head1 CALLBACKS

Several callback functions are provided. These may be set using the C<set_callbacks> function,
which takes a hashref of keys pointing to coderefs. The keys are named for the event to fire the
callback on.

=head2 ontriple

This is called once a triple is ready to be added to the graph. (After the pretriple
callbacks.) The parameters passed to the callback function are:

=over 4

=item * A reference to the C<RDF::RDFa::Parser> object

=item * A hashref of relevant C<XML::LibXML::Element> objects (subject, predicate, object, graph, current)

=item * An RDF::Trine::Statement object.

=back

The callback should return 1 to tell the parser to skip this triple (not add it to
the graph); return 0 otherwise. The callback may modify the RDF::Trine::Statement
object.

=head2 onprefix

This is called when a new CURIE prefix is discovered. The parameters passed
to the callback function are:

=over 4

=item * A reference to the C<RDF::RDFa::Parser> object

=item * A reference to the C<XML::LibXML::Element> being parsed

=item * The prefix (string, e.g. "foaf")

=item * The expanded URI (string, e.g. "http://xmlns.com/foaf/0.1/")

=back

The return value of this callback is currently ignored, but you should return
0 in case future versions of this module assign significance to the return value.

=head2 ontoken

This is called when a CURIE or term has been expanded. The parameters are:

=over 4

=item * A reference to the C<RDF::RDFa::Parser> object

=item * A reference to the C<XML::LibXML::Element> being parsed

=item * The CURIE or token as a string (e.g. "foaf:name" or "Stylesheet")

=item * The fully expanded URI

=back

The callback function must return a fully expanded URI, or if it
wants the CURIE to be ignored, undef.

=head2 onerror

This is called when an error occurs:

=over 4

=item * A reference to the C<RDF::RDFa::Parser> object

=item * The error level (RDF::RDFa::Parser::ERR_ERROR or
RDF::RDFa::Parser::ERR_WARNING)

=item * An error code

=item * An error message

=item * A hash of other information

=back

The return value of this callback is currently ignored, but you should return
0 in case future versions of this module assign significance to the return value.

If you do not define an onerror callback, then errors will be output via STDERR
and warnings will be silent. Either way, you can retrieve errors after parsing
using the C<errors> method.

=head2 pretriple_resource

B<This callback is deprecated - use ontriple instead.>

This is called when a triple has been found, but before preparing the triple for
adding to the model. It is only called for triples with a non-literal object value.

The parameters passed to the callback function are:

=over 4

=item * A reference to the C<RDF::RDFa::Parser> object

=item * A reference to the C<XML::LibXML::Element> being parsed

=item * Subject URI or bnode (string)

=item * Predicate URI (string)

=item * Object URI or bnode (string)

=item * Graph URI or bnode (string or undef)

=back

The callback should return 1 to tell the parser to skip this triple (not add it to
the graph); return 0 otherwise.

=head2 pretriple_literal

B<This callback is deprecated - use ontriple instead.>

This is the equivalent of pretriple_resource, but is only called for triples with a
literal object value.

The parameters passed to the callback function are:

=over 4

=item * A reference to the C<RDF::RDFa::Parser> object

=item * A reference to the C<XML::LibXML::Element> being parsed

=item * Subject URI or bnode (string)

=item * Predicate URI (string)

=item * Object literal (string)

=item * Datatype URI (string or undef)

=item * Language (string or undef)

=item * Graph URI or bnode (string or undef)

=back

Beware: sometimes both a datatype I<and> a language will be passed. 
This goes beyond the normal RDF data model.)

The callback should return 1 to tell the parser to skip this triple (not add it to
the graph); return 0 otherwise.

=head1 FEATURES

Most features are configurable using L<RDF::RDFa::Parser::Config>.

=head2 RDFa Versions

RDF::RDFa::Parser supports RDFa versions 1.0 and 1.1.

1.1 is currently a moving target; support is experimental.

1.1 is the default, but this can be configured using RDF::RDFa::Parser::Config.

=head2 Host Languages

RDF::RDFa::Parser supports various different RDFa host languages:

=over 4

=item * B<XHTML>

As per the XHTML+RDFa 1.0 and XHTML+RDFa 1.1 specifications.

=item * B<HTML 4>

Uses an HTML5 (sic) parser; uses @lang instead of @xml:lang; keeps prefixes
and terms case-insensitive; recognises the @rel relations defined in the HTML
4 specification. Otherwise the same as XHTML.

=item * B<HTML5>

Uses an HTML5 parser; uses @lang as well as @xml:lang; keeps prefixes
and terms case-insensitive; recognises the @rel relations defined in the HTML5
draft specification. Otherwise the same as XHTML.

=item * B<XML>

This is implemented as per the RDFa Core 1.1 specification. There is also
support for "RDFa Core 1.0", for which no specification exists, but has been
reverse-engineered by applying the differences between XHTML+RDFa 1.1 and
RDFa Core 1.1 to the XHTML+RDFa 1.0 specification.

Embedded chunks of RDF/XML within XML are supported.

=item * B<SVG>

For now, a synonym for XML.

=item * B<Atom>

The E<lt>feedE<gt> and E<lt>entryE<gt> elements are treated specially, setting
a new subject; IANA-registered rel keywords are recognised.

By passing C<< atom_parser=>1 >> as a Config option, you can also handle
Atom's native semantics. (Uses L<XML::Atom::OWL>. If this module is not installed,
this option is silently ignored.)

Otherwise, the same as XML.

=item * B<DataRSS>

Defines some default prefixes. Otherwise, the same as Atom.

=item * B<OpenDocument XML>

That is, XML content formatted along the lines of 'content.xml' in OpenDocument
files.

Supports OpenDocument bookmarked ranges used as typed or plain object literals
(though not XML literals); expects RDFa attributes in the XHTML namespace
instead of in no namespace. Otherwise, the same as XML.

=item * B<OpenDocument>

That is, a ZIP file containing OpenDocument XML files. RDF::RDFa::Parser
will do all the unzipping and combining for you, so you don't have to.
The unregistered "jar:" URI scheme is used to refer to files within the ZIP.

=back

=head2 Embedded RDF/XML

Though a rarely used feature, XHTML allows other XML markup languages
to be directly embedded into it. In particular, chunks of RDF/XML can
be included in XHTML. While this is not common in XHTML, it's seen quite
often in SVG and other XML markup languages.

When RDF::RDFa::Parser encounters a chunk of RDF/XML in a document
it's parsing (i.e. an element called 'RDF' with namespace
'http://www.w3.org/1999/02/22-rdf-syntax-ns#'), there are three different
courses of action it can take:

=over 4

=item 0. Continue straight through it.

This is the behaviour that XHTML+RDFa seems to suggest is the right
option. It should mostly not do any harm: triples encoded in RDF/XML
will be generally ignored (though the chunk itself could theoretically
end up as part of an XML literal). It will waste a bit of time though.

=item 1. Parse the RDF/XML.

The parser will parse the RDF/XML properly. If named graphs are
enabled, any triples will be added to a separate graph. This is
the behaviour that SVG Tiny 1.2 seems to suggest is the correct
thing to do.

=item 2. Skip the chunk.

This will skip over the RDF element entirely, and thus save you a
bit of time.

=back

You can decide which path to take by setting the 'embedded_rdfxml'
Config option. For HTML and XHTML, you probably want
to set embedded_rdfxml to '0' (the default) or '2' (a little faster).
For other XML markup languages (e.g. SVG or Atom), then you probably want to
set it to '1'.

(There's also an option '3' which controls how embedded RDF/XML interacts
with named graphs, but this is only really intended for internal use, parsing
OpenDocument.)

=head2 Named Graphs

The parser has support for named graphs within a single RDFa
document. To switch this on, use the 'graph' Config option.

See also L<http://buzzword.org.uk/2009/rdfa4/spec>.

The name of the attribute which indicates graph URIs is by
default 'graph', but can be changed using the 'graph_attr'
Config option. This option accepts Clark Notation to specify a
namespaced attribute. By default, the attribute value is
interpreted as like the 'about' attribute (i.e. CURIEs, URIs, etc),
but if you set the 'graph_type' Config option to 'id',
it will be treated as setting a fragment identifier (like the 'id'
attribute).

The 'graph_default' Config option allows you to set the default
graph URI/bnode identifier.

Once you're using named graphs, the C<graphs> method becomes
useful: it returns a hashref of { graph_uri => trine_model } pairs.
The optional parameter to the C<graph> method also becomes useful.

OpenDocument (ZIP) host language support makes internal use
of named graphs, so if you're parsing OpenDocument, tinker with
the graph Config options at your own risk!

=head2 Auto Config

RDF::RDFa::Parser has a lot of different Config options to play with. Sometimes it
might be useful to allow the page being parsed to control some of these options.
If you switch on the 'auto_config' Config option, pages can do this.

A page can set options using a specially crafted E<lt>metaE<gt> tag:

  <meta name="http://search.cpan.org/dist/RDF-RDFa-Parser/#auto_config"
     content="xhtml_lang=1&amp;xml_lang=0" />

Note that the C<content> attribute is an application/x-www-form-urlencoded
string (which must then be HTML-escaped of course). Semicolons may be used
instead of ampersands, as these tend to look nicer:

  <meta name="http://search.cpan.org/dist/RDF-RDFa-Parser/#auto_config"
     content="xhtml_lang=1;xml_lang=0" />

It's possible to use auto config outside XHTML (e.g. in Atom or
SVG) using namespaces:

  <xhtml:meta xmlns:xhtml="http://www.w3.org/1999/xhtml"
     name="http://search.cpan.org/dist/RDF-RDFa-Parser/#auto_config"
     content="xhtml_lang=0;xml_base=2;atom_elements=1" />

Any Config option may be given using auto config, except 'use_rtnlx', 'dom_parser',
and of course 'auto_config' itself. 

=head2 Profiles

Support for Profiles (an experimental RDFa 1.1 feature) was added in
version 1.09_00, but dropped after version 1.096, because the feature
was removed from draft specs.

=head1 BUGS

RDF::RDFa::Parser 0.21 passed all approved tests in the XHTML+RDFa
test suite at the time of its release.

RDF::RDFa::Parser 0.22 (used in conjunction with HTML::HTML5::Parser
0.01 and HTML::HTML5::Sanity 0.01) additionally passes all approved
tests in the HTML4+RDFa and HTML5+RDFa test suites at the time of
its release; except test cases 0113 and 0121, which the author of
this module believes mandate incorrect HTML parsing.

RDF::RDFa::Parser 1.096_01 passes all approved tests on the default
graph (not the processor graph) in the RDFa 1.1 test suite for language
versions 1.0 and host languages xhtml1, html4 and html5, with the
following exceptions which are skipped:

=over

=item * B<0140> - wilful violation, pending proof that the test is backed up by the spec.

=item * B<0198> - an XML canonicalisation test that may be dropped in the future.

=item * B<0212> - wilful violation, as passing this test would require regressing on the old RDFa 1.0 test suite.

=item * B<0251> to B<0256> pass with RDFa 1.1 and are skipped in RDFa 1.0 because they use RDFa-1.1-specific syntax.

=item * B<0256> is additionally skipped in HTML4 mode, as the author believes xml:lang should be ignored in HTML versions prior to HTML5.

=item * B<0303> - wilful violation, as this feature is simply awful.
	
=back

Please report any bugs to L<http://rt.cpan.org/>.

Common gotchas:

=over 8

=item * Are you using the XML catalogue?

RDF::RDFa::Parser maintains a locally cached version of the XHTML+RDFa
DTD. This will normally be within your Perl module directory, in a subdirectory
named "auto/share/dist/RDF-RDFa-Parser/catalogue/".
If this is missing, the parser should still work, but will be very slow.

=back

=head1 SEE ALSO

L<RDF::TrineX::Parser::RDFa> provides a saner interface for this module.

L<RDF::RDFa::Parser::Config>. 

L<XML::LibXML>, L<RDF::Trine>, L<HTML::HTML5::Parser>, L<HTML::HTML5::Sanity>,
L<RDF::RDFa::Generator>, L<RDF::RDFa::Linter>.

L<http://www.perlrdf.org/>, L<http://rdfa.info>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 ACKNOWLEDGEMENTS

Kjetil Kjernsmo E<lt>kjetilk@cpan.orgE<gt> wrote much of the stuff for
building RDF::Trine models. Neubert Joachim taught me to use XML
catalogues, which massively speeds up parsing of XHTML files that have
DTDs.

=head1 COPYRIGHT AND LICENCE

Copyright 2008-2012 Toby Inkster

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
