package SPVM::Sys::IO::Constant;

1;

=head1 Name

SPVM::Sys::IO::Constant - Constant values for IO.

=head1 Usage

  use Sys::IO::Constant as IO;
  
  my $o_trunc = IO->O_TRUNC;

=head1 Description

C<Sys::IO::Constant> is the class for the constant values for IO.

=head1 Class Methods

=head2 AT_EMPTY_PATH

  static method AT_EMPTY_PATH : int ();

Get the constant value of C<AT_EMPTY_PATH>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 AT_FDCWD

  static method AT_FDCWD : int ();

Get the constant value of C<AT_FDCWD>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 AT_NO_AUTOMOUNT

  static method AT_NO_AUTOMOUNT : int ();

Get the constant value of C<AT_NO_AUTOMOUNT>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 AT_SYMLINK_FOLLOW

  static method AT_SYMLINK_FOLLOW : int ();

Get the constant value of C<AT_SYMLINK_FOLLOW>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 AT_SYMLINK_NOFOLLOW

  static method AT_SYMLINK_NOFOLLOW : int ();

Get the constant value of C<AT_SYMLINK_NOFOLLOW>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 CAP_CHOWN

  static method CAP_CHOWN : int ();

Get the constant value of C<CAP_CHOWN>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 CAP_DAC_READ_SEARCH

  static method CAP_DAC_READ_SEARCH : int ();

Get the constant value of C<CAP_DAC_READ_SEARCH>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 CAP_FOWNER

  static method CAP_FOWNER : int ();

Get the constant value of C<CAP_FOWNER>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 CAP_FSETID

  static method CAP_FSETID : int ();

Get the constant value of C<CAP_FSETID>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 CAP_LEASE

  static method CAP_LEASE : int ();

Get the constant value of C<CAP_LEASE>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 CAP_SYS_RESOURCE

  static method CAP_SYS_RESOURCE : int ();

Get the constant value of C<CAP_SYS_RESOURCE>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 DN_ACCESS

  static method DN_ACCESS : int ();

Get the constant value of C<DN_ACCESS>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 DN_ATTRIB

  static method DN_ATTRIB : int ();

Get the constant value of C<DN_ATTRIB>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 DN_CREATE

  static method DN_CREATE : int ();

Get the constant value of C<DN_CREATE>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 DN_DELETE

  static method DN_DELETE : int ();

Get the constant value of C<DN_DELETE>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 DN_MODIFY

  static method DN_MODIFY : int ();

Get the constant value of C<DN_MODIFY>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 DN_MULTISHOT

  static method DN_MULTISHOT : int ();

Get the constant value of C<DN_MULTISHOT>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 DN_RENAME

  static method DN_RENAME : int ();

Get the constant value of C<DN_RENAME>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EOF

  static method EOF : int ();

Get the constant value of C<EOF>.

=head2 FD_CLOEXEC

  static method FD_CLOEXEC : int ();

Get the constant value of C<FD_CLOEXEC>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 F_ADD_SEALS

  static method F_ADD_SEALS : int ();

Get the constant value of C<F_ADD_SEALS>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 F_DUPFD

  static method F_DUPFD : int ();

Get the constant value of C<F_DUPFD>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 F_DUPFD_CLOEXEC

  static method F_DUPFD_CLOEXEC : int ();

Get the constant value of C<F_DUPFD_CLOEXEC>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 F_GETFD

  static method F_GETFD : int ();

Get the constant value of C<F_GETFD>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 F_GETFL

  static method F_GETFL : int ();

Get the constant value of C<F_GETFL>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 F_GETLEASE

  static method F_GETLEASE : int ();

Get the constant value of C<F_GETLEASE>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 F_GETLK

  static method F_GETLK : int ();

Get the constant value of C<F_GETLK>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 F_GETLK64

  static method F_GETLK64 : int ();

Get the constant value of C<F_GETLK64>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 F_GETOWN

  static method F_GETOWN : int ();

Get the constant value of C<F_GETOWN>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 F_GETOWN_EX

  static method F_GETOWN_EX : int ();

Get the constant value of C<F_GETOWN_EX>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 F_GETPIPE_SZ

  static method F_GETPIPE_SZ : int ();

Get the constant value of C<F_GETPIPE_SZ>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 F_GETSIG

  static method F_GETSIG : int ();

Get the constant value of C<F_GETSIG>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 F_GET_FILE_RW_HINT

  static method F_GET_FILE_RW_HINT : int ();

