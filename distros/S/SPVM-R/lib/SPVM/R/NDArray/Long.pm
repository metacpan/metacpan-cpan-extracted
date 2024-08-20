package SPVM::R::NDArray::Long;



1;

=head1 Name

SPVM::R::NDArray::Long - N-Dimensional Array of long Type.

=head1 Description

R::NDArray::Long class in L<SPVM> represents n-dimensional array of C<long> type.

=head1 Usage

  use R::NDArray::Long;
  
  my $ndarray = R::NDArray::Long->new({data => [(long)1, 2, 3, 4, 5, 6], dim => [3, 2]});

=head1 Super Class

L<R::NDArray|SPVM::R::NDArray>

=head1 Field

=head2 data

C<method data : long[] ();>

Same as L<R::NDArray#data|SPVM::R::NDArray/"data"> method, but the return type is different.

=head1 Class Methods

=head2 new

C<static method new : L<R::NDArray::Long|SPVM::R::NDArray::Long> ($options : object[] = undef);>

Creates a new L<R::NDArray::Long|SPVM::R::NDArray::Long> given the options $options and returns it.

This method calls L<R::NDArray#init|SPVM::R::NDArray/"init"> method given the options $options.

=head1 Instance Methods

=head2 create_default_data

C<method create_default_data : long[] ($length : int = 0);>

Creates a default data given the length $length and returns it.

The default data is created by the following code.

  my $default_data = new long[$length];

Exceptions:

The length $length must be more than or equal to 0. Otherwise an exception is thrown.

=head2 elem_to_string

C<method elem_to_string : string ($data : long[], $data_index : int);>

Converts an element $data at index $data_index to a string and returns it.

The string is created by the following code.

  my $string = (string)$data->[$data_index];

=head2 elem_assign

C<method elem_assign : void ($dist_data : long[], $dist_data_index : int, $src_data : long[], $src_data_index : int);>

Assigns the element $src_data at index $src_data_index to the element $dist_data at index $dist_data_index.

=head2 elem_clone

C<method elem_clone : void ($dist_data : long[], $dist_data_index : int, $src_data : long[], $src_data_index : int);>

Same as L</"elem_assign"> method.

=head2 elem_cmp

C<method elem_cmp : int ($a_data : long[], $a_data_index : int, $b_data : long[], $b_data_index : int);>

Compares the element $a_data at index $a_data_index and the element $b_data at index $b_data_index using the comparison operator C<E<lt>=E<gt>> and returns the result.

=head2 elem_is_na

C<method elem_is_na : int ($data : byte[], $data_index : int);>

Checks if an element represets NA.

Always returns 0.

=head2 clone

C<method clone : L<R::NDArray::Long|SPVM::R::NDArray::Long> ($shallow : int = 0);>

Same as L<R::NDArray#clone|SPVM::R::NDArray/"clone"> method, but the return type is different.

=head2 slice

C<method slice : L<R::NDArray::Long|SPVM::R::NDArray::Long> ($indexes_product : L<R::NDArray::Int|SPVM::R::NDArray::Int>[]);>

Same as L<R::NDArray#slice|SPVM::R::NDArray/"slice"> method, but the return type is different.

=head2 to_int_ndarray

C<method to_int_ndarray : L<R::NDArray::Int|SPVM::R::NDArray::Int> ();>

Converts this n-dimensional array to a n-dimensional array of L<R::NDArray::Int|SPVM::R::NDArray::Int> and returns it.

Each element is converted by the following code.

  my $ret_elem = (int)$elem;

=head2 to_float_ndarray

C<method to_float_ndarray : L<R::NDArray::Float|SPVM::R::NDArray::Float> ();>

Converts this n-dimensional array to a n-dimensional array of L<R::NDArray::Float|SPVM::R::NDArray::Float> and returns it.

Each element is converted by the following code.

  my $ret_elem = (float)$elem;

=head2 to_double_ndarray

C<method to_double_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double> ();>

Converts this n-dimensional array to a n-dimensional array of L<R::NDArray::Double|SPVM::R::NDArray::Double> and returns it.

Each element is converted by the following code.

  my $ret_elem = (double)$elem;

=head1 See Also

=over 2

=item * L<R::OP::Long|SPVM::R::OP::Long>

=item * L<R::NDArray|SPVM::R::NDArray>

=item * L<R|SPVM::R>

=back

=head1 Copyright & License

Copyright (c) 2024 Yuki Kimoto

MIT License

