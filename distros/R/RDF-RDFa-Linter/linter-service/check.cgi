#!/usr/bin/perl

use common::sense;
use constant XHTML_NS => 'http://www.w3.org/1999/xhtml';
use CGI qw'';
use CGI::Carp qw'fatalsToBrowser';
use Data::Dumper qw'';
use Digest::SHA1 qw'sha1_hex';
use File::Slurp qw'slurp';
use HTML::HTML5::Writer qw(DOCTYPE_HTML5 DOCTYPE_XHTML_RDFA);
use HTTP::Cache::Transparent (BasePath=>'/tmp/cache/');
use HTTP::Negotiate qw'choose';
use JSON -convert_blessed_universally;
use LWPx::ParanoidAgent;
use PHP::Serialization qw'';
use RDF::RDFa::Generator;
use RDF::RDFa::Linter;
use RDF::RDFa::Linter::Error;
use RDF::RDFa::Parser;
use URI qw'';
use WWW::RobotRules;
use XML::LibXML qw':all';
use YAML::Any qw'';

my $CGI = CGI->new;
$CGI::POST_MAX = 1024*1024*2;

my @services = qw(Facebook Google CreativeCommons);

my $url = $CGI->param('url') || $CGI->param('uri') || shift @ARGV;
my $content;
my $source;

if ($CGI->param('source') =~ /upload/i)
{
	$source = 'uploaded file';
	my $fh = $CGI->upload('file');
	$content = do { local $/; <$fh>; };
	$url = 'widget://'.sha1_hex($content).'.rdfa/self'
		unless length $url;
}
elsif ($CGI->param('source') =~ /post/i)
{
	$source = 'posted data';
	$content = $CGI->param('data');
	$url = 'widget://'.sha1_hex($content).'.rdfa/self'
		unless length $url;
}
elsif ($url =~ /^referr?er$/i && length $CGI->referer)
{
	$url = $CGI->referer;
	$source = "referer <$url>";
}
elsif (length $url)
{
	$source = "<$url>";
}
else
{
	die "Must provide a URL!";
}

# Set up primary RDFa parser
my $ua = LWPx::ParanoidAgent->new(
	agent => sprintf("check.rdfa/0.0.1 (+http://check.rdfa.info/) RDF-RDFa-Parser/%s RDF-RDFa-Linter/%s RDF-RDFa-Generator/%s ",
		$RDF::RDFa::Parser::VERSION, $RDF::RDFa::Linter::VERSION, $RDF::RDFa::Generator::VERSION));
my $rdfa_parser;
my $opts = RDF::RDFa::Parser::Config->new(
	$CGI->param('language')||'html5',
	$CGI->param('version')||'1.0',
	lwp_ua => $ua,
	);
if (defined $content)
{
	$rdfa_parser = RDF::RDFa::Parser->new($content, $url, $opts);
}
else
{
	my $robots_txt_url = URI->new_abs('/robots.txt', $url);
	my $robots_txt     = $ua->get($robots_txt_url);
	my $rules          = WWW::RobotRules->new('check.rdfa');
	$rules->parse($robots_txt_url, $robots_txt->decoded_content)
		if $robots_txt->is_success;
	
	die "Forbidden by robots.txt."
		unless $rules->allowed($url);
	
	$rdfa_parser = RDF::RDFa::Parser->new_from_url($url, $opts);
}

my @main_errs;
$rdfa_parser->set_callbacks({oncurie => \&main_cb_oncurie});

my $var = $CGI->param('format') || choose([
	[ 'html',  1.000, 'text/html'],
	[ 'xhtml', 0.900, 'application/xhtml+xml'],
	[ 'json',  0.500, 'application/json'],
	[ 'yaml',  0.100, 'text/x-yaml'],
	[ 'pl',    0.100, 'text/x-perl'],
	[ 'php',   0.100, 'application/vnd.php.serialized'],
	]) || 'html';
$var = lc $var;

