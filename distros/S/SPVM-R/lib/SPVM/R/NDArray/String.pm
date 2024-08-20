package SPVM::R::NDArray::String;



1;

=head1 Name

SPVM::R::NDArray::String - N-Dimensional Array of string Type.

=head1 Description

R::NDArray::String class in L<SPVM> represents n-dimensional array of C<string> type.

=head1 Usage

  use R::NDArray::String;
  
  my $ndarray = R::NDArray::String->new({data => [(string)"a", "b", "c", "d", "e", "f"], dim => [3, 2]});

=head1 Super Class

L<R::NDArray|SPVM::R::NDArray>

=head1 Field

=head2 data

C<method data : string[] ();>

Same as L<R::NDArray#data|SPVM::R::NDArray/"data"> method, but the return type is different.

=head1 Class Methods

=head2 new

C<static method new : L<R::NDArray::String|SPVM::R::NDArray::String> ($options : object[] = undef);>

Creates a new L<R::NDArray::String|SPVM::R::NDArray::String> given the options $options and returns it.

This method calls L<R::NDArray#init|SPVM::R::NDArray/"init"> method given the options $options.

=head1 Instance Methods

=head2 create_default_data

C<method create_default_data : string[] ($length : int = 0);>

Creates a default data given the length $length and returns it.

The default data is created by the following code.

  my $default_data = new string[$length];

Exceptions:

The length $length must be more than or equal to 0. Otherwise an exception is thrown.

=head2 elem_to_string

C<method elem_to_string : string ($data : string[], $data_index : int);>

Converts an element $data at index $data_index to a string and returns it.

The string is created by the following code.

  my $string = copy $data->[$data_index];

=head2 elem_assign

C<method elem_assign : void ($dist_data : string[], $dist_data_index : int, $src_data : string[], $src_data_index : int);>

Assigns the element $src_data at index $src_data_index to the element $dist_data at index $dist_data_index.

=head2 elem_clone

C<method elem_clone : void ($dist_data : string[], $dist_data_index : int, $src_data : string[], $src_data_index : int);>

Clones the element $src_data at index $src_data_indext to the element $dist_data at index $dist_data_index.

The clone is created by the following code.

  $dist_data->[$dist_data_index] = copy $src_data->[$src_data_index];

=head2 elem_cmp

C<method elem_cmp : int ($a_data : string[], $a_data_index : int, $b_data : string[], $b_data_index : int);>

Compares the element $a_data at index $a_data_index and the element $b_data at index $b_data_index using the string comparison operator C<cmp> and returns the result.

=head2 elem_is_na

C<method elem_is_na : int ($data : object, $data_index : int);>

Checks if an element represets NA.

If the element $data at index $data_index is not defined, returns 1, otherwise returns 0.

=head2 clone

C<method clone : L<R::NDArray::String|SPVM::R::NDArray::String> ($shallow : int = 0);>

Same as L<R::NDArray#clone|SPVM::R::NDArray/"clone"> method, but the return type is different.

=head2 slice

C<method slice : L<R::NDArray::String|SPVM::R::NDArray::String> ($indexes_product : L<R::NDArray::Int|SPVM::R::NDArray::Int>[]);>

Same as L<R::NDArray#slice|SPVM::R::NDArray/"slice"> method, but the return type is different.

=head2 to_string_buffer_ndarray

C<method to_string_buffer_ndarray : L<R::NDArray::StringBuffer|SPVM::R::NDArray::StringBuffer> ();>

Converts this n-dimensional array to a n-dimensional array of L<R::NDArray::StringBuffer|SPVM::R::NDArray::StringBuffer> and returns it.

Each element is converted to a L<StringBuffer|SPVM::StringBuffer> object by the following code.
  
  my $ret_elem = (StringBuffer)undef;
  if ($elem) {
    $ret_elem = StringBuffer->new($elem);
  }

=head2 to_time_piece_ndarray

C<method to_time_piece_ndarray : L<R::NDArray::Time::Piece|SPVM::R::NDArray::Time::Piece> ();>

Converts this n-dimensional array to a n-dimensional array of L<R::NDArray::Time::Piece|SPVM::R::NDArray::Time::Piece> and returns it.

Each element is converted to a L<Time::Piece|SPVM::Time::Piece> object by the following code.
  
  my $ret_elem = (Time::Piece)undef;
  if ($elem) {
    eval { $ret_elem = Time::Piece->strptime($elem, "%Y-%m-%d %H:%M:%S"); }
    
    unless ($ret_elem) {
      eval { $ret_elem = Time::Piece->strptime($elem, "%Y-%m-%d"); }
    }
  }

Every string format must be C<%Y-%m-%d %H:%M:%S> or C<%Y-%m-%d> if the element is defined.

=head1 See Also

=over 2

=item * L<R::OP::String|SPVM::R::OP::String>

=item * L<R::NDArray|SPVM::R::NDArray>

=item * L<R|SPVM::R>

=back

=head1 Copyright & License

Copyright (c) 2024 Yuki Kimoto

MIT License

