package SPVM::R;

our $VERSION = "0.101001";

1;

=head1 Name

SPVM::R - Porting R language Features

=head1 Description

R class in L<SPVM> is a port of the L<R language|https://www.r-project.org/> features.

=head1 Features

=over 2

=item * L<N-dimensional arrays|SPVM::R::NDArray> and L<their operations|SPVM::R::OP>, such as addition, subtraction, multiplication, division, modulo(or remainder), sum, max, min, mean, cumulative sum, cumulative product, trigonometric functions, exponential functions, log functions.

=item * Support of L<sequence creation|SPVM::R::OP::Int/"seq">, L<repetition|SPVM::R::OP/"rep">, L<slice|SPVM::R::NDArray/"slice">, L<order|SPVM::R::NDArray/"order">, L<sort|SPVM::R::NDArray/"sort_asc"> of a n-dimensional array.

=item * Various types of n-dimensional arrays(L<byte|SPVM::R::OP::Byte>, L<short|SPVM::R::OP::Short>, L<int|SPVM::R::OP::Int>, L<long|SPVM::R::OP::Long>, L<float|SPVM::R::OP::Float>, L<double|SPVM::R::OP::Double>, L<float complex|SPVM::R::OP::FloatComplex>, L<double complex|SPVM::R::OP::DoubleComplex>, L<string|SPVM::R::OP::String>, L<variable-length string|SPVM::R::OP::StringBuffer>, L<datetime|SPVM::R::OP::Time::Piece>).

=item * Support of L<NA representation|SPVM::R::NDArray/"NA Representation">.

=item * L<Data frame|SPVM::R::DataFrame> and L<its operations|SPVM::R::OP::DataFrame>.

=item * Support of L<slice|SPVM::R::DataFrame/"slice">(L<subset|SPVM::R::OP::DataFrame/"subset">), L<order|SPVM::R::DataFrame/"order">, L<sort|SPVM::R::DataFrame/"sort"> of a data frame.

=back

=head1 Usage

=head2 Math and Matrix Examples

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
  my $dot = DOP->dot($vec1, vec2);
  
  # Matrix(column major)
  my $mat1 = DMOP->matrix([1, 0, 0, 1], 2, 2);
  
  my $mat_ret = DMOP->mul($mat1, $vec1);

See also L<examples of matrix|https://github.com/yuki-kimoto/SPVM-R/wiki/SPVM%3A%3AR-Matrix-Examples>.

=head2 Data Frame Examples

Create a data frame.

  use R::DataFrame;
  
  my $data_frame = R::DataFrame->new;

Add colunns:

  use R::OP::String as STROP;
  use R::OP::Int as IOP;
  use R::OP::Double as DOP;
  use R::OP::Time::Pirce as TPOP;
  
  $data_frame->set_col("Name" => STROP->c(["Mike, "Ken", "Yumi"]));
  $data_frame->set_col("Age" => IOP->c([12, 20, 15]));
  $data_frame->set_col("Height" => DOP->c([(double)160.7, 173.2, 153.3]));
  $data_frame->set_col("Birth" => TPOP->c(["2010-10-15", "2000-07-08", "2020-02-08"]));

Get columns and rows:

  $data_frame->slice(["Name", "Age"], [IOP->c([0, 1, 2])]); 

Get rows using conditions:
  
  # Age > 12
  my $conditions = IOP->gt($data_frame->col("Age"), IOP->rep(IOP->c(12), $data_frame->nrow);
  $data_frame->slice(["Name", "Age"], [$conditions->to_indexes]);
  
  # Age > 12 && Height < 150.3
  my $conditions = IOP->and(
    IOP->gt($data_frame->col("Age"), IOP->rep(IOP->c(12), $data_frame->nrow)),
    IOP->lt($data_frame->col("Height"), IOP->rep(IOP->c(150.3), $data_frame->nrow)),
  );
  $data_frame->slice(["Name", "Age"], [$conditions->to_indexes]);

Sort rows:
  
  # Age asc
  $data_frame->sort(["Age"]);

  # Age desc
  $data_frame->sort(["Age desc"]);

  # Age asc, Height asc
  $data_frame->sort(["Age", "Height"]);

  # Age asc, Height desc
  $data_frame->sort(["Age", "Height desc"]);

See also L<examples of data frames|https://github.com/yuki-kimoto/SPVM-R/wiki/SPVM%3A%3AR-Data-Frame-Examples>.

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

=item * L<R::OP::Matrix|SPVM::R::OP::Matrix>

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

