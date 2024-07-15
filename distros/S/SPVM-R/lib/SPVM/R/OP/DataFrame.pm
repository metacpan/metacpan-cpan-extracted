package SPVM::R::OP::DataFrame;



1;

=head1 Name

SPVM::R::OP::DataFrame - Data Frame Operations

=head1 Description

R::OP::DataFrame class in L<SPVM> has methods for operations for data frame.

=head1 Usage

  use R::OP::DataFrame as DFOP;
  use R::OP::Int as IOP;
  use R::OP::Double as DOP;
  use R::OP::String as STROP;
  
  my $data_frame1 = DFOP->data_frame;
  
  $data_frame1->set_col("name", STROP->c(["Ken", "Yuki", "Mike"]));
  $data_frame1->set_col("age", IOP->c([19, 43, 50]));
  $data_frame1->set_col("weight", DOP->c([(double)50.6, 60.3, 80.5]));
  
  my $data_frame2 = DFOP->data_frame;
  
  $data_frame1->set_col("name", STROP->c(["Jonh"]));
  $data_frame1->set_col("age", IOP->c([25]));
  $data_frame1->set_col("weight", DOP->c([(double)40.6]));
  
  my $data_frame3 = DFOP->cbind($data_frame1, $data_frame2);

=head1 Class Methods

=head2 cbind

C<static method cbind : L<R::DataFrame|SPVM::R::DataFrame> ($x_data_frame : L<R::DataFrame|SPVM::R::DataFrame>, $y_data_frame : L<R::DataFrame|SPVM::R::DataFrame>);>

=head2 rbind

C<static method rbind : L<R::DataFrame|SPVM::R::DataFrame> ($x_data_frame : L<R::DataFrame|SPVM::R::DataFrame>, $y_data_frame : L<R::DataFrame|SPVM::R::DataFrame>);>

=head1 See Also

=over 2

=item * L<R::DataFrame|SPVM::R::DataFrame>

=item * L<R|SPVM::R>

=back

=head1 Copyright & License

Copyright (c) 2024 Yuki Kimoto

MIT License

