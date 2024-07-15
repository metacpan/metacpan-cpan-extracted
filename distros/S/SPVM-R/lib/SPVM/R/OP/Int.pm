package SPVM::R::OP::Int;



1;

=head1 Name

SPVM::R::OP::Int - N-Dimensional Array Operations for R::NDArray::Int

=head1 Description

The R::OP::Int class in L<SPVM> has methods for n-dimensional array operations for L<R::NDArray::Int|SPVM::R::NDArray::Int>.

=head1 Usage

  use R::OP::Int as IOP;
  
  my $ndarray_scalar = IOP->c((int)1);
  
  my $ndarray_vector = IOP->c([(int)1, 2, 3]);
  
  my $ndarray = IOP->c([(int)1, 2, 3, 4, 5, 6], [3, 2]);
  
  my $ndarray2 = IOP->c($ndarray);

=head1 Class Methods

=head2 c

C<static method c : L<R::NDArray::Int|SPVM::R::NDArray::Int> ($data : object of L<Int|SPVM::Int>|int[]|L<R::NDArray::Int|SPVM::R::NDArray::Int>, $dim : int[] = undef);>

=head2 add

C<static method add : L<R::NDArray::Int|SPVM::R::NDArray::Int> ($x_ndarray : L<R::NDArray::Int|SPVM::R::NDArray::Int>, $y_ndarray : L<R::NDArray::Int|SPVM::R::NDArray::Int>);>

=head2 sub

C<static method sub : L<R::NDArray::Int|SPVM::R::NDArray::Int> ($x_ndarray : L<R::NDArray::Int|SPVM::R::NDArray::Int>, $y_ndarray : L<R::NDArray::Int|SPVM::R::NDArray::Int>);>

=head2 mul

C<static method mul : L<R::NDArray::Int|SPVM::R::NDArray::Int> ($x_ndarray : L<R::NDArray::Int|SPVM::R::NDArray::Int>, $y_ndarray : L<R::NDArray::Int|SPVM::R::NDArray::Int>);>

=head2 scamul

C<static method scamul : R::NDArray::Int ($scalar_ndarray : L<R::NDArray::Int|SPVM::R::NDArray::Int>, $x_ndarray : L<R::NDArray::Int|SPVM::R::NDArray::Int>);>

=head2 div

C<static method div : L<R::NDArray::Int|SPVM::R::NDArray::Int> ($x_ndarray : L<R::NDArray::Int|SPVM::R::NDArray::Int>, $y_ndarray : L<R::NDArray::Int|SPVM::R::NDArray::Int>);>

=head2 scadiv

C<static method scadiv : R::NDArray::Int ($scalar_ndarray : L<R::NDArray::Int|SPVM::R::NDArray::Int>, $x_ndarray : L<R::NDArray::Int|SPVM::R::NDArray::Int>);>

=head2 div_u

C<static method div_u : L<R::NDArray::Int|SPVM::R::NDArray::Int> ($x_ndarray : L<R::NDArray::Int|SPVM::R::NDArray::Int>, $y_ndarray : L<R::NDArray::Int|SPVM::R::NDArray::Int>);>

=head2 mod

C<static method mod : L<R::NDArray::Int|SPVM::R::NDArray::Int> ($x_ndarray : L<R::NDArray::Int|SPVM::R::NDArray::Int>, $y_ndarray : L<R::NDArray::Int|SPVM::R::NDArray::Int>);>

=head2 mod_u

C<static method mod_u : L<R::NDArray::Int|SPVM::R::NDArray::Int> ($x_ndarray : L<R::NDArray::Int|SPVM::R::NDArray::Int>, $y_ndarray : L<R::NDArray::Int|SPVM::R::NDArray::Int>);>

=head2 neg

C<static method neg : L<R::NDArray::Int|SPVM::R::NDArray::Int> ($x_ndarray : L<R::NDArray::Int|SPVM::R::NDArray::Int>);>

=head2 abs

C<static method abs : L<R::NDArray::Int|SPVM::R::NDArray::Int> ($x_ndarray : L<R::NDArray::Int|SPVM::R::NDArray::Int>);>

=head2 eq

C<static method eq : L<R::NDArray::Int|SPVM::R::NDArray::Int> ($x_ndarray : L<R::NDArray::Int|SPVM::R::NDArray::Int>, $y_ndarray : L<R::NDArray::Int|SPVM::R::NDArray::Int>);>

=head2 ne

