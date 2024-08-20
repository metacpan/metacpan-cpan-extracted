package SPVM::R::NDArray::Time::Piece;



1;

=head1 Name

SPVM::R::NDArray::Time::Piece - N-Dimensional Array of Time::Piece Type.

=head1 Description

R::NDArray::Time::Piece class in L<SPVM> represents n-dimensional array of C<Time::Piece> type.

=head1 Usage

  use R::NDArray::Time::Piece;
  
  my $data = [
    Time::Piece->strptime("2024-01-01 00-00-00", '%Y-%m-%d %H:%M:%S'),
    Time::Piece->strptime("2024-01-02 00-00-00", '%Y-%m-%d %H:%M:%S'),
    Time::Piece->strptime("2024-01-03 00-00-00", '%Y-%m-%d %H:%M:%S'),
    Time::Piece->strptime("2024-01-04 00-00-00", '%Y-%m-%d %H:%M:%S'),
    Time::Piece->strptime("2024-01-05 00-00-00", '%Y-%m-%d %H:%M:%S'),
    Time::Piece->strptime("2024-01-06 00-00-00", '%Y-%m-%d %H:%M:%S'),
  ];
  
  my $ndarray = R::NDArray::Time::Piece->new({data => $data, dim => [3, 2]});

=head1 Super Class

L<R::NDArray|SPVM::R::NDArray>

=head1 Field

=head2 data

C<method data : L<Time::Piece|SPVM::Time::Piece>[] ();>

Same as L<R::NDArray#data|SPVM::R::NDArray/"data"> method, but the return type is different.

=head1 Class Methods

=head2 new

C<static method new : L<R::NDArray::Time::Piece|SPVM::R::NDArray::Time::Piece> ($options : object[] = undef);>

Creates a new L<R::NDArray::Time::Piece|SPVM::R::NDArray::Time::Piece> given the options $options and returns it.

This method calls L<R::NDArray#init|SPVM::R::NDArray/"init"> method given the options $options.

=head1 Instance Methods

=head2 create_default_data

C<method create_default_data : L<Time::Piece|SPVM::Time::Piece>[] ($length : int = 0);>

Creates a default data given the length $length and returns it.

The default data is created by the following code.

  my $default_data = new Time::Piece[$length];

Exceptions:

The length $length must be more than or equal to 0. Otherwise an exception is thrown.

=head2 elem_to_string

C<method elem_to_string : string ($data : L<Time::Piece|SPVM::Time::Piece>[], $data_index : int);>

Converts an element $data at index $data_index to a string and returns it.

  my $string = (string)undef;
  if ($data->[$data_index]) {
    $string = $data->[$data_index]->strftime("%Y-%m-%d %H:%M:%S");
  }

=head2 elem_assign

C<method elem_assign : void ($dist_data : L<Time::Piece|SPVM::Time::Piece>[], $dist_data_index : int, $src_data : L<Time::Piece|SPVM::Time::Piece>[], $src_data_index : int);>

Assigns the element $src_data at index $src_data_index to the element $dist_data at index $dist_data_index.

=head2 elem_clone

C<method elem_clone : void ($dist_data : L<Time::Piece|SPVM::Time::Piece>[], $dist_data_index : int, $src_data : L<Time::Piece|SPVM::Time::Piece>[], $src_data_index : int);>

Clones the element $src_data at index $src_data_indext to the element $dist_data at index $dist_data_index.

The clone is created by the following code.
  
  $dist_data->[$dist_data_index] = (Time::Piece)undef;
  if ($src_data->[$src_data_index]) {
    $dist_data->[$dist_data_index] = $src_data->[$src_data_index]->clone;
  }

=head2 elem_cmp

C<method elem_cmp : int ($a_data : L<Time::Piece|SPVM::Time::Piece>[], $a_data_index : int, $b_data : L<Time::Piece|SPVM::Time::Piece>[], $b_data_index : int);>

Compares the element $a_data at index $a_data_index and the element $b_data at index $b_data_index using the following comparison code and returns the result.

  my $cmp = 0;
  if ($a_data->[$a_data_index] && $b_data->[$b_data_index]) {
    my $a_epoch = $a_data->[$a_data_index]->epoch;
    
    my $b_epoch = $b_data->[$b_data_index]->epoch;
    
    $cmp = $a_epoch <=> $b_epoch;
  }
  elsif ($a_data->[$a_data_index]) {
    $cmp = 1;
  }
  elsif ($b_data->[$b_data_index]) {
    $cmp = -1;
  }

=head2 clone

C<method clone : L<R::NDArray::Time::Piece|SPVM::R::NDArray::Time::Piece> ($shallow : int = 0);>

Same as L<R::NDArray#clone|SPVM::R::NDArray/"clone"> method, but the return type is different.

=head2 slice

C<method slice : L<R::NDArray::Time::Piece|SPVM::R::NDArray::Time::Piece> ($indexes_product : L<R::NDArray::Int|SPVM::R::NDArray::Int>[]);>

Same as L<R::NDArray#slice|SPVM::R::NDArray/"slice"> method, but the return type is different.

=head1 See Also

=over 2

=item * L<R::OP::Time::Piece|SPVM::R::OP::Time::Piece>

=item * L<R::NDArray|SPVM::R::NDArray>

=item * L<R|SPVM::R>

=back

=head1 Copyright & License

Copyright (c) 2024 Yuki Kimoto

MIT License

