package SPVM::R::OP::Byte;



1;

=head1 Name

SPVM::R::OP::Byte - N-Dimensional Array Operations for R::NDArray::Byte

=head1 Description

R::OP::Byte class in L<SPVM> has methods for n-dimensional array operations for L<R::NDArray::Byte|SPVM::R::NDArray::Byte>.

=head1 Usage

  use R::OP::Byte as BOP;
  
  my $ndarray_scalar = BOP->c((byte)1);
  
  my $ndarray_vector = BOP->c([(byte)1, 2, 3]);
  
  my $ndarray = BOP->c([(byte)1, 2, 3, 4, 5, 6], [3, 2]);
  
  my $ndarray2 = BOP->c($ndarray);

=head1 Class Methods

=head2 c

C<static method c : L<R::NDArray::Byte|SPVM::R::NDArray::Byte> ($data : object of L<Byte|SPVM::Byte>|byte[]|L<R::NDArray::Byte|SPVM::R::NDArray::Byte>, $dim : int[] = undef);>

Creates a new L<R::NDArray::Byte|SPVM::R::NDArray::Byte> object given the data $data and the dimensions $dim.

Implemetation:

If $data is defined and the type of $data is L<Byte|SPVM::Byte>, $data is set to C<[(byte)$data->(Byte)]>.

If $data is defined and the type of $data is L<R::NDArray::Byte|SPVM::R::NDArray::Byte>, $dim is set to C<$data-E<gt>(R::NDArray::Byte)-E<gt>dim> unless $dim is defined and $data is set to C<$data-E<gt>(R::NDArray::Byte)-E<gt>data>.

And this method calls L<R::NDArray::Byte#new|SPVM::R::NDArray::Byte/"new"> method given $dim and $data.

Exceptions:

The type of the data $data must be Byte, byte[], or R::NDArray::Byte if defined. Othrewise, an exception is thrown.

=head2 rep

C<static method rep : L<R::NDArray::Byte|SPVM::R::NDArray::Byte> ($x_ndarray : L<R::NDArray::Byte|SPVM::R::NDArray::Byte>, $times : int);>

Same as L<R::OP#rep|SPVM::R::OP/"rep"> method, but the return type is different.

=head2 rep_length

C<static method rep_length : L<R::NDArray::Byte|SPVM::R::NDArray::Byte> ($x_ndarray : L<R::NDArray::Byte|SPVM::R::NDArray::Byte>, $length : int);>

Same as L<R::OP#rep_length|SPVM::R::OP/"rep_length"> method, but the return type is different.

=head2 seq

C<static method seq : L<R::NDArray::Byte|SPVM::R::NDArray::Byte> ($begin : byte, $end : byte, $by : byte = 1);>

Creates a L<R::NDArray::Byte|SPVM::R::NDArray::Byte> object from $bigin to $end at intervals of $by.

Exceptions:

$by must not be 0. Otherwise, an exception is thrown.

If $by is greater than 0 and $end is not greater than or equal to $begin, an exception is thrown.

If $by is less than 0 and $end Is not greater than or equal to $begin, an exception is thrown.

=head1 See Also

=over 2

=item * L<R::OP|SPVM::R::OP>

=item * L<R::NDArray::Byte|SPVM::R::NDArray::Byte>

=item * L<R::NDArray|SPVM::R::NDArray>

=item * L<R|SPVM::R>

=back

=head1 Copyright & License

Copyright (c) 2024 Yuki Kimoto

MIT License