if ($var eq 'json' or $var eq 'yaml' or $var eq 'pl' or $var eq 'php')
{
	my $data = {};
	
	$data->{'RDFa'}->{'Data'}   = $rdfa_parser->graph->as_hashref;
	$data->{'RDFa'}->{'Errors'} = \@main_errs;

	foreach my $srv (@services)
	{
		my $this_parser = RDF::RDFa::Parser->new($rdfa_parser->dom, $rdfa_parser->uri, $opts);
		my $linter      = RDF::RDFa::Linter->new($srv, $url, $this_parser);
		
		if ($linter->filtered_graph->count_statements)
		{
			$data->{$srv}->{'Info'}   = $linter->info;
			$data->{$srv}->{'Data'}   = $linter->filtered_graph->as_hashref;
			$data->{$srv}->{'Errors'} = [ $linter->find_errors ];
		}
		else
		{
			$data->{$srv} = undef;
		}
	}
	
	if ($var eq 'json')
	{
		print $CGI->header('application/json')
			if defined $CGI->request_method;
		print JSON->new->utf8->convert_blessed->encode($data);
	}
	elsif ($var eq 'yaml')
	{
		print $CGI->header('text/x-yaml')
			if defined $CGI->request_method;
		print YAML::Any::Dump($data);
	}
	elsif ($var eq 'pl')
	{
		print $CGI->header('text/x-perl')
			if defined $CGI->request_method;
		print Data::Dumper::Dumper($data);
	}
	elsif ($var eq 'php')
	{
		print $CGI->header('application/vnd.php.serialized')
			if defined $CGI->request_method;
		print PHP::Serialization::serialize($data);
	}
	exit;	
}
else
{
	my $template = slurp('linter-template.xml');
	my $dom = XML::LibXML->new->parse_string($template);
	my $xpc = XML::LibXML::XPathContext->new($dom);
	$xpc->registerNs('x', XHTML_NS);
	my $gen = RDF::RDFa::Generator->new(style=>'HTML::Pretty', safe_xml_literals=>1);

	# Title
	my @title = $dom->getElementsByTagName('title');
	$title[0]->appendTextNode("check.rdfa: $url");

	# Header
	my @head = $xpc->findnodes('//x:*[@class="head"]');
	$head[0]->addNewChild(XHTML_NS, 'h1')->appendWellBalancedChunk('check<span class="space"> </span><span class="r">rdfa</span>');

	# Summary
	my @summary = $xpc->findnodes('//x:*[@class="summary"]');
	$summary[0]->addNewChild(XHTML_NS, 'p')->appendTextNode("results for $source");

	# Main tab
	my $main_tab = _add_tab($xpc, 'RDFa', undef, 0, 'All Data');
	$main_tab->addNewChild(XHTML_NS, 'p')->appendTextNode("This tab shows all RDFa data extracted from your page; the other tabs filter this data down to show what particular services will see.");
	foreach my $node ($gen->nodes($rdfa_parser->graph, notes=>\@main_errs))
	{
		$node->setAttribute('class', $node->getAttribute('class').' rdfa');
		$main_tab->appendChild($node);
	}

	# Service tabs
	foreach my $srv (@services)
	{
		my $this_parser = RDF::RDFa::Parser->new($rdfa_parser->dom, $rdfa_parser->uri, $opts);
		my $linter      = RDF::RDFa::Linter->new($srv, $url, $this_parser);
		
		my $this_tab    = _add_tab($xpc, $linter->info->{'short'}, undef, 0, $linter->info->{'title'});	
		$this_tab->addNewChild(XHTML_NS, 'p')->appendTextNode($linter->info->{'description'});
		
		if ($linter->filtered_graph->count_statements)
		{
			foreach my $node ($gen->nodes($linter->filtered_graph, notes=>[$linter->find_errors]))
			{
				$node->setAttribute('class', $node->getAttribute('class').' rdfa');
				$this_tab->appendChild($node);
			}
		}
		else
		{
			$this_tab->addNewChild(XHTML_NS, 'p')->addNewChild(XHTML_NS, 'strong')->appendTextNode("No data found by this service.");
		}
	}

	# Output
	my $doctype = {
		html  => DOCTYPE_HTML5,
		xhtml => DOCTYPE_XHTML_RDFA,
		};
	$dom->documentElement->removeAttributeNS(undef, 'lang')
		if $var eq 'xhtml';
	print $CGI->header(($var eq 'html' ? 'text/html' : 'application/xhtml+xml')."; charset=utf-8")
		if defined $CGI->request_method;
	print HTML::HTML5::Writer->new(charset=>'ascii',markup=>$var,doctype=>$doctype->{$var})->document($dom);
	exit;
}

