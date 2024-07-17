package SPVM::R::OP::Double;



1;

=head1 Name

SPVM::R::OP::Double - N-Dimensional Array Operations for R::NDArray::Double

=head1 Description

The R::OP::Double class in L<SPVM> has methods for n-dimensional array operations for L<R::NDArray::Double|SPVM::R::NDArray::Double>.

=head1 Usage

  use R::OP::Double as DOP;
  
  my $ndarray_scalar = DOP->c((double)1);
  
  my $ndarray_vector = DOP->c([(double)1, 2, 3]);
  
  my $ndarray = DOP->c([(double)1, 2, 3, 4, 5, 6], [3, 2]);
  
  my $ndarray2 = DOP->c($ndarray);

=head1 Class Methods

=head2 c

C<static method c : L<R::NDArray::Double|SPVM::R::NDArray::Double> ($data : object of L<Double|SPVM::Double>|double[]|L<R::NDArray::Double|SPVM::R::NDArray::Double>, $dim : int[] = undef);>

=head2 add

C<static method add : L<R::NDArray::Double|SPVM::R::NDArray::Double> ($x_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>, $y_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>);>

Creates a new L<R::NDArray::Double|SPVM::R::NDArray::Double> object for a return value, performs addition operations on each element of the n-dimensional array $x_ndarray and $y_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

The n-dimensional array $y_ndarray must be defined. Otherwise, an exception is thrown.

The dim field of $x_ndarray must be equal to the dim field of $y_ndarray. Otherwise, an exception is thrown.

=head2 sub

C<static method sub : L<R::NDArray::Double|SPVM::R::NDArray::Double> ($x_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>, $y_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>);>

Creates a new L<R::NDArray::Double|SPVM::R::NDArray::Double> object for a return value, performs subtraction operations on each element of the n-dimensional array $x_ndarray and $y_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

The n-dimensional array $y_ndarray must be defined. Otherwise, an exception is thrown.

The dim field of $x_ndarray must be equal to the dim field of $y_ndarray. Otherwise, an exception is thrown.

=head2 mul

C<static method mul : L<R::NDArray::Double|SPVM::R::NDArray::Double> ($x_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>, $y_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>);>

Creates a new L<R::NDArray::Double|SPVM::R::NDArray::Double> object for a return value, performs multiplication operations on each element of the n-dimensional array $x_ndarray and $y_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

The n-dimensional array $y_ndarray must be defined. Otherwise, an exception is thrown.

The dim field of $x_ndarray must be equal to the dim field of $y_ndarray. Otherwise, an exception is thrown.

=head2 scamul

C<static method scamul : R::NDArray::Int ($x_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>, $scalar_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>);>

Creates a new L<R::NDArray::Double|SPVM::R::NDArray::Double> object for a return value, performs multiplication operations on each element of the n-dimensional array $x_ndarray, and sets each element of the new n-dimensional array and the n-dimensional array $scalar_ndarray at data index 0 to the each operation result, and returns the new n-dimensional array.

Exceptions:

The n-dimensional array $scalar_ndarray must be defined. Otherwise, an exception is thrown.

The n-dmension array $scalar_ndarray must be a L<scalar|SPVM::R::NDArray/"Scalar">.

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

=head2 div

C<static method div : L<R::NDArray::Double|SPVM::R::NDArray::Double> ($x_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>, $y_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>);>

Creates a new L<R::NDArray::Double|SPVM::R::NDArray::Double> object for a return value, performs division operations on each element of the n-dimensional array $x_ndarray and $y_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

The n-dimensional array $y_ndarray must be defined. Otherwise, an exception is thrown.

The dim field of $x_ndarray must be equal to the dim field of $y_ndarray. Otherwise, an exception is thrown.

=head2 scadiv

C<static method scadiv : R::NDArray::Int ($x_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>, $scalar_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>);>

Creates a new L<R::NDArray::Double|SPVM::R::NDArray::Double> object for a return value, performs division operations on the n-dimensional array $scalar_ndarray at data index 0 and each element of the n-dimensional array $x_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.

