package SPVM::Mojo::Transaction;



1;

=head1 Name

SPVM::Mojo::Transaction - Transaction base class

=head1 Description

Mojo::Transaction class in L<SPVM> is an abstract base class for transactions, like L<Mojo::Transaction::HTTP|SPVM::Mojo::Transaction::HTTP> and
L<Mojo::Transaction::WebSocket|SPVM::Mojo::Transaction::WebSocket>.

=head1 Usage

  class Mojo::Transaction::MyTransaction extends Mojo::Transaction {
  
  }
  
=head1 Super Class

L<Mojo::EventEmitter|SPVM::Mojo::EventEmitter>

=head1 Events

=head2 connection

Emitted when a connection has been assigned to transaction.

Examples:

  $tx->on(connection => method : void ($tx : Mojo::Transaction, $connection : string) {...});

=head2 finish

Emitted when transaction is finished.

Examples:

  $tx->on(finish => method : void ($tx : Mojo::Transaction) {...});

=head1 Fields

=head2 kept_alive

C<has kept_alive : rw byte;>

Connection has been kept alive.

=head2 local_address

C<has local_address : rw string;>

Local interface address.

=head2 local_port

C<has local_port : rw int;>

Local interface port.

=head2 original_remote_address

C<has original_remote_address : rw string;>

Remote interface address.

=head2 remote_address

C<has remote_address : virtual rw string;>

Same as L</"original_remote_address"> unless L</"req"> has been performed via a L<Mojo::Message::Request#reverse_proxy|SPVM::Mojo::Message::Request/"reverse_proxy">.
If so then the last value of C<X-Forwarded-For> header is returned. Additionally if
L<Mojo::Message::Request#trusted_proxies|SPVM::Mojo::Message::Request/"trusted_proxies"> are also provided then the original address must be trusted and any
C<X-Forwarded-For> entries that are trusted are ignored, returning the last untrusted address or the first address if
all are trusted.

=head2 remote_port

C<has remote_port : rw int;>

Remote interface port.

=head2 req

C<has req : rw L<Mojo::Message::Request|SPVM::Mojo::Message::Request>;>

HTTP request, defaults to a L<Mojo::Message::Request|SPVM::Mojo::Message::Request> object.

  # Access request information
  my $method = $tx->req->method;
  my $url    = $tx->req->url->to_abs;
  my $info   = $tx->req->url->to_abs->userinfo;
  my $host   = $tx->req->url->to_abs->host;
  my $agent  = $tx->req->headers->user_agent;
  my $custom = $tx->req->headers->header("Custom-Header");
  my $bytes  = $tx->req->body;
  my $str    = $tx->req->text;
  my $hash   = $tx->req->params->to_hash;
  my $all    = $tx->req->uploads;
  my $value  = $tx->req->json;

=head2 res

C<has res : rw L<Mojo::Message::Response|SPVM::Mojo::Message::Response>;>

HTTP response, defaults to a L<Mojo::Message::Response|SPVM::Mojo::Message::Response> object.

  # Access response information
  my $code    = $tx->res->code;
  my $message = $tx->res->message;
  my $server  = $tx->res->headers->server;
  my $custom  = $tx->res->headers->header("Custom-Header");
  my $bytes   = $tx->res->body;
  my $str     = $tx->res->text;
  my $value   = $tx->res->json;

=head2 connection

C<has connection : rw string;>

Connection identifier.

=head1 Class Methods

=head2 new

C<static method new : L<Mojo::Transaction|SPVM::Mojo::Transaction> ();>

Create a new L<Mojo::Transaction|SPVM::Mojo::Transaction> object, and return it.

=head1 Instance Methods

=head2 client_read

C<method client_read : void ($chunk : string);>

Read data client-side, used to implement user agents such as L<Mojo::UserAgent|SPVM::Mojo::UserAgent>. Meant to be overloaded in a subclass.

=head2 client_write
  
C<method client_write : string ($server : int);>

Write data client-side, used to implement user agents such as L<Mojo::UserAgent|SPVM::Mojo::UserAgent>. Meant to be overloaded in a subclass.

=head2 completed

C<method completed : void ();>

Low-level method to finalize transaction.

=head2 closed

C<method closed : void ();>

Same as L</"completed">, but also indicates that all transaction data has been sent.

=head2 is_finished

C<method is_finished : int ();>

Check if transaction is finished.

=head2 is_websocket

C<method is_websocket : int ();>

False, this is not a L<Mojo::Transaction::WebSocket> object.

=head2 result

C<method result : Mojo::Message::Response ();>

=head2 server_read

C<method server_read : void ($chunk : string);>

Read data server-side, used to implement web servers such as L<Mojo::Server::Daemon|SPVM::Mojo::Server::Daemon>. Meant to be overloaded in a
subclass.

=head2 server_write

C<method server_write : string ($server : int);>

Write data server-side, used to implement web servers such as L<Mojo::Server::Daemon|SPVM::Mojo::Server::Daemon>. Meant to be overloaded in a
subclass.

=head1 Well Known Child Classes

=over 2

=item * L<Mojo::Transaction::HTTP|SPVM::Mojo::Transaction::HTTP>

=item * L<Mojo::Transaction::WebSocket|SPVM::Mojo::Transaction::WebSocket>

=back

=head1 See Also

=over 2

=item * L<SPVM::Mojolicious>

=back

=head1 Copyright & License

Copyright (c) 2025 Yuki Kimoto

MIT License
