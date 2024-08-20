package SPVM::R::NDArray::Hash;



1;

=head1 Name

SPVM::R::NDArray::Hash - Hash of N-Dimensional Array.

=head1 Description

R::NDArray::Hash class in L<SPVM> represents a data structure to store n-dimensional arrays in hash.

=head1 Usage

  use R::NDArray::Hash;
  use R::OP::Int as IOP;
  
  my $ndarray = R::NDArray::Hash->new;
  
  $ndarray->set("name", IOP->c([1, 2, 3]));
  
  my $ndarray = $ndarray->get("name");
  
  my $ndarray_int = $ndarray->get_int("name");

=head1 Field

=head2 ndarrays_h

C<has ndarrays_h : L<Hash|SPVM::Hash> of L<R::NDArray|SPVM::R::NDArray>;>

A L<Hash|SPVM::Hash> object to store n-dimensional arrays.

=head1 Class Methods

=head2 new

C<static method new : L<R::NDArray::Hash|SPVM::R::NDArray::Hash> ();>

Creates a new L<R::NDArray::Hash|SPVM::R::NDArray::Hash> object.

=head2 set

C<method set : void ($name : string, $value : L<R::NDArray|SPVM::R::NDArray>);>

Sets the value of key $name to $value.

=head2 get

C<method get : L<R::NDArray|SPVM::R::NDArray> ($name : string);>

Returns the value of key $name.

Exceptions:

If $name is not found, an exception is thrown.

=head2 get_byte

C<method get_byte : L<R::NDArray::Byte|SPVM::R::NDArray::Byte> ($name : string);>

Same as L</"get"> method, but the return type is different.

=head2 get_short

C<method get_short : L<R::NDArray::Short|SPVM::R::NDArray::Short> ($name : string);>

Same as L</"get"> method, but the return type is different.

=head2 get_int

C<method get_int : L<R::NDArray::Int|SPVM::R::NDArray::Int> ($name : string);>

Same as L</"get"> method, but the return type is different.

=head2 get_long

C<method get_long : L<R::NDArray::Long|SPVM::R::NDArray::Long> ($name : string);>

Same as L</"get"> method, but the return type is different.

=head2 get_float

C<method get_float : L<R::NDArray::Float|SPVM::R::NDArray::Float> ($name : string);>

Same as L</"get"> method, but the return type is different.

=head2 get_float_complex

C<method get_float_complex : L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex> ($name : string);>

Same as L</"get"> method, but the return type is different.

=head2 get_double

C<method get_double : L<R::NDArray::Double|SPVM::R::NDArray::Double> ($name : string);>

Same as L</"get"> method, but the return type is different.

=head2 get_double_complex

C<method get_double_complex : L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex> ($name : string);>

Same as L</"get"> method, but the return type is different.

=head2 get_string

C<method get_string : L<R::NDArray::String|SPVM::R::NDArray::String> ($name : string);>

Same as L</"get"> method, but the return type is different.

=head1 See Also

=over 2

=item * L<R::NDArray|SPVM::R::NDArray>

=item * L<R|SPVM::R>

=back

=head1 Copyright & License

Copyright (c) 2024 Yuki Kimoto

MIT License

