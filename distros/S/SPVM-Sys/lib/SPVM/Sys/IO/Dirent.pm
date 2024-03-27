package SPVM::Sys::IO::Dirent;

1;

=head1 Name

SPVM::Sys::IO::Dirent - struct dirent in the C language

=head1 Description

The Sys::IO::Dirent class in L<SPVM> represents L<struct dirent|https://linux.die.net/man/3/readdir> in the C language.

=head1 Usage
  
  use Sys;
  use Sys::IO::DirStream;
  
  my $dh_ref = [(Sys::IO::DirStream)undef];
  
  Sys->opendir($dh_ref, $test_dir);
  
  my $dh = $dh_ref->[0];
  
  my $dirent = Sys->readdir($dh);
  
  my $d_name = $dirent->d_name;

=head1 Details

This class is a pointer class. The pointer the instance has is set to a C<struct dirent> object.

=head1 Class Methods

=head2 d_ino

C<method d_ino : int ();>

Returns C<d_ino>.

=head2 d_reclen

C<method d_reclen : int ();>

Returns C<d_reclen>.

=head2 d_name

C<method d_name : string ();>

Gets and copies C<d_name> and returns it.

=head2 d_off

C<method d_off : long;>

Returns C<d_off>.

=head2 d_type

C<method d_type : int ();>

Returns C<d_type>.

=head1 See Also

=over 2

=item * L<readdir|SPVM::Sys/"readdir"> in Sys.

=item * L<readdir|SPVM::Sys::IO/"readdir"> in Sys::IO.

=item * L<opendir|SPVM::Sys/"opendir"> in Sys.

=item * L<opendir|SPVM::Sys::IO/"opendir"> in Sys::IO.

=back

=head1 Copyright & License

Copyright (c) 2023 Yuki Kimoto

MIT License

