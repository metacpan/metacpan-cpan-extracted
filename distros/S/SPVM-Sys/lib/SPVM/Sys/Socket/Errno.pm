package SPVM::Sys::Socket::Errno;



1;

=head1 Name

SPVM::Sys::Socket::Errno - Socket Error Numbers

=head1 Description

The Sys::Socket::Errno class in L<SPVM> has methods to get socket error numbers.

=head1 Usage

  use Sys::Socket::Errno;
  
  my $errno = Sys::Socket::Errno->errno;
  
  my $strerror = Sys::Socket::Errno->strerror($errno);
  

=head1 Class Methods

=head2 errno

C<static method errno : int ();>

Returns C<errno> related to sockets in a portable way.

=head2 strerror

C<static method strerror : string ($errno : int, $length : int = 0);>

Returns C<strerror> related to sockets in a portable way given enough length $max_length to hold the error message..

If $length is 0, an appropriate default value is set.

=head2 EINTR

C<static method EINTR : int ();>

Calls the L<WSAEINTR|SPVM::Errno/"WSAEINTR"> method in the L<Errno|SPVM::Errno> class in Windows,
or the L<EINTR|SPVM::Errno/"EINTR"> method in the L<Errno|SPVM::Errno> class in other OSs,
and returns its return value.

=head2 EBADF

C<static method EBADF : int ();>

Calls the L<WSAEBADF|SPVM::Errno/"WSAEBADF"> method in the L<Errno|SPVM::Errno> class in Windows,
or the L<EBADF|SPVM::Errno/"EBADF"> method in the L<Errno|SPVM::Errno> class in other OSs,
and returns its return value.

=head2 EACCES

C<static method EACCES : int ();>

Calls the L<WSAEACCES|SPVM::Errno/"WSAEACCES"> method in the L<Errno|SPVM::Errno> class in Windows,
or the L<EACCES|SPVM::Errno/"EACCES"> method in the L<Errno|SPVM::Errno> class in other OSs,
and returns its return value.

=head2 EFAULT

C<static method EFAULT : int ();>

Calls the L<WSAEFAULT|SPVM::Errno/"WSAEFAULT"> method in the L<Errno|SPVM::Errno> class in Windows,
or the L<EFAULT|SPVM::Errno/"EFAULT"> method in the L<Errno|SPVM::Errno> class in other OSs,
and returns its return value.

=head2 EINVAL

C<static method EINVAL : int ();>

Calls the L<WSAEINVAL|SPVM::Errno/"WSAEINVAL"> method in the L<Errno|SPVM::Errno> class in Windows,
or the L<EINVAL|SPVM::Errno/"EINVAL"> method in the L<Errno|SPVM::Errno> class in other OSs,
and returns its return value.

=head2 EMFILE

C<static method EMFILE : int ();>

Calls the L<WSAEMFILE|SPVM::Errno/"WSAEMFILE"> method in the L<Errno|SPVM::Errno> class in Windows,
or the L<EMFILE|SPVM::Errno/"EMFILE"> method in the L<Errno|SPVM::Errno> class in other OSs,
and returns its return value.

=head2 EWOULDBLOCK

C<static method EWOULDBLOCK : int ();>

Calls the L<WSAEWOULDBLOCK|SPVM::Errno/"WSAEWOULDBLOCK"> method in the L<Errno|SPVM::Errno> class in Windows,
or the L<EWOULDBLOCK|SPVM::Errno/"EWOULDBLOCK"> method in the L<Errno|SPVM::Errno> class in other OSs,
and returns its return value.

=head2 EINPROGRESS

C<static method EINPROGRESS : int ();>

Calls the L<WSAEINPROGRESS|SPVM::Errno/"WSAEINPROGRESS"> method in the L<Errno|SPVM::Errno> class in Windows,
or the L<EINPROGRESS|SPVM::Errno/"EINPROGRESS"> method in the L<Errno|SPVM::Errno> class in other OSs,
and returns its return value.

=head2 EALREADY

C<static method EALREADY : int ();>

Calls the L<WSAEALREADY|SPVM::Errno/"WSAEALREADY"> method in the L<Errno|SPVM::Errno> class in Windows,
or the L<EALREADY|SPVM::Errno/"EALREADY"> method in the L<Errno|SPVM::Errno> class in other OSs,
and returns its return value.

=head2 ENOTSOCK

C<static method ENOTSOCK : int ();>

