use 5.010;
use strict;

use Encode qw(encode);
use JSON qw(from_json);
use LWP::UserAgent;
use Object::AUTHORITY -package => 'UNIVERSAL';
use Plack::Request;
use RDF::RDFa::Parser 1.096;
use RDF::Trine;

BEGIN { eval 'use RDF::RDFa::Generator' };

my $user_agent = LWP::UserAgent->new(
	agent             => 'RDF::RDFa::Parser Distiller',
	from              => 'tobyink@cpan.org',  ## change this!!
	max_redirect      => 2,
	parse_head        => 0,
	protocols_allowed => [qw[ http https ]],
	timeout           => 60,
);

my %std = (
	'X-Powered-By' => sprintf(
		'RDF::RDFa::Parser/%s (%s)',
		RDF::RDFa::Parser->VERSION,
		RDF::RDFa::Parser->AUTHORITY,
	),
);

sub error
{
	my $message = shift;
	
	[
		400,
		[ %std, 'Content-Type' => 'text/plain' ],
		[ sprintf $message => @_ ],
	]
}

sub show_form
{
	state $form = do
	{
		(my $file = __FILE__) =~ s/psgi$/html/;
		local(@ARGV, $/) = $file;
		my $html = <>;
		
		$html =~ s{ \$AUTHORITY }
		          { RDF::RDFa::Parser->AUTHORITY }xeg;
		$html =~ s{ \$VERSION }
		          { RDF::RDFa::Parser->VERSION }xeg;
		
		$html;
	};
	
	[
		200,
		[ %std, 'Content-Type' => 'text/html' ],
		[ $form ],
	]
}

sub process_config
{
	my ($req, $rdfa_response) = @_;
	my $p   = $req->parameters;
	
	my $rdfa_host =
		   $p->{host}
		|| RDF::RDFa::Parser::Config->host_from_media_type($rdfa_response->content_type);
	
	if ($rdfa_host eq 'html5' and not $p->{host})
	{
		my $prelude = substr($rdfa_response->decoded_content, 0, 512);
		$rdfa_host = 'html32' if $prelude =~ m{-//W3C//DTD HTML 3\.2};
		$rdfa_host = 'html4'  if $prelude =~ m{-//W3C//DTD HTML 4};
	}
	
	$rdfa_host ||= 'xhtml';
	
	my $rdfa_version =
		   $p->{version}
		|| 'guess';
	
	my %options = %{
		eval { from_json($p->{options}) } or +{}
	};
	
	foreach my $k (keys %$p)
	{
		next unless $k =~ /^option_(.+)$/;
		$options{$1} = $p->{$k};
	}
	
	RDF::RDFa::Parser::Config->new($rdfa_host, $rdfa_version, %options)
}

my $app = sub
{
	my $req = Plack::Request->new( shift );
	
	my $url = $req->parameters->{url} // $req->parameters->{uri};
	return show_form($req) unless $url;
	
	my $response = $user_agent->get(
		$url,
		'User-Agent' => sprintf('RDF::RDFa::Parser Distiller (+%s)', $req->uri),
	);
	
	return error(
		'Request for <%s> responded with status "%s".',
		$url,
		$response->status_line,
	) unless $response->is_success;
	
	my $prefixes = {
		rdf  => 'http://www.w3.org/1999/02/22-rdf-syntax-ns#',
		rdfs => 'http://www.w3.org/2000/01/rdf-schema#',
		xsd  => 'http://www.w3.org/2001/XMLSchema#',
		owl  => 'http://www.w3.org/2002/07/owl#',
		rdfa => 'http://www.w3.org/ns/rdfa#',
		xhv  => 'http://www.w3.org/1999/xhtml/vocab#',
	};
	
	my $rdfa = RDF::RDFa::Parser->new(
		$response->decoded_content,
		$response->base,
		process_config($req, $response),
	)->set_callbacks(
		{ onprefix => sub { $prefixes->{$_[2]} = $_[3]; return 0 } }
	)->consume;
	
	my %options = (namespaces => $prefixes, style => 'HTML::Pretty');
	my $ser = $req->parameters->{format}
		? RDF::Trine::Serializer->new($req->parameters->{format}, %options)
		: RDF::Trine::Serializer->negotiate(request_headers => $req->headers, %options);
	
	my $media_type = $ser->isa('RDF::RDFa::Generator')
		? 'text/html'
		: [$ser->media_types]->[0];
	$media_type = 'text/turtle' if $media_type =~ /turtle/; # :-(
	
	my $graph  = $req->parameters->{rdfagraph};
	my $method = do {
		   if (not $graph)                       { 'graph' }
		elsif (lc $graph eq 'output')            { 'graph' }
		elsif (lc $graph eq 'processor')         { 'processor_graph' }
		elsif (lc $graph eq 'processor,output')  { 'processor_and_output_graph' }
		elsif (lc $graph eq 'output,processor')  { 'processor_and_output_graph' }
		else                                     { sub { shift->graph($graph) } }
	};
	
	[
		200,
		[ %std, 'Content-Type' => $media_type ],
		[ encode utf8 => $ser->serialize_model_to_string($rdfa->$method) ],
	];
};


