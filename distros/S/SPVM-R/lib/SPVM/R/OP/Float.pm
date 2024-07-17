package SPVM::R::OP::Float;



1;

=head1 Name

SPVM::R::OP::Float - N-Dimensional Array Operations for R::NDArray::Float

=head1 Description

The R::OP::Float class in L<SPVM> has methods for n-dimensional array operations for L<R::NDArray::Float|SPVM::R::NDArray::Float>.

=head1 Usage

  use R::OP::Float as FOP;
  
  my $ndarray_scalar = FOP->c((float)1);
  
  my $ndarray_vector = FOP->c([(float)1, 2, 3]);
  
  my $ndarray = FOP->c([(float)1, 2, 3, 4, 5, 6], [3, 2]);
  
  my $ndarray2 = FOP->c($ndarray);

=head1 Class Methods

=head2 c

C<static method c : L<R::NDArray::Float|SPVM::R::NDArray::Float> ($data : object of L<Float|SPVM::Float>|float[]|L<R::NDArray::Float|SPVM::R::NDArray::Float>, $dim : int[] = undef);>

=head2 add

C<static method add : L<R::NDArray::Float|SPVM::R::NDArray::Float> ($x_ndarray : L<R::NDArray::Float|SPVM::R::NDArray::Float>, $y_ndarray : L<R::NDArray::Float|SPVM::R::NDArray::Float>);>

=head2 sub

C<static method sub : L<R::NDArray::Float|SPVM::R::NDArray::Float> ($x_ndarray : L<R::NDArray::Float|SPVM::R::NDArray::Float>, $y_ndarray : L<R::NDArray::Float|SPVM::R::NDArray::Float>);>

=head2 mul

C<static method mul : L<R::NDArray::Float|SPVM::R::NDArray::Float> ($y_ndarray : L<R::NDArray::Float|SPVM::R::NDArray::Float>, $x_ndarray : L<R::NDArray::Float|SPVM::R::NDArray::Float>);>

=head2 scamul

C<static method scamul : R::NDArray::Int ($x_ndarray : L<R::NDArray::Float|SPVM::R::NDArray::Float>, $scalar_ndarray : L<R::NDArray::Float|SPVM::R::NDArray::Float>);>

=head2 div

C<static method div : L<R::NDArray::Float|SPVM::R::NDArray::Float> ($x_ndarray : L<R::NDArray::Float|SPVM::R::NDArray::Float>, $y_ndarray : L<R::NDArray::Float|SPVM::R::NDArray::Float>);>

=head2 scadiv

C<static method scadiv : R::NDArray::Int ($x_ndarray : L<R::NDArray::Float|SPVM::R::NDArray::Float>, $scalar_ndarray : L<R::NDArray::Float|SPVM::R::NDArray::Float>);>

=head2 neg

C<static method neg : L<R::NDArray::Float|SPVM::R::NDArray::Float> ($x_ndarray : L<R::NDArray::Float|SPVM::R::NDArray::Float>);>

=head2 abs

C<static method abs : L<R::NDArray::Float|SPVM::R::NDArray::Float> ($x_ndarray : L<R::NDArray::Float|SPVM::R::NDArray::Float>);>

=head2 eq

C<static method eq : R::NDArray::Int ($x_ndarray : L<R::NDArray::Float|SPVM::R::NDArray::Float>, $y_ndarray : L<R::NDArray::Float|SPVM::R::NDArray::Float>);>

=head2 ne

C<static method ne : R::NDArray::Int ($x_ndarray : L<R::NDArray::Float|SPVM::R::NDArray::Float>, $y_ndarray : L<R::NDArray::Float|SPVM::R::NDArray::Float>);>

=head2 gt

C<static method gt : R::NDArray::Int ($x_ndarray : L<R::NDArray::Float|SPVM::R::NDArray::Float>, $y_ndarray : L<R::NDArray::Float|SPVM::R::NDArray::Float>);>

