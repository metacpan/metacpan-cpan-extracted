package SPVM::Mojo::UserAgent::Transactor;



1;

=head1 Name

SPVM::Mojo::UserAgent::Transactor - User agent transactor

=head1 Description

Mojo::UserAgent::Transactor class in L<SPVM> is the transaction building and manipulation framework used by L<Mojo::UserAgent|SPVM::Mojo::UserAgent>.

=head1 Usage

  use Mojo::UserAgent::Transactor;

  # GET request with Accept header
  my $t = Mojo::UserAgent::Transactor->new;
  say $t->tx(GET => "http://example.com" => {Accept => "*/*"})->req->to_string;

  # POST request with form-data
  say $t->tx(POST => "example.com" => [(object)form => {a => "b"}])->req->to_string;

  # PUT request with JSON data
  say $t->tx(PUT => "example.com" => [(object)json => {a => "b"}])->req->to_string;

=head1 Generators

These content generators are available by default.

=head2 form

  $t->tx(POST => "http://example.com" => [(object)form => {a => "b"}]);

Generate query string, C<application/x-www-form-urlencoded> or C<multipart/form-data> content. See L</"tx"> for more.

=head2 json

  $t->tx(PATCH => "http://example.com" => [(object)json => {a => "b"}]);

Generate JSON content with L<JSON|SPVM::JSON>. See L</"tx"> for more.

=head2 multipart

  $t->tx(PUT => "http://example.com" => [(object)multipart => ["Hello", "World!"]]);

Generate multipart content. See L</"tx"> for more.

=head1 Fields

=head2 compressed

C<has compressed : rw byte;>

Try to negotiate compression for the response content and decompress it automatically, defaults to the value of the
C<SPVM_MOJO_GZIP> environment variable or true.

=head2 generators

C<has generators : rw Hash of L<Mojo::UserAgent::Transactor::Callback::Generator|SPVM::Mojo::UserAgent::Transactor::Callback::Generator>;>

Registered content generators, by default only C<form>, C<json> and C<multipart> are already defined.

=head2 name

C<has name : rw string;>

Value for C<User-Agent> request header of generated transactions, defaults to C<Mojolicious (SPVM)>.

=head1 Class Methods

C<static method new : L<Mojo::UserAgent::Transactor|SPVM::Mojo::UserAgent::Transactor> ();>

Create a new L<Mojo::UserAgent::Transactor|SPVM::Mojo::UserAgent::Transactor> object, and return it.

=head1 Instance Methods

=head2 add_generator

C<method add_generator : void ($name : string, $cb : L<Mojo::UserAgent::Transactor::Callback::Generator|SPVM::Mojo::UserAgent::Transactor::Callback::Generator>);>

Register a content generator.

Examples:

  $t->add_generator(foo => method : void ($t : Mojo::UserAgent::Transactor, $tx : Mojo::Transaction, $arg : object) {});

=head2 download

Not yet implemented.

=head2 endpoint

C<method endpoint : L<Mojo::UserAgent::Transactor::Endpoint|SPVM::Mojo::UserAgent::Transactor::Endpoint> ($tx : Mojo::Transaction);>

Actual endpoint for transaction.

=head2 peer

C<method peer : L<Mojo::UserAgent::Transactor::Endpoint|SPVM::Mojo::UserAgent::Transactor::Endpoint> ($tx : L<Mojo::Transaction::HTTP|SPVM::Mojo::Transaction::HTTP>);>

Actual peer for transaction.

=head2 proxy_connect

C<method proxy_connect : L<Mojo::Transaction::HTTP|SPVM::Mojo::Transaction::HTTP> ($old : L<Mojo::Transaction::HTTP|SPVM::Mojo::Transaction::HTTP>);>

=head2 promisify

Not yet implemented.

=head2 redirect

C<method redirect : L<Mojo::Transaction::HTTP|SPVM::Mojo::Transaction::HTTP> ($old : L<Mojo::Transaction::HTTP|SPVM::Mojo::Transaction::HTTP>);>

Build L<Mojo::Transaction::HTTP|SPVM::Mojo::Transaction::HTTP> follow-up request for C<301>, C<302>, C<303>, C<307> or C<308> redirect response if
possible.

=head2 tx

C<method tx : Mojo::Transaction::HTTP ($method : string, $url : string|Mojo::URL, $args : object...);>

Versatile general purpose L<Mojo::Transaction::HTTP|SPVM::Mojo::Transaction::HTTP> transaction builder for requests, with support for
L</"Generators">.

Examples:

  my $tx = $t->tx(GET  => "example.com");
  my $tx = $t->tx(POST => "http://example.com");
  my $tx = $t->tx(GET  => "http://example.com" => {Accept => "*/*"});
  my $tx = $t->tx(PUT  => "http://example.com" => "Content!");
  my $tx = $t->tx(PUT  => "http://example.com" => [(object)form => {a => "b"}]);
  my $tx = $t->tx(PUT  => "http://example.com" => [(object)json => {a => "b"}]);
  my $tx = $t->tx(PUT  => "https://example.com" => [(object)multipart => ["a", "b"]]);
  my $tx = $t->tx(POST => "example.com" => {Accept => "*/*"} => "Content!");
  my $tx = $t->tx(PUT => "example.com" => {Accept => "*/*"} => [(object)form => {a => "b"}]);
  my $tx = $t->tx(PUT => "example.com" => {Accept => "*/*"} => [(object)json => {a => "b"}]);
  my $tx = $t->tx(PUT => "example.com" => {Accept => "*/*"} => [(object)multipart => ["a", "b"]]);

  # Generate and inspect custom GET request with DNT header and content
  say $t->tx(GET => "example.com" => {DNT => 1} => "Bye!")->req->to_string;

  # Stream response content to STDOUT
  my $tx = $t->tx(GET => "http://example.com");
  (my $_ = $tx->res->content, $_->unsubscribe("read"), $_->on(read => method : void ($chunk : string) { say $string }));

  # PUT request with content streamed from file
  my $tx = $t->tx(PUT => "http://example.com");
  $tx->req->content->asset((my $_ = Mojo::Asset::File->new, $_->set_path("/foo.txt"), $_));

