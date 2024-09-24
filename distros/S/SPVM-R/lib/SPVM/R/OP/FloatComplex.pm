package SPVM::R::OP::FloatComplex;



1;

=head1 Name

SPVM::R::OP::FloatComplex - N-Dimensional Array Operations for R::NDArray::FloatComplex

=head1 Description

R::OP::FloatComplex class in L<SPVM> has methods for n-dimensional array operations for L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex>.

=head1 Usage

  use R::OP::FloatComplex as FCOP;
  
  # 1+10i
  my $ndarray_scalar = FCOP->c([(float)1,10]);
  
  # 1+10i, 2+20i, 3+30i
  my $ndarray_vector = FCOP->c([(float)1,10,  2,20,  3,30]);
  
  my $ndarray = FCOP->c([(float)1,10,  2,20,  3,30,  4,40,  5,50,  6,60], [3, 2]);
  
  my $ndarray2 = FCOP->c($ndarray);

=head1 Class Methods

=head2 c

C<static method c : L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex> ($data : object of float[]|L<Complex_2f|SPVMComplex_2f>[]|L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex>, $dim : int[] = undef);>

Creates a new L<R::NDArray::Float|SPVM::R::NDArray::Float> object given the data $data and the dimensions $dim.

Implemetation:

If $data is defined and the type of $data is float[], it is interpreted as pairs of a real number and a complex number and is converted to an array of L<Complex_2f|SPVM::Complex_2f>, $data is set to the array.

If $data is defined and the type of $data is L<R::NDArray::Float|SPVM::R::NDArray::Float>, $dim is set to C<$data-E<gt>(R::NDArray::Float)-E<gt>dim> unless $dim is defined and $data is set to C<$data-E<gt>(R::NDArray::Float)-E<gt>data>.

And this method calls L<R::NDArray::Float#new|SPVM::R::NDArray::Float/"new"> method given $dim and $data.

Exceptions:

The length of pairs \$data must be an even number if the type of \$data is float[]. Othrewise, an exception is thrown.

The type of the data $data must be float[], Complex_2f[] or R::NDArray::FloatComplex.

=head2 add

C<static method add : L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex> ($x_ndarray : L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex>, $y_ndarray : L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex>);>

Creates a new L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, performs L<Math#caddf|SPVM::Math/"caddf"> method on each element of the n-dimensional array $x_ndarray and $y_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.

$y_ndarray allows to be a L<scalar|SPVM::R::NDArray/"Scalar">. In that case, each element used in the operation is the element at index 0.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

The n-dimensional array $y_ndarray must be defined. Otherwise, an exception is thrown.

The dimensions of $x_ndarray must be equal to the dimensions of $y_ndarray if $y_ndarray is not a scalar. Otherwise, an exception is thrown.

=head2 sub

C<static method sub : L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex> ($x_ndarray : L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex>, $y_ndarray : L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex>);>

Creates a new L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, performs L<Math#csubf|SPVM::Math/"csubf"> method on each element of the n-dimensional array $x_ndarray and $y_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.

$y_ndarray allows to be a L<scalar|SPVM::R::NDArray/"Scalar">. In that case, each element used in the operation is the element at index 0.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

The n-dimensional array $y_ndarray must be defined. Otherwise, an exception is thrown.

The dimensions of $x_ndarray must be equal to the dimensions of $y_ndarray if $y_ndarray is not a scalar. Otherwise, an exception is thrown.

=head2 mul

C<static method mul : L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex> ($x_ndarray : L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex>, $y_ndarray : L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex>);>

Creates a new L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, performs L<Math#cmulf|SPVM::Math/"cmulf"> method on each element of the n-dimensional array $x_ndarray and $y_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.

$y_ndarray allows to be a L<scalar|SPVM::R::NDArray/"Scalar">. In that case, each element used in the operation is the element at index 0.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

The n-dimensional array $y_ndarray must be defined. Otherwise, an exception is thrown.

The dimensions of $x_ndarray must be equal to the dimensions of $y_ndarray if $y_ndarray is not a scalar. Otherwise, an exception is thrown.

