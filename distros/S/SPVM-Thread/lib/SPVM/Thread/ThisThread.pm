package SPVM::Thread::ThisThread;

1;

=head1 Name

SPVM::Thread::ThisThread - Getting Current Thread Information

=head1 Usage

  use Thread::ThisThread;
  
  my $current_thread_id = Thread::ThisThread->get_id;

=head1 Description

Thread::ThisThread class in L<SPVM> has methods to get information of the current thread.

This class is a binding of L<std::this_thread in C++|https://en.cppreference.com/w/cpp/thread>.

=head1 Class Methods

C<static method get_id : L<Thread::ID|SPVM::Thread::ID> ();>

Gets the thread ID of the current thread.

=head2 See Also

=over 2

=item * L<Thread|SPVM::Thread>

=item * L<Thread::ID|SPVM::Thread::ID>

=item * L<std::this_thread in C++|https://en.cppreference.com/w/cpp/thread>

=back

=head1 Copyright & License

Copyright 2022-2022 Yuki Kimoto, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

