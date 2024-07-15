package SPVM::R::OP::String;



1;

=head1 Name

SPVM::R::OP::String - N-Dimensional Array Operations for R::NDArray::String

=head1 Description

The R::OP::String class in L<SPVM> has methods for n-dimensional array operations for L<R::NDArray::String|SPVM::R::NDArray::String>.

=head1 Usage

  use R::OP::String as STROP;
  
  my $ndarray_scalar = STROP->c((string)1);
  
  my $ndarray_vector = STROP->c([(string)"a", "b", "c"]);
  
  my $ndarray = STROP->c([(string)"a", "b", "c", "d", "e", "f"], [3, 2]);
  
  my $ndarray2 = STROP->c($ndarray);

=head1 Class Methods

=head2 c

C<static method c : L<R::NDArray::String|SPVM::R::NDArray::String> ($data : object of string|string[]|L<R::NDArray::String|SPVM::R::NDArray::String>, $dim : int[] = undef);>

=head2 concat

C<static method concat : L<R::NDArray::String|SPVM::R::NDArray::String> ($x_ndarray : L<R::NDArray::String|SPVM::R::NDArray::String>, $y_ndarray : L<R::NDArray::String|SPVM::R::NDArray::String>);>

=head2 eq

C<static method eq : L<R::NDArray::Int|SPVM::R::NDArray::Int> ($x_ndarray : L<R::NDArray::String|SPVM::R::NDArray::String>, $y_ndarray : L<R::NDArray::String|SPVM::R::NDArray::String>);>

=head2 ne

C<static method ne : L<R::NDArray::Int|SPVM::R::NDArray::Int> ($x_ndarray : L<R::NDArray::String|SPVM::R::NDArray::String>, $y_ndarray : L<R::NDArray::String|SPVM::R::NDArray::String>);>

=head2 gt

C<static method gt : L<R::NDArray::Int|SPVM::R::NDArray::Int> ($x_ndarray : L<R::NDArray::String|SPVM::R::NDArray::String>, $y_ndarray : L<R::NDArray::String|SPVM::R::NDArray::String>);>

=head2 ge

C<static method ge : L<R::NDArray::Int|SPVM::R::NDArray::Int> ($x_ndarray : L<R::NDArray::String|SPVM::R::NDArray::String>, $y_ndarray : L<R::NDArray::String|SPVM::R::NDArray::String>);>

=head2 lt

C<static method lt : L<R::NDArray::Int|SPVM::R::NDArray::Int> ($x_ndarray : L<R::NDArray::String|SPVM::R::NDArray::String>, $y_ndarray : L<R::NDArray::String|SPVM::R::NDArray::String>);>

=head2 le

C<static method le : L<R::NDArray::Int|SPVM::R::NDArray::Int> ($x_ndarray : L<R::NDArray::String|SPVM::R::NDArray::String>, $y_ndarray : L<R::NDArray::String|SPVM::R::NDArray::String>);>

=head2 rep

C<static method rep : L<R::NDArray::String|SPVM::R::NDArray::String> ($x_ndarray : L<R::NDArray::String|SPVM::R::NDArray::String>, $times : int);>

=head2 rep_length

C<static method rep_length : L<R::NDArray::String|SPVM::R::NDArray::String> ($x_ndarray : L<R::NDArray::String|SPVM::R::NDArray::String>, $length : int);>

=head1 See Also

=over 2

=item * L<R::NDArray::String|SPVM::R::NDArray::String>

=item * L<R::NDArray|SPVM::R::NDArray>

=item * L<R|SPVM::R>

=back

=head1 Copyright & License

Copyright (c) 2024 Yuki Kimoto

MIT License