=head2 ge

C<static method ge : R::NDArray::Int ($x_ndarray : L<R::NDArray::Float|SPVM::R::NDArray::Float>, $y_ndarray : L<R::NDArray::Float|SPVM::R::NDArray::Float>);>

=head2 lt

C<static method lt : R::NDArray::Int ($x_ndarray : L<R::NDArray::Float|SPVM::R::NDArray::Float>, $y_ndarray : L<R::NDArray::Float|SPVM::R::NDArray::Float>);>

=head2 le

C<static method le : R::NDArray::Int ($x_ndarray : L<R::NDArray::Float|SPVM::R::NDArray::Float>, $y_ndarray : L<R::NDArray::Float|SPVM::R::NDArray::Float>);>

=head2 rep

C<static method rep : L<R::NDArray::Float|SPVM::R::NDArray::Float> ($x_ndarray : L<R::NDArray::Float|SPVM::R::NDArray::Float>, $times : int);>

=head2 rep_length

C<static method rep_length : L<R::NDArray::Float|SPVM::R::NDArray::Float> ($x_ndarray : L<R::NDArray::Float|SPVM::R::NDArray::Float>, $length : int);>

=head2 seq

C<static method seq : L<R::NDArray::Float|SPVM::R::NDArray::Float> ($begin : float, $end : float, $by : float = 1);>

=head2 seq_length

C<static method seq_length : L<R::NDArray::Float|SPVM::R::NDArray::Float> ($begin : float, $end : float, $length : int);>

=head2 sin

C<static method sin : L<R::NDArray::Float|SPVM::R::NDArray::Float> ($x_ndarray : L<R::NDArray::Float|SPVM::R::NDArray::Float>);>

=head2 cos

C<static method cos : L<R::NDArray::Float|SPVM::R::NDArray::Float> ($x_ndarray : L<R::NDArray::Float|SPVM::R::NDArray::Float>);>

=head2 tan

C<static method tan : L<R::NDArray::Float|SPVM::R::NDArray::Float> ($x_ndarray : L<R::NDArray::Float|SPVM::R::NDArray::Float>);>

=head2 sinh

C<static method sinh : L<R::NDArray::Float|SPVM::R::NDArray::Float> ($x_ndarray : L<R::NDArray::Float|SPVM::R::NDArray::Float>);>

=head2 cosh

C<static method cosh : L<R::NDArray::Float|SPVM::R::NDArray::Float> ($x_ndarray : L<R::NDArray::Float|SPVM::R::NDArray::Float>);>

=head2 tanh

C<static method tanh : L<R::NDArray::Float|SPVM::R::NDArray::Float> ($x_ndarray : L<R::NDArray::Float|SPVM::R::NDArray::Float>);>

=head2 acos

C<static method acos : L<R::NDArray::Float|SPVM::R::NDArray::Float> ($x_ndarray : L<R::NDArray::Float|SPVM::R::NDArray::Float>);>

=head2 asin

C<static method asin : L<R::NDArray::Float|SPVM::R::NDArray::Float> ($x_ndarray : L<R::NDArray::Float|SPVM::R::NDArray::Float>);>

=head2 atan

C<static method atan : L<R::NDArray::Float|SPVM::R::NDArray::Float> ($x_ndarray : L<R::NDArray::Float|SPVM::R::NDArray::Float>);>

=head2 asinh

C<static method asinh : L<R::NDArray::Float|SPVM::R::NDArray::Float> ($x_ndarray : L<R::NDArray::Float|SPVM::R::NDArray::Float>);>

=head2 acosh

C<static method acosh : L<R::NDArray::Float|SPVM::R::NDArray::Float> ($x_ndarray : L<R::NDArray::Float|SPVM::R::NDArray::Float>);>

=head2 atanh

C<static method atanh : L<R::NDArray::Float|SPVM::R::NDArray::Float> ($x_ndarray : L<R::NDArray::Float|SPVM::R::NDArray::Float>);>

