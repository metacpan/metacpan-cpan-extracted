package SPVM::Sys::IO::Stat;

1;

=head1 Name

SPVM::Sys::IO::Stat - struct stat in the C language

=head1 Description

The Sys::IO::Stat class in L<SPVM> represents C<struct stat> in the C language, and has utility methods for the structure.

=head1 Usage

  use Sys::IO::Stat;
  
  my $file = "foo.txt";
  my $stat = Sys::IO::Stat->new;
  
  Sys::IO::Stat->stat($file, $stat);
  
  Sys::IO::Stat->lstat($file, $stat);
  
  my $st_mode = $stat->st_mode;
  my $st_size = $stat->st_size;

=head1 Details

This class is a pointer class. The pointer the instance has is set to a C<struct stat> object.

=head1 Class Methods

=head2 new

C<static method new : L<Sys::IO::Stat|SPVM::Sys::IO::Stat> ();>

Creates a new L<Sys::IO::Stat|SPVM::Sys::IO::Stat> object.

=head2 stat

C<static method stat : int ($path : string, $stat : L<Sys::IO::Stat|SPVM::Sys::IO::Stat>);>

Calls the L<stat|https://linux.die.net/man/2/stat> function and returns its return value.

Exceptions:

$path must be defined. Otherwise an exception is thrown.

$stat must be defined. Otherwise an exception is thrown.

If the stat function failed, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::System|SPVM::Error::System> class.

=head2 lstat

C<static method lstat : int ($path : string, $stat : L<Sys::IO::Stat|SPVM::Sys::IO::Stat>);>

Calls the L<lstat|https://linux.die.net/man/2/lstat> function and returns its return value.

Exceptions:

$path must be defined. Otherwise an exception is thrown.

$stat must be defined. Otherwise an exception is thrown.

If the lstat function failed, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::System|SPVM::Error::System> class.

=head2 fstat

C<static method fstat : int ($fd : int, $stat : L<Sys::IO::Stat|SPVM::Sys::IO::Stat>);>

Calls the L<fstat|https://linux.die.net/man/2/fstat> function and returns its return value.

Exceptions:

The C<$stat> is a L<Sys::IO::Stat|SPVM::Sys::IO::Stat> object.

$stat must be defined. Otherwise an exception is thrown.

If the stat function failed, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::System|SPVM::Error::System> class.

=head1 Instance Methods

=head2 DESTROY

C<method DESTROY : void ();>

The destructor.

=head2 st_dev

C<method st_dev : int ();>

Returns C<st_dev>.

=head2 st_ino

C<method st_ino : int ();>

Returns C<st_ino>.

=head2 st_mode

C<method st_mode : int ();>

Returns C<st_mode>.

=head2 st_nlink

C<method st_nlink : int ();>

Returns C<st_nlink>.

=head2 st_uid

C<method st_uid : int ();>

Returns C<st_uid>.

=head2 st_gid

C<method st_gid : int ();>

Returns C<st_gid>.

=head2 st_rdev

C<method st_rdev : int ();>

Returns C<st_rdev>.

=head2 st_size

C<method st_size : long ();>

Returns C<st_size>.

=head2 st_blksize

C<method st_blksize : long ();>

Returns C<st_blksize>.

=head2 st_blocks

C<method st_blocks : long ();>

Returns C<st_blocks>.

=head2 st_mtime

C<method st_mtime : long ();>

Returns C<st_mtime>.

=head2 st_atime

C<method st_atime : long ();>

Returns C<st_atime>.

=head2 st_ctime

C<method st_ctime : long ();>

Returns C<st_ctime>.

=head2 st_mtim_tv_nsec

C<method st_mtim_tv_nsec : long ();>

Returns C<st_mtim.tv_nsec>.

=head2 st_atim_tv_nsec

C<method st_atim_tv_nsec : long ();>

Returns C<st_atim.tv_nsec>.

=head2 st_ctim_tv_nsec

C<method st_ctim_tv_nsec : long ();>

Returns C<st_ctim.tv_nsec>.

=head2 A

C<method A : double ();>

The implementation of the L<A|SPVM::Sys/"A"> method in the Sys class.

=head2 C

C<method C : double ();>

The implementation of the L<C|SPVM::Sys/"C"> method in the Sys class.

=head2 M

C<method M : double ();>

The implementation of the L<M|SPVM::Sys/"M"> method in the Sys class.

=head2 O

C<method O : int ();>

The implementation of the L<O|SPVM::Sys/"O"> method in the Sys class.

=head2 S

C<method S : int ();>

The implementation of the L<S|SPVM::Sys/"S"> method in the Sys class.

=head2 b

C<method b : int ();>

The implementation of the L<b|SPVM::Sys/"b"> method in the Sys class.

=head2 c

C<method c : int ();>

The implementation of the L<c|SPVM::Sys/"c"> method in the Sys class.

=head2 d

C<method d : int ();>

The implementation of the L<d|SPVM::Sys/"d"> method in the Sys class.

=head2 e

C<method e : int ();>

The implementation of the L<e|SPVM::Sys/"e"> method in the Sys class.

=head2 f

C<method f : int ();>

The implementation of the L<f|SPVM::Sys/"f"> method in the Sys class.

=head2 g

C<method g : int ();>

The implementation of the L<g|SPVM::Sys/"g"> method in the Sys class.

=head2 k

C<method k : int ();>

The implementation of the L<k|SPVM::Sys/"k"> method in the Sys class.

=head2 l

C<method l : int ();>

The implementation of the L<l|SPVM::Sys/"l"> method in the Sys class.

=head2 o

C<method o : int ();>

The implementation of the L<o|SPVM::Sys/"o"> method in the Sys class.

=head2 p

C<method p : int ();>

The implementation of the L<p|SPVM::Sys/"p"> method in the Sys class.

=head2 s

C<method s : long ();>

The implementation of the L<s|SPVM::Sys/"s"> method in the Sys class.

=head2 u

C<method u : int ();>

The implementation of the L<u|SPVM::Sys/"u"> method in the Sys class.

=head2 z

C<method z : int ();>

The implementation of the L<z|SPVM::Sys/"z"> method in the Sys class.

=head2 r

C<method r : int ();>

The implementation of the L<r|SPVM::Sys/"r"> method in the Sys class.

=head2 w

C<method w : int ();>

The implementation of the L<w |SPVM::Sys/"w "> method in the Sys class.

=head2 x

C<method x : int ();>

The implementation of the L<x|SPVM::Sys/"x"> method in the Sys class.

=head2 R

C<method R : int ();>

The implementation of the L<R|SPVM::Sys/"R"> method in the Sys class.

=head2 W

C<method W : int ();>

The implementation of the L<W|SPVM::Sys/"W"> method in the Sys class.

=head2 X

C<method X : int ();>

The implementation of the L<X|SPVM::Sys/"X"> method in the Sys class.

=head1 Copyright & License

Copyright (c) 2023 Yuki Kimoto

MIT License

