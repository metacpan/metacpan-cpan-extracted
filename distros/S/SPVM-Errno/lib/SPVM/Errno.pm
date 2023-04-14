package SPVM::Errno;

our $VERSION = '0.08';

1;

=head1 Name

SPVM::Errno - Error Number

=head1 Usage

  use Errno;
  
  my $errno = Errno->errno;
  
  my $eagain = Errno->EAGAIN;

=head1 Description

C<Errno> is a L<SPVM> module to manipulate system error numbers.

=head1 Caution

L<SPVM> is yet experimental status.

=head1 Class Methods

=head2 errno

  static method errno : int ()

Get the current error number. This is the same as C<errno> defined in C<errno.h> of C<C language>.

=head2 E2BIG

  static method E2BIG : int ();

Get the constant value of C<E2BIG>. If the system doesn't define this error number, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EACCES

  static method EACCES : int ();

Get the constant value of C<EACCES>. If the system doesn't define this error number, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EADDRINUSE

  static method EADDRINUSE : int ();

Get the constant value of C<EADDRINUSE>. If the system doesn't define this error number, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EADDRNOTAVAIL

  static method EADDRNOTAVAIL : int ();

Get the constant value of C<EADDRNOTAVAIL>. If the system doesn't define this error number, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EAFNOSUPPORT

  static method EAFNOSUPPORT : int ();

Get the constant value of C<EAFNOSUPPORT>. If the system doesn't define this error number, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EAGAIN

  static method EAGAIN : int ();

Get the constant value of C<EAGAIN>. If the system doesn't define this error number, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EALREADY

  static method EALREADY : int ();

Get the constant value of C<EALREADY>. If the system doesn't define this error number, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EBADE

  static method EBADE : int ();

Get the constant value of C<EBADE>. If the system doesn't define this error number, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EBADF

  static method EBADF : int ();

Get the constant value of C<EBADF>. If the system doesn't define this error number, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EBADFD

  static method EBADFD : int ();

Get the constant value of C<EBADFD>. If the system doesn't define this error number, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EBADMSG

  static method EBADMSG : int ();

Get the constant value of C<EBADMSG>. If the system doesn't define this error number, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EBADR

  static method EBADR : int ();

Get the constant value of C<EBADR>. If the system doesn't define this error number, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EBADRQC

  static method EBADRQC : int ();

Get the constant value of C<EBADRQC>. If the system doesn't define this error number, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EBADSLT

  static method EBADSLT : int ();

Get the constant value of C<EBADSLT>. If the system doesn't define this error number, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EBUSY

  static method EBUSY : int ();

Get the constant value of C<EBUSY>. If the system doesn't define this error number, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ECANCELED

  static method ECANCELED : int ();

Get the constant value of C<ECANCELED>. If the system doesn't define this error number, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ECHILD

  static method ECHILD : int ();

Get the constant value of C<ECHILD>. If the system doesn't define this error number, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ECHRNG

  static method ECHRNG : int ();

Get the constant value of C<ECHRNG>. If the system doesn't define this error number, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ECOMM

  static method ECOMM : int ();

Get the constant value of C<ECOMM>. If the system doesn't define this error number, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ECONNABORTED

  static method ECONNABORTED : int ();

Get the constant value of C<ECONNABORTED>. If the system doesn't define this error number, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ECONNREFUSED

  static method ECONNREFUSED : int ();

Get the constant value of C<ECONNREFUSED>. If the system doesn't define this error number, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ECONNRESET

  static method ECONNRESET : int ();

Get the constant value of C<ECONNRESET>. If the system doesn't define this error number, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EDEADLK

  static method EDEADLK : int ();

Get the constant value of C<EDEADLK>. If the system doesn't define this error number, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EDEADLOCK

  static method EDEADLOCK : int ();

Get the constant value of C<EDEADLOCK>. If the system doesn't define this error number, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EDESTADDRREQ

  static method EDESTADDRREQ : int ();

Get the constant value of C<EDESTADDRREQ>. If the system doesn't define this error number, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EDOM

  static method EDOM : int ();

Get the constant value of C<EDOM>. If the system doesn't define this error number, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EDQUOT

  static method EDQUOT : int ();

