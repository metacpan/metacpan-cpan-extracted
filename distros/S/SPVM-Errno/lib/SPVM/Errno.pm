package SPVM::Errno;

our $VERSION = "0.090003";

1;

=head1 Name

SPVM::Errno - Error Numbers

=head1 Description

The Errno class of L<SPVM> has methods for error numbers defined in the C<errno.h> header of the C language.

=head1 Usage

  use Errno;
  
  my $errno = Errno->errno;
  
  my $eagain = Errno->EAGAIN;

=head2 errno

C<static method errno : int ();>

Gets the current error number.

This is the same operation as getting C<errno> in the C language.

=head2 E2BIG

C<static method E2BIG : int ();>

Gets the value of C<E2BIG>.

Exceptions:

If the system does not define this error number, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EACCES

C<static method EACCES : int ();>

Gets the value of C<EACCES>.

Exceptions:

If the system does not define this error number, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EADDRINUSE

C<static method EADDRINUSE : int ();>

Gets the value of C<EADDRINUSE>.

Exceptions:

If the system does not define this error number, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EADDRNOTAVAIL

C<static method EADDRNOTAVAIL : int ();>

Gets the value of C<EADDRNOTAVAIL>.

Exceptions:

If the system does not define this error number, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EAFNOSUPPORT

C<static method EAFNOSUPPORT : int ();>

Gets the value of C<EAFNOSUPPORT>.

Exceptions:

If the system does not define this error number, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EAGAIN

C<static method EAGAIN : int ();>

Gets the value of C<EAGAIN>.

Exceptions:

If the system does not define this error number, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EALREADY

C<static method EALREADY : int ();>

Gets the value of C<EALREADY>.

Exceptions:

If the system does not define this error number, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EBADE

C<static method EBADE : int ();>

Gets the value of C<EBADE>.

Exceptions:

If the system does not define this error number, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EBADF

C<static method EBADF : int ();>

Gets the value of C<EBADF>.

Exceptions:

If the system does not define this error number, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EBADFD

C<static method EBADFD : int ();>

Gets the value of C<EBADFD>.

Exceptions:

If the system does not define this error number, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EBADMSG

C<static method EBADMSG : int ();>

Gets the value of C<EBADMSG>.

Exceptions:

If the system does not define this error number, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EBADR

C<static method EBADR : int ();>

Gets the value of C<EBADR>.

Exceptions:

If the system does not define this error number, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EBADRQC

C<static method EBADRQC : int ();>

Gets the value of C<EBADRQC>.

Exceptions:

If the system does not define this error number, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EBADSLT

C<static method EBADSLT : int ();>

Gets the value of C<EBADSLT>.

Exceptions:

If the system does not define this error number, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EBUSY

C<static method EBUSY : int ();>

Gets the value of C<EBUSY>.

Exceptions:

If the system does not define this error number, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ECANCELED

C<static method ECANCELED : int ();>

Gets the value of C<ECANCELED>.

Exceptions:

If the system does not define this error number, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ECHILD

C<static method ECHILD : int ();>

Gets the value of C<ECHILD>.

Exceptions:

If the system does not define this error number, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ECHRNG

C<static method ECHRNG : int ();>

Gets the value of C<ECHRNG>.

Exceptions:

If the system does not define this error number, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ECOMM

C<static method ECOMM : int ();>

Gets the value of C<ECOMM>.

Exceptions:

If the system does not define this error number, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ECONNABORTED

C<static method ECONNABORTED : int ();>

Gets the value of C<ECONNABORTED>.

Exceptions:

If the system does not define this error number, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ECONNREFUSED

C<static method ECONNREFUSED : int ();>

Gets the value of C<ECONNREFUSED>.

Exceptions:

If the system does not define this error number, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ECONNRESET

C<static method ECONNRESET : int ();>

Gets the value of C<ECONNRESET>.

Exceptions:

If the system does not define this error number, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EDEADLK

C<static method EDEADLK : int ();>

Gets the value of C<EDEADLK>.

Exceptions:

