package SPVM::Errno;

our $VERSION = "0.090002";

1;

=head1 Name

SPVM::Errno - Error Numbers

=head1 Description

The Errno class has methods for error numbers that are defined C<errno.h> in the C<errno.h> header of the C language.

=head1 Usage

  use Errno;
  
  my $errno = Errno->errno;
  
  my $eagain = Errno->EAGAIN;

=head2 errno

  static method errno : int ()

Gets the current error number. This is the same as C<errno> defined in the C<errno.h> header of the C language.

=head2 E2BIG

  static method E2BIG : int ();

Gets the value of C<E2BIG>. If a system does not define this error number, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EACCES

  static method EACCES : int ();

Gets the value of C<EACCES>. If a system does not define this error number, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EADDRINUSE

  static method EADDRINUSE : int ();

Gets the value of C<EADDRINUSE>. If a system does not define this error number, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EADDRNOTAVAIL

  static method EADDRNOTAVAIL : int ();

Gets the value of C<EADDRNOTAVAIL>. If a system does not define this error number, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EAFNOSUPPORT

  static method EAFNOSUPPORT : int ();

Gets the value of C<EAFNOSUPPORT>. If a system does not define this error number, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EAGAIN

  static method EAGAIN : int ();

Gets the value of C<EAGAIN>. If a system does not define this error number, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EALREADY

  static method EALREADY : int ();

Gets the value of C<EALREADY>. If a system does not define this error number, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EBADE

  static method EBADE : int ();

Gets the value of C<EBADE>. If a system does not define this error number, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EBADF

  static method EBADF : int ();

Gets the value of C<EBADF>. If a system does not define this error number, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EBADFD

  static method EBADFD : int ();

Gets the value of C<EBADFD>. If a system does not define this error number, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EBADMSG

  static method EBADMSG : int ();

Gets the value of C<EBADMSG>. If a system does not define this error number, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EBADR

  static method EBADR : int ();

Gets the value of C<EBADR>. If a system does not define this error number, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EBADRQC

  static method EBADRQC : int ();

Gets the value of C<EBADRQC>. If a system does not define this error number, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EBADSLT

  static method EBADSLT : int ();

Gets the value of C<EBADSLT>. If a system does not define this error number, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EBUSY

  static method EBUSY : int ();

Gets the value of C<EBUSY>. If a system does not define this error number, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ECANCELED

  static method ECANCELED : int ();

Gets the value of C<ECANCELED>. If a system does not define this error number, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ECHILD

  static method ECHILD : int ();

Gets the value of C<ECHILD>. If a system does not define this error number, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ECHRNG

  static method ECHRNG : int ();

Gets the value of C<ECHRNG>. If a system does not define this error number, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ECOMM

  static method ECOMM : int ();

Gets the value of C<ECOMM>. If a system does not define this error number, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ECONNABORTED

  static method ECONNABORTED : int ();

Gets the value of C<ECONNABORTED>. If a system does not define this error number, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ECONNREFUSED

  static method ECONNREFUSED : int ();

Gets the value of C<ECONNREFUSED>. If a system does not define this error number, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ECONNRESET

  static method ECONNRESET : int ();

Gets the value of C<ECONNRESET>. If a system does not define this error number, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EDEADLK

  static method EDEADLK : int ();

Gets the value of C<EDEADLK>. If a system does not define this error number, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EDEADLOCK

  static method EDEADLOCK : int ();

Gets the value of C<EDEADLOCK>. If a system does not define this error number, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EDESTADDRREQ

  static method EDESTADDRREQ : int ();

Gets the value of C<EDESTADDRREQ>. If a system does not define this error number, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EDOM

  static method EDOM : int ();

Gets the value of C<EDOM>. If a system does not define this error number, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EDQUOT

  static method EDQUOT : int ();

Gets the value of C<EDQUOT>. If a system does not define this error number, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EEXIST

  static method EEXIST : int ();

