package SPVM::Errno;

our $VERSION = '0.01';

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

Get the error number of C<E2BIG>. If the system doesn't define this error number, an exception is thrown.

=head2 EACCES

  static method EACCES : int ();

Get the error number of C<EACCES>. If the system doesn't define this error number, an exception is thrown.

=head2 EADDRINUSE

  static method EADDRINUSE : int ();

Get the error number of C<EADDRINUSE>. If the system doesn't define this error number, an exception is thrown.

=head2 EADDRNOTAVAIL

  static method EADDRNOTAVAIL : int ();

Get the error number of C<EADDRNOTAVAIL>. If the system doesn't define this error number, an exception is thrown.

=head2 EAFNOSUPPORT

  static method EAFNOSUPPORT : int ();

Get the error number of C<EAFNOSUPPORT>. If the system doesn't define this error number, an exception is thrown.

=head2 EAGAIN

  static method EAGAIN : int ();

Get the error number of C<EAGAIN>. If the system doesn't define this error number, an exception is thrown.

=head2 EALREADY

  static method EALREADY : int ();

Get the error number of C<EALREADY>. If the system doesn't define this error number, an exception is thrown.

=head2 EBADE

  static method EBADE : int ();

Get the error number of C<EBADE>. If the system doesn't define this error number, an exception is thrown.

=head2 EBADF

  static method EBADF : int ();

Get the error number of C<EBADF>. If the system doesn't define this error number, an exception is thrown.

=head2 EBADFD

  static method EBADFD : int ();

Get the error number of C<EBADFD>. If the system doesn't define this error number, an exception is thrown.

=head2 EBADMSG

  static method EBADMSG : int ();

Get the error number of C<EBADMSG>. If the system doesn't define this error number, an exception is thrown.

=head2 EBADR

  static method EBADR : int ();

Get the error number of C<EBADR>. If the system doesn't define this error number, an exception is thrown.

=head2 EBADRQC

  static method EBADRQC : int ();

Get the error number of C<EBADRQC>. If the system doesn't define this error number, an exception is thrown.

=head2 EBADSLT

  static method EBADSLT : int ();

Get the error number of C<EBADSLT>. If the system doesn't define this error number, an exception is thrown.

=head2 EBUSY

  static method EBUSY : int ();

Get the error number of C<EBUSY>. If the system doesn't define this error number, an exception is thrown.

=head2 ECANCELED

  static method ECANCELED : int ();

Get the error number of C<ECANCELED>. If the system doesn't define this error number, an exception is thrown.

=head2 ECHILD

  static method ECHILD : int ();

Get the error number of C<ECHILD>. If the system doesn't define this error number, an exception is thrown.

=head2 ECHRNG

  static method ECHRNG : int ();

Get the error number of C<ECHRNG>. If the system doesn't define this error number, an exception is thrown.

=head2 ECOMM

  static method ECOMM : int ();

Get the error number of C<ECOMM>. If the system doesn't define this error number, an exception is thrown.

=head2 ECONNABORTED

  static method ECONNABORTED : int ();

Get the error number of C<ECONNABORTED>. If the system doesn't define this error number, an exception is thrown.

=head2 ECONNREFUSED

  static method ECONNREFUSED : int ();

Get the error number of C<ECONNREFUSED>. If the system doesn't define this error number, an exception is thrown.

=head2 ECONNRESET

  static method ECONNRESET : int ();

Get the error number of C<ECONNRESET>. If the system doesn't define this error number, an exception is thrown.

=head2 EDEADLK

  static method EDEADLK : int ();

Get the error number of C<EDEADLK>. If the system doesn't define this error number, an exception is thrown.

=head2 EDEADLOCK

  static method EDEADLOCK : int ();

Get the error number of C<EDEADLOCK>. If the system doesn't define this error number, an exception is thrown.

=head2 EDESTADDRREQ

  static method EDESTADDRREQ : int ();