Get the constant value of C<EDQUOT>. If the system doesn't define this error number, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EEXIST

  static method EEXIST : int ();

Get the constant value of C<EEXIST>. If the system doesn't define this error number, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EFAULT

  static method EFAULT : int ();

Get the constant value of C<EFAULT>. If the system doesn't define this error number, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EFBIG

  static method EFBIG : int ();

Get the constant value of C<EFBIG>. If the system doesn't define this error number, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EHOSTDOWN

  static method EHOSTDOWN : int ();

Get the constant value of C<EHOSTDOWN>. If the system doesn't define this error number, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EHOSTUNREACH

  static method EHOSTUNREACH : int ();

Get the constant value of C<EHOSTUNREACH>. If the system doesn't define this error number, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EIDRM

  static method EIDRM : int ();

Get the constant value of C<EIDRM>. If the system doesn't define this error number, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EILSEQ

  static method EILSEQ : int ();

Get the constant value of C<EILSEQ>. If the system doesn't define this error number, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EINPROGRESS

  static method EINPROGRESS : int ();

Get the constant value of C<EINPROGRESS>. If the system doesn't define this error number, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EINTR

  static method EINTR : int ();

Get the constant value of C<EINTR>. If the system doesn't define this error number, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EINVAL

  static method EINVAL : int ();

Get the constant value of C<EINVAL>. If the system doesn't define this error number, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EIO

  static method EIO : int ();

Get the constant value of C<EIO>. If the system doesn't define this error number, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EISCONN

  static method EISCONN : int ();

Get the constant value of C<EISCONN>. If the system doesn't define this error number, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EISDIR

  static method EISDIR : int ();

Get the constant value of C<EISDIR>. If the system doesn't define this error number, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EISNAM

  static method EISNAM : int ();

Get the constant value of C<EISNAM>. If the system doesn't define this error number, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EKEYEXPIRED

  static method EKEYEXPIRED : int ();

Get the constant value of C<EKEYEXPIRED>. If the system doesn't define this error number, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EKEYREJECTED

  static method EKEYREJECTED : int ();

Get the constant value of C<EKEYREJECTED>. If the system doesn't define this error number, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EKEYREVOKED

  static method EKEYREVOKED : int ();

Get the constant value of C<EKEYREVOKED>. If the system doesn't define this error number, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EL2HLT

  static method EL2HLT : int ();

Get the constant value of C<EL2HLT>. If the system doesn't define this error number, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EL2NSYNC

  static method EL2NSYNC : int ();

Get the constant value of C<EL2NSYNC>. If the system doesn't define this error number, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EL3HLT

  static method EL3HLT : int ();

Get the constant value of C<EL3HLT>. If the system doesn't define this error number, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EL3RST

  static method EL3RST : int ();

Get the constant value of C<EL3RST>. If the system doesn't define this error number, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ELIBACC

  static method ELIBACC : int ();

Get the constant value of C<ELIBACC>. If the system doesn't define this error number, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ELIBBAD

  static method ELIBBAD : int ();

Get the constant value of C<ELIBBAD>. If the system doesn't define this error number, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ELIBMAX

  static method ELIBMAX : int ();

Get the constant value of C<ELIBMAX>. If the system doesn't define this error number, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ELIBSCN

  static method ELIBSCN : int ();

Get the constant value of C<ELIBSCN>. If the system doesn't define this error number, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ELIBEXEC

  static method ELIBEXEC : int ();

Get the constant value of C<ELIBEXEC>. If the system doesn't define this error number, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ELOOP

  static method ELOOP : int ();

Get the constant value of C<ELOOP>. If the system doesn't define this error number, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EMEDIUMTYPE

  static method EMEDIUMTYPE : int ();

Get the constant value of C<EMEDIUMTYPE>. If the system doesn't define this error number, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EMFILE

  static method EMFILE : int ();

Get the constant value of C<EMFILE>. If the system doesn't define this error number, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EMLINK

  static method EMLINK : int ();

Get the constant value of C<EMLINK>. If the system doesn't define this error number, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EMSGSIZE

  static method EMSGSIZE : int ();

Get the constant value of C<EMSGSIZE>. If the system doesn't define this error number, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EMULTIHOP

  static method EMULTIHOP : int ();