Exceptions:

The n-dimensional array $scalar_ndarray must be defined. Otherwise, an exception is thrown.

The n-dmension array $scalar_ndarray must be a L<scalar|SPVM::R::NDArray/"Scalar">.

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

=head2 neg

C<static method neg : L<R::NDArray::Double|SPVM::R::NDArray::Double> ($x_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>);>

=head2 abs

C<static method abs : L<R::NDArray::Double|SPVM::R::NDArray::Double> ($x_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>);>

=head2 eq

C<static method eq : R::NDArray::Int ($x_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>, $y_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>);>

=head2 ne

C<static method ne : R::NDArray::Int ($x_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>, $y_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>);>

=head2 gt

C<static method gt : R::NDArray::Int ($x_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>, $y_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>);>

=head2 ge

C<static method ge : R::NDArray::Int ($x_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>, $y_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>);>

=head2 lt

C<static method lt : R::NDArray::Int ($x_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>, $y_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>);>

=head2 le

C<static method le : R::NDArray::Int ($x_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>, $y_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>);>

=head2 rep

C<static method rep : L<R::NDArray::Double|SPVM::R::NDArray::Double> ($x_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>, $times : int);>

=head2 rep_length

C<static method rep_length : L<R::NDArray::Double|SPVM::R::NDArray::Double> ($x_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>, $length : int);>

=head2 seq

C<static method seq : L<R::NDArray::Double|SPVM::R::NDArray::Double> ($begin : double, $end : double, $by : double = 1);>

=head2 seq_length

C<static method seq_length : L<R::NDArray::Double|SPVM::R::NDArray::Double> ($begin : double, $end : double, $length : int);>

=head2 sin

C<static method sin : L<R::NDArray::Double|SPVM::R::NDArray::Double> ($x_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>);>

=head2 cos

C<static method cos : L<R::NDArray::Double|SPVM::R::NDArray::Double> ($x_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>);>

=head2 tan

C<static method tan : L<R::NDArray::Double|SPVM::R::NDArray::Double> ($x_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>);>

=head2 sinh

C<static method sinh : L<R::NDArray::Double|SPVM::R::NDArray::Double> ($x_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>);>

=head2 cosh

C<static method cosh : L<R::NDArray::Double|SPVM::R::NDArray::Double> ($x_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>);>

=head2 tanh

C<static method tanh : L<R::NDArray::Double|SPVM::R::NDArray::Double> ($x_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>);>

=head2 acos

C<static method acos : L<R::NDArray::Double|SPVM::R::NDArray::Double> ($x_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>);>

=head2 asin

C<static method asin : L<R::NDArray::Double|SPVM::R::NDArray::Double> ($x_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>);>

=head2 atan

C<static method atan : L<R::NDArray::Double|SPVM::R::NDArray::Double> ($x_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>);>

=head2 asinh

C<static method asinh : L<R::NDArray::Double|SPVM::R::NDArray::Double> ($x_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>);>

=head2 acosh

C<static method acosh : L<R::NDArray::Double|SPVM::R::NDArray::Double> ($x_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>);>

=head2 atanh

C<static method atanh : L<R::NDArray::Double|SPVM::R::NDArray::Double> ($x_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>);>

=head2 exp

C<static method exp : L<R::NDArray::Double|SPVM::R::NDArray::Double> ($x_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>);>

=head2 expm1

C<static method expm1 : L<R::NDArray::Double|SPVM::R::NDArray::Double> ($x_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>);>

=head2 log

C<static method log : L<R::NDArray::Double|SPVM::R::NDArray::Double> ($x_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>);>

=head2 logb

C<static method logb : L<R::NDArray::Double|SPVM::R::NDArray::Double> ($x_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>);>

=head2 log2

C<static method log2 : L<R::NDArray::Double|SPVM::R::NDArray::Double> ($x_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>);>

=head2 log10

C<static method log10 : L<R::NDArray::Double|SPVM::R::NDArray::Double> ($x_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>);>

