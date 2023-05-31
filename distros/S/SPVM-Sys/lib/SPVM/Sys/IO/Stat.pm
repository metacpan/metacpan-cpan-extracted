package SPVM::Sys::IO::Stat;

1;

=head1 Name

SPVM::Sys::IO::Stat - The stat Functions and The struct stat in C language

=head1 Usage
  
  use Sys::IO::Stat;
  
  my $file = "foo.txt";
  my $stat = Sys::IO::Stat->new($file);
  
  my $st_mode = $stat->st_mode;
  my $st_size = $stat->st_size;
  
  # More native
  my $stat = Sys::IO::Stat->new;
  Sys::IO::Stat->stat($file, $stat);
  Sys::IO::Stat->lstat($file, $stat);

=head1 Description

C<Sys::IO::Stat> is the class for the C<struct stat> in C<C language>.

This is a L<pointer class|SPVM::Document::Language/"Pointer Class">.

=head1 Class Methods

=head2 new

  static method new : Sys::IO::Stat ($path : string = undef, $options : object[] = undef);

Creates a new C<Sys::IO::Stat> object.

If $path is specified, L</"stat"> is called.

=head2 stat_raw

  static method stat_raw : int ($path : string, $stat : Sys::IO::Stat);

The same as L</"stat">, but even if the return value is C<-1>, an exception will not be thrown.

=head2 stat

  static method stat : int ($path : string, $stat : Sys::IO::Stat);

These functions return information about a file. No permissions are required on the file itself, but-in the case of stat() and lstat() - execute (search) permission is required on all of the directories in path that lead to the file.

stat() stats the file pointed to by path and fills in buf.

See the L<stat|https://linux.die.net/man/2/stat> function in Linux.

The stat is L<Sys::IO::Stat|SPVM::Sys::IO::Stat> object.

=head2 lstat_raw

  static method lstat_raw : int ($path : string, $stat : Sys::IO::Stat);

The same as L</"lstat">, but even if the return value is C<-1>, an exception will not be thrown.

=head2 lstat

  static method lstat : int ($path : string, $stat : Sys::IO::Stat);

These functions return information about a file. No permissions are required on the file itself, but-in the case of stat() and lstat() - execute (search) permission is required on all of the directories in path that lead to the file.

lstat() is identical to stat(), except that if path is a symbolic link, then the link itself is stat-ed, not the file that it refers to.

See the L<lstat|https://linux.die.net/man/2/lstat> function in Linux.

The stat is L<Sys::IO::Stat|SPVM::Sys::IO::Stat> object.

=head2 fstat_raw

  static method fstat_raw : int ($fd : int, $stat : Sys::IO::Stat);

The same as L</"fstat">, but even if the return value is C<-1>, an exception will not be thrown.

=head2 fstat

  static method fstat : int ($fd : int, $stat : Sys::IO::Stat);

fstat() is identical to stat(), except that the file to be stat-ed is specified by the file descriptor fd.

See L<fstat(2) - Linux man page|https://linux.die.net/man/2/fsync> in Linux.

The C<$stat> is a L<Sys::IO::Stat|SPVM::Sys::IO::Stat> object.

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

=head2 A

  method A : double ();

=head2 C

  method C : double ();

=head2 M

  method M : double ();

=head2 O

  method O : int ();

=head2 S

  method S : int ();

=head2 b

  method b : int ();

=head2 c

  method c : int ();

=head2 d

  method d : int ();

=head2 e

  method e : int ();

=head2 f

  method f : int ();

=head2 g

  method g : int ();

=head2 k

  method k : int ();

=head2 l

  method l : int ();

=head2 o

  method o : int ();

=head2 p

  method p : int ();

=head2 s

  method s : long ();

=head2 u

  method u : int ();

=head2 z

  method z : int ();

=head2 cando

  method cando : int ($mode : int, $effective : int);

=head2 r

  method r : int ();

=head2 w

  method w : int ();

=head2 x

  method x : int ();

=head2 R

  method R : int ();

=head2 W

  method W : int ();

=head2 X

  method X : int ();

=head1 Copyright & License

Copyright (c) 2023 Yuki Kimoto

MIT License