Get the constant value of C<EMULTIHOP>. If the system doesn't define this error number, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ENAMETOOLONG

  static method ENAMETOOLONG : int ();

Get the constant value of C<ENAMETOOLONG>. If the system doesn't define this error number, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ENETDOWN

  static method ENETDOWN : int ();

Get the constant value of C<ENETDOWN>. If the system doesn't define this error number, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ENETRESET

  static method ENETRESET : int ();

Get the constant value of C<ENETRESET>. If the system doesn't define this error number, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ENETUNREACH

  static method ENETUNREACH : int ();

Get the constant value of C<ENETUNREACH>. If the system doesn't define this error number, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ENFILE

  static method ENFILE : int ();

Get the constant value of C<ENFILE>. If the system doesn't define this error number, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ENOBUFS

  static method ENOBUFS : int ();

Get the constant value of C<ENOBUFS>. If the system doesn't define this error number, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ENODATA

  static method ENODATA : int ();

Get the constant value of C<ENODATA>. If the system doesn't define this error number, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ENODEV

  static method ENODEV : int ();

Get the constant value of C<ENODEV>. If the system doesn't define this error number, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ENOENT

  static method ENOENT : int ();

Get the constant value of C<ENOENT>. If the system doesn't define this error number, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ENOEXEC

  static method ENOEXEC : int ();

Get the constant value of C<ENOEXEC>. If the system doesn't define this error number, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ENOKEY

  static method ENOKEY : int ();

Get the constant value of C<ENOKEY>. If the system doesn't define this error number, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ENOLCK

  static method ENOLCK : int ();

Get the constant value of C<ENOLCK>. If the system doesn't define this error number, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ENOLINK

  static method ENOLINK : int ();

Get the constant value of C<ENOLINK>. If the system doesn't define this error number, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ENOMEDIUM

  static method ENOMEDIUM : int ();

Get the constant value of C<ENOMEDIUM>. If the system doesn't define this error number, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ENOMEM

  static method ENOMEM : int ();

Get the constant value of C<ENOMEM>. If the system doesn't define this error number, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ENOMSG

  static method ENOMSG : int ();

Get the constant value of C<ENOMSG>. If the system doesn't define this error number, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ENONET

  static method ENONET : int ();

Get the constant value of C<ENONET>. If the system doesn't define this error number, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ENOPKG

  static method ENOPKG : int ();

Get the constant value of C<ENOPKG>. If the system doesn't define this error number, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ENOPROTOOPT

  static method ENOPROTOOPT : int ();

Get the constant value of C<ENOPROTOOPT>. If the system doesn't define this error number, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ENOSPC

  static method ENOSPC : int ();

Get the constant value of C<ENOSPC>. If the system doesn't define this error number, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ENOSR

  static method ENOSR : int ();

Get the constant value of C<ENOSR>. If the system doesn't define this error number, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ENOSTR

  static method ENOSTR : int ();

Get the constant value of C<ENOSTR>. If the system doesn't define this error number, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ENOSYS

  static method ENOSYS : int ();

Get the constant value of C<ENOSYS>. If the system doesn't define this error number, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ENOTBLK

  static method ENOTBLK : int ();

Get the constant value of C<ENOTBLK>. If the system doesn't define this error number, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ENOTCONN

  static method ENOTCONN : int ();

Get the constant value of C<ENOTCONN>. If the system doesn't define this error number, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ENOTDIR

  static method ENOTDIR : int ();

Get the constant value of C<ENOTDIR>. If the system doesn't define this error number, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ENOTEMPTY

  static method ENOTEMPTY : int ();

Get the constant value of C<ENOTEMPTY>. If the system doesn't define this error number, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ENOTSOCK

  static method ENOTSOCK : int ();

Get the constant value of C<ENOTSOCK>. If the system doesn't define this error number, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ENOTSUP

  static method ENOTSUP : int ();

Get the constant value of C<ENOTSUP>. If the system doesn't define this error number, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ENOTTY

  static method ENOTTY : int ();

Get the constant value of C<ENOTTY>. If the system doesn't define this error number, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ENOTUNIQ

  static method ENOTUNIQ : int ();