Calls the L<WSAENOTSOCK|SPVM::Errno/"WSAENOTSOCK"> method in the L<Errno|SPVM::Errno> class in Windows,
or the L<ENOTSOCK|SPVM::Errno/"ENOTSOCK"> method in the L<Errno|SPVM::Errno> class in other OSs,
and returns its return value.

=head2 EDESTADDRREQ

C<static method EDESTADDRREQ : int ();>

Calls the L<WSAEDESTADDRREQ|SPVM::Errno/"WSAEDESTADDRREQ"> method in the L<Errno|SPVM::Errno> class in Windows,
or the L<EDESTADDRREQ|SPVM::Errno/"EDESTADDRREQ"> method in the L<Errno|SPVM::Errno> class in other OSs,
and returns its return value.

=head2 EMSGSIZE

C<static method EMSGSIZE : int ();>

Calls the L<WSAEMSGSIZE|SPVM::Errno/"WSAEMSGSIZE"> method in the L<Errno|SPVM::Errno> class in Windows,
or the L<EMSGSIZE|SPVM::Errno/"EMSGSIZE"> method in the L<Errno|SPVM::Errno> class in other OSs,
and returns its return value.

=head2 EPROTOTYPE

C<static method EPROTOTYPE : int ();>

Calls the L<WSAEPROTOTYPE|SPVM::Errno/"WSAEPROTOTYPE"> method in the L<Errno|SPVM::Errno> class in Windows,
or the L<EPROTOTYPE|SPVM::Errno/"EPROTOTYPE"> method in the L<Errno|SPVM::Errno> class in other OSs,
and returns its return value.

=head2 ENOPROTOOPT

C<static method ENOPROTOOPT : int ();>

Calls the L<WSAENOPROTOOPT|SPVM::Errno/"WSAENOPROTOOPT"> method in the L<Errno|SPVM::Errno> class in Windows,
or the L<ENOPROTOOPT|SPVM::Errno/"ENOPROTOOPT"> method in the L<Errno|SPVM::Errno> class in other OSs,
and returns its return value.

=head2 EPROTONOSUPPORT

C<static method EPROTONOSUPPORT : int ();>

Calls the L<WSAEPROTONOSUPPORT|SPVM::Errno/"WSAEPROTONOSUPPORT"> method in the L<Errno|SPVM::Errno> class in Windows,
or the L<EPROTONOSUPPORT|SPVM::Errno/"EPROTONOSUPPORT"> method in the L<Errno|SPVM::Errno> class in other OSs,
and returns its return value.

=head2 ESOCKTNOSUPPORT

C<static method ESOCKTNOSUPPORT : int ();>

Calls the L<WSAESOCKTNOSUPPORT|SPVM::Errno/"WSAESOCKTNOSUPPORT"> method in the L<Errno|SPVM::Errno> class in Windows,
or the L<ESOCKTNOSUPPORT|SPVM::Errno/"ESOCKTNOSUPPORT"> method in the L<Errno|SPVM::Errno> class in other OSs,
and returns its return value.

=head2 EOPNOTSUPP

C<static method EOPNOTSUPP : int ();>

Calls the L<WSAEOPNOTSUPP|SPVM::Errno/"WSAEOPNOTSUPP"> method in the L<Errno|SPVM::Errno> class in Windows,
or the L<EOPNOTSUPP|SPVM::Errno/"EOPNOTSUPP"> method in the L<Errno|SPVM::Errno> class in other OSs,
and returns its return value.

=head2 EPFNOSUPPORT

C<static method EPFNOSUPPORT : int ();>

Calls the L<WSAEPFNOSUPPORT|SPVM::Errno/"WSAEPFNOSUPPORT"> method in the L<Errno|SPVM::Errno> class in Windows,
or the L<EPFNOSUPPORT|SPVM::Errno/"EPFNOSUPPORT"> method in the L<Errno|SPVM::Errno> class in other OSs,
and returns its return value.

=head2 EAFNOSUPPORT

C<static method EAFNOSUPPORT : int ();>

Calls the L<WSAEAFNOSUPPORT|SPVM::Errno/"WSAEAFNOSUPPORT"> method in the L<Errno|SPVM::Errno> class in Windows,
or the L<EAFNOSUPPORT|SPVM::Errno/"EAFNOSUPPORT"> method in the L<Errno|SPVM::Errno> class in other OSs,
and returns its return value.

=head2 EADDRINUSE

C<static method EADDRINUSE : int ();>

