package SPVM::R::OP::Long;



1;

=head1 Name

SPVM::R::OP::Long - N-Dimensional Array Operations for R::NDArray::Long

=head1 Description

The R::OP::Long class in L<SPVM> has methods for n-dimensional array operations for L<R::NDArray::Long|SPVM::R::NDArray::Long>.

=head1 Usage

  use R::OP::Long as LOP;
  
  my $ndarray_scalar = LOP->c((int)1);
  
  my $ndarray_vector = LOP->c([(int)1, 2, 3]);
  
  my $ndarray = LOP->c([(int)1, 2, 3, 4, 5, 6], [3, 2]);
  
  my $ndarray2 = LOP->c($ndarray);

=head1 Class Methods

=head2 c

C<static method c : L<R::NDArray::Long|SPVM::R::NDArray::Long> ($data : object of L<Long|SPVM::Long>|int[]|L<R::NDArray::Long|SPVM::R::NDArray::Long>, $dim : int[] = undef);>

=head2 add

C<static method add : L<R::NDArray::Long|SPVM::R::NDArray::Long> ($x_ndarray : L<R::NDArray::Long|SPVM::R::NDArray::Long>, $y_ndarray : L<R::NDArray::Long|SPVM::R::NDArray::Long>);>

=head2 sub

C<static method sub : L<R::NDArray::Long|SPVM::R::NDArray::Long> ($x_ndarray : L<R::NDArray::Long|SPVM::R::NDArray::Long>, $y_ndarray : L<R::NDArray::Long|SPVM::R::NDArray::Long>);>

=head2 mul

C<static method mul : L<R::NDArray::Long|SPVM::R::NDArray::Long> ($x_ndarray : L<R::NDArray::Long|SPVM::R::NDArray::Long>, $y_ndarray : L<R::NDArray::Long|SPVM::R::NDArray::Long>);>

=head2 scamul

C<static method scamul : R::NDArray::Int ($x_ndarray : L<R::NDArray::Long|SPVM::R::NDArray::Long>, $scalar_ndarray : L<R::NDArray::Long|SPVM::R::NDArray::Long>);>

=head2 div

C<static method div : L<R::NDArray::Long|SPVM::R::NDArray::Long> ($x_ndarray : L<R::NDArray::Long|SPVM::R::NDArray::Long>, $y_ndarray : L<R::NDArray::Long|SPVM::R::NDArray::Long>);>

=head2 scadiv

C<static method scadiv : R::NDArray::Int ($x_ndarray : L<R::NDArray::Long|SPVM::R::NDArray::Long>, $scalar_ndarray : L<R::NDArray::Long|SPVM::R::NDArray::Long>);>

=head2 div_u

C<static method div_u : L<R::NDArray::Long|SPVM::R::NDArray::Long> ($x_ndarray : L<R::NDArray::Long|SPVM::R::NDArray::Long>, $y_ndarray : L<R::NDArray::Long|SPVM::R::NDArray::Long>);>

=head2 mod

C<static method mod : L<R::NDArray::Long|SPVM::R::NDArray::Long> ($x_ndarray : L<R::NDArray::Long|SPVM::R::NDArray::Long>, $y_ndarray : L<R::NDArray::Long|SPVM::R::NDArray::Long>);>

=head2 mod_u

C<static method mod_u : L<R::NDArray::Long|SPVM::R::NDArray::Long> ($x_ndarray : L<R::NDArray::Long|SPVM::R::NDArray::Long>, $y_ndarray : L<R::NDArray::Long|SPVM::R::NDArray::Long>);>

=head2 neg

C<static method neg : L<R::NDArray::Long|SPVM::R::NDArray::Long> ($x_ndarray : L<R::NDArray::Long|SPVM::R::NDArray::Long>);>

=head2 abs

C<static method abs : L<R::NDArray::Long|SPVM::R::NDArray::Long> ($x_ndarray : L<R::NDArray::Long|SPVM::R::NDArray::Long>);>

