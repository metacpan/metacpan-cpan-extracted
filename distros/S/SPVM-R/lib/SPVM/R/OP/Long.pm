package SPVM::R::OP::Long;



1;

=head1 Name

SPVM::R::OP::Long - N-Dimensional Array Operations for R::NDArray::Long

=head1 Description

R::OP::Long class in L<SPVM> has methods for n-dimensional array operations for L<R::NDArray::Long|SPVM::R::NDArray::Long>.

=head1 Usage

  use R::OP::Long as LOP;
  
  my $ndarray_scalar = LOP->c((long)1);
  
  my $ndarray_vector = LOP->c([(long)1, 2, 3]);
  
  my $ndarray = LOP->c([(long)1, 2, 3, 4, 5, 6], [3, 2]);
  
  my $ndarray2 = LOP->c($ndarray);

=head1 Class Methods

=head2 c

C<static method c : L<R::NDArray::Long|SPVM::R::NDArray::Long> ($data : object of L<Long|SPVM::Long>|long[]|L<R::NDArray::Long|SPVM::R::NDArray::Long>, $dim : long[] = undef);>

Creates a new L<R::NDArray::Long|SPVM::R::NDArray::Long> object given the data $data and the dimensions $dim.

Implemetation:

If $data is defined and the type of $data is L<Long|SPVM::Long>, $data is set to C<[(long)$data->(Long)]>.

If $data is defined and the type of $data is L<R::NDArray::Long|SPVM::R::NDArray::Long>, $dim is set to C<$data-E<gt>(R::NDArray::Long)-E<gt>dim> unless $dim is defined and $data is set to C<$data-E<gt>(R::NDArray::Long)-E<gt>data>.

And this method calls L<R::NDArray::Long#new|SPVM::R::NDArray::Long/"new"> method given $dim and $data.

Exceptions:

The type of the data $data must be Long, long[], or R::NDArray::Long if defined. Othrewise, an exception is thrown.

=head2 add

C<static method add : L<R::NDArray::Long|SPVM::R::NDArray::Long> ($x_ndarray : L<R::NDArray::Long|SPVM::R::NDArray::Long>, $y_ndarray : L<R::NDArray::Long|SPVM::R::NDArray::Long>);>

Creates a new L<R::NDArray::Long|SPVM::R::NDArray::Long> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, performs addition C<+> operation on each element of the n-dimensional array $x_ndarray and $y_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

The n-dimensional array $y_ndarray must be defined. Otherwise, an exception is thrown.

The dimensions of $x_ndarray must be equal to the dimensions of $y_ndarray. Otherwise, an exception is thrown.

=head2 sub

C<static method sub : L<R::NDArray::Long|SPVM::R::NDArray::Long> ($x_ndarray : L<R::NDArray::Long|SPVM::R::NDArray::Long>, $y_ndarray : L<R::NDArray::Long|SPVM::R::NDArray::Long>);>

Creates a new L<R::NDArray::Long|SPVM::R::NDArray::Long> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, performs subtraction C<-> operation on each element of the n-dimensional array $x_ndarray and $y_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

The n-dimensional array $y_ndarray must be defined. Otherwise, an exception is thrown.

The dimensions of $x_ndarray must be equal to the dimensions of $y_ndarray. Otherwise, an exception is thrown.

=head2 mul

C<static method mul : L<R::NDArray::Long|SPVM::R::NDArray::Long> ($x_ndarray : L<R::NDArray::Long|SPVM::R::NDArray::Long>, $y_ndarray : L<R::NDArray::Long|SPVM::R::NDArray::Long>);>

Creates a new L<R::NDArray::Long|SPVM::R::NDArray::Long> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, performs multiplication C<*> operation on each element of the n-dimensional array $x_ndarray and $y_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

The n-dimensional array $y_ndarray must be defined. Otherwise, an exception is thrown.

The dimensions of $x_ndarray must be equal to the dimensions of $y_ndarray. Otherwise, an exception is thrown.

=head2 scamul

C<static method scamul : L<R::NDArray::Long|SPVM::R::NDArray::Long> ($x_ndarray : L<R::NDArray::Long|SPVM::R::NDArray::Long>, $scalar_ndarray : L<R::NDArray::Long|SPVM::R::NDArray::Long>);>

Creates a new L<R::NDArray::Long|SPVM::R::NDArray::Long> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, performs multiplication C<*> operation on each element of the n-dimensional array $x_ndarray, and sets each element of the new n-dimensional array and the n-dimensional array $scalar_ndarray at data index 0 to the each operation result, and returns the new n-dimensional array.

