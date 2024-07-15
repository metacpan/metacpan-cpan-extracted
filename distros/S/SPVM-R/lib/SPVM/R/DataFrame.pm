package SPVM::R::DataFrame;



1;

=head1 Name

SPVM::R::DataFrame - Short Description

=head1 Description

The R::DataFrame class in L<SPVM> represents a data frame.

=head1 Usage

  use R::OP::DataFrame as DFOP;
  use R::OP::Int as IOP;
  use R::OP::Double as DOP;
  use R::OP::String as STROP;
  use R::OP::Time::Piece as TPOP;
  
  # Create a R::DataFrame object
  my $data_frame = DFOP->data_frame;
  
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

=head1 Details

This class is a port of data frame features of L<R language|https://www.r-project.org/>.

=head1 Fields

=head2 colobjs_list;

C<has colobjs_list : List of L<R::DataFrame::Column|SPVM::R::DataFrame::Column>;>

=head2 colobjs_indexes_h

C<has colobjs_indexes_h : Hash of Int;>

=head1 Class Methods

C<static method new : L<R::DataFrame|SPVM::R::DataFrame> ();>

=head1 Instance Methods

=head2 colnames

C<method colnames : string[] ();>

=head2 exists_col

C<method exists_col : int ($colname : string);>

=head2 colname

C<method colname : string ($col : int);>

=head2 colindex

C<method colindex : int ($colname : string);>

=head2 col_by_index

C<method col_by_index : L<R::NDArray|SPVM::R::NDArray> ($col : int);>

=head2 first_col

C<method first_col : L<R::NDArray|SPVM::R::NDArray> ();>

=head2 col

C<method col : L<R::NDArray|SPVM::R::NDArray> ($colname : string);>

=head2 set_col

C<method set_col : void ($colname : string, $ndarray : L<R::NDArray|SPVM::R::NDArray>);>

=head2 insert_col

C<method insert_col : void ($colname : string, $ndarray : L<R::NDArray|SPVM::R::NDArray>, $before_colname : string = undef);>

=head2 ncol

C<method ncol : int ();>

=head2 nrow

C<method nrow : int ();>

=head2 remove_col

C<method remove_col : void ($colname : string);>

=head2 clone

C<method clone : L<R::DataFrame|SPVM::R::DataFrame> ($shallow : int = 0);>

=head2 to_string

C<method to_string : string ();>

=head2 slice

C<method slice : L<R::DataFrame|SPVM::R::DataFrame> ($colnames : string[], $asix_indexes_product : L<R::NDArray::Int|SPVM::R::NDArray::Int>[]);>

=head2 set_order

C<method set_order : void ($indexes_ndarray : L<R::NDArray::Int|SPVM::R::NDArray::Int>);>

=head2 sort

C<method sort : void ($colnames_with_order_by : string[]);>

=head2 order

C<method order : L<R::NDArray::Int|SPVM::R::NDArray::Int> ($colnames_with_order_by : string[]);>

=head1 See Also

=over 2

=item * L<R::NDArray|SPVM::R::NDArray>

=item * L<R::NDArray::Int|SPVM::R::NDArray::Int>

=item * L<R::OP|SPVM::R::OP>

=item * L<R|SPVM::R>

=back

=head1 Copyright & License

Copyright (c) 2024 Yuki Kimoto

MIT License

