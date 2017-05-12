package RDF::RDFa::Parser::Config;

BEGIN {
	$RDF::RDFa::Parser::Config::AUTHORITY = 'cpan:TOBYINK';
	$RDF::RDFa::Parser::Config::VERSION   = '1.097';	
}

use parent qw(Exporter);
use constant {
	HOST_ATOM     => 'atom',
	HOST_DATARSS  => 'datarss',
	HOST_HTML32   => 'html32',
	HOST_HTML4    => 'html4',
	HOST_HTML5    => 'html5',
	HOST_OPENDOCUMENT_XML => 'opendocument-xml',
	HOST_OPENDOCUMENT_ZIP => 'opendocument-zip',
	HOST_SVG      => 'svg',
	HOST_XHTML    => 'xhtml',
	HOST_XHTML5   => 'xhtml5',
	HOST_XML      => 'xml',
};
use constant {
	RDFA_10     => '1.0',
	RDFA_11     => '1.1',
	RDFA_LATEST => '1.1',
	RDFA_GUESS  => 'guess',
};
use common::sense;
use 5.010;

use RDF::RDFa::Parser::OpenDocumentObjectModel;
use URI::Escape qw'uri_unescape';

our @EXPORT_OK = qw(HOST_ATOM HOST_DATARSS HOST_HTML4 HOST_HTML5 HOST_OPENDOCUMENT_XML HOST_OPENDOCUMENT_ZIP HOST_SVG HOST_XHTML HOST_XHTML5 HOST_XML RDFA_10 RDFA_11);

