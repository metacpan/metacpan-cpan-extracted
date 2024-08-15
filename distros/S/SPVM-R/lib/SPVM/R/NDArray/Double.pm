package SPVM::R::NDArray::Double;



1;

=head1 Name

SPVM::R::NDArray::Double - N-Dimensional Array of double Type.

=head1 Description

R::NDArray::Double class in L<SPVM> represents n-dimensional array of C<double> type.

=head1 Usage

  use R::NDArray::Double;
  
  my $ndarray = R::NDArray::Double->new({data => [(double)1, 2, 3, 4, 5, 6], dim => [3, 2]});

=head1 Super Class

L<R::NDArray|SPVM::R::NDArray>

=head1 Field

=head2 data

C<method data : double[] ();>

Same as L<R::NDArray#data|SPVM::R::NDArray/"data"> method, but the return type is different.

=head1 Class Methods

=head2 new

C<static method new : L<R::NDArray::Double|SPVM::R::NDArray::Double> ($options : object[] = undef);>

Creates a new L<R::NDArray::Double|SPVM::R::NDArray::Double> and returns it.

This method calls L<R::NDArray#init|SPVM::R::NDArray/"init"> method given the options $options.

=head1 Instance Methods

=head2 create_default_data

C<method create_default_data : double[] ($length : int = 0);>

Creates a default data given the length $length and returns it.

=head2 elem_to_string

C<method elem_to_string : string ($data : double[], $data_index : int);>

Converts an element $data at index $data_index to a string and returns it.

=head2 elem_assign

C<method elem_assign : void ($dist_data : double[], $dist_data_index : int, $src_data : double[], $src_data_index : int);>

Assigns the element $src_data at index $src_data_index to the element $dist_data at index $dist_data_index.

=head2 elem_clone

C<method elem_clone : void ($dist_data : double[], $dist_data_index : int, $src_data : double[], $src_data_index : int);>

Copies the element $src_data at index $src_data_indext to the element $dist_data at index $dist_data_index.

=head2 elem_cmp

C<method elem_cmp : int ($a_data : double[], $a_data_index : int, $b_data : double[], $b_data_index : int);>

Compares the element $a_data at index $a_data_index and the element $b_data at index $b_data_index and returns the result.

=head2 elem_is_na

C<method elem_is_na : int ($data : double[], $data_index : int);>

Checks if an element represets NA.

If the element $data at index $data_index is NaN, returns 1, otherwise returns 0.

=head2 clone

C<method clone : L<R::NDArray::Double|SPVM::R::NDArray::Double> ($shallow : int = 0);>

Same as L<R::NDArray#clone|SPVM::R::NDArray/"clone"> method, but the return type is different.

=head2 slice

C<method slice : L<R::NDArray::Double|SPVM::R::NDArray::Double> ($asix_indexes_product : L<R::NDArray::Int|SPVM::R::NDArray::Int>[]);>

Same as L<R::NDArray#slice|SPVM::R::NDArray/"slice"> method, but the return type is different.

=head2 to_int_ndarray

C<method to_int_ndarray : L<R::NDArray::Int|SPVM::R::NDArray::Int> ();>

Converts this n-dimensional array to a n-dimensional array of L<R::NDArray::Int|SPVM::R::NDArray::Int> and returns it.

=head2 to_long_ndarray

C<method to_long_ndarray : L<R::NDArray::Long|SPVM::R::NDArray::Long> ();>

Converts this n-dimensional array to a n-dimensional array of L<R::NDArray::Long|SPVM::R::NDArray::Long> and returns it.

=head2 to_float_ndarray

C<method to_float_ndarray : L<R::NDArray::Float|SPVM::R::NDArray::Float> ();>

Converts this n-dimensional array to a n-dimensional array of L<R::NDArray::Float|SPVM::R::NDArray::Float> and returns it.

=head2 to_double_complex_ndarray

C<method to_double_complex_ndarray : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex> ();>

Converts this n-dimensional array to a n-dimensional array of L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex> and returns it.

=head1 Copyright & License

Copyright (c) 2024 Yuki Kimoto

MIT License

