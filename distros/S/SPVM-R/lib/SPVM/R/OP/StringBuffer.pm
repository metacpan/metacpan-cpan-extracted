package SPVM::R::OP::StringBuffer;



1;

=head1 Name

SPVM::R::OP::StringBuffer - N-Dimensional Array Operations for R::NDArray::StringBuffer

=head1 Description

The R::OP::StringBuffer class in L<SPVM> has methods for n-dimensional array operations for L<R::NDArray::StringBuffer|SPVM::R::NDArray::StringBuffer>.

=head1 Usage

  use R::OP::StringBuffer as BUFOP;
  
  my $data = [
    StringBuffer->new("a"),
    StringBuffer->new("b"),
    StringBuffer->new("c"),
    StringBuffer->new("d"),
    StringBuffer->new("e"),
    StringBuffer->new("f")
  ];
  
  my $ndarray_scalar = BUFOP->c(StringBuffer->new("a"));
  
  my $ndarray_vector = BUFOP->c($data);
  
  my $ndarray = BUFOP->c($data, [3, 2]);
  
  my $ndarray2 = BUFOP->c($ndarray);

=head1 Class Methods

=head2 c

C<static method c : L<R::NDArray::StringBuffer|SPVM::R::NDArray::StringBuffer> ($data : object of StringBuffer|StringBuffer[]|L<R::NDArray::StringBuffer|SPVM::R::NDArray::StringBuffer>, $dim : int[] = undef);>

=head2 push

C<static method push : void ($x_ndarray : L<R::NDArray::StringBuffer|SPVM::R::NDArray::StringBuffer>, $y_ndarray : L<R::NDArray::String|SPVM::R::NDArray::String>);>

=head2 eq

C<static method eq : L<R::NDArray::Int|SPVM::R::NDArray::Int> ($x_ndarray : L<R::NDArray::StringBuffer|SPVM::R::NDArray::StringBuffer>, $y_ndarray : L<R::NDArray::StringBuffer|SPVM::R::NDArray::StringBuffer>);>

=head2 ne

C<static method ne : L<R::NDArray::Int|SPVM::R::NDArray::Int> ($x_ndarray : L<R::NDArray::StringBuffer|SPVM::R::NDArray::StringBuffer>, $y_ndarray : L<R::NDArray::StringBuffer|SPVM::R::NDArray::StringBuffer>);>

=head2 gt

C<static method gt : L<R::NDArray::Int|SPVM::R::NDArray::Int> ($x_ndarray : L<R::NDArray::StringBuffer|SPVM::R::NDArray::StringBuffer>, $y_ndarray : L<R::NDArray::StringBuffer|SPVM::R::NDArray::StringBuffer>);>

=head2 ge

C<static method ge : L<R::NDArray::Int|SPVM::R::NDArray::Int> ($x_ndarray : L<R::NDArray::StringBuffer|SPVM::R::NDArray::StringBuffer>, $y_ndarray : L<R::NDArray::StringBuffer|SPVM::R::NDArray::StringBuffer>);>

=head2 lt

C<static method lt : L<R::NDArray::Int|SPVM::R::NDArray::Int> ($x_ndarray : L<R::NDArray::StringBuffer|SPVM::R::NDArray::StringBuffer>, $y_ndarray : L<R::NDArray::StringBuffer|SPVM::R::NDArray::StringBuffer>);>

=head2 le

C<static method le : L<R::NDArray::Int|SPVM::R::NDArray::Int> ($x_ndarray : L<R::NDArray::StringBuffer|SPVM::R::NDArray::StringBuffer>, $y_ndarray : L<R::NDArray::StringBuffer|SPVM::R::NDArray::StringBuffer>);>

=head2 rep

C<static method rep : L<R::NDArray::StringBuffer|SPVM::R::NDArray::StringBuffer> ($x_ndarray : L<R::NDArray::StringBuffer|SPVM::R::NDArray::StringBuffer>, $times : int);>

=head2 rep_length

C<static method rep_length : L<R::NDArray::StringBuffer|SPVM::R::NDArray::StringBuffer> ($x_ndarray : L<R::NDArray::StringBuffer|SPVM::R::NDArray::StringBuffer>, $length : int);>

=head1 See Also

=over 2

=item * L<R::NDArray::StringBufferBuffer|SPVM::R::NDArray::StringBufferBuffer>

=item * L<R::NDArray|SPVM::R::NDArray>

=item * L<R|SPVM::R>

=back

=head1 Copyright & License

Copyright (c) 2024 Yuki Kimoto

MIT License

