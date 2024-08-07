package SPVM::R::OP::DataFrame;



1;

=head1 Name

SPVM::R::OP::DataFrame - Data Frame Operations

=head1 Description

R::OP::DataFrame class in L<SPVM> has methods for operations for data frame.

=head1 Usage

  use R::DataFrame;
  use R::OP::DataFrame as DFOP;
  use R::OP::Int as IOP;
  use R::OP::Double as DOP;
  use R::OP::String as STROP;
  
  my $data_frame1 = R::DataFrame->new;
  
  $data_frame1->set_col("name", STROP->c(["Ken", "Yuki", "Mike"]));
  $data_frame1->set_col("age", IOP->c([19, 43, 50]));
  $data_frame1->set_col("weight", DOP->c([(double)50.6, 60.3, 80.5]));
  
  my $data_frame2 = R::DataFrame->new;
  
  $data_frame1->set_col("name", STROP->c(["Jonh"]));
  $data_frame1->set_col("age", IOP->c([25]));
  $data_frame1->set_col("weight", DOP->c([(double)40.6]));
  
  my $data_frame3 = DFOP->cbind($data_frame1, $data_frame2);

See also L<Data Frame Examples|https://github.com/yuki-kimoto/SPVM-R/wiki/SPVM%3A%3AR-Data-Frame-Examples>.

=head1 Class Methods

=head2 cbind

C<static method cbind : L<R::DataFrame|SPVM::R::DataFrame> ($x_data_frame : L<R::DataFrame|SPVM::R::DataFrame>, $y_data_frame : L<R::DataFrame|SPVM::R::DataFrame>);>

Creates a new L<R::DataFrame|SPVM::R::DataFrame> object, adds all columns of $x_data_frame and all columns of $y_data_frame are added to the new data frame object, and returns the new data frame object.

This method calls L<R::DataFrame#insert_col|SPVM::R::DataFrame/"insert_col"> method.

Exceptions:

The data frame $x_data_frame must be defined. Otherwise, an exception is thrown.

The data frame $y_data_frame must be defined. Otherwise, an exception is thrown.

Exceptions thrown by L<R::DataFrame#insert_col|SPVM::R::DataFrame/"insert_col"> method could be thrown.

=head2 rbind

C<static method rbind : L<R::DataFrame|SPVM::R::DataFrame> ($x_data_frame : L<R::DataFrame|SPVM::R::DataFrame>, $y_data_frame : L<R::DataFrame|SPVM::R::DataFrame>);>

Creates a new L<R::DataFrame|SPVM::R::DataFrame> object, adds all rows of $x_data_frame and all rows of $y_data_frame are added to the new data frame object, and returns the new data frame object.

Exceptions:

The data frame $x_data_frame must be defined. Otherwise, an exception is thrown.

The data frame $y_data_frame must be defined. Otherwise, an exception is thrown.

The column numbers of the data frame $x_data_frame must be equal to the column numbers of the data frame $y_data_frame.

The column name at column index $i of the data frame $x_data_frame must be equal to the column name at column index $i of the data frame $y_data_frame. Otherwise, an exception is thrown.

The type of the n-dimensional array at column index $i of the data frame $x_data_frame must be equal to the type of the n-dimensional array at column index $i of the data frame $y_data_frame. Otherwise, an exception is thrown.

($i is a column index)

=head2 subset

C<static method subset : L<R::DataFrame|SPVM::R::DataFrame> ($x_data_frame : L<R::DataFrame|SPVM::R::DataFrame>, $indexes : L<R::NDArray::Int|SPVM::R::NDArray::Int>, $options : object[] = undef);>

Gets the subset of the data frame $x_data_frame given the indexes $indexes and the options $options, and returns the subset.

Same as the following code using L<R::DataFrame#slice|SPVM::R::DataFrame/"slice"> method.

  $x_data_frame->slice($colnames, [$indexes]);

($colnames is the value of key C<select> in the options $options.)

Options:

=over 2

=item * C<select> : string[] = undef

Column names.

=back

Exceptions:

The data frame $x_data_frame must be defined. Otherwise, an exception is thrown.

The first column of $x_data_frame must be a vector if columns exists. Otherwise, an exception is thrown.

Exceptions thrown by L<R::DataFrame#slice|SPVM::R::DataFrame/"slice"> method could be thrown.

=head2 na_omit

C<static method na_omit : L<R::DataFrame|SPVM::R::DataFrame> ($x_data_frame : L<R::DataFrame|SPVM::R::DataFrame>);>

Gets the subset of the $x_data_frame which rows does not contains NA data and returns the subset.

This method calls L</"subset"> method.

Exceptions:

The data frame $x_data_frame must be defined.

Exceptions thrown by L</"subset"> method could be thrown.

=head1 See Also

=over 2

=item * L<Data Frame Examples|https://github.com/yuki-kimoto/SPVM-R/wiki/SPVM%3A%3AR-Data-Frame-Examples>

=item * L<R::DataFrame|SPVM::R::DataFrame>

=item * L<R|SPVM::R>

=back

=head1 Copyright & License

Copyright (c) 2024 Yuki Kimoto

MIT License

