package SPVM::UV::StdioContainer;



1;

=encoding utf8

=head1 Name

L<SPVM::UV::StdioContainer|SPVM::UV::StdioContainer> - libuv Stdio Container

=head1 Description

C<UV::StdioContainer> class in L<SPVM> represents a stdio container used in L<libuv|https://libuv.org/> process spawning. See L<uv_stdio_container_t|https://docs.libuv.org/en/v1.x/process.html#c.uv_stdio_container_t>.

=head1 Usage

  use UV::StdioContainer;
  use UV::Constant as UV_C;

  my $container = UV::StdioContainer->new;
  $container->set_flags(UV_C->UV_INHERIT_FD);
  $container->set_fd(0);

=head1 Fields

=head2 stream

C<has stream : L<UV::Handle::Stream|SPVM::UV::Handle::Stream>;>

A stream associated with this stdio container.

=head1 Class Methods

=head2 new

C<static method new : L<UV::StdioContainer|SPVM::UV::StdioContainer> ();>

Creates a new L<libuv stdio container|https://docs.libuv.org/en/v1.x/process.html#c.uv_stdio_container_t>.

=head1 Instance Methods

=head2 flags

C<method flags : int ();>

Gets the flags of the container. See L<uv_stdio_flags|https://docs.libuv.org/en/v1.x/process.html#c.uv_stdio_flags>.

=head2 set_flags

C<method set_flags : void ($flags : int);>

Sets the flags of the container.

=head2 stream

C<method stream : L<UV::Handle::Stream|SPVM::UV::Handle::Stream> ();>

Gets the stream of the container.

Exceptions:

If flags is not C<UV_CREATE_PIPE> or C<UV_INHERIT_STREAM>, an exception is thrown.

=head2 set_stream

C<method set_stream : void ($stream : L<UV::Handle::Stream|SPVM::UV::Handle::Stream>);>

Sets the stream of the container.

Exceptions:

If flags is not C<UV_CREATE_PIPE> or C<UV_INHERIT_STREAM>, an exception is thrown.

=head2 fd

C<method fd : int ();>

Gets the file descriptor of the container.

Exceptions:

If flags is not C<UV_INHERIT_FD>, an exception is thrown.

=head2 set_fd

C<method set_fd : void ($fd : int);>

Sets the file descriptor of the container.

Exceptions:

If flags is not C<UV_INHERIT_FD>, an exception is thrown.

=head2 DESTROY

C<method DESTROY : void ();>

Destroys the container and releases its resources.

=head1 Repository

Yuki Kimoto C<kimoto.yuki@gmail.com>

=head1 Copyright & License

Copyright (c) 2026 Yuki Kimoto

MIT License
