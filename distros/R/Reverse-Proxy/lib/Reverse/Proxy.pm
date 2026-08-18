package Reverse::Proxy;

use 5.008003;
use strict;
use warnings;
use Carp ();
use Fetch;

our $VERSION = '0.04';

require XSLoader;
XSLoader::load('Reverse::Proxy', $VERSION);

Carp::croak(
	"Reverse::Proxy requires Fetch built with its C ABI (Fetch 0.05 or later); "
	. "please upgrade or reinstall Fetch"
) unless _abi_ok();

1;

__END__

=head1 NAME

Reverse::Proxy - a generic, non-blocking PSGI reverse proxy

=head1 VERSION

Version 0.04

=head1 SYNOPSIS

	use Reverse::Proxy;

	# forward a whole app to one backend
	my $app = Reverse::Proxy->new(
	    upstream => 'http://127.0.0.1:3000',
	)->to_app;

	# path-prefix routing to several backends (longest prefix wins)
	my $app = Reverse::Proxy->new(
	    routes => [
	        '/api' => 'http://api-backend:3000',
	        '/'    => 'http://web-backend:8080',
	    ],
	)->to_app;

	# dynamic target per request
	my $app = Reverse::Proxy->new(
	    resolver => sub {
	        my $env = shift;
	        return $env->{HTTP_HOST} =~ /^admin\./
	            ? 'http://admin:9000' : 'http://public:8080';
	    },
	)->to_app;

Run it under any PSGI server; on Hyperman it forwards without blocking:

	plackup -s Hyperman -e 'use Reverse::Proxy; Reverse::Proxy->new(upstream => "http://127.0.0.1:3000")->to_app'

=head1 DESCRIPTION

C<Reverse::Proxy> is a PSGI application that forwards each request to an upstream
HTTP backend and returns the reply, using L<Fetch> as the client. The whole
request path - target resolution, header rebuild, body, dispatch, response
mapping, streaming and WebSocket/Upgrade tunnelling - runs in C through Fetch's
C ABI.

It runs on any PSGI server. On L<Hyperman> - which advertises C<psgix.loop> and
C<psgi.nonblocking> - it forwards with Fetch running on the worker's own event
loop and hands the server back a L<Fetch::Future>, so a single worker proxies
many concurrent requests without a thread or process each. On other servers it
makes a blocking Fetch call per request. Either way it reuses one keep-alive
connection pool to the upstream per worker.

Standard proxy behaviour is handled for you: hop-by-hop headers (C<Connection>,
C<Keep-Alive>, C<TE>, C<Trailer>, C<Transfer-Encoding>, C<Upgrade>,
C<Proxy-Authenticate>, C<Proxy-Authorization>, and anything the client's
C<Connection> header names) are stripped in both directions; C<X-Forwarded-For>,
C<X-Forwarded-Proto> and C<X-Forwarded-Host> are appended; multi-valued response
headers such as C<Set-Cookie> are preserved; and an unreachable or failing
upstream yields a C<502>.

=head2 The forwarded request target

C<PATH_INFO> reaches a PSGI application percent-B<decoded>, and the request
target is written into a request line that terminates at the first space or
CRLF. So the path is re-encoded on the way out: any byte at or below C<0x20>,
C<0x7f> and above, and C<%>, C<#> and C<?> go back to C<%XX>.

That is a security boundary, not tidiness. Forwarding the decoded bytes
verbatim would let a client whose URL contains C<%0d%0a> end the request line
and write a second, complete request onto the upstream connection - request
smuggling, past whatever the proxy in front of it enforces. Re-encoding rather
than rejecting also means a path that decoded to a space is still forwarded as
the path that was asked for.

C<QUERY_STRING> is B<not> decoded by the PSGI spec, so it is forwarded byte for
byte, with the same control-byte encoding applied and nothing else.

One thing the encoding cannot restore: a C<%2F> in the client's URL is already
a plain C</> by the time any PSGI application sees it, so an upstream that
distinguishes the two cannot be told apart through this or any other PSGI
proxy.

=head1 CONSTRUCTOR

=head2 new(%opts)

Exactly one target selector is required:

=over 4

=item C<upstream> => $base_url

Forward every request to C<$base_url> (C<scheme://host[:port][/prefix]>). The
request's C<PATH_INFO> and C<QUERY_STRING> are appended.

=item C<routes> => [ $prefix => $base_url, ... ]

Route by C<PATH_INFO> prefix; the longest matching prefix wins and is stripped
from the forwarded path. A C<'/'> prefix acts as a catch-all.

=item C<resolver> => sub { my $env = shift; ... }

Return a base URL (or C<undef> for a 404) per request.

=back

Options: C<preserve_host> (default false - when true forward the client Host
unchanged, otherwise set Host from the upstream URL), C<timeout> (default 30
seconds), C<tls_verify> (default true, for C<https> upstreams), C<via>
(default C<'Reverse::Proxy'> - the C<Via> header value, C<undef> to omit),
C<pool_size> (default 64 - size of the keep-alive connection pool to the
upstream; raise it towards your peak concurrency so busy workers reuse
connections instead of opening fresh ones), and C<stream> (default false - see
L</STREAMING>).

=head2 to_app

Return the PSGI C<$app> coderef.

=head1 STREAMING

By default a response is buffered and returned whole. Pass C<< stream => 1 >>
to forward the body chunk-by-chunk instead: the proxy uses Fetch's
C<on_headers> to send the status and headers as soon as they arrive, then a
C<psgi.streaming> writer to pass each body chunk straight through as Fetch
delivers it. Nothing is buffered, so large downloads and endless
server-sent-event streams flow with flat memory. On Hyperman this runs on the
worker's loop (non-blocking); elsewhere it streams within a blocking request.

	my $app = Reverse::Proxy->new(upstream => 'http://sse:9000', stream => 1)->to_app;

=head1 WEBSOCKETS AND UPGRADE

Requests carrying an C<Upgrade> header (C<Connection: Upgrade>) - WebSocket and
any other protocol upgrade - are tunnelled transparently: the proxy hijacks the
client socket (C<psgix.io>), replays the raw Upgrade request to the upstream,
relays the upstream's C<101> back to the client, then splices bytes both ways
until either side closes. Frames, ping/pong, fragmentation and close pass
through untouched, so no WebSocket framing is parsed.

This needs a server that provides C<psgix.io> (Hyperman does); elsewhere an
Upgrade request gets a C<501>. The tunnel is blocking for its lifetime and
occupies one worker, so run enough workers for your expected concurrent
upgrades. Both plaintext (C<ws://> / C<http://>) and TLS (C<wss://> /
C<https://>) upstreams are supported - a TLS upstream reuses Fetch's own client
TLS, honouring C<tls_verify>.

=head1 LIMITATIONS

The upgrade tunnel is blocking: it holds one worker for the connection's
lifetime. A non-blocking, loop-driven byte splice (so a Hyperman worker is not
tied up for the tunnel's duration) is planned.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 BUGS

Please report any bugs or feature requests to C<bug-reverse-proxy at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Reverse-Proxy>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Reverse::Proxy

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Reverse-Proxy>

=item * Search CPAN

L<https://metacpan.org/release/Reverse-Proxy>

=back

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
