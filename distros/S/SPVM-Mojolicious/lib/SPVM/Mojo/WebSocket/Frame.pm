package SPVM::Mojo::WebSocket::Frame;



1;

=head1 Name

SPVM::Mojo::WebSocket::Frame - WebSocket frame

=head1 Description

Mojo::WebSocket::Frame class in L<SPVM> is a WebSocket frame.

=head1 Usage

  use Mojo::WebSocket::Frame;
  
  my $frame = Mojo::WebSocket::Frame->new($fin, $rsv1, $rsv2, $rsv3, $op, $payload);
  
=head1 Fields

=head2 fin

C<has fin : byte;>

=head2 rsv1

C<has rsv1 : byte;>

=head2 rsv2

C<has rsv2 : byte;>

=head2 rsv3

C<has rsv3 : byte;>

=head2 opcode

C<has opcode : byte;>

=head2 payload

C<has payload : string;>

=head2 mask

C<has mask : rw byte;>

=head1 Class Methods

C<static method new : L<Mojo::WebSocket::Frame|SPVM::Mojo::WebSocket::Frame> ($fin : int, $rsv1 : int, $rsv2 : int, $rsv3 : int, $opcode : int, $payload : string, $mask : int = -1);>

Create a new L<Mojo::WebSocket::Frame|SPVM::Mojo::WebSocket::Frame> object and return it.

=head1 See Also

=over 2

=item * L<Mojo::Transaction::WebSocket|SPVM::Mojo::Transaction::WebSocket>

=item * L<SPVM::Mojolicious>

=back

=head1 Copyright & License

Copyright (c) 2025 Yuki Kimoto

MIT License