Get the constant value of C<F_GET_FILE_RW_HINT>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 F_GET_RW_HINT

  static method F_GET_RW_HINT : int ();

Get the constant value of C<F_GET_RW_HINT>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 F_GET_SEALS

  static method F_GET_SEALS : int ();

Get the constant value of C<F_GET_SEALS>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 F_NOTIFY

  static method F_NOTIFY : int ();

Get the constant value of C<F_NOTIFY>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 F_OFD_GETLK

  static method F_OFD_GETLK : int ();

Get the constant value of C<F_OFD_GETLK>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 F_OFD_SETLK

  static method F_OFD_SETLK : int ();

Get the constant value of C<F_OFD_SETLK>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 F_OFD_SETLKW

  static method F_OFD_SETLKW : int ();

Get the constant value of C<F_OFD_SETLKW>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 F_OK

  static method F_OK : int ();

Get the constant value of C<F_OK>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 F_OWNER_PGRP

  static method F_OWNER_PGRP : int ();

Get the constant value of C<F_OWNER_PGRP>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 F_OWNER_PID

  static method F_OWNER_PID : int ();

Get the constant value of C<F_OWNER_PID>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 F_OWNER_TID

  static method F_OWNER_TID : int ();

Get the constant value of C<F_OWNER_TID>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 F_RDLCK

  static method F_RDLCK : int ();

Get the constant value of C<F_RDLCK>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 F_SEAL_FUTURE_WRITE

  static method F_SEAL_FUTURE_WRITE : int ();

Get the constant value of C<F_SEAL_FUTURE_WRITE>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 F_SEAL_GROW

  static method F_SEAL_GROW : int ();

Get the constant value of C<F_SEAL_GROW>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 F_SEAL_SEAL

  static method F_SEAL_SEAL : int ();

Get the constant value of C<F_SEAL_SEAL>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 F_SEAL_SHRINK

  static method F_SEAL_SHRINK : int ();

Get the constant value of C<F_SEAL_SHRINK>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 F_SEAL_WRITE

  static method F_SEAL_WRITE : int ();

Get the constant value of C<F_SEAL_WRITE>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 F_SETFD

  static method F_SETFD : int ();

Get the constant value of C<F_SETFD>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 F_SETFL

  static method F_SETFL : int ();

Get the constant value of C<F_SETFL>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 F_SETLEASE

  static method F_SETLEASE : int ();

Get the constant value of C<F_SETLEASE>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 F_SETLK

  static method F_SETLK : int ();

Get the constant value of C<F_SETLK>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 F_SETLK64

  static method F_SETLK64 : int ();

Get the constant value of C<F_SETLK64>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 F_SETLKW

  static method F_SETLKW : int ();

Get the constant value of C<F_SETLKW>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 F_SETLKW64

  static method F_SETLKW64 : int ();

Get the constant value of C<F_SETLKW64>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 F_SETOWN

  static method F_SETOWN : int ();

Get the constant value of C<F_SETOWN>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 F_SETOWN_EX

  static method F_SETOWN_EX : int ();

Get the constant value of C<F_SETOWN_EX>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 F_SETPIPE_SZ

  static method F_SETPIPE_SZ : int ();

Get the constant value of C<F_SETPIPE_SZ>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 F_SETSIG

  static method F_SETSIG : int ();

Get the constant value of C<F_SETSIG>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 F_SET_FILE_RW_HINT

  static method F_SET_FILE_RW_HINT : int ();

Get the constant value of C<F_SET_FILE_RW_HINT>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 F_SET_RW_HINT

  static method F_SET_RW_HINT : int ();

Get the constant value of C<F_SET_RW_HINT>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 F_UNLCK

  static method F_UNLCK : int ();

Get the constant value of C<F_UNLCK>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 F_WRLCK

  static method F_WRLCK : int ();

Get the constant value of C<F_WRLCK>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 LOCK_EX

  static method LOCK_EX : int ();

Get the constant value of C<LOCK_EX>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 LOCK_SH

  static method LOCK_SH : int ();

Get the constant value of C<LOCK_SH>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 LOCK_UN

  static method LOCK_UN : int ();

Get the constant value of C<LOCK_UN>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 O_APPEND

  static method O_APPEND : int ();

Get the constant value of C<O_APPEND>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 O_ASYNC

  static method O_ASYNC : int ();

