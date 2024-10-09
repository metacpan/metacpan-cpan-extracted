package SPVM::Sys::IO::Constant;

1;

=head1 Name

SPVM::Sys::IO::Constant - Constant values for File IO.

=head1 Description

Sys::IO::Constant class in L<SPVM> has method to get constant values for File IO.

=head1 Usage

  use Sys::IO::Constant;

=head1 Class Methods

=head2 AT_EMPTY_PATH

C<static method AT_EMPTY_PATH : int ();>

Gets the value of C<AT_EMPTY_PATH>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 AT_FDCWD

C<static method AT_FDCWD : int ();>

Gets the value of C<AT_FDCWD>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 AT_NO_AUTOMOUNT

C<static method AT_NO_AUTOMOUNT : int ();>

Gets the value of C<AT_NO_AUTOMOUNT>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 AT_SYMLINK_FOLLOW

C<static method AT_SYMLINK_FOLLOW : int ();>

Gets the value of C<AT_SYMLINK_FOLLOW>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 AT_SYMLINK_NOFOLLOW

C<static method AT_SYMLINK_NOFOLLOW : int ();>

Gets the value of C<AT_SYMLINK_NOFOLLOW>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 CAP_CHOWN

C<static method CAP_CHOWN : int ();>

Gets the value of C<CAP_CHOWN>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 CAP_DAC_READ_SEARCH

C<static method CAP_DAC_READ_SEARCH : int ();>

Gets the value of C<CAP_DAC_READ_SEARCH>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 CAP_FOWNER

C<static method CAP_FOWNER : int ();>

Gets the value of C<CAP_FOWNER>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 CAP_FSETID

C<static method CAP_FSETID : int ();>

Gets the value of C<CAP_FSETID>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 CAP_LEASE

C<static method CAP_LEASE : int ();>

Gets the value of C<CAP_LEASE>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 CAP_SYS_RESOURCE

C<static method CAP_SYS_RESOURCE : int ();>

Gets the value of C<CAP_SYS_RESOURCE>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 DN_ACCESS

C<static method DN_ACCESS : int ();>

Gets the value of C<DN_ACCESS>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 DN_ATTRIB

C<static method DN_ATTRIB : int ();>

Gets the value of C<DN_ATTRIB>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 DN_CREATE

C<static method DN_CREATE : int ();>

Gets the value of C<DN_CREATE>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 DN_DELETE

C<static method DN_DELETE : int ();>

Gets the value of C<DN_DELETE>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 DN_MODIFY

C<static method DN_MODIFY : int ();>

Gets the value of C<DN_MODIFY>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 DN_MULTISHOT

C<static method DN_MULTISHOT : int ();>

Gets the value of C<DN_MULTISHOT>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 DN_RENAME

C<static method DN_RENAME : int ();>

Gets the value of C<DN_RENAME>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EOF

C<static method EOF : int ();>

Gets the value of C<EOF>.

=head2 FD_CLOEXEC

C<static method FD_CLOEXEC : int ();>

Gets the value of C<FD_CLOEXEC>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 F_ADD_SEALS

C<static method F_ADD_SEALS : int ();>

Gets the value of C<F_ADD_SEALS>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 F_DUPFD

C<static method F_DUPFD : int ();>

Gets the value of C<F_DUPFD>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 F_DUPFD_CLOEXEC

C<static method F_DUPFD_CLOEXEC : int ();>

Gets the value of C<F_DUPFD_CLOEXEC>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 F_GETFD

C<static method F_GETFD : int ();>

Gets the value of C<F_GETFD>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 F_GETFL

C<static method F_GETFL : int ();>

Gets the value of C<F_GETFL>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 F_GETLEASE

C<static method F_GETLEASE : int ();>

Gets the value of C<F_GETLEASE>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 F_GETLK

C<static method F_GETLK : int ();>

Gets the value of C<F_GETLK>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 F_GETLK64

C<static method F_GETLK64 : int ();>

Gets the value of C<F_GETLK64>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 F_GETOWN

C<static method F_GETOWN : int ();>

Gets the value of C<F_GETOWN>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 F_GETOWN_EX

C<static method F_GETOWN_EX : int ();>

Gets the value of C<F_GETOWN_EX>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 F_GETPIPE_SZ

C<static method F_GETPIPE_SZ : int ();>

Gets the value of C<F_GETPIPE_SZ>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 F_GETSIG

C<static method F_GETSIG : int ();>

Gets the value of C<F_GETSIG>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 F_GET_FILE_RW_HINT

