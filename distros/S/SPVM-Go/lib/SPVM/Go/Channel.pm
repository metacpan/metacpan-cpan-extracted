package SPVM::Go::Channel;



1;

=head1 Name

SPVM::Go::Channel - Golang Compatible Channel

=head1 Description

The Go::Channel class in L<SPVM> has methods to manipulate channels.

=head1 Usage

  use Go;
  
  # A non-buffered channel
  my $channel = Go->make;
  
  # A buffered channel
  my $channel = Go->make(3);
  
  # Read channel
  my $ok = 0;
  my $value = $channel->read(\$ok);
  
  # Write channel
  $channel->write($value);

=head1 Instance Methods

=head2 read

C<method read : object ($ok_ref : int*);>

Reads a value from the channel. If the value is red from a closed channl, undef is returned.

If the channel is closed and any written values do not exist, the value referred by $ok_ref is set to 0, otherwise it is set to 1.

=head2 write

C<method write : void ($value : object);>

Writes a value to the channel. If the buffer is full, this method blocks until the value is red or there is free buffer space.

Exceptions:

If this channel is closed, an exception is thrown.

=head2 close

C<method close : void ();>

Closes the channel. A closed channel cannot be writen.

Exceptions:

If this channel is already closed, an exception is thrown.

=head2 cap

C<method cap : int ();>

Gets the buffer capacity of the channel.

=head2 len

C<method len : int ();>

Gets the length of the values in the buffer.

=head1 Copyright & License

Copyright (c) 2023 Yuki Kimoto

MIT License