Get the constant value of C<O_ASYNC>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 O_CLOEXEC

  static method O_CLOEXEC : int ();

Get the constant value of C<O_CLOEXEC>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 O_CREAT

  static method O_CREAT : int ();

Get the constant value of C<O_CREAT>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 O_DIRECT

  static method O_DIRECT : int ();

Get the constant value of C<O_DIRECT>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 O_DIRECTORY

  static method O_DIRECTORY : int ();

Get the constant value of C<O_DIRECTORY>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 O_DSYNC

  static method O_DSYNC : int ();

Get the constant value of C<O_DSYNC>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 O_EXCL

  static method O_EXCL : int ();

Get the constant value of C<O_EXCL>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 O_EXEC

  static method O_EXEC : int ();

Get the constant value of C<O_EXEC>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 O_LARGEFILE

  static method O_LARGEFILE : int ();

Get the constant value of C<O_LARGEFILE>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 O_NDELAY

  static method O_NDELAY : int ();

Get the constant value of C<O_NDELAY>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 O_NOATIME

  static method O_NOATIME : int ();

Get the constant value of C<O_NOATIME>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 O_NOCTTY

  static method O_NOCTTY : int ();

Get the constant value of C<O_NOCTTY>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 O_NOFOLLOW

  static method O_NOFOLLOW : int ();

Get the constant value of C<O_NOFOLLOW>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 O_NONBLOCK

  static method O_NONBLOCK : int ();

Get the constant value of C<O_NONBLOCK>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 O_PATH

  static method O_PATH : int ();

Get the constant value of C<O_PATH>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 O_RDONLY

  static method O_RDONLY : int ();

Get the constant value of C<O_RDONLY>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 O_RDWR

  static method O_RDWR : int ();

Get the constant value of C<O_RDWR>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 O_RSYNC

  static method O_RSYNC : int ();

Get the constant value of C<O_RSYNC>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 O_SYNC

  static method O_SYNC : int ();

Get the constant value of C<O_SYNC>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 O_TMPFILE

  static method O_TMPFILE : int ();

Get the constant value of C<O_TMPFILE>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 O_TRUNC

  static method O_TRUNC : int ();

Get the constant value of C<O_TRUNC>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 O_WRONLY

  static method O_WRONLY : int ();

Get the constant value of C<O_WRONLY>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 R_OK

  static method R_OK : int ();

Get the constant value of C<R_OK>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SEEK_CUR

  static method SEEK_CUR : int ();

Get the constant value of C<SEEK_CUR>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SEEK_DATA

  static method SEEK_DATA : int ();

Get the constant value of C<SEEK_DATA>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SEEK_END

  static method SEEK_END : int ();

Get the constant value of C<SEEK_END>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SEEK_HOLE

  static method SEEK_HOLE : int ();

Get the constant value of C<SEEK_HOLE>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SEEK_SET

  static method SEEK_SET : int ();

Get the constant value of C<SEEK_SET>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 S_CDF

  static method S_CDF : int ();

Get the constant value of C<S_CDF>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 S_ENFMT

  static method S_ENFMT : int ();

Get the constant value of C<S_ENFMT>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 S_IF

  static method S_IF : int ();

Get the constant value of C<S_IF>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 S_IFBLK

  static method S_IFBLK : int ();

Get the constant value of C<S_IFBLK>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 S_IFCHR

  static method S_IFCHR : int ();

Get the constant value of C<S_IFCHR>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 S_IFCMP

  static method S_IFCMP : int ();

Get the constant value of C<S_IFCMP>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 S_IFDIR

  static method S_IFDIR : int ();

Get the constant value of C<S_IFDIR>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 S_IFDOOR

  static method S_IFDOOR : int ();

Get the constant value of C<S_IFDOOR>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 S_IFIFO

  static method S_IFIFO : int ();

Get the constant value of C<S_IFIFO>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 S_IFLNK

  static method S_IFLNK : int ();

Get the constant value of C<S_IFLNK>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 S_IFMPB

  static method S_IFMPB : int ();

Get the constant value of C<S_IFMPB>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 S_IFMPC

  static method S_IFMPC : int ();

Get the constant value of C<S_IFMPC>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 S_IFMT

  static method S_IFMT : int ();

Get the constant value of C<S_IFMT>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 S_IFNAM

  static method S_IFNAM : int ();

Get the constant value of C<S_IFNAM>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 S_IFNWK

  static method S_IFNWK : int ();