=head2 exp

C<static method exp : L<R::NDArray::Float|SPVM::R::NDArray::Float> ($x_ndarray : L<R::NDArray::Float|SPVM::R::NDArray::Float>);>

=head2 expm1

C<static method expm1 : L<R::NDArray::Float|SPVM::R::NDArray::Float> ($x_ndarray : L<R::NDArray::Float|SPVM::R::NDArray::Float>);>

=head2 log

C<static method log : L<R::NDArray::Float|SPVM::R::NDArray::Float> ($x_ndarray : L<R::NDArray::Float|SPVM::R::NDArray::Float>);>

=head2 logb

C<static method logb : L<R::NDArray::Float|SPVM::R::NDArray::Float> ($x_ndarray : L<R::NDArray::Float|SPVM::R::NDArray::Float>);>

=head2 log2

C<static method log2 : L<R::NDArray::Float|SPVM::R::NDArray::Float> ($x_ndarray : L<R::NDArray::Float|SPVM::R::NDArray::Float>);>

=head2 log10

C<static method log10 : L<R::NDArray::Float|SPVM::R::NDArray::Float> ($x_ndarray : L<R::NDArray::Float|SPVM::R::NDArray::Float>);>

=head2 sqrt

C<static method sqrt : L<R::NDArray::Float|SPVM::R::NDArray::Float> ($x_ndarray : L<R::NDArray::Float|SPVM::R::NDArray::Float>);>

=head2 isinf

C<static method isinf : L<R::NDArray::Int|SPVM::R::NDArray::Int> ($x_ndarray : L<R::NDArray::Float|SPVM::R::NDArray::Float>);>

=head2 is_infinite

C<static method is_infinite : L<R::NDArray::Int|SPVM::R::NDArray::Int> ($x_ndarray : L<R::NDArray::Float|SPVM::R::NDArray::Float>);>

=head2 is_finite

C<static method is_finite : L<R::NDArray::Int|SPVM::R::NDArray::Int> ($x_ndarray : L<R::NDArray::Float|SPVM::R::NDArray::Float>);>

=head2 isnan

C<static method isnan : L<R::NDArray::Int|SPVM::R::NDArray::Int> ($x_ndarray : L<R::NDArray::Float|SPVM::R::NDArray::Float>);>

=head2 is_nan

C<static method is_nan : L<R::NDArray::Int|SPVM::R::NDArray::Int> ($x_ndarray : L<R::NDArray::Float|SPVM::R::NDArray::Float>);>

=head2 pow

C<static method pow : L<R::NDArray::Float|SPVM::R::NDArray::Float> ($x_ndarray : L<R::NDArray::Float|SPVM::R::NDArray::Float>, $y_ndarray : L<R::NDArray::Float|SPVM::R::NDArray::Float>);>

=head2 atan2

C<static method atan2 : L<R::NDArray::Float|SPVM::R::NDArray::Float> ($y_ndarray : L<R::NDArray::Float|SPVM::R::NDArray::Float>, $x_ndarray : L<R::NDArray::Float|SPVM::R::NDArray::Float>);>

=head2 modf

C<static method modf : L<R::NDArray::Float|SPVM::R::NDArray::Float> ($x_ndarray : L<R::NDArray::Float|SPVM::R::NDArray::Float>, $intpart_ndarray_ref : L<R::NDArray::Float|SPVM::R::NDArray::Float>[]);>

=head2 ceil

C<static method ceil : L<R::NDArray::Float|SPVM::R::NDArray::Float> ($x_ndarray : L<R::NDArray::Float|SPVM::R::NDArray::Float>);>

=head2 ceiling

C<static method ceiling : L<R::NDArray::Float|SPVM::R::NDArray::Float> ($x_ndarray : L<R::NDArray::Float|SPVM::R::NDArray::Float>);>

=head2 floor