Get the error number of C<EDESTADDRREQ>. If the system doesn't define this error number, an exception is thrown.

=head2 EDOM

  static method EDOM : int ();

Get the error number of C<EDOM>. If the system doesn't define this error number, an exception is thrown.

=head2 EDQUOT

  static method EDQUOT : int ();

Get the error number of C<EDQUOT>. If the system doesn't define this error number, an exception is thrown.

=head2 EEXIST

  static method EEXIST : int ();

Get the error number of C<EEXIST>. If the system doesn't define this error number, an exception is thrown.

=head2 EFAULT

  static method EFAULT : int ();

Get the error number of C<EFAULT>. If the system doesn't define this error number, an exception is thrown.

=head2 EFBIG

  static method EFBIG : int ();

Get the error number of C<EFBIG>. If the system doesn't define this error number, an exception is thrown.

=head2 EHOSTDOWN

  static method EHOSTDOWN : int ();

Get the error number of C<EHOSTDOWN>. If the system doesn't define this error number, an exception is thrown.

=head2 EHOSTUNREACH

  static method EHOSTUNREACH : int ();

Get the error number of C<EHOSTUNREACH>. If the system doesn't define this error number, an exception is thrown.

=head2 EIDRM

  static method EIDRM : int ();

Get the error number of C<EIDRM>. If the system doesn't define this error number, an exception is thrown.

=head2 EILSEQ

  static method EILSEQ : int ();

Get the error number of C<EILSEQ>. If the system doesn't define this error number, an exception is thrown.

=head2 EINPROGRESS

  static method EINPROGRESS : int ();

Get the error number of C<EINPROGRESS>. If the system doesn't define this error number, an exception is thrown.

=head2 EINTR

  static method EINTR : int ();

Get the error number of C<EINTR>. If the system doesn't define this error number, an exception is thrown.

=head2 EINVAL

  static method EINVAL : int ();

Get the error number of C<EINVAL>. If the system doesn't define this error number, an exception is thrown.

=head2 EIO

  static method EIO : int ();

Get the error number of C<EIO>. If the system doesn't define this error number, an exception is thrown.

=head2 EISCONN

  static method EISCONN : int ();

Get the error number of C<EISCONN>. If the system doesn't define this error number, an exception is thrown.

=head2 EISDIR

  static method EISDIR : int ();

Get the error number of C<EISDIR>. If the system doesn't define this error number, an exception is thrown.

=head2 EISNAM

  static method EISNAM : int ();

Get the error number of C<EISNAM>. If the system doesn't define this error number, an exception is thrown.

=head2 EKEYEXPIRED

  static method EKEYEXPIRED : int ();

Get the error number of C<EKEYEXPIRED>. If the system doesn't define this error number, an exception is thrown.

=head2 EKEYREJECTED

  static method EKEYREJECTED : int ();

Get the error number of C<EKEYREJECTED>. If the system doesn't define this error number, an exception is thrown.

=head2 EKEYREVOKED

  static method EKEYREVOKED : int ();

Get the error number of C<EKEYREVOKED>. If the system doesn't define this error number, an exception is thrown.

=head2 EL2HLT

  static method EL2HLT : int ();

Get the error number of C<EL2HLT>. If the system doesn't define this error number, an exception is thrown.

=head2 EL2NSYNC

  static method EL2NSYNC : int ();

Get the error number of C<EL2NSYNC>. If the system doesn't define this error number, an exception is thrown.

=head2 EL3HLT

  static method EL3HLT : int ();

Get the error number of C<EL3HLT>. If the system doesn't define this error number, an exception is thrown.

=head2 EL3RST

  static method EL3RST : int ();

Get the error number of C<EL3RST>. If the system doesn't define this error number, an exception is thrown.

=head2 ELIBACC

  static method ELIBACC : int ();

Get the error number of C<ELIBACC>. If the system doesn't define this error number, an exception is thrown.

=head2 ELIBBAD

  static method ELIBBAD : int ();

