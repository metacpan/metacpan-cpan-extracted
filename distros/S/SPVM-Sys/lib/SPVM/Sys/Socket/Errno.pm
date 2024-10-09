package SPVM::Sys::Socket::Errno;



1;

=head1 Name

SPVM::Sys::Socket::Errno - Socket Error Numbers

=head1 Description

Sys::Socket::Errno class in L<SPVM> has methods to get socket error numbers.

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

Calls L<Errno#WSAEINTR|SPVM::Errno/"WSAEINTR"> method in Windows,
or L<Errno#EINTR|SPVM::Errno/"EINTR"> method in other OSs,
and returns its return value.

=head2 EBADF

C<static method EBADF : int ();>

Calls L<Errno#WSAEBADF|SPVM::Errno/"WSAEBADF"> method in Windows,
or L<Errno#EBADF|SPVM::Errno/"EBADF"> method in other OSs,
and returns its return value.

=head2 EACCES

C<static method EACCES : int ();>

Calls L<Errno#WSAEACCES|SPVM::Errno/"WSAEACCES"> method in Windows,
or L<Errno#EACCES|SPVM::Errno/"EACCES"> method in other OSs,
and returns its return value.

=head2 EFAULT

C<static method EFAULT : int ();>

Calls L<Errno#WSAEFAULT|SPVM::Errno/"WSAEFAULT"> method in Windows,
or L<Errno#EFAULT|SPVM::Errno/"EFAULT"> method in other OSs,
and returns its return value.

=head2 EINVAL

C<static method EINVAL : int ();>

Calls L<Errno#WSAEINVAL|SPVM::Errno/"WSAEINVAL"> method in Windows,
or L<Errno#EINVAL|SPVM::Errno/"EINVAL"> method in other OSs,
and returns its return value.

=head2 EMFILE

C<static method EMFILE : int ();>

Calls L<Errno#WSAEMFILE|SPVM::Errno/"WSAEMFILE"> method in Windows,
or L<Errno#EMFILE|SPVM::Errno/"EMFILE"> method in other OSs,
and returns its return value.

=head2 EWOULDBLOCK

C<static method EWOULDBLOCK : int ();>

Calls L<Errno#WSAEWOULDBLOCK|SPVM::Errno/"WSAEWOULDBLOCK"> method in Windows,
or L<Errno#EWOULDBLOCK|SPVM::Errno/"EWOULDBLOCK"> method in other OSs,
and returns its return value.

=head2 EINPROGRESS

C<static method EINPROGRESS : int ();>

Calls L<Errno#WSAEINPROGRESS|SPVM::Errno/"WSAEINPROGRESS"> method in Windows,
or L<Errno#EINPROGRESS|SPVM::Errno/"EINPROGRESS"> method in other OSs,
and returns its return value.

=head2 EALREADY

C<static method EALREADY : int ();>

Calls L<Errno#WSAEALREADY|SPVM::Errno/"WSAEALREADY"> method in Windows,
or L<Errno#EALREADY|SPVM::Errno/"EALREADY"> method in other OSs,
and returns its return value.

=head2 ENOTSOCK

C<static method ENOTSOCK : int ();>

Calls L<Errno#WSAENOTSOCK|SPVM::Errno/"WSAENOTSOCK"> method in Windows,
or L<Errno#ENOTSOCK|SPVM::Errno/"ENOTSOCK"> method in other OSs,
and returns its return value.

=head2 EDESTADDRREQ

C<static method EDESTADDRREQ : int ();>

Calls L<Errno#WSAEDESTADDRREQ|SPVM::Errno/"WSAEDESTADDRREQ"> method in Windows,
or L<Errno#EDESTADDRREQ|SPVM::Errno/"EDESTADDRREQ"> method in other OSs,
and returns its return value.

=head2 EMSGSIZE

C<static method EMSGSIZE : int ();>

Calls L<Errno#WSAEMSGSIZE|SPVM::Errno/"WSAEMSGSIZE"> method in Windows,
or L<Errno#EMSGSIZE|SPVM::Errno/"EMSGSIZE"> method in other OSs,
and returns its return value.

=head2 EPROTOTYPE

C<static method EPROTOTYPE : int ();>

Calls L<Errno#WSAEPROTOTYPE|SPVM::Errno/"WSAEPROTOTYPE"> method in Windows,
or L<Errno#EPROTOTYPE|SPVM::Errno/"EPROTOTYPE"> method in other OSs,
and returns its return value.

=head2 ENOPROTOOPT

C<static method ENOPROTOOPT : int ();>

Calls L<Errno#WSAENOPROTOOPT|SPVM::Errno/"WSAENOPROTOOPT"> method in Windows,
or L<Errno#ENOPROTOOPT|SPVM::Errno/"ENOPROTOOPT"> method in other OSs,
and returns its return value.

