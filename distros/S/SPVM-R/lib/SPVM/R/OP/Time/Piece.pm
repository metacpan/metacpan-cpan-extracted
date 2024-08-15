package SPVM::R::OP::Time::Piece;



1;

=head1 Name

SPVM::R::OP::Time::Piece - N-Dimensional Array Operations for R::NDArray::Time::Piece

=head1 Description

R::OP::Time::Piece class in L<SPVM> has methods for n-dimensional array operations for L<R::NDArray::Time::Piece|SPVM::R::NDArray::Time::Piece>.

=head1 Usage

  use R::OP::Time::Piece as TPOP;
  
  my $ndarray_scalar = TPOP->c(Time::Piece->strptime("2024-01-01 00-00-00", '%Y-%m-%d %H:%M:%S'));
  
  my $ndarray_scalar = TPOP->c("2024-01-01");
  
  my $ndarray_scalar = TPOP->c("2024-01-01 12:01:05");
  
  my $data = [
    Time::Piece->strptime("2024-01-01 00-00-00", '%Y-%m-%d %H:%M:%S'),
    Time::Piece->strptime("2024-01-02 00-00-00", '%Y-%m-%d %H:%M:%S'),
    Time::Piece->strptime("2024-01-03 00-00-00", '%Y-%m-%d %H:%M:%S'),
    Time::Piece->strptime("2024-01-04 00-00-00", '%Y-%m-%d %H:%M:%S'),
    Time::Piece->strptime("2024-01-05 00-00-00", '%Y-%m-%d %H:%M:%S'),
    Time::Piece->strptime("2024-01-06 00-00-00", '%Y-%m-%d %H:%M:%S'),
  ];
  
  my $ndarray_vector = TPOP->c($data);
  
  my $ndarray_vector = TPOP->c(["2024-01-01", "2024-01-02"]);
  
  my $ndarray_vector = TPOP->c(["2024-01-01 12:01:05", "2024-01-02 12:01:10"]);
  
  my $ndarray = TPOP->c($data, [3, 2]);
  
  my $ndarray2 = TPOP->c($ndarray);

=head1 Class Methods

=head2 c

C<static method c : R::NDArray::Time::Piece ($data : object of L<Time::Piece|SPVM::Time::Piece>|L<Time::Piece|SPVM::Time::Piece>[]|L<R::NDArray::Time::Piece|SPVM::R::NDArray::Time::Piece>|string|string[]|L<R::NDArray::String|SPVM::R::NDArray::String>, $dim : int[] = undef);>

Creates a new L<R::NDArray::Time::Piece|SPVM::R::NDArray::Time::Piece> object given the data $data and the dimensions $dim.

Implemetation:

If $data is defined and the type of $data is L<Time::Piece|SPVM::Time::Piece>, $data is set to C<[(Time::Piece)$data]>.

If $data is defined and the type of $data is L<R::NDArray::Time::Piece|SPVM::R::NDArray::Time::Piece>, $dim is set to C<$data-E<gt>(R::NDArray::Time::Piece)-E<gt>dim> unless $dim is defined and $data is set to C<$data-E<gt>(R::NDArray::Time::Piece)-E<gt>data>.

If $data is defined and the type of $data is C<string>, $data is set to C<R::OP::String-E<gt>c($data)-E<gt>to_time_piece_ndarray-E<gt>data>.

If $data is defined and the type of $data is C<string[]>, $data is set to the return value of C<R::OP::String-E<gt>c($data)-E<gt>to_time_piece_ndarray-E<gt>data>.

If $data is defined and the type of $data is L<R::NDArray::String|SPVM::R::NDArray::String>, $dim is set to C<$data-E<gt>(R::NDArray::String)-E<gt>dim> unless $dim is defined and $data is set to C<$data-E<gt>(R::NDArray::String)-E<gt>to_time_piece_ndarray-E<gt>data>.

And this method calls L<R::NDArray::Time::Piece#new|SPVM::R::NDArray::Time::Piece/"new"> method given $dim and $data.

Exceptions:

The type of the data $data must be Time::Piece, Time::Piece[], R::NDArray::Time::Piece, string, string[], R::NDArray::String if defined. Othrewise, an exception is thrown.

=head2 eq

C<static method eq : L<R::NDArray::Int|SPVM::R::NDArray::Int> ($x_ndarray : L<R::NDArray::Time::Piece|SPVM::R::NDArray::Time::Piece>, $y_ndarray : L<R::NDArray::Time::Piece|SPVM::R::NDArray::Time::Piece>);>

Creates a new L<R::NDArray::Int|SPVM::R::NDArray::Int> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, performs the comparison logic C<$x_ndarray-E<gt>L<elem_cmp|SPVM::R::NDArray::Time::Piece/"elem_cmp">($x_ndarray-E<gt>data, $i, $y_ndarray-E<gt>data, $i) == 0> on the each element(the index is $i) of the n-dimensional array $x_ndarray and $y_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

The n-dimensional array $y_ndarray must be defined. Otherwise, an exception is thrown.

The dimensions of $x_ndarray must be equal to the dimensions of $y_ndarray. Otherwise, an exception is thrown.

=head2 ne

C<static method ne : L<R::NDArray::Int|SPVM::R::NDArray::Int> ($x_ndarray : L<R::NDArray::Time::Piece|SPVM::R::NDArray::Time::Piece>, $y_ndarray : L<R::NDArray::Time::Piece|SPVM::R::NDArray::Time::Piece>);>

