package SPVM::R::OP::Double;



1;

=head1 Name

SPVM::R::OP::Double - N-Dimensional Array Operations for R::NDArray::Double

=head1 Description

R::OP::Double class in L<SPVM> has methods for n-dimensional array operations for L<R::NDArray::Double|SPVM::R::NDArray::Double>.

=head1 Usage

  use R::OP::Double as DOP;
  
  my $ndarray_scalar = DOP->c((double)1);
  
  my $ndarray_vector = DOP->c([(double)1, 2, 3]);
  
  my $ndarray = DOP->c([(double)1, 2, 3, 4, 5, 6], [3, 2]);
  
  my $ndarray2 = DOP->c($ndarray);

=head1 Class Methods

=head2 c

C<static method c : L<R::NDArray::Double|SPVM::R::NDArray::Double> ($data : object of L<Double|SPVM::Double>|double[]|L<R::NDArray::Double|SPVM::R::NDArray::Double>, $dim : int[] = undef);>

Creates a new L<R::NDArray::Double|SPVM::R::NDArray::Double> object given the data $data and the dimensions $dim.

Implemetation:

If $data is defined and the type of $data is L<Double|SPVM::Double>, $data is set to C<[(double)$data->(Double)]>.

If $data is defined and the type of $data is L<R::NDArray::Double|SPVM::R::NDArray::Double>, $dim is set to C<$data-E<gt>(R::NDArray::Double)-E<gt>dim> unless $dim is defined and $data is set to C<$data-E<gt>(R::NDArray::Double)-E<gt>data>.

And this method calls L<R::NDArray::Double#new|SPVM::R::NDArray::Double/"new"> method given $dim and $data.

Exceptions:

The type of the data $data must be Double, double[], or R::NDArray::Double if defined. Othrewise, an exception is thrown.

=head2 add

C<static method add : L<R::NDArray::Double|SPVM::R::NDArray::Double> ($x_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>, $y_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>);>

Creates a new L<R::NDArray::Double|SPVM::R::NDArray::Double> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, performs addition C<+> operation on each element of the n-dimensional array $x_ndarray and $y_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

The n-dimensional array $y_ndarray must be defined. Otherwise, an exception is thrown.

The dimensions of $x_ndarray must be equal to the dimensions of $y_ndarray. Otherwise, an exception is thrown.

=head2 sub

C<static method sub : L<R::NDArray::Double|SPVM::R::NDArray::Double> ($x_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>, $y_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>);>

Creates a new L<R::NDArray::Double|SPVM::R::NDArray::Double> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, performs subtraction C<-> operation on each element of the n-dimensional array $x_ndarray and $y_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

The n-dimensional array $y_ndarray must be defined. Otherwise, an exception is thrown.

The dimensions of $x_ndarray must be equal to the dimensions of $y_ndarray. Otherwise, an exception is thrown.

=head2 mul

C<static method mul : L<R::NDArray::Double|SPVM::R::NDArray::Double> ($x_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>, $y_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>);>

Creates a new L<R::NDArray::Double|SPVM::R::NDArray::Double> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, performs multiplication C<*> operation on each element of the n-dimensional array $x_ndarray and $y_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

The n-dimensional array $y_ndarray must be defined. Otherwise, an exception is thrown.

The dimensions of $x_ndarray must be equal to the dimensions of $y_ndarray. Otherwise, an exception is thrown.

=head2 scamul

C<static method scamul : L<R::NDArray::Double|SPVM::R::NDArray::Double> ($x_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>, $scalar_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>);>

Creates a new L<R::NDArray::Double|SPVM::R::NDArray::Double> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, performs multiplication C<*> operation on each element of the n-dimensional array $x_ndarray, and sets each element of the new n-dimensional array and the n-dimensional array $scalar_ndarray at data index 0 to the each operation result, and returns the new n-dimensional array.

Exceptions:

The n-dimensional array $scalar_ndarray must be defined. Otherwise, an exception is thrown.

The n-dmension array $scalar_ndarray must be a L<scalar|SPVM::R::NDArray/"Scalar">.

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

=head2 div

C<static method div : L<R::NDArray::Double|SPVM::R::NDArray::Double> ($x_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>, $y_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>);>

