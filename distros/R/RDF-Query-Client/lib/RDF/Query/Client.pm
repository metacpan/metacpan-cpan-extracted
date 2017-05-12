use 5.010;
use strict;
use warnings;

package RDF::Query::Client;

BEGIN {
	$RDF::Query::Client::AUTHORITY = 'cpan:TOBYINK';
	$RDF::Query::Client::VERSION   = '0.114';
}

use Carp 0 qw/carp/;
use LWP::UserAgent 0 qw//;
use RDF::Trine 0.133 qw//;
use Scalar::Util 0 qw/blessed/;
use URI::Escape 0 qw/uri_escape/;

use namespace::clean;

sub new
{
	my $class = shift;
	my ($query, $opts) = @_;
	
	bless {
		query      => $query ,
		useragent  => ($opts->{UserAgent} // undef) ,
		results    => [] ,
		error      => undef ,
	}, $class;
}

sub execute
{
	my $self = shift;
	my ($endpoint, $opts) = @_;
	
	my $ua       = $opts->{UserAgent} // $self->useragent;
	my $request  = $self->_prepare_request($endpoint, $opts);
	my $response = $ua->request($request);
	
	push @{ $self->{results} }, { response => $response };
	
	my $iterator = $self->_create_iterator($response);
	return unless defined $iterator;
	$self->{results}[-1]{iterator} = $iterator;
	
	wantarray ? $iterator->get_all : $iterator;
}

our $LRDD;
sub discover_execute
{
	my $self = shift;
	my ($resource_uri, $opts) = @_;
	
	unless ($LRDD)
	{
		no warnings;
		eval 'use HTTP::LRDD;';
		eval
		{
			$LRDD = HTTP::LRDD->new('http://ontologi.es/sparql#endpoint', 'http://ontologi.es/sparql#fingerpoint')
				if HTTP::LRDD->can('new');
		};
	}
	
	unless (blessed($LRDD) and $LRDD->isa('HTTP::LRDD'))
	{
		$self->{error} = "Need HTTP::LRDD to use the discover_execute feature.";
		return;
	}
	
	my $endpoint = $LRDD->discover($resource_uri)
		or return;
	
	return $self->execute($endpoint, $opts);
}

sub get
{
	my $self = shift;
	my $stream = $self->execute(@_);
	
	if (ref $stream)
	{
		if ($stream->is_bindings)
		{
			my $row = $stream->next;
			return $stream->binding_values;
		}
		if ($stream->is_graph)
		{
			my $st = $stream->next;
			return ($st->subject, $st->predicate, $st->object);
		}
		if ($stream->is_boolean)
		{
			my @rv;
			push @rv, 1 if $stream->get_boolean;
			return @rv;
		}
	}
	
	return;
}

sub as_sparql
{
	return (shift)->{query};
}

sub http_response
{
	return (shift)->{results}[-1]{response};
}

sub error
{
	return (shift)->{error};
}

sub prepare { carp "Method not implemented"; }
sub execute_plan { carp "Method not implemented"; }
sub execute_with_named_graphs { carp "Method not implemented"; }
sub aggregate { carp "Method not implemented"; }
sub pattern { carp "Method not implemented"; }
sub sse { carp "Method not implemented"; }
sub algebra_fixup { carp "Method not implemented"; }
sub add_function { carp "Method not implemented"; }
sub supported_extensions { carp "Method not implemented"; }
sub supported_functions { carp "Method not implemented"; }
sub add_computed_statement_generator { carp "Method not implemented"; }
sub get_computed_statement_generators { carp "Method not implemented"; }
sub net_filter_function { carp "Method not implemented"; }
sub add_hook_once { carp "Method not implemented"; }
sub add_hook { carp "Method not implemented"; }
sub parsed { carp "Method not implemented"; }
sub bridge { carp "Method not implemented"; }
sub log { carp "Method not implemented"; }
sub logger { carp "Method not implemented"; }
sub costmodel { carp "Method not implemented"; }

sub useragent
{
	my $self = shift;
	
	unless (defined $self->{useragent})
	{
		my $accept = join q{, } => (
			'application/sparql-results+xml',
			'application/sparql-results+json;q=0.9',
			'application/rdf+xml',
			'application/x-turtle',
			'text/turtle',
		);
		my $agent = sprintf(
			'%s/%s (%s) ',
			__PACKAGE__,
			__PACKAGE__->VERSION,
			do { no strict "refs"; ${ref($self)."::AUTHORITY"} },
		);
		$self->{useragent} = LWP::UserAgent->new(
			agent             => $agent,
			max_redirect      => 2,
			parse_head        => 0,
			protocols_allowed => [qw/http https/],
		);
		$self->{useragent}->default_header(Accept => $accept);
	}
	
	$self->{useragent};
}

sub _prepare_request
{
	my $self = shift;
	my ($endpoint, $opts) = @_;
	
	my $method = uc($opts->{QueryMethod} // '');
	if ($method !~ /^(get|post|patch)$/i)
	{
		$method = (length $self->{'query'} > 511) ? 'POST' : 'GET';
	}
	
	my $param = $opts->{QueryParameter} // 'query';
	
	my $uri = '';
	my $cnt = '';
	if ($method eq 'GET')
	{
		$uri  = $endpoint . ($endpoint =~ /\?/ ? '&' : '?');
		$uri .= sprintf(
			"%s=%s",
			uri_escape($param),
			uri_escape($self->{query})
		);
		if ($opts->{Parameters})
		{
			foreach my $field (keys %{$opts->{Parameters}})
			{
				$uri .= sprintf(
					"&%s=%s",
					uri_escape($field),
					uri_escape($opts->{Parameters}->{$field}),
				);
			}
		}
	}
	elsif ($method eq 'POST')
	{
		$uri  = $endpoint;
		$cnt  = sprintf(
			"%s=%s",
			uri_escape($param),
			uri_escape($self->{query})
		);
		if ($opts->{Parameters})
		{
			foreach my $field (keys %{$opts->{Parameters}})
			{
				$cnt .= sprintf(
					"&%s=%s",
					uri_escape($field),
					uri_escape($opts->{Parameters}{$field}),
				);
			}
		}
	}
	
	my $req = HTTP::Request->new($method => $uri);
	
	my $type = $opts->{ContentType} // '';
	if ($type =~ m{^application/sparql-query}i)
	{
		$req->content_type('application/sparql-query');
		$req->content($self->{query});
	}
	elsif ($type =~ m{^application/sparql-update}i)
	{
		$req->content_type('application/sparql-update');
		$req->content($self->{query});
	}
	else
	{
		$req->content_type('application/x-www-form-urlencoded');
		$req->content($cnt);
	}
	
	$req->authorization_basic($opts->{AuthUsername}, $opts->{AuthPassword})
		if defined $opts->{AuthUsername};
	
	foreach my $k (keys %{$opts->{Headers}})
	{
		$req->header($k => $opts->{Headers}{$k});
	}
	
	$req;
}

sub _create_iterator
{
	my $self = shift;
	my ($response) = @_;
	
	unless ($response->is_success)
	{
		$self->{error} = $response->message;
		return;
	}
	
	if ($response->content_type =~ /sparql.results/)
	{
		local $@ = undef;
		my $iterator = eval
		{
			if ($response->content_type =~ /json/)
				{ RDF::Trine::Iterator->from_json($response->decoded_content); }
			else
				{ RDF::Trine::Iterator->from_string($response->decoded_content); }
		};
		return $iterator
			if $iterator;
		
		$self->{error} = $@;
		return;
	}
	else
	{
		my $model;
		eval
		{
			my $parser = RDF::Trine::Parser->parser_by_media_type($response->content_type);
			my $tmp    = RDF::Trine::Model->temporary_model;
			$parser->parse_into_model($response->base, $response->decoded_content, $tmp);
			$model = $tmp;
		};
		
		return $model->as_stream if defined $model;
		
		$self->{error} = sprintf("Response of type '%s' could not be parsed.", $response->content_type);
		return;
	}
}

1;

__END__

=pod

=encoding utf8

=begin stopwords

'sparql'
application/sparql-query
application/sparql-update
application/x-www-form-urlencoded
rel
WebID

=end stopwords

=head1 NAME

RDF::Query::Client - get data from W3C SPARQL Protocol 1.0 servers

=head1 SYNOPSIS

 use RDF::Query::Client;
 
 my $query = RDF::Query::Client
               ->new('SELECT DISTINCT ?s WHERE { ?s ?p ?o . }');
 
 my $iterator = $query->execute('http://example.com/sparql');
 
 while (my $row = $iterator->next) {
    print $row->{s}->as_string;
 }

=head1 DESCRIPTION

=head2 Constructor

=over 4

=item C<< new ( $sparql, \%opts ) >>

Returns a new RDF::Query::Client object for the specified C<$sparql>.
The object's interface is designed to be roughly compatible with RDF::Query
objects, though RDF::Query is not required by this module.

Options include:

=over 4

=item B<UserAgent> - an LWP::UserAgent to handle HTTP requests.

=back 

Unlike RDF::Query, where you get a choice of query language, the query
language for RDF::Query::Client is always 'sparql'. RDF::TrineShortcuts offers
a way to perform RDQL queries on remote SPARQL stores though (by transforming
RDQL to SPARQL).

=back

=head2 Public Methods

=over 4

=item C<< execute ( $endpoint, \%opts ) >>

C<$endpoint> is a URI object or string containing the endpoint
URI to be queried.

Options include:

=over 4

=item * B<UserAgent> - an LWP::UserAgent to handle HTTP requests.

=item * B<QueryMethod> - 'GET', 'POST', 'PATCH' or undef (automatic).

=item * B<QueryParameter> - defaults to 'query'.

=item * B<AuthUsername> - HTTP Basic authorization.

=item * B<AuthPassword> - HTTP Basic authorization.

=item * B<Headers> - additional headers to include (hashref).

=item * B<Parameters> - additional GET/POST fields to include (hashref).

=item * B<ContentType> - 'application/sparql-query',
'application/sparql-update' or 'application/x-www-form-urlencoded' (default).

=back

Returns undef on error; an RDF::Trine::Iterator if called in a
scalar context; an array obtained by calling C<get_all> on the
iterator if called in list context.

=item C<< discover_execute( $resource_uri, \%opts ) >>

Experimental feature. Discovers a SPARQL endpoint relevant to $resource_uri
and then calls C<< $query->execute >> against that. Uses an LRDD-like
method to discover the endpoint. If you're publishing data and want people
to be able to find your SPARQL endpoint automatically, the easiest way is to
include an Link header in HTTP responses:

 Link: </my/endpoint>; rel="http://ontologi.es/sparql#endpoint"

Change the URL in the angled brackets, but not the URL in the rel string.

This feature requires the HTTP::LRDD package to be installed.

=item C<< get ( $endpoint, \%opts ) >>

Executes the query using the specified endpoint, and returns the first
matching row as a LIST of values. Takes the same arguments as C<execute>.

=item C<< as_sparql >>

Returns the query as a string in the SPARQL syntax.

=item C<< useragent >>

Returns the LWP::UserAgent object used for retrieving web content.

=item C<< http_response >>

Returns the last HTTP Response the client experienced.

=item C<< error >>

Returns the last error the client experienced.

=back

=head2 Security

The C<execute> and C<get> methods allow AuthUsername and
AuthPassword options to be passed to them for HTTP Basic authentication.
For more complicated authentication (Digest, OAuth, Windows, etc),
it is also possible to pass these methods a customised LWP::UserAgent.

If you have the Crypt::SSLeay package installed, requests to HTTPS
endpoints should work. It's possible to specify a client X.509
certificate (e.g. for WebID authentication) by setting particular
environment variables. See L<Crypt::SSLeay> documentation for details.

=head1 BUGS

Probably.

Please report any you find here:
L<https://rt.cpan.org/Dist/Display.html?Queue=RDF-Query-Client>.

=head1 SEE ALSO

=over 4

=item * L<RDF::Trine>, L<RDF::Trine::Iterator>

=item * L<RDF::Query>

=item * L<LWP::UserAgent>

=item * L<http://www.w3.org/TR/rdf-sparql-protocol/>

=item * L<http://www.w3.org/TR/rdf-sparql-query/>

=item * L<http://www.perlrdf.org/>

=back

=head1 AUTHOR

Toby Inkster, E<lt>tobyink@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-2013 by Toby Inkster

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

=cut

