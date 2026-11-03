package Monitoring::Sneck::Checks::http;

use 5.014;
use strict;
use warnings;
use parent 'Monitoring::Sneck::Checks::base';
use Time::HiRes ();

=head1 NAME

Monitoring::Sneck::Checks::http - checks a HTTP or HTTPS server

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

=head1 SYNOPSIS

    www|perl:http -H www.example.org -S -w 1 -c 2 -s 'Welcome'
    api|perl:http -u https://api.example.org/health -e 200 -r '"status":\s*"ok"'
    feed|perl:http -H www.example.org -u /feed.xml -x '//item'
    to_https|perl:http -H www.example.org -L https://www.example.org/
    hsts|perl:http -H www.example.org -S -E 'Strict-Transport-Security: max-age=[0-9]{8}' -E Content-Security-Policy

=head1 DESCRIPTION

Fetches a URL through L<LWP::UserAgent>. With no --expect, 2xx and 3xx
are OK, 4xx is WARNING, and anything else is CRITICAL, including not
being able to connect. Content that does not match is CRITICAL.

Certificates are checked for HTTPS unless --insecure is given. See
L<Monitoring::Sneck::Checks::https_cert> for when they expire.

=head1 OPTIONS

- -H, --hostname :: The host. Required unless --url is a whole URL.

- -u, --url :: The path, or a whole URL, in which case --hostname,
--port, and --ssl are ignored.
Default :: /

- -p, --port :: The port.
Default :: 80, or 443 with --ssl

- -S, --ssl :: Use HTTPS.

- -j, --method :: The method.
Default :: GET

- -P, --post :: Content to send, which makes the method POST unless
--method is given.

- -T, --content-type :: The type of what --post sends.
Default :: application/x-www-form-urlencoded

- -k, --header :: A header to send, as "Name: value". May be given more
than once.

- -e, --expect :: Status codes that are OK, comma separated. Anything
else is CRITICAL.

- -s, --string :: Text the content must have.

- -r, --regex :: A regex the content must match.

- --invert-regex :: The content must not match --regex.

- -x, --xpath :: A XPath expression that must find something in the
content, parsed as XML if it says it is, else as HTML.

- -f, --follow :: Follow up to 5 redirects.

- -E, --expect-header :: "Name", a header that must be there, or
"Name: regex", one that must match the regex. Names are not case
sensitive. May be given more than once.

- -L, --location :: Where it must redirect to. A relative one is taken
from the URL fetched, as is the Location header, so /login and
https://www.example.org/login are the same for https://www.example.org/.
No Location, or a different one, is CRITICAL. Can not be used with
--follow.

- -w, --warning :: Range of seconds for the response time.

- -c, --critical :: Range of seconds for the response time.

- --insecure :: Do not check the certificate.

- --ca-file :: The CA file to check the certificate against.

=cut

sub option_spec {
	return (
		'hostname|H=s', 'url|u=s',          'port|p=i',     'ssl|S',        'method|j=s',
		'post|P=s',     'content-type|T=s', 'header|k=s@',  'expect|e=s',   'string|s=s',
		'regex|r=s',    'invert-regex',     'xpath|x=s',    'location|L=s', 'expect-header|E=s@',
		'follow|f',     'warning|w=s',      'critical|c=s', 'insecure',     'ca-file=s',
	);
}

sub defaults { return { url => '/', 'content-type' => 'application/x-www-form-urlencoded' } }

sub ranges { return ( 'warning', 'critical' ) }