=head2 div

C<static method div : L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex> ($x_ndarray : L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex>, $y_ndarray : L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex>);>

Creates a new L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, performs L<Math#cdivf|SPVM::Math/"cdivf"> method on each element of the n-dimensional array $x_ndarray and $y_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.

$y_ndarray allows to be a L<scalar|SPVM::R::NDArray/"Scalar">. In that case, each element used in the operation is the element at index 0.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

The n-dimensional array $y_ndarray must be defined. Otherwise, an exception is thrown.

The dimensions of $x_ndarray must be equal to the dimensions of $y_ndarray if $y_ndarray is not a scalar. Otherwise, an exception is thrown.

=head2 neg

C<static method neg : L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex> ($x_ndarray : L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex>);>

Creates a new L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, performs L<Math#cnegf|SPVM::Math/"cnegf"> method on each element of the n-dimensional array $x_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.
Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

=head2 abs

C<static method abs : L<R::NDArray::FloatSPVM::R::NDArray::Float> ($x_ndarray : L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex>);>

Creates a new L<R::NDArray::Float|SPVM::R::NDArray::Float> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, performs L<Math#cabsf|SPVM::Math/"cabsf"> method on each element of the n-dimensional array $x_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.
Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

=head2 re

C<static method re : L<R::NDArray::FloatSPVM::R::NDArray::Float> ($x_ndarray : L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex>);>

Creates a new L<R::NDArray::Float|SPVM::R::NDArray::Float> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, gets the real number on each element of the n-dimensional array $x_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

=head2 im

C<static method im : L<R::NDArray::FloatSPVM::R::NDArray::Float> ($x_ndarray : L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex>);>

Creates a new L<R::NDArray::Float|SPVM::R::NDArray::Float> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, gets the image number on each element of the n-dimensional array $x_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

=head2 i

C<static method i : L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex> ();>

Creates a new L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex> object of the dimensions C<[1]> for a return value, sets the element of the new n-dimensional array to the return value of C<Math-E<gt>complex(0, 1)>, and returns the new n-dimensional array.

=head2 conj

C<static method conj : L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex> ($x_ndarray : L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex>);>

Creates a new L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, performs L<Math#conjf|SPVM::Math/"conjf"> method on each element of the n-dimensional array $x_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.
Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

=head2 arg

C<static method arg : L<R::NDArray::FloatSPVM::R::NDArray::Float> ($x_ndarray : L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex>);>

Creates a new L<R::NDArray::Float|SPVM::R::NDArray::Float> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, performs L<Math#cargf|SPVM::Math/"cargf"> method on each element of the n-dimensional array $x_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.
Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

=head2 eq

C<static method eq : L<R::NDArray::Int|SPVM::R::NDArray::Int> ($x_ndarray : L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex>, $y_ndarray : L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex>);>

Creates a new L<R::NDArray::Int|SPVM::R::NDArray::Int> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, performs AND operation C<&&> on the results of numeric comparison C<==> operation on the real number and image number of each element of the n-dimensional array $x_ndarray and $y_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

The n-dimensional array $y_ndarray must be defined. Otherwise, an exception is thrown.

The dimensions of $x_ndarray must be equal to the dimensions of $y_ndarray. Otherwise, an exception is thrown.

=head2 ne

C<static method ne : L<R::NDArray::Int|SPVM::R::NDArray::Int> ($x_ndarray : L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex>, $y_ndarray : L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex>);>

Creates a new L<R::NDArray::Int|SPVM::R::NDArray::Int> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, performs NOT operation C<!> on the reust of AND operation C<&&> on the results of numeric comparison C<==> operation on the real number and image number of each element of the n-dimensional array $x_ndarray and $y_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

The n-dimensional array $y_ndarray must be defined. Otherwise, an exception is thrown.

The dimensions of $x_ndarray must be equal to the dimensions of $y_ndarray. Otherwise, an exception is thrown.

=head2 rep

C<static method rep : L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex> ($x_ndarray : L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex>, $times : int);>