The C<json> content generator uses L<JSON|SPVM::JSON> for encoding and sets the content type to C<application/json>.

  # POST request with "application/json" content
  my $tx = $t->tx(POST => "http://example.com" => [(object)json => {a => "b", c => [1, 2, 3]]});

The C<form> content generator will automatically use query parameters for C<GET> and C<HEAD> requests.

  # GET request with query parameters
  my $tx = $t->tx(GET => "http://example.com" => [(object)form => {a => "b"}]);

For all other request methods the C<application/x-www-form-urlencoded> content type is used.

  # POST request with "application/x-www-form-urlencoded" content
  my $tx = $t->tx(POST => "http://example.com" => [(object)form => {a => "b", c => "d"}]);

Parameters may be encoded with the C<foo> option.

  # PUT request with Shift_JIS encoded form values
  my $tx = $t->tx(PUT => "example.com" => [(object)form => {a => "b"} => {foo => "value"}]);

An array reference can be used for multiple form values sharing the same name.

  # POST request with form values sharing the same name
  my $tx = $t->tx(POST => "http://example.com" => [(object)form => {a => ["b", "c", "d"]]});

A hash reference with a C<content> or C<file> value can be used to switch to the C<multipart/form-data> content type
for file uploads.

  # POST request with "multipart/form-data" content
  my $tx = $t->tx(POST => "http://example.com" => [(object)form => {mytext => {content => "lala"}]});

  # POST request with multiple files sharing the same name
  my $tx = $t->tx(POST => "http://example.com" => [(object)form => {mytext => [{content => "first"}, {content => "second"}]]});

The C<file> value should contain the path to the file you want to upload or an asset object, like L<Mojo::Asset::File|SPVM::Mojo::Asset::Memory>
or L<Mojo::Asset::Memory|SPVM::Mojo::Asset::Memory>.

  # POST request with upload streamed from file
  my $tx = $t->tx(POST => "http://example.com" => [(object)form => {mytext => {file => "/foo.txt"}]});

  # POST request with upload streamed from asset
  my $asset = (my $_ = Mojo::Asset::Memory->new, $_->add_chunk("lalala"), $_);
  my $tx    = $t->tx(POST => "http://example.com" => [(object)form => {mytext => {file => $asset}]});

A C<filename> value will be generated automatically, but can also be set manually if necessary. All remaining values in
the hash reference get merged into the C<multipart/form-data> content as headers.

  # POST request with form values and customized upload (filename and header)
  my $tx = $t->tx(POST => "http://example.com" => [(object)form => {
    a      => "b",
    c      => "d",
    mytext => {
      content        => "lalala",
      filename       => "foo.txt",
      "Content-Type" => "text/plain"
    }
  }]);

The C<multipart/form-data> content type can also be enforced by setting the C<Content-Type> header manually.

  # Force "multipart/form-data"
  my $headers = {"Content-Type" => "multipart/form-data"};
  my $tx = $t->tx(POST => "example.com" => $headers => [(object)form => {a => "b"}]);

The C<multipart> content generator can be used to build custom multipart requests and does not set a content type.

  # POST request with multipart content ("foo" and "bar")
  my $tx = $t->tx(POST => "http://example.com" => [(object)multipart => ["foo", "bar"]]);

Similar to the C<form> content generator you can also pass hash references with C<content> or C<file> values, as well
as headers.

  # POST request with multipart content streamed from file
  my $tx = $t->tx(POST => "http://example.com" => [(object)multipart => [{file => "/foo.txt"}]]);

  # PUT request with multipart content streamed from asset
  my $headers = {"Content-Type" => "multipart/custom"};
  my $asset   = (my $_ = Mojo::Asset::Memory->new, $_->add_chunk("lalala"), $_);
  my $tx      = $t->tx(PUT => "http://example.com" => $headers => [(object)multipart => [{file => $asset}]]);

  # POST request with multipart content and custom headers
  my $tx = $t->tx(POST => "http://example.com" => [(object)multipart => [
    {
      content            => "Hello",
      "Content-Type"     => "text/plain",
      "Content-Language" => "en-US"
    },
    {
      content            => "World!",
      "Content-Type"     => "text/plain",
      "Content-Language" => "en-US"
    }
  ]]);

=head2 upgrade

C<method upgrade : L<Mojo::Transaction::WebSocket|SPVM::Mojo::Transaction::WebSocket> ($tx : L<Mojo::Transaction::HTTP|SPVM::Mojo::Transaction::HTTP>);>

Build L<Mojo::Transaction::WebSocket|SPVM::Mojo::Transaction::WebSocket> follow-up transaction for WebSocket handshake if possible.

=head1 See Also

=over 2

=item * L<Mojo::UserAgent|SPVM::Mojo::UserAgent>

=item * L<SPVM::Mojolicious>

=back

=head1 Copyright & License

Copyright (c) 2025 Yuki Kimoto

MIT License

