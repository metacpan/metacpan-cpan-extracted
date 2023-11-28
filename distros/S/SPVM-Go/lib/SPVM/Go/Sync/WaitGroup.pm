package SPVM::Go::Sync::WaitGroup;



1;

=head1 Name

SPVM::Go::Sync::WaitGroup - Go WaitGroup

=head1 Description

Go::Sync::WaitGroup class of L<SPVM> has methods to manipulate waiting count.

=head1 Usage

  use Go::Sync::WaitGroup;
  use Fn;
  
  Go->go(method : void () {
    my $wg = Go::Sync::WaitGroup->new;
    
    $wg->add(2);
    
    Go->go([has wg : Go::Sync::WaitGroup = $wg] method : void () {
      
      Fn->defer([has wg : Go::Sync::WaitGroup = $self->{wg}] method : void () {
        $self->{wg}->done;
      });
      
    });
    
    Go->go([has wg : Go::Sync::WaitGroup = $wg] method : void () {
      Fn->defer([has wg : Go::Sync::WaitGroup = $self->{wg}] method : void () {
        $self->{wg}->done;
      });
      
    });
    
    $wg->wait;
  });
  
  Go->gosched;

=head1 Fields

=head2 count

C<has count : int;>

The count of waiting.

=head1 Class Methods

=head2 new

C<static method new : L<Go::Sync::WaitGroup|SPVM::Go::Sync::WaitGroup> ();>

Creates a new L<Go::Sync::WaitGroup|SPVM::Go::Sync::WaitGroup> object.

=head1 Instance Methods

=head2 add

C<method add : void ($delta : int = 1);>

Adds $delta to the count of waiting.

This method is thread-safe.

Exceptions:

The count field must be greater than or equal to 0. Otherwise an exception is thrown.

=head2 done

C<method done : void ();>

Decrements the count of waiting.

The same as

  $wait_group->add(-1);

This method is thread-safe.

=head2 wait

C<method wait : void ();>

Waits until the count of waiting is 0.

=head1 Copyright & License

Copyright (c) 2023 Yuki Kimoto

MIT License