If the system does not define this error number, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EDEADLOCK

C<static method EDEADLOCK : int ();>

Gets the value of C<EDEADLOCK>.

Exceptions:

If the system does not define this error number, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EDESTADDRREQ

C<static method EDESTADDRREQ : int ();>

Gets the value of C<EDESTADDRREQ>.

Exceptions:

If the system does not define this error number, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EDOM

C<static method EDOM : int ();>

Gets the value of C<EDOM>.

Exceptions:

If the system does not define this error number, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EDQUOT

C<static method EDQUOT : int ();>

Gets the value of C<EDQUOT>.

Exceptions:

If the system does not define this error number, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EEXIST

C<static method EEXIST : int ();>

Gets the value of C<EEXIST>.

Exceptions:

If the system does not define this error number, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EFAULT

C<static method EFAULT : int ();>

Gets the value of C<EFAULT>.

Exceptions:

If the system does not define this error number, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EFBIG

C<static method EFBIG : int ();>

Gets the value of C<EFBIG>.

Exceptions:

If the system does not define this error number, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EHOSTDOWN

C<static method EHOSTDOWN : int ();>

Gets the value of C<EHOSTDOWN>.

Exceptions:

If the system does not define this error number, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EHOSTUNREACH

C<static method EHOSTUNREACH : int ();>

Gets the value of C<EHOSTUNREACH>.

Exceptions:

If the system does not define this error number, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EIDRM

C<static method EIDRM : int ();>

Gets the value of C<EIDRM>.

Exceptions:

If the system does not define this error number, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EILSEQ

C<static method EILSEQ : int ();>

Gets the value of C<EILSEQ>.

Exceptions:

If the system does not define this error number, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EINPROGRESS

C<static method EINPROGRESS : int ();>

Gets the value of C<EINPROGRESS>.

Exceptions:

If the system does not define this error number, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EINTR

C<static method EINTR : int ();>

Gets the value of C<EINTR>.

Exceptions:

If the system does not define this error number, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EINVAL

C<static method EINVAL : int ();>

Gets the value of C<EINVAL>.

Exceptions:

If the system does not define this error number, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EIO

C<static method EIO : int ();>

Gets the value of C<EIO>.

Exceptions:

If the system does not define this error number, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EISCONN

C<static method EISCONN : int ();>

Gets the value of C<EISCONN>.

Exceptions:

If the system does not define this error number, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EISDIR

C<static method EISDIR : int ();>

Gets the value of C<EISDIR>.

Exceptions:

If the system does not define this error number, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EISNAM

C<static method EISNAM : int ();>

Gets the value of C<EISNAM>.

Exceptions:

If the system does not define this error number, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EKEYEXPIRED

C<static method EKEYEXPIRED : int ();>

Gets the value of C<EKEYEXPIRED>.

Exceptions:

If the system does not define this error number, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EKEYREJECTED

C<static method EKEYREJECTED : int ();>

Gets the value of C<EKEYREJECTED>.

Exceptions:

If the system does not define this error number, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EKEYREVOKED

C<static method EKEYREVOKED : int ();>

Gets the value of C<EKEYREVOKED>.

Exceptions:

If the system does not define this error number, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EL2HLT

C<static method EL2HLT : int ();>

Gets the value of C<EL2HLT>.

Exceptions:

If the system does not define this error number, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EL2NSYNC

C<static method EL2NSYNC : int ();>

Gets the value of C<EL2NSYNC>.

Exceptions:

If the system does not define this error number, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EL3HLT

C<static method EL3HLT : int ();>

Gets the value of C<EL3HLT>.

Exceptions:

If the system does not define this error number, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EL3RST

C<static method EL3RST : int ();>

Gets the value of C<EL3RST>.

Exceptions:

If the system does not define this error number, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ELIBACC

C<static method ELIBACC : int ();>

Gets the value of C<ELIBACC>.

Exceptions:

If the system does not define this error number, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ELIBBAD

C<static method ELIBBAD : int ();>

Gets the value of C<ELIBBAD>.