C<static method F_GET_FILE_RW_HINT : int ();>

Gets the value of C<F_GET_FILE_RW_HINT>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 F_GET_RW_HINT

C<static method F_GET_RW_HINT : int ();>

Gets the value of C<F_GET_RW_HINT>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 F_GET_SEALS

C<static method F_GET_SEALS : int ();>

Gets the value of C<F_GET_SEALS>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 F_NOTIFY

C<static method F_NOTIFY : int ();>

Gets the value of C<F_NOTIFY>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 F_OFD_GETLK

C<static method F_OFD_GETLK : int ();>

Gets the value of C<F_OFD_GETLK>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 F_OFD_SETLK

C<static method F_OFD_SETLK : int ();>

Gets the value of C<F_OFD_SETLK>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 F_OFD_SETLKW

C<static method F_OFD_SETLKW : int ();>

Gets the value of C<F_OFD_SETLKW>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 F_OK

C<static method F_OK : int ();>

Gets the value of C<F_OK>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 F_OWNER_PGRP

C<static method F_OWNER_PGRP : int ();>

Gets the value of C<F_OWNER_PGRP>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 F_OWNER_PID

C<static method F_OWNER_PID : int ();>

Gets the value of C<F_OWNER_PID>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 F_OWNER_TID

C<static method F_OWNER_TID : int ();>

Gets the value of C<F_OWNER_TID>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 F_RDLCK

C<static method F_RDLCK : int ();>

Gets the value of C<F_RDLCK>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 F_SEAL_FUTURE_WRITE

C<static method F_SEAL_FUTURE_WRITE : int ();>

Gets the value of C<F_SEAL_FUTURE_WRITE>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 F_SEAL_GROW

C<static method F_SEAL_GROW : int ();>

Gets the value of C<F_SEAL_GROW>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 F_SEAL_SEAL

C<static method F_SEAL_SEAL : int ();>

Gets the value of C<F_SEAL_SEAL>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 F_SEAL_SHRINK

C<static method F_SEAL_SHRINK : int ();>

Gets the value of C<F_SEAL_SHRINK>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 F_SEAL_WRITE

C<static method F_SEAL_WRITE : int ();>

Gets the value of C<F_SEAL_WRITE>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 F_SETFD

C<static method F_SETFD : int ();>

Gets the value of C<F_SETFD>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 F_SETFL

C<static method F_SETFL : int ();>

Gets the value of C<F_SETFL>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 F_SETLEASE

C<static method F_SETLEASE : int ();>

Gets the value of C<F_SETLEASE>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 F_SETLK

C<static method F_SETLK : int ();>

Gets the value of C<F_SETLK>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 F_SETLK64

C<static method F_SETLK64 : int ();>

Gets the value of C<F_SETLK64>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 F_SETLKW

C<static method F_SETLKW : int ();>

Gets the value of C<F_SETLKW>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 F_SETLKW64

C<static method F_SETLKW64 : int ();>

Gets the value of C<F_SETLKW64>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 F_SETOWN

C<static method F_SETOWN : int ();>

Gets the value of C<F_SETOWN>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 F_SETOWN_EX

C<static method F_SETOWN_EX : int ();>

Gets the value of C<F_SETOWN_EX>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 F_SETPIPE_SZ

C<static method F_SETPIPE_SZ : int ();>

Gets the value of C<F_SETPIPE_SZ>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 F_SETSIG

C<static method F_SETSIG : int ();>

Gets the value of C<F_SETSIG>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 F_SET_FILE_RW_HINT

C<static method F_SET_FILE_RW_HINT : int ();>

Gets the value of C<F_SET_FILE_RW_HINT>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 F_SET_RW_HINT

C<static method F_SET_RW_HINT : int ();>

Gets the value of C<F_SET_RW_HINT>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 F_UNLCK

C<static method F_UNLCK : int ();>

Gets the value of C<F_UNLCK>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 F_WRLCK

C<static method F_WRLCK : int ();>

Gets the value of C<F_WRLCK>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 LOCK_EX

C<static method LOCK_EX : int ();>

Gets the value of C<LOCK_EX>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 LOCK_SH

C<static method LOCK_SH : int ();>

Gets the value of C<LOCK_SH>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 LOCK_UN

C<static method LOCK_UN : int ();>

Gets the value of C<LOCK_UN>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 O_APPEND

C<static method O_APPEND : int ();>

Gets the value of C<O_APPEND>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 O_ASYNC

C<static method O_ASYNC : int ();>

Gets the value of C<O_ASYNC>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 O_CLOEXEC