Gets the value of C<EEXIST>. If a system does not define this error number, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EFAULT

  static method EFAULT : int ();

Gets the value of C<EFAULT>. If a system does not define this error number, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EFBIG

  static method EFBIG : int ();

Gets the value of C<EFBIG>. If a system does not define this error number, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EHOSTDOWN

  static method EHOSTDOWN : int ();

Gets the value of C<EHOSTDOWN>. If a system does not define this error number, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EHOSTUNREACH

  static method EHOSTUNREACH : int ();

Gets the value of C<EHOSTUNREACH>. If a system does not define this error number, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EIDRM

  static method EIDRM : int ();

Gets the value of C<EIDRM>. If a system does not define this error number, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EILSEQ

  static method EILSEQ : int ();

Gets the value of C<EILSEQ>. If a system does not define this error number, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EINPROGRESS

  static method EINPROGRESS : int ();

Gets the value of C<EINPROGRESS>. If a system does not define this error number, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EINTR

  static method EINTR : int ();

Gets the value of C<EINTR>. If a system does not define this error number, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EINVAL

  static method EINVAL : int ();

Gets the value of C<EINVAL>. If a system does not define this error number, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EIO

  static method EIO : int ();

Gets the value of C<EIO>. If a system does not define this error number, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EISCONN

  static method EISCONN : int ();

Gets the value of C<EISCONN>. If a system does not define this error number, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EISDIR

  static method EISDIR : int ();

Gets the value of C<EISDIR>. If a system does not define this error number, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EISNAM

  static method EISNAM : int ();

Gets the value of C<EISNAM>. If a system does not define this error number, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EKEYEXPIRED

  static method EKEYEXPIRED : int ();

Gets the value of C<EKEYEXPIRED>. If a system does not define this error number, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EKEYREJECTED

  static method EKEYREJECTED : int ();

Gets the value of C<EKEYREJECTED>. If a system does not define this error number, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EKEYREVOKED

  static method EKEYREVOKED : int ();

Gets the value of C<EKEYREVOKED>. If a system does not define this error number, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EL2HLT

  static method EL2HLT : int ();

Gets the value of C<EL2HLT>. If a system does not define this error number, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EL2NSYNC

  static method EL2NSYNC : int ();

Gets the value of C<EL2NSYNC>. If a system does not define this error number, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EL3HLT

  static method EL3HLT : int ();

Gets the value of C<EL3HLT>. If a system does not define this error number, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EL3RST

  static method EL3RST : int ();

Gets the value of C<EL3RST>. If a system does not define this error number, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ELIBACC

  static method ELIBACC : int ();

Gets the value of C<ELIBACC>. If a system does not define this error number, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ELIBBAD

  static method ELIBBAD : int ();

Gets the value of C<ELIBBAD>. If a system does not define this error number, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ELIBMAX

  static method ELIBMAX : int ();

Gets the value of C<ELIBMAX>. If a system does not define this error number, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ELIBSCN

  static method ELIBSCN : int ();

Gets the value of C<ELIBSCN>. If a system does not define this error number, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ELIBEXEC

  static method ELIBEXEC : int ();

Gets the value of C<ELIBEXEC>. If a system does not define this error number, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ELOOP

  static method ELOOP : int ();

Gets the value of C<ELOOP>. If a system does not define this error number, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EMEDIUMTYPE

  static method EMEDIUMTYPE : int ();

Gets the value of C<EMEDIUMTYPE>. If a system does not define this error number, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EMFILE

  static method EMFILE : int ();

Gets the value of C<EMFILE>. If a system does not define this error number, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EMLINK

  static method EMLINK : int ();

Gets the value of C<EMLINK>. If a system does not define this error number, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EMSGSIZE

  static method EMSGSIZE : int ();

Gets the value of C<EMSGSIZE>. If a system does not define this error number, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EMULTIHOP

  static method EMULTIHOP : int ();

