package SPVM::R::OP::StringBuffer;



1;

=head1 Name

SPVM::R::OP::StringBuffer - N-Dimensional Array Operations for R::NDArray::StringBuffer

=head1 Description

R::OP::StringBuffer class in L<SPVM> has methods for n-dimensional array operations for L<R::NDArray::StringBuffer|SPVM::R::NDArray::StringBuffer>.

=head1 Usage

  use R::OP::StringBuffer as BUFOP;
  
  my $ndarray_scalar = BUFOP->c(StringBuffer->new("a"));
  
  my $ndarray_scalar = BUFOP->c("a");
  
  my $data = [
    StringBuffer->new("a"),
    StringBuffer->new("b"),
    StringBuffer->new("c"),
    StringBuffer->new("d"),
    StringBuffer->new("e"),
    StringBuffer->new("f")
  ];
  
  my $ndarray_vector = BUFOP->c($data);
  
  my $ndarray_vector = BUFOP->c([(string)"a", "b", "c", "d", "e", "f"]);
  
  my $ndarray = BUFOP->c($data, [3, 2]);
  
  my $ndarray2 = BUFOP->c($ndarray);

=head1 Class Methods

=head2 c

C<static method c : L<R::NDArray::StringBuffer|SPVM::R::NDArray::StringBuffer> ($data : object of StringBuffer|StringBuffer[]|L<R::NDArray::StringBuffer|SPVM::R::NDArray::StringBuffer>|string|string[]|L<R::NDArray::String|SPVM::R::NDArray::String>, $dim : int[] = undef);>

Creates a new L<R::NDArray::StringBuffer|SPVM::R::NDArray::StringBuffer> object given the data $data and the dimensions $dim.

Implemetation:

If $data is defined and the type of $data is L<StringBuffer|SPVM::StringBuffer>, $data is set to C<[(StringBuffer)$data]>.

If $data is defined and the type of $data is L<R::NDArray::StringBuffer|SPVM::R::NDArray::StringBuffer>, $dim is set to C<$data-E<gt>(R::NDArray::StringBuffer)-E<gt>dim> unless $dim is defined and $data is set to C<$data-E<gt>(R::NDArray::StringBuffer)-E<gt>data>.

If $data is defined and the type of $data is C<string>, $data is set to C<[StringBuffer-E<gt>new((string)$data)]>.

If $data is defined and the type of $data is C<string[]>, $data is set to the return value of C<R::OP::String->c((string[])$data)->to_string_buffer_ndarray->data>.

If $data is defined and the type of $data is L<R::NDArray::String|SPVM::R::NDArray::String>, $dim is set to C<$data-E<gt>(R::NDArray::String)-E<gt>dim> unless $dim is defined and $data is set to C<$data-E<gt>(R::NDArray::String)-E<gt>to_string_buffer_ndarray-E<gt>data>.

And this method calls L<R::NDArray::StringBuffer#new|SPVM::R::NDArray::StringBuffer/"new"> method given $dim and $data.

Exceptions:

The type of the data $data must be StringBuffer, StringBuffer[], R::NDArray::StringBuffer, string, string[], R::NDArray::String if defined. Othrewise, an exception is thrown.

=head2 push

C<static method push : void ($x_ndarray : L<R::NDArray::StringBuffer|SPVM::R::NDArray::StringBuffer>, $y_ndarray : L<R::NDArray::String|SPVM::R::NDArray::String>);>

Performs C<$x_elem-E<gt>L<push|SPVM::StringBuffer/"push">($y_elem)> method on each element(named $x_elem, $y_elem) of the n-dimensional array $x_ndarray and $y_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.

$y_ndarray allows to be a L<scalar|SPVM::R::NDArray/"Scalar">. In that case, each element used in the operation is the element at index 0.

If C<push> method throw an exceptions, $x_elem is unchanged.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

The n-dimensional array $y_ndarray must be defined. Otherwise, an exception is thrown.

The dimensions of $x_ndarray must be equal to the dimensions of $y_ndarray if $y_ndarray is not a scalar. Otherwise, an exception is thrown.

=head2 eq

C<static method eq : L<R::NDArray::Int|SPVM::R::NDArray::Int> ($x_ndarray : L<R::NDArray::StringBuffer|SPVM::R::NDArray::StringBuffer>, $y_ndarray : L<R::NDArray::StringBuffer|SPVM::R::NDArray::StringBuffer>);>

Creates a new L<R::NDArray::Int|SPVM::R::NDArray::Int> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, performs the comparison logic C<$x_ndarray-E<gt>L<elem_cmp|SPVM::R::NDArray::StringBuffer/"elem_cmp">($x_ndarray-E<gt>data, $i, $y_ndarray-E<gt>data, $i) == 0> on the each element(the index is $i) of the n-dimensional array $x_ndarray and $y_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

The n-dimensional array $y_ndarray must be defined. Otherwise, an exception is thrown.

The dimensions of $x_ndarray must be equal to the dimensions of $y_ndarray. Otherwise, an exception is thrown.

=head2 ne

C<static method ne : L<R::NDArray::Int|SPVM::R::NDArray::Int> ($x_ndarray : L<R::NDArray::StringBuffer|SPVM::R::NDArray::StringBuffer>, $y_ndarray : L<R::NDArray::StringBuffer|SPVM::R::NDArray::StringBuffer>);>

