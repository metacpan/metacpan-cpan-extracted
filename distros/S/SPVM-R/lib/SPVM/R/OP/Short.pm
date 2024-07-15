package SPVM::R::OP::Short;



1;

=head1 Name

SPVM::R::OP::Short - N-Dimensional Array Operations for R::NDArray::Short

=head1 Description

The R::OP::Short class in L<SPVM> has methods for n-dimensional array operations for L<R::NDArray::Short|SPVM::R::NDArray::Short>.

=head1 Usage

  use R::OP::Short as SOP;
  
  my $ndarray_scalar = SOP->c((short)1);
  
  my $ndarray_vector = SOP->c([(short)1, 2, 3]);
  
  my $ndarray = SOP->c([(short)1, 2, 3, 4, 5, 6], [3, 2]);
  
  my $ndarray2 = SOP->c($ndarray);

=head1 Class Methods

=head2 c

C<static method c : L<R::NDArray::Short|SPVM::R::NDArray::Short> ($data : object of L<Short|SPVM::Short>|short[]|L<R::NDArray::Short|SPVM::R::NDArray::Short>, $dim : int[] = undef);>

=head2 rep

C<static method rep : L<R::NDArray::Short|SPVM::R::NDArray::Short> ($x_ndarray : L<R::NDArray::Short|SPVM::R::NDArray::Short>, $times : int);>

=head2 rep_length

C<static method rep_length : L<R::NDArray::Short|SPVM::R::NDArray::Short> ($x_ndarray : L<R::NDArray::Short|SPVM::R::NDArray::Short>, $length : int);>

=head2 seq

C<static method seq : L<R::NDArray::Short|SPVM::R::NDArray::Short> ($begin : short, $end : short, $by : short = 1);>

=head1 See Also

=over 2

=item * L<R::NDArray::Short|SPVM::R::NDArray::Short>

=item * L<R::NDArray|SPVM::R::NDArray>

=item * L<R|SPVM::R>

=back

=head1 Copyright & License

Copyright (c) 2024 Yuki Kimoto

MIT License

