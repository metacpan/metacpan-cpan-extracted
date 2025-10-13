package SPVM::Mojo::Transaction::WebSocket;



1;

=head1 Name

SPVM::Mojo::Transaction::WebSocket - WebSocket transaction

=head1 Description

Mojo::Transaction::WebSocket class in L<SPVM> is a container for WebSocket transactions, based on L<RFC
6455|https://tools.ietf.org/html/rfc6455> and L<RFC 7692|https://tools.ietf.org/html/rfc7692>.

=head1 Usage

  use Mojo::Transaction::WebSocket;
  
  # Send and receive WebSocket messages
  my $ws = Mojo::Transaction::WebSocket->new;
  $ws->send("Hello World!");
  $ws->on(message => method : void ($ws : Mojo::Transaction::WebSocket, $msg : string) { say "Message: $msg"; });
  $ws->on(finish => method : void ($ws : Mojo::Transaction::WebSocket, $code : Int, $reason : string) { say "WebSocket closed with status " . (int)$code . "."; });

=head1 Super Class

L<Mojo::Transaction|SPVM::Mojo::Transaction>

=head1 Events

=head2 binary

Emitted when a complete WebSocket binary message has been received.

Callback:

C<method : void ($ws : L<Mojo::Transaction::WebSocket|SPVM::Mojo::Transaction::WebSocket>, $bytes : string);>

Examples:

  $ws->on(binary => method : void ($ws : Mojo::Transaction::WebSocket, $bytes : string) { say "Binary: $bytes"; });

=head2 drain

Emitted once all data has been sent.

Callback:

C<method : void ($ws : L<Mojo::Transaction::WebSocket|SPVM::Mojo::Transaction::WebSocket>);>

Examples:

  $ws->on(drain => method : void ($ws : Mojo::Transaction::WebSocket) { $ws->send(time) });

=head2 finish

Emitted when the WebSocket connection has been closed.

Callback:

C<method : void ($ws : L<Mojo::Transaction::WebSocket|SPVM::Mojo::Transaction::WebSocket>, $code : int, $reason : string);>

Examples:

  $ws->on(finish => method : void ($ws : Mojo::Transaction::WebSocket, $code : int, $reason : string) {});

=head2 frame

Emitted when a WebSocket frame has been received.

Callback:

C<method : void ($ws : L<Mojo::Transaction::WebSocket|SPVM::Mojo::Transaction::WebSocket>, $frame : L<Mojo::WebSocket::Frame|SPVM::Mojo::WebSocket::Frame>);>

Examples:

  $ws->on(frame => method : void ($ws : Mojo::Transaction::WebSocket, $frame : Mojo::WebSocket::Frame) {
    
  });

=head2 json

Emitted when a complete WebSocket message has been received, all text and binary messages will be automatically JSON
decoded. Note that this event only gets emitted when it has at least one subscriber.

Callback:

C<method : void ($ws : L<Mojo::Transaction::WebSocket|SPVM::Mojo::Transaction::WebSocket>, $json : object);>

Examples:

  $ws->on(json => method : void ($ws : Mojo::Transaction::WebSocket, $hash : object) { say "Message: " . $hash->(Hash)->{"msg"}->(string); });

=head2 message

Emitted when a complete WebSocket message has been received, text messages will be automatically decoded. Note that
this event only gets emitted when it has at least one subscriber.

Callback:

C<method : void ($ws : L<Mojo::Transaction::WebSocket|SPVM::Mojo::Transaction::WebSocket>, $msg);>

Examples:

  $ws->on(message => method : void ($ws : Mojo::Transaction::WebSocket, $msg) { say "Message: $msg"; });

=head2 resume

Emitted when transaction is resumed.

Callback:

C<method : void ($ws : L<Mojo::Transaction::WebSocket|SPVM::Mojo::Transaction::WebSocket>);>

Examples:

  $tx->on(resume => method : void ($ws : Mojo::Transaction::WebSocket) {});

=head2 text

Emitted when a complete WebSocket text message has been received.

Callback:

C<method : void ($ws : L<Mojo::Transaction::WebSocket|SPVM::Mojo::Transaction::WebSocket>, $bytes : string);>

Examples:

  $ws->on(text => method : void ($ws : Mojo::Transaction::WebSocket, $bytes : string) { say "Text: $bytes"; });

=head1 Fields

=head2 compressed

C<has compressed : rw byte;>

Compress messages with C<permessage-deflate> extension.

=head2 established

C<has established : rw byte;>

WebSocket connection established.

=head2 handshake

C<has handshake : rw L<Mojo::Transaction::HTTP|SPVM::Mojo::Transaction::HTTP>;>

The original handshake transaction, usually a L<Mojo::Transaction::HTTP|SPVM::Mojo::Transaction::HTTP> object.

=head2 masked

C<has masked : rw byte;>