Exceptions:

The n-dimensional array $scalar_ndarray must be defined. Otherwise, an exception is thrown.

The n-dmension array $scalar_ndarray must be a L<scalar|SPVM::R::NDArray/"Scalar">.

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

=head2 div

C<static method div : L<R::NDArray::Long|SPVM::R::NDArray::Long> ($x_ndarray : L<R::NDArray::Long|SPVM::R::NDArray::Long>, $y_ndarray : L<R::NDArray::Long|SPVM::R::NDArray::Long>);>

Creates a new L<R::NDArray::Long|SPVM::R::NDArray::Long> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, performs division C</> operation on each element of the n-dimensional array $x_ndarray and $y_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

The n-dimensional array $y_ndarray must be defined. Otherwise, an exception is thrown.

The dimensions of $x_ndarray must be equal to the dimensions of $y_ndarray. Otherwise, an exception is thrown.

=head2 scadiv

C<static method scadiv : L<R::NDArray::Long|SPVM::R::NDArray::Long> ($x_ndarray : L<R::NDArray::Long|SPVM::R::NDArray::Long>, $scalar_ndarray : L<R::NDArray::Long|SPVM::R::NDArray::Long>);>

Creates a new L<R::NDArray::Long|SPVM::R::NDArray::Long> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, performs division C</> operations on the n-dimensional array $scalar_ndarray at data index 0 and each element of the n-dimensional array $x_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.

Exceptions:

The n-dimensional array $scalar_ndarray must be defined. Otherwise, an exception is thrown.

The n-dmension array $scalar_ndarray must be a L<scalar|SPVM::R::NDArray/"Scalar">.

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

=head2 div_u

C<static method div_u : L<R::NDArray::Long|SPVM::R::NDArray::Long> ($x_ndarray : L<R::NDArray::Long|SPVM::R::NDArray::Long>, $y_ndarray : L<R::NDArray::Long|SPVM::R::NDArray::Long>);>

Creates a new L<R::NDArray::Long|SPVM::R::NDArray::Long> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, performs unsigned division C<div_ulong> operation on each element of the n-dimensional array $x_ndarray and $y_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

The n-dimensional array $y_ndarray must be defined. Otherwise, an exception is thrown.

The dimensions of $x_ndarray must be equal to the dimensions of $y_ndarray. Otherwise, an exception is thrown.

=head2 mod

C<static method mod : L<R::NDArray::Long|SPVM::R::NDArray::Long> ($x_ndarray : L<R::NDArray::Long|SPVM::R::NDArray::Long>, $y_ndarray : L<R::NDArray::Long|SPVM::R::NDArray::Long>);>

Creates a new L<R::NDArray::Long|SPVM::R::NDArray::Long> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, performs modulo C<%> operation on each element of the n-dimensional array $x_ndarray and $y_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

The n-dimensional array $y_ndarray must be defined. Otherwise, an exception is thrown.

The dimensions of $x_ndarray must be equal to the dimensions of $y_ndarray. Otherwise, an exception is thrown.

=head2 mod_u

C<static method mod_u : L<R::NDArray::Long|SPVM::R::NDArray::Long> ($x_ndarray : L<R::NDArray::Long|SPVM::R::NDArray::Long>, $y_ndarray : L<R::NDArray::Long|SPVM::R::NDArray::Long>);>

Creates a new L<R::NDArray::Long|SPVM::R::NDArray::Long> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, performs unsigned modulo C<mod_ulong> operation on each element of the n-dimensional array $x_ndarray and $y_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

The n-dimensional array $y_ndarray must be defined. Otherwise, an exception is thrown.

The dimensions of $x_ndarray must be equal to the dimensions of $y_ndarray. Otherwise, an exception is thrown.

=head2 neg

C<static method neg : L<R::NDArray::Long|SPVM::R::NDArray::Long> ($x_ndarray : L<R::NDArray::Long|SPVM::R::NDArray::Long>);>

Creates a new L<R::NDArray::Long|SPVM::R::NDArray::Long> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, performs negation C<-> operation on each element of the n-dimensional array $x_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

=head2 abs

C<static method abs : L<R::NDArray::Long|SPVM::R::NDArray::Long> ($x_ndarray : L<R::NDArray::Long|SPVM::R::NDArray::Long>);>

Creates a new L<R::NDArray::Long|SPVM::R::NDArray::Long> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, performs L<Fn#labs|SPVM::Fn/"labs"> method on each element of the n-dimensional array $x_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

=head2 eq

