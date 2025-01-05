use Test::More;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
BEGIN { $ENV{SPVM_BUILD_DIR} = "$FindBin::Bin/.spvm_build"; }
use Time::HiRes 'usleep';

use SPVM 'Errno';
use SPVM 'Sys::Socket::Errno';

my $api = SPVM::api();

my $start_memory_blocks_count = $api->get_memory_blocks_count();

# is_read_again
{
  ok(SPVM::Sys::Socket::Errno->is_read_again(SPVM::Sys::Socket::Errno->EINTR));
  ok(SPVM::Sys::Socket::Errno->is_read_again(SPVM::Sys::Socket::Errno->EWOULDBLOCK));
  ok(!SPVM::Sys::Socket::Errno->is_read_again(SPVM::Sys::Socket::Errno->EBADF));
}

# is_write_again
{
  ok(SPVM::Sys::Socket::Errno->is_write_again(SPVM::Sys::Socket::Errno->EINTR));
  ok(SPVM::Sys::Socket::Errno->is_write_again(SPVM::Sys::Socket::Errno->EWOULDBLOCK));
  ok(!SPVM::Sys::Socket::Errno->is_write_again(SPVM::Sys::Socket::Errno->EBADF));
}

# is_connect_again
{
  ok(SPVM::Sys::Socket::Errno->is_connect_again(SPVM::Sys::Socket::Errno->EINTR));
  ok(SPVM::Sys::Socket::Errno->is_connect_again(SPVM::Sys::Socket::Errno->EWOULDBLOCK));
  ok(SPVM::Sys::Socket::Errno->is_connect_again(SPVM::Sys::Socket::Errno->EINPROGRESS));
  ok(!SPVM::Sys::Socket::Errno->is_connect_again(SPVM::Sys::Socket::Errno->EBADF));
}

# is_accept_again
{
  ok(SPVM::Sys::Socket::Errno->is_accept_again(SPVM::Sys::Socket::Errno->EINTR));
  ok(SPVM::Sys::Socket::Errno->is_accept_again(SPVM::Sys::Socket::Errno->EWOULDBLOCK));
  ok(!SPVM::Sys::Socket::Errno->is_accept_again(SPVM::Sys::Socket::Errno->EBADF));
}

