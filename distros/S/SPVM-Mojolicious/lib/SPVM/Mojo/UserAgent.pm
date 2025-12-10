package SPVM::Mojo::UserAgent;



1;

=encoding utf-8

=head1 Name

SPVM::Mojo::UserAgent - Non-blocking I/O HTTP and WebSocket user agent

=head1 Description

Mojo::UserAgent class in L<SPVM> is a full featured non-blocking I/O HTTP and WebSocket user agent, with IPv6, TLS, SNI, IDNA,
HTTP proxy, UNIX domain socket, Comet (long polling), Promises/A+, keep-alive, connection pooling, timeout,
cookie, multipart, gzip compression and multiple event loop support.

=head1 Usage

  use Mojo::UserAgent;

  # Fine grained response handling (dies on connection errors)
  my $ua  = Mojo::UserAgent->new;
  my $res = $ua->get("docs.mojolicious.org")->result;
  if    ($res->is_success)  { say $res->body }
  elsif ($res->is_error)    { say $res->message }
  elsif ($res->code == 301) { say $res->headers->location }
  else                      { say "Whatever..." }

  # Say hello to the Unicode snowman and include an Accept header
  say $ua->get("www.☃.net?hello=there" => {Accept => "*/*"})->result->body;

  # IPv6 PUT request with Content-Type header and content
  my $tx = $ua->put("[::1]:3000" => {"Content-Type" => "text/plain"} => "Hi!");

  # Quick JSON API request with Basic authentication
  my $url = (my $_ = Mojo::URL->new("https://example.com/test.json"), $_->set_userinfo("sri:☃"), $_);
  my $value = $ua->get($url)->result->json;

  # JSON POST (application/json) with TLS certificate authentication
  my $tx = ($ua->set_cert("tls.crt"), $ua->set_key("tls.key"), $ua->post("https://example.com" => [(object)json => {top => "secret"}]));

  # Form POST (application/x-www-form-urlencoded)
  my $tx = $ua->post("https://metacpan.org/search" => [(object)form => {q => "mojo"}]);

  # Search DuckDuckGo anonymously through Tor
  $ua->proxy->http("socks://127.0.0.1:9050");
  $ua->get("api.3g2upl4pq6kufc4m.onion/?q=mojolicious&format=json")->result->json;

  # GET request via UNIX domain socket "/tmp/myapp.sock" (percent encoded slash)
  say $ua->get("http+unix://%2Ftmp%2Fmyapp.sock/test")->result->body;

  # Follow redirects to download Mojolicious from GitHub
  ($ua->set_max_redirects(5),
    $ua->get("https://www.github.com/mojolicious/mojo/tarball/main")
    ->result->save_to("/home/sri/mojo.tar.gz"));

=head1 Class Methods

=head2 new

C<static method new : Mojo::UserAgent ();>

Create a new L<Mojo::UserAgent|SPVM::Mojo::UserAgent> object, and return it.

=head1 Instance Methods

=head2 build_tx

C<method build_tx : Mojo::Transaction::HTTP ($method : string, $url : string|L<Mojo::URL|SPVM::Mojo::URL>, $args : object...);>

Generate L<Mojo::Transaction::HTTP|SPVM::Mojo::Transaction::HTTP> object with L<Mojo::UserAgent::Transactor#tx|SPVM::Mojo::UserAgent::Transactor/"tx">.

Examples:

  my $tx = $ua->build_tx(GET => "example.com");
  my $tx = $ua->build_tx(PUT => "http://example.com" => {Accept => "*/*"} => "Content!");
  my $tx = $ua->build_tx(PUT => "http://example.com" => {Accept => "*/*"} => [(object)form => {a => "b"}]);
  my $tx = $ua->build_tx(PUT => "http://example.com" => {Accept => "*/*"} => [(object)json => {a => "b"}]);

  # Request with custom cookie
  my $tx = $ua->build_tx(GET => "https://example.com/account");
  $tx->req->cookies({name => "user", value => "sri"});
  $tx = $ua->start($tx);

  # Deactivate gzip compression
  my $tx = $ua->build_tx(GET => "example.com");
  $tx->req->headers->remove("Accept-Encoding");
  $tx = $ua->start($tx);

  # Interrupt response by raising an error
  my $tx = $ua->build_tx(GET => "http://example.com");
  $tx->res->on(progress => method ($res : Mojo::Message::Response) {
    unless (my $server = $res->headers->server) {
      return;
    }
    
    if (Re->m($server, "IIS")) {
      die "Oh noes, it is IIS!";
    }
  });
  $tx = $ua->start($tx);

=head2 build_websocket_tx

Not yet implemented.

=head2 delete

C<method delete : Mojo::Transaction::HTTP ($url : string|L<Mojo::URL|SPVM::Mojo::URL>, $args : object...);>

Perform blocking C<DELETE> request and return resulting L<Mojo::Transaction::HTTP|SPVM::Mojo::Transaction::HTTP> object, takes the same arguments as
L<Mojo::UserAgent::Transactor/"tx"> (except for the C<DELETE> method, which is implied).

Examples:

  my $tx = $ua->delete("example.com");
  my $tx = $ua->delete("http://example.com" => {Accept => "*/*"} => "Content!");
  my $tx = $ua->delete("http://example.com" => {Accept => "*/*"} => [(object)form => {a => "b"}]);
  my $tx = $ua->delete("http://example.com" => {Accept => "*/*"} => [(object)json => {a => "b"}]);

=head2 get

