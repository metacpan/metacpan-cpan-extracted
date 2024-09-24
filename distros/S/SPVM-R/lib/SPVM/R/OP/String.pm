package SPVM::R::OP::String;



1;

=head1 Name

SPVM::R::OP::String - N-Dimensional Array Operations for R::NDArray::String

=head1 Description

R::OP::String class in L<SPVM> has methods for n-dimensional array operations for L<R::NDArray::String|SPVM::R::NDArray::String>.

=head1 Usage

  use R::OP::String as STROP;
  
  my $ndarray_scalar = STROP->c((string)"a");
  
  my $ndarray_vector = STROP->c([(string)"a", "b", "c"]);
  
  my $ndarray = STROP->c([(string)"a", "b", "c", "d", "e", "f"], [3, 2]);
  
  my $ndarray2 = STROP->c($ndarray);

=head1 Class Methods

=head2 c

C<static method c : L<R::NDArray::String|SPVM::R::NDArray::String> ($data : object of string|string[]|L<R::NDArray::String|SPVM::R::NDArray::String>, $dim : int[] = undef);>

Creates a new L<R::NDArray::String|SPVM::R::NDArray::String> object given the data $data and the dimensions $dim.

Implemetation:

If $data is defined and the type of $data is C<string>, $data is set to C<[(string)$data]>.

If $data is defined and the type of $data is L<R::NDArray::String|SPVM::R::NDArray::String>, $dim is set to C<$data-E<gt>(R::NDArray::String)-E<gt>dim> unless $dim is defined and $data is set to C<$data-E<gt>(R::NDArray::String)-E<gt>data>.

And this method calls L<R::NDArray::String#new|SPVM::R::NDArray::String/"new"> method given $dim and $data.

Exceptions:

The type of the data $data must be string, string[], or R::NDArray::String if defined. Othrewise, an exception is thrown.

=head2 concat

C<static method concat : L<R::NDArray::String|SPVM::R::NDArray::String> ($x_ndarray : L<R::NDArray::String|SPVM::R::NDArray::String>, $y_ndarray : L<R::NDArray::String|SPVM::R::NDArray::String>);>

Creates a new L<R::NDArray::String|SPVM::R::NDArray::String> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, performs concatnation C<.> operation on each element of the n-dimensional array $x_ndarray and $y_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.

$y_ndarray allows to be a L<scalar|SPVM::R::NDArray/"Scalar">. In that case, each element used in the operation is the element at index 0.

If concatnation C<.> operation throw an exceptions, the element is set to C<undef>.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

The n-dimensional array $y_ndarray must be defined. Otherwise, an exception is thrown.

The dimensions of $x_ndarray must be equal to the dimensions of $y_ndarray if $y_ndarray is not a scalar. Otherwise, an exception is thrown.

=head2 eq

C<static method eq : L<R::NDArray::Int|SPVM::R::NDArray::Int> ($x_ndarray : L<R::NDArray::String|SPVM::R::NDArray::String>, $y_ndarray : L<R::NDArray::String|SPVM::R::NDArray::String>);>

Creates a new L<R::NDArray::Int|SPVM::R::NDArray::Int> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, performs string comparison C<eq> operation on each element of the n-dimensional array $x_ndarray and $y_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

The n-dimensional array $y_ndarray must be defined. Otherwise, an exception is thrown.

The dimensions of $x_ndarray must be equal to the dimensions of $y_ndarray. Otherwise, an exception is thrown.

=head2 ne

C<static method ne : L<R::NDArray::Int|SPVM::R::NDArray::Int> ($x_ndarray : L<R::NDArray::String|SPVM::R::NDArray::String>, $y_ndarray : L<R::NDArray::String|SPVM::R::NDArray::String>);>

Creates a new L<R::NDArray::Int|SPVM::R::NDArray::Int> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, performs string comparison C<ne> operation on each element of the n-dimensional array $x_ndarray and $y_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