Get the constant value of C<ENOTUNIQ>. If the system doesn't define this error number, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ENXIO

  static method ENXIO : int ();

Get the constant value of C<ENXIO>. If the system doesn't define this error number, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EOPNOTSUPP

  static method EOPNOTSUPP : int ();

Get the constant value of C<EOPNOTSUPP>. If the system doesn't define this error number, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EOVERFLOW

  static method EOVERFLOW : int ();

Get the constant value of C<EOVERFLOW>. If the system doesn't define this error number, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EPERM

  static method EPERM : int ();

Get the constant value of C<EPERM>. If the system doesn't define this error number, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EPFNOSUPPORT

  static method EPFNOSUPPORT : int ();

Get the constant value of C<EPFNOSUPPORT>. If the system doesn't define this error number, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EPIPE

  static method EPIPE : int ();

Get the constant value of C<EPIPE>. If the system doesn't define this error number, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EPROTO

  static method EPROTO : int ();

Get the constant value of C<EPROTO>. If the system doesn't define this error number, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EPROTONOSUPPORT

  static method EPROTONOSUPPORT : int ();

Get the constant value of C<EPROTONOSUPPORT>. If the system doesn't define this error number, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EPROTOTYPE

  static method EPROTOTYPE : int ();

Get the constant value of C<EPROTOTYPE>. If the system doesn't define this error number, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ERANGE

  static method ERANGE : int ();

Get the constant value of C<ERANGE>. If the system doesn't define this error number, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EREMCHG

  static method EREMCHG : int ();

Get the constant value of C<EREMCHG>. If the system doesn't define this error number, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EREMOTE

  static method EREMOTE : int ();

Get the constant value of C<EREMOTE>. If the system doesn't define this error number, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EREMOTEIO

  static method EREMOTEIO : int ();

Get the constant value of C<EREMOTEIO>. If the system doesn't define this error number, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ERESTART

  static method ERESTART : int ();

Get the constant value of C<ERESTART>. If the system doesn't define this error number, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EROFS

  static method EROFS : int ();

Get the constant value of C<EROFS>. If the system doesn't define this error number, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ESHUTDOWN

  static method ESHUTDOWN : int ();

Get the constant value of C<ESHUTDOWN>. If the system doesn't define this error number, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ESPIPE

  static method ESPIPE : int ();

Get the constant value of C<ESPIPE>. If the system doesn't define this error number, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ESOCKTNOSUPPORT

  static method ESOCKTNOSUPPORT : int ();

Get the constant value of C<ESOCKTNOSUPPORT>. If the system doesn't define this error number, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ESRCH

  static method ESRCH : int ();

Get the constant value of C<ESRCH>. If the system doesn't define this error number, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ESTALE

  static method ESTALE : int ();

Get the constant value of C<ESTALE>. If the system doesn't define this error number, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ESTRPIPE

  static method ESTRPIPE : int ();

Get the constant value of C<ESTRPIPE>. If the system doesn't define this error number, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ETIME

  static method ETIME : int ();

Get the constant value of C<ETIME>. If the system doesn't define this error number, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ETIMEDOUT

  static method ETIMEDOUT : int ();

Get the constant value of C<ETIMEDOUT>. If the system doesn't define this error number, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 ETXTBSY

  static method ETXTBSY : int ();

Get the constant value of C<ETXTBSY>. If the system doesn't define this error number, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EUCLEAN

  static method EUCLEAN : int ();

Get the constant value of C<EUCLEAN>. If the system doesn't define this error number, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EUNATCH

  static method EUNATCH : int ();

Get the constant value of C<EUNATCH>. If the system doesn't define this error number, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EUSERS

  static method EUSERS : int ();

Get the constant value of C<EUSERS>. If the system doesn't define this error number, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EWOULDBLOCK

  static method EWOULDBLOCK : int ();

Get the constant value of C<EWOULDBLOCK>. If the system doesn't define this error number, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EXDEV

  static method EXDEV : int ();

Get the constant value of C<EXDEV>. If the system doesn't define this error number, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 EXFULL

  static method EXFULL : int ();

Get the constant value of C<EXFULL>. If the system doesn't define this error number, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAEACCES

  static method WSAEACCES : int ();

