package SPVM::R::OP::Matrix::Double;



1;

=head1 Name

SPVM::R::OP::Matrix::Double - Matrix Operations for R::NDArray::Double

=head1 Description

R::OP::Matrix::Double class in L<SPVM> has methods for matrix operations for L<R::NDArray::Double|SPVM::R::NDArray::Double>.

=head1 Usage

  use R::OP::Matrix::Double as MDOP;
  
  my $nrow = 3;
  my $ncol = 2;
  my $ndarray = MDOP->matrix([(double)1, 2, 3, 4, 5, 6], $nrow, $ncol);

=head1 Class Methods

=head2 matrix

C<static method matrix : L<R::NDArray::Double|SPVM::R::NDArray::Double> ($data : object of L<Double|SPVM::Double>|double[]|L<R::NDArray::Double|SPVM::R::NDArray::Double>, $nrow : int, $ncol : int);>

=head2 matrix_byrow

C<static method matrix_byrow : L<R::NDArray::Double|SPVM::R::NDArray::Double> ($data : object of L<Double|SPVM::Double>|double[]|L<R::NDArray::Double|SPVM::R::NDArray::Double>, $nrow : int, $ncol : int);>

=head2 cbind

C<static method cbind : L<R::NDArray::Double|SPVM::R::NDArray::Double> ($x_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>, $y_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>);>

=head2 rbind

C<static method rbind : L<R::NDArray::Double|SPVM::R::NDArray::Double> ($x_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>, $y_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>);>

=head2 diag

C<static method diag : L<R::NDArray::Double|SPVM::R::NDArray::Double> ($x_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>);>

=head2 diag_identity

C<static method diag_identity : L<R::NDArray::Double|SPVM::R::NDArray::Double> ($nrow : int);>

=head2 mul

C<static method mul : L<R::NDArray::Double|SPVM::R::NDArray::Double> ($x_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>, $y_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>);>

=head2 t

C<static method t : L<R::NDArray::Double|SPVM::R::NDArray::Double> ($x_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>);>

=head2 det

C<static method det : L<R::NDArray::Double|SPVM::R::NDArray::Double> ($x_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>);>

=head2 solve

C<static method solve : L<R::NDArray::Double|SPVM::R::NDArray::Double> ($x_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>);>

=head2 eigen

C<static method eigen : L<R::NDArray::Hash|SPVM::R::NDArray::Hash> ($x_ndarray : L<R::NDArray::Double|SPVM::R::NDArray::Double>);>

=head1 See Also

=over 2

=item * L<R::NDArray::Matrix::Double|SPVM::R::NDArray::Matrix::Double>

=item * L<R::NDArray|SPVM::R::NDArray>

=item * L<R|SPVM::R>

=back

=head1 Copyright & License

Copyright (c) 2024 Yuki Kimoto

MIT License

