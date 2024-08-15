package SPVM::R::NDArray::Int;



1;

=head1 Name

SPVM::R::NDArray::Int - N-Dimensional Array of int Type.

=head1 Description

R::NDArray::Int class in L<SPVM> represents n-dimensional array of C<int> type.

=head1 Usage

  use R::NDArray::Int;
  
  my $ndarray = R::NDArray::Int->new({data => [(int)1, 2, 3, 4, 5, 6], dim => [3, 2]});

=head1 Super Class

L<R::NDArray|SPVM::R::NDArray>

=head1 Field

=head2 data

C<method data : int[] ();>

Same as L<R::NDArray#data|SPVM::R::NDArray/"data"> method, but the return type is different.

=head1 Class Methods

=head2 new

C<static method new : L<R::NDArray::Int|SPVM::R::NDArray::Int> ($options : object[] = undef);>

Creates a new L<R::NDArray::Int|SPVM::R::NDArray::Int> and returns it.

This method calls L<R::NDArray#init|SPVM::R::NDArray/"init"> method given the options $options.

=head1 Instance Methods

=head2 create_default_data

C<method create_default_data : int[] ($length : int = 0);>

Creates a default data given the length $length and returns it.

=head2 elem_to_string

C<method elem_to_string : string ($data : int[], $data_index : int);>

Converts an element $data at index $data_index to a string and returns it.

=head2 elem_assign

C<method elem_assign : void ($dist_data : int[], $dist_data_index : int, $src_data : int[], $src_data_index : int);>

Assigns the element $src_data at index $src_data_index to the element $dist_data at index $dist_data_index.

=head2 elem_clone

C<method elem_clone : void ($dist_data : int[], $dist_data_index : int, $src_data : int[], $src_data_index : int);>

Copies the element $src_data at index $src_data_indext to the element $dist_data at index $dist_data_index.

=head2 elem_cmp

C<method elem_cmp : int ($a_data : int[], $a_data_index : int, $a_data : int[], $b_data_index : int);>

Compares the element $a_data at index $a_data_index and the element $b_data at index $b_data_index and returns the result.

=head2 elem_is_na

C<method elem_is_na : int ($data : byte[], $data_index : int);>

Checks if an element represets NA.

Returns 0.

=head2 clone

C<method clone : L<R::NDArray::Int|SPVM::R::NDArray::Int> ($shallow : int = 0);>

Same as L<R::NDArray#clone|SPVM::R::NDArray/"clone"> method, but the return type is different.

=head2 slice

C<method slice : L<R::NDArray::Int|SPVM::R::NDArray::Int> ($asix_indexes_product : L<R::NDArray::Int|SPVM::R::NDArray::Int>[]);>

Same as L<R::NDArray#slice|SPVM::R::NDArray/"slice"> method, but the return type is different.

=head2 to_byte_ndarray

C<method to_byte_ndarray : L<R::NDArray::Byte|SPVM::R::NDArray::Byte> ();>

Converts this n-dimensional array to a n-dimensional array of L<R::NDArray::Byte|SPVM::R::NDArray::Byte> and returns it.

=head2 to_short_ndarray

C<method to_short_ndarray : L<R::NDArray::Short|SPVM::R::NDArray::Short> ();>

Converts this n-dimensional array to a n-dimensional array of L<R::NDArray::Short|SPVM::R::NDArray::Short> and returns it.

=head2 to_long_ndarray

C<method to_long_ndarray : L<R::NDArray::Long|SPVM::R::NDArray::Long> ();>

Converts this n-dimensional array to a n-dimensional array of L<R::NDArray::Long|SPVM::R::NDArray::Long> and returns it.

=head2 to_float_ndarray

C<method to_float_ndarray : L<R::NDArray::Float|SPVM::R::NDArray::Float> ();>

Converts this n-dimensional array to a n-dimensional array of L<R::NDArray::Float|SPVM::R::NDArray::Float> and returns it.

=head2 to_double_ndarray

C<method to_double_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double> ();>

Converts this n-dimensional array to a n-dimensional array of L<R::NDArray::Double|SPVM::R::NDArray::Double> and returns it.

=head2 to_indexes

C<method to_indexes : L<R::NDArray::Int|SPVM::R::NDArray::Int> ();>

Creates a list of indexes whose elements are true values, convert it to an N-dimensional array that is a vector, and return it.

For example, C<[0, 1, 0, 1, 1]> is converted to C<[1, 3, 4]>.

Exceptions: 

This n-dimensional array must be a vector. Otherwise an exception is thrown.

=head1 Copyright & License

Copyright (c) 2024 Yuki Kimoto

MIT License