Creates a new L<R::NDArray::Double|SPVM::R::NDArray::Double> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, performs division C</> operation on each element of the n-dimensional array $x_ndarray and $y_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

The n-dimensional array $y_ndarray must be defined. Otherwise, an exception is thrown.

The dimensions of $x_ndarray must be equal to the dimensions of $y_ndarray. Otherwise, an exception is thrown.

=head2 scadiv

C<static method scadiv : L<R::NDArray::Double|SPVM::R::NDArray::Double> ($x_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>, $scalar_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>);>

Creates a new L<R::NDArray::Double|SPVM::R::NDArray::Double> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, performs division C</> operations on the n-dimensional array $scalar_ndarray at data index 0 and each element of the n-dimensional array $x_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.

Exceptions:

The n-dimensional array $scalar_ndarray must be defined. Otherwise, an exception is thrown.

The n-dmension array $scalar_ndarray must be a L<scalar|SPVM::R::NDArray/"Scalar">.

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

=head2 neg

C<static method neg : L<R::NDArray::Double|SPVM::R::NDArray::Double> ($x_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>);>

Creates a new L<R::NDArray::Double|SPVM::R::NDArray::Double> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, performs negation C<-> operation on each element of the n-dimensional array $x_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

=head2 abs

C<static method abs : L<R::NDArray::Double|SPVM::R::NDArray::Double> ($x_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>);>

Creates a new L<R::NDArray::Double|SPVM::R::NDArray::Double> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, performs L<Math#fabs|SPVM::Math/"fabs"> method on each element of the n-dimensional array $x_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

=head2 eq

C<static method eq : L<R::NDArray::Double|SPVM::R::NDArray::Double> ($x_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>, $y_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>);>

Creates a new L<R::NDArray::Int|SPVM::R::NDArray::Int> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, performs numeric comparison C<==> operation on each element of the n-dimensional array $x_ndarray and $y_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

The n-dimensional array $y_ndarray must be defined. Otherwise, an exception is thrown.

The dimensions of $x_ndarray must be equal to the dimensions of $y_ndarray. Otherwise, an exception is thrown.

=head2 ne

C<static method ne : L<R::NDArray::Int|SPVM::R::NDArray::Int> ($x_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>, $y_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>);>

Creates a new L<R::NDArray::Int|SPVM::R::NDArray::Int> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, performs numeric comparison C<!=> operation on each element of the n-dimensional array $x_ndarray and $y_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

The n-dimensional array $y_ndarray must be defined. Otherwise, an exception is thrown.

The dimensions of $x_ndarray must be equal to the dimensions of $y_ndarray. Otherwise, an exception is thrown.

=head2 gt

C<static method gt : L<R::NDArray::Int|SPVM::R::NDArray::Int> ($x_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>, $y_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>);>

Creates a new L<R::NDArray::Int|SPVM::R::NDArray::Int> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, performs numeric comparison C<E<gt>> operation on each element of the n-dimensional array $x_ndarray and $y_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

The n-dimensional array $y_ndarray must be defined. Otherwise, an exception is thrown.

The dimensions of $x_ndarray must be equal to the dimensions of $y_ndarray. Otherwise, an exception is thrown.

=head2 ge

C<static method ge : L<R::NDArray::Int|SPVM::R::NDArray::Int> ($x_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>, $y_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>);>

Creates a new L<R::NDArray::Int|SPVM::R::NDArray::Int> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, performs numeric comparison C<E<gt>=> operation on each element of the n-dimensional array $x_ndarray and $y_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

The n-dimensional array $y_ndarray must be defined. Otherwise, an exception is thrown.

The dimensions of $x_ndarray must be equal to the dimensions of $y_ndarray. Otherwise, an exception is thrown.

=head2 lt

C<static method lt : R::NDArray::Int ($x_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>, $y_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>);>

Creates a new L<R::NDArray::Int|SPVM::R::NDArray::Int> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, performs numeric comparison C<E<lt>> operation on each element of the n-dimensional array $x_ndarray and $y_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

The n-dimensional array $y_ndarray must be defined. Otherwise, an exception is thrown.

The dimensions of $x_ndarray must be equal to the dimensions of $y_ndarray. Otherwise, an exception is thrown.

=head2 le

C<static method le : R::NDArray::Int ($x_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>, $y_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>);>

