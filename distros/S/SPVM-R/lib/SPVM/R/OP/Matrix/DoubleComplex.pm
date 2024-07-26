package SPVM::R::OP::Matrix::DoubleComplex;



1;

=head1 Name

SPVM::R::OP::Matrix::DoubleComplex - Matrix Operations for R::NDArray::DoubleComplex

=head1 Description

R::OP::Matrix::DoubleComplex class in L<SPVM> has methods for matrix operations for L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex>.

=head1 Usage

  use R::OP::Matrix::DoubleComplex as MDCOP;
  
  # $nrow * $ncol matrix. data field is [1+10i, 2+20i, 3+30i, 4+40i, 5+50i, 6+60i] by column major order.
  my $nrow = 3;
  my $ncol = 2;
  my $ndarray = MDCOP->matrix([(double)1,10,  2,20,  3,30,  4,40,  5,50,  6,60], $nrow, $ncol);

=head1 Class Methods

=head2 matrix

C<static method matrix : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex> ($data : object of double[]|L<Complex_2d|SPVM::Complex_2d>[]|L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex>, $nrow : int, $ncol : int);>

=head2 matrix_byrow

C<static method matrix_byrow : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex> ($data : object of double[]|L<Complex_2d|SPVM::Complex_2d>[]|L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex>, $nrow : int, $ncol : int);>

=head2 cbind

C<static method cbind : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex> ($x_ndarray : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex>, $y_ndarray : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex>);>

=head2 rbind

C<static method rbind : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex> ($x_ndarray : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex>, $y_ndarray : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex>);>

=head2 diag

C<static method diag : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex> ($x_ndarray : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex>);>

=head2 identity

C<static method identity : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex> ($nrow : int);>

=head2 mul

C<static method mul : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex> ($x_ndarray : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex>, $y_ndarray : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex>);>

=head2 t

C<static method t : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex> ($x_ndarray : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex>);>

=head2 det

C<static method det : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex> ($x_ndarray : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex>);>

=head2 solve

C<static method solve : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex> ($x_ndarray : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex>);>

=head2 eigen

C<static method eigen : L<R::NDArray::Hash|SPVM::R::NDArray::Hash> ($x_ndarray : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex>);>

=head1 See Also

=over 2

=item * L<R::NDArray::Matrix::DoubleComplex|SPVM::R::NDArray::Matrix::DoubleComplex>

=item * L<R::NDArray|SPVM::R::NDArray>

=item * L<R|SPVM::R>

=back

=head1 Copyright & License

Copyright (c) 2024 Yuki Kimoto

MIT License