Exceptions:

If the system does not define this error number, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ELIBMAX

C<static method ELIBMAX : int ();>

Gets the value of C<ELIBMAX>.

Exceptions:

If the system does not define this error number, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ELIBSCN

C<static method ELIBSCN : int ();>

Gets the value of C<ELIBSCN>.

Exceptions:

If the system does not define this error number, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ELIBEXEC

C<static method ELIBEXEC : int ();>

Gets the value of C<ELIBEXEC>.

Exceptions:

If the system does not define this error number, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ELOOP

C<static method ELOOP : int ();>

Gets the value of C<ELOOP>.

Exceptions:

If the system does not define this error number, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EMEDIUMTYPE

C<static method EMEDIUMTYPE : int ();>

Gets the value of C<EMEDIUMTYPE>.

Exceptions:

If the system does not define this error number, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EMFILE

C<static method EMFILE : int ();>

Gets the value of C<EMFILE>.

Exceptions:

If the system does not define this error number, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EMLINK

C<static method EMLINK : int ();>

Gets the value of C<EMLINK>.

Exceptions:

If the system does not define this error number, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EMSGSIZE

C<static method EMSGSIZE : int ();>

Gets the value of C<EMSGSIZE>.

Exceptions:

If the system does not define this error number, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EMULTIHOP

C<static method EMULTIHOP : int ();>

Gets the value of C<EMULTIHOP>.

Exceptions:

If the system does not define this error number, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ENAMETOOLONG

C<static method ENAMETOOLONG : int ();>

Gets the value of C<ENAMETOOLONG>.

Exceptions:

If the system does not define this error number, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ENETDOWN

C<static method ENETDOWN : int ();>

Gets the value of C<ENETDOWN>.

Exceptions:

If the system does not define this error number, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ENETRESET

C<static method ENETRESET : int ();>

Gets the value of C<ENETRESET>.

Exceptions:

If the system does not define this error number, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ENETUNREACH

C<static method ENETUNREACH : int ();>

Gets the value of C<ENETUNREACH>.

Exceptions:

If the system does not define this error number, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ENFILE

C<static method ENFILE : int ();>

Gets the value of C<ENFILE>.

Exceptions:

If the system does not define this error number, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ENOBUFS

C<static method ENOBUFS : int ();>

Gets the value of C<ENOBUFS>.

Exceptions:

If the system does not define this error number, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ENODATA

C<static method ENODATA : int ();>

Gets the value of C<ENODATA>.

Exceptions:

If the system does not define this error number, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ENODEV

C<static method ENODEV : int ();>

Gets the value of C<ENODEV>.

Exceptions:

If the system does not define this error number, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ENOENT

C<static method ENOENT : int ();>

Gets the value of C<ENOENT>.

Exceptions:

If the system does not define this error number, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ENOEXEC

C<static method ENOEXEC : int ();>

Gets the value of C<ENOEXEC>.

Exceptions:

If the system does not define this error number, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ENOKEY

C<static method ENOKEY : int ();>

Gets the value of C<ENOKEY>.

Exceptions:

If the system does not define this error number, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ENOLCK

C<static method ENOLCK : int ();>

Gets the value of C<ENOLCK>.

Exceptions:

If the system does not define this error number, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ENOLINK

C<static method ENOLINK : int ();>

Gets the value of C<ENOLINK>.

Exceptions:

If the system does not define this error number, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ENOMEDIUM

C<static method ENOMEDIUM : int ();>

Gets the value of C<ENOMEDIUM>.

Exceptions:

If the system does not define this error number, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ENOMEM

C<static method ENOMEM : int ();>

Gets the value of C<ENOMEM>.

Exceptions:

If the system does not define this error number, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ENOMSG

C<static method ENOMSG : int ();>

Gets the value of C<ENOMSG>.

Exceptions:

If the system does not define this error number, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ENONET

C<static method ENONET : int ();>

Gets the value of C<ENONET>.

Exceptions:

If the system does not define this error number, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ENOPKG

