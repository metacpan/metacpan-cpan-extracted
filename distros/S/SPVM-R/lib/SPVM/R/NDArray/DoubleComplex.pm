package SPVM::R::OP::DoubleComplex;



1;

=head1 Name

SPVM::R::OP::DoubleComplex - N-Dimensional Array Operations for R::NDArray::DoubleComplex

=head1 Description

The R::OP::DoubleComplex class in L<SPVM> has methods for n-dimensional array operations for L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex>.

=head1 Usage

  use R::OP::DoubleComplex as DCOP;
  
  # 1+10i
  my $ndarray_scalar = DCOP->c([(double)1,10]);
  
  # 1+10i, 2+20i, 3 + 30i
  my $ndarray_vector = DCOP->c([(double)1,10,  2,20,  3,30]);
  
  my $ndarray = DCOP->c([(double)1,10,  2,20,  3,30,  4,40,  5,50,  6,60], [3, 2]);
  
  my $ndarray2 = DCOP->c($ndarray);

=head1 Class Methods

=head2 c

C<static method c : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex> ($data : object of float[]|Complex_2f[]|L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex>, $dim : int[] = undef);>

=head2 add

C<static method add : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex> ($x_ndarray : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex>, $y_ndarray : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex>);>

=head2 sub

C<static method sub : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex> ($x_ndarray : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex>, $y_ndarray : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex>);>

=head2 mul

C<static method mul : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex> ($x_ndarray : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex>, $y_ndarray : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex>);>

=head2 scamul

C<static method scamul : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex> ($scalar_ndarray : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex>, $x_ndarray : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex>);>

=head2 div

C<static method div : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex> ($x_ndarray : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex>, $y_ndarray : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex>);>

=head2 scadiv

C<static method scadiv : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex> ($scalar_ndarray : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex>, $x_ndarray : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex>);>

=head2 neg

C<static method neg : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex> ($x_ndarray : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex>);>

=head2 abs

C<static method abs : L<R::NDArray::Double|SPVM::R::NDArray::Double> ($x_ndarray : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex>);>

=head2 re

C<static method re : L<R::NDArray::Double|SPVM::R::NDArray::Double> ($x_ndarray : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex>);>

=head2 im

C<static method im : L<R::NDArray::Double|SPVM::R::NDArray::Double> ($x_ndarray : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex>);>

=head2 i

C<static method i : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex> ();>

=head2 conj

C<static method conj : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex> ($x_ndarray : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex>);>

=head2 arg

C<static method arg : L<R::NDArray::Double|SPVM::R::NDArray::Double> ($x_ndarray : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex>);>

=head2 eq

C<static method eq : L<R::NDArray::Int|SPVM::R::NDArray::Int> ($x_ndarray : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex>, $y_ndarray : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex>);>

=head2 ne

C<static method ne : L<R::NDArray::Int|SPVM::R::NDArray::Int> ($x_ndarray : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex>, $y_ndarray : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex>);>

=head2 rep

C<static method rep : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex> ($x_ndarray : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex>, $times : int);>

=head2 rep_length

C<static method rep_length : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex> ($x_ndarray : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex>, $length : int);>

=head2 sin

C<static method sin : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex> ($x_ndarray : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex>);>

=head2 cos

C<static method cos : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex> ($x_ndarray : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex>);>

=head2 tan

C<static method tan : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex> ($x_ndarray : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex>);>

=head2 sinh

C<static method sinh : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex> ($x_ndarray : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex>);>

=head2 cosh

C<static method cosh : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex> ($x_ndarray : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex>);>

=head2 tanh

C<static method tanh : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex> ($x_ndarray : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex>);>

=head2 acos

C<static method acos : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex> ($x_ndarray : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex>);>

=head2 asin

C<static method asin : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex> ($x_ndarray : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex>);>

=head2 atan

C<static method atan : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex> ($x_ndarray : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex>);>

=head2 asinh

C<static method asinh : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex> ($x_ndarray : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex>);>

=head2 acosh

C<static method acosh : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex> ($x_ndarray : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex>);>

=head2 atanh

C<static method atanh : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex> ($x_ndarray : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex>);>

=head2 exp

C<static method exp : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex> ($x_ndarray : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex>);>

=head2 log

C<static method log : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex> ($x_ndarray : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex>);>

=head2 sqrt

C<static method sqrt : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex> ($x_ndarray : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex>);>

=head2 pow

C<static method pow : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex> ($x_ndarray : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex>, $y_ndarray : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex>);>

=head2 sum

C<static method sum : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex> ($x_ndarray : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex>);>

=head2 cumsum

C<static method cumsum : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex> ($x_ndarray : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex>);>

=head2 prod

C<static method prod : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex> ($x_ndarray : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex>);>

=head2 cumprod

C<static method cumprod : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex> ($x_ndarray : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex>);>

=head2 diff

C<static method diff : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex> ($x_ndarray : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex>);>

=head2 mean

C<static method mean : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex> ($x_ndarray : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex>);>

=head2 inner

C<static method inner : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex> ($x_ndarray : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex>, $y_ndarray : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex>);>

=head2 cross

C<static method cross : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex> ($x_ndarray : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex>, $y_ndarray : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex>);>

=head2 outer

C<static method outer : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex> ($x_ndarray : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex>, $y_ndarray : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex>);>

=head1 See Also

=over 2

=item * L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex>

=item * L<R::NDArray|SPVM::R::NDArray>

=item * L<R|SPVM::R>

=back

=head1 Copyright & License

Copyright (c) 2024 Yuki Kimoto

MIT License

