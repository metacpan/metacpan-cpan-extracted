package SPVM::Thread::ID;

1;

=head1 Name

SPVM::Thread::ID - Thread ID

=head1 Usage

  use Thread::ID;
  
  my $result = Thread::ID->eq($thread_id1, $thread_id2);

=head1 Description

Thread::ID class in L<SPVM> has methods to compare thread IDs.

This class is a binding of L<std::thread::id in C++|https://en.cppreference.com/w/cpp/thread/thread/id>.

=head1 Class Methods

=head2 eq

C<static method eq : int ($thread_id1 : L<Thread::ID|SPVM::Thread::ID>, $thread_id2 : L<Thread::ID|SPVM::Thread::ID>);>

Checks if the thread ID $thread_id1 is equal to the thread ID $thread_id2.

If the check is ok, returns 1, otherwise returns 0.

=head2 ne

C<static method ne : int ($thread_id1 : L<Thread::ID|SPVM::Thread::ID>, $thread_id2 : L<Thread::ID|SPVM::Thread::ID>);>

Checks if the thread ID $thread_id1 is not equal to the thread ID $thread_id2.

If the check is ok, returns 1, otherwise returns 0.

=head2 gt

C<static method gt : int ($thread_id1 : L<Thread::ID|SPVM::Thread::ID>, $thread_id2 : L<Thread::ID|SPVM::Thread::ID>);>

Checks if the thread ID $thread_id1 is greater than the thread ID $thread_id2.

If the check is ok, returns 1, otherwise returns 0.

=head2 ge

C<static method ge : int ($thread_id1 : L<Thread::ID|SPVM::Thread::ID>, $thread_id2 : L<Thread::ID|SPVM::Thread::ID>);>

Checks if the thread ID $thread_id1 is greater than or equal to the thread ID $thread_id2.

If the check is ok, returns 1, otherwise returns 0.

=head2 lt

C<static method lt : int ($thread_id1 : L<Thread::ID|SPVM::Thread::ID>, $thread_id2 : L<Thread::ID|SPVM::Thread::ID>);>

Checks if the thread ID $thread_id1 is less than the thread ID $thread_id2.

If the check is ok, returns 1, otherwise returns 0.

=head2 le

C<static method le : int ($thread_id1 : L<Thread::ID|SPVM::Thread::ID>, $thread_id2 : L<Thread::ID|SPVM::Thread::ID>);>

Checks if the thread ID $thread_id1 is less than or equal to the thread ID $thread_id2.

If the check is ok, returns 1, otherwise returns 0.

=head2 See Also

=over 2

=item * L<Thread|SPVM::Thread>

=item * L<Thread::ThisThread|SPVM::Thread::ThisThread>

=item * L<std::thread::id in C++|https://en.cppreference.com/w/cpp/thread/thread/id>

=back

=head1 Copyright & License

Copyright 2022-2022 Yuki Kimoto, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

