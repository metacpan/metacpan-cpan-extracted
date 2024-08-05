package SPVM::R::OP::Matrix;



1;

=head1 Name

SPVM::R::OP::Matrix - Matrix Operations

=head1 Description

R::OP::Matrix class in L<SPVM> has methods for operations for n-dimension arrays L<R::NDArray|SPVM::R::NDArray> representing matrices.

=head1 Usage

  use R::OP::Matrix;

=head1 Class Methods

=head2 cbind

C<static method cbind : R::NDArray ($x_ndarray : L<R::NDArray|SPVM::R::NDArray>, $y_ndarray : L<R::NDArray|SPVM::R::NDArray>);>

Creates a new L<R::NDArray> of the same type as the n-dimension array $x_ndarray, adds all columns of $x_ndarray and all columns of $y_ndarray are added to the new n-dimensional array in order, and returns the new n-dimensional array.

Exceptions:

The n-dimention array $x_ndarray must be defined. Otherwise, an exception is thrown.

The n-dimention array $x_ndarray must be a matrix. Otherwise, an exception is thrown.

The n-dimention array $y_ndarray must be defined. Otherwise, an exception is thrown.

The n-dimention array $y_ndarray must be a matrix. Otherwise, an exception is thrown.

The type of the n-dimention array $x_ndarray must be eqaul to the type of the n-dimention array $y_ndarray. Otherwise, an exception is thrown.

The row numbers of the n-dimention array $x_ndarray must be equal to the row numbers of the n-dimention array $y_ndarray. Otherwise, an exception is thrown.

=head2 rbind

C<static method rbind : R::NDArray ($x_ndarray : L<R::NDArray|SPVM::R::NDArray>, $y_ndarray : L<R::NDArray|SPVM::R::NDArray>);>

Creates a new L<R::NDArray> of the same type as the n-dimension array $x_ndarray, adds all rows of $x_ndarray and all rows of $y_ndarray are added to the new n-dimensional array in order, and returns the new n-dimensional array.

Exceptions:

The n-dimention array $x_ndarray must be defined. Otherwise, an exception is thrown.

The n-dimention array $x_ndarray must be a matrix. Otherwise, an exception is thrown.

The n-dimention array $y_ndarray must be defined. Otherwise, an exception is thrown.

The n-dimention array $y_ndarray must be a matrix. Otherwise, an exception is thrown.

The type of the n-dimention array $x_ndarray must be eqaul to the type of the n-dimention array $y_ndarray. Otherwise, an exception is thrown.

The column numbers of the n-dimention array $x_ndarray must be equal to the column numbers of the n-dimention array $y_ndarray. Otherwise, an exception is thrown.

=head1 Related Modules

=over 2

=item * L<R::OP::Matrix::Float|SPVM::R::OP::Matrix::Float>

=item * L<R::OP::Matrix::Double|SPVM::R::OP::Matrix::Double>

=item * L<R::OP::Matrix::FloatComplex|SPVM::R::OP::Matrix::FloatComplex>

=item * L<R::OP::Matrix::DoubleComplex|SPVM::R::OP::Matrix::DoubleComplex>

=back

=head1 See Also

=over 2

=item * L<R::OP|SPVM::R::OP>

=item * L<R::NDArray|SPVM::R::NDArray>

=item * L<R|SPVM::R>

=back

=head1 Copyright & License

Copyright (c) 2024 Yuki Kimoto

MIT License