Calls the L<WSAEADDRINUSE|SPVM::Errno/"WSAEADDRINUSE"> method in the L<Errno|SPVM::Errno> class in Windows,
or the L<EADDRINUSE|SPVM::Errno/"EADDRINUSE"> method in the L<Errno|SPVM::Errno> class in other OSs,
and returns its return value.

=head2 EADDRNOTAVAIL

C<static method EADDRNOTAVAIL : int ();>

Calls the L<WSAEADDRNOTAVAIL|SPVM::Errno/"WSAEADDRNOTAVAIL"> method in the L<Errno|SPVM::Errno> class in Windows,
or the L<EADDRNOTAVAIL|SPVM::Errno/"EADDRNOTAVAIL"> method in the L<Errno|SPVM::Errno> class in other OSs,
and returns its return value.

=head2 ENETDOWN

C<static method ENETDOWN : int ();>

Calls the L<WSAENETDOWN|SPVM::Errno/"WSAENETDOWN"> method in the L<Errno|SPVM::Errno> class in Windows,
or the L<ENETDOWN|SPVM::Errno/"ENETDOWN"> method in the L<Errno|SPVM::Errno> class in other OSs,
and returns its return value.

=head2 ENETUNREACH

C<static method ENETUNREACH : int ();>

Calls the L<WSAENETUNREACH|SPVM::Errno/"WSAENETUNREACH"> method in the L<Errno|SPVM::Errno> class in Windows,
or the L<ENETUNREACH|SPVM::Errno/"ENETUNREACH"> method in the L<Errno|SPVM::Errno> class in other OSs,
and returns its return value.

=head2 ENETRESET

C<static method ENETRESET : int ();>

Calls the L<WSAENETRESET|SPVM::Errno/"WSAENETRESET"> method in the L<Errno|SPVM::Errno> class in Windows,
or the L<ENETRESET|SPVM::Errno/"ENETRESET"> method in the L<Errno|SPVM::Errno> class in other OSs,
and returns its return value.

=head2 ECONNABORTED

C<static method ECONNABORTED : int ();>

Calls the L<WSAECONNABORTED|SPVM::Errno/"WSAECONNABORTED"> method in the L<Errno|SPVM::Errno> class in Windows,
or the L<ECONNABORTED|SPVM::Errno/"ECONNABORTED"> method in the L<Errno|SPVM::Errno> class in other OSs,
and returns its return value.

=head2 ECONNRESET

C<static method ECONNRESET : int ();>

Calls the L<WSAECONNRESET|SPVM::Errno/"WSAECONNRESET"> method in the L<Errno|SPVM::Errno> class in Windows,
or the L<ECONNRESET|SPVM::Errno/"ECONNRESET"> method in the L<Errno|SPVM::Errno> class in other OSs,
and returns its return value.

=head2 ENOBUFS

C<static method ENOBUFS : int ();>

Calls the L<WSAENOBUFS|SPVM::Errno/"WSAENOBUFS"> method in the L<Errno|SPVM::Errno> class in Windows,
or the L<ENOBUFS|SPVM::Errno/"ENOBUFS"> method in the L<Errno|SPVM::Errno> class in other OSs,
and returns its return value.

=head2 EISCONN

C<static method EISCONN : int ();>

Calls the L<WSAEISCONN|SPVM::Errno/"WSAEISCONN"> method in the L<Errno|SPVM::Errno> class in Windows,
or the L<EISCONN|SPVM::Errno/"EISCONN"> method in the L<Errno|SPVM::Errno> class in other OSs,
and returns its return value.

=head2 ENOTCONN

C<static method ENOTCONN : int ();>

Calls the L<WSAENOTCONN|SPVM::Errno/"WSAENOTCONN"> method in the L<Errno|SPVM::Errno> class in Windows,
or the L<ENOTCONN|SPVM::Errno/"ENOTCONN"> method in the L<Errno|SPVM::Errno> class in other OSs,
and returns its return value.

=head2 ESHUTDOWN

C<static method ESHUTDOWN : int ();>

Calls the L<WSAESHUTDOWN|SPVM::Errno/"WSAESHUTDOWN"> method in the L<Errno|SPVM::Errno> class in Windows,
or the L<ESHUTDOWN|SPVM::Errno/"ESHUTDOWN"> method in the L<Errno|SPVM::Errno> class in other OSs,
and returns its return value.

=head2 ETIMEDOUT

C<static method ETIMEDOUT : int ();>