C<static method floor : L<R::NDArray::Float|SPVM::R::NDArray::Float> ($x_ndarray : L<R::NDArray::Float|SPVM::R::NDArray::Float>);>

=head2 round

C<static method round : L<R::NDArray::Float|SPVM::R::NDArray::Float> ($x_ndarray : L<R::NDArray::Float|SPVM::R::NDArray::Float>);>

=head2 lround

C<static method lround : R::NDArray::Long ($x_ndarray : L<R::NDArray::Float|SPVM::R::NDArray::Float>);>

=head2 remainder

C<static method remainder : L<R::NDArray::Float|SPVM::R::NDArray::Float> ($x_ndarray : L<R::NDArray::Float|SPVM::R::NDArray::Float>, $y_ndarray : L<R::NDArray::Float|SPVM::R::NDArray::Float>);>

=head2 fmod

C<static method fmod : L<R::NDArray::Float|SPVM::R::NDArray::Float> ($x_ndarray : L<R::NDArray::Float|SPVM::R::NDArray::Float>, $y_ndarray : L<R::NDArray::Float|SPVM::R::NDArray::Float>);>

=head2 sum

C<static method sum : L<R::NDArray::Float|SPVM::R::NDArray::Float> ($x_ndarray : L<R::NDArray::Float|SPVM::R::NDArray::Float>);>

=head2 cumsum

C<static method cumsum : L<R::NDArray::Float|SPVM::R::NDArray::Float> ($x_ndarray : L<R::NDArray::Float|SPVM::R::NDArray::Float>);>

=head2 prod

C<static method prod : L<R::NDArray::Float|SPVM::R::NDArray::Float> ($x_ndarray : L<R::NDArray::Float|SPVM::R::NDArray::Float>);>

=head2 cumprod

C<static method cumprod : L<R::NDArray::Float|SPVM::R::NDArray::Float> ($x_ndarray : L<R::NDArray::Float|SPVM::R::NDArray::Float>);>

=head2 diff

C<static method diff : L<R::NDArray::Float|SPVM::R::NDArray::Float> ($x_ndarray : L<R::NDArray::Float|SPVM::R::NDArray::Float>);>

=head2 max

C<static method max : L<R::NDArray::Float|SPVM::R::NDArray::Float> ($x_ndarray : L<R::NDArray::Float|SPVM::R::NDArray::Float>);>

=head2 min

C<static method min : L<R::NDArray::Float|SPVM::R::NDArray::Float> ($x_ndarray : L<R::NDArray::Float|SPVM::R::NDArray::Float>);>

=head2 mean

C<static method mean : L<R::NDArray::Float|SPVM::R::NDArray::Float> ($x_ndarray : L<R::NDArray::Float|SPVM::R::NDArray::Float>);>

=head2 inner

C<static method inner : L<R::NDArray::Float|SPVM::R::NDArray::Float> ($x_ndarray : L<R::NDArray::Float|SPVM::R::NDArray::Float>, $y_ndarray : L<R::NDArray::Float|SPVM::R::NDArray::Float>);>

=head2 cross

C<static method cross : L<R::NDArray::Float|SPVM::R::NDArray::Float> ($x_ndarray : L<R::NDArray::Float|SPVM::R::NDArray::Float>, $y_ndarray : L<R::NDArray::Float|SPVM::R::NDArray::Float>);>

=head2 outer

C<static method outer : L<R::NDArray::Float|SPVM::R::NDArray::Float> ($x_ndarray : L<R::NDArray::Float|SPVM::R::NDArray::Float>, $y_ndarray : L<R::NDArray::Float|SPVM::R::NDArray::Float>);>

=head1 See Also

=over 2

=item * L<R::NDArray::Float|SPVM::R::NDArray::Float>

=item * L<R::NDArray|SPVM::R::NDArray>

=item * L<R|SPVM::R>

=back

=head1 Copyright & License

Copyright (c) 2024 Yuki Kimoto

MIT License