our $CONFIGS = {
	'host' => {
		HOST_ATOM() => {
			'atom_elements'         => 1,
			'initial_context'       => '',
			'vocab_default'         => 'http://www.iana.org/assignments/relation/',
		},
		HOST_DATARSS() => {
			'atom_elements'         => 1,
			'initial_context'       => 'http://search.yahoo.com/searchmonkey-profile',
			'vocab_default'         => 'http://www.iana.org/assignments/relation/',
		},
		HOST_HTML32() => {
			'dom_parser'            => 'html',
			'embedded_rdfxml'       => 0,
			'intial_context'        => 'tag:buzzword.org.uk,2010:rdfa:profile:html32',
			'prefix_nocase_xmlns'   => 1,
			'xhtml_base'            => 1,
			'xhtml_elements'        => 1,
			'xhtml_lang'            => 1,
			'xml_base'              => 0,
			'xml_lang'              => 0,
		},
		HOST_HTML4() => {
			'dom_parser'            => 'html',
			'embedded_rdfxml'       => 0,
			'initial_context'       => 'tag:buzzword.org.uk,2010:rdfa:profile:html4 http://www.w3.org/2011/rdfa-context/html-rdfa-1.1',
			'prefix_nocase_xmlns'   => 1,
			'xhtml_base'            => 1,
			'xhtml_elements'        => 1,
			'xhtml_lang'            => 1,
			'xml_base'              => 0,
			'xml_lang'              => 0,
		},
		HOST_HTML5() => {
			'dom_parser'            => 'html',
			'embedded_rdfxml'       => 0,
			'initial_context'       => 'tag:buzzword.org.uk,2010:rdfa:profile:html5 http://www.w3.org/2011/rdfa-context/html-rdfa-1.1',
			'prefix_nocase_xmlns'   => 1,
			'xhtml_base'            => 1,
			'xhtml_elements'        => 1,
			'xhtml_lang'            => 1,
			'xml_base'              => 0,
			'xml_lang'              => 1,
		},
		HOST_OPENDOCUMENT_XML() => {
			'bookmark_end'          => '{urn:oasis:names:tc:opendocument:xmlns:text:1.0}bookmark-end',
			'bookmark_name'         => '{urn:oasis:names:tc:opendocument:xmlns:text:1.0}name',
			'bookmark_start'        => '{urn:oasis:names:tc:opendocument:xmlns:text:1.0}bookmark-start',
			'ns'                    => 'http://www.w3.org/1999/xhtml',
		},
		HOST_OPENDOCUMENT_ZIP() => {
			'bookmark_end'          => '{urn:oasis:names:tc:opendocument:xmlns:text:1.0}bookmark-end',
			'bookmark_name'         => '{urn:oasis:names:tc:opendocument:xmlns:text:1.0}name',
			'bookmark_start'        => '{urn:oasis:names:tc:opendocument:xmlns:text:1.0}bookmark-start',
			'dom_parser'            => 'opendocument',
			'graph'                 => 3,
			'graph_attr'            => '{http://purl.org/NET/cpan-uri/dist/RDF-RDFa-Parser/opendocument-dom-wrapper}graph',
			'graph_type'            => 'about',
			'ns'                    => 'http://www.w3.org/1999/xhtml',
		},
		HOST_SVG() => {},
		HOST_XHTML() => {
			'embedded_rdfxml'       => 0,
			'xhtml_base'            => 1,
			'xhtml_elements'        => 1,
			'xml_base'              => 0,
		},
		HOST_XHTML5() => {
			'embedded_rdfxml'       => 0,
			'xhtml_base'            => 1,
			'xhtml_elements'        => 1,
			'xml_base'              => 2,
		},
		HOST_XML() => {},
	},
	'rdfa' => {
		RDFA_10() => {
			'alt_stylesheet'        => 0,
			'atom_elements'         => 0,
			'atom_parser'           => 0,
			'auto_config'           => 0,
			'bookmark_end'          => undef,
			'bookmark_name'         => undef,
			'bookmark_start'        => undef,
			'cite_attr'             => 0,
			'datetime_attr'         => 0,
			'dom_parser'            => 'xml',
			'embedded_rdfxml'       => 1,
			'full_uris'             => 0,
			'graph'                 => 0,
			'graph_attr'            => 'graph',
			'graph_type'            => 'about',
			'graph_default'         => undef,
			'graph_default_trine'   => undef,  # not officially exposed
			'initial_context'       => 'tag:buzzword.org.uk,2010:rdfa:profile:rdfa-1.0',
			'inlist_attr'           => 0,
			'longdesc_attr'         => 0,
			'lwp_ua'                => undef,
			'ns'                    => undef,
			'prefix_attr'           => 0,
			'prefix_bare'           => 0,
			'prefix_default'        => 'http://www.w3.org/1999/xhtml/vocab#',
			'prefix_nocase_attr'    => 0,
			'prefix_nocase_xmlns'   => 0,
			'property_resources'    => 0,
			'role_attr'             => 0,
			'safe_anywhere'         => 0,
			'safe_optional'         => 0,
			'skolemize'             => 0,
			'src_sets_object'       => 0,
			'tdb_service'           => 0,
			'typeof_resources'      => 0,
			'uri_class'             => 'URI',
			'use_rtnlx'             => 0,
			'user_agent'            => undef,
			'value_attr'            => 0,
			'vocab_attr'            => 0,
			'vocab_default'         => undef,
			'vocab_triple'          => 0,
			'xhtml_base'            => 0,
			'xhtml_elements'        => 0,
			'xhtml_lang'            => 0,
			'xml_base'              => 2,
			'xml_lang'              => 1,
			'xmllit_default'        => 1,
			'xmllit_recurse'        => 0,
			'xmlns_attr'            => 1,
		},
		RDFA_11() => {
			'alt_stylesheet'        => 0,
			'atom_elements'         => 0,
			'atom_parser'           => 0,
			'auto_config'           => 0,
			'bookmark_end'          => undef,
			'bookmark_name'         => undef,
			'bookmark_start'        => undef,
			'cite_attr'             => 0,
			'datetime_attr'         => 0,
			'dom_parser'            => 'xml',
			'embedded_rdfxml'       => 1,
			'full_uris'             => 1, #diff
			'graph'                 => 0,
			'graph_attr'            => 'graph',
			'graph_type'            => 'about',
			'graph_default'         => undef,
			'graph_default_trine'   => undef,
			'inlist_attr'           => 1, #diff
			'initial_context'       => 'http://www.w3.org/2011/rdfa-context/rdfa-1.1',
			'longdesc_attr'         => 0,
			'lwp_ua'                => undef,
			'ns'                    => undef,
			'prefix_attr'           => 1, #diff
			'prefix_bare'           => 0,
			'prefix_default'        => 'http://www.w3.org/1999/xhtml/vocab#',
			'prefix_nocase_attr'    => 1, #diff
			'prefix_nocase_xmlns'   => 1, #diff
			'property_resources'    => 1, #diff
			'role_attr'             => 0,
			'safe_anywhere'         => 1, #diff
			'safe_optional'         => 1, #diff
			'src_sets_object'       => 1, #diff
			'skolemize'             => 0,
			'tdb_service'           => 0,
			'typeof_resources'      => 1, #diff
			'uri_class'             => 'URI',
			'use_rtnlx'             => 0,
			'user_agent'            => undef,
			'value_attr'            => 0,
			'vocab_attr'            => 1, #diff
			'vocab_default'         => undef,
			'vocab_triple'          => 1,
			'xhtml_base'            => 0,
			'xhtml_elements'        => 0,
			'xhtml_lang'            => 0,
			'xml_base'              => 2,
			'xml_lang'              => 1,
			'xmllit_default'        => 0, #diff
			'xmllit_recurse'        => 1, #diff
			'xmlns_attr'            => 1,
		},
	},
	'combination' => {
		'xhtml+1.1' => {
			'initial_context'       => 'http://www.w3.org/2011/rdfa-context/xhtml-rdfa-1.1 http://www.w3.org/2011/rdfa-context/rdfa-1.1',
			'xhtml_elements'        => 2,
			
			# XHTML+RDFa 1.1 wants to use @lang, though
			# neither XHTML's host language rules, nor
			# RDFa 1.1's rules individually use it.
			'xhtml_lang'            => 1,
		},
		'html32+1.1' => {
			'datetime_attr'         => 1,
			'value_attr'            => 1,
			'xhtml_elements'        => 2,
		},
		'html4+1.1' => {
			'datetime_attr'         => 1,
			'value_attr'            => 1,
			'xhtml_elements'        => 2,
		},
		'html5+1.1' => {
			'datetime_attr'         => 1,
			'value_attr'            => 1,
			'xhtml_elements'        => 2,
		},
		'xhtml5+1.1' => {
			'datetime_attr'         => 1,
			'initial_context'       => 'tag:buzzword.org.uk,2010:rdfa:profile:html5 http://www.w3.org/2011/rdfa-context/html-rdfa-1.1 http://www.w3.org/2011/rdfa-context/xhtml-rdfa-1.1',
			'value_attr'            => 1,
			'xhtml_elements'        => 2,
			'xhtml_lang'            => 1,
		},
	},
};

