package SPVM::R::NDArray;



1;

=head1 Name

SPVM::R::NDArray - N-Dimensional Array Base Class

=head1 Description

The R::NDArray class in L<SPVM> represetns n-dimensional array and it is the base class of classes that represents typed n-dimensional arrays.

=head1 Usage

  use R::NDArray;

=head1 Details

R::NDArray is column major.

=head1 Fields

=head2 data

C<has data : protected ro object;>

An array of numeric type, multi-numeric type, or object type.

=head2 dim

C<has dim : int[];>

Dimensions.

C<method dim : int[] ();>

Creates a new array, copies the elements of this field, and returns the array.

C<method set_dim : void ($dim : int[]);>

The dimensions $dim is normalized by L<R::Util#normalize_dim|SPVM::R::Util/"normalize_dim"> method, checks the normalized dim by L<R::Util#check_length|SPVM::R::Util/"check_length"> method, and sets this field to the normalized dim.

Exceptions:

C<set_dim> Method:

If L</"is_dim_read_only"> is a true value, an exception is thrown.

Exceptions thrown by L<R::Util#normalize_dim|SPVM::R::Util/"normalize_dim"> method could be thrown.

Exceptions thrown by L<R::Util#check_length|SPVM::R::Util/"check_length"> method could be thrown.

=head2 is_dim_read_only

C<has is_dim_read_only : ro byte;>

If this field is a true value, it indicates L</"dim"> field is read only, otherwise writable.

=head1 Class Methods

=head2 new

C<static method new : R::NDArray ($options : object[] = undef);>

=head1 Instance Methods

=head1 Well Known Child Classes

=over 2

=item * L<R::NDArray::Byte|SPVM::R::NDArray::Byte>

=item * L<R::NDArray::Short|SPVM::R::NDArray::Short>

=item * L<R::NDArray::Int|SPVM::R::NDArray::Int>

=item * L<R::NDArray::Float|SPVM::R::NDArray::Float>

=item * L<R::NDArray::Double|SPVM::R::NDArray::Double>

=item * L<R::NDArray::FloatComplex|SPVM::R::NDArray::FloatComplex>

=item * L<R::NDArray::DoubleComplex|SPVM::R::NDArray::DoubleComplex>

=item * L<R::NDArray::Long|SPVM::R::NDArray::Long>

=item * L<R::NDArray::Object|SPVM::R::NDArray::Object>

=item * L<R::NDArray::String|SPVM::R::NDArray::String>

=item * L<R::NDArray::StringBuffer|SPVM::R::NDArray::StringBuffer>

=item * L<R::NDArray::Time::Piece|SPVM::R::NDArray::Time::Piece>

=back

=head1 Copyright & License

Copyright (c) 2024 Yuki Kimoto

MIT License

