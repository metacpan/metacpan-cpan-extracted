package SPVM::R::OP::DoubleComplex;



1;

=head1 Name

SPVM::R::OP::DoubleComplex - N-Dimensional Array Operations for R::NDArray::DoubleComplex

=head1 Description

R::OP::DoubleComplex class in L<SPVM> has methods for n-dimensional array operations for L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex>.

=head1 Usage

  use R::OP::DoubleComplex as DCOP;
  
  # 1+10i
  my $ndarray_scalar = DCOP->c([(double)1,10]);
  
  # 1+10i, 2+20i, 3+30i
  my $ndarray_vector = DCOP->c([(double)1,10,  2,20,  3,30]);
  
  my $ndarray = DCOP->c([(double)1,10,  2,20,  3,30,  4,40,  5,50,  6,60], [3, 2]);
  
  my $ndarray2 = DCOP->c($ndarray);

=head1 Class Methods

=head2 c

C<static method c : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex> ($data : object of double[]|L<Complex_2d|SPVM::Complex_2d>[]|L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex>, $dim : int[] = undef);>

Creates a new L<R::NDArray::Double|SPVM::R::NDArray::Double> object given the data $data and the dimensions $dim.

Implemetation:

If $data is defined and the type of $data is double[], it is interpreted as pairs of a real number and a complex number and is converted to an array of L<Complex_2d|SPVM::Complex_2d>, $data is set to the array.

If $data is defined and the type of $data is L<R::NDArray::Double|SPVM::R::NDArray::Double>, $dim is set to C<$data-E<gt>(R::NDArray::Double)-E<gt>dim> unless $dim is defined and $data is set to C<$data-E<gt>(R::NDArray::Double)-E<gt>data>.

And this method calls L<R::NDArray::Double#new|SPVM::R::NDArray::Double/"new"> method given $dim and $data.

Exceptions:

The length of pairs \$data must be an even number if the type of \$data is double[]. Othrewise, an exception is thrown.

The type of the data $data must be double[], Complex_2d[] or R::NDArray::DoubleComplex.

=head2 add

C<static method add : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex> ($x_ndarray : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex>, $y_ndarray : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex>);>

Creates a new L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, performs L<Math#cadd|SPVM::Math/"cadd"> method on each element of the n-dimensional array $x_ndarray and $y_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

The n-dimensional array $y_ndarray must be defined. Otherwise, an exception is thrown.

The dimensions of $x_ndarray must be equal to the dimensions of $y_ndarray. Otherwise, an exception is thrown.

=head2 sub

C<static method sub : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex> ($x_ndarray : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex>, $y_ndarray : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex>);>

Creates a new L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, performs L<Math#csub|SPVM::Math/"csub"> method on each element of the n-dimensional array $x_ndarray and $y_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

The n-dimensional array $y_ndarray must be defined. Otherwise, an exception is thrown.

The dimensions of $x_ndarray must be equal to the dimensions of $y_ndarray. Otherwise, an exception is thrown.

=head2 mul

C<static method mul : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex> ($x_ndarray : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex>, $y_ndarray : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex>);>

Creates a new L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, performs L<Math#cmul|SPVM::Math/"cmul"> method on each element of the n-dimensional array $x_ndarray and $y_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

The n-dimensional array $y_ndarray must be defined. Otherwise, an exception is thrown.

The dimensions of $x_ndarray must be equal to the dimensions of $y_ndarray. Otherwise, an exception is thrown.

=head2 scamul

C<static method scamul : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex> ($x_ndarray : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex>, $scalar_ndarray : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex>);>

Creates a new L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, performs L<Math#cmul|SPVM::Math/"cmul"> method on each element of the n-dimensional array $x_ndarray, and sets each element of the new n-dimensional array and the n-dimensional array $scalar_ndarray at data index 0 to the each operation result, and returns the new n-dimensional array.

Exceptions:

The n-dimensional array $scalar_ndarray must be defined. Otherwise, an exception is thrown.

