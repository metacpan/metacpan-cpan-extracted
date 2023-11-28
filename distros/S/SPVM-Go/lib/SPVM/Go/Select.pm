package SPVM::Go::Select;



1;

=head1 Name

SPVM::Go::Select - Go select Statement

=head1 Description

Go::Select class of L<SPVM> has methods to select a readable/writable channel.

=head1 Usage

  use Go;
  
  Go->go(method : void () {
    
    my $ch0 = Go->make;
    
    my $ch1 = Go->make;
    
    my $ch2 = Go->make;
    
    my $ch3 = Go->make;
    
    Go->go([has ch0 : Go::Channel = $ch0, has ch1 : Go::Channel = $ch1, has ch2 : Go::Channel = $ch2, has ch3 : Go::Channel = $ch3] method : void () {
      
      my $ch0 = $self->{ch0};
      
      $ch0->write(1);
      
      my $ch1 = $self->{ch1};
      
      $ch1->write(2);
      
      my $ch2 = $self->{ch2};
      
      $ch2->write(3);
      
      my $ch3 = $self->{ch3};
      
      my $ok = 0;
      
      my $value = (int)$ch3->read(\$ok);
    });
    
    my $select = Go->new_select;
    
    $select->add_read($ch2);
    
    $select->add_read($ch1);
    
    $select->add_read($ch0);
    
    $select->add_write($ch3 => 4);
    
    while (1) {
      my $result = $select->select;
      
      my $ok = $result->ok;
      
      if ($ok) {
        my $ch = $result->channel;
        
        my $is_write = $result->is_write;
        
        if ($is_write) {
          $select->remove_write($ch);
        }
        else {
          my $value = (int)$result->value;
          
          $select->remove_read($ch);
        }
      }
      
      if ($select->is_empty) {
        last;
      }
    }
    
  });
  
  Go->gosched;

=head1 Fields

=head2 non_blocking

C<has non_blocking : rw byte;>

Set the flag if this select is non-blocking.

=head1 Instance Methods

=head2 add_read

C<method add_read : void ($channel : L<Go::Channel|SPVM::Go::Channe>);>

Adds a select case for reading given a channel $channel.

=head2 add_write

C<method add_write : void ($channel : L<Go::Channel|SPVM::Go::Channe>, $value : object);>

Adds a select case for writing given a channel $channel and a value $value.

=head2 remove_read

C<method remove_read : void ($channel : L<Go::Channel|SPVM::Go::Channe>);>

Removes a corresponding select case for reading given a channel $channel.

=head2 remove_write

C<method remove_write : void ($channel : L<Go::Channel|SPVM::Go::Channe>);>

Removes a corresponding select case for reading given a channel $channel.

=head2 select

C<method select : L<Go::Select::Result|SPVM::Go::Select::Result> ();>

Selects a channel and returns its result.

A readable or writable channel is randomly selected.

If no channels are readable or writable, the goroutine waits until a readable or writable channel is selected.

If the L</"non_blocking"> field is set to non-zero and no channels are readable or writable, returns undef.

=head2 is_empty

C<method is_empty : int ();>

If the count of the select cases is 0, returns 1. Otherwise returns 0.

=head1 Copyright & License

Copyright (c) 2023 Yuki Kimoto

MIT License

