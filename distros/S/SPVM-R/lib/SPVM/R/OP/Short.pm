package SPVM::R::OP::Short;



1;

=head1 Name

SPVM::R::OP::Short - N-Dimensional Array Operations for R::NDArray::Short

=head1 Description

R::OP::Short class in L<SPVM> has methods for n-dimensional array operations for L<R::NDArray::Short|SPVM::R::NDArray::Short>.

=head1 Usage

  use R::OP::Short as SOP;
  
  my $ndarray_scalar = SOP->c((short)1);
  
  my $ndarray_vector = SOP->c([(short)1, 2, 3]);
  
  my $ndarray = SOP->c([(short)1, 2, 3, 4, 5, 6], [3, 2]);
  
  my $ndarray2 = SOP->c($ndarray);

=head1 Class Methods

=head2 c

C<static method c : L<R::NDArray::Short|SPVM::R::NDArray::Short> ($data : object of L<Short|SPVM::Short>|short[]|L<R::NDArray::Short|SPVM::R::NDArray::Short>, $dim : int[] = undef);>

Creates a new L<R::NDArray::Short|SPVM::R::NDArray::Short> object given the data $data and the dimensions $dim.

Implemetation:

If $data is defined and the type of $data is L<Short|SPVM::Short>, $data is set to C<[(short)$data->(Short)]>.

If $data is defined and the type of $data is L<R::NDArray::Short|SPVM::R::NDArray::Short>, $dim is set to C<$data-E<gt>(R::NDArray::Short)-E<gt>dim> unless $dim is defined and $data is set to C<$data-E<gt>(R::NDArray::Short)-E<gt>data>.

And this method calls L<R::NDArray::Short#new|SPVM::R::NDArray::Short/"new"> method given $dim and $data.

Exceptions:

The type of the data $data must be Short, short[], or R::NDArray::Short if defined. Othrewise, an exception is thrown.

=head2 rep

C<static method rep : L<R::NDArray::Short|SPVM::R::NDArray::Short> ($x_ndarray : L<R::NDArray::Short|SPVM::R::NDArray::Short>, $times : int);>

Same as L<R::OP#rep|SPVM::R::OP/"rep"> method, but the return type is different.

=head2 rep_length

C<static method rep_length : L<R::NDArray::Short|SPVM::R::NDArray::Short> ($x_ndarray : L<R::NDArray::Short|SPVM::R::NDArray::Short>, $length : int);>

Same as L<R::OP#rep_length|SPVM::R::OP/"rep_length"> method, but the return type is different.

=head2 seq

C<static method seq : L<R::NDArray::Short|SPVM::R::NDArray::Short> ($begin : short, $end : short, $by : short = 1);>

Creates a L<R::NDArray::Short|SPVM::R::NDArray::Short> object from $bigin to $end at intervals of $by.

Exceptions:

$by must not be 0. Otherwise, an exception is thrown.

If $by is greater than 0 and $end is not greater than or equal to $begin, an exception is thrown.

If $by is less than 0 and $end Is not greater than or equal to $begin, an exception is thrown.

=head1 See Also

=over 2

=item * L<R::OP|SPVM::R::OP>

=item * L<R::NDArray::Short|SPVM::R::NDArray::Short>

=item * L<R::NDArray|SPVM::R::NDArray>

=item * L<R|SPVM::R>

=back

=head1 Copyright & License

Copyright (c) 2024 Yuki Kimoto

MIT License

