package SPVM::R;

our $VERSION = "0.009";

1;

=head1 Name

SPVM::R - Porting R language Features

=head1 Description

R class in L<SPVM> is a port of the L<R language|https://www.r-project.org/> features.

B<WARNINGS:Tests are not yet done. All of method and field definitions in all classes will be changed.>

=head1 Usage

=head2 Math Examples

  use R::OP::Double as DOP;
  use R::OP::Matrix::Double as DMOP;
  
  # Scalar
  my $sca1 = DOP->c((double)3);
  
  # Vector
  my $vec1 = DOP->c([(double)1, 2]);
  my $vec2 = DOP->c([(double)3, 4]);
  
  # Addition
  my $add = DOP->add($vec1, $vec2);
  
  # Subtruction
  my $sub = DOP->sub($vec1, $vec2);
  
  # Scalar multiplication
  my $scamul = DOP->scamul($sca1, $vec1);
  
  # Absolute
  my $abs_vec1 = DOP->abs($vec1);
  my $abs_vec2 = DOP->abs($vec2);
  
  # Trigonometric
  my $sin_vec1 = DOP->sin($vec1);
  my $cos_vec1 = DOP->cos($vec1);
  my $tan_vec1 = DOP->tan($vec1);
  
  # Innner product
  my $inner = DOP->inner($vec1, vec2);
  
  # Matrix(column major)
  my $mat1 = DMOP->matrix([1, 0, 0, 1], 2, 2);
  
  my $mat_ret = DMOP->mul($mat1, $vec1);

=head1 Tutorial

L<SPVM::R Tutorial|https://github.com/yuki-kimoto/SPVM-R/wiki/SPVM%3A%3AR-Tutorial>

=head1 Modules

=head2 N-Dimension Array

=over 2

=item * L<R::NDArray|SPVM::R::NDArray>

=item * L<R::NDArray::Byte|SPVM::R::NDArray::Byte>

=item * L<R::NDArray::Short|SPVM::R::NDArray::Short>

=item * L<R::NDArray::Int|SPVM::R::NDArray::Int>

=item * L<R::NDArray::Float|SPVM::R::NDArray::Float>

=item * L<R::NDArray::Double|SPVM::R::NDArray::Double>

=item * L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex>

=item * L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex>

=item * L<R::NDArray::Long|SPVM::R::NDArray::Long>

=item * L<R::NDArray::AnyObject|SPVM::R::NDArray::AnyObject>

=item * L<R::NDArray::String|SPVM::R::NDArray::String>

=item * L<R::NDArray::StringBuffer|SPVM::R::NDArray::StringBuffer>

=item * L<R::NDArray::Time::Piece|SPVM::R::NDArray::Time::Piece>

=back

=head2 N-Dimension Array Operations

=over 2

=item * L<R::OP|SPVM::R::OP>

=item * L<R::OP::Byte|SPVM::R::OP::Byte>

=item * L<R::OP::Short|SPVM::R::OP::Short>

=item * L<R::OP::Int|SPVM::R::OP::Int>

=item * L<R::OP::Long|SPVM::R::OP::Long>

=item * L<R::OP::Float|SPVM::R::OP::Float>

=item * L<R::OP::Double|SPVM::R::OP::Double>

=item * L<R::OP::FloatComplex|SPVM::R::OP::FloatComplex>

=item * L<R::OP::DoubleComplex|SPVM::R::OP::DoubleComplex>

=item * L<R::OP::AnyObject|SPVM::R::OP::AnyObject>

=item * L<R::OP::String|SPVM::R::OP::String>

=item * L<R::OP::StringBuffer|SPVM::R::OP::StringBuffer>

=item * L<R::OP::Time::Piece|SPVM::R::OP::Time::Piece>

=back

=head2 Matrix Operations

=over 2

=item * L<R::OP::Matrix::Float|SPVM::R::OP::Matrix::Float>

=item * L<R::OP::Matrix::Double|SPVM::R::OP::Matrix::Double>

=item * L<R::OP::Matrix::FloatComplex|SPVM::R::OP::Matrix::FloatComplex>

=item * L<R::OP::Matrix::DoubleComplex|SPVM::R::OP::Matrix::DoubleComplex>

=back

=head2 Data Frame

=over 2

=item * L<R::DataFrame|SPVM::R::DataFrame>

=item * L<R::OP::DataFrame|SPVM::R::OP::DataFrame>

=back

=head2 Utilities

=over 2

=item * L<R::Util|SPVM::R::Util>

=back

=head1 Wiki

L<SPVM::R Wiki|https://github.com/yuki-kimoto/SPVM-R/wiki>

=head1 Repository

L<SPVM::R - Github|https://github.com/yuki-kimoto/SPVM-R>

=head1 Author

Yuki Kimoto C<kimoto.yuki@gmail.com>

=head1 Copyright & License

Copyright (c) 2024 Yuki Kimoto

MIT License