Creates a new L<R::NDArray::Int|SPVM::R::NDArray::Int> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, performs numeric comparison C<E<lt>=> operation on each element of the n-dimensional array $x_ndarray and $y_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

The n-dimensional array $y_ndarray must be defined. Otherwise, an exception is thrown.

The dimensions of $x_ndarray must be equal to the dimensions of $y_ndarray. Otherwise, an exception is thrown.

=head2 rep

C<static method rep : L<R::NDArray::Double|SPVM::R::NDArray::Double> ($x_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>, $times : int);>

Same as L<R::OP#rep|SPVM::R::OP/"rep"> method, but the return type is different.

=head2 rep_length

C<static method rep_length : L<R::NDArray::Double|SPVM::R::NDArray::Double> ($x_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>, $length : int);>

Same as L<R::OP#rep_length|SPVM::R::OP/"rep_length"> method, but the return type is different.

=head2 seq

C<static method seq : L<R::NDArray::Double|SPVM::R::NDArray::Double> ($begin : double, $end : double, $by : double = 1);>

Creates a L<R::NDArray::Double|SPVM::R::NDArray::Double> object from $bigin to $end at intervals of $by.

Exceptions:

$by must not be 0. Otherwise, an exception is thrown.

If $by is greater than 0 and $end is not greater than or equal to $begin, an exception is thrown.

If $by is less than 0 and $end Is not greater than or equal to $begin, an exception is thrown.

=head2 seq_length

C<static method seq_length : L<R::NDArray::Double|SPVM::R::NDArray::Double> ($begin : double, $end : double, $length : int);>

Creates a L<R::NDArray::Double|SPVM::R::NDArray::Double> object from $bigin to $end up to length $length.

An interval $by is calcurated by C<(($end - $begin + 1) / $length)>.

This method calls L</"seq"> method given $by.

Exceptions:

Exceptions thrown by L</"seq"> method could be thronw.

=head2 sin

C<static method sin : L<R::NDArray::Double|SPVM::R::NDArray::Double> ($x_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>);>

Creates a new L<R::NDArray::Double|SPVM::R::NDArray::Double> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, performs L<Math#sin|SPVM::Math/"sin"> method on each element of the n-dimensional array $x_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

=head2 cos

C<static method cos : L<R::NDArray::Double|SPVM::R::NDArray::Double> ($x_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>);>

Creates a new L<R::NDArray::Double|SPVM::R::NDArray::Double> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, performs L<Math#cos|SPVM::Math/"cos"> method on each element of the n-dimensional array $x_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.
Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

=head2 tan

C<static method tan : L<R::NDArray::Double|SPVM::R::NDArray::Double> ($x_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>);>

Creates a new L<R::NDArray::Double|SPVM::R::NDArray::Double> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, performs L<Math#tan|SPVM::Math/"tan"> method on each element of the n-dimensional array $x_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.
Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

=head2 sinh

C<static method sinh : L<R::NDArray::Double|SPVM::R::NDArray::Double> ($x_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>);>

Creates a new L<R::NDArray::Double|SPVM::R::NDArray::Double> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, performs L<Math#sinh|SPVM::Math/"sinh"> method on each element of the n-dimensional array $x_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

=head2 cosh

C<static method cosh : L<R::NDArray::Double|SPVM::R::NDArray::Double> ($x_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>);>

Creates a new L<R::NDArray::Double|SPVM::R::NDArray::Double> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, performs L<Math#cosh|SPVM::Math/"cosh"> method on each element of the n-dimensional array $x_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

=head2 tanh

C<static method tanh : L<R::NDArray::Double|SPVM::R::NDArray::Double> ($x_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>);>

Creates a new L<R::NDArray::Double|SPVM::R::NDArray::Double> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, performs L<Math#tanh|SPVM::Math/"tanh"> method on each element of the n-dimensional array $x_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

=head2 acos

C<static method acos : L<R::NDArray::Double|SPVM::R::NDArray::Double> ($x_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>);>

Creates a new L<R::NDArray::Double|SPVM::R::NDArray::Double> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, performs L<Math#acos|SPVM::Math/"acos"> method on each element of the n-dimensional array $x_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

=head2 asin

C<static method asin : L<R::NDArray::Double|SPVM::R::NDArray::Double> ($x_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>);>