Creates a new L<R::NDArray::Int|SPVM::R::NDArray::Int> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, performs the comparison logic C<$x_ndarray-E<gt>L<elem_cmp|SPVM::R::NDArray::StringBuffer/"elem_cmp">($x_ndarray-E<gt>data, $i, $y_ndarray-E<gt>data, $i) != 0> on the each element(the index is $i) of the n-dimensional array $x_ndarray and $y_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

The n-dimensional array $y_ndarray must be defined. Otherwise, an exception is thrown.

The dimensions of $x_ndarray must be equal to the dimensions of $y_ndarray. Otherwise, an exception is thrown.

=head2 gt

C<static method gt : L<R::NDArray::Int|SPVM::R::NDArray::Int> ($x_ndarray : L<R::NDArray::StringBuffer|SPVM::R::NDArray::StringBuffer>, $y_ndarray : L<R::NDArray::StringBuffer|SPVM::R::NDArray::StringBuffer>);>

Creates a new L<R::NDArray::Int|SPVM::R::NDArray::Int> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, performs the comparison logic C<$x_ndarray-E<gt>L<elem_cmp|SPVM::R::NDArray::StringBuffer/"elem_cmp">($x_ndarray-E<gt>data, $i, $y_ndarray-E<gt>data, $i) E<gt> 0> on the each element(the index is $i) of the n-dimensional array $x_ndarray and $y_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

The n-dimensional array $y_ndarray must be defined. Otherwise, an exception is thrown.

The dimensions of $x_ndarray must be equal to the dimensions of $y_ndarray. Otherwise, an exception is thrown.

=head2 ge

C<static method ge : L<R::NDArray::Int|SPVM::R::NDArray::Int> ($x_ndarray : L<R::NDArray::StringBuffer|SPVM::R::NDArray::StringBuffer>, $y_ndarray : L<R::NDArray::StringBuffer|SPVM::R::NDArray::StringBuffer>);>

Creates a new L<R::NDArray::Int|SPVM::R::NDArray::Int> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, performs the comparison logic C<$x_ndarray-E<gt>L<elem_cmp|SPVM::R::NDArray::StringBuffer/"elem_cmp">($x_ndarray-E<gt>data, $i, $y_ndarray-E<gt>data, $i) E<gt>= 0> on the each element(the index is $i) of the n-dimensional array $x_ndarray and $y_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

The n-dimensional array $y_ndarray must be defined. Otherwise, an exception is thrown.

The dimensions of $x_ndarray must be equal to the dimensions of $y_ndarray. Otherwise, an exception is thrown.

=head2 lt

C<static method lt : L<R::NDArray::Int|SPVM::R::NDArray::Int> ($x_ndarray : L<R::NDArray::StringBuffer|SPVM::R::NDArray::StringBuffer>, $y_ndarray : L<R::NDArray::StringBuffer|SPVM::R::NDArray::StringBuffer>);>

Creates a new L<R::NDArray::Int|SPVM::R::NDArray::Int> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, performs the comparison logic C<$x_ndarray-E<gt>L<elem_cmp|SPVM::R::NDArray::StringBuffer/"elem_cmp">($x_ndarray-E<gt>data, $i, $y_ndarray-E<gt>data, $i) E<lt> 0> on the each element(the index is $i) of the n-dimensional array $x_ndarray and $y_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

The n-dimensional array $y_ndarray must be defined. Otherwise, an exception is thrown.

The dimensions of $x_ndarray must be equal to the dimensions of $y_ndarray. Otherwise, an exception is thrown.

=head2 le

C<static method le : L<R::NDArray::Int|SPVM::R::NDArray::Int> ($x_ndarray : L<R::NDArray::StringBuffer|SPVM::R::NDArray::StringBuffer>, $y_ndarray : L<R::NDArray::StringBuffer|SPVM::R::NDArray::StringBuffer>);>

Creates a new L<R::NDArray::Int|SPVM::R::NDArray::Int> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, performs the comparison logic C<$x_ndarray-E<gt>L<elem_cmp|SPVM::R::NDArray::StringBuffer/"elem_cmp">($x_ndarray-E<gt>data, $i, $y_ndarray-E<gt>data, $i) E<lt>= 0> on the each element(the index is $i) of the n-dimensional array $x_ndarray and $y_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

The n-dimensional array $y_ndarray must be defined. Otherwise, an exception is thrown.

The dimensions of $x_ndarray must be equal to the dimensions of $y_ndarray. Otherwise, an exception is thrown.

=head2 rep

C<static method rep : L<R::NDArray::StringBuffer|SPVM::R::NDArray::StringBuffer> ($x_ndarray : L<R::NDArray::StringBuffer|SPVM::R::NDArray::StringBuffer>, $times : int);>

Same as L<R::OP#rep|SPVM::R::OP/"rep"> method, but the return type is different.

=head2 rep_length

C<static method rep_length : L<R::NDArray::StringBuffer|SPVM::R::NDArray::StringBuffer> ($x_ndarray : L<R::NDArray::StringBuffer|SPVM::R::NDArray::StringBuffer>, $length : int);>

Same as L<R::OP#rep_length|SPVM::R::OP/"rep_length"> method, but the return type is different.

=head1 See Also

=over 2

=item * L<R::OP|SPVM::R::OP>

=item * L<R::NDArray::StringBufferBuffer|SPVM::R::NDArray::StringBufferBuffer>

=item * L<R::NDArray|SPVM::R::NDArray>

=item * L<R|SPVM::R>

=back

=head1 Copyright & License

Copyright (c) 2024 Yuki Kimoto

MIT License