sub validate {
	my ( $self, $options ) = @_;

	my @problems;
	if ( !defined( $options->{hostname} ) && $options->{url} !~ m{\Ahttps?://}i ) {
		push( @problems, '--hostname is required unless --url is a whole URL' );
	}
	if ( defined( $options->{hostname} ) && !$self->is_host( $options->{hostname} ) ) {
		push( @problems, '--hostname "' . $options->{hostname} . '" is not a IP or hostname' );
	}
	foreach my $header ( @{ $options->{'expect-header'} // [] } ) {
		my ( $name, $regex ) = $header =~ /\A([^:\s]+)(?::\s*(.*))?\z/;
		if ( !defined($name) ) {
			push( @problems, '--expect-header "' . $header . '" is not Name or "Name: regex"' );
		} elsif ( defined($regex) && !eval { qr/$regex/; 1 } ) {
			push( @problems, '--expect-header "' . $header . '" does not have a valid regex' );
		}
	}
	push( @problems, '--location and --follow can not both be given' )
		if defined( $options->{location} ) && $options->{follow};
	if ( defined( $options->{expect} ) && $options->{expect} !~ /\A[0-9]{3}(?:,[0-9]{3})*\z/ ) {
		push( @problems, '--expect must be status codes, comma separated' );
	}
	if ( defined( $options->{regex} ) && !eval { qr/$options->{regex}/; 1 } ) {
		push( @problems, '--regex is not a valid regex' );
	}
	foreach my $header ( @{ $options->{header} // [] } ) {
		push( @problems, '--header "' . $header . '" is not "Name: value"' ) if $header !~ /\A[^:\s]+:/;
	}

	return @problems;
} ## end sub validate

=head1 METHODS

=head2 url

Returns the URL to fetch.

=cut

sub url {
	my ($self) = @_;

	my $url = $self->opt('url');
	return $url if $url =~ m{\Ahttps?://}i;

	my $host = $self->opt('hostname');
	$host = '[' . $host . ']' if $host =~ /:/;
	my $scheme = $self->opt('ssl')             ? 'https'                  : 'http';
	my $port   = defined( $self->opt('port') ) ? ':' . $self->opt('port') : '';
	$url = '/' . $url if $url !~ m{\A/};

	return $scheme . '://' . $host . $port . $url;
} ## end sub url

=head2 check

Does the check.

=cut

sub check {
	my ($self) = @_;

	require HTTP::Request;
	my $user_agent = $self->user_agent(
		insecure     => $self->opt('insecure'),
		ca_file      => $self->opt('ca-file'),
		max_redirect => $self->opt('follow') ? 5 : 0,
	);
	my $method  = $self->opt('method') // ( defined( $self->opt('post') ) ? 'POST' : 'GET' );
	my $request = HTTP::Request->new( uc($method), $self->url );
	foreach my $header ( @{ $self->opt('header') // [] } ) {
		my ( $name, $value ) = split( /:\s*/, $header, 2 );
		$request->header( $name => $value );
	}
	if ( defined( $self->opt('post') ) ) {
		$request->content_type( $self->opt('content-type') );
		$request->content( $self->opt('post') );
	}

	my $start    = Time::HiRes::time;
	my $response = $user_agent->request($request);
	my $seconds  = sprintf( '%.3f', Time::HiRes::time - $start );

	# LWP makes up a 500 when it never got a answer
	my $internal = ( $response->header('Client-Warning') // '' ) eq 'Internal response';
	if ($internal) {
		my $why = $response->message // 'failed';
		$why =~ s/\s+\z//;
		return $self->finish( $self->CRITICAL, $self->url . ', ' . $why );
	}

	my $content = $response->decoded_content // $response->content // '';
	my @codes   = ( $self->status_code( $response->code ) );
	my @problems;
	if ( $codes[0] != $self->OK ) {
		push( @problems, 'unexpected status' );
	}

	foreach my $found ( $self->content_problems( $response, $content ) ) {
		push( @codes,    $found->[0] );
		push( @problems, $found->[1] );
	}

	my $time_code = $self->threshold_status( $seconds, $self->opt('warning'), $self->opt('critical') );
	push( @codes,    $time_code );
	push( @problems, 'slow' ) if $time_code != $self->OK;

	$self->perfdata(
		label    => 'time',
		value    => $seconds,
		uom      => 's',
		warning  => $self->opt('warning'),
		critical => $self->opt('critical'),
		min      => 0
	);
	$self->perfdata( label => 'size', value => length( $response->content // '' ), uom => 'B', min => 0 );

	my $message
		= ( $response->protocol // 'HTTP' ) . ' '
		. $response->status_line . ' - '
		. length( $response->content // '' )
		. ' bytes in '
		. $seconds
		. ' seconds';
	$message = $message . ', ' . join( ', ', @problems ) if defined( $problems[0] );

	return $self->finish( $self->worst(@codes), $message );
} ## end sub check

=head2 content_problems

Checks the response as --location, --expect-header, --string, --regex,
and --xpath say.
A subclass may add its own checks to these.

- response :: The L<HTTP::Response>.

- content :: Its decoded content.

Returns a list of array refs of the code and what is wrong, one for
each problem.

    foreach my $found ( $check->content_problems( $response, $content ) ) {
        my ( $code, $problem ) = @{$found};
    }

=cut

sub content_problems {
	my ( $self, $response, $content ) = @_;

	my @found;
	if ( defined( $self->opt('location') ) ) {
		require URI;
		my $wanted  = URI->new_abs( $self->opt('location'), $self->url )->canonical->as_string;
		my $located = $response->header('Location');
		if ( !defined($located) ) {
			push( @found, [ $self->CRITICAL, 'no Location, wanted ' . $wanted ] );
		} elsif ( ( my $absolute = URI->new_abs( $located, $self->url )->canonical->as_string ) ne $wanted ) {
			push( @found, [ $self->CRITICAL, 'redirects to ' . $absolute . ', not ' . $wanted ] );
		}
	} ## end if ( defined( $self->opt('location') ) )
	foreach my $header ( @{ $self->opt('expect-header') // [] } ) {
		my ( $name, $regex ) = $header =~ /\A([^:\s]+)(?::\s*(.*))?\z/;
		my $value = $response->header($name);
		if ( !defined($value) ) {
			push( @found, [ $self->CRITICAL, 'no ' . $name . ' header' ] );
		} elsif ( defined($regex) && $value !~ /$regex/ ) {
			push( @found, [ $self->CRITICAL, $name . ' is "' . $value . '", not matching /' . $regex . '/' ] );
		}
	}
	if ( defined( $self->opt('string') ) && index( $content, $self->opt('string') ) < 0 ) {
		push( @found, [ $self->CRITICAL, 'did not find "' . $self->opt('string') . '"' ] );
	}
	if ( defined( $self->opt('regex') ) ) {
		my $regex   = $self->opt('regex');
		my $matched = ( $content =~ /$regex/ ) ? 1 : 0;
		if ( $matched xor !$self->opt('invert-regex') ) {
			push( @found, [ $self->CRITICAL, ( $matched ? 'matched' : 'did not match' ) . ' /' . $regex . '/' ] );
		}
	}
	if ( defined( $self->opt('xpath') ) && !$self->xpath_count( $response, $content ) ) {
		push( @found, [ $self->CRITICAL, 'XPath ' . $self->opt('xpath') . ' found nothing' ] );
	}

	return @found;
} ## end sub content_problems

=head2 status_code

Returns the code for a HTTP status, as said under L</DESCRIPTION>.

    $check->status_code(404);    # WARNING, unless --expect is given

=cut

sub status_code {
	my ( $self, $status ) = @_;

	if ( defined( $self->opt('expect') ) ) {
		my %expected = map { $_ => 1 } split( /,/, $self->opt('expect') );
		return $expected{$status} ? $self->OK : $self->CRITICAL;
	}
	return $self->OK      if $status >= 200 && $status < 400;
	return $self->WARNING if $status >= 400 && $status < 500;

	return $self->CRITICAL;
} ## end sub status_code

=head2 xpath_count

Returns how many nodes --xpath finds in the content of a response, 0
if it can not be parsed.

=cut

sub xpath_count {
	my ( $self, $response, $content ) = @_;

	require XML::LibXML;
	my $type     = $response->content_type // '';
	my $is_xml   = ( $type =~ /xml/ && $type !~ /html/ ) ? 1 : 0;
	my $document = eval {
		$is_xml
			? XML::LibXML->load_xml( string => $content, no_network => 1 )
			: XML::LibXML->load_html( string => $content, recover => 2, suppress_errors => 1, no_network => 1 );
	};
	return 0 if !defined($document);

	my $nodes = eval { $document->findnodes( $self->opt('xpath') ) };
	return 0 if !defined($nodes);

	return $nodes->size;
} ## end sub xpath_count

1;