sub new
{
	my ($class, $host, $version, %options) = @_;
	$host    ||= HOST_XHTML;
	$version ||= RDFA_11;
	
	if ($version eq RDFA_GUESS)
	{
		$version = RDFA_11;
		$options{'guess_rdfa_version'} = 1;
	}
	
	$host = $class->host_from_media_type($host) if $host =~ m'/';
	
	my $self = bless {}, $class;
	
	if (defined $CONFIGS->{'rdfa'}->{$version})
	{
		$self->merge_options($CONFIGS->{'rdfa'}->{$version});
	}
	else
	{
		die "Unsupported RDFa version: $version";
	}
	
	$self->merge_options($CONFIGS->{'host'}->{$host})
		if defined $CONFIGS->{'host'}->{$host};

	$self->merge_options($CONFIGS->{'combination'}->{$host . '+' . $version})
		if defined $CONFIGS->{'combination'}->{$host . '+' . $version};

	$self->merge_options(\%options)
		if %options;
	
	$self->{'_host'} = $host;
	$self->{'_rdfa'} = $version;
	$self->{'_opts'} = \%options;
	
	return $self;
}

sub tagsoup
{
	my ($class) = @_;
	return $class->new(
		HOST_HTML5,
		RDFA_LATEST,
		cite_attr        => 1,
		role_attr        => 1,
		longdesc_attr    => 1,
	);
}

sub host_from_media_type
{
	my ($class, $mediatype) = @_;
	
	my $host = {
		'application/atom+xml'    => HOST_ATOM,
		'application/vnd.wap.xhtml+xml' => HOST_XHTML,
		'application/xhtml+xml'   => HOST_XHTML,
		'application/xml'         => HOST_XML,
		'application/zip'         => HOST_OPENDOCUMENT_ZIP,
		'image/svg+xml'           => HOST_SVG,
		'text/html'               => HOST_HTML5,
		'text/xml'                => HOST_XML,
		}->{$mediatype};
	
	return $host
		if defined $host;
	
	return HOST_XML
		if $mediatype =~ /\+xml/;
	
	return HOST_OPENDOCUMENT_ZIP
		if grep { $mediatype eq $_ } @RDF::RDFa::Parser::OpenDocumentObjectModel::Types;
	
	return undef;
}

sub rehost
{
	my ($self, $host, $version) = @_;
	$version ||= $self->{'_rdfa'};
	my $opts   = $self->{'_opts'};
	my $class  = ref $self;
	return $class->new($host, $version, %$opts);
}

