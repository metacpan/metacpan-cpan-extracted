package SPVM::IO::Select;

1;

=head1 Name

SPVM::IO::Select - Select

=head1 Usage
  
  use IO::Select;
  
  $select = IO::Select->new;
   
  $select->add($fd0);
  $select->add($fd1);
   
  my $ready = $select->can_read($timeout);

=head1 Description

L<SPVM::IO::Select> provides select utilities.

=head1 Fields

  has handles : IntList;

=head1 Class Methods

=head2 new

  static method new : IO::Select ();

=head1 Instance Methods

=head2 add

  method add : int ($new_handle : int);

=head2 remove

  method remove : int ($remove_handle : int);

=head2 exists

  method exists : int ($check_handle : int);

=head2 handles

  method handles : int[] ();

=head2 can_read

  method can_read : int[] ($timeout : double);

=head2 can_write

  method can_write : int[] ($timeout : double);

=head2 has_exception

  method has_exception : int[] ($timeout : double);

=head1 See Also

=head2 Perl's IO::Select

C<IO::Select> is a Perl's L<IO::Select|IO::Select> porting to L<SPVM>.
