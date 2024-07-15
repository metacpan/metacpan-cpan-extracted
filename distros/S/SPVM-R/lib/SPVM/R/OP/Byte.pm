package SPVM::R::OP::Byte;



1;

=head1 Name

SPVM::R::OP::Byte - N-Dimensional Array Operations for R::NDArray::Byte

=head1 Description

The R::OP::Byte class in L<SPVM> has methods for n-dimensional array operations for L<R::NDArray::Byte|SPVM::R::NDArray::Byte>.

=head1 Usage

  use R::OP::Byte as BOP;
  
  my $ndarray_scalar = BOP->c((byte)1);
  
  my $ndarray_vector = BOP->c([(byte)1, 2, 3]);
  
  my $ndarray = BOP->c([(byte)1, 2, 3, 4, 5, 6], [3, 2]);
  
  my $ndarray2 = BOP->c($ndarray);

=head1 Class Methods

=head2 c

C<static method c : L<R::NDArray::Byte|SPVM::R::NDArray::Byte> ($data : object of L<Byte|SPVM::Byte>|byte[]|L<R::NDArray::Byte|SPVM::R::NDArray::Byte>, $dim : int[] = undef);>

=head2 rep

C<static method rep : L<R::NDArray::Byte|SPVM::R::NDArray::Byte> ($x_ndarray : L<R::NDArray::Byte|SPVM::R::NDArray::Byte>, $times : int);>

=head2 rep_length

C<static method rep_length : L<R::NDArray::Byte|SPVM::R::NDArray::Byte> ($x_ndarray : L<R::NDArray::Byte|SPVM::R::NDArray::Byte>, $length : int);>

=head2 seq

C<static method seq : L<R::NDArray::Byte|SPVM::R::NDArray::Byte> ($begin : byte, $end : byte, $by : byte = 1);>

=head1 See Also

=over 2

=item * L<R::NDArray::Byte|SPVM::R::NDArray::Byte>

=item * L<R::NDArray|SPVM::R::NDArray>

=item * L<R|SPVM::R>

=back

=head1 Copyright & License

Copyright (c) 2024 Yuki Kimoto

MIT License