# The constant values
{
  if ($^O eq 'MSWin32') {
    is(SPVM::Sys::Socket::Errno->EINTR, SPVM::Errno->WSAEINTR);
  }
  else {
    is(SPVM::Sys::Socket::Errno->EINTR, SPVM::Errno->EINTR);
  }

  if ($^O eq 'MSWin32') {
    is(SPVM::Sys::Socket::Errno->EBADF, SPVM::Errno->WSAEBADF);
  }
  else {
    is(SPVM::Sys::Socket::Errno->EBADF, SPVM::Errno->EBADF);
  }

  if ($^O eq 'MSWin32') {
    is(SPVM::Sys::Socket::Errno->EACCES, SPVM::Errno->WSAEACCES);
  }
  else {
    is(SPVM::Sys::Socket::Errno->EACCES, SPVM::Errno->EACCES);
  }

  if ($^O eq 'MSWin32') {
    is(SPVM::Sys::Socket::Errno->EFAULT, SPVM::Errno->WSAEFAULT);
  }
  else {
    is(SPVM::Sys::Socket::Errno->EFAULT, SPVM::Errno->EFAULT);
  }

  if ($^O eq 'MSWin32') {
    is(SPVM::Sys::Socket::Errno->EINVAL, SPVM::Errno->WSAEINVAL);
  }
  else {
    is(SPVM::Sys::Socket::Errno->EINVAL, SPVM::Errno->EINVAL);
  }

  if ($^O eq 'MSWin32') {
    is(SPVM::Sys::Socket::Errno->EMFILE, SPVM::Errno->WSAEMFILE);
  }
  else {
    is(SPVM::Sys::Socket::Errno->EMFILE, SPVM::Errno->EMFILE);
  }

  if ($^O eq 'MSWin32') {
    is(SPVM::Sys::Socket::Errno->EWOULDBLOCK, SPVM::Errno->WSAEWOULDBLOCK);
  }
  else {
    is(SPVM::Sys::Socket::Errno->EWOULDBLOCK, SPVM::Errno->EWOULDBLOCK);
  }

  if ($^O eq 'MSWin32') {
    is(SPVM::Sys::Socket::Errno->EINPROGRESS, SPVM::Errno->WSAEINPROGRESS);
  }
  else {
    is(SPVM::Sys::Socket::Errno->EINPROGRESS, SPVM::Errno->EINPROGRESS);
  }

  if ($^O eq 'MSWin32') {
    is(SPVM::Sys::Socket::Errno->EALREADY, SPVM::Errno->WSAEALREADY);
  }
  else {
    is(SPVM::Sys::Socket::Errno->EALREADY, SPVM::Errno->EALREADY);
  }

  if ($^O eq 'MSWin32') {
    is(SPVM::Sys::Socket::Errno->ENOTSOCK, SPVM::Errno->WSAENOTSOCK);
  }
  else {
    is(SPVM::Sys::Socket::Errno->ENOTSOCK, SPVM::Errno->ENOTSOCK);
  }

  if ($^O eq 'MSWin32') {
    is(SPVM::Sys::Socket::Errno->EDESTADDRREQ, SPVM::Errno->WSAEDESTADDRREQ);
  }
  else {
    is(SPVM::Sys::Socket::Errno->EDESTADDRREQ, SPVM::Errno->EDESTADDRREQ);
  }

  if ($^O eq 'MSWin32') {
    is(SPVM::Sys::Socket::Errno->EMSGSIZE, SPVM::Errno->WSAEMSGSIZE);
  }
  else {
    is(SPVM::Sys::Socket::Errno->EMSGSIZE, SPVM::Errno->EMSGSIZE);
  }

  if ($^O eq 'MSWin32') {
    is(SPVM::Sys::Socket::Errno->EPROTOTYPE, SPVM::Errno->WSAEPROTOTYPE);
  }
  else {
    is(SPVM::Sys::Socket::Errno->EPROTOTYPE, SPVM::Errno->EPROTOTYPE);
  }

  if ($^O eq 'MSWin32') {
    is(SPVM::Sys::Socket::Errno->ENOPROTOOPT, SPVM::Errno->WSAENOPROTOOPT);
  }
  else {
    is(SPVM::Sys::Socket::Errno->ENOPROTOOPT, SPVM::Errno->ENOPROTOOPT);
  }

  if ($^O eq 'MSWin32') {
    is(SPVM::Sys::Socket::Errno->EPROTONOSUPPORT, SPVM::Errno->WSAEPROTONOSUPPORT);
  }
  else {
    is(SPVM::Sys::Socket::Errno->EPROTONOSUPPORT, SPVM::Errno->EPROTONOSUPPORT);
  }

  if ($^O eq 'MSWin32') {
    is(SPVM::Sys::Socket::Errno->ESOCKTNOSUPPORT, SPVM::Errno->WSAESOCKTNOSUPPORT);
  }
  else {
    is(SPVM::Sys::Socket::Errno->ESOCKTNOSUPPORT, SPVM::Errno->ESOCKTNOSUPPORT);
  }

  if ($^O eq 'MSWin32') {
    is(SPVM::Sys::Socket::Errno->EOPNOTSUPP, SPVM::Errno->WSAEOPNOTSUPP);
  }
  else {
    is(SPVM::Sys::Socket::Errno->EOPNOTSUPP, SPVM::Errno->EOPNOTSUPP);
  }

  if ($^O eq 'MSWin32') {
    is(SPVM::Sys::Socket::Errno->EPFNOSUPPORT, SPVM::Errno->WSAEPFNOSUPPORT);
  }
  else {
    is(SPVM::Sys::Socket::Errno->EPFNOSUPPORT, SPVM::Errno->EPFNOSUPPORT);
  }

  if ($^O eq 'MSWin32') {
    is(SPVM::Sys::Socket::Errno->EAFNOSUPPORT, SPVM::Errno->WSAEAFNOSUPPORT);
  }
  else {
    is(SPVM::Sys::Socket::Errno->EAFNOSUPPORT, SPVM::Errno->EAFNOSUPPORT);
  }

  if ($^O eq 'MSWin32') {
    is(SPVM::Sys::Socket::Errno->EADDRINUSE, SPVM::Errno->WSAEADDRINUSE);
  }
  else {
    is(SPVM::Sys::Socket::Errno->EADDRINUSE, SPVM::Errno->EADDRINUSE);
  }

  if ($^O eq 'MSWin32') {
    is(SPVM::Sys::Socket::Errno->EADDRNOTAVAIL, SPVM::Errno->WSAEADDRNOTAVAIL);
  }
  else {
    is(SPVM::Sys::Socket::Errno->EADDRNOTAVAIL, SPVM::Errno->EADDRNOTAVAIL);
  }

  if ($^O eq 'MSWin32') {
    is(SPVM::Sys::Socket::Errno->ENETDOWN, SPVM::Errno->WSAENETDOWN);
  }
  else {
    is(SPVM::Sys::Socket::Errno->ENETDOWN, SPVM::Errno->ENETDOWN);
  }

  if ($^O eq 'MSWin32') {
    is(SPVM::Sys::Socket::Errno->ENETUNREACH, SPVM::Errno->WSAENETUNREACH);
  }
  else {
    is(SPVM::Sys::Socket::Errno->ENETUNREACH, SPVM::Errno->ENETUNREACH);
  }

  if ($^O eq 'MSWin32') {
    is(SPVM::Sys::Socket::Errno->ENETRESET, SPVM::Errno->WSAENETRESET);
  }
  else {
    is(SPVM::Sys::Socket::Errno->ENETRESET, SPVM::Errno->ENETRESET);
  }

  if ($^O eq 'MSWin32') {
    is(SPVM::Sys::Socket::Errno->ECONNABORTED, SPVM::Errno->WSAECONNABORTED);
  }
  else {
    is(SPVM::Sys::Socket::Errno->ECONNABORTED, SPVM::Errno->ECONNABORTED);
  }

  if ($^O eq 'MSWin32') {
    is(SPVM::Sys::Socket::Errno->ECONNRESET, SPVM::Errno->WSAECONNRESET);
  }
  else {
    is(SPVM::Sys::Socket::Errno->ECONNRESET, SPVM::Errno->ECONNRESET);
  }

  if ($^O eq 'MSWin32') {
    is(SPVM::Sys::Socket::Errno->ENOBUFS, SPVM::Errno->WSAENOBUFS);
  }
  else {
    is(SPVM::Sys::Socket::Errno->ENOBUFS, SPVM::Errno->ENOBUFS);
  }

  if ($^O eq 'MSWin32') {
    is(SPVM::Sys::Socket::Errno->EISCONN, SPVM::Errno->WSAEISCONN);
  }
  else {
    is(SPVM::Sys::Socket::Errno->EISCONN, SPVM::Errno->EISCONN);
  }

  if ($^O eq 'MSWin32') {
    is(SPVM::Sys::Socket::Errno->ENOTCONN, SPVM::Errno->WSAENOTCONN);
  }
  else {
    is(SPVM::Sys::Socket::Errno->ENOTCONN, SPVM::Errno->ENOTCONN);
  }

  if ($^O eq 'MSWin32') {
    is(SPVM::Sys::Socket::Errno->ESHUTDOWN, SPVM::Errno->WSAESHUTDOWN);
  }
  else {
    is(SPVM::Sys::Socket::Errno->ESHUTDOWN, SPVM::Errno->ESHUTDOWN);
  }

  if ($^O eq 'MSWin32') {
    is(SPVM::Sys::Socket::Errno->ETIMEDOUT, SPVM::Errno->WSAETIMEDOUT);
  }
  else {
    is(SPVM::Sys::Socket::Errno->ETIMEDOUT, SPVM::Errno->ETIMEDOUT);
  }

  if ($^O eq 'MSWin32') {
    is(SPVM::Sys::Socket::Errno->ECONNREFUSED, SPVM::Errno->WSAECONNREFUSED);
  }
  else {
    is(SPVM::Sys::Socket::Errno->ECONNREFUSED, SPVM::Errno->ECONNREFUSED);
  }

  if ($^O eq 'MSWin32') {
    is(SPVM::Sys::Socket::Errno->ELOOP, SPVM::Errno->WSAELOOP);
  }
  else {
    is(SPVM::Sys::Socket::Errno->ELOOP, SPVM::Errno->ELOOP);
  }

  if ($^O eq 'MSWin32') {
    is(SPVM::Sys::Socket::Errno->ENAMETOOLONG, SPVM::Errno->WSAENAMETOOLONG);
  }
  else {
    is(SPVM::Sys::Socket::Errno->ENAMETOOLONG, SPVM::Errno->ENAMETOOLONG);
  }

  if ($^O eq 'MSWin32') {
    is(SPVM::Sys::Socket::Errno->EHOSTDOWN, SPVM::Errno->WSAEHOSTDOWN);
  }
  else {
    is(SPVM::Sys::Socket::Errno->EHOSTDOWN, SPVM::Errno->EHOSTDOWN);
  }

  if ($^O eq 'MSWin32') {
    is(SPVM::Sys::Socket::Errno->EHOSTUNREACH, SPVM::Errno->WSAEHOSTUNREACH);
  }
  else {
    is(SPVM::Sys::Socket::Errno->EHOSTUNREACH, SPVM::Errno->EHOSTUNREACH);
  }

  if ($^O eq 'MSWin32') {
    is(SPVM::Sys::Socket::Errno->ENOTEMPTY, SPVM::Errno->WSAENOTEMPTY);
  }
  else {
    is(SPVM::Sys::Socket::Errno->ENOTEMPTY, SPVM::Errno->ENOTEMPTY);
  }

  if ($^O eq 'MSWin32') {
    is(SPVM::Sys::Socket::Errno->EUSERS, SPVM::Errno->WSAEUSERS);
  }
  else {
    is(SPVM::Sys::Socket::Errno->EUSERS, SPVM::Errno->EUSERS);
  }

  if ($^O eq 'MSWin32') {
    is(SPVM::Sys::Socket::Errno->EDQUOT, SPVM::Errno->WSAEDQUOT);
  }
  else {
    is(SPVM::Sys::Socket::Errno->EDQUOT, SPVM::Errno->EDQUOT);
  }

  if ($^O eq 'MSWin32') {
    is(SPVM::Sys::Socket::Errno->ESTALE, SPVM::Errno->WSAESTALE);
  }
  else {
    is(SPVM::Sys::Socket::Errno->ESTALE, SPVM::Errno->ESTALE);
  }

  if ($^O eq 'MSWin32') {
    is(SPVM::Sys::Socket::Errno->EREMOTE, SPVM::Errno->WSAEREMOTE);
  }
  else {
    is(SPVM::Sys::Socket::Errno->EREMOTE, SPVM::Errno->EREMOTE);
  }
}

my $end_memory_blocks_count = SPVM::api->get_memory_blocks_count();
is($end_memory_blocks_count, $start_memory_blocks_count);

done_testing;