sub guess_rdfa_version
{
	my ($config, $parser) = @_;
	
	my $rdfans = $config->{'ns'} || undef;
	my $version;
	if ($rdfans)
	{
		$version = $parser->dom->documentElement->hasAttributeNS($rdfans, 'version')
			? $parser->dom->documentElement->getAttributeNS($rdfans, 'version')
			: undef;
	}
	else
	{
		$version = $parser->dom->documentElement->hasAttribute('version')
			? $parser->dom->documentElement->getAttribute('version')
			: undef;
	}
		
	if (defined $version and $version =~ /\bRDFa\s+(\d+\.\d+)\b/i)
	{
		return $config->rehost($config->{'_host'}, $1);
	}
	
	return $config;
}

sub lwp_ua
{
	my ($self) = @_;
	
	unless (ref $self->{lwp_ua})
	{
		my $uastr = sprintf('%s/%s ', 'RDF::RDFa::Parser', RDF::RDFa::Parser->VERSION);
		if (defined $self->{'user_agent'})
		{
			if ($self->{'user_agent'} =~ /\s+$/)
			{
				$uastr = $self->{'user_agent'} . " $uastr";
			}
			else
			{
				$uastr = $self->{'user_agent'};
			}
		}
		
		my $accept = "application/xhtml+xml, text/html;q=0.9, image/svg+xml;q=0.9, application/atom+xml;q=0.9, application/xml;q=0.1, text/xml;q=0.1";
		if (RDF::RDFa::Parser::OpenDocumentObjectModel->usable)
		{
			foreach my $t (@RDF::RDFa::Parser::OpenDocumentObjectModel::Types)
			{
				$accept .= ", $t;q=0.4";
			}
		}
		
		$self->{lwp_ua} = LWP::UserAgent->new;
		$self->{lwp_ua}->agent($uastr);
		$self->{lwp_ua}->default_header("Accept" => $accept);
	}
	
	return $self->{lwp_ua};
}

sub auto_config
{
	my ($self, $parser) = @_;
	my $count;
	
	return undef unless $self->{'auto_config'};

	my $xpc = XML::LibXML::XPathContext->new;
	$xpc->registerNs('x', 'http://www.w3.org/1999/xhtml');
	my $nodes  = $xpc->find('//x:meta[@name="http://search.cpan.org/dist/RDF-RDFa-Parser/#auto_config"]/@content', $parser->dom->documentElement);
	my $optstr = '';
	foreach my $node ($nodes->get_nodelist)
	{
		$optstr .= '&' . $node->getValue;
	}
	$optstr =~ s/^\&//;
	my $options = _parse_application_x_www_form_urlencoded($optstr);
	
	my $x = {};
	
	foreach my $o (keys %$options)
	{
		# ignore use_rtnlx, dom_parser and auto_config.
		next if $o=~ /^(use_rtnlx|dom_parser|auto_config)$/i;
		$count++;
		
		if (lc $o eq 'initial_context')
		{
			$x->{lc $o} .= ' ' . $options->{$o};
		}
		else
		{
			$x->{lc $o} = $options->{$o};
		}
	}
	
	$self->merge_options(%$x);
	
	return $count;
}

sub _parse_application_x_www_form_urlencoded
{
	my $axwfue = shift;
	$axwfue =~ tr/;/&/;
	$axwfue =~ s/\+/%20/g;
	$axwfue =~ s/(^&+|&+$)//g;
	my $rv = {};
	for (split /&/, $axwfue)
	{
		my ($k, $v) = split /=/, $_, 2;
		next unless length $k;
		$rv->{uri_unescape($k)} = uri_unescape($v);
	}
	return $rv;
}

sub merge_options
{
	my $self = shift;
	my %opts = (ref $_[0]) ? %{$_[0]} : @_;
	
	while (my ($key, $value) = each %opts)
	{
		if ($key =~ m'^(initial_context)$'i
		&&  defined $self->{$key}
		&&  length $self->{$key})
		{
			$self->{$key} .= " $value"; 
		}
		elsif ($key eq 'prefix_nocase')
		{
			$self->{'prefix_nocase_attr'}  = $value;
			$self->{'prefix_nocase_xmlns'} = $value;
		}
		else
		{
			$self->{$key}  = $value;
		}
	}
}

1;

__END__

=head1 NAME

RDF::RDFa::Parser::Config - configuration sets for RDFa parser

=head1 DESCRIPTION

The third argument to the constructor for RDF::RDFa::Parser objects is a
configuration set. This module provides such configuration sets.