Creates a new L<R::NDArray::Double|SPVM::R::NDArray::Double> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, performs L<Math#asin|SPVM::Math/"asin"> method on each element of the n-dimensional array $x_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

=head2 atan

C<static method atan : L<R::NDArray::Double|SPVM::R::NDArray::Double> ($x_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>);>

Creates a new L<R::NDArray::Double|SPVM::R::NDArray::Double> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, performs L<Math#atan|SPVM::Math/"atan"> method on each element of the n-dimensional array $x_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

=head2 asinh

C<static method asinh : L<R::NDArray::Double|SPVM::R::NDArray::Double> ($x_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>);>

Creates a new L<R::NDArray::Double|SPVM::R::NDArray::Double> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, performs L<Math#asinh|SPVM::Math/"asinh"> method on each element of the n-dimensional array $x_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

=head2 acosh

C<static method acosh : L<R::NDArray::Double|SPVM::R::NDArray::Double> ($x_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>);>

Creates a new L<R::NDArray::Double|SPVM::R::NDArray::Double> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, performs L<Math#acosh|SPVM::Math/"acosh"> method on each element of the n-dimensional array $x_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

=head2 atanh

C<static method atanh : L<R::NDArray::Double|SPVM::R::NDArray::Double> ($x_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>);>

Creates a new L<R::NDArray::Double|SPVM::R::NDArray::Double> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, performs L<Math#atanh|SPVM::Math/"atanh"> method on each element of the n-dimensional array $x_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

=head2 exp

C<static method exp : L<R::NDArray::Double|SPVM::R::NDArray::Double> ($x_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>);>

Creates a new L<R::NDArray::Double|SPVM::R::NDArray::Double> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, performs L<Math#exp|SPVM::Math/"exp"> method on each element of the n-dimensional array $x_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

=head2 expm1

C<static method expm1 : L<R::NDArray::Double|SPVM::R::NDArray::Double> ($x_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>);>

Creates a new L<R::NDArray::Double|SPVM::R::NDArray::Double> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, performs L<Math#expm1|SPVM::Math/"expm1"> method on each element of the n-dimensional array $x_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

=head2 log

C<static method log : L<R::NDArray::Double|SPVM::R::NDArray::Double> ($x_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>);>

Creates a new L<R::NDArray::Double|SPVM::R::NDArray::Double> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, performs L<Math#log|SPVM::Math/"log"> method on each element of the n-dimensional array $x_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

=head2 logb

C<static method logb : L<R::NDArray::Double|SPVM::R::NDArray::Double> ($x_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>);>

Creates a new L<R::NDArray::Double|SPVM::R::NDArray::Double> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, performs L<Math#logb|SPVM::Math/"logb"> method on each element of the n-dimensional array $x_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

=head2 log2

C<static method log2 : L<R::NDArray::Double|SPVM::R::NDArray::Double> ($x_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>);>

Creates a new L<R::NDArray::Double|SPVM::R::NDArray::Double> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, performs L<Math#log2|SPVM::Math/"log2"> method on each element of the n-dimensional array $x_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

=head2 log10

C<static method log10 : L<R::NDArray::Double|SPVM::R::NDArray::Double> ($x_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>);>

Creates a new L<R::NDArray::Double|SPVM::R::NDArray::Double> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, performs L<Math#log10|SPVM::Math/"log10"> method on each element of the n-dimensional array $x_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

=head2 sqrt

C<static method sqrt : L<R::NDArray::Double|SPVM::R::NDArray::Double> ($x_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>);>

Creates a new L<R::NDArray::Double|SPVM::R::NDArray::Double> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, performs L<Math#sqrt|SPVM::Math/"sqrt"> method on each element of the n-dimensional array $x_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

=head2 isinf

C<static method isinf : L<R::NDArray::Int|SPVM::R::NDArray::Int> ($x_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>);>

Creates a new L<R::NDArray::Double|SPVM::R::NDArray::Double> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, performs L<Math#isinf|SPVM::Math/"isinf"> method on each element of the n-dimensional array $x_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

=head2 is_infinite

C<static method is_infinite : L<R::NDArray::Int|SPVM::R::NDArray::Int> ($x_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>);>

Same as L</"isinf"> method.

=head2 is_finite

C<static method is_finite : L<R::NDArray::Int|SPVM::R::NDArray::Int> ($x_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>);>