Get the error number of C<ELIBBAD>. If the system doesn't define this error number, an exception is thrown.

=head2 ELIBMAX

  static method ELIBMAX : int ();

Get the error number of C<ELIBMAX>. If the system doesn't define this error number, an exception is thrown.

=head2 ELIBSCN

  static method ELIBSCN : int ();

Get the error number of C<ELIBSCN>. If the system doesn't define this error number, an exception is thrown.

=head2 ELIBEXEC

  static method ELIBEXEC : int ();

Get the error number of C<ELIBEXEC>. If the system doesn't define this error number, an exception is thrown.

=head2 ELOOP

  static method ELOOP : int ();

Get the error number of C<ELOOP>. If the system doesn't define this error number, an exception is thrown.

=head2 EMEDIUMTYPE

  static method EMEDIUMTYPE : int ();

Get the error number of C<EMEDIUMTYPE>. If the system doesn't define this error number, an exception is thrown.

=head2 EMFILE

  static method EMFILE : int ();

Get the error number of C<EMFILE>. If the system doesn't define this error number, an exception is thrown.

=head2 EMLINK

  static method EMLINK : int ();

Get the error number of C<EMLINK>. If the system doesn't define this error number, an exception is thrown.

=head2 EMSGSIZE

  static method EMSGSIZE : int ();

Get the error number of C<EMSGSIZE>. If the system doesn't define this error number, an exception is thrown.

=head2 EMULTIHOP

  static method EMULTIHOP : int ();

Get the error number of C<EMULTIHOP>. If the system doesn't define this error number, an exception is thrown.

=head2 ENAMETOOLONG

  static method ENAMETOOLONG : int ();

Get the error number of C<ENAMETOOLONG>. If the system doesn't define this error number, an exception is thrown.

=head2 ENETDOWN

  static method ENETDOWN : int ();

Get the error number of C<ENETDOWN>. If the system doesn't define this error number, an exception is thrown.

=head2 ENETRESET

  static method ENETRESET : int ();

Get the error number of C<ENETRESET>. If the system doesn't define this error number, an exception is thrown.

=head2 ENETUNREACH

  static method ENETUNREACH : int ();

Get the error number of C<ENETUNREACH>. If the system doesn't define this error number, an exception is thrown.

=head2 ENFILE

  static method ENFILE : int ();

Get the error number of C<ENFILE>. If the system doesn't define this error number, an exception is thrown.

=head2 ENOBUFS

  static method ENOBUFS : int ();

Get the error number of C<ENOBUFS>. If the system doesn't define this error number, an exception is thrown.

=head2 ENODATA

  static method ENODATA : int ();

Get the error number of C<ENODATA>. If the system doesn't define this error number, an exception is thrown.

=head2 ENODEV

  static method ENODEV : int ();

Get the error number of C<ENODEV>. If the system doesn't define this error number, an exception is thrown.

=head2 ENOENT

  static method ENOENT : int ();

Get the error number of C<ENOENT>. If the system doesn't define this error number, an exception is thrown.

=head2 ENOEXEC

  static method ENOEXEC : int ();

Get the error number of C<ENOEXEC>. If the system doesn't define this error number, an exception is thrown.

=head2 ENOKEY

  static method ENOKEY : int ();

Get the error number of C<ENOKEY>. If the system doesn't define this error number, an exception is thrown.

=head2 ENOLCK

  static method ENOLCK : int ();

Get the error number of C<ENOLCK>. If the system doesn't define this error number, an exception is thrown.

=head2 ENOLINK

  static method ENOLINK : int ();

Get the error number of C<ENOLINK>. If the system doesn't define this error number, an exception is thrown.

=head2 ENOMEDIUM

  static method ENOMEDIUM : int ();

Get the error number of C<ENOMEDIUM>. If the system doesn't define this error number, an exception is thrown.

=head2 ENOMEM

  static method ENOMEM : int ();