=head2 sqrt

C<static method sqrt : L<R::NDArray::Double|SPVM::R::NDArray::Double> ($x_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>);>

=head2 isinf

C<static method isinf : L<R::NDArray::Int|SPVM::R::NDArray::Int> ($x_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>);>

=head2 is_infinite

C<static method is_infinite : L<R::NDArray::Int|SPVM::R::NDArray::Int> ($x_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>);>

=head2 is_finite

C<static method is_finite : L<R::NDArray::Int|SPVM::R::NDArray::Int> ($x_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>);>

=head2 isnan

C<static method isnan : L<R::NDArray::Int|SPVM::R::NDArray::Int> ($x_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>);>

=head2 is_nan

C<static method is_nan : L<R::NDArray::Int|SPVM::R::NDArray::Int> ($x_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>);>

=head2 pow

C<static method pow : L<R::NDArray::Double|SPVM::R::NDArray::Double> ($x_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>, $y_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>);>

=head2 atan2

C<static method atan2 : L<R::NDArray::Double|SPVM::R::NDArray::Double> ($y_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>, $x_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>);>

=head2 modf

C<static method modf : L<R::NDArray::Double|SPVM::R::NDArray::Double> ($x_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>, $intpart_ndarray_ref : L<R::NDArray::Double|SPVM::R::NDArray::Double>[]);>

=head2 ceil

C<static method ceil : L<R::NDArray::Double|SPVM::R::NDArray::Double> ($x_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>);>

=head2 ceiling

C<static method ceiling : L<R::NDArray::Double|SPVM::R::NDArray::Double> ($x_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>);>

=head2 floor

C<static method floor : L<R::NDArray::Double|SPVM::R::NDArray::Double> ($x_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>);>

=head2 round

C<static method round : L<R::NDArray::Double|SPVM::R::NDArray::Double> ($x_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>);>

=head2 lround

C<static method lround : R::NDArray::Long ($x_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>);>

=head2 remainder

C<static method remainder : L<R::NDArray::Double|SPVM::R::NDArray::Double> ($x_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>, $y_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>);>

=head2 fmod

C<static method fmod : L<R::NDArray::Double|SPVM::R::NDArray::Double> ($x_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>, $y_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>);>

=head2 sum

C<static method sum : L<R::NDArray::Double|SPVM::R::NDArray::Double> ($x_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>);>

=head2 cumsum

C<static method cumsum : L<R::NDArray::Double|SPVM::R::NDArray::Double> ($x_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>);>

=head2 prod

C<static method prod : L<R::NDArray::Double|SPVM::R::NDArray::Double> ($x_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>);>

=head2 cumprod

C<static method cumprod : L<R::NDArray::Double|SPVM::R::NDArray::Double> ($x_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>);>

=head2 diff

C<static method diff : L<R::NDArray::Double|SPVM::R::NDArray::Double> ($x_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>);>

=head2 max

C<static method max : L<R::NDArray::Double|SPVM::R::NDArray::Double> ($x_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>);>

=head2 min

C<static method min : L<R::NDArray::Double|SPVM::R::NDArray::Double> ($x_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>);>

=head2 mean

C<static method mean : L<R::NDArray::Double|SPVM::R::NDArray::Double> ($x_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>);>

=head2 inner

C<static method inner : L<R::NDArray::Double|SPVM::R::NDArray::Double> ($x_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>, $y_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>);>

=head2 cross

C<static method cross : L<R::NDArray::Double|SPVM::R::NDArray::Double> ($x_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>, $y_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>);>

=head2 outer

C<static method outer : L<R::NDArray::Double|SPVM::R::NDArray::Double> ($x_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>, $y_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>);>

=head1 See Also

=over 2

=item * L<R::NDArray::Double|SPVM::R::NDArray::Double>

=item * L<R::NDArray|SPVM::R::NDArray>

=item * L<R|SPVM::R>

=back

=head1 Copyright & License

Copyright (c) 2024 Yuki Kimoto

MIT License

