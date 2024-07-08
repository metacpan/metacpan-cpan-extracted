package SPVM::R;

our $VERSION = "0.005";

1;

=head1 Name

SPVM::R - Porting R language Features

=head1 Description

R class is a port of the R language features.

B<WARNINGS:Tests are not yet done. All of method and field definitions in all classes will be changed.>

=head1 Usage

=head2 Math Examples

  use R::OP::Double as DOP;
  use R::OP::Matrix::Double as DMOP;
  
  # Scalar
  my $sca1 = DOP->c(3);
  
  # Vector
  my $vec1 = DOP->c([(double)1, 2]);
  my $vec2 = DOP->c([(double)3, 4]);
  
  # Addition
  my $add = DOP->add($vec1, $vec2);
  
  # Subtruction
  my $sub = DOP->sub($vec1, $vec2);
  
  # Scalar multiplication
  my $scamul = DOP->scamul($sca1, $vec1);
  
  # Innner product
  my $inner_vec1_vec2 = DOP->inner($vec1, vec2);
  
  # Absolute
  my $abs_vec1 = DOP->abs($vec1);
  my $abs_vec2 = DOP->abs($vec2);
  
  # Cosine for angle
  my $cos = DOP->div($inner_vec1_vec2, DOP->mul($abs_vec1, $abs_vec2));
  
  # Matrix and liner conversion
  my $mat1 = DMOP->matrix_by_row(
    [(double)
      1, 0,
      0, 1
    ],
    2, 2
  );
  my $ret_vec = DMOP->mul($mat1, $vec1);

=head1 Details

=head2 Column major or Row major

Column major.

=head2 Complex Numbers

Use L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex>, L<R::OP::DoubleComplex|SPVM::R::OP::DoubleComplex>, and L<R::OP::Matrix::DoubleComplex|SPVM::R::OP::Matrix::DoubleComplex>.

=head1 Modules

=over 2

=item * L<R::DataFrame::Column|SPVM::R::DataFrame::Column>

=item * L<R::DataFrame|SPVM::R::DataFrame>

=item * L<R::NDArray::Byte|SPVM::R::NDArray::Byte>

=item * L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex>

=item * L<R::NDArray::Double|SPVM::R::NDArray::Double>

=item * L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex>

=item * L<R::NDArray::Float|SPVM::R::NDArray::Float>

=item * L<R::NDArray::Int|SPVM::R::NDArray::Int>

=item * L<R::NDArray::Long|SPVM::R::NDArray::Long>

=item * L<R::NDArray::Object|SPVM::R::NDArray::Object>

=item * L<R::NDArray::Short|SPVM::R::NDArray::Short>

=item * L<R::NDArray|SPVM::R::NDArray>

=item * L<R::NDArray::StringBuffer|SPVM::R::NDArray::StringBuffer>

=item * L<R::NDArray::String|SPVM::R::NDArray::String>

=item * L<R::NDArray::Time::Piece|SPVM::R::NDArray::Time::Piece>

=item * L<R::OP::Byte|SPVM::R::OP::Byte>

=item * L<R::OP::DataFrame|SPVM::R::OP::DataFrame>

=item * L<R::OP::DoubleComplex|SPVM::R::OP::DoubleComplex>

=item * L<R::OP::Double|SPVM::R::OP::Double>

=item * L<R::OP::FloatComplex|SPVM::R::OP::FloatComplex>

=item * L<R::OP::Float|SPVM::R::OP::Float>

=item * L<R::OP::Int|SPVM::R::OP::Int>

=item * L<R::OP::Long|SPVM::R::OP::Long>

=item * L<R::OP::Matrix|SPVM::R::OP::Matrix>

=item * L<R::OP::Matrix::DoubleComplex|SPVM::R::OP::Matrix::DoubleComplex>

=item * L<R::OP::Matrix::Double|SPVM::R::OP::Matrix::Double>

=item * L<R::OP::Matrix::FloatComplex|SPVM::R::OP::Matrix::FloatComplex>

=item * L<R::OP::Matrix::Float|SPVM::R::OP::Matrix::Float>

=item * L<R::OP::Short|SPVM::R::OP::Short>

=item * L<R::OP|SPVM::R::OP>

=item * L<R::OP::StringBuffer|SPVM::R::OP::StringBuffer>

=item * L<R::OP::String|SPVM::R::OP::String>

=item * L<R::OP::Time::Piece|SPVM::R::OP::Time::Piece>

=item * L<R::Resource::Eigen|SPVM::R::Resource::Eigen>

=item * L<R|SPVM::R>

=item * L<R::Util|SPVM::R::Util>

=back

=head1 Repository

L<SPVM::R - Github|https://github.com/yuki-kimoto/SPVM-R>

=head1 Author

Yuki Kimoto C<kimoto.yuki@gmail.com>

=head1 Copyright & License

Copyright (c) 2024 Yuki Kimoto

MIT License

