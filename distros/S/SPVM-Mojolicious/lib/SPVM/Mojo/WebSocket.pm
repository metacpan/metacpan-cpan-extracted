package SPVM::Mojo::WebSocket;



1;

=head1 Name

SPVM::Mojo::WebSocket - The WebSocket protocol

=head1 Description

Mojo::WebSocket class in L<SPVM> has methods to do someting.

=head1 Usage

  use Mojo::WebSocket;
  
  my $bytes = Mojo::WebSocket->build_frame($frame);
  my $frame =  Mojo::WebSocket->parse_frame(\$bytes, 262144);

=head1 Enumerations

=head2 WS_BINARY

Opcode for C<Binary> frames.

=head2 WS_CLOSE

Opcode for C<Close> frames.

=head2 WS_CONTINUATION

Opcode for C<Continuation> frames.

=head2 WS_PING

Opcode for C<Ping> frames.

=head2 WS_PONG

Opcode for C<Pong> frames.

=head2 WS_TEXT

Opcode for C<Text> frames.

=head1 Class Methods

=head2 build_frame

C<static method build_frame : string  ($frame : L<Mojo::WebSocket::Frame|SPVM::Mojo::WebSocket::Frame>);>

Build WebSocket frame.

Examples:

  # Masked binary frame with FIN bit and payload
  say Mojo::WebSocket->build_frame(Mojo::WebSocket::Frame->new(1, 1, 0, 0, 0, Mojo::WebSocket->WS_BINARY, "Hello World!"));

  # Text frame with payload but without FIN bit
  say Mojo::WebSocket->build_frame(Mojo::WebSocket::Frame->new(0, 0, 0, 0, 0, Mojo::WebSocket->WS_TEXT, "Hello "));

  # Continuation frame with FIN bit and payload
  say Mojo::WebSocket->build_frame(Mojo::WebSocket::Frame->new(0, 1, 0, 0, 0, Mojo::WebSocket->WS_CONTINUATION, "World!"));

  # Close frame with FIN bit and without payload
  say Mojo::WebSocket->build_frame(Mojo::WebSocket::Frame->new(0, 1, 0, 0, 0, Mojo::WebSocket->WS_CLOSE, ""));

  # Ping frame with FIN bit and payload
  say Mojo::WebSocket->build_frame(Mojo::WebSocket::Frame->new(0, 1, 0, 0, 0, Mojo::WebSocket->WS_PING, "Test 123"));

  # Pong frame with FIN bit and payload
  say Mojo::WebSocket->build_frame(Mojo::WebSocket::Frame->new(0, 1, 0, 0, 0, Mojo::WebSocket->WS_PONG, "Test 123"));

=head2 challenge

C<static method challenge : string ($tx : L<Mojo::Transaction::WebSocket|SPVM::Mojo::Transaction::WebSocket>);>

Check WebSocket handshake challenge.

C<static method client_handshake : L<Mojo::Transaction::HTTP|SPVM::Mojo::Transaction::HTTP> ($tx : L<Mojo::Transaction::HTTP|SPVM::Mojo::Transaction::HTTP>);>

=head2 parse_frame

C<static method parse_frame : L<Mojo::WebSocket::Frame|SPVM::Mojo::WebSocket::Frame> ($buffer_ref : string[], $max : int);>

=head2 server_handshake

C<static method server_handshake : L<Mojo::Transaction::HTTP|SPVM::Mojo::Transaction::HTTP> ($tx : L<Mojo::Transaction::HTTP|SPVM::Mojo::Transaction::HTTP>);>

=head1 See Also

=over 2

=item * L<Mojo::Transaction::WebSocket|SPVM::Mojo::Transaction::WebSocket>

=item * L<SPVM::Mojolicious>

=back

=head1 Copyright & License

Copyright (c) 2025 Yuki Kimoto

MIT License