C<method get : Mojo::Transaction::HTTP ($url : string|L<Mojo::URL|SPVM::Mojo::URL>, $args : object...);>

Perform blocking C<GET> request and return resulting L<Mojo::Transaction::HTTP|SPVM::Mojo::Transaction::HTTP> object, takes the same arguments as
L<Mojo::UserAgent::Transactor/"tx"> (except for the C<GET> method, which is implied).

Examples:

  my $tx = $ua->get("example.com");
  my $tx = $ua->get("http://example.com" => {Accept => "*/*"} => "Content!");
  my $tx = $ua->get("http://example.com" => {Accept => "*/*"} => [(object)form => {a => "b"}]);
  my $tx = $ua->get("http://example.com" => {Accept => "*/*"} => [(object)json => {a => "b"}]);

=head2 head

C<method head : Mojo::Transaction::HTTP ($url : string|L<Mojo::URL|SPVM::Mojo::URL>, $args : object...);>

Perform blocking C<HEAD> request and return resulting L<Mojo::Transaction::HTTP|SPVM::Mojo::Transaction::HTTP> object, takes the same arguments as
L<Mojo::UserAgent::Transactor/"tx"> (except for the C<HEAD> method, which is implied).

Examples:

  my $tx = $ua->head("example.com");
  my $tx = $ua->head("http://example.com" => {Accept => "*/*"} => "Content!");
  my $tx = $ua->head("http://example.com" => {Accept => "*/*"} => [(object)form => {a => "b"}]);
  my $tx = $ua->head("http://example.com" => {Accept => "*/*"} => [(object)json => {a => "b"}]);

=head2 options

C<method options : Mojo::Transaction::HTTP ($url : string|L<Mojo::URL|SPVM::Mojo::URL>, $args : object...);>

Perform blocking C<OPTIONS> request and return resulting L<Mojo::Transaction::HTTP|SPVM::Mojo::Transaction::HTTP> object, takes the same arguments as
L<Mojo::UserAgent::Transactor/"tx"> (except for the C<OPTIONS> method, which is implied).

Examples:

  my $tx = $ua->options("example.com");
  my $tx = $ua->options("http://example.com" => {Accept => "*/*"} => "Content!");
  my $tx = $ua->options("http://example.com" => {Accept => "*/*"} => [(object)form => {a => "b"}]);
  my $tx = $ua->options("http://example.com" => {Accept => "*/*"} => [(object)json => {a => "b"}]);

=head2 patch

C<method patch : Mojo::Transaction::HTTP ($url : string|L<Mojo::URL|SPVM::Mojo::URL>, $args : object...);>

Perform blocking C<PATCH> request and return resulting L<Mojo::Transaction::HTTP|SPVM::Mojo::Transaction::HTTP> object, takes the same arguments as
L<Mojo::UserAgent::Transactor/"tx"> (except for the C<PATCH> method, which is implied).

Examples:

  my $tx = $ua->patch("example.com");
  my $tx = $ua->patch("http://example.com" => {Accept => "*/*"} => "Content!");
  my $tx = $ua->patch("http://example.com" => {Accept => "*/*"} => [(object)form => {a => "b"}]);
  my $tx = $ua->patch("http://example.com" => {Accept => "*/*"} => [(object)json => {a => "b"}]);

=head2 post

C<method post : Mojo::Transaction::HTTP ($url : string|L<Mojo::URL|SPVM::Mojo::URL>, $args : object...);>

Perform blocking C<POST> request and return resulting L<Mojo::Transaction::HTTP|SPVM::Mojo::Transaction::HTTP> object, takes the same arguments as
L<Mojo::UserAgent::Transactor/"tx"> (except for the C<POST> method, which is implied).

Examples:

  my $tx = $ua->post("example.com");
  my $tx = $ua->post("http://example.com" => {Accept => "*/*"} => "Content!");
  my $tx = $ua->post("http://example.com" => {Accept => "*/*"} => [(object)form => {a => "b"}]);
  my $tx = $ua->post("http://example.com" => {Accept => "*/*"} => [(object)json => {a => "b"}]);

=head2 put

C<method put : Mojo::Transaction::HTTP ($url : string|L<Mojo::URL|SPVM::Mojo::URL>, $args : object...);>

Perform blocking C<PUT> request and return resulting L<Mojo::Transaction::HTTP|SPVM::Mojo::Transaction::HTTP> object, takes the same arguments as
L<Mojo::UserAgent::Transactor/"tx"> (except for the C<PUT> method, which is implied).

Examples:

  my $tx = $ua->put("example.com");
  my $tx = $ua->put("http://example.com" => {Accept => "*/*"} => "Content!");
  my $tx = $ua->put("http://example.com" => {Accept => "*/*"} => [(object)form => {a => "b"}]);
  my $tx = $ua->put("http://example.com" => {Accept => "*/*"} => [(object)json => {a => "b"}]);

=head2 start

C<method start : Mojo::Transaction::HTTP ($tx : Mojo::Transaction::HTTP);>

Perform blocking request for a custom L<Mojo::Transaction::HTTP|SPVM::Mojo::Transaction::HTTP> object, which can be prepared manually or with
L</"build_tx">.

Examples:

  my $tx = $ua->start(Mojo::Transaction::HTTP->new);

=head2 websocket

Not yet implemented.

=head1 See Also

=over 2

=item * L<SPVM::Mojolicious>

=back

=head1 Copyright & License

Copyright (c) 2025 Yuki Kimoto

MIT License