C<static method ENOPKG : int ();>

Gets the value of C<ENOPKG>.

Exceptions:

If the system does not define this error number, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ENOPROTOOPT

C<static method ENOPROTOOPT : int ();>

Gets the value of C<ENOPROTOOPT>.

Exceptions:

If the system does not define this error number, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ENOSPC

C<static method ENOSPC : int ();>

Gets the value of C<ENOSPC>.

Exceptions:

If the system does not define this error number, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ENOSR

C<static method ENOSR : int ();>

Gets the value of C<ENOSR>.

Exceptions:

If the system does not define this error number, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ENOSTR

C<static method ENOSTR : int ();>

Gets the value of C<ENOSTR>.

Exceptions:

If the system does not define this error number, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ENOSYS

C<static method ENOSYS : int ();>

Gets the value of C<ENOSYS>.

Exceptions:

If the system does not define this error number, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ENOTBLK

C<static method ENOTBLK : int ();>

Gets the value of C<ENOTBLK>.

Exceptions:

If the system does not define this error number, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ENOTCONN

C<static method ENOTCONN : int ();>

Gets the value of C<ENOTCONN>.

Exceptions:

If the system does not define this error number, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ENOTDIR

C<static method ENOTDIR : int ();>

Gets the value of C<ENOTDIR>.

Exceptions:

If the system does not define this error number, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ENOTEMPTY

C<static method ENOTEMPTY : int ();>

Gets the value of C<ENOTEMPTY>.

Exceptions:

If the system does not define this error number, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ENOTSOCK

C<static method ENOTSOCK : int ();>

Gets the value of C<ENOTSOCK>.

Exceptions:

If the system does not define this error number, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ENOTSUP

C<static method ENOTSUP : int ();>

Gets the value of C<ENOTSUP>.

Exceptions:

If the system does not define this error number, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ENOTTY

C<static method ENOTTY : int ();>

Gets the value of C<ENOTTY>.

Exceptions:

If the system does not define this error number, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ENOTUNIQ

C<static method ENOTUNIQ : int ();>

Gets the value of C<ENOTUNIQ>.

Exceptions:

If the system does not define this error number, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ENXIO

C<static method ENXIO : int ();>

Gets the value of C<ENXIO>.

Exceptions:

If the system does not define this error number, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EOPNOTSUPP

C<static method EOPNOTSUPP : int ();>

Gets the value of C<EOPNOTSUPP>.

Exceptions:

If the system does not define this error number, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EOVERFLOW

C<static method EOVERFLOW : int ();>

Gets the value of C<EOVERFLOW>.

Exceptions:

If the system does not define this error number, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EPERM

C<static method EPERM : int ();>

Gets the value of C<EPERM>.

Exceptions:

If the system does not define this error number, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EPFNOSUPPORT

C<static method EPFNOSUPPORT : int ();>

Gets the value of C<EPFNOSUPPORT>.

Exceptions:

If the system does not define this error number, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EPIPE

C<static method EPIPE : int ();>

Gets the value of C<EPIPE>.

Exceptions:

If the system does not define this error number, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EPROTO

C<static method EPROTO : int ();>

Gets the value of C<EPROTO>.

Exceptions:

If the system does not define this error number, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EPROTONOSUPPORT

C<static method EPROTONOSUPPORT : int ();>

Gets the value of C<EPROTONOSUPPORT>.

Exceptions:

If the system does not define this error number, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EPROTOTYPE

C<static method EPROTOTYPE : int ();>

Gets the value of C<EPROTOTYPE>.

Exceptions:

If the system does not define this error number, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ERANGE

C<static method ERANGE : int ();>

Gets the value of C<ERANGE>.

Exceptions:

If the system does not define this error number, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EREMCHG

C<static method EREMCHG : int ();>

Gets the value of C<EREMCHG>.

Exceptions:

If the system does not define this error number, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EREMOTE

C<static method EREMOTE : int ();>

Gets the value of C<EREMOTE>.

Exceptions:

If the system does not define this error number, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EREMOTEIO