C<static method eq : L<R::NDArray::Int|SPVM::R::NDArray::Int> ($x_ndarray : L<R::NDArray::Long|SPVM::R::NDArray::Long>, $y_ndarray : L<R::NDArray::Long|SPVM::R::NDArray::Long>);>

Creates a new L<R::NDArray::Int|SPVM::R::NDArray::Int> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, performs numeric comparison C<==> operation on each element of the n-dimensional array $x_ndarray and $y_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

The n-dimensional array $y_ndarray must be defined. Otherwise, an exception is thrown.

The dimensions of $x_ndarray must be equal to the dimensions of $y_ndarray. Otherwise, an exception is thrown.

=head2 ne

C<static method ne : L<R::NDArray::Int|SPVM::R::NDArray::Int> ($x_ndarray : L<R::NDArray::Long|SPVM::R::NDArray::Long>, $y_ndarray : L<R::NDArray::Long|SPVM::R::NDArray::Long>);>

Creates a new L<R::NDArray::Int|SPVM::R::NDArray::Int> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, performs numeric comparison C<!=> operation on each element of the n-dimensional array $x_ndarray and $y_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

The n-dimensional array $y_ndarray must be defined. Otherwise, an exception is thrown.

The dimensions of $x_ndarray must be equal to the dimensions of $y_ndarray. Otherwise, an exception is thrown.

=head2 gt

C<static method gt : L<R::NDArray::Int|SPVM::R::NDArray::Int> ($x_ndarray : L<R::NDArray::Long|SPVM::R::NDArray::Long>, $y_ndarray : L<R::NDArray::Long|SPVM::R::NDArray::Long>);>

Creates a new L<R::NDArray::Int|SPVM::R::NDArray::Int> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, performs numeric comparison C<E<gt>> operation on each element of the n-dimensional array $x_ndarray and $y_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

The n-dimensional array $y_ndarray must be defined. Otherwise, an exception is thrown.

The dimensions of $x_ndarray must be equal to the dimensions of $y_ndarray. Otherwise, an exception is thrown.

=head2 ge

C<static method ge : L<R::NDArray::Int|SPVM::R::NDArray::Int> ($x_ndarray : L<R::NDArray::Long|SPVM::R::NDArray::Long>, $y_ndarray : L<R::NDArray::Long|SPVM::R::NDArray::Long>);>

Creates a new L<R::NDArray::Int|SPVM::R::NDArray::Int> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, performs numeric comparison C<E<gt>=> operation on each element of the n-dimensional array $x_ndarray and $y_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

The n-dimensional array $y_ndarray must be defined. Otherwise, an exception is thrown.

The dimensions of $x_ndarray must be equal to the dimensions of $y_ndarray. Otherwise, an exception is thrown.

=head2 lt

C<static method lt : L<R::NDArray::Int|SPVM::R::NDArray::Int> ($x_ndarray : L<R::NDArray::Long|SPVM::R::NDArray::Long>, $y_ndarray : L<R::NDArray::Long|SPVM::R::NDArray::Long>);>

Creates a new L<R::NDArray::Int|SPVM::R::NDArray::Int> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, performs numeric comparison C<E<lt>> operation on each element of the n-dimensional array $x_ndarray and $y_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

The n-dimensional array $y_ndarray must be defined. Otherwise, an exception is thrown.

The dimensions of $x_ndarray must be equal to the dimensions of $y_ndarray. Otherwise, an exception is thrown.

=head2 le

C<static method le : L<R::NDArray::Int|SPVM::R::NDArray::Int> ($x_ndarray : L<R::NDArray::Long|SPVM::R::NDArray::Long>, $y_ndarray : L<R::NDArray::Long|SPVM::R::NDArray::Long>);>

Creates a new L<R::NDArray::Int|SPVM::R::NDArray::Int> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, performs numeric comparison C<E<lt>=> operation on each element of the n-dimensional array $x_ndarray and $y_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

The n-dimensional array $y_ndarray must be defined. Otherwise, an exception is thrown.

The dimensions of $x_ndarray must be equal to the dimensions of $y_ndarray. Otherwise, an exception is thrown.

=head2 rep

C<static method rep : L<R::NDArray::Long|SPVM::R::NDArray::Long> ($x_ndarray : L<R::NDArray::Long|SPVM::R::NDArray::Long>, $times : int);>

Same as L<R::OP#rep|SPVM::R::OP/"rep"> method, but the return type is different.

=head2 rep_length

