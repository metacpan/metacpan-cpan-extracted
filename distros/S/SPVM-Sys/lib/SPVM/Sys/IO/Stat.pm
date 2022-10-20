package SPVM::Sys::IO::Stat;

1;

=head1 Name

SPVM::Sys::IO::Stat - struct stat in C language

=head1 Usage
  
  use Sys::IO;
  use Sys::IO::Stat;
  
  my $file = "foo.txt";
  my $stat =  Sys::IO::Stat->new;
  Sys::IO->stat($file, $stat);
  
  my $st_mode = $stat->st_mode;
  my $st_size = $stat->st_size;

=head1 Description

C<Sys::IO::Stat> is the class for the C<struct stat> in C<C language>.

This is a L<pointer class|SPVM::Document::Language/"Pointer Class">.

=head1 Class Methods

=head2 new

  static method new : Sys::IO::Stat ();

Create a new C<Sys::IO::Stat> object.

=head1 Instance Methods

=head2 DESTROY

  method DESTROY : void ();

The destructor.

=head2 st_dev

  method st_dev : int ();

Gets C<st_dev>.

=head2 st_ino

  method st_ino : int ();

Gets C<st_ino>.

=head2 st_mode

  method st_mode : int ();

Gets C<st_mode>.

=head2 st_nlink

  method st_nlink : int ();

Gets C<st_nlink>.

=head2 st_uid

  method st_uid : int ();

Gets C<st_uid>.

=head2 st_gid

  method st_gid : int ();

Gets C<st_gid>.

=head2 st_rdev

  method st_rdev : int ();

Gets C<st_rdev>.

=head2 st_size

  method st_size : long ();

Gets C<st_size>.

=head2 st_blksize

  method st_blksize : long ();

Gets C<st_blksize>.

=head2 st_blocks

  method st_blocks : long ();

Gets C<st_blocks>.

=head2 st_mtime

  method st_mtime : long ();

Gets C<st_mtime>.

=head2 st_atime

  method st_atime : long ();

Gets C<st_atime>.

=head2 st_ctime

  method st_ctime : long ();

Gets C<st_ctime>.

=head2 st_mtim_tv_nsec

  method st_mtim_tv_nsec : long ();

Gets C<st_mtim.tv_nsec>.

=head2 st_atim_tv_nsec

  method st_atim_tv_nsec : long ();

Gets C<st_atim.tv_nsec>.

=head2 st_ctim_tv_nsec

  method st_ctim_tv_nsec : long ();

Gets C<st_ctim.tv_nsec>.

=head1 Copyright & License

Copyright 2022-2022 Yuki Kimoto, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