Get the constant value of C<WSAEACCES>. If the system doesn't define this constant value, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAEADDRINUSE

  static method WSAEADDRINUSE : int ();

Get the constant value of C<WSAEADDRINUSE>. If the system doesn't define this constant value, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAEADDRNOTAVAIL

  static method WSAEADDRNOTAVAIL : int ();

Get the constant value of C<WSAEADDRNOTAVAIL>. If the system doesn't define this constant value, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAEAFNOSUPPORT

  static method WSAEAFNOSUPPORT : int ();

Get the constant value of C<WSAEAFNOSUPPORT>. If the system doesn't define this constant value, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAEALREADY

  static method WSAEALREADY : int ();

Get the constant value of C<WSAEALREADY>. If the system doesn't define this constant value, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAEBADF

  static method WSAEBADF : int ();

Get the constant value of C<WSAEBADF>. If the system doesn't define this constant value, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAECANCELLED

  static method WSAECANCELLED : int ();

Get the constant value of C<WSAECANCELLED>. If the system doesn't define this constant value, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAECONNABORTED

  static method WSAECONNABORTED : int ();

Get the constant value of C<WSAECONNABORTED>. If the system doesn't define this constant value, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAECONNREFUSED

  static method WSAECONNREFUSED : int ();

Get the constant value of C<WSAECONNREFUSED>. If the system doesn't define this constant value, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAECONNRESET

  static method WSAECONNRESET : int ();

Get the constant value of C<WSAECONNRESET>. If the system doesn't define this constant value, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAEDESTADDRREQ

  static method WSAEDESTADDRREQ : int ();

Get the constant value of C<WSAEDESTADDRREQ>. If the system doesn't define this constant value, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAEDISCON

  static method WSAEDISCON : int ();

Get the constant value of C<WSAEDISCON>. If the system doesn't define this constant value, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAEDQUOT

  static method WSAEDQUOT : int ();

Get the constant value of C<WSAEDQUOT>. If the system doesn't define this constant value, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAEFAULT

  static method WSAEFAULT : int ();

Get the constant value of C<WSAEFAULT>. If the system doesn't define this constant value, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAEHOSTDOWN

  static method WSAEHOSTDOWN : int ();

Get the constant value of C<WSAEHOSTDOWN>. If the system doesn't define this constant value, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAEHOSTUNREACH

  static method WSAEHOSTUNREACH : int ();

Get the constant value of C<WSAEHOSTUNREACH>. If the system doesn't define this constant value, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAEINPROGRESS

  static method WSAEINPROGRESS : int ();

Get the constant value of C<WSAEINPROGRESS>. If the system doesn't define this constant value, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAEINTR

  static method WSAEINTR : int ();

Get the constant value of C<WSAEINTR>. If the system doesn't define this constant value, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAEINVAL

  static method WSAEINVAL : int ();

Get the constant value of C<WSAEINVAL>. If the system doesn't define this constant value, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAEINVALIDPROCTABLE

  static method WSAEINVALIDPROCTABLE : int ();

Get the constant value of C<WSAEINVALIDPROCTABLE>. If the system doesn't define this constant value, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAEINVALIDPROVIDER

  static method WSAEINVALIDPROVIDER : int ();

Get the constant value of C<WSAEINVALIDPROVIDER>. If the system doesn't define this constant value, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAEISCONN

  static method WSAEISCONN : int ();

Get the constant value of C<WSAEISCONN>. If the system doesn't define this constant value, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAELOOP

  static method WSAELOOP : int ();

Get the constant value of C<WSAELOOP>. If the system doesn't define this constant value, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAEMFILE

  static method WSAEMFILE : int ();

Get the constant value of C<WSAEMFILE>. If the system doesn't define this constant value, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAEMSGSIZE

  static method WSAEMSGSIZE : int ();

Get the constant value of C<WSAEMSGSIZE>. If the system doesn't define this constant value, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAENAMETOOLONG

  static method WSAENAMETOOLONG : int ();

Get the constant value of C<WSAENAMETOOLONG>. If the system doesn't define this constant value, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAENETDOWN

  static method WSAENETDOWN : int ();

