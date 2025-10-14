package SPVM::Mojo::Message::Request;



1;

=head1 Name

SPVM::Mojo::Message::Request - HTTP request

=head1 Description

Mojo::Message::Request class in L<SPVM> is a container for HTTP requests, based on L<RFC 7230|https://tools.ietf.org/html/rfc7230>,
L<RFC 7231|https://tools.ietf.org/html/rfc7231>, L<RFC 7235|https://tools.ietf.org/html/rfc7235> and L<RFC
2817|https://tools.ietf.org/html/rfc2817>.

=head1 Usage

  use Mojo::Message::Request;

  # Parse
  my $req = Mojo::Message::Request->new;
  $req->parse("GET /foo HTTP/1.0\x0d\x0a");
  $req->parse("Content-Length: 12\x0d\x0a");
  $req->parse("Content-Type: text/plain\x0d\x0a\x0d\x0a");
  $req->parse("Hello World!");
  say $req->method;
  say $req->headers->content_type;
  say $req->body;

  # Build
  my $req = Mojo::Message::Request->new;
  $req->url->parse("http://127.0.0.1/foo/bar");
  $req->set_method("GET");
  say $req->to_string;

=head1 Super Class

L<Mojo::Message|SPVM::Mojo::Message>

=head1 Fields

=head2 env

C<has env : rw L<Hash|SPVM::Hash> of string;>

Direct access to the C<CGI> or C<PSGI> environment hash if available.

  # Check CGI version
  my $version = $req->env->get("GATEWAY_INTERFACE");

  # Check PSGI version
  my $version = $req->env->get("psgi.version");

=head2 method

C<has method : rw string;>

HTTP request method, defaults to C<GET>.

=head2 proxy

C<has proxy : rw L<Mojo::URL|SPVM::Mojo::URL>;>

Proxy URL for request.

=head2 reverse_proxy

C<has reverse_proxy : rw byte;>

Request has been performed through a reverse proxy.

=head2 trusted_proxies

C<has trusted_proxies : rw string[];>

Trusted reverse proxies, addresses or networks in CIDR form.

=head2 request_id

C<has request_id : rw string;>

Request ID, defaults to a reasonably unique value.

=head2 url

C<has url : rw L<Mojo::URL|SPVM::Mojo::URL>;>

HTTP request URL, defaults to a L<Mojo::URL|SPVM::Mojo::URL> object.

  # Get request information
  my $info = $req->url->to_abs->userinfo;
  my $host = $req->url->to_abs->host;
  my $path = $req->url->to_abs->path;

=head2 via_proxy

C<has via_proxy : rw byte;>

Request can be performed through a proxy server.

=head1 Class Methods

=head2 new

C<static method new : L<Mojo::Message::Request|SPVM::Mojo::Message::Request> ();>

Create a new L<Mojo::Message::Request|SPVM::Mojo::Message::Request> object.

=head1 Instance Methods

=head2 clone

C<method clone : L<Mojo::Message::Request|SPVM::Mojo::Message::Request> ();>

Return a new L<Mojo::Message::Request|SPVM::Mojo::Message::Request> object cloned from this request if possible, otherwise return C<undef>.

=head2 cookies
  
C<method cookies : L<Mojo::Cookie::Request|SPVM::Mojo::Cookie::Request>[] ();>

Get request cookies, usually L<Mojo::Cookie::Request|SPVM::Mojo::Cookie::Request> objects.

  # Names of all cookies
  for my $_ (@{$req->cookies}) {
    say $_->name ;
  }

=head2 set_cookies

C<method set_cookies : void ($cookies : L<Mojo::Cookie::Request|SPVM::Mojo::Cookie::Request>[]);>

Set request cookies, usually L<Mojo::Cookie::Request|SPVM::Mojo::Cookie::Request> objects.

=head2 every_param

C<method every_param : string[] ($name : string);>

Similar to L</"param">, but returns all values sharing the same name as an array reference.

  # Get first value
  say $req->every_param("foo")->[0];

=head2 extract_start_line
  
C<method extract_start_line : int ($buf : mutable string);>

Extract request-line from string.

=head2 fix_headers

C<method fix_headers : void ();>

Make sure request has all required headers.

=head2 get_start_line_chunk

C<method get_start_line_chunk : string ($offset : int);>

Get a chunk of request-line data starting from a specific position. Note that this method finalizes the request.

=head2 is_handshake

C<method is_handshake : int ();>

Check C<Upgrade> header for C<websocket> value.

=head2 is_secure

C<method is_secure : int ();>

Check if connection is secure.

=head2 is_xhr

C<method is_xhr : int ();>

Check C<X-Requested-With> header for C<XMLHttpRequest> value.

=head2 param

C<method param : string ($name : string);>

Access C<GET> and C<POST> parameters extracted from the query string and C<application/x-www-form-urlencoded> or
C<multipart/form-data> message body. If there are multiple values sharing the same name, and you want to access more
than just the last one, you can use L</"every_param">. Note that this method caches all data, so it should not be
called before the entire request body has been received. Parts of the request body need to be loaded into memory to
parse C<POST> parameters, so you have to make sure it is not excessively large. There's a 16MiB limit for requests by
default.

=head2 params

C<method params : L<Mojo::Parameters|SPVM::Mojo::Parameters> ();>

All C<GET> and C<POST> parameters extracted from the query string and C<application/x-www-form-urlencoded> or
C<multipart/form-data> message body, usually a L<Mojo::Parameters|SPVM::Mojo::Parameters> object. Note that this method caches all data, so it
should not be called before the entire request body has been received. Parts of the request body need to be loaded into
memory to parse C<POST> parameters, so you have to make sure it is not excessively large. There's a 16MiB limit for
requests by default.

  # Get parameter names and values
  my $hash = $req->params->to_hash;

=head2 parse

C<method parse : void ($chunk : string, $env : Hash of string = undef);>

Parse HTTP request chunks or environment hash.

=head2 query_params

C<method query_params : L<Mojo::Parameters|SPVM::Mojo::Parameters> ();>

All C<GET> parameters, usually a L<Mojo::Parameters|SPVM::Mojo::Parameters> object.

  # Turn GET parameters to hash and extract value
  say $req->query_params->to_hash->get("foo");

=head1 See Also

=over 2

=item * L<SPVM::Mojolicious>

=back

=head1 Copyright & License

Copyright (c) 2025 Yuki Kimoto

MIT License
