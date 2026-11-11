package SPVM::UV::Handle::Stream;



1;

=encoding utf8

=head1 Name

SPVM::UV::Handle::Stream - Stream Handle for libuv

=head1 Description

C<UV::Handle::Stream> in L<SPVM> represents the stream handle for L<libuv|https://libuv.org/>, corresponding to the C<uv_stream_t> structure.

=head1 Super Class

L<UV::Handle|SPVM::UV::Handle>

=head1 Usage

  use UV::Handle::Stream;

=head1 Fields

=head2 read_cb

C<has read_cb : rw L<UV::Callback::Read|SPVM::UV::Callback::Read>;>

The callback called when data has been read from the stream.

=head2 read_buffer

C<has read_buffer : rw mutable string;>

The buffer associated with the read operation.

=head2 read_buffer_length

C<has read_buffer_length : rw int;>

The length of the read buffer.

=head2 read_buffer_offset

C<has read_buffer_offset : rw int;>

The offset of the read buffer.

=head1 Instance Methods

=head2 read_start

C<method read_start : void ($buffer : mutable string, $buffer_length : int, $cb : L<UV::Callback::Read|SPVM::UV::Callback::Read>, $buffer_offset : int = 0);>

Starts reading data into C<$buffer> with length C<$buffer_length> and offset C<$buffer_offset> from the stream. 

The callback C<$cb> is stored in L</"read_cb"> field. The buffer C<$buffer> is stored in L</"read_buffer"> field. The length C<$buffer_length> is stored in L</"read_buffer_length"> field. The offset C<$buffer_offset> is stored in L</"read_buffer_offset"> field.

The callback C<$cb> is invoked when data has been read from the stream.

This method calls the L<uv_read_start|https://docs.libuv.org/en/v1.x/stream.html#c.uv_read_start> function internally.

Exceptions:

If $buffer is not defined, an exception is thrown.

If $buffer_length is not a positive number, an exception is thrown.

If $buffer_offset + $buffer_length is greater than the length of C<$buffer>, an exception is thrown.

If $cb is not defined, an exception is thrown.

If uv_read_start> fails, an exception is thrown.

=head2 read_stop

C<method read_stop : void ();>

Stops reading data from the stream.

This method calls the L<uv_read_stop|https://docs.libuv.org/en/v1.x/stream.html#c.uv_read_stop> function internally.

Exceptions:

If uv_read_stop fails, an exception is thrown.

=head1 Copyright & License

Copyright (c) 2026 Yuki Kimoto

MIT License