Gets the value of C<EMULTIHOP>. If a system does not define this error number, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ENAMETOOLONG

  static method ENAMETOOLONG : int ();

Gets the value of C<ENAMETOOLONG>. If a system does not define this error number, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ENETDOWN

  static method ENETDOWN : int ();

Gets the value of C<ENETDOWN>. If a system does not define this error number, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ENETRESET

  static method ENETRESET : int ();

Gets the value of C<ENETRESET>. If a system does not define this error number, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ENETUNREACH

  static method ENETUNREACH : int ();

Gets the value of C<ENETUNREACH>. If a system does not define this error number, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ENFILE

  static method ENFILE : int ();

Gets the value of C<ENFILE>. If a system does not define this error number, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ENOBUFS

  static method ENOBUFS : int ();

Gets the value of C<ENOBUFS>. If a system does not define this error number, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ENODATA

  static method ENODATA : int ();

Gets the value of C<ENODATA>. If a system does not define this error number, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ENODEV

  static method ENODEV : int ();

Gets the value of C<ENODEV>. If a system does not define this error number, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ENOENT

  static method ENOENT : int ();

Gets the value of C<ENOENT>. If a system does not define this error number, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ENOEXEC

  static method ENOEXEC : int ();

Gets the value of C<ENOEXEC>. If a system does not define this error number, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ENOKEY

  static method ENOKEY : int ();

Gets the value of C<ENOKEY>. If a system does not define this error number, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ENOLCK

  static method ENOLCK : int ();

Gets the value of C<ENOLCK>. If a system does not define this error number, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ENOLINK

  static method ENOLINK : int ();

Gets the value of C<ENOLINK>. If a system does not define this error number, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ENOMEDIUM

  static method ENOMEDIUM : int ();

Gets the value of C<ENOMEDIUM>. If a system does not define this error number, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ENOMEM

  static method ENOMEM : int ();

Gets the value of C<ENOMEM>. If a system does not define this error number, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ENOMSG

  static method ENOMSG : int ();

Gets the value of C<ENOMSG>. If a system does not define this error number, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ENONET

  static method ENONET : int ();

Gets the value of C<ENONET>. If a system does not define this error number, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ENOPKG

  static method ENOPKG : int ();

Gets the value of C<ENOPKG>. If a system does not define this error number, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ENOPROTOOPT

  static method ENOPROTOOPT : int ();

Gets the value of C<ENOPROTOOPT>. If a system does not define this error number, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ENOSPC

  static method ENOSPC : int ();

Gets the value of C<ENOSPC>. If a system does not define this error number, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ENOSR

  static method ENOSR : int ();

Gets the value of C<ENOSR>. If a system does not define this error number, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ENOSTR

  static method ENOSTR : int ();

Gets the value of C<ENOSTR>. If a system does not define this error number, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ENOSYS

  static method ENOSYS : int ();

Gets the value of C<ENOSYS>. If a system does not define this error number, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ENOTBLK

  static method ENOTBLK : int ();

Gets the value of C<ENOTBLK>. If a system does not define this error number, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ENOTCONN

  static method ENOTCONN : int ();

Gets the value of C<ENOTCONN>. If a system does not define this error number, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ENOTDIR

  static method ENOTDIR : int ();

Gets the value of C<ENOTDIR>. If a system does not define this error number, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ENOTEMPTY

  static method ENOTEMPTY : int ();

Gets the value of C<ENOTEMPTY>. If a system does not define this error number, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ENOTSOCK

  static method ENOTSOCK : int ();

Gets the value of C<ENOTSOCK>. If a system does not define this error number, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ENOTSUP

  static method ENOTSUP : int ();

Gets the value of C<ENOTSUP>. If a system does not define this error number, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ENOTTY

  static method ENOTTY : int ();

Gets the value of C<ENOTTY>. If a system does not define this error number, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ENOTUNIQ

  static method ENOTUNIQ : int ();