Calls the L<WSAETIMEDOUT|SPVM::Errno/"WSAETIMEDOUT"> method in the L<Errno|SPVM::Errno> class in Windows,
or the L<ETIMEDOUT|SPVM::Errno/"ETIMEDOUT"> method in the L<Errno|SPVM::Errno> class in other OSs,
and returns its return value.

=head2 ECONNREFUSED

C<static method ECONNREFUSED : int ();>

Calls the L<WSAECONNREFUSED|SPVM::Errno/"WSAECONNREFUSED"> method in the L<Errno|SPVM::Errno> class in Windows,
or the L<ECONNREFUSED|SPVM::Errno/"ECONNREFUSED"> method in the L<Errno|SPVM::Errno> class in other OSs,
and returns its return value.

=head2 ELOOP

C<static method ELOOP : int ();>

Calls the L<WSAELOOP|SPVM::Errno/"WSAELOOP"> method in the L<Errno|SPVM::Errno> class in Windows,
or the L<ELOOP|SPVM::Errno/"ELOOP"> method in the L<Errno|SPVM::Errno> class in other OSs,
and returns its return value.

=head2 ENAMETOOLONG

C<static method ENAMETOOLONG : int ();>

Calls the L<WSAENAMETOOLONG|SPVM::Errno/"WSAENAMETOOLONG"> method in the L<Errno|SPVM::Errno> class in Windows,
or the L<ENAMETOOLONG|SPVM::Errno/"ENAMETOOLONG"> method in the L<Errno|SPVM::Errno> class in other OSs,
and returns its return value.

=head2 EHOSTDOWN

C<static method EHOSTDOWN : int ();>

Calls the L<WSAEHOSTDOWN|SPVM::Errno/"WSAEHOSTDOWN"> method in the L<Errno|SPVM::Errno> class in Windows,
or the L<EHOSTDOWN|SPVM::Errno/"EHOSTDOWN"> method in the L<Errno|SPVM::Errno> class in other OSs,
and returns its return value.

=head2 EHOSTUNREACH

C<static method EHOSTUNREACH : int ();>

Calls the L<WSAEHOSTUNREACH|SPVM::Errno/"WSAEHOSTUNREACH"> method in the L<Errno|SPVM::Errno> class in Windows,
or the L<EHOSTUNREACH|SPVM::Errno/"EHOSTUNREACH"> method in the L<Errno|SPVM::Errno> class in other OSs,
and returns its return value.

=head2 ENOTEMPTY

C<static method ENOTEMPTY : int ();>

Calls the L<WSAENOTEMPTY|SPVM::Errno/"WSAENOTEMPTY"> method in the L<Errno|SPVM::Errno> class in Windows,
or the L<ENOTEMPTY|SPVM::Errno/"ENOTEMPTY"> method in the L<Errno|SPVM::Errno> class in other OSs,
and returns its return value.

=head2 EUSERS

C<static method EUSERS : int ();>

Calls the L<WSAEUSERS|SPVM::Errno/"WSAEUSERS"> method in the L<Errno|SPVM::Errno> class in Windows,
or the L<EUSERS|SPVM::Errno/"EUSERS"> method in the L<Errno|SPVM::Errno> class in other OSs,
and returns its return value.

=head2 EDQUOT

C<static method EDQUOT : int ();>

Calls the L<WSAEDQUOT|SPVM::Errno/"WSAEDQUOT"> method in the L<Errno|SPVM::Errno> class in Windows,
or the L<EDQUOT|SPVM::Errno/"EDQUOT"> method in the L<Errno|SPVM::Errno> class in other OSs,
and returns its return value.

=head2 ESTALE

C<static method ESTALE : int ();>

Calls the L<WSAESTALE|SPVM::Errno/"WSAESTALE"> method in the L<Errno|SPVM::Errno> class in Windows,
or the L<ESTALE|SPVM::Errno/"ESTALE"> method in the L<Errno|SPVM::Errno> class in other OSs,
and returns its return value.

=head2 EREMOTE

C<static method EREMOTE : int ();>

Calls the L<WSAEREMOTE|SPVM::Errno/"WSAEREMOTE"> method in the L<Errno|SPVM::Errno> class in Windows,
or the L<EREMOTE|SPVM::Errno/"EREMOTE"> method in the L<Errno|SPVM::Errno> class in other OSs,
and returns its return value.

=head1 Copyright & License

Copyright (c) 2023 Yuki Kimoto

MIT License