=head2 rep

C<static method rep : L<R::NDArray::Long|SPVM::R::NDArray::Long> ($x_ndarray : L<R::NDArray::Long|SPVM::R::NDArray::Long>, $times : int);>

=head2 rep_length

C<static method rep_length : L<R::NDArray::Long|SPVM::R::NDArray::Long> ($x_ndarray : L<R::NDArray::Long|SPVM::R::NDArray::Long>, $length : int);>

=head2 seq

C<static method seq : L<R::NDArray::Long|SPVM::R::NDArray::Long> ($begin : long, $end : long, $by : long = 1);>

=head2 eq

C<static method eq : L<R::NDArray::Long|SPVM::R::NDArray::Long> ($x_ndarray : L<R::NDArray::Long|SPVM::R::NDArray::Long>, $y_ndarray : L<R::NDArray::Long|SPVM::R::NDArray::Long>);>

=head2 ne

C<static method ne : L<R::NDArray::Long|SPVM::R::NDArray::Long> ($x_ndarray : L<R::NDArray::Long|SPVM::R::NDArray::Long>, $y_ndarray : L<R::NDArray::Long|SPVM::R::NDArray::Long>);>

=head2 gt

C<static method gt : L<R::NDArray::Long|SPVM::R::NDArray::Long> ($x_ndarray : L<R::NDArray::Long|SPVM::R::NDArray::Long>, $y_ndarray : L<R::NDArray::Long|SPVM::R::NDArray::Long>);>

=head2 ge

C<static method ge : L<R::NDArray::Long|SPVM::R::NDArray::Long> ($x_ndarray : L<R::NDArray::Long|SPVM::R::NDArray::Long>, $y_ndarray : L<R::NDArray::Long|SPVM::R::NDArray::Long>);>

=head2 lt

C<static method lt : L<R::NDArray::Long|SPVM::R::NDArray::Long> ($x_ndarray : L<R::NDArray::Long|SPVM::R::NDArray::Long>, $y_ndarray : L<R::NDArray::Long|SPVM::R::NDArray::Long>);>

=head2 le

C<static method le : L<R::NDArray::Long|SPVM::R::NDArray::Long> ($x_ndarray : L<R::NDArray::Long|SPVM::R::NDArray::Long>, $y_ndarray : L<R::NDArray::Long|SPVM::R::NDArray::Long>);>

=head2 sum

C<static method sum : L<R::NDArray::Long|SPVM::R::NDArray::Long> ($x_ndarray : L<R::NDArray::Long|SPVM::R::NDArray::Long>);>

=head2 cumsum

C<static method cumsum : L<R::NDArray::Long|SPVM::R::NDArray::Long> ($x_ndarray : L<R::NDArray::Long|SPVM::R::NDArray::Long>);>

=head2 prod

C<static method prod : L<R::NDArray::Long|SPVM::R::NDArray::Long> ($x_ndarray : L<R::NDArray::Long|SPVM::R::NDArray::Long>);>

=head2 cumprod

C<static method cumprod : L<R::NDArray::Long|SPVM::R::NDArray::Long> ($x_ndarray : L<R::NDArray::Long|SPVM::R::NDArray::Long>);>

=head2 diff

C<static method diff : R::NDArray::Long ($x_ndarray : L<R::NDArray::Long|SPVM::R::NDArray::Long>);>

=head2 max

C<static method max : R::NDArray::Long ($x_ndarray : L<R::NDArray::Long|SPVM::R::NDArray::Long>);>

=head2 min

C<static method min : R::NDArray::Long ($x_ndarray : L<R::NDArray::Long|SPVM::R::NDArray::Long>);>

=head1 See Also

=over 2

=item * L<R::NDArray::Long|SPVM::R::NDArray::Long>

=item * L<R::NDArray|SPVM::R::NDArray>

=item * L<R|SPVM::R>

=back

=head1 Copyright & License

Copyright (c) 2024 Yuki Kimoto

MIT License

