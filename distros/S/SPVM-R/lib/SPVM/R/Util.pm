package SPVM::R::Util;



1;

=head1 Name

SPVM::R::Util - Utilities for N-Dimensional Array

=head1 Description

R::Util class in L<SPVM> has utility methods for n-dimensional array.

=head1 Usage

  use R::Util;

=head1 Class Methods

=head2 calc_data_length

C<static method calc_data_length : int ($dim : int[]);>

Calcurates the data length from the dimensions $dim, and returns it.

The data length means the product of all elements in $dim.

Examples are
  
  $dim       Return Value
  [2, 3]     6
  [1, 2, 3]  6

Exceptions:

The dimensions $dim must be L<normalized|/"is_normalized_dim">. Otherwise an exception is thrown.

=head2 normalize_dim

C<static method normalize_dim : int[] ($dim : int[]);>

Normalizes the dimension $dim, and returns it.

See L</"is_normalized_dim"> method about the normalization of dimensions.

Exceptions:

All element of the dimensions $dim except the last one must be greater than 0. Otherwise an exception is thrown.

=head2 is_normalized_dim

C<static method is_normalized_dim : int ($dim : int[]);>

If the dimensions $dim is normalized, returns 1, otherwise returns 0.

Normalized dimensions mean that

=over 2 

=item * $dim is defined.

=item * And all elements of $dim are greater than 0 if elements exists.

=back

=head2 check_length

C<static method check_length : void ($data : object, $dim : int[]);>

Checks if the data $data that is an array and the dimensions $dim have length compatibility.

If they are satisfied, returns 1, otherwise returns 0.

length compatibility means the array length of $data is equal to the length calcurated by L</"calc_data_length"> method.

Exceptions:

The data $data must be defined. Otherwise an exception is thrown.

The data $data must be an array. Otherwise an exception is thrown.

The dimensions $dim must be L<normalized|/"is_normalized_dim">. Otherwise an exception is thrown.

=head2 drop_dim

C<static method drop_dim : int[] ($dim : int[], $index : int = -1);>

Case : C<$index E<lt> 0>

$dim is copied and assigned to $dim.

If the length of the dimensions $dim is 0, returns $dim.

If not, removes all elements of $dim that are equal to 1. If $dim becomes [], [1] is assinged to $dim. And $dim is returned. 

Examples are
  
  $dim         Retrun value
  [1, 2, 3]    [2, 3]
  [1, 2, 1, 3] [2, 3]
  [1, 1]       [1]
  [1]          [1]
  []           []

Case : C<$index E<gt>= 0>

$dim is copied and assigned to $dim.

If the element of $dim at index $index is 1, removes it, and returns $dim.

Exceptions:

The dimensions $dim must be L<normalized|/"is_normalized_dim">. Otherwise an exception is thrown.

The index $index must be less than the length of the dimension $dim.

The element of the dimension $dim at index $index must be 1. Otherwise an exception is thrown.

=head2 expand_dim

C<static method expand_dim : int[] ($dim : int[], $index : int = -1);>

$dim is copied and assigned to $dim, inserts 1 to $dim at index $index, and returns $dim.

Exceptions:

The dimensions $dim must be L<normalized|/"is_normalized_dim">. Otherwise an exception is thrown.

The index $index must be less than or equal to the length of the dimension $dim.

=head2 equals_dim

C<static method equals_dim : int ($x_dim : int[], $y_dim : int[]);>

If $x_dim is equal to $y_dim, returns 1, otherwise returns 0.

Exceptions:

The dimensions $x_dim must be L<normalized|/"is_normalized_dim">. Otherwise an exception is thrown.

The dimensions $y_dim must be L<normalized|/"is_normalized_dim">. Otherwise an exception is thrown.

=head2 equals_dropped_dim

C<static method equals_dropped_dim : int ($x_dim : int[], $y_dim : int[]);>

If $x_dim on which L</"drop_dim"> method is performed is equal to $y_dim on which L</"drop_dim"> method is performed, returns 1, otherwise returns 0.

This method calls L</"equals_dim"> method.

Exceptions:

Exceptions thrown by L</"equals_dim"> method could be thrown.

=head1 Copyright & License

Copyright (c) 2024 Yuki Kimoto

MIT License

