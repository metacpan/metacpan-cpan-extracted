package SPVM::Thread;

our $VERSION = '0.001';

1;

=head1 Name

SPVM::Thread - Native Thread

=head1 Usage

  use Thread;
  
  my $results = [0];
  my $thread = Thread->new([$results : int[]] method : void () {
    $results->[0] = 5;
  });
  
  $thread->join;

=head1 Description

The C<Thread> class has methods to create native threads.

This class is a binding of L<std::thread in C++|https://en.cppreference.com/w/cpp/thread/thread>.

=head1 Class Methods

C<static method new : L<Thread|SPVM::Thread> ($task : L<Callback|SPVM::Callback>);>

Creates a new native thread and run the task $task on it.

And creates a new L<Thread|SPVM::Thread> object and returns it.

=head1 Instance Methods

=head2 join

C<method join : void ();>

Waits for the thread to finish.

=head2 get_id

C<method get_id : L<Thread::ID|SPVM::Thread::ID> ();>

Gets the thread ID.

=head1 Repository

L<SPVM::Thread - Github|https://github.com/yuki-kimoto/SPVM-Thread>

=head2 See Also

=over 2

=item * L<Thread::ThisThread|SPVM::Thread::ThisThread>

=item * L<Thread::ID|SPVM::Thread::ID>

=item * L<std::thread in C++|https://en.cppreference.com/w/cpp/thread/thread>

=back

=head1 Author

Yuki Kimoto C<kimoto.yuki@gmail.com>

=head1 Copyright & License

Copyright 2022-2022 Yuki Kimoto, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