Gets the value of C<ENOTUNIQ>. If a system does not define this error number, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ENXIO

  static method ENXIO : int ();

Gets the value of C<ENXIO>. If a system does not define this error number, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EOPNOTSUPP

  static method EOPNOTSUPP : int ();

Gets the value of C<EOPNOTSUPP>. If a system does not define this error number, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EOVERFLOW

  static method EOVERFLOW : int ();

Gets the value of C<EOVERFLOW>. If a system does not define this error number, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EPERM

  static method EPERM : int ();

Gets the value of C<EPERM>. If a system does not define this error number, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EPFNOSUPPORT

  static method EPFNOSUPPORT : int ();

Gets the value of C<EPFNOSUPPORT>. If a system does not define this error number, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EPIPE

  static method EPIPE : int ();

Gets the value of C<EPIPE>. If a system does not define this error number, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EPROTO

  static method EPROTO : int ();

Gets the value of C<EPROTO>. If a system does not define this error number, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EPROTONOSUPPORT

  static method EPROTONOSUPPORT : int ();

Gets the value of C<EPROTONOSUPPORT>. If a system does not define this error number, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EPROTOTYPE

  static method EPROTOTYPE : int ();

Gets the value of C<EPROTOTYPE>. If a system does not define this error number, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ERANGE

  static method ERANGE : int ();

Gets the value of C<ERANGE>. If a system does not define this error number, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EREMCHG

  static method EREMCHG : int ();

Gets the value of C<EREMCHG>. If a system does not define this error number, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EREMOTE

  static method EREMOTE : int ();

Gets the value of C<EREMOTE>. If a system does not define this error number, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EREMOTEIO

  static method EREMOTEIO : int ();

Gets the value of C<EREMOTEIO>. If a system does not define this error number, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ERESTART

  static method ERESTART : int ();

Gets the value of C<ERESTART>. If a system does not define this error number, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EROFS

  static method EROFS : int ();

Gets the value of C<EROFS>. If a system does not define this error number, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ESHUTDOWN

  static method ESHUTDOWN : int ();

Gets the value of C<ESHUTDOWN>. If a system does not define this error number, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ESPIPE

  static method ESPIPE : int ();

Gets the value of C<ESPIPE>. If a system does not define this error number, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ESOCKTNOSUPPORT

  static method ESOCKTNOSUPPORT : int ();

Gets the value of C<ESOCKTNOSUPPORT>. If a system does not define this error number, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ESRCH

  static method ESRCH : int ();

Gets the value of C<ESRCH>. If a system does not define this error number, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ESTALE

  static method ESTALE : int ();

Gets the value of C<ESTALE>. If a system does not define this error number, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ESTRPIPE

  static method ESTRPIPE : int ();

Gets the value of C<ESTRPIPE>. If a system does not define this error number, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ETIME

  static method ETIME : int ();

Gets the value of C<ETIME>. If a system does not define this error number, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ETIMEDOUT

  static method ETIMEDOUT : int ();

Gets the value of C<ETIMEDOUT>. If a system does not define this error number, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ETXTBSY

  static method ETXTBSY : int ();

Gets the value of C<ETXTBSY>. If a system does not define this error number, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EUCLEAN

  static method EUCLEAN : int ();

Gets the value of C<EUCLEAN>. If a system does not define this error number, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EUNATCH

  static method EUNATCH : int ();

Gets the value of C<EUNATCH>. If a system does not define this error number, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EUSERS

  static method EUSERS : int ();

Gets the value of C<EUSERS>. If a system does not define this error number, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EWOULDBLOCK

  static method EWOULDBLOCK : int ();

Gets the value of C<EWOULDBLOCK>. If a system does not define this error number, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EXDEV

  static method EXDEV : int ();

Gets the value of C<EXDEV>. If a system does not define this error number, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EXFULL

  static method EXFULL : int ();

Gets the value of C<EXFULL>. If a system does not define this error number, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAEACCES

  static method WSAEACCES : int ();