Creates a new L<R::NDArray::Int|SPVM::R::NDArray::Int> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, performs the comparison logic C<$x_ndarray-E<gt>L<elem_cmp|SPVM::R::NDArray::Time::Piece/"elem_cmp">($x_ndarray-E<gt>data, $i, $y_ndarray-E<gt>data, $i) != 0> on the each element(the index is $i) of the n-dimensional array $x_ndarray and $y_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

The n-dimensional array $y_ndarray must be defined. Otherwise, an exception is thrown.

The dimensions of $x_ndarray must be equal to the dimensions of $y_ndarray. Otherwise, an exception is thrown.

=head2 gt

C<static method gt : L<R::NDArray::Int|SPVM::R::NDArray::Int> ($x_ndarray : L<R::NDArray::Time::Piece|SPVM::R::NDArray::Time::Piece>, $y_ndarray : L<R::NDArray::Time::Piece|SPVM::R::NDArray::Time::Piece>);>

Creates a new L<R::NDArray::Int|SPVM::R::NDArray::Int> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, performs the comparison logic C<$x_ndarray-E<gt>L<elem_cmp|SPVM::R::NDArray::Time::Piece/"elem_cmp">($x_ndarray-E<gt>data, $i, $y_ndarray-E<gt>data, $i) E<gt> 0> on the each element(the index is $i) of the n-dimensional array $x_ndarray and $y_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

The n-dimensional array $y_ndarray must be defined. Otherwise, an exception is thrown.

The dimensions of $x_ndarray must be equal to the dimensions of $y_ndarray. Otherwise, an exception is thrown.

=head2 ge

C<static method ge : L<R::NDArray::Int|SPVM::R::NDArray::Int> ($x_ndarray : L<R::NDArray::Time::Piece|SPVM::R::NDArray::Time::Piece>, $y_ndarray : L<R::NDArray::Time::Piece|SPVM::R::NDArray::Time::Piece>);>

Creates a new L<R::NDArray::Int|SPVM::R::NDArray::Int> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, performs the comparison logic C<$x_ndarray-E<gt>L<elem_cmp|SPVM::R::NDArray::Time::Piece/"elem_cmp">($x_ndarray-E<gt>data, $i, $y_ndarray-E<gt>data, $i) E<gt>= 0> on the each element(the index is $i) of the n-dimensional array $x_ndarray and $y_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

The n-dimensional array $y_ndarray must be defined. Otherwise, an exception is thrown.

The dimensions of $x_ndarray must be equal to the dimensions of $y_ndarray. Otherwise, an exception is thrown.

=head2 lt

C<static method lt : L<R::NDArray::Int|SPVM::R::NDArray::Int> ($x_ndarray : L<R::NDArray::Time::Piece|SPVM::R::NDArray::Time::Piece>, $y_ndarray : L<R::NDArray::Time::Piece|SPVM::R::NDArray::Time::Piece>);>

Creates a new L<R::NDArray::Int|SPVM::R::NDArray::Int> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, performs the comparison logic C<$x_ndarray-E<gt>L<elem_cmp|SPVM::R::NDArray::Time::Piece/"elem_cmp">($x_ndarray-E<gt>data, $i, $y_ndarray-E<gt>data, $i) E<lt> 0> on the each element(the index is $i) of the n-dimensional array $x_ndarray and $y_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

The n-dimensional array $y_ndarray must be defined. Otherwise, an exception is thrown.

The dimensions of $x_ndarray must be equal to the dimensions of $y_ndarray. Otherwise, an exception is thrown.

=head2 le

C<static method le : L<R::NDArray::Int|SPVM::R::NDArray::Int> ($x_ndarray : L<R::NDArray::Time::Piece|SPVM::R::NDArray::Time::Piece>, $y_ndarray : L<R::NDArray::Time::Piece|SPVM::R::NDArray::Time::Piece>);>

Creates a new L<R::NDArray::Int|SPVM::R::NDArray::Int> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, performs the comparison logic C<$x_ndarray-E<gt>L<elem_cmp|SPVM::R::NDArray::Time::Piece/"elem_cmp">($x_ndarray-E<gt>data, $i, $y_ndarray-E<gt>data, $i) E<lt>= 0> on the each element(the index is $i) of the n-dimensional array $x_ndarray and $y_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

The n-dimensional array $y_ndarray must be defined. Otherwise, an exception is thrown.

The dimensions of $x_ndarray must be equal to the dimensions of $y_ndarray. Otherwise, an exception is thrown.

=head2 rep

C<static method rep : L<R::NDArray::Time::Piece|SPVM::R::NDArray::Time::Piece> ($x_ndarray : L<R::NDArray::Time::Piece|SPVM::R::NDArray::Time::Piece>, $times : int);>

Same as L<R::OP#rep|SPVM::R::OP/"rep"> method, but the return type is different.

=head2 rep_length

C<static method rep_length : L<R::NDArray::Time::Piece|SPVM::R::NDArray::Time::Piece> ($x_ndarray : L<R::NDArray::Time::Piece|SPVM::R::NDArray::Time::Piece>, $length : int);>

Same as L<R::OP#rep_length|SPVM::R::OP/"rep_length"> method, but the return type is different.

=head1 See Also

=over 2

=item * L<R::OP|SPVM::R::OP>

=item * L<R::NDArray::Time::Piece|SPVM::R::NDArray::Time::Piece>

=item * L<R::NDArray|SPVM::R::NDArray>

=item * L<R|SPVM::R>

=back

=head1 Copyright & License

Copyright (c) 2024 Yuki Kimoto

MIT License

