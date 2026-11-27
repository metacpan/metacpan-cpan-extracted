package SPVM::UV::Handle::TCP;



1;

=encoding utf8

=head1 Name

SPVM::UV::Handle::TCP - TCP Handle for libuv

=head1 Description

C<UV::Handle::TCP> in L<SPVM> represents the TCP handle for L<libuv|https://libuv.org/>, corresponding to the C<uv_tcp_t> structure.

=head1 Super Class

L<UV::Handle::Stream|SPVM::UV::Handle::Stream>

=head1 Usage

  use UV::Handle::TCP;
  
  my $tcp = UV::Handle::TCP->new;

=head1 Class Methods

=head2 new

C<static method new : L<UV::Handle::TCP|SPVM::UV::Handle::TCP> ();>

Creates a new L<UV::Handle::TCP|SPVM::UV::Handle::TCP> object, and returns it.

=head1 Instance Methods

=head2 open

C<method open : void ($fd : int);>

Associates an existing file descriptor C<$fd> with the TCP handle.

This method calls the L<uv_tcp_open|https://docs.libuv.org/en/v1.x/tcp.html#c.uv_tcp_open> function.

Exceptions:

If uv_tcp_open fails, an exception is thrown.

=head1 Copyright & License

Copyright (c) 2026 Yuki Kimoto

MIT License