Get the constant value of C<WSAENETDOWN>. If the system doesn't define this constant value, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAENETRESET

  static method WSAENETRESET : int ();

Get the constant value of C<WSAENETRESET>. If the system doesn't define this constant value, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAENETUNREACH

  static method WSAENETUNREACH : int ();

Get the constant value of C<WSAENETUNREACH>. If the system doesn't define this constant value, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAENOBUFS

  static method WSAENOBUFS : int ();

Get the constant value of C<WSAENOBUFS>. If the system doesn't define this constant value, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAENOMORE

  static method WSAENOMORE : int ();

Get the constant value of C<WSAENOMORE>. If the system doesn't define this constant value, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAENOPROTOOPT

  static method WSAENOPROTOOPT : int ();

Get the constant value of C<WSAENOPROTOOPT>. If the system doesn't define this constant value, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAENOTCONN

  static method WSAENOTCONN : int ();

Get the constant value of C<WSAENOTCONN>. If the system doesn't define this constant value, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAENOTEMPTY

  static method WSAENOTEMPTY : int ();

Get the constant value of C<WSAENOTEMPTY>. If the system doesn't define this constant value, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAENOTSOCK

  static method WSAENOTSOCK : int ();

Get the constant value of C<WSAENOTSOCK>. If the system doesn't define this constant value, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAEOPNOTSUPP

  static method WSAEOPNOTSUPP : int ();

Get the constant value of C<WSAEOPNOTSUPP>. If the system doesn't define this constant value, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAEPFNOSUPPORT

  static method WSAEPFNOSUPPORT : int ();

Get the constant value of C<WSAEPFNOSUPPORT>. If the system doesn't define this constant value, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAEPROCLIM

  static method WSAEPROCLIM : int ();

Get the constant value of C<WSAEPROCLIM>. If the system doesn't define this constant value, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAEPROTONOSUPPORT

  static method WSAEPROTONOSUPPORT : int ();

Get the constant value of C<WSAEPROTONOSUPPORT>. If the system doesn't define this constant value, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAEPROTOTYPE

  static method WSAEPROTOTYPE : int ();

Get the constant value of C<WSAEPROTOTYPE>. If the system doesn't define this constant value, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAEPROVIDERFAILEDINIT

  static method WSAEPROVIDERFAILEDINIT : int ();

Get the constant value of C<WSAEPROVIDERFAILEDINIT>. If the system doesn't define this constant value, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAEREFUSED

  static method WSAEREFUSED : int ();

Get the constant value of C<WSAEREFUSED>. If the system doesn't define this constant value, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAEREMOTE

  static method WSAEREMOTE : int ();

Get the constant value of C<WSAEREMOTE>. If the system doesn't define this constant value, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAESHUTDOWN

  static method WSAESHUTDOWN : int ();

Get the constant value of C<WSAESHUTDOWN>. If the system doesn't define this constant value, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAESOCKTNOSUPPORT

  static method WSAESOCKTNOSUPPORT : int ();

Get the constant value of C<WSAESOCKTNOSUPPORT>. If the system doesn't define this constant value, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAESTALE

  static method WSAESTALE : int ();

Get the constant value of C<WSAESTALE>. If the system doesn't define this constant value, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAETIMEDOUT

  static method WSAETIMEDOUT : int ();

Get the constant value of C<WSAETIMEDOUT>. If the system doesn't define this constant value, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAETOOMANYREFS

  static method WSAETOOMANYREFS : int ();

Get the constant value of C<WSAETOOMANYREFS>. If the system doesn't define this constant value, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAEUSERS

  static method WSAEUSERS : int ();

Get the constant value of C<WSAEUSERS>. If the system doesn't define this constant value, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head2 WSAEWOULDBLOCK

  static method WSAEWOULDBLOCK : int ();

Get the constant value of C<WSAEWOULDBLOCK>. If the system doesn't define this constant value, an exception will be thrown with the error code set to the class id of the L<Error::NotSupported|SPVM::Error::NotSupported> class.

=head1 Repository

L<https://github.com/yuki-kimoto/SPVM-Errno>

=head1 Author

Yuki Kimoto C<kimoto.yuki@gmail.com>

=head1 Copyright & License

Copyright 2022-2022 Yuki Kimoto, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

