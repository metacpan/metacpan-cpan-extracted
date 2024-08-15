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

C<method data : Time::Piece[] ();>

Same as L<R::NDArray#data|SPVM::R::NDArray/"data"> method, but the return type is different.

=head1 Class Methods

=head2 new

C<static method new : L<R::NDArray::Time::Piece|SPVM::R::NDArray::Time::Piece> ($options : object[] = undef);>

Creates a new L<R::NDArray::Time::Piece|SPVM::R::NDArray::Time::Piece> and returns it.

This method calls L<R::NDArray#init|SPVM::R::NDArray/"init"> method given the options $options.

=head1 Instance Methods

=head2 create_default_data

C<method create_default_data : Time::Piece[] ($length : int = 0);>

Creates a default data given the length $length and returns it.

=head2 elem_to_string

C<method elem_to_string : string ($data : Time::Piece[], $data_index : int);>

Converts an element $data at index $data_index to a string and returns it.

=head2 elem_assign

C<method elem_assign : void ($dist_data : Time::Piece[], $dist_data_index : int, $src_data : Time::Piece[], $src_data_index : int);>

Assigns the element $src_data at index $src_data_index to the element $dist_data at index $dist_data_index.

=head2 elem_clone

C<method elem_clone : void ($dist_data : Time::Piece[], $dist_data_index : int, $src_data : Time::Piece[], $src_data_index : int);>

Copies the element $src_data at index $src_data_indext to the element $dist_data at index $dist_data_index.

=head2 elem_cmp

C<method elem_cmp : int ($a_data : Time::Piece[], $a_data_index : int, $b_data : Time::Piece[], $b_data_index : int);>

Compares the element $a_data at index $a_data_index and the element $b_data at index $b_data_index and returns the result.

=head2 clone

C<method clone : L<R::NDArray::Time::Piece|SPVM::R::NDArray::Time::Piece> ($shallow : int = 0);>

Same as L<R::NDArray#clone|SPVM::R::NDArray/"clone"> method, but the return type is different.

=head2 slice

C<method slice : L<R::NDArray::Time::Piece|SPVM::R::NDArray::Time::Piece> ($asix_indexes_product : L<R::NDArray::Int|SPVM::R::NDArray::Int>[]);>

Same as L<R::NDArray#slice|SPVM::R::NDArray/"slice"> method, but the return type is different.

=head2 to_long_ndarray

C<method to_long_ndarray : L<R::NDArray::Long|SPVM::R::NDArray::Long> ();>

Converts this n-dimensional array to a n-dimensional array of L<R::NDArray::Long|SPVM::R::NDArray::Long> using L<Time::Piece#epoch|SPVM::Time::Piece#/"epoch"> method and returns it.

=head1 Copyright & License

Copyright (c) 2024 Yuki Kimoto

MIT License