C<static method ne : L<R::NDArray::Int|SPVM::R::NDArray::Int> ($x_ndarray : L<R::NDArray::Int|SPVM::R::NDArray::Int>, $y_ndarray : L<R::NDArray::Int|SPVM::R::NDArray::Int>);>

=head2 gt

C<static method gt : L<R::NDArray::Int|SPVM::R::NDArray::Int> ($x_ndarray : L<R::NDArray::Int|SPVM::R::NDArray::Int>, $y_ndarray : L<R::NDArray::Int|SPVM::R::NDArray::Int>);>

=head2 ge

C<static method ge : L<R::NDArray::Int|SPVM::R::NDArray::Int> ($x_ndarray : L<R::NDArray::Int|SPVM::R::NDArray::Int>, $y_ndarray : L<R::NDArray::Int|SPVM::R::NDArray::Int>);>

=head2 lt

C<static method lt : L<R::NDArray::Int|SPVM::R::NDArray::Int> ($x_ndarray : L<R::NDArray::Int|SPVM::R::NDArray::Int>, $y_ndarray : L<R::NDArray::Int|SPVM::R::NDArray::Int>);>

=head2 le

C<static method le : L<R::NDArray::Int|SPVM::R::NDArray::Int> ($x_ndarray : L<R::NDArray::Int|SPVM::R::NDArray::Int>, $y_ndarray : L<R::NDArray::Int|SPVM::R::NDArray::Int>);>

=head2 rep

C<static method rep : L<R::NDArray::Int|SPVM::R::NDArray::Int> ($x_ndarray : L<R::NDArray::Int|SPVM::R::NDArray::Int>, $times : int);>

=head2 rep_length

C<static method rep_length : L<R::NDArray::Int|SPVM::R::NDArray::Int> ($x_ndarray : L<R::NDArray::Int|SPVM::R::NDArray::Int>, $length : int);>

=head2 seq

C<static method seq : L<R::NDArray::Int|SPVM::R::NDArray::Int> ($begin : int, $end : int, $by : int = 1);>

=head2 undef

C<static method undef : L<R::NDArray::Int|SPVM::R::NDArray::Int> ();>

=head2 sum

C<static method sum : L<R::NDArray::Int|SPVM::R::NDArray::Int> ($x_ndarray : L<R::NDArray::Int|SPVM::R::NDArray::Int>);>

=head2 cumsum

C<static method cumsum : L<R::NDArray::Int|SPVM::R::NDArray::Int> ($x_ndarray : L<R::NDArray::Int|SPVM::R::NDArray::Int>);>

=head2 prod

C<static method prod : L<R::NDArray::Int|SPVM::R::NDArray::Int> ($x_ndarray : L<R::NDArray::Int|SPVM::R::NDArray::Int>);>

=head2 cumprod

C<static method cumprod : L<R::NDArray::Int|SPVM::R::NDArray::Int> ($x_ndarray : L<R::NDArray::Int|SPVM::R::NDArray::Int>);>

=head2 diff

C<static method diff : L<R::NDArray::Int|SPVM::R::NDArray::Int> ($x_ndarray : L<R::NDArray::Int|SPVM::R::NDArray::Int>);>

=head2 max

C<static method max : L<R::NDArray::Int|SPVM::R::NDArray::Int> ($x_ndarray : L<R::NDArray::Int|SPVM::R::NDArray::Int>);>

=head2 min

C<static method min : L<R::NDArray::Int|SPVM::R::NDArray::Int> ($x_ndarray : L<R::NDArray::Int|SPVM::R::NDArray::Int>);>

=head2 and

C<static method and : L<R::NDArray::Int|SPVM::R::NDArray::Int> ($x_ndarray : L<R::NDArray::Int|SPVM::R::NDArray::Int>, $y_ndarray : L<R::NDArray::Int|SPVM::R::NDArray::Int>);>

=head2 or

C<static method or : L<R::NDArray::Int|SPVM::R::NDArray::Int> ($x_ndarray : L<R::NDArray::Int|SPVM::R::NDArray::Int>, $y_ndarray : L<R::NDArray::Int|SPVM::R::NDArray::Int>);>

=head2 not

C<static method not : L<R::NDArray::Int|SPVM::R::NDArray::Int> ($x_ndarray : L<R::NDArray::Int|SPVM::R::NDArray::Int>);>

=head1 See Also

=over 2

=item * L<R::NDArray::Int|SPVM::R::NDArray::Int>

=item * L<R::NDArray|SPVM::R::NDArray>

=item * L<R|SPVM::R>

=back

=head1 Copyright & License

Copyright (c) 2024 Yuki Kimoto

MIT License