Same as L<R::OP#rep|SPVM::R::OP/"rep"> method, but the return type is different.

=head2 rep_length

C<static method rep_length : L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex> ($x_ndarray : L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex>, $length : int);>

Same as L<R::OP#rep_length|SPVM::R::OP/"rep_length"> method, but the return type is different.

=head2 sin

C<static method sin : L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex> ($x_ndarray : L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex>);>

Creates a new L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, performs L<Math#csinf|SPVM::Math/"csinf"> method on each element of the n-dimensional array $x_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.
Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

=head2 cos

C<static method cos : L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex> ($x_ndarray : L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex>);>

Creates a new L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, performs L<Math#ccosf|SPVM::Math/"ccosf"> method on each element of the n-dimensional array $x_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.
Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

=head2 tan

C<static method tan : L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex> ($x_ndarray : L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex>);>

Creates a new L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, performs L<Math#ctanf|SPVM::Math/"ctanf"> method on each element of the n-dimensional array $x_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.
Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

=head2 sinh

C<static method sinh : L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex> ($x_ndarray : L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex>);>

Creates a new L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, performs L<Math#csinhf|SPVM::Math/"csinhf"> method on each element of the n-dimensional array $x_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

=head2 cosh

C<static method cosh : L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex> ($x_ndarray : L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex>);>

Creates a new L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, performs L<Math#ccoshf|SPVM::Math/"ccoshf"> method on each element of the n-dimensional array $x_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

=head2 tanh

C<static method tanh : L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex> ($x_ndarray : L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex>);>

Creates a new L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, performs L<Math#ctanhf|SPVM::Math/"ctanhf"> method on each element of the n-dimensional array $x_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

=head2 acos

C<static method acos : L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex> ($x_ndarray : L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex>);>

Creates a new L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, performs L<Math#cacosf|SPVM::Math/"cacosf"> method on each element of the n-dimensional array $x_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

=head2 asin

C<static method asin : L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex> ($x_ndarray : L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex>);>

Creates a new L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, performs L<Math#casinf|SPVM::Math/"casinf"> method on each element of the n-dimensional array $x_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

=head2 atan

C<static method atan : L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex> ($x_ndarray : L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex>);>

Creates a new L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, performs L<Math#catanf|SPVM::Math/"catanf"> method on each element of the n-dimensional array $x_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

=head2 asinh

C<static method asinh : L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex> ($x_ndarray : L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex>);>

Creates a new L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, performs L<Math#casinhf|SPVM::Math/"casinhf"> method on each element of the n-dimensional array $x_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

=head2 acosh

C<static method acosh : L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex> ($x_ndarray : L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex>);>

Creates a new L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, performs L<Math#cacoshf|SPVM::Math/"cacoshf"> method on each element of the n-dimensional array $x_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

=head2 atanh

C<static method atanh : L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex> ($x_ndarray : L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex>);>

Creates a new L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, performs L<Math#catanhf|SPVM::Math/"catanhf"> method on each element of the n-dimensional array $x_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

=head2 exp

C<static method exp : L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex> ($x_ndarray : L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex>);>

Creates a new L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, performs L<Math#cexpf|SPVM::Math/"cexpf"> method on each element of the n-dimensional array $x_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

=head2 log

C<static method log : L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex> ($x_ndarray : L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex>);>

Creates a new L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, performs L<Math#clogf|SPVM::Math/"clogf"> method on each element of the n-dimensional array $x_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

=head2 sqrt

C<static method sqrt : L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex> ($x_ndarray : L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex>);>

Creates a new L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, performs L<Math#csqrtf|SPVM::Math/"csqrtf"> method on each element of the n-dimensional array $x_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

=head2 pow

C<static method pow : L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex> ($x_ndarray : L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex>, $y_ndarray : L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex>);>

Creates a new L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, performs L<Math#cpowf|SPVM::Math/"cpowf"> method given each element of the n-dimensional array $x_ndarray and $y_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.

$y_ndarray allows to be a L<scalar|SPVM::R::NDArray/"Scalar">. In that case, each element used in the operation is the element at index 0.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

