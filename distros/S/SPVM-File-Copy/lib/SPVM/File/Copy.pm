package SPVM::File::Copy;

our $VERSION = "0.023";

1;

=head1 Name

SPVM::File::Copy - Copying and Moving Files

=head1 Description

File::Copy class in L<SPVM> has methods to move and copy files.

=head1 Usage

  use File::Copy;
  
  my $from = "a.txt";
  my $to = "b.txt";
  
  File::Copy->copy($from, $to);
  
  File::Copy->move($from, $to);

=head1 Class Methods

=head2 copy

C<static method copy : void ($from : string, $to : string, $size : int = -1);>

Copies the first $size bytes of the source file $from to the distination file $to. If $size is a negative value, it is set to the size of $from.

=head2 move

C<static method move : void ($from : string, $to : string);>

Moves the source file $from to the distination file $to.

=head1 See Also

=over 2

=item * L<Sys|SPVM::Sys>

=item * L<IO::File|SPVM::IO::File>

=item * L<File::Find|SPVM::File::Find>

=back

=head1 Porting

C<SPVM::File::Copy> is a Perl's L<File::Copy> porting to L<SPVM>.

=head1 Repository

L<SPVM::File::Copy - Github|https://github.com/yuki-kimoto/SPVM-File-Copy>

=head1 Author

Yuki Kimoto C<kimoto.yuki@gmail.com>

=head1 Copyright & License

Copyright (c) 2023 Yuki Kimoto

MIT License