The n-dmension array $scalar_ndarray must be a L<scalar|SPVM::R::NDArray/"Scalar">.

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

=head2 div

C<static method div : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex> ($x_ndarray : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex>, $y_ndarray : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex>);>

Creates a new L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, performs L<Math#cdiv|SPVM::Math/"cdiv"> method on each element of the n-dimensional array $x_ndarray and $y_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

The n-dimensional array $y_ndarray must be defined. Otherwise, an exception is thrown.

The dimensions of $x_ndarray must be equal to the dimensions of $y_ndarray. Otherwise, an exception is thrown.

=head2 scadiv

C<static method scadiv : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex> ($x_ndarray : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex>, $scalar_ndarray : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex>);>

Creates a new L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, performs L<Math#cdiv|SPVM::Math/"cdiv"> method on the n-dimensional array $scalar_ndarray at data index 0 and each element of the n-dimensional array $x_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.

Exceptions:

The n-dimensional array $scalar_ndarray must be defined. Otherwise, an exception is thrown.

The n-dmension array $scalar_ndarray must be a L<scalar|SPVM::R::NDArray/"Scalar">.

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

=head2 neg

C<static method neg : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex> ($x_ndarray : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex>);>

Creates a new L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, performs L<Math#cneg|SPVM::Math/"cneg"> method on each element of the n-dimensional array $x_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.
Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

=head2 abs

C<static method abs : L<R::NDArray::Double|SPVM::R::NDArray::Double> ($x_ndarray : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex>);>

Creates a new L<R::NDArray::Double|SPVM::R::NDArray::Double> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, performs L<Math#cabs|SPVM::Math/"cabs"> method on each element of the n-dimensional array $x_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.
Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

=head2 re

C<static method re : L<R::NDArray::Double|SPVM::R::NDArray::Double> ($x_ndarray : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex>);>

Creates a new L<R::NDArray::Double|SPVM::R::NDArray::Double> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, gets the real number on each element of the n-dimensional array $x_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

=head2 im

C<static method im : L<R::NDArray::Double|SPVM::R::NDArray::Double> ($x_ndarray : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex>);>

Creates a new L<R::NDArray::Double|SPVM::R::NDArray::Double> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, gets the image number on each element of the n-dimensional array $x_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

=head2 i

C<static method i : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex> ();>

Creates a new L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex> object of the dimensions C<[1]> for a return value, sets the element of the new n-dimensional array to the return value of C<Math-E<gt>complex(0, 1)>, and returns the new n-dimensional array.

=head2 conj

C<static method conj : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex> ($x_ndarray : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex>);>

Creates a new L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, performs L<Math#conj|SPVM::Math/"conj"> method on each element of the n-dimensional array $x_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.
Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

=head2 arg

C<static method arg : L<R::NDArray::Double|SPVM::R::NDArray::Double> ($x_ndarray : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex>);>

Creates a new L<R::NDArray::Double|SPVM::R::NDArray::Double> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, performs L<Math#carg|SPVM::Math/"carg"> method on each element of the n-dimensional array $x_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.
Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

=head2 eq

C<static method eq : L<R::NDArray::Int|SPVM::R::NDArray::Int> ($x_ndarray : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex>, $y_ndarray : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex>);>

Creates a new L<R::NDArray::Int|SPVM::R::NDArray::Int> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, performs AND operation C<&&> on the results of numeric comparison C<==> operation on the real number and image number of each element of the n-dimensional array $x_ndarray and $y_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

The n-dimensional array $y_ndarray must be defined. Otherwise, an exception is thrown.

The dimensions of $x_ndarray must be equal to the dimensions of $y_ndarray. Otherwise, an exception is thrown.

=head2 ne

C<static method ne : L<R::NDArray::Int|SPVM::R::NDArray::Int> ($x_ndarray : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex>, $y_ndarray : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex>);>

Creates a new L<R::NDArray::Int|SPVM::R::NDArray::Int> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, performs NOT operation C<!> on the reust of AND operation C<&&> on the results of numeric comparison C<==> operation on the real number and image number of each element of the n-dimensional array $x_ndarray and $y_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

