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

=head2 rbind

C<static method rbind : R::NDArray ($x_ndarray : L<R::NDArray|SPVM::R::NDArray>, $y_ndarray : L<R::NDArray|SPVM::R::NDArray>);>

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