Gets the value of C<WSAEACCES>. If the system does not define this constant value, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAEADDRINUSE

  static method WSAEADDRINUSE : int ();

Gets the value of C<WSAEADDRINUSE>. If the system does not define this constant value, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAEADDRNOTAVAIL

  static method WSAEADDRNOTAVAIL : int ();

Gets the value of C<WSAEADDRNOTAVAIL>. If the system does not define this constant value, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAEAFNOSUPPORT

  static method WSAEAFNOSUPPORT : int ();

Gets the value of C<WSAEAFNOSUPPORT>. If the system does not define this constant value, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAEALREADY

  static method WSAEALREADY : int ();

Gets the value of C<WSAEALREADY>. If the system does not define this constant value, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAEBADF

  static method WSAEBADF : int ();

Gets the value of C<WSAEBADF>. If the system does not define this constant value, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAECANCELLED

  static method WSAECANCELLED : int ();

Gets the value of C<WSAECANCELLED>. If the system does not define this constant value, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAECONNABORTED

  static method WSAECONNABORTED : int ();

Gets the value of C<WSAECONNABORTED>. If the system does not define this constant value, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAECONNREFUSED

  static method WSAECONNREFUSED : int ();

Gets the value of C<WSAECONNREFUSED>. If the system does not define this constant value, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAECONNRESET

  static method WSAECONNRESET : int ();

Gets the value of C<WSAECONNRESET>. If the system does not define this constant value, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAEDESTADDRREQ

  static method WSAEDESTADDRREQ : int ();

Gets the value of C<WSAEDESTADDRREQ>. If the system does not define this constant value, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAEDISCON

  static method WSAEDISCON : int ();

Gets the value of C<WSAEDISCON>. If the system does not define this constant value, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAEDQUOT

  static method WSAEDQUOT : int ();

Gets the value of C<WSAEDQUOT>. If the system does not define this constant value, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAEFAULT

  static method WSAEFAULT : int ();

Gets the value of C<WSAEFAULT>. If the system does not define this constant value, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAEHOSTDOWN

  static method WSAEHOSTDOWN : int ();

Gets the value of C<WSAEHOSTDOWN>. If the system does not define this constant value, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAEHOSTUNREACH

  static method WSAEHOSTUNREACH : int ();

Gets the value of C<WSAEHOSTUNREACH>. If the system does not define this constant value, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAEINPROGRESS

  static method WSAEINPROGRESS : int ();

Gets the value of C<WSAEINPROGRESS>. If the system does not define this constant value, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAEINTR

  static method WSAEINTR : int ();

Gets the value of C<WSAEINTR>. If the system does not define this constant value, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAEINVAL

  static method WSAEINVAL : int ();

Gets the value of C<WSAEINVAL>. If the system does not define this constant value, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAEINVALIDPROCTABLE

  static method WSAEINVALIDPROCTABLE : int ();

Gets the value of C<WSAEINVALIDPROCTABLE>. If the system does not define this constant value, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAEINVALIDPROVIDER

  static method WSAEINVALIDPROVIDER : int ();

Gets the value of C<WSAEINVALIDPROVIDER>. If the system does not define this constant value, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAEISCONN

  static method WSAEISCONN : int ();

Gets the value of C<WSAEISCONN>. If the system does not define this constant value, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAELOOP

  static method WSAELOOP : int ();

Gets the value of C<WSAELOOP>. If the system does not define this constant value, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAEMFILE

  static method WSAEMFILE : int ();

Gets the value of C<WSAEMFILE>. If the system does not define this constant value, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAEMSGSIZE

  static method WSAEMSGSIZE : int ();

Gets the value of C<WSAEMSGSIZE>. If the system does not define this constant value, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAENAMETOOLONG

  static method WSAENAMETOOLONG : int ();

Gets the value of C<WSAENAMETOOLONG>. If the system does not define this constant value, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAENETDOWN

  static method WSAENETDOWN : int ();