Confguration sets are needed by the parser so that it knows how to handle
certain features which vary between different host languages, or different
RDFa versions.

All you need to know about is the constructor:

  $config = RDF::RDFa::Parser::Config->new($host, $version, %options);

$host is the host language. Generally you would supply one of the
following constants; the default is HOST_XHTML. Internet media types
are accepted (e.g. 'text/html' or 'image/svg+xml'), but it's usually
better to use a constant as some media types are shared (e.g. HTML4
and HTML5 both use the same media type).

=over

=item * B<< RDF::RDFa::Parser::Config->HOST_ATOM >>

=item * B<< RDF::RDFa::Parser::Config->HOST_DATARSS >>

=item * B<< RDF::RDFa::Parser::Config->HOST_HTML32 >>

=item * B<< RDF::RDFa::Parser::Config->HOST_HTML4 >>

=item * B<< RDF::RDFa::Parser::Config->HOST_HTML5 >>

=item * B<< RDF::RDFa::Parser::Config->HOST_OPENDOCUMENT_XML >> (Flat XML: "FODT", "FODS", etc)

=item * B<< RDF::RDFa::Parser::Config->HOST_OPENDOCUMENT_ZIP >> ("ODT", "ODS", etc)

=item * B<< RDF::RDFa::Parser::Config->HOST_SVG >>

=item * B<< RDF::RDFa::Parser::Config->HOST_XHTML >>

=item * B<< RDF::RDFa::Parser::Config->HOST_XHTML5 >>

=item * B<< RDF::RDFa::Parser::Config->HOST_XML >>

=back

$version is the RDFa version. Generally you would supply one of the
following constants; the default is RDFA_LATEST.

=over 2

=item * B<< RDF::RDFa::Parser::Config->RDFA_10 >>

=item * B<< RDF::RDFa::Parser::Config->RDFA_11 >>

=item * B<< RDF::RDFa::Parser::Config->RDFA_GUESS >>

=item * B<< RDF::RDFa::Parser::Config->RDFA_LATEST >>

=back

Version guessing: the root element is inspected for an attribute
'version'. If this exists and matches /\bRDFa\s+(\d+\.\d+)\b/i
then that is used as the version. Otherwise, the latest version
is assumed.

%options is a hash of additional options to use which override the
defaults. While many of these are useful, they probably also reduce
conformance to the official RDFa specifications. The following
options exist; defaults for XHTML+RDFa1.0 and XHTML+RDFa1.1 are shown
in brackets.

=over 2

=item * B<alt_stylesheet> - magic rel="alternate stylesheet". [0]

=item * B<atom_elements> - process <feed> and <entry> specially. [0]

=item * B<atom_parser> - extract Atom 1.0 native semantics. [0]

=item * B<auto_config> - see section "Auto Config" [0]

=item * B<bookmark_start>, B<bookmark_end>, B<bookmark_name> - Elements to treat like OpenDocument's E<lt>text:bookmark-startE<gt> and E<lt>text:bookmark-endE<gt> element, and associated text:name attribute. Must set all three to use this feature. Use Clark Notation to specify namespaces. [all undef]

=item * B<cite_attr> - support @cite [0]

=item * B<datetime_attr> - support @datetime attribute and HTML5 <time> element. [0]

=item * B<default_profiles> - THIS OPTION IS NO LONGER SUPPORTED!

=item * B<dom_parser> - parser to use to turn a markup string into a DOM. 'html', 'opendocument' (i.e. zipped XML) or 'xml'. ['xml']

=item * B<embedded_rdfxml> - find plain RDF/XML chunks within document. 0=no, 1=handle, 2=skip. [0]

=item * B<full_uris> - support full URIs in CURIE-only attributes. [0, 1]

=item * B<graph> - enable support for named graphs. [0]

=item * B<graph_attr> - attribute to use for named graphs. Use Clark Notation to specify a namespace. ['graph']

=item * B<graph_type> - graph attribute behaviour ('id' or 'about'). ['about']

=item * B<graph_default> - default graph name. [undef]

=item * B<initial_context> - space-separated list of URIs, which must be keys in %RDF::RDFa::Parser::InitialContext::Known [?]

=item * B<inlist_attr> - support @inlist. [0, 1]

=item * B<longdesc_attr> - support @longdesc [0]

=item * B<lwp_ua> - an LWP::UserAgent to use for HTTP requests. [undef]