Get the error number of C<ENOMEM>. If the system doesn't define this error number, an exception is thrown.

=head2 ENOMSG

  static method ENOMSG : int ();

Get the error number of C<ENOMSG>. If the system doesn't define this error number, an exception is thrown.

=head2 ENONET

  static method ENONET : int ();

Get the error number of C<ENONET>. If the system doesn't define this error number, an exception is thrown.

=head2 ENOPKG

  static method ENOPKG : int ();

Get the error number of C<ENOPKG>. If the system doesn't define this error number, an exception is thrown.

=head2 ENOPROTOOPT

  static method ENOPROTOOPT : int ();

Get the error number of C<ENOPROTOOPT>. If the system doesn't define this error number, an exception is thrown.

=head2 ENOSPC

  static method ENOSPC : int ();

Get the error number of C<ENOSPC>. If the system doesn't define this error number, an exception is thrown.

=head2 ENOSR

  static method ENOSR : int ();

Get the error number of C<ENOSR>. If the system doesn't define this error number, an exception is thrown.

=head2 ENOSTR

  static method ENOSTR : int ();

Get the error number of C<ENOSTR>. If the system doesn't define this error number, an exception is thrown.

=head2 ENOSYS

  static method ENOSYS : int ();

Get the error number of C<ENOSYS>. If the system doesn't define this error number, an exception is thrown.

=head2 ENOTBLK

  static method ENOTBLK : int ();

Get the error number of C<ENOTBLK>. If the system doesn't define this error number, an exception is thrown.

=head2 ENOTCONN

  static method ENOTCONN : int ();

Get the error number of C<ENOTCONN>. If the system doesn't define this error number, an exception is thrown.

=head2 ENOTDIR

  static method ENOTDIR : int ();

Get the error number of C<ENOTDIR>. If the system doesn't define this error number, an exception is thrown.

=head2 ENOTEMPTY

  static method ENOTEMPTY : int ();

Get the error number of C<ENOTEMPTY>. If the system doesn't define this error number, an exception is thrown.

=head2 ENOTSOCK

  static method ENOTSOCK : int ();

Get the error number of C<ENOTSOCK>. If the system doesn't define this error number, an exception is thrown.

=head2 ENOTSUP

  static method ENOTSUP : int ();

Get the error number of C<ENOTSUP>. If the system doesn't define this error number, an exception is thrown.

=head2 ENOTTY

  static method ENOTTY : int ();

Get the error number of C<ENOTTY>. If the system doesn't define this error number, an exception is thrown.

=head2 ENOTUNIQ

  static method ENOTUNIQ : int ();

Get the error number of C<ENOTUNIQ>. If the system doesn't define this error number, an exception is thrown.

=head2 ENXIO

  static method ENXIO : int ();

Get the error number of C<ENXIO>. If the system doesn't define this error number, an exception is thrown.

=head2 EOPNOTSUPP

  static method EOPNOTSUPP : int ();

Get the error number of C<EOPNOTSUPP>. If the system doesn't define this error number, an exception is thrown.

=head2 EOVERFLOW

  static method EOVERFLOW : int ();

Get the error number of C<EOVERFLOW>. If the system doesn't define this error number, an exception is thrown.

=head2 EPERM

  static method EPERM : int ();

Get the error number of C<EPERM>. If the system doesn't define this error number, an exception is thrown.

=head2 EPFNOSUPPORT

  static method EPFNOSUPPORT : int ();

Get the error number of C<EPFNOSUPPORT>. If the system doesn't define this error number, an exception is thrown.

=head2 EPIPE

  static method EPIPE : int ();

Get the error number of C<EPIPE>. If the system doesn't define this error number, an exception is thrown.

=head2 EPROTO

  static method EPROTO : int ();

Get the error number of C<EPROTO>. If the system doesn't define this error number, an exception is thrown.

=head2 EPROTONOSUPPORT

  static method EPROTONOSUPPORT : int ();