=head2 EPROTONOSUPPORT

C<static method EPROTONOSUPPORT : int ();>

Calls L<Errno#WSAEPROTONOSUPPORT|SPVM::Errno/"WSAEPROTONOSUPPORT"> method in Windows,
or L<Errno#EPROTONOSUPPORT|SPVM::Errno/"EPROTONOSUPPORT"> method in other OSs,
and returns its return value.

=head2 ESOCKTNOSUPPORT

C<static method ESOCKTNOSUPPORT : int ();>

Calls L<Errno#WSAESOCKTNOSUPPORT|SPVM::Errno/"WSAESOCKTNOSUPPORT"> method in Windows,
or L<Errno#ESOCKTNOSUPPORT|SPVM::Errno/"ESOCKTNOSUPPORT"> method in other OSs,
and returns its return value.

=head2 EOPNOTSUPP

C<static method EOPNOTSUPP : int ();>

Calls L<Errno#WSAEOPNOTSUPP|SPVM::Errno/"WSAEOPNOTSUPP"> method in Windows,
or L<Errno#EOPNOTSUPP|SPVM::Errno/"EOPNOTSUPP"> method in other OSs,
and returns its return value.

=head2 EPFNOSUPPORT

C<static method EPFNOSUPPORT : int ();>

Calls L<Errno#WSAEPFNOSUPPORT|SPVM::Errno/"WSAEPFNOSUPPORT"> method in Windows,
or L<Errno#EPFNOSUPPORT|SPVM::Errno/"EPFNOSUPPORT"> method in other OSs,
and returns its return value.

=head2 EAFNOSUPPORT

C<static method EAFNOSUPPORT : int ();>

Calls L<Errno#WSAEAFNOSUPPORT|SPVM::Errno/"WSAEAFNOSUPPORT"> method in Windows,
or L<Errno#EAFNOSUPPORT|SPVM::Errno/"EAFNOSUPPORT"> method in other OSs,
and returns its return value.

=head2 EADDRINUSE

C<static method EADDRINUSE : int ();>

Calls L<Errno#WSAEADDRINUSE|SPVM::Errno/"WSAEADDRINUSE"> method in Windows,
or L<Errno#EADDRINUSE|SPVM::Errno/"EADDRINUSE"> method in other OSs,
and returns its return value.

=head2 EADDRNOTAVAIL

C<static method EADDRNOTAVAIL : int ();>

Calls L<Errno#WSAEADDRNOTAVAIL|SPVM::Errno/"WSAEADDRNOTAVAIL"> method in Windows,
or L<Errno#EADDRNOTAVAIL|SPVM::Errno/"EADDRNOTAVAIL"> method in other OSs,
and returns its return value.

=head2 ENETDOWN

C<static method ENETDOWN : int ();>

Calls L<Errno#WSAENETDOWN|SPVM::Errno/"WSAENETDOWN"> method in Windows,
or L<Errno#ENETDOWN|SPVM::Errno/"ENETDOWN"> method in other OSs,
and returns its return value.

=head2 ENETUNREACH

C<static method ENETUNREACH : int ();>

Calls L<Errno#WSAENETUNREACH|SPVM::Errno/"WSAENETUNREACH"> method in Windows,
or L<Errno#ENETUNREACH|SPVM::Errno/"ENETUNREACH"> method in other OSs,
and returns its return value.

=head2 ENETRESET

C<static method ENETRESET : int ();>

Calls L<Errno#WSAENETRESET|SPVM::Errno/"WSAENETRESET"> method in Windows,
or L<Errno#ENETRESET|SPVM::Errno/"ENETRESET"> method in other OSs,
and returns its return value.

=head2 ECONNABORTED

C<static method ECONNABORTED : int ();>

Calls L<Errno#WSAECONNABORTED|SPVM::Errno/"WSAECONNABORTED"> method in Windows,
or L<Errno#ECONNABORTED|SPVM::Errno/"ECONNABORTED"> method in other OSs,
and returns its return value.

=head2 ECONNRESET

C<static method ECONNRESET : int ();>

Calls L<Errno#WSAECONNRESET|SPVM::Errno/"WSAECONNRESET"> method in Windows,
or L<Errno#ECONNRESET|SPVM::Errno/"ECONNRESET"> method in other OSs,
and returns its return value.

=head2 ENOBUFS

C<static method ENOBUFS : int ();>

Calls L<Errno#WSAENOBUFS|SPVM::Errno/"WSAENOBUFS"> method in Windows,
or L<Errno#ENOBUFS|SPVM::Errno/"ENOBUFS"> method in other OSs,
and returns its return value.