C<static method O_CLOEXEC : int ();>

Gets the value of C<O_CLOEXEC>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 O_CREAT

C<static method O_CREAT : int ();>

Gets the value of C<O_CREAT>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 O_DIRECT

C<static method O_DIRECT : int ();>

Gets the value of C<O_DIRECT>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 O_DIRECTORY

C<static method O_DIRECTORY : int ();>

Gets the value of C<O_DIRECTORY>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 O_DSYNC

C<static method O_DSYNC : int ();>

Gets the value of C<O_DSYNC>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 O_EXCL

C<static method O_EXCL : int ();>

Gets the value of C<O_EXCL>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 O_EXEC

C<static method O_EXEC : int ();>

Gets the value of C<O_EXEC>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 O_LARGEFILE

C<static method O_LARGEFILE : int ();>

Gets the value of C<O_LARGEFILE>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 O_NDELAY

C<static method O_NDELAY : int ();>

Gets the value of C<O_NDELAY>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 O_NOATIME

C<static method O_NOATIME : int ();>

Gets the value of C<O_NOATIME>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 O_NOCTTY

C<static method O_NOCTTY : int ();>

Gets the value of C<O_NOCTTY>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 O_NOFOLLOW

C<static method O_NOFOLLOW : int ();>

Gets the value of C<O_NOFOLLOW>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 O_NONBLOCK

C<static method O_NONBLOCK : int ();>

Gets the value of C<O_NONBLOCK>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 O_PATH

C<static method O_PATH : int ();>

Gets the value of C<O_PATH>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 O_RDONLY

C<static method O_RDONLY : int ();>

Gets the value of C<O_RDONLY>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 O_RDWR

C<static method O_RDWR : int ();>

Gets the value of C<O_RDWR>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 O_RSYNC

C<static method O_RSYNC : int ();>

Gets the value of C<O_RSYNC>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 O_SYNC

C<static method O_SYNC : int ();>

Gets the value of C<O_SYNC>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 O_TMPFILE

C<static method O_TMPFILE : int ();>

Gets the value of C<O_TMPFILE>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 O_TRUNC

C<static method O_TRUNC : int ();>

Gets the value of C<O_TRUNC>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 O_WRONLY

C<static method O_WRONLY : int ();>

Gets the value of C<O_WRONLY>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 R_OK

C<static method R_OK : int ();>

Gets the value of C<R_OK>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SEEK_CUR

C<static method SEEK_CUR : int ();>

Gets the value of C<SEEK_CUR>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SEEK_DATA

C<static method SEEK_DATA : int ();>

Gets the value of C<SEEK_DATA>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SEEK_END

C<static method SEEK_END : int ();>

Gets the value of C<SEEK_END>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SEEK_HOLE

C<static method SEEK_HOLE : int ();>

Gets the value of C<SEEK_HOLE>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 SEEK_SET

C<static method SEEK_SET : int ();>

Gets the value of C<SEEK_SET>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 S_CDF

C<static method S_CDF : int ();>

Gets the value of C<S_CDF>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 S_ENFMT

C<static method S_ENFMT : int ();>

Gets the value of C<S_ENFMT>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 S_IF

C<static method S_IF : int ();>

Gets the value of C<S_IF>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 S_IFBLK

C<static method S_IFBLK : int ();>

Gets the value of C<S_IFBLK>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 S_IFCHR

C<static method S_IFCHR : int ();>

Gets the value of C<S_IFCHR>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 S_IFCMP

C<static method S_IFCMP : int ();>

Gets the value of C<S_IFCMP>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 S_IFDIR

C<static method S_IFDIR : int ();>

Gets the value of C<S_IFDIR>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 S_IFDOOR

C<static method S_IFDOOR : int ();>

Gets the value of C<S_IFDOOR>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 S_IFIFO

C<static method S_IFIFO : int ();>

Gets the value of C<S_IFIFO>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 S_IFLNK

C<static method S_IFLNK : int ();>

Gets the value of C<S_IFLNK>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 S_IFMPB

C<static method S_IFMPB : int ();>

Gets the value of C<S_IFMPB>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 S_IFMPC

C<static method S_IFMPC : int ();>

Gets the value of C<S_IFMPC>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 S_IFMT

C<static method S_IFMT : int ();>

Gets the value of C<S_IFMT>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 S_IFNAM

C<static method S_IFNAM : int ();>

Gets the value of C<S_IFNAM>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 S_IFNWK

C<static method S_IFNWK : int ();>

Gets the value of C<S_IFNWK>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 S_IFREG