C<static method EREMOTEIO : int ();>

Gets the value of C<EREMOTEIO>.

Exceptions:

If the system does not define this error number, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ERESTART

C<static method ERESTART : int ();>

Gets the value of C<ERESTART>.

Exceptions:

If the system does not define this error number, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EROFS

C<static method EROFS : int ();>

Gets the value of C<EROFS>.

Exceptions:

If the system does not define this error number, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ESHUTDOWN

C<static method ESHUTDOWN : int ();>

Gets the value of C<ESHUTDOWN>.

Exceptions:

If the system does not define this error number, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ESPIPE

C<static method ESPIPE : int ();>

Gets the value of C<ESPIPE>.

Exceptions:

If the system does not define this error number, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ESOCKTNOSUPPORT

C<static method ESOCKTNOSUPPORT : int ();>

Gets the value of C<ESOCKTNOSUPPORT>.

Exceptions:

If the system does not define this error number, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ESRCH

C<static method ESRCH : int ();>

Gets the value of C<ESRCH>.

Exceptions:

If the system does not define this error number, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ESTALE

C<static method ESTALE : int ();>

Gets the value of C<ESTALE>.

Exceptions:

If the system does not define this error number, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ESTRPIPE

C<static method ESTRPIPE : int ();>

Gets the value of C<ESTRPIPE>.

Exceptions:

If the system does not define this error number, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ETIME

C<static method ETIME : int ();>

Gets the value of C<ETIME>.

Exceptions:

If the system does not define this error number, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ETIMEDOUT

C<static method ETIMEDOUT : int ();>

Gets the value of C<ETIMEDOUT>.

Exceptions:

If the system does not define this error number, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ETXTBSY

C<static method ETXTBSY : int ();>

Gets the value of C<ETXTBSY>.

Exceptions:

If the system does not define this error number, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EUCLEAN

C<static method EUCLEAN : int ();>

Gets the value of C<EUCLEAN>.

Exceptions:

If the system does not define this error number, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EUNATCH

C<static method EUNATCH : int ();>

Gets the value of C<EUNATCH>.

Exceptions:

If the system does not define this error number, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EUSERS

C<static method EUSERS : int ();>

Gets the value of C<EUSERS>.

Exceptions:

If the system does not define this error number, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EWOULDBLOCK

C<static method EWOULDBLOCK : int ();>

Gets the value of C<EWOULDBLOCK>.

Exceptions:

If the system does not define this error number, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EXDEV

C<static method EXDEV : int ();>

Gets the value of C<EXDEV>.

Exceptions:

If the system does not define this error number, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EXFULL

C<static method EXFULL : int ();>

Gets the value of C<EXFULL>.

Exceptions:

If the system does not define this error number, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAEACCES

C<static method WSAEACCES : int ();>

Gets the value of C<WSAEACCES>.

Exceptions:

If the system does not define this constant value, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAEADDRINUSE

C<static method WSAEADDRINUSE : int ();>

Gets the value of C<WSAEADDRINUSE>.

Exceptions:

If the system does not define this constant value, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAEADDRNOTAVAIL

C<static method WSAEADDRNOTAVAIL : int ();>

Gets the value of C<WSAEADDRNOTAVAIL>.

Exceptions:

If the system does not define this constant value, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAEAFNOSUPPORT

C<static method WSAEAFNOSUPPORT : int ();>

Gets the value of C<WSAEAFNOSUPPORT>.

Exceptions:

If the system does not define this constant value, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAEALREADY

C<static method WSAEALREADY : int ();>

Gets the value of C<WSAEALREADY>.

Exceptions:

If the system does not define this constant value, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAEBADF

C<static method WSAEBADF : int ();>

Gets the value of C<WSAEBADF>.

Exceptions:

If the system does not define this constant value, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAECANCELLED

C<static method WSAECANCELLED : int ();>

Gets the value of C<WSAECANCELLED>.

Exceptions:

If the system does not define this constant value, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAECONNABORTED

C<static method WSAECONNABORTED : int ();>

Gets the value of C<WSAECONNABORTED>.

Exceptions:

If the system does not define this constant value, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAECONNREFUSED

C<static method WSAECONNREFUSED : int ();>

Gets the value of C<WSAECONNREFUSED>.

Exceptions:

If the system does not define this constant value, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAECONNRESET

C<static method WSAECONNRESET : int ();>

Gets the value of C<WSAECONNRESET>.

Exceptions:

If the system does not define this constant value, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAEDESTADDRREQ

C<static method WSAEDESTADDRREQ : int ();>

Gets the value of C<WSAEDESTADDRREQ>.

Exceptions:

If the system does not define this constant value, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAEDISCON

C<static method WSAEDISCON : int ();>

Gets the value of C<WSAEDISCON>.

Exceptions:

If the system does not define this constant value, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAEDQUOT

C<static method WSAEDQUOT : int ();>

Gets the value of C<WSAEDQUOT>.

Exceptions:

If the system does not define this constant value, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAEFAULT

C<static method WSAEFAULT : int ();>

Gets the value of C<WSAEFAULT>.

Exceptions:

If the system does not define this constant value, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAEHOSTDOWN

C<static method WSAEHOSTDOWN : int ();>

Gets the value of C<WSAEHOSTDOWN>.

Exceptions:

If the system does not define this constant value, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAEHOSTUNREACH

C<static method WSAEHOSTUNREACH : int ();>

Gets the value of C<WSAEHOSTUNREACH>.

Exceptions:

If the system does not define this constant value, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAEINPROGRESS

C<static method WSAEINPROGRESS : int ();>

Gets the value of C<WSAEINPROGRESS>.

Exceptions:

If the system does not define this constant value, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAEINTR

C<static method WSAEINTR : int ();>

Gets the value of C<WSAEINTR>.

Exceptions:

If the system does not define this constant value, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAEINVAL

C<static method WSAEINVAL : int ();>

Gets the value of C<WSAEINVAL>.

Exceptions:

If the system does not define this constant value, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAEINVALIDPROCTABLE

C<static method WSAEINVALIDPROCTABLE : int ();>

Gets the value of C<WSAEINVALIDPROCTABLE>.

Exceptions:

If the system does not define this constant value, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAEINVALIDPROVIDER

C<static method WSAEINVALIDPROVIDER : int ();>

Gets the value of C<WSAEINVALIDPROVIDER>.

Exceptions:

If the system does not define this constant value, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAEISCONN

C<static method WSAEISCONN : int ();>

Gets the value of C<WSAEISCONN>.

Exceptions:

If the system does not define this constant value, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAELOOP

C<static method WSAELOOP : int ();>

Gets the value of C<WSAELOOP>.

Exceptions:

If the system does not define this constant value, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAEMFILE

C<static method WSAEMFILE : int ();>

Gets the value of C<WSAEMFILE>.

Exceptions:

If the system does not define this constant value, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAEMSGSIZE

C<static method WSAEMSGSIZE : int ();>

Gets the value of C<WSAEMSGSIZE>.

Exceptions:

If the system does not define this constant value, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAENAMETOOLONG

C<static method WSAENAMETOOLONG : int ();>

Gets the value of C<WSAENAMETOOLONG>.

Exceptions:

If the system does not define this constant value, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAENETDOWN

C<static method WSAENETDOWN : int ();>

Gets the value of C<WSAENETDOWN>.

Exceptions:

If the system does not define this constant value, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAENETRESET

C<static method WSAENETRESET : int ();>

Gets the value of C<WSAENETRESET>.

Exceptions:

If the system does not define this constant value, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAENETUNREACH

C<static method WSAENETUNREACH : int ();>

Gets the value of C<WSAENETUNREACH>.

Exceptions:

If the system does not define this constant value, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAENOBUFS

C<static method WSAENOBUFS : int ();>

Gets the value of C<WSAENOBUFS>.

Exceptions:

If the system does not define this constant value, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAENOMORE

C<static method WSAENOMORE : int ();>

Gets the value of C<WSAENOMORE>.

Exceptions:

If the system does not define this constant value, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAENOPROTOOPT

C<static method WSAENOPROTOOPT : int ();>

Gets the value of C<WSAENOPROTOOPT>.

Exceptions:

If the system does not define this constant value, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAENOTCONN

C<static method WSAENOTCONN : int ();>

Gets the value of C<WSAENOTCONN>.

Exceptions:

If the system does not define this constant value, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAENOTEMPTY

C<static method WSAENOTEMPTY : int ();>

Gets the value of C<WSAENOTEMPTY>.

Exceptions:

If the system does not define this constant value, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAENOTSOCK

C<static method WSAENOTSOCK : int ();>

Gets the value of C<WSAENOTSOCK>.

Exceptions:

If the system does not define this constant value, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAEOPNOTSUPP

C<static method WSAEOPNOTSUPP : int ();>

Gets the value of C<WSAEOPNOTSUPP>.

Exceptions:

If the system does not define this constant value, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAEPFNOSUPPORT

C<static method WSAEPFNOSUPPORT : int ();>

Gets the value of C<WSAEPFNOSUPPORT>.

Exceptions:

If the system does not define this constant value, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAEPROCLIM

C<static method WSAEPROCLIM : int ();>

Gets the value of C<WSAEPROCLIM>.

Exceptions:

If the system does not define this constant value, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAEPROTONOSUPPORT

C<static method WSAEPROTONOSUPPORT : int ();>

Gets the value of C<WSAEPROTONOSUPPORT>.

Exceptions:

If the system does not define this constant value, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAEPROTOTYPE

C<static method WSAEPROTOTYPE : int ();>

Gets the value of C<WSAEPROTOTYPE>.

Exceptions:

If the system does not define this constant value, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAEPROVIDERFAILEDINIT

C<static method WSAEPROVIDERFAILEDINIT : int ();>

Gets the value of C<WSAEPROVIDERFAILEDINIT>.

Exceptions:

If the system does not define this constant value, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAEREFUSED

C<static method WSAEREFUSED : int ();>

Gets the value of C<WSAEREFUSED>.

Exceptions:

If the system does not define this constant value, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAEREMOTE

C<static method WSAEREMOTE : int ();>

Gets the value of C<WSAEREMOTE>.

Exceptions:

If the system does not define this constant value, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAESHUTDOWN

C<static method WSAESHUTDOWN : int ();>

Gets the value of C<WSAESHUTDOWN>.

Exceptions:

If the system does not define this constant value, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAESOCKTNOSUPPORT

C<static method WSAESOCKTNOSUPPORT : int ();>

Gets the value of C<WSAESOCKTNOSUPPORT>.

Exceptions:

If the system does not define this constant value, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAESTALE

C<static method WSAESTALE : int ();>

Gets the value of C<WSAESTALE>.

Exceptions:

If the system does not define this constant value, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAETIMEDOUT

C<static method WSAETIMEDOUT : int ();>

Gets the value of C<WSAETIMEDOUT>.

Exceptions:

If the system does not define this constant value, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAETOOMANYREFS

C<static method WSAETOOMANYREFS : int ();>

Gets the value of C<WSAETOOMANYREFS>.

Exceptions:

If the system does not define this constant value, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAEUSERS

C<static method WSAEUSERS : int ();>

Gets the value of C<WSAEUSERS>.

Exceptions:

If the system does not define this constant value, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAEWOULDBLOCK

C<static method WSAEWOULDBLOCK : int ();>

Gets the value of C<WSAEWOULDBLOCK>.

Exceptions:

If the system does not define this constant value, an exception is thrown with the error ID set to the basic type ID of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head1 Repository

L<SPVM::Errno - Github|https://github.com/yuki-kimoto/SPVM-Errno>

=head1 Author

Yuki Kimoto C<kimoto.yuki@gmail.com>

=head1 Copyright & License

Copyright (c) 2023 Yuki Kimoto

MIT License
