package SPVM::R::DataFrame;



1;

=head1 Name

SPVM::R::DataFrame - Data Frame

=head1 Description

R::DataFrame class in L<SPVM> represents a data frame.

=head1 Usage
  
  use R::DataFrame;
  use R::OP::DataFrame as DFOP;
  use R::OP::Int as IOP;
  use R::OP::Double as DOP;
  use R::OP::String as STROP;
  use R::OP::Time::Piece as TPOP;
  
  # Create a R::DataFrame object
  my $data_frame = R::DataFrame->new;
  
  $data_frame->set_col("name", STROP->c(["Ken", "Yuki", "Mike"]));
  $data_frame->set_col("age", IOP->c([19, 43, 50]));
  $data_frame->set_col("weight", DOP->c([(double)50.6, 60.3, 80.5]));
  $data_frame->set_col("birth", TPOP->c(["1980-10-10", "1985-12-10", "1970-02-16"]));
  
  my $data_frame_string = $data_frame->to_string;
  
  my $slice_data_frame = $data_frame->slice(["name", "age"], [IOP->c([0, 1])]);
  
  $data_frame->sort(["name", "age desc"]);
  
  my $nrow = $data_frame->nrow;
  
  my $ncol = $data_frame->ncol;
  
  my $dim = $data_frame->first_col->dim;

See also L<Data Frame Examples|https://github.com/yuki-kimoto/SPVM-R/wiki/SPVM%3A%3AR-Data-Frame-Examples>.

=head1 Details

This class is a port of data frame features of L<R language|https://www.r-project.org/>.

=head2 Complexity of Getting, Setting, Inserting and Removing a Column

The complexity of getting a new column is O(1).

The complexity of setting a column is O(1).

The complexity of inserting a new column is O(n), but the complexity of inserting a new column to the end of columns is O(1).

The complexity of removing a column is O(n), but the complexity of removing a column from the end of columns is O(1).

=head2 Data Frame Operations

See L<R::OP::DataFrame|SPVM::R::OP::DataFrame> about data frame operations.

=head1 Fields

=head2 colobjs_list;

C<has colobjs_list : List of L<R::DataFrame::Column|SPVM::R::DataFrame::Column>;>

A list of L<R::DataFrame::Column|SPVM::R::DataFrame::Column> objects that represents columns.

=head2 colobjs_indexes_h

C<has colobjs_indexes_h : Hash of Int;>

A hash that stores the column index for each column name.

=head1 Class Methods

=head2 new

C<static method new : L<R::DataFrame|SPVM::R::DataFrame> ();>

Creates a new L<R::DataFrame|SPVM::R::DataFrame> object and returns it.

=head1 Instance Methods

=head2 colnames

C<method colnames : string[] ();>

Returns column names.

=head2 exists_col

C<method exists_col : int ($colname : string);>

If the colnum named $colname exists, returns 1, otherwise returns 0.

=head2 colname

C<method colname : string ($col : int);>

Returns a column name at column index $col.

Exceptions:

If the column at index $col dose not exist, an exception is thrown.

=head2 colindex

C<method colindex : int ($colname : string);>

Returns the column index of the column named $colname.

Exceptions:

If the column named $colname does not exists, an exception is thrown.

=head2 col_by_index

C<method col_by_index : L<R::NDArray|SPVM::R::NDArray> ($col : int);>

Returns the n-dimensional array at column index $col.

Exceptions:

If the column at index $col does not exists, an exception is thrown.

=head2 first_col

C<method first_col : L<R::NDArray|SPVM::R::NDArray> ();>

Returns the n-dimensional array of the first column.

This method calls L</"col"> method.

Exceptions:

Exceptions thrown by L</"col"> method could be thrown.

=head2 col

C<method col : L<R::NDArray|SPVM::R::NDArray> ($colname : string);>

Returns the n-dimensional array of the column named $colname.

Excepttions:

If the column named $colname dose not exist, an exception is thrown.

=head2 set_col

C<method set_col : void ($colname : string, $ndarray : L<R::NDArray|SPVM::R::NDArray>);>

Sets the n-dimensional array of the column named $colname to the n-dimensional array $ndarray.

$ndarray becomes read-only by calling L<R::NDArray#make_dim_read_only|SPVM::R::NDArray/"make_dim_read_only"> method.