The n-dimensional array $y_ndarray must be defined. Otherwise, an exception is thrown.

The dimensions of $x_ndarray must be equal to the dimensions of $y_ndarray. Otherwise, an exception is thrown.

=head2 gt

C<static method gt : L<R::NDArray::Int|SPVM::R::NDArray::Int> ($x_ndarray : L<R::NDArray::String|SPVM::R::NDArray::String>, $y_ndarray : L<R::NDArray::String|SPVM::R::NDArray::String>);>

Creates a new L<R::NDArray::Int|SPVM::R::NDArray::Int> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, performs string comparison C<gt> operation on each element of the n-dimensional array $x_ndarray and $y_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

The n-dimensional array $y_ndarray must be defined. Otherwise, an exception is thrown.

The dimensions of $x_ndarray must be equal to the dimensions of $y_ndarray. Otherwise, an exception is thrown.

=head2 ge

C<static method ge : L<R::NDArray::Int|SPVM::R::NDArray::Int> ($x_ndarray : L<R::NDArray::String|SPVM::R::NDArray::String>, $y_ndarray : L<R::NDArray::String|SPVM::R::NDArray::String>);>

Creates a new L<R::NDArray::Int|SPVM::R::NDArray::Int> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, performs string comparison C<ge> operation on each element of the n-dimensional array $x_ndarray and $y_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

The n-dimensional array $y_ndarray must be defined. Otherwise, an exception is thrown.

The dimensions of $x_ndarray must be equal to the dimensions of $y_ndarray. Otherwise, an exception is thrown.

=head2 lt

C<static method lt : L<R::NDArray::Int|SPVM::R::NDArray::Int> ($x_ndarray : L<R::NDArray::String|SPVM::R::NDArray::String>, $y_ndarray : L<R::NDArray::String|SPVM::R::NDArray::String>);>

Creates a new L<R::NDArray::Int|SPVM::R::NDArray::Int> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, performs string comparison C<lt> operation on each element of the n-dimensional array $x_ndarray and $y_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

The n-dimensional array $y_ndarray must be defined. Otherwise, an exception is thrown.

The dimensions of $x_ndarray must be equal to the dimensions of $y_ndarray. Otherwise, an exception is thrown.

=head2 le

C<static method le : L<R::NDArray::Int|SPVM::R::NDArray::Int> ($x_ndarray : L<R::NDArray::String|SPVM::R::NDArray::String>, $y_ndarray : L<R::NDArray::String|SPVM::R::NDArray::String>);>

Creates a new L<R::NDArray::Int|SPVM::R::NDArray::Int> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, performs string comparison C<le> operation on each element of the n-dimensional array $x_ndarray and $y_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

The n-dimensional array $y_ndarray must be defined. Otherwise, an exception is thrown.

The dimensions of $x_ndarray must be equal to the dimensions of $y_ndarray. Otherwise, an exception is thrown.

=head2 rep

C<static method rep : L<R::NDArray::String|SPVM::R::NDArray::String> ($x_ndarray : L<R::NDArray::String|SPVM::R::NDArray::String>, $times : int);>

Same as L<R::OP#rep|SPVM::R::OP/"rep"> method, but the return type is different.

=head2 rep_length

C<static method rep_length : L<R::NDArray::String|SPVM::R::NDArray::String> ($x_ndarray : L<R::NDArray::String|SPVM::R::NDArray::String>, $length : int);>

Same as L<R::OP#rep_length|SPVM::R::OP/"rep_length"> method, but the return type is different.

=head1 See Also

=over 2

=item * L<R::OP|SPVM::R::OP>

=item * L<R::NDArray::String|SPVM::R::NDArray::String>

=item * L<R::NDArray|SPVM::R::NDArray>

=item * L<R|SPVM::R>

=back

=head1 Copyright & License

Copyright (c) 2024 Yuki Kimoto

MIT License