Get the error number of C<EPROTONOSUPPORT>. If the system doesn't define this error number, an exception is thrown.

=head2 EPROTOTYPE

  static method EPROTOTYPE : int ();

Get the error number of C<EPROTOTYPE>. If the system doesn't define this error number, an exception is thrown.

=head2 ERANGE

  static method ERANGE : int ();

Get the error number of C<ERANGE>. If the system doesn't define this error number, an exception is thrown.

=head2 EREMCHG

  static method EREMCHG : int ();

Get the error number of C<EREMCHG>. If the system doesn't define this error number, an exception is thrown.

=head2 EREMOTE

  static method EREMOTE : int ();

Get the error number of C<EREMOTE>. If the system doesn't define this error number, an exception is thrown.

=head2 EREMOTEIO

  static method EREMOTEIO : int ();

Get the error number of C<EREMOTEIO>. If the system doesn't define this error number, an exception is thrown.

=head2 ERESTART

  static method ERESTART : int ();

Get the error number of C<ERESTART>. If the system doesn't define this error number, an exception is thrown.

=head2 EROFS

  static method EROFS : int ();

Get the error number of C<EROFS>. If the system doesn't define this error number, an exception is thrown.

=head2 ESHUTDOWN

  static method ESHUTDOWN : int ();

Get the error number of C<ESHUTDOWN>. If the system doesn't define this error number, an exception is thrown.

=head2 ESPIPE

  static method ESPIPE : int ();

Get the error number of C<ESPIPE>. If the system doesn't define this error number, an exception is thrown.

=head2 ESOCKTNOSUPPORT

  static method ESOCKTNOSUPPORT : int ();

Get the error number of C<ESOCKTNOSUPPORT>. If the system doesn't define this error number, an exception is thrown.

=head2 ESRCH

  static method ESRCH : int ();

Get the error number of C<ESRCH>. If the system doesn't define this error number, an exception is thrown.

=head2 ESTALE

  static method ESTALE : int ();

Get the error number of C<ESTALE>. If the system doesn't define this error number, an exception is thrown.

=head2 ESTRPIPE

  static method ESTRPIPE : int ();

Get the error number of C<ESTRPIPE>. If the system doesn't define this error number, an exception is thrown.

=head2 ETIME

  static method ETIME : int ();

Get the error number of C<ETIME>. If the system doesn't define this error number, an exception is thrown.

=head2 ETIMEDOUT

  static method ETIMEDOUT : int ();

Get the error number of C<ETIMEDOUT>. If the system doesn't define this error number, an exception is thrown.

=head2 ETXTBSY

  static method ETXTBSY : int ();

Get the error number of C<ETXTBSY>. If the system doesn't define this error number, an exception is thrown.

=head2 EUCLEAN

  static method EUCLEAN : int ();

Get the error number of C<EUCLEAN>. If the system doesn't define this error number, an exception is thrown.

=head2 EUNATCH

  static method EUNATCH : int ();

Get the error number of C<EUNATCH>. If the system doesn't define this error number, an exception is thrown.

=head2 EUSERS

  static method EUSERS : int ();

Get the error number of C<EUSERS>. If the system doesn't define this error number, an exception is thrown.

=head2 EWOULDBLOCK

  static method EWOULDBLOCK : int ();

Get the error number of C<EWOULDBLOCK>. If the system doesn't define this error number, an exception is thrown.

=head2 EXDEV

  static method EXDEV : int ();

Get the error number of C<EXDEV>. If the system doesn't define this error number, an exception is thrown.

=head2 EXFULL

  static method EXFULL : int ();

Get the error number of C<EXFULL>. If the system doesn't define this error number, an exception is thrown.


=head1 Repository

L<https://github.com/yuki-kimoto/SPVM-Errno>

=head1 Author

Yuki Kimoto C<kimoto.yuki@gmail.com>

=head1 Copyright & License

Copyright 2022-2022 Yuki Kimoto, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