C<static method rep_length : L<R::NDArray::Long|SPVM::R::NDArray::Long> ($x_ndarray : L<R::NDArray::Long|SPVM::R::NDArray::Long>, $length : int);>

Same as L<R::OP#rep_length|SPVM::R::OP/"rep_length"> method, but the return type is different.

=head2 seq

C<static method seq : L<R::NDArray::Long|SPVM::R::NDArray::Long> ($begin : long, $end : long, $by : long = 1);>

Creates a L<R::NDArray::Long|SPVM::R::NDArray::Long> object from $bigin to $end at intervals of $by.

Exceptions:

$by must not be 0. Otherwise, an exception is thrown.

If $by is greater than 0 and $end is not greater than or equal to $begin, an exception is thrown.

If $by is less than 0 and $end Is not greater than or equal to $begin, an exception is thrown.

=head2 sum

C<static method sum : L<R::NDArray::Long|SPVM::R::NDArray::Long> ($x_ndarray : L<R::NDArray::Long|SPVM::R::NDArray::Long>);>

Creates a new L<R::NDArray::Long|SPVM::R::NDArray::Long> object with the dimenstion C<[1]> for a return value, calculates the sum of all elements of the n-dimensional array $x_ndarray, and sets the element of the new n-dimensional array to the result, and returns the new n-dimensional array.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

=head2 cumsum

C<static method cumsum : L<R::NDArray::Long|SPVM::R::NDArray::Long> ($x_ndarray : L<R::NDArray::Long|SPVM::R::NDArray::Long>);>

Creates a new L<R::NDArray::Long|SPVM::R::NDArray::Long> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, calculates the cumulative sum on each element of the n-dimensional array $x_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.

Examples are
  
  # data
  [(long)3, 1, 4, 1, 5, 9, 2, 6, 5]
  
  # result
  [(long)0, 3, 4, 8, 9, 14, 23, 25, 31, 36]

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

=head2 prod

C<static method prod : L<R::NDArray::Long|SPVM::R::NDArray::Long> ($x_ndarray : L<R::NDArray::Long|SPVM::R::NDArray::Long>);>

Creates a new L<R::NDArray::Long|SPVM::R::NDArray::Long> object with the dimenstion C<[1]> for a return value, calculates the production of all elements of the n-dimensional array $x_ndarray, and sets the element of the new n-dimensional array to the result, and returns the new n-dimensional array.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

=head2 cumprod

C<static method cumprod : L<R::NDArray::Long|SPVM::R::NDArray::Long> ($x_ndarray : L<R::NDArray::Long|SPVM::R::NDArray::Long>);>

Creates a new L<R::NDArray::Long|SPVM::R::NDArray::Long> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, calculates the cumulative product on each element of the n-dimensional array $x_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.

Examples are
  
  # data
  [(long)2, 3, 4, 5]
  
  # result
  [(long)2, 6, 24, 120]

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

=head2 diff

C<static method diff : R::NDArray::Long ($x_ndarray : L<R::NDArray::Long|SPVM::R::NDArray::Long>);>

Creates a new L<R::NDArray::Long|SPVM::R::NDArray::Long> object of the dimensions as the n-dimensional array $x_ndarray minus 1 for a return value, calculats the difference of adjacent elements of the n-dimensional array $x_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.

Examples are
  
  # data
  [(long)2, 4, 7]
  
  # result
  [(long)2, 3]

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

=head2 max

C<static method max : R::NDArray::Long ($x_ndarray : L<R::NDArray::Long|SPVM::R::NDArray::Long>);>

Creates a new L<R::NDArray::Long|SPVM::R::NDArray::Long> object with the dimenstion C<[1]> for a return value, calculates the maximum value of all elements of the n-dimensional array $x_ndarray, and sets the element of the new n-dimensional array to the result, and returns the new n-dimensional array.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

=head2 min

C<static method min : R::NDArray::Long ($x_ndarray : L<R::NDArray::Long|SPVM::R::NDArray::Long>);>

Creates a new L<R::NDArray::Long|SPVM::R::NDArray::Long> object with the dimenstion C<[1]> for a return value, calculates the minimum value of all elements of the n-dimensional array $x_ndarray, and sets the element of the new n-dimensional array to the result, and returns the new n-dimensional array.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

=head1 See Also

=over 2

=item * L<R::OP|SPVM::R::OP>

=item * L<R::NDArray::Long|SPVM::R::NDArray::Long>

=item * L<R::NDArray|SPVM::R::NDArray>

=item * L<R|SPVM::R>

=back

=head1 Copyright & License

Copyright (c) 2024 Yuki Kimoto

MIT License

