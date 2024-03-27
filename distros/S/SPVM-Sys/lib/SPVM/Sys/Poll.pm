package SPVM::Sys::Poll;

1;

=head1 Name

SPVM::Sys::Poll - Poll System Call

=head1 Usage
  
  use Sys::Poll;

=head1 Description

C<Sys::Poll> is the class for the poll function.

=head1 Class Methods

=head2 poll

C<static method poll : int ($fds : L<Sys::Poll::PollfdArray|SPVM::Sys::Poll::PollfdArray>, $nfds : int, $timeout : int);>

poll() performs a similar task to select(2): it waits for one of a set of file descriptors to become ready to perform I/O.

See the L<poll|https://linux.die.net/man/2/poll> function in Linux.

The file discritors are a L<Sys::Poll::PollfdArray|SPVM::Sys::Poll::PollfdArray> object.

=head1 Copyright & License

Copyright (c) 2023 Yuki Kimoto

MIT License