If the n-dimensional array of the column named $colname exists, it is replaced with $ndarray.

If not, a new column is inserted by L</"insert_col"> method.

=head2 insert_col

C<method insert_col : void ($colname : string, $ndarray : L<R::NDArray|SPVM::R::NDArray>, $before_colname : string = undef);>

Inserts the column named $colname with the n-dimensional array $ndarray before the column named $before_colname.

If $before_colname is not defined, the new column is instered at the end of columns.

The column name $colname must be a non-empty string. Otherwise, an exception is thrown.

The n-dimensional array $ndarray must be defined. Otherwise, an exception is thrown.

If the column named $colname already exists, an exception is thrown.

The dimensions of the n-dimensional array $ndarray must be equal to the dimensions of the n-dimensional array of the first column of this data frame. Otherwise, an exception is thrown.

=head2 ncol

C<method ncol : int ();>

Returns the column numbers.

=head2 nrow

C<method nrow : int ();>

Returns the row numbers.

If columns do not exist, returns 0.

Exceptions:

The n-dimensional array of the first column of this data frame must be a vector.

=head2 remove_col

C<method remove_col : void ($colname : string);>

Removes the column named $colname.

This method calls L</"colindex"> method.

Exceptions:

Exceptions thrown by L</"colindex"> method could be thrown.

=head2 clone

C<method clone : L<R::DataFrame|SPVM::R::DataFrame> ($shallow : int = 0);>

Clones this data frame and returns it.

This method calls L<R::NDArray#clone|SPVM::R::NDArray#clone> method for the n-dimensional array of each column in this data frame.

=head2 to_string

C<method to_string : string ();>

Strigifies this data frame and returns it.

=head2 slice

C<method slice : L<R::DataFrame|SPVM::R::DataFrame> ($colnames : string[], $axis_indexes_product : L<R::NDArray::Int|SPVM::R::NDArray::Int>[]);>

Slices this data frame given the column names $colnames and the product of axis indexes $axis_indexes_product, and returnd sliced data frame.

This method calls L<R::NDArray#slice|SPVM::R::NDArray#slice> method for the n-dimensional array of each column in this data frame.

=head2 order

C<method order : L<R::NDArray::Int|SPVM::R::NDArray::Int> ($colnames_with_sort_order : string[]);>

Gets order data given the column names with the sort orders $colnames_with_sort_order, and returns the order data.

The returned order data can be used for the argument of L</"set_order"> method.

Format of a Column Name with the Sort Order:

  COLUMN_NAME
  COLUMN_NAME SORT_ORDER

C<COLUMN_NAME> is a column name.

C<SORT_ORDER> is C<asc> or C<desc>.

Examples are

  age
  age asc
  age desc

Exceptions:

The column names $colnames_with_sort_order must be defined. Otherwise an exception is thrown.

The column numbers of this data frame must be greater than 0. Otherwise an exception is thrown.

If the column named $colname does not exist, an excetpion is thrown.

($colname is the column part of $colnames_with_sort_order.)

If the column name with the sort order is invalid format, an exception is thrown.

=head2 set_order

C<method set_order : void ($data_indexes_ndarray : L<R::NDArray::Int|SPVM::R::NDArray::Int>);>

Calls L<R::NDArray#set_order|SPVM::R::NDArray#set_order> method for the n-dimeniaonal array of each column in this data frame.

=head2 sort

C<method sort : void ($colnames_with_sort_order : string[]);>

Sort data in the n-dimensional array in this data frame given the column name with the sort order $colnames_with_sort_order.

Implementation:

This method calls L</"order"> method given $colnames_with_sort_order and calls L</"set_order"> method givne the return value of L</"order"> method.

=head1 See Also

=over 2

=item * L<R::OP::DataFrame|SPVM::R::OP::DataFrame>

=item * L<R::DataFrame::Column|SPVM::R::DataFrame::Column>

=item * L<R::NDArray|SPVM::R::NDArray>

=item * L<R::NDArray::Int|SPVM::R::NDArray::Int>

=item * L<R::OP|SPVM::R::OP>

=item * L<R|SPVM::R>

=back

=head1 Copyright & License

Copyright (c) 2024 Yuki Kimoto

MIT License