Creates a new L<R::NDArray::Double|SPVM::R::NDArray::Double> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, checks if the value is finite on each element of the n-dimensional array $x_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.

Implementation:

Returns C<R::OP::Int-E<gt>and(R::OP::Int-E<gt>not(&isnan($x_ndarray)), R::OP::Int-E<gt>not(&is_infinite($x_ndarray)))>.

=head2 isnan

C<static method isnan : L<R::NDArray::Int|SPVM::R::NDArray::Int> ($x_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>);>

Creates a new L<R::NDArray::Double|SPVM::R::NDArray::Double> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, performs L<Math#isnan|SPVM::Math/"isnan"> method on each element of the n-dimensional array $x_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

=head2 is_nan

C<static method is_nan : L<R::NDArray::Int|SPVM::R::NDArray::Int> ($x_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>);>

Same as L</"isnan"> method.

=head2 pow

C<static method pow : L<R::NDArray::Double|SPVM::R::NDArray::Double> ($x_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>, $y_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>);>

Creates a new L<R::NDArray::Double|SPVM::R::NDArray::Double> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, performs L<Math#pow|SPVM::Math/"pow"> method given each element of the n-dimensional array $x_ndarray and $y_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

The n-dimensional array $y_ndarray must be defined. Otherwise, an exception is thrown.

The dimensions of $x_ndarray must be equal to the dimensions of $y_ndarray. Otherwise, an exception is thrown.

=head2 atan2

C<static method atan2 : L<R::NDArray::Double|SPVM::R::NDArray::Double> ($y_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>, $x_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>);>

Creates a new L<R::NDArray::Double|SPVM::R::NDArray::Double> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, performs L<Math#atan2|SPVM::Math/"atan2"> method given each element of the n-dimensional array $y_ndarray and $x_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

The n-dimensional array $y_ndarray must be defined. Otherwise, an exception is thrown.

The dimensions of $x_ndarray must be equal to the dimensions of $y_ndarray. Otherwise, an exception is thrown.

=head2 modf

C<static method modf : L<R::NDArray::Double|SPVM::R::NDArray::Double> ($x_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>, $intpart_ndarray_ref : L<R::NDArray::Double|SPVM::R::NDArray::Double>[]);>

Creates a new L<R::NDArray::Double|SPVM::R::NDArray::Double> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, performs L<Math#modf|SPVM::Math/"modf"> method given each element of the n-dimensional array $x_ndarray and $intpart_ndarray_ref, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

The array of the n-dimensional array $intpart_ndarray_ref must be defined. Otherwise, an exception is thrown.

The integer part n-dimensional array $intpart_ndarray_ref must be defined. Otherwise, an exception is thrown.

The length of integer part n-dimensional array $intpart_ndarray_ref must be 1. Otherwise, an exception is thrown.

=head2 ceil

C<static method ceil : L<R::NDArray::Double|SPVM::R::NDArray::Double> ($x_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>);>

Creates a new L<R::NDArray::Double|SPVM::R::NDArray::Double> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, performs L<Math#ceil|SPVM::Math/"ceil"> method on each element of the n-dimensional array $x_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

=head2 ceiling

C<static method ceiling : L<R::NDArray::Double|SPVM::R::NDArray::Double> ($x_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>);>

Same as L</"ceil"> method.

=head2 floor

C<static method floor : L<R::NDArray::Double|SPVM::R::NDArray::Double> ($x_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>);>

Creates a new L<R::NDArray::Double|SPVM::R::NDArray::Double> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, performs L<Math#floor|SPVM::Math/"floor"> method on each element of the n-dimensional array $x_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

=head2 round

C<static method round : L<R::NDArray::Double|SPVM::R::NDArray::Double> ($x_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>);>

Creates a new L<R::NDArray::Double|SPVM::R::NDArray::Double> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, performs L<Math#round|SPVM::Math/"round"> method on each element of the n-dimensional array $x_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

=head2 lround

C<static method lround : L<R::NDArray::Long|SPVM::R::NDArray::Long> ($x_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>);>

Creates a new L<R::NDArray::Long|SPVM::R::NDArray::Long> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, performs L<Math#lround|SPVM::Math/"lround"> method on each element of the n-dimensional array $x_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

=head2 remainder