The n-dimensional array $y_ndarray must be defined. Otherwise, an exception is thrown.

The dimensions of $x_ndarray must be equal to the dimensions of $y_ndarray. Otherwise, an exception is thrown.

=head2 rep

C<static method rep : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex> ($x_ndarray : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex>, $times : int);>

Same as L<R::OP#rep|SPVM::R::OP/"rep"> method, but the return type is different.

=head2 rep_length

C<static method rep_length : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex> ($x_ndarray : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex>, $length : int);>

Same as L<R::OP#rep_length|SPVM::R::OP/"rep_length"> method, but the return type is different.

=head2 sin

C<static method sin : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex> ($x_ndarray : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex>);>

Creates a new L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, performs L<Math#csin|SPVM::Math/"csin"> method on each element of the n-dimensional array $x_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.
Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

=head2 cos

C<static method cos : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex> ($x_ndarray : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex>);>

Creates a new L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, performs L<Math#ccos|SPVM::Math/"ccos"> method on each element of the n-dimensional array $x_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.
Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

=head2 tan

C<static method tan : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex> ($x_ndarray : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex>);>

Creates a new L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, performs L<Math#ctan|SPVM::Math/"ctan"> method on each element of the n-dimensional array $x_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.
Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

=head2 sinh

C<static method sinh : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex> ($x_ndarray : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex>);>

Creates a new L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, performs L<Math#csinh|SPVM::Math/"csinh"> method on each element of the n-dimensional array $x_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

=head2 cosh

C<static method cosh : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex> ($x_ndarray : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex>);>

Creates a new L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, performs L<Math#ccosh|SPVM::Math/"ccosh"> method on each element of the n-dimensional array $x_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

=head2 tanh

C<static method tanh : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex> ($x_ndarray : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex>);>

Creates a new L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, performs L<Math#ctanh|SPVM::Math/"ctanh"> method on each element of the n-dimensional array $x_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

=head2 acos

C<static method acos : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex> ($x_ndarray : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex>);>

Creates a new L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, performs L<Math#cacos|SPVM::Math/"cacos"> method on each element of the n-dimensional array $x_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

=head2 asin

C<static method asin : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex> ($x_ndarray : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex>);>

Creates a new L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, performs L<Math#casin|SPVM::Math/"casin"> method on each element of the n-dimensional array $x_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

=head2 atan

C<static method atan : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex> ($x_ndarray : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex>);>

Creates a new L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, performs L<Math#catan|SPVM::Math/"catan"> method on each element of the n-dimensional array $x_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

=head2 asinh

C<static method asinh : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex> ($x_ndarray : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex>);>

Creates a new L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, performs L<Math#casinh|SPVM::Math/"casinh"> method on each element of the n-dimensional array $x_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

=head2 acosh

C<static method acosh : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex> ($x_ndarray : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex>);>

Creates a new L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, performs L<Math#cacosh|SPVM::Math/"cacosh"> method on each element of the n-dimensional array $x_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

=head2 atanh

C<static method atanh : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex> ($x_ndarray : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex>);>

Creates a new L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, performs L<Math#catanh|SPVM::Math/"catanh"> method on each element of the n-dimensional array $x_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

=head2 exp

C<static method exp : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex> ($x_ndarray : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex>);>

Creates a new L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, performs L<Math#cexp|SPVM::Math/"cexp"> method on each element of the n-dimensional array $x_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

=head2 log

C<static method log : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex> ($x_ndarray : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex>);>

Creates a new L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, performs L<Math#clog|SPVM::Math/"clog"> method on each element of the n-dimensional array $x_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

=head2 sqrt

C<static method sqrt : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex> ($x_ndarray : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex>);>

Creates a new L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, performs L<Math#csqrt|SPVM::Math/"csqrt"> method on each element of the n-dimensional array $x_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

=head2 pow

C<static method pow : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex> ($x_ndarray : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex>, $y_ndarray : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex>);>

