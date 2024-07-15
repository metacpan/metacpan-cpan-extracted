package SPVM::R::OP::Time::Piece;



1;

=head1 Name

SPVM::R::OP::Time::Piece - N-Dimensional Array Operations for R::NDArray::Time::Piece

=head1 Description

The R::OP::Time::Piece class in L<SPVM> has methods for n-dimensional array operations for L<R::NDArray::Time::Piece|SPVM::R::NDArray::Time::Piece>.

=head1 Usage

  use R::OP::Time::Piece as TPOP;
  
  my $data = [
    Time::Piece->strptime("2024-01-01 00-00-00", '%Y-%m-%d %H:%M:%S'),
    Time::Piece->strptime("2024-01-02 00-00-00", '%Y-%m-%d %H:%M:%S'),
    Time::Piece->strptime("2024-01-03 00-00-00", '%Y-%m-%d %H:%M:%S'),
    Time::Piece->strptime("2024-01-04 00-00-00", '%Y-%m-%d %H:%M:%S'),
    Time::Piece->strptime("2024-01-05 00-00-00", '%Y-%m-%d %H:%M:%S'),
    Time::Piece->strptime("2024-01-06 00-00-00", '%Y-%m-%d %H:%M:%S'),
  ];
  
  my $ndarray_scalar = TPOP->c(Time::Piece->strptime("2024-01-01 00-00-00", '%Y-%m-%d %H:%M:%S'));
  
  my $ndarray_vector = TPOP->c($data);
  
  my $ndarray = TPOP->c($data, [3, 2]);
  
  my $ndarray2 = TPOP->c($ndarray);

=head1 Class Methods

=head2 c

C<static method c : R::NDArray::Time::Piece ($data : object of L<Time::Piece|SPVM::Time::Piece>|L<Time::Piece|SPVM::Time::Piece>[]|L<R::NDArray::Time::Piece|SPVM::R::NDArray::Time::Piece>|string|string[]|L<R::NDArray::String|SPVM::R::NDArray::String>, $dim : int[] = undef);>

=head2 eq

C<static method eq : L<R::NDArray::Int|SPVM::R::NDArray::Int> ($x_ndarray : L<R::NDArray::Time::Piece|SPVM::R::NDArray::Time::Piece>, $y_ndarray : L<R::NDArray::Time::Piece|SPVM::R::NDArray::Time::Piece>);>

=head2 ne

C<static method ne : L<R::NDArray::Int|SPVM::R::NDArray::Int> ($x_ndarray : L<R::NDArray::Time::Piece|SPVM::R::NDArray::Time::Piece>, $y_ndarray : L<R::NDArray::Time::Piece|SPVM::R::NDArray::Time::Piece>);>

=head2 gt

C<static method gt : L<R::NDArray::Int|SPVM::R::NDArray::Int> ($x_ndarray : L<R::NDArray::Time::Piece|SPVM::R::NDArray::Time::Piece>, $y_ndarray : L<R::NDArray::Time::Piece|SPVM::R::NDArray::Time::Piece>);>

=head2 ge

C<static method ge : L<R::NDArray::Int|SPVM::R::NDArray::Int> ($x_ndarray : L<R::NDArray::Time::Piece|SPVM::R::NDArray::Time::Piece>, $y_ndarray : L<R::NDArray::Time::Piece|SPVM::R::NDArray::Time::Piece>);>

=head2 lt

C<static method lt : L<R::NDArray::Int|SPVM::R::NDArray::Int> ($x_ndarray : L<R::NDArray::Time::Piece|SPVM::R::NDArray::Time::Piece>, $y_ndarray : L<R::NDArray::Time::Piece|SPVM::R::NDArray::Time::Piece>);>

=head2 le

C<static method le : L<R::NDArray::Int|SPVM::R::NDArray::Int> ($x_ndarray : L<R::NDArray::Time::Piece|SPVM::R::NDArray::Time::Piece>, $y_ndarray : L<R::NDArray::Time::Piece|SPVM::R::NDArray::Time::Piece>);>

=head2 rep

C<static method rep : L<R::NDArray::Time::Piece|SPVM::R::NDArray::Time::Piece> ($x_ndarray : L<R::NDArray::Time::Piece|SPVM::R::NDArray::Time::Piece>, $times : int);>

=head2 rep_length

C<static method rep_length : L<R::NDArray::Time::Piece|SPVM::R::NDArray::Time::Piece> ($x_ndarray : L<R::NDArray::Time::Piece|SPVM::R::NDArray::Time::Piece>, $length : int);>

=head1 See Also

=over 2

=item * L<R::NDArray::Time::Piece|SPVM::R::NDArray::Time::Piece>

=item * L<R::NDArray|SPVM::R::NDArray>

=item * L<R|SPVM::R>

=back

=head1 Copyright & License

Copyright (c) 2024 Yuki Kimoto

MIT License

