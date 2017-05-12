use 5.014;
use strict;
use warnings;

package Plack::Middleware::MockProxyFrontend;
$Plack::Middleware::MockProxyFrontend::VERSION = '0.002';
# ABSTRACT: virtualhost-aware PSGI app developer tool

use parent 'Plack::Middleware';
use Plack::Util::Accessor qw( host_acceptor http_server _ssl_context );
use URI::Split ();
use Plack::Util ();
use IO::Socket::SSL ();

sub new {
	my $class = shift;
	my $self = $class->SUPER::new( @_ );

	$self->_ssl_context( IO::Socket::SSL::SSL_Context->new(
		( map { /^SSL_/ ? ( $_, $self->{ $_ } ) : () } keys %$self ),
		SSL_server => 1,
	) );

	$self->http_server( do {
		require HTTP::Server::PSGI;
		HTTP::Server::PSGI->new;
	} ) unless $self->http_server;

	$self;
}

sub call {
	my $self = shift;
	my $env = shift;

	my ( $scheme, $auth, $path, $query, $client_fh );

	if ( 'CONNECT' eq $env->{'REQUEST_METHOD'} ) {
		$client_fh = $env->{'psgix.io'}
			or return [ 405, [], ['CONNECT is not supported'] ];
		$auth = $env->{'REQUEST_URI'};
		$scheme = 'https';
	}
	else {
		( $scheme, $auth, $path, $query ) = URI::Split::uri_split $env->{'REQUEST_URI'};
		return [ 400, [], ['Not a proxy request'] ] if not $scheme;
		return [ 400, [], ['Non-HTTP(S) requests are unsupported'] ] if $scheme !~ /\Ahttps?\z/i;
	}

	my ( $host, $port ) = ( lc $auth ) =~ m{^(?:.+\@)?(.+?)(?::(\d+))?$};
	$port //= 'https' eq lc $scheme ? 443 : 80;

	my $acceptor = $self->host_acceptor;
	return [ 403, [], ['Refused by MockProxyFrontend'] ]
		if $acceptor and not grep $acceptor->( $host ), $host;

	$client_fh
		? sub {
			my $writer = shift->( [ 200, [] ] );

			my $conn = IO::Socket::SSL->new_from_fd(
				fileno $client_fh,
				SSL_server    => 1,
				SSL_reuse_ctx => $self->_ssl_context,
			);

			$self->http_server->handle_connection( {
				'psgi.url_scheme' => $scheme,
				SERVER_NAME       => $host,
				SERVER_PORT       => $port,
				SCRIPT_NAME       => '',
				'psgix.io'        => $conn,
				# pass-through
				REMOTE_ADDR    => $env->{'REMOTE_ADDR'},
				REMOTE_PORT    => $env->{'REMOTE_PORT'},
				'psgi.errors'  => $env->{'psgi.errors'},
				'psgi.version' => $env->{'psgi.version'},
				# constants
				'psgi.run_once'        => Plack::Util::TRUE,
				'psgi.multithread'     => Plack::Util::FALSE,
				'psgi.multiprocess'    => Plack::Util::FALSE,
				'psgi.streaming'       => Plack::Util::TRUE,
				'psgi.nonblocking'     => Plack::Util::FALSE,
				'psgix.input.buffered' => Plack::Util::TRUE,
			}, $conn, $self->app );

			$conn->close;
			$writer->close;
		}
		: $self->app->( {
			%$env,
			'psgi.url_scheme' => $scheme,
			HTTP_HOST         => $host,
			SERVER_PORT       => $port,
			REQUEST_URI       => ( join '?', $path, $query // () ),
			PATH_INFO         => $path =~ s!%([0-9]{2})!chr hex $1!rge,
		} );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Plack::Middleware::MockProxyFrontend - virtualhost-aware PSGI app developer tool

=head1 VERSION

version 0.002

=head1 SYNOPSIS

 # in app.psgi
 use Plack::Builder;
 
 builder {
     enable 'MockProxyFrontend',
         SSL_key_file  => 'key.pem',
         SSL_cert_file => 'cert.pem';
     $app;
 };

=head1 DESCRIPTION

This middleware implements the HTTP proxy protocolE<hellip> without the proxy:
it passes every request down to the wrapped PSGI application. Your application
becomes the browser's entire internet: no matter which address you navigate to,
the response comes from the wrapped PSGI application.

This is useful in the development of PSGI applications that do virtual hosting,
i.e. dispatching on hostname. Instead of testing your application by going to
C<http://localhost:5000/>, you go to C<https://example.com/> (or whatever your
site is). Your application will see a request for C<https://example.com/>, not
C<http://localhost:5000/>, e.g. when your framework generates absolute links.
And then when the page loads, the browser will think it is showing you the real
C<https://example.com/>, e.g. in the address bar.

The way this works is that instead of typing C<http://localhost:5000/> into the
browser's address bar to test your app (or wherever your development server is
listening), you put C<localhost:5000> as the HTTP/HTTPS proxy in the browser's
configuration. Then I<any> URL you navigate to will end up being served by your
application, so e.g. absolute links to C<https://example.com/> will just work.

=head1 NOTE

If you use L<plackup> to start your application, use C<--no-default-middleware>
to prevent it wrapping L<Plack::Middleware::Lint> around this middleware. Lint
reacts badly to a browser speaking the proxy protocol to it.

Generally MockProxyFrontend ought to be the outermost middleware in your stack.
Most other middlewares will work OK when confronted with the proxy protocol,
but they are not really designed for it, so it is best to convert the request
to a normal HTTP request as soon as possible.

=head1 CONFIGURATION OPTIONS

=over 4

=item C<SSL_*>

Configuration options for L<IO::Socket::SSL> that will be used to construct an
SSL context.

You don't need to pass any of these unless you need SSL support.
If you need it, C<SSL_key_file> and C<SSL_cert_file> are probably the options
you are looking for.

Note that SSL support requires a PSGI server that implements the C<psgix.io>
extension.

=item C<host_acceptor>

A function that will be called to decide whether to serve a request.
If it returns false, the request will be refused, otherwise it will be served.
The function will be passed the (lowercased) hostname from the request,
both as its sole argument and in C<$_>. E.g.:

 enable 'MockProxyFrontend',
     host_acceptor => sub { 'webmonkeys.io' eq $_ };

Defaults to accepting all requests.

=item C<http_server>

An object that responds to C<< $self->handle_connection( $env, $socket, $app ) >>.
This will be passed the connection from C<CONNECT> requests. E.g.:

 enable 'MockProxyFrontend',
     http_server => do {
         require Starlet::Server;
         Starlet::Server->new
     };

Defaults to an instance of L<HTTP::Server::PSGI>.

=back

=head1 BUGS AND LIMITATIONS

Error checking and attitude toward security is lackadaiscal.

There are B<NO TESTS> because I wouldn't know how to write them.

This was written as a developer tool, not for deployment anywhere that could be
described as production. Otherwise I wouldn't be releasing it in this state.

Use at your own risk.

Mind you, I am anything but opposed to fixing these problems E<ndash> I am just
not losing sleep over them. Patches welcome and highly appreciated.

=head1 AUTHOR

Aristotle Pagaltzis <pagaltzis@gmx.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Aristotle Pagaltzis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
