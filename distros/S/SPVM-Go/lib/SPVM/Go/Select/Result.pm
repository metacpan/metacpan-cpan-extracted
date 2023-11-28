package SPVM::Go::Select::Result;



1;

=head1 Name

SPVM::Go::Select::Result - Result of select

=head1 Description

Go::Select::Result class of L<SPVM> has methods to manipulate the result of select.

=head1 Usage

  use Go::Select::Result;

=head1 Fields

=head2 ok

C<has ok : ro byte;>

A ok flag got by the L<read|Go::Channel/"read"> method in the L<Go::Channel|SPVM::Go::Channel> class.

If the channel is a write channle, this value is always 1.

=head2 value

C<has value : ro object;>

A return value got by the L<read|Go::Channel/"read"> method in the L<Go::Channel|SPVM::Go::Channel> class.

=head2 channel

C<has channel : ro L<Go::Channel|SPVM::Go::Channel>;>

A channel.

=head2 is_write

C<has is_write : ro byte;>

A flag if the channel is a write channel.

If this flag is 0, the channel is a read channel.

=head1 Copyright & License

Copyright (c) 2023 Yuki Kimoto

MIT License

