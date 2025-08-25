package SPVM::Mojo::Transaction::HTTP;



1;

=head1 Name

SPVM::Mojo::Transaction::HTTP - HTTP transaction

=head1 Description

Mojo::Transaction::HTTP class in L<SPVM> has methods to do someting.

=head1 Usage

  use Mojo::Transaction::HTTP;

  # Client
  my $tx = Mojo::Transaction::HTTP->new;
  $tx->req->set_method("GET");
  $tx->req->url->parse("http://example.com");
  $tx->req->headers->set_accept("application/json");
  say $tx->res->code;
  say $tx->res->headers->content_type;
  say $tx->res->body;
  say $tx->remote_address;

  # Server
  my $tx = Mojo::Transaction::HTTP->new;
  say $tx->req->method;
  say $tx->req->url->to_abs;
  say $tx->req->headers->accept;
  say $tx->remote_address;
  $tx->res->set_code(200);
  $tx->res->headers->set_content_type("text/plain");
  $tx->res->set_body("Hello World!");

=head1 Super Class

L<Mojo::Transaction|SPVM::Mojo::Transaction>

=head1 Events

=head2 request

Emitted when a request is ready and needs to be handled.

Callback:

C<method : void ($tx : L<Mojo::Transaction::HTTP|SPVM::Mojo::Transaction::HTTP>);>

Examples:

  $tx->on(request => method : void ($tx : Mojo::Transaction::HTTP) {
    
  });

=head2 resume

Emitted when transaction is resumed.

Callback:

C<method : void ($tx : L<Mojo::Transaction::HTTP|SPVM::Mojo::Transaction::HTTP>);>

Examples:

  $tx->on(resume => method : void ($tx : Mojo::Transaction::HTTP) {
    
  });

=head2 unexpected

Emitted for unexpected C<1xx> responses that will be ignored.

Callback:

C<method : void ($tx : L<Mojo::Transaction::HTTP|SPVM::Mojo::Transaction::HTTP>, $res : L<Mojo::Message::Response|SPVM::Mojo::Message::Response>);>

Examples:

  $tx->on(unexpected => method : void ($tx : Mojo::Transaction::HTTP, $res : Mojo::Message::Response) {
    
  });

=head1 Fields

C<has previous : rw L<Mojo::Transaction::HTTP|SPVM::Mojo::Transaction::HTTP>;>

Previous transaction that triggered this follow-up transaction, usually a L<Mojo::Transaction::HTTP|SPVM::Mojo::Transaction::HTTP> object.

  # Paths of previous requests
  say $tx->previous->previous->req->url->path;
  say $tx->previous->req->url->path;

=head1 Class Methods

C<static method new : L<Mojo::Transaction::HTTP|SPVM::Mojo::Transaction::HTTP> ();>

Create a new L<Mojo::Transaction::HTTP|SPVM::Mojo::Transaction::HTTP> object, and return it.

=head1 Instance Methods

=head2 client_read

C<method client_read : void ($chunk : string);>

Read data client-side, used to implement user agents such as L<Mojo::UserAgent|SPVM::Mojo::UserAgent>.

=head2 client_write

C<method client_write : string ($server : int);>

Write data client-side, used to implement user agents such as L<Mojo::UserAgent|SPVM::Mojo::UserAgent>.

=head2 is_empty

C<method is_empty : int ();>

Check transaction for C<HEAD> request and C<1xx>, C<204> or C<304> response.

=head2 keep_alive

C<method keep_alive : int ();>

Check if connection can be kept alive.

=head2 redirects

C<method redirects : L<Mojo::Transaction::HTTP|SPVM::Mojo::Transaction::HTTP>[] ();>

Return an array reference with all previous transactions that preceded this follow-up transaction.

Examples:

  # Paths of all previous requests
  for my $_ (@{$tx->redirects}) {
    say $_->req->url->path;
  }

=head2 resume

C<method resume : void ();>

Resume transaction.

=head2 server_read

C<method server_read : void ($chunk : string);>

Read data server-side, used to implement web servers such as L<Mojo::Server::Daemon|SPVM::Mojo::Server::Daemon>.

=head2 server_write

C<method server_write : string ($server : int);>

Write data server-side, used to implement web servers such as L<Mojo::Server::Daemon|SPVM::Mojo::Server::Daemon>.

=head1 See Also

=over 2

=item * L<SPVM::Mojolicious>

=back

=head1 Copyright & License

Copyright (c) 2025 Yuki Kimoto

MIT License