Creates a new L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, performs L<Math#cpow|SPVM::Math/"cpow"> method given each element of the n-dimensional array $x_ndarray and $y_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

The n-dimensional array $y_ndarray must be defined. Otherwise, an exception is thrown.

The dimensions of $x_ndarray must be equal to the dimensions of $y_ndarray. Otherwise, an exception is thrown.

=head2 sum

C<static method sum : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex> ($x_ndarray : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex>);>

Creates a new L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex> object with the dimenstion C<[1]> for a return value, calculates the sum of all elements of the n-dimensional array $x_ndarray, and sets the element of the new n-dimensional array to the result, and returns the new n-dimensional array.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

=head2 cumsum

C<static method cumsum : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex> ($x_ndarray : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex>);>

Creates a new L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, calculates the cumulative sum on each element of the n-dimensional array $x_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

=head2 prod

C<static method prod : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex> ($x_ndarray : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex>);>

Creates a new L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex> object with the dimenstion C<[1]> for a return value, calculates the production of all elements of the n-dimensional array $x_ndarray, and sets the element of the new n-dimensional array to the result, and returns the new n-dimensional array.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

=head2 cumprod

C<static method cumprod : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex> ($x_ndarray : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex>);>

Creates a new L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, calculates the cumulative product on each element of the n-dimensional array $x_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

=head2 diff

C<static method diff : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex> ($x_ndarray : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex>);>

Creates a new L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex> object of the dimensions as the n-dimensional array $x_ndarray minus 1 for a return value, calculats the difference of adjacent elements of the n-dimensional array $x_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

=head2 mean

C<static method mean : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex> ($x_ndarray : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex>);>

Creates a new L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex> object with the dimenstion C<[1]> for a return value, calculates the mean of all elements of the n-dimensional array $x_ndarray, and sets the element of the new n-dimensional array to the result, and returns the new n-dimensional array.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

=head2 dot

C<static method dot : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex> ($x_ndarray : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex>, $y_ndarray : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex>);>

Creates a new L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, performs L<dot product|https://en.wikipedia.org/wiki/Dot_product> of elements of the n-dimensional array $x_ndarray and $y_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.

The dot product in this implementation is conjugate-linear in the first variable and linear in the second variable.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

The n-dimensional array $x_ndarray must be a vector. Otherwise, an exception is thrown.

The n-dimensional array $y_ndarray must be defined. Otherwise, an exception is thrown.

The n-dimensional array $y_ndarray must be a vector. Otherwise, an exception is thrown.

The length of the n-dimensional array $x_ndarray must be equal to the length of the n-dimensional array $y_ndarray. Otherwise, an exception is thrown.

=head2 outer

C<static method outer : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex> ($x_ndarray : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex>, $y_ndarray : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex>);>

Creates a new L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex> object of the dimensions C<[$x_dim, $y_dim]> ($x_dim is the dimensions of $x_ndarray and $y_dim is the dimensions of $y_ndarray) for a return value, performs L<outer product|https://en.wikipedia.org/wiki/Outer_product> of elements of the n-dimensional array $x_ndarray and $y_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

The n-dimensional array $x_ndarray must be a vector. Otherwise, an exception is thrown.

The n-dimensional array $y_ndarray must be defined. Otherwise, an exception is thrown.

The n-dimensional array $y_ndarray must be a vector. Otherwise, an exception is thrown.

=head2 pi

C<static method pi : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex> ();>

Creates a new L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex> object of the dimensions C<[1]> for a return value, sets the real number of the element of the new n-dimensional array to the return value os L<Math#PI|SPVM::Math/"PI"> method, and returns the new n-dimensional array.

=head1 See Also

=over 2

=item * L<R::OP|SPVM::R::OP>

=item * L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex>

=item * L<R::NDArray|SPVM::R::NDArray>

=item * L<R|SPVM::R>

=back

=head1 Copyright & License

Copyright (c) 2024 Yuki Kimoto

MIT License