Gets the value of C<WSAENETDOWN>. If the system does not define this constant value, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAENETRESET

  static method WSAENETRESET : int ();

Gets the value of C<WSAENETRESET>. If the system does not define this constant value, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAENETUNREACH

  static method WSAENETUNREACH : int ();

Gets the value of C<WSAENETUNREACH>. If the system does not define this constant value, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAENOBUFS

  static method WSAENOBUFS : int ();

Gets the value of C<WSAENOBUFS>. If the system does not define this constant value, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAENOMORE

  static method WSAENOMORE : int ();

Gets the value of C<WSAENOMORE>. If the system does not define this constant value, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAENOPROTOOPT

  static method WSAENOPROTOOPT : int ();

Gets the value of C<WSAENOPROTOOPT>. If the system does not define this constant value, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAENOTCONN

  static method WSAENOTCONN : int ();

Gets the value of C<WSAENOTCONN>. If the system does not define this constant value, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAENOTEMPTY

  static method WSAENOTEMPTY : int ();

Gets the value of C<WSAENOTEMPTY>. If the system does not define this constant value, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAENOTSOCK

  static method WSAENOTSOCK : int ();

Gets the value of C<WSAENOTSOCK>. If the system does not define this constant value, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAEOPNOTSUPP

  static method WSAEOPNOTSUPP : int ();

Gets the value of C<WSAEOPNOTSUPP>. If the system does not define this constant value, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAEPFNOSUPPORT

  static method WSAEPFNOSUPPORT : int ();

Gets the value of C<WSAEPFNOSUPPORT>. If the system does not define this constant value, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAEPROCLIM

  static method WSAEPROCLIM : int ();

Gets the value of C<WSAEPROCLIM>. If the system does not define this constant value, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAEPROTONOSUPPORT

  static method WSAEPROTONOSUPPORT : int ();

Gets the value of C<WSAEPROTONOSUPPORT>. If the system does not define this constant value, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAEPROTOTYPE

  static method WSAEPROTOTYPE : int ();

Gets the value of C<WSAEPROTOTYPE>. If the system does not define this constant value, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAEPROVIDERFAILEDINIT

  static method WSAEPROVIDERFAILEDINIT : int ();

Gets the value of C<WSAEPROVIDERFAILEDINIT>. If the system does not define this constant value, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAEREFUSED

  static method WSAEREFUSED : int ();

Gets the value of C<WSAEREFUSED>. If the system does not define this constant value, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAEREMOTE

  static method WSAEREMOTE : int ();

Gets the value of C<WSAEREMOTE>. If the system does not define this constant value, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAESHUTDOWN

  static method WSAESHUTDOWN : int ();

Gets the value of C<WSAESHUTDOWN>. If the system does not define this constant value, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAESOCKTNOSUPPORT

  static method WSAESOCKTNOSUPPORT : int ();

Gets the value of C<WSAESOCKTNOSUPPORT>. If the system does not define this constant value, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAESTALE

  static method WSAESTALE : int ();

Gets the value of C<WSAESTALE>. If the system does not define this constant value, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAETIMEDOUT

  static method WSAETIMEDOUT : int ();

Gets the value of C<WSAETIMEDOUT>. If the system does not define this constant value, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAETOOMANYREFS

  static method WSAETOOMANYREFS : int ();

Gets the value of C<WSAETOOMANYREFS>. If the system does not define this constant value, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAEUSERS

  static method WSAEUSERS : int ();

Gets the value of C<WSAEUSERS>. If the system does not define this constant value, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAEWOULDBLOCK

  static method WSAEWOULDBLOCK : int ();

Gets the value of C<WSAEWOULDBLOCK>. If the system does not define this constant value, an exception is thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head1 Repository

L<SPVM::Errno - Github|https://github.com/yuki-kimoto/SPVM-Errno>

=head1 Author

Yuki Kimoto C<kimoto.yuki@gmail.com>