Get the constant value of C<S_IFNWK>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 S_IFREG

  static method S_IFREG : int ();

Get the constant value of C<S_IFREG>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 S_IFSHAD

  static method S_IFSHAD : int ();

Get the constant value of C<S_IFSHAD>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 S_IFSOCK

  static method S_IFSOCK : int ();

Get the constant value of C<S_IFSOCK>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 S_IFWHT

  static method S_IFWHT : int ();

Get the constant value of C<S_IFWHT>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 S_INSEM

  static method S_INSEM : int ();

Get the constant value of C<S_INSEM>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 S_INSHD

  static method S_INSHD : int ();

Get the constant value of C<S_INSHD>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 S_IREAD

  static method S_IREAD : int ();

Get the constant value of C<S_IREAD>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 S_IRGRP

  static method S_IRGRP : int ();

Get the constant value of C<S_IRGRP>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 S_IROTH

  static method S_IROTH : int ();

Get the constant value of C<S_IROTH>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 S_IRUSR

  static method S_IRUSR : int ();

Get the constant value of C<S_IRUSR>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 S_IRWXG

  static method S_IRWXG : int ();

Get the constant value of C<S_IRWXG>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 S_IRWXO

  static method S_IRWXO : int ();

Get the constant value of C<S_IRWXO>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 S_IRWXU

  static method S_IRWXU : int ();

Get the constant value of C<S_IRWXU>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 S_ISBLK

  static method S_ISBLK : int ();

Get the constant value of C<S_ISBLK>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 S_ISCHR

  static method S_ISCHR : int ();

Get the constant value of C<S_ISCHR>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 S_ISDIR

  static method S_ISDIR : int ();

Get the constant value of C<S_ISDIR>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 S_ISFIFO

  static method S_ISFIFO : int ();

Get the constant value of C<S_ISFIFO>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 S_ISGID

  static method S_ISGID : int ();

Get the constant value of C<S_ISGID>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 S_ISLNK

  static method S_ISLNK : int ();

Get the constant value of C<S_ISLNK>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 S_ISREG

  static method S_ISREG : int ();

Get the constant value of C<S_ISREG>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 S_ISSOCK

  static method S_ISSOCK : int ();

Get the constant value of C<S_ISSOCK>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 S_ISUID

  static method S_ISUID : int ();

Get the constant value of C<S_ISUID>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 S_ISVTX

  static method S_ISVTX : int ();

Get the constant value of C<S_ISVTX>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 S_IWGRP

  static method S_IWGRP : int ();

Get the constant value of C<S_IWGRP>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 S_IWOTH

  static method S_IWOTH : int ();

Get the constant value of C<S_IWOTH>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 S_IWUSR

  static method S_IWUSR : int ();

Get the constant value of C<S_IWUSR>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 S_IXGRP

  static method S_IXGRP : int ();

Get the constant value of C<S_IXGRP>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 S_IXOTH

  static method S_IXOTH : int ();

Get the constant value of C<S_IXOTH>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 S_IXUSR

  static method S_IXUSR : int ();

Get the constant value of C<S_IXUSR>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 W_OK

  static method W_OK : int ();

Get the constant value of C<W_OK>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 X_OK

  static method X_OK : int ();

Get the constant value of C<X_OK>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 POLLERR

  static method POLLERR : int ();

Get the constant value of C<POLLERR>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 POLLHUP

  static method POLLHUP : int ();

Get the constant value of C<POLLHUP>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 POLLIN

  static method POLLIN : int ();

Get the constant value of C<POLLIN>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 POLLNVAL

  static method POLLNVAL : int ();

Get the constant value of C<POLLNVAL>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 POLLOUT

  static method POLLOUT : int ();

Get the constant value of C<POLLOUT>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 POLLPRI

  static method POLLPRI : int ();

Get the constant value of C<POLLPRI>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 POLLRDBAND

  static method POLLRDBAND : int ();

Get the constant value of C<POLLRDBAND>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 POLLRDNORM

  static method POLLRDNORM : int ();

Get the constant value of C<POLLRDNORM>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 POLLWRBAND

  static method POLLWRBAND : int ();

Get the constant value of C<POLLWRBAND>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 POLLWRNORM

  static method POLLWRNORM : int ();

Get the constant value of C<POLLWRNORM>. If the system doesn't define this constant, an exception will be thrown. The error code is set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head1 Copyright & License

Copyright 2022-2022 Yuki Kimoto, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