C<static method S_IFREG : int ();>

Gets the value of C<S_IFREG>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 S_IFSHAD

C<static method S_IFSHAD : int ();>

Gets the value of C<S_IFSHAD>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 S_IFSOCK

C<static method S_IFSOCK : int ();>

Gets the value of C<S_IFSOCK>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 S_IFWHT

C<static method S_IFWHT : int ();>

Gets the value of C<S_IFWHT>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 S_INSEM

C<static method S_INSEM : int ();>

Gets the value of C<S_INSEM>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 S_INSHD

C<static method S_INSHD : int ();>

Gets the value of C<S_INSHD>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 S_IREAD

C<static method S_IREAD : int ();>

Gets the value of C<S_IREAD>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 S_IRGRP

C<static method S_IRGRP : int ();>

Gets the value of C<S_IRGRP>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 S_IROTH

C<static method S_IROTH : int ();>

Gets the value of C<S_IROTH>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 S_IRUSR

C<static method S_IRUSR : int ();>

Gets the value of C<S_IRUSR>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 S_IRWXG

C<static method S_IRWXG : int ();>

Gets the value of C<S_IRWXG>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 S_IRWXO

C<static method S_IRWXO : int ();>

Gets the value of C<S_IRWXO>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 S_IRWXU

C<static method S_IRWXU : int ();>

Gets the value of C<S_IRWXU>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 S_ISBLK

C<static method S_ISBLK : int ();>

Gets the value of C<S_ISBLK>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 S_ISCHR

C<static method S_ISCHR : int ();>

Gets the value of C<S_ISCHR>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 S_ISDIR

C<static method S_ISDIR : int ();>

Gets the value of C<S_ISDIR>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 S_ISFIFO

C<static method S_ISFIFO : int ();>

Gets the value of C<S_ISFIFO>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 S_ISGID

C<static method S_ISGID : int ();>

Gets the value of C<S_ISGID>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 S_ISLNK

C<static method S_ISLNK : int ();>

Gets the value of C<S_ISLNK>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 S_ISREG

C<static method S_ISREG : int ();>

Gets the value of C<S_ISREG>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 S_ISSOCK

C<static method S_ISSOCK : int ();>

Gets the value of C<S_ISSOCK>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 S_ISUID

C<static method S_ISUID : int ();>

Gets the value of C<S_ISUID>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 S_ISVTX

C<static method S_ISVTX : int ();>

Gets the value of C<S_ISVTX>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 S_IWGRP

C<static method S_IWGRP : int ();>

Gets the value of C<S_IWGRP>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 S_IWOTH

C<static method S_IWOTH : int ();>

Gets the value of C<S_IWOTH>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 S_IWUSR

C<static method S_IWUSR : int ();>

Gets the value of C<S_IWUSR>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 S_IXGRP

C<static method S_IXGRP : int ();>

Gets the value of C<S_IXGRP>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 S_IXOTH

C<static method S_IXOTH : int ();>

Gets the value of C<S_IXOTH>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 S_IXUSR

C<static method S_IXUSR : int ();>

Gets the value of C<S_IXUSR>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 W_OK

C<static method W_OK : int ();>

Gets the value of C<W_OK>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 X_OK

C<static method X_OK : int ();>

Gets the value of C<X_OK>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 AT_EACCESS

C<static method AT_EACCESS : int ();>

Gets the value of C<AT_EACCESS>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 STDIN_FILENO

C<static method STDIN_FILENO : int ();>

Gets the value of C<STDIN_FILENO>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 STDOUT_FILENO

C<static method STDOUT_FILENO : int ();>

Gets the value of C<STDOUT_FILENO>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 STDERR_FILENO

C<static method STDERR_FILENO : int ();>

Gets the value of C<STDERR_FILENO>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 BUFSIZ

C<static method BUFSIZ : int ();>

Gets the value of C<BUFSIZ>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 _IONBF

C<static method _IONBF : int ();>

Gets the value of C<_IONBF>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 _IOLBF

C<static method _IOLBF : int ();>

Gets the value of C<_IOLBF>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 _IOFBF

C<static method _IOFBF : int ();>

Gets the value of C<_IOFBF>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 O_BINARY

C<static method O_BINARY : int ();>

Gets the value of C<O_BINARY>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 O_TEXT

C<static method O_TEXT : int ();>

Gets the value of C<O_TEXT>. If the value is not defined in this system, an exception is thrown with C<eval_error_id> set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.


=head1 Copyright & License

Copyright (c) 2023 Yuki Kimoto

MIT License