C<static method remainder : L<R::NDArray::Double|SPVM::R::NDArray::Double> ($x_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>, $y_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>);>

Creates a new L<R::NDArray::Double|SPVM::R::NDArray::Double> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, performs L<Math#remainder|SPVM::Math/"remainder"> method on on each element of the n-dimensional array $x_ndarray and $y_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

The n-dimensional array $y_ndarray must be defined. Otherwise, an exception is thrown.

The dimensions of $x_ndarray must be equal to the dimensions of $y_ndarray. Otherwise, an exception is thrown.

=head2 fmod

C<static method fmod : L<R::NDArray::Double|SPVM::R::NDArray::Double> ($x_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>, $y_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>);>

Creates a new L<R::NDArray::Double|SPVM::R::NDArray::Double> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, performs L<Math#fmod|SPVM::Math/"fmod"> method on on each element of the n-dimensional array $x_ndarray and $y_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

The n-dimensional array $y_ndarray must be defined. Otherwise, an exception is thrown.

The dimensions of $x_ndarray must be equal to the dimensions of $y_ndarray. Otherwise, an exception is thrown.

=head2 sum

C<static method sum : L<R::NDArray::Double|SPVM::R::NDArray::Double> ($x_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>);>

Creates a new L<R::NDArray::Double|SPVM::R::NDArray::Double> object with the dimenstion C<[1]> for a return value, calculates the sum of all elements of the n-dimensional array $x_ndarray, and sets the element of the new n-dimensional array to the result, and returns the new n-dimensional array.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

=head2 cumsum

C<static method cumsum : L<R::NDArray::Double|SPVM::R::NDArray::Double> ($x_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>);>

Creates a new L<R::NDArray::Double|SPVM::R::NDArray::Double> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, calculates the cumulative sum on each element of the n-dimensional array $x_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.

Examples are
  
  # data
  [(double)3, 1, 4, 1, 5, 9, 2, 6, 5]
  
  # result
  [(double)0, 3, 4, 8, 9, 14, 23, 25, 31, 36]

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

=head2 prod

C<static method prod : L<R::NDArray::Double|SPVM::R::NDArray::Double> ($x_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>);>

Creates a new L<R::NDArray::Double|SPVM::R::NDArray::Double> object with the dimenstion C<[1]> for a return value, calculates the production of all elements of the n-dimensional array $x_ndarray, and sets the element of the new n-dimensional array to the result, and returns the new n-dimensional array.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

=head2 cumprod

C<static method cumprod : L<R::NDArray::Double|SPVM::R::NDArray::Double> ($x_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>);>

Creates a new L<R::NDArray::Double|SPVM::R::NDArray::Double> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, calculates the cumulative product on each element of the n-dimensional array $x_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.

Examples are
  
  # data
  [(double)2, 3, 4, 5]
  
  # result
  [(double)2, 6, 24, 120]

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

=head2 diff

C<static method diff : L<R::NDArray::Double|SPVM::R::NDArray::Double> ($x_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>);>

Creates a new L<R::NDArray::Double|SPVM::R::NDArray::Double> object of the dimensions as the n-dimensional array $x_ndarray minus 1 for a return value, calculats the difference of adjacent elements of the n-dimensional array $x_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.

Examples are
  
  # data
  [(double)2, 4, 7]
  
  # result
  [(double)2, 3]

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

=head2 max

C<static method max : L<R::NDArray::Double|SPVM::R::NDArray::Double> ($x_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>);>

Creates a new L<R::NDArray::Double|SPVM::R::NDArray::Double> object with the dimenstion C<[1]> for a return value, calculates the maximum value of all elements of the n-dimensional array $x_ndarray, and sets the element of the new n-dimensional array to the result, and returns the new n-dimensional array.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

=head2 min

C<static method min : L<R::NDArray::Double|SPVM::R::NDArray::Double> ($x_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>);>

Creates a new L<R::NDArray::Double|SPVM::R::NDArray::Double> object with the dimenstion C<[1]> for a return value, calculates the minimum value of all elements of the n-dimensional array $x_ndarray, and sets the element of the new n-dimensional array to the result, and returns the new n-dimensional array.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

=head2 mean

C<static method mean : L<R::NDArray::Double|SPVM::R::NDArray::Double> ($x_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>);>

