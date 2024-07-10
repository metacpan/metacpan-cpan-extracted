package SPVM::R::Util;



1;

=head1 Name

SPVM::R::Util - Utilities for N-Dimensional Array

=head1 Description

The R::Util class in L<SPVM> has utility methods for n-dimensional array.

=head1 Usage

  use R::Util;

=head1 Class Methods

=head2 calc_data_length

C<static method calc_data_length : int ($dim : int[]);>

=head2 normalize_dim

C<static method normalize_dim : int[] ($dim : int[]);>

=head2 check_length

C<static method check_length : void ($data : object, $dim : int[]);>

=head2 drop_dim

C<static method drop_dim : int[] ($dim : int[], $index : int = -1);>

=head2 expand_dim

C<static method expand_dim : int[] ($dim : int[], $index : int = -1);>

=head2 equals_dim

C<static method equals_dim : int ($x_dim : int[], $y_dim : int[]);>

=head2 equals_dropped_dim

C<static method equals_dropped_dim : int ($x_dim : int[], $y_dim : int[]);>

=head1 Copyright & License

Copyright (c) 2024 Yuki Kimoto

MIT License