=item * B<ns> - namespace for RDFa attributes. [undef]

=item * B<prefix_attr> - support @prefix rather than just @xmlns:*. [0, 1]

=item * B<prefix_bare> - support CURIEs with no colon+suffix. [0]

=item * B<prefix_default> - URI for default prefix (e.g. rel=":foo"). ['http://www.w3.org/1999/xhtml/vocab#']

=item * B<prefix_nocase> - DEPRECATED - shortcut for prefix_nocase_attr and prefix_nocase_xmlns.

=item * B<prefix_nocase_attr> - ignore case-sensitivity of CURIE prefixes defined via @prefix attribute. [0, 1]

=item * B<prefix_nocase_xmlns> - ignore case-sensitivity of CURIE prefixes defined via xmlns. [0, 1]

=item * B<profile_attr> - THIS OPTION IS NO LONGER SUPPORTED!

=item * B<profile_pi> - THIS OPTION IS NO LONGER SUPPORTED!

=item * B<property_resources> - @property works for resources [0, 1]

=item * B<role_attr> - support for XHTML @role [0]

=item * B<safe_anywhere> - allow Safe CURIEs in @rel/@rev/etc. [0, 1]

=item * B<safe_optional> - allow Unsafe CURIEs in @about/@resource. [0, 1]

=item * B<skolemize> - mint URIs instead of blank node identifiers. [0]

=item * B<src_sets_object> - @src sets object URI (like @href) [0, 1]

=item * B<tdb_service> - use thing-described-by.org to name some bnodes. [0]

=item * B<typeof_resources> - allow @typeof to occasionally apply to objects rather than subjects. [0, 1]

=item * B<user_agent> - a User-Agent header to use for HTTP requests. Ignored if lwp_ua is provided. [undef]

=item * B<use_rtnlx> - use RDF::Trine::Node::Literal::XML. 0=no, 1=if available. [0]

=item * B<value_attr> - support @value attribute (like @content) [0]

=item * B<vocab_attr> - support @vocab from RDFa 1.1. [0, 1]

=item * B<vocab_default> - default vocab URI (e.g. rel="foo"). [undef]

=item * B<vocab_triple> - generate triple from @vocab. [0, 1]

=item * B<xhtml_base> - process <base> element. 0=no, 1=yes, 2=use it for RDF/XML too. [1]                      

=item * B<xhtml_elements> - process <head> and <body> specially. (Different special handling for XHTML+RDFa 1.0 and 1.1.) [1, 2]

=item * B<xhtml_lang> - support @lang rather than just @xml:lang. [0]

=item * B<xml_base> - support for 'xml:base' attribute. 0=only RDF/XML; 1=except @href/@src; 2=always. [0]

=item * B<xml_lang> - Support for 'xml:lang' attribute. [1]

=item * B<xmllit_default> - Generate XMLLiterals enthusiastically. [1, 0]

=item * B<xmllit_recurse> - Look for RDFa inside XMLLiterals. [0, 1]

=item * B<xmlns_attr> - Support for 'xmlns:foo' to define CURIE prefixes. [1]

=back

An alternative constructor C<tagsoup> is provided with a useful set of
options for dealing with content "from the wild".

=head1 EXAMPLES

The following full example parses RDFa 1.1 in an Atom document, also using
the non-default 'atom_parser' option which parses native Atom elements into
the graph too.

  use RDF::RDFa::Parser;
  
  $config = RDF::RDFa::Parser::Config->new(
    RDF::RDFa::Parser::Config->HOST_ATOM,
    RDF::RDFa::Parser::Config->RDFA_11,
    atom_parser => 1,
    );
  $parser = RDF::RDFa::Parser->new_from_url($url, $config);
  $data   = $parser->graph;

The following configuration set parses XHTML+RDFa 1.1 while also parsing
any RDF/XML chunks that are embedded in the document.

  use RDF::RDFa::Parser::Config qw(HOST_XHTML RDFA_11);
  $config = RDF::RDFa::Parser::Config->new(
    HOST_XHTML, RDFA_11, embedded_rdfxml=>1);
  $parser = RDF::RDFa::Parser->new_from_url($url, $config);
  $data   = $parser->graph;

The following config is good for dealing with (X)HTML content from the
wild:

  $config = RDF::RDFa::Parser::Config->tagsoup;
  $parser = RDF::RDFa::Parser->new_from_url($url, $config);
  $data   = $parser->graph;

=head1 SEE ALSO

L<RDF::RDFa::Parser>.

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