=head2 EISCONN

C<static method EISCONN : int ();>

Calls L<Errno#WSAEISCONN|SPVM::Errno/"WSAEISCONN"> method in Windows,
or L<Errno#EISCONN|SPVM::Errno/"EISCONN"> method in other OSs,
and returns its return value.

=head2 ENOTCONN

C<static method ENOTCONN : int ();>

Calls L<Errno#WSAENOTCONN|SPVM::Errno/"WSAENOTCONN"> method in Windows,
or L<Errno#ENOTCONN|SPVM::Errno/"ENOTCONN"> method in other OSs,
and returns its return value.

=head2 ESHUTDOWN

C<static method ESHUTDOWN : int ();>

Calls L<Errno#WSAESHUTDOWN|SPVM::Errno/"WSAESHUTDOWN"> method in Windows,
or L<Errno#ESHUTDOWN|SPVM::Errno/"ESHUTDOWN"> method in other OSs,
and returns its return value.

=head2 ETIMEDOUT

C<static method ETIMEDOUT : int ();>

Calls L<Errno#WSAETIMEDOUT|SPVM::Errno/"WSAETIMEDOUT"> method in Windows,
or L<Errno#ETIMEDOUT|SPVM::Errno/"ETIMEDOUT"> method in other OSs,
and returns its return value.

=head2 ECONNREFUSED

C<static method ECONNREFUSED : int ();>

Calls L<Errno#WSAECONNREFUSED|SPVM::Errno/"WSAECONNREFUSED"> method in Windows,
or L<Errno#ECONNREFUSED|SPVM::Errno/"ECONNREFUSED"> method in other OSs,
and returns its return value.

=head2 ELOOP

C<static method ELOOP : int ();>

Calls L<Errno#WSAELOOP|SPVM::Errno/"WSAELOOP"> method in Windows,
or L<Errno#ELOOP|SPVM::Errno/"ELOOP"> method in other OSs,
and returns its return value.

=head2 ENAMETOOLONG

C<static method ENAMETOOLONG : int ();>

Calls L<Errno#WSAENAMETOOLONG|SPVM::Errno/"WSAENAMETOOLONG"> method in Windows,
or L<Errno#ENAMETOOLONG|SPVM::Errno/"ENAMETOOLONG"> method in other OSs,
and returns its return value.

=head2 EHOSTDOWN

C<static method EHOSTDOWN : int ();>

Calls L<Errno#WSAEHOSTDOWN|SPVM::Errno/"WSAEHOSTDOWN"> method in Windows,
or L<Errno#EHOSTDOWN|SPVM::Errno/"EHOSTDOWN"> method in other OSs,
and returns its return value.

=head2 EHOSTUNREACH

C<static method EHOSTUNREACH : int ();>

Calls L<Errno#WSAEHOSTUNREACH|SPVM::Errno/"WSAEHOSTUNREACH"> method in Windows,
or L<Errno#EHOSTUNREACH|SPVM::Errno/"EHOSTUNREACH"> method in other OSs,
and returns its return value.

=head2 ENOTEMPTY

C<static method ENOTEMPTY : int ();>

Calls L<Errno#WSAENOTEMPTY|SPVM::Errno/"WSAENOTEMPTY"> method in Windows,
or L<Errno#ENOTEMPTY|SPVM::Errno/"ENOTEMPTY"> method in other OSs,
and returns its return value.

=head2 EUSERS

C<static method EUSERS : int ();>

Calls L<Errno#WSAEUSERS|SPVM::Errno/"WSAEUSERS"> method in Windows,
or L<Errno#EUSERS|SPVM::Errno/"EUSERS"> method in other OSs,
and returns its return value.

=head2 EDQUOT

C<static method EDQUOT : int ();>

Calls L<Errno#WSAEDQUOT|SPVM::Errno/"WSAEDQUOT"> method in Windows,
or L<Errno#EDQUOT|SPVM::Errno/"EDQUOT"> method in other OSs,
and returns its return value.

=head2 ESTALE

C<static method ESTALE : int ();>

Calls L<Errno#WSAESTALE|SPVM::Errno/"WSAESTALE"> method in Windows,
or L<Errno#ESTALE|SPVM::Errno/"ESTALE"> method in other OSs,
and returns its return value.

=head2 EREMOTE

C<static method EREMOTE : int ();>

Calls L<Errno#WSAEREMOTE|SPVM::Errno/"WSAEREMOTE"> method in Windows,
or L<Errno#EREMOTE|SPVM::Errno/"EREMOTE"> method in other OSs,
and returns its return value.

=head1 Copyright & License

Copyright (c) 2023 Yuki Kimoto

MIT License

