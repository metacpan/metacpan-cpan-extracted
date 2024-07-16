package SPVM::R::OP::Matrix::Float;



1;

=head1 Name

SPVM::R::OP::Matrix::Float - Matrix Operations for R::NDArray::Float

=head1 Description

R::OP::Matrix::Float class in L<SPVM> has methods for matrix operations for L<R::NDArray::Float|SPVM::R::NDArray::Float>.

=head1 Usage

  use R::OP::Matrix::Float as MFOP;
  
  my $nrow = 3;
  my $ncol = 2;
  my $ndarray = MFOP->matrix([(float)1, 2, 3, 4, 5, 6], $nrow, $ncol);

=head1 Class Methods

=head2 matrix

C<static method matrix : L<R::NDArray::Float|SPVM::R::NDArray::Float> ($data : object of L<Float|SPVM::Float>|float[]|L<R::NDArray::Float|SPVM::R::NDArray::Float>, $nrow : int, $ncol : int);>

=head2 matrix_byrow

C<static method matrix_byrow : L<R::NDArray::Float|SPVM::R::NDArray::Float> ($data : object of L<Float|SPVM::Float>|float[]|L<R::NDArray::Float|SPVM::R::NDArray::Float>, $nrow : int, $ncol : int);>

=head2 cbind

C<static method cbind : L<R::NDArray::Float|SPVM::R::NDArray::Float> ($x_ndarray : L<R::NDArray::Float|SPVM::R::NDArray::Float>, $y_ndarray : L<R::NDArray::Float|SPVM::R::NDArray::Float>);>

=head2 rbind

C<static method rbind : L<R::NDArray::Float|SPVM::R::NDArray::Float> ($x_ndarray : L<R::NDArray::Float|SPVM::R::NDArray::Float>, $y_ndarray : L<R::NDArray::Float|SPVM::R::NDArray::Float>);>

=head2 diag

C<static method diag : L<R::NDArray::Float|SPVM::R::NDArray::Float> ($x_ndarray : L<R::NDArray::Float|SPVM::R::NDArray::Float>);>

=head2 diag_identity

C<static method diag_identity : L<R::NDArray::Float|SPVM::R::NDArray::Float> ($nrow : int);>

=head2 mul

C<static method mul : L<R::NDArray::Float|SPVM::R::NDArray::Float> ($x_ndarray : L<R::NDArray::Float|SPVM::R::NDArray::Float>, $y_ndarray : L<R::NDArray::Float|SPVM::R::NDArray::Float>);>

=head2 t

C<static method t : L<R::NDArray::Float|SPVM::R::NDArray::Float> ($x_ndarray : L<R::NDArray::Float|SPVM::R::NDArray::Float>);>

=head2 det

C<static method det : L<R::NDArray::Float|SPVM::R::NDArray::Float> ($x_ndarray : L<R::NDArray::Float|SPVM::R::NDArray::Float>);>

=head2 solve

C<static method solve : L<R::NDArray::Float|SPVM::R::NDArray::Float> ($x_ndarray : L<R::NDArray::Float|SPVM::R::NDArray::Float>);>

=head2 eigen

C<static method eigen : L<R::NDArray::Hash|SPVM::R::NDArray::Hash> ($x_ndarray : L<R::NDArray::Float|SPVM::R::NDArray::Float>);>

=head1 See Also

=over 2

=item * L<R::NDArray::Matrix::Float|SPVM::R::NDArray::Matrix::Float>

=item * L<R::NDArray|SPVM::R::NDArray>

=item * L<R|SPVM::R>

=back

=head1 Copyright & License

Copyright (c) 2024 Yuki Kimoto

MIT License

