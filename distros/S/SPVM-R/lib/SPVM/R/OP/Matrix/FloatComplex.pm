package SPVM::R::OP::Matrix::FloatComplex;



1;

=head1 Name

SPVM::R::OP::Matrix::FloatComplex - Matrix Operations for R::NDArray::FloatComplex

=head1 Description

R::OP::Matrix::FloatComplex class in L<SPVM> has methods for matrix operations for L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex>.

=head1 Usage

  use R::OP::Matrix::FloatComplex as MFCOP;
  
  # $nrow * $ncol matrix. data field is [1+10i, 2+20i, 3+30i, 4+40i, 5+50i, 6+60i] by column major order.
  my $nrow = 3;
  my $ncol = 2;
  my $ndarray = MFCOP->matrix([(float)1,10,  2,20,  3,30,  4,40,  5,50,  6,60], $nrow, $ncol);

See also L<Matrix Examples|https://github.com/yuki-kimoto/SPVM-R/wiki/SPVM%3A%3AR-Matrix-Examples>.

=head1 Class Methods

=head2 matrix

C<static method matrix : L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex> ($data : object of float[]|L<Complex_2f|SPVM::Complex_2f>[]|L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex>, $nrow : int, $ncol : int);>

Creates a new L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex> object that represents a matrix given the data $data, the row numers $nrow, and the column numbers $ncol, and returns the new object.

This method calls L<R::OP::FloatComplex#c|SPVM::R::OP::FloatComplex/"c"> method.

  my $ret_ndarray = R::OP::FloatComplex->c($data, [$nrow, $ncol]);

Exceptions:

Exceptions thrown by L<R::OP::FloatComplex#c|SPVM::R::OP::FloatComplex/"c"> method could be thrown.

=head2 matrix_byrow

C<static method matrix_byrow : L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex> ($data : object of float[]|L<Complex_2f|SPVM::Complex_2f>[]|L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex>, $nrow : int, $ncol : int);>

Same as L</"matrix"> method, but the input data $data is interpreted as column major order.

Exceptions:

Exceptions thrown by L</"matrix"> method could be thrown.

=head2 cbind

C<static method cbind : L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex> ($x_ndarray : L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex>, $y_ndarray : L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex>);>

Same as L<R::OP::Matrix#cbind|SPVM::R::OP::Matrix/"cbind"> method, but the return type is different.

=head2 rbind

C<static method rbind : L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex> ($x_ndarray : L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex>, $y_ndarray : L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex>);>

Same as L<R::OP::Matrix#rbind|SPVM::R::OP::Matrix/"rbind"> method, but the return type is different.

=head2 diag

C<static method diag : L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex> ($x_ndarray : L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex>);>

Creates a L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex> object that represents a diagonal matrix given a n-dimensional array $x_ndarray that is a vector with diagonal values, and returns the new object.

The row numbers and column numbers of the new object is equal to the value of C<length> field of $x_ndarray.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

The n-dimensional array $x_ndarray must be a vector. Otherwise, an exception is thrown.

=head2 slice_diag

C<static method slice_diag : L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex> ($x_ndarray : R::NDArray::FloatComplex);>

Creates a new L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex>, sets its data to the diagonal values of the n-dimension array $x_ndarray that is a matrix, and returns the new object.

The value of C<length> field of the new object is equal to the row numbers of $x_ndarray.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

The n-dimensional array $x_ndarray must be a matrix. Otherwise, an exception is thrown.

=head2 identity

C<static method identity : L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex> ($nrow : int);>

Creates a new L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex> object that represets an identity matrix given the row numbers $nrow, and returns the new object.

Exceptions:

The row numbers $nrow must be greater than 0. Otherwise, an exception is thrown.

=head2 mul

C<static method mul : L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex> ($x_ndarray : L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex>, $y_ndarray : L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex>);>

Performs a matrix multiplication on the n-dimension array $x_ndarray that is a matrix and the n-dimension array $y_ndarray that is a matrix.

And creates a new L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex> object with the result, and returns the new object.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

The n-dimensional array $x_ndarray must be a matrix. Otherwise, an exception is thrown.

The n-dimensional array $y_ndarray must be defined. Otherwise, an exception is thrown.

The n-dimensional array $y_ndarray must be a matrix. Otherwise, an exception is thrown.

The column numbers of the matrix $x_ndarray must be equal to the row numbers of the matrix $y_ndarray. Otherwise, an exception is thrown.

=head2 t

C<static method t : L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex> ($x_ndarray : L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex>);>

Performs a matrix transpose on the n-dimension array $x_ndarray that is a matrix, creates a new L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex> object with the result, and returns the new object.

Excetpions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

The n-dimensional array $x_ndarray must be a matrix. Otherwise, an exception is thrown.

=head2 det

C<static method det : L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex> ($x_ndarray : L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex>);>

Calculates the determinant of the n-dimension array $x_ndarray that is a matrix, creates a new L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex> object with the result, and returns the new object.

The new object is a scalar.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

The n-dimensional array $x_ndarray must be a square matrix. Otherwise, an exception is thrown.

=head2 solve

C<static method solve : L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex> ($x_ndarray : L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex>);>

Calculates the inverse of the n-dimension array $x_ndarray that is a matrix, creates a new L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex> object with the result, and returns the new object.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

The n-dimensional array $x_ndarray must be a square matrix. Otherwise, an exception is thrown.

The determinant of the n-dimensional array $x_ndarray that is a matrix must not be equal to 0. Otherwise, an exception is thrown.

=head2 eigen

C<static method eigen : L<R::NDArray::Hash|SPVM::R::NDArray::Hash> ($x_ndarray : L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex>);>

Finds the eigenvectors and eigenvalues of the n-dimension array $x_ndarray that is a matrix, and creates a new two L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex> object for each results.

And creates a new L<R::NDArray::Hash|SPVM::R::NDArray::Hash> object, sets the value of key C<"vectors"> to the new object that has the eigenvectors, sets the value of key C<"values"> to the new object that has the eigenvalues. Note that these vectores and values are complex numbers even if the result is able to be represented by real numbers.

And returns the new L<R::NDArray::Hash|SPVM::R::NDArray::Hash>.

Exceptions:

The n-dimensional array $x_ndarray must be defined. Otherwise, an exception is thrown.

The n-dimensional array $x_ndarray must be a square matrix. Otherwise, an exception is thrown.

=head1 See Also

=over 2

=item * L<Matrix Examples|https://github.com/yuki-kimoto/SPVM-R/wiki/SPVM%3A%3AR-Matrix-Examples>

=item * L<R::OP::FloatComplex|SPVM::R::OP::FloatComplex>

=item * L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex>

=item * L<R::NDArray|SPVM::R::NDArray>

=item * L<R|SPVM::R>

=back

=head1 Copyright & License

Copyright (c) 2024 Yuki Kimoto

MIT License