Creates a new L<R::NDArray::Double|SPVM::R::NDArray::Double> object with the dimenstion C<[1]> for a return value, calculates the mean of all elements of the n-dimensional array $x_ndarray, and sets the element of the new n-dimensional array to the result, and returns the new n-dimensional array.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

=head2 dot

C<static method dot : L<R::NDArray::Double|SPVM::R::NDArray::Double> ($x_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>, $y_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>);>

Creates a new L<R::NDArray::Double|SPVM::R::NDArray::Double> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, performs L<dot product|https://en.wikipedia.org/wiki/Dot_product> of elements of the n-dimensional array $x_ndarray and $y_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

The n-dimensional array $x_ndarray must be a vector. Otherwise, an exception is thrown.

The n-dimensional array $y_ndarray must be defined. Otherwise, an exception is thrown.

The n-dimensional array $y_ndarray must be a vector. Otherwise, an exception is thrown.

The length of the n-dimensional array $x_ndarray must be equal to the length of the n-dimensional array $y_ndarray. Otherwise, an exception is thrown.

=head2 cross

C<static method cross : L<R::NDArray::Double|SPVM::R::NDArray::Double> ($x_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>, $y_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>);>

Creates a new L<R::NDArray::Double|SPVM::R::NDArray::Double> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, performs L<cross product|https://en.wikipedia.org/wiki/Cross_product> of elements of the n-dimensional array $x_ndarray and $y_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.
Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

The n-dimensional array $x_ndarray must be a vector. Otherwise, an exception is thrown.

The n-dimensional array $y_ndarray must be defined. Otherwise, an exception is thrown.

The n-dimensional array $y_ndarray must be a vector. Otherwise, an exception is thrown.

The length of the n-dimensional array $x_ndarray must be equal to the length of the n-dimensional array $y_ndarray. Otherwise, an exception is thrown.

The length of n-dimensional array $x_ndarray must be 3.

The length of n-dimensional array $y_ndarray must be 3.

=head2 outer

C<static method outer : L<R::NDArray::Double|SPVM::R::NDArray::Double> ($x_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>, $y_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>);>

Creates a new L<R::NDArray::Double|SPVM::R::NDArray::Double> object of the dimensions C<[$x_dim, $y_dim]> ($x_dim is the dimensions of $x_ndarray and $y_dim is the dimensions of $y_ndarray) for a return value, performs L<outer product|https://en.wikipedia.org/wiki/Outer_product> of elements of the n-dimensional array $x_ndarray and $y_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

The n-dimensional array $x_ndarray must be a vector. Otherwise, an exception is thrown.

The n-dimensional array $y_ndarray must be defined. Otherwise, an exception is thrown.

The n-dimensional array $y_ndarray must be a vector. Otherwise, an exception is thrown.

=head2 runif

C<static method runif : L<R::NDArray::Double|SPVM::R::NDArray::Double> ($length : int, $options : object[]);>

Creates a new L<R::NDArray::Double|SPVM::R::NDArray::Double> object of the dimensions C<[$length]> for a return value, generates random numbers from a uniform distribution between a specified minimum value C<min> option and maximum value C<max> option.

C<seed_ref> option for a seed can be available.

Examples:
  
  my $length = 10;
  my $ret_ndarray = R::OP::Double->runif($length, {min => 0, max => 100});
  
  my $seed_ref = [(int)(Sys->time * Sys->process_id)];
  my $length = 10;
  my $ret_ndarray = R::OP::Double->runif($length, {min => 0, max => 100, seed_ref => $seed_ref});

Exceptions:

If non-available options are specified, an exception is thrown.

=head2 pi

C<static method pi : L<R::NDArray::Double|SPVM::R::NDArray::Double> ();>

Creates a new L<R::NDArray::Double|SPVM::R::NDArray::Double> object of the dimensions C<[1]> for a return value, sets the element of the new n-dimensional array to the return value os L<Math#PI|SPVM::Math/"PI"> method, and returns the new n-dimensional array.

=head1 See Also

=over 2

=item * L<R::OP|SPVM::R::OP>

=item * L<R::NDArray::Double|SPVM::R::NDArray::Double>

=item * L<R::NDArray|SPVM::R::NDArray>

=item * L<R|SPVM::R>

=back

=head1 Copyright & License

Copyright (c) 2024 Yuki Kimoto

MIT License

