package SPVM::R::OP::AnyObject;



1;

=head1 Name

SPVM::R::OP::AnyObject - N-Dimensional Array Operations for R::NDArray::AnyObject

=head1 Description

R::OP::AnyObject class in L<SPVM> has methods for n-dimensional array operations for L<R::NDArray::AnyObject|SPVM::R::NDArray::AnyObject>.

=head1 Usage

  use R::OP::AnyObject as AOP;
  
  my $ndarray_scalar = AOP->c((object)1);
  
  my $ndarray_vector = AOP->c([(object)1, 2, 3]);
  
  my $ndarray = AOP->c([(object)1, 2, 3, 4, 5, 6], [3, 2]);
  
  my $ndarray2 = AOP->c($ndarray);

=head1 Class Methods

=head2 c

C<static method c : L<R::NDArray::AnyObject|SPVM::R::NDArray::AnyObject> ($data : object of L<AnyObject|SPVM::AnyObject>|AnyObject[]|L<R::NDArray::AnyObject|SPVM::R::NDArray::AnyObject>, $dim : int[] = undef);>

Creates a new L<R::NDArray::AnyObject|SPVM::R::NDArray::AnyObject> object given the data $data and the dimensions $dim.

Implemetation:

If $data is defined and the type of $data is L<R::NDArray::AnyObject|SPVM::R::NDArray::AnyObject>, $dim is set to C<$data-E<gt>(R::NDArray::AnyObject)-E<gt>dim> unless $dim is defined and $data is set to C<$data-E<gt>(R::NDArray::AnyObject)-E<gt>data>.

And this method calls L<R::NDArray::AnyObject#new|SPVM::R::NDArray::AnyObject/"new"> method given $dim and $data.

Exceptions:

The type of the data $data must be AnyObject, AnyObject[], or R::NDArray::AnyObject if defined. Othrewise, an exception is thrown.

=head1 See Also

=over 2

=item * L<R::OP|SPVM::R::OP>

=item * L<R::NDArray::AnyObject|SPVM::R::NDArray::AnyObject>

=item * L<R::NDArray|SPVM::R::NDArray>

=item * L<R|SPVM::R>

=back

=head1 Copyright & License

Copyright (c) 2024 Yuki Kimoto

MIT License