The n-dimensional array $y_ndarray must be defined. Otherwise, an exception is thrown.

The dimensions of $x_ndarray must be equal to the dimensions of $y_ndarray if $y_ndarray is not a scalar. Otherwise, an exception is thrown.

=head2 sum

C<static method sum : L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex> ($x_ndarray : L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex>);>

Creates a new L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex> object with the dimenstion C<[1]> for a return value, calculates the sum of all elements of the n-dimensional array $x_ndarray, and sets the element of the new n-dimensional array to the result, and returns the new n-dimensional array.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

=head2 cumsum

C<static method cumsum : L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex> ($x_ndarray : L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex>);>

Creates a new L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, calculates the cumulative sum on each element of the n-dimensional array $x_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

=head2 prod

C<static method prod : L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex> ($x_ndarray : L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex>);>

Creates a new L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex> object with the dimenstion C<[1]> for a return value, calculates the production of all elements of the n-dimensional array $x_ndarray, and sets the element of the new n-dimensional array to the result, and returns the new n-dimensional array.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

=head2 cumprod

C<static method cumprod : L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex> ($x_ndarray : L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex>);>

Creates a new L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, calculates the cumulative product on each element of the n-dimensional array $x_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

=head2 diff

C<static method diff : L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex> ($x_ndarray : L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex>);>

Creates a new L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex> object of the dimensions as the n-dimensional array $x_ndarray minus 1 for a return value, calculats the difference of adjacent elements of the n-dimensional array $x_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

=head2 mean

C<static method mean : L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex> ($x_ndarray : L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex>);>

Creates a new L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex> object with the dimenstion C<[1]> for a return value, calculates the mean of all elements of the n-dimensional array $x_ndarray, and sets the element of the new n-dimensional array to the result, and returns the new n-dimensional array.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

=head2 dot

C<static method dot : L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex> ($x_ndarray : L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex>, $y_ndarray : L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex>);>

Creates a new L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex> object of the same dimensions as the n-dimensional array $x_ndarray for a return value, performs L<dot product|https://en.wikipedia.org/wiki/Dot_product> of elements of the n-dimensional array $x_ndarray and $y_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.

The dot product in this implementation is conjugate-linear in the first variable and linear in the second variable.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

The n-dimensional array $x_ndarray must be a vector. Otherwise, an exception is thrown.

The n-dimensional array $y_ndarray must be defined. Otherwise, an exception is thrown.

The n-dimensional array $y_ndarray must be a vector. Otherwise, an exception is thrown.

The length of the n-dimensional array $x_ndarray must be equal to the length of the n-dimensional array $y_ndarray. Otherwise, an exception is thrown.

=head2 outer

C<static method outer : L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex> ($x_ndarray : L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex>, $y_ndarray : L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex>);>

Creates a new L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex> object of the dimensions C<[$x_dim, $y_dim]> ($x_dim is the dimensions of $x_ndarray and $y_dim is the dimensions of $y_ndarray) for a return value, performs L<outer product|https://en.wikipedia.org/wiki/Outer_product> of elements of the n-dimensional array $x_ndarray and $y_ndarray, and sets each element of the new n-dimensional array to the each operation result, and returns the new n-dimensional array.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

The n-dimensional array $x_ndarray must be a vector. Otherwise, an exception is thrown.

The n-dimensional array $y_ndarray must be defined. Otherwise, an exception is thrown.

The n-dimensional array $y_ndarray must be a vector. Otherwise, an exception is thrown.

=head2 pi

C<static method pi : L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex> ();>

Same as L<R::OP::FloatComplex#pi|SPVM::R::OP::FloatComplex/"pi"> method, but the return type is different.

=head1 See Also

=over 2

=item * L<R::OP|SPVM::R::OP>

=item * L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex>

=item * L<R::NDArray|SPVM::R::NDArray>

=item * L<R|SPVM::R>

=back

=head1 Copyright & License

Copyright (c) 2024 Yuki Kimoto

MIT License