Mask outgoing frames with XOR cipher and a random 32-bit key.

=head2 max_websocket_size

C<has max_websocket_size : rw int;>

Maximum WebSocket message size in bytes, defaults to the value of the C<SPVM_MOJO_MAX_WEBSOCKET_SIZE> environment variable
or C<262144> (256KiB).

=head1 Class Methods

C<static method new : L<Mojo::Transaction::WebSocket|SPVM::Mojo::Transaction::WebSocket> ();>

Create a new L<Mojo::Transaction::WebSocket|SPVM::Mojo::Transaction::WebSocket> object, and return it.

=head1 Instance Methods

=head2 build_message

C<method build_message : Mojo::WebSocket::Frame ($msg : string|object[]);>

Build WebSocket message.

Examples:

  my $frame = $ws->build_message({binary => $bytes});
  my $frame = $ws->build_message({text   => $bytes});
  my $frame = $ws->build_message({json   => $data});
  my $frame = $ws->build_message($chars);

=head2 client_read

C<method client_read : void ($chunk : string);>

Read data client-side, used to implement user agents such as L<Mojo::UserAgent|SPVM::Mojo::UserAgent>.

=head2 client_write

C<method client_write : string ();>

Write data client-side, used to implement user agents such as L<Mojo::UserAgent|SPVM::Mojo::UserAgent>.

=head2 closed

C<method closed : void ();>

Same as L<Mojo::Transaction#completed|SPVM::Mojo::Transaction/"completed">, but also indicates that all transaction data has been sent.

=head2 connection

C<method connection : L<Mojo::Connection|SPVM::Mojo::Connection> ();>

Connection identifier.

=head2 finish

C<method finish : void ($code : int = 0, $reason : string = undef);>

Close WebSocket connection gracefully.

Examples:

  $ws = $ws->finish;
  $ws = $ws->finish(1000);
  $ws = $ws->finish(1003 => "Cannot accept data!");

=head2 is_websocket

C<method is_websocket : int ();>

True, this is a L<Mojo::Transaction::WebSocket|SPVM::Mojo::Transaction::WebSocket> object.

=head2 kept_alive

C<method kept_alive : int ();>

Connection has been kept alive.

=head2 local_address

C<method local_address : string ();>

Local interface address.

=head2 local_port

C<method local_port : int ();>

Local interface port.

=head2 parse_message

C<method parse_message : void ($frame : L<Mojo::WebSocket::Frame|SPVM::Mojo::WebSocket::Frame>);>

Parse WebSocket message.

Examples:

  $ws->parse_message($frame);

=head2 protocol

C<method protocol : string ();>

Return negotiated subprotocol or C<undef>.

=head2 remote_address

C<method remote_address : string ();>

Remote interface address.

=head2 remote_port

C<method remote_port : int ();>

Remote interface port.

=head2 req

C<method req : Mojo::Message::Request ();>

Handshake request, usually a L<Mojo::Message::Request|SPVM::Mojo::Message::Response> object.

=head2 res

C<method res : Mojo::Message::Response ();>

Handshake response, usually a L<Mojo::Message::Response|SPVM::Mojo::Message::Response> object.

=head2 resume

C<method resume : void ();>

Resume L</"handshake"> transaction.

=head2 send

C<method send : void ($msg : string|object[]|L<Mojo::WebSocket::Frame|SPVM::Mojo::WebSocket::Frame>, $cb : L<Mojo::Callback|SPVM::Mojo::Callback> = undef);>

Send message or frame non-blocking via WebSocket, the optional drain callback will be executed once all data has been
written.

Examples:

  $ws = $ws->send({binary => $bytes});
  $ws = $ws->send({text   => $bytes});
  $ws = $ws->send({json   => $data);
  $ws = $ws->send($frame);
  $ws = $ws->send($chars);
  $ws = $ws->send($chars => method : void ($ws : Mojo::Transaction::WebSocket) {});

  # Send "Ping" frame
  $ws->send([1, 0, 0, 0, Mojo::WebSocket->WS_PING, 'Hello World!']);

=head2 server_read

C<method server_read : void ($chunk : string);>

Read data server-side, used to implement web servers such as L<Mojo::Server::Daemon|SPVM::Mojo::Server::Daemon>.

=head2 server_write

C<method server_write : string ();>

Write data server-side, used to implement web servers such as L<Mojo::Server::Daemon|SPVM::Mojo::Server::Daemon>.

=head2 with_compression

C<method with_compression : void ();>

Negotiate C<permessage-deflate> extension for this WebSocket connection.

=head2 with_protocols

C<method with_protocols : string ($protos : string[]);>

Negotiate subprotocol for this WebSocket connection.

=head1 See Also

=over 2

=item * L<SPVM::Mojolicious>

=back

=head1 Copyright & License

Copyright (c) 2025 Yuki Kimoto

MIT License