sub _xpath_has_class
{
	my ($nodelist, $class) = @_;
	my $result = XML::LibXML::NodeList->new;
	for my $node ($nodelist->get_nodelist)
	{
		next unless $node->nodeType eq XML_ELEMENT_NODE;
		next unless $node->hasAttribute('class');
		$result->push($node) if $node->getAttribute('class') =~ /\b($class)\b/;
	}
	return $result;
}

sub _add_tab
{
	my ($xpc, $title, $id, $index, $long) = @_;
	
	($id = 'tab-'.lc $title) =~ s/[^a-z0-9-]//i
		unless defined $id;
	
	$index = 0 unless defined $index;
		
	my @containers = $xpc->findnodes('//x:*[@class="tabs"]');
	my $tab = $containers[$index]->addNewChild(XHTML_NS, 'div');
	$tab->setAttribute('id', $id);	
	$tab->addNewChild(XHTML_NS, 'h2')->appendTextNode($long||$title);
	
	my @menus = $xpc->findnodes('//x:*[@class="tabNavigation"]');
	my $item = $menus[$index]->addNewChild(XHTML_NS, 'li');
	my $a = $item->addNewChild(XHTML_NS, 'a');
	$a->setAttribute('href', '#'.$id);
	$a->appendTextNode($title);
	
	return $tab;
}

sub main_cb_oncurie
{
	my ($parser, $node, $curie, $uri) = @_;

	return $uri unless $curie eq $uri || $uri eq '';

	my $preferred = {
		bibo => 'http://purl.org/ontology/bibo/' ,
		cc => 'http://creativecommons.org/ns#' ,
		ctag => 'http://commontag.org/ns#' ,
		dbp => 'http://dbpedia.org/property/' ,
		dc => 'http://purl.org/dc/terms/' ,
		doap => 'http://usefulinc.com/ns/doap#' ,
		fb => 'http://developers.facebook.com/schema/' ,
		foaf => 'http://xmlns.com/foaf/0.1/' ,
		geo => 'http://www.w3.org/2003/01/geo/wgs84_pos#' ,
		gr => 'http://purl.org/goodrelations/v1#' ,
		ical => 'http://www.w3.org/2002/12/cal/ical#' ,
		og => 'http://opengraphprotocol.org/schema/' ,
		owl => 'http://www.w3.org/2002/07/owl#' ,
		rdf => 'http://www.w3.org/1999/02/22-rdf-syntax-ns#' ,
		rdfa => 'http://www.w3.org/ns/rdfa#' ,
		rdfs => 'http://www.w3.org/2000/01/rdf-schema#' ,
		rel => 'http://purl.org/vocab/relationship/' ,
		rev => 'http://purl.org/stuff/rev#' ,
		rss => 'http://purl.org/rss/1.0/' ,
		sioc => 'http://rdfs.org/sioc/ns#' ,
		skos => 'http://www.w3.org/2004/02/skos/core#' ,
		v => 'http://rdf.data-vocabulary.org/#' ,
		vann => 'http://purl.org/vocab/vann/' ,
		vcard => 'http://www.w3.org/2006/vcard/ns#' ,
		void => 'http://rdfs.org/ns/void#' ,
		xfn => 'http://vocab.sindice.com/xfn#' ,
		xhv => 'http://www.w3.org/1999/xhtml/vocab#' ,
		xsd => 'http://www.w3.org/2001/XMLSchema#' ,
		};
	
	if ($curie =~ m/^([^:]+):(.*)$/)
	{
		my ($pfx, $sfx) = ($1, $2);
		
		if (defined $preferred->{$pfx})
		{
			push @main_errs,
				RDF::RDFa::Linter::Error->new(
					'subject' => RDF::Trine::Node::Resource->new($url),
					'text'    => "CURIE '$curie' used but '$pfx' is not bound - perhaps you forgot to specify xmlns:${pfx}=\"".$preferred->{$pfx}."\"",
					'level'   => 5,
					);
		}
		elsif ($pfx !~ m'^(http|https|file|ftp|urn|tag|mailto|acct|data|
			fax|tel|modem|gopher|info|news|sip|irc|javascript|sgn|ssh|xri|widget)$'ix)
		{
			push @main_errs,
				RDF::RDFa::Linter::Error->new(
					'subject' => RDF::Trine::Node::Resource->new($url),
					'text'    => "CURIE '$curie' used but '$pfx' is not bound - perhaps you forgot to specify xmlns:${pfx}=\"SOMETHING\"",
					'level'   => 1,
					);
		}
	}

	return $uri;
}
