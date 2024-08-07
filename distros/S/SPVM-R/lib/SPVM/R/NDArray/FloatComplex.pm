package SPVM::R::NDArray::FloatComplex;



1;

=head1 Name

SPVM::R::NDArray::FloatComplex - N-Dimensional Array of Float Complex Type.

=head1 Description

R::NDArray::FloatComplex class in L<SPVM> represents n-dimensional array of float complex L<Complex_2f|SPVM::Complex_2f> type.

=head1 Usage

  use R::NDArray::FloatComplex;
  use Math;
  
  my $data = [
    Math->complexf(1, 0),
    Math->complexf(2, 0),
    Math->complexf(3, 0),
    Math->complexf(4, 0),
    Math->complexf(5, 0),
    Math->complexf(6, 0)
  ];
  
  my $ndarray = R::NDArray::FloatComplex->new({data => $data, dim => [3, 2]});

=head1 Super Class

L<R::NDArray|SPVM::R::NDArray>

=head1 Fields

=head2 data

C<method data : L<Complex_2f|SPVM::Complex_2f>[] ();>

Same as L<R::NDArray#data|SPVM::R::NDArray/"data"> method, but the return type is different.

=head1 Class Methods

C<static method new : L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex> ($options : object[] = undef);>

Creates a new L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex> and returns it.

This method calls L<R::NDArray#init|SPVM::R::NDArray/"init"> method given the options $options.

=head1 Instance Methods

=head2 create_default_data

C<method create_default_data : L<Complex_2f|SPVM::Complex_2f>[] ($length : int = 0);>

Creates a default data given the length $length and returns it.

=head2 elem_to_string

C<method elem_to_string : string ($data : L<Complex_2f|SPVM::Complex_2f>[], $data_index : int);>

Converts an element $data at index $data_index to a string and returns it.

=head2 elem_assign

C<method elem_assign : void ($dist_data : L<Complex_2f|SPVM::Complex_2f>[], $dist_data_index : int, $src_data : L<Complex_2f|SPVM::Complex_2f>[], $src_data_index : int);>

Assigns the element $src_data at index $src_data_index to the element $dist_data at index $dist_data_index.

=head2 elem_clone

C<method elem_clone : void ($dist_data : L<Complex_2f|SPVM::Complex_2f>[], $dist_data_index : int, $src_data : L<Complex_2f|SPVM::Complex_2f>[], $src_data_index : int);>

Copies the element $src_data at index $src_data_indext to the element $dist_data at index $dist_data_index.

=head2 elem_is_na

C<method elem_is_na : int ($data : L<Complex_2f|SPVM::Complex_2f>[], $data_index : int);>

Checks if an element represets NA.

If the real number or the image number of the element $data at index $data_index is NaN, returns 1, otherwise returns 0.

=head2 clone

C<method clone : L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex> ($shallow : int = 0);>

Same as L<R::NDArray#clone|SPVM::R::NDArray/"clone"> method, but the return type is different.

=head2 slice

C<method slice : L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex> ($asix_indexes_product : L<R::NDArray::Int|SPVM::R::NDArray::Int>[]);>

Same as L<R::NDArray#slice|SPVM::R::NDArray/"slice"> method, but the return type is different.

=head2 to_double_complex_ndarray

C<method to_double_complex_ndarray : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex> ();>

Converts this n-dimensional array to a n-dimensional array of L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex> and returns it.

=head1 Copyright & License

Copyright (c) 2024 Yuki Kimoto

MIT License

