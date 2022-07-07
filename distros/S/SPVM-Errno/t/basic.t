use Test::More;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
BEGIN { $ENV{SPVM_BUILD_DIR} = "$FindBin::Bin/.spvm_build"; }

use SPVM 'TestCase::Errno';

use SPVM 'Errno';

use Errno();

ok(SPVM::TestCase::Errno->test);

{
  my $errno_value = Errno->E2BIG;
}
{
  is(SPVM::Errno->EACCES, Errno::EACCES);
}
{
  is(SPVM::Errno->EADDRINUSE, Errno::EADDRINUSE);
}
{
  is(SPVM::Errno->EADDRNOTAVAIL, Errno::EADDRNOTAVAIL);
}
{
  is(SPVM::Errno->EAFNOSUPPORT, Errno::EAFNOSUPPORT);
}
{
  is(SPVM::Errno->EAGAIN, Errno::EAGAIN);
}
{
  is(SPVM::Errno->EALREADY, Errno::EALREADY);
}
{
  is(SPVM::Errno->EBADE, Errno::EBADE);
}
{
  is(SPVM::Errno->EBADF, Errno::EBADF);
}
{
  is(SPVM::Errno->EBADFD, Errno::EBADFD);
}
{
  is(SPVM::Errno->EBADMSG, Errno::EBADMSG);
}
{
  is(SPVM::Errno->EBADR, Errno::EBADR);
}
{
  is(SPVM::Errno->EBADRQC, Errno::EBADRQC);
}
{
  is(SPVM::Errno->EBADSLT, Errno::EBADSLT);
}
{
  is(SPVM::Errno->EBUSY, Errno::EBUSY);
}
{
  is(SPVM::Errno->ECANCELED, Errno::ECANCELED);
}
{
  is(SPVM::Errno->ECHILD, Errno::ECHILD);
}
{
  is(SPVM::Errno->ECHRNG, Errno::ECHRNG);
}
{
  is(SPVM::Errno->ECOMM, Errno::ECOMM);
}
{
  is(SPVM::Errno->ECONNABORTED, Errno::ECONNABORTED);
}
{
  is(SPVM::Errno->ECONNREFUSED, Errno::ECONNREFUSED);
}
{
  is(SPVM::Errno->ECONNRESET, Errno::ECONNRESET);
}
{
  is(SPVM::Errno->EDEADLK, Errno::EDEADLK);
}
{
  is(SPVM::Errno->EDEADLOCK, Errno::EDEADLOCK);
}
{
  is(SPVM::Errno->EDESTADDRREQ, Errno::EDESTADDRREQ);
}
{
  is(SPVM::Errno->EDOM, Errno::EDOM);
}
{
  is(SPVM::Errno->EDQUOT, Errno::EDQUOT);
}
{
  is(SPVM::Errno->EEXIST, Errno::EEXIST);
}
{
  is(SPVM::Errno->EFAULT, Errno::EFAULT);
}
{
  is(SPVM::Errno->EFBIG, Errno::EFBIG);
}
{
  is(SPVM::Errno->EHOSTDOWN, Errno::EHOSTDOWN);
}
{
  is(SPVM::Errno->EHOSTUNREACH, Errno::EHOSTUNREACH);
}
{
  is(SPVM::Errno->EIDRM, Errno::EIDRM);
}
{
  is(SPVM::Errno->EILSEQ, Errno::EILSEQ);
}
{
  is(SPVM::Errno->EINPROGRESS, Errno::EINPROGRESS);
}
{
  is(SPVM::Errno->EINTR, Errno::EINTR);
}
{
  is(SPVM::Errno->EINVAL, Errno::EINVAL);
}
{
  is(SPVM::Errno->EIO, Errno::EIO);
}
{
  is(SPVM::Errno->EISCONN, Errno::EISCONN);
}
{
  is(SPVM::Errno->EISDIR, Errno::EISDIR);
}
{
  is(SPVM::Errno->EISNAM, Errno::EISNAM);
}
{
  is(SPVM::Errno->EKEYEXPIRED, Errno::EKEYEXPIRED);
}
{
  is(SPVM::Errno->EKEYREJECTED, Errno::EKEYREJECTED);
}
{
  is(SPVM::Errno->EKEYREVOKED, Errno::EKEYREVOKED);
}
{
  my $errno_value = Errno->EL2HLT;
}
{
  my $errno_value = Errno->EL2NSYNC;
}
{
  my $errno_value = Errno->EL3HLT;
}
{
  my $errno_value = Errno->EL3RST;
}
{
  is(SPVM::Errno->ELIBACC, Errno::ELIBACC);
}
{
  is(SPVM::Errno->ELIBBAD, Errno::ELIBBAD);
}
{
  is(SPVM::Errno->ELIBMAX, Errno::ELIBMAX);
}
{
  is(SPVM::Errno->ELIBSCN, Errno::ELIBSCN);
}
{
  is(SPVM::Errno->ELIBEXEC, Errno::ELIBEXEC);
}
{
  is(SPVM::Errno->ELOOP, Errno::ELOOP);
}
{
  is(SPVM::Errno->EMEDIUMTYPE, Errno::EMEDIUMTYPE);
}
{
  is(SPVM::Errno->EMFILE, Errno::EMFILE);
}
{
  is(SPVM::Errno->EMLINK, Errno::EMLINK);
}
{
  is(SPVM::Errno->EMSGSIZE, Errno::EMSGSIZE);
}
{
  is(SPVM::Errno->EMULTIHOP, Errno::EMULTIHOP);
}
{
  is(SPVM::Errno->ENAMETOOLONG, Errno::ENAMETOOLONG);
}
{
  is(SPVM::Errno->ENETDOWN, Errno::ENETDOWN);
}
{
  is(SPVM::Errno->ENETRESET, Errno::ENETRESET);
}
{
  is(SPVM::Errno->ENETUNREACH, Errno::ENETUNREACH);
}
{
  is(SPVM::Errno->ENFILE, Errno::ENFILE);
}
{
  is(SPVM::Errno->ENOBUFS, Errno::ENOBUFS);
}
{
  is(SPVM::Errno->ENODATA, Errno::ENODATA);
}
{
  is(SPVM::Errno->ENODEV, Errno::ENODEV);
}
{
  is(SPVM::Errno->ENOENT, Errno::ENOENT);
}
{
  is(SPVM::Errno->ENOEXEC, Errno::ENOEXEC);
}
{
  is(SPVM::Errno->ENOKEY, Errno::ENOKEY);
}
{
  is(SPVM::Errno->ENOLCK, Errno::ENOLCK);
}
{
  is(SPVM::Errno->ENOLINK, Errno::ENOLINK);
}
{
  is(SPVM::Errno->ENOMEDIUM, Errno::ENOMEDIUM);
}
{
  is(SPVM::Errno->ENOMEM, Errno::ENOMEM);
}
{
  is(SPVM::Errno->ENOMSG, Errno::ENOMSG);
}
{
  is(SPVM::Errno->ENONET, Errno::ENONET);
}
{
  is(SPVM::Errno->ENOPKG, Errno::ENOPKG);
}
{
  is(SPVM::Errno->ENOPROTOOPT, Errno::ENOPROTOOPT);
}
{
  is(SPVM::Errno->ENOSPC, Errno::ENOSPC);
}
{
  is(SPVM::Errno->ENOSR, Errno::ENOSR);
}
{
  is(SPVM::Errno->ENOSTR, Errno::ENOSTR);
}
{
  is(SPVM::Errno->ENOSYS, Errno::ENOSYS);
}
{
  is(SPVM::Errno->ENOTBLK, Errno::ENOTBLK);
}
{
  is(SPVM::Errno->ENOTCONN, Errno::ENOTCONN);
}
{
  is(SPVM::Errno->ENOTDIR, Errno::ENOTDIR);
}
{
  is(SPVM::Errno->ENOTEMPTY, Errno::ENOTEMPTY);
}
{
  is(SPVM::Errno->ENOTSOCK, Errno::ENOTSOCK);
}
{
  is(SPVM::Errno->ENOTSUP, Errno::ENOTSUP);
}
{
  is(SPVM::Errno->ENOTTY, Errno::ENOTTY);
}
{
  is(SPVM::Errno->ENOTUNIQ, Errno::ENOTUNIQ);
}
{
  is(SPVM::Errno->ENXIO, Errno::ENXIO);
}
{
  is(SPVM::Errno->EOPNOTSUPP, Errno::EOPNOTSUPP);
}
{
  is(SPVM::Errno->EOVERFLOW, Errno::EOVERFLOW);
}
{
  is(SPVM::Errno->EPERM, Errno::EPERM);
}
{
  is(SPVM::Errno->EPFNOSUPPORT, Errno::EPFNOSUPPORT);
}
{
  is(SPVM::Errno->EPIPE, Errno::EPIPE);
}
{
  is(SPVM::Errno->EPROTO, Errno::EPROTO);
}
{
  is(SPVM::Errno->EPROTONOSUPPORT, Errno::EPROTONOSUPPORT);
}
{
  is(SPVM::Errno->EPROTOTYPE, Errno::EPROTOTYPE);
}
{
  is(SPVM::Errno->ERANGE, Errno::ERANGE);
}
{
  is(SPVM::Errno->EREMCHG, Errno::EREMCHG);
}
{
  is(SPVM::Errno->EREMOTE, Errno::EREMOTE);
}
{
  is(SPVM::Errno->EREMOTEIO, Errno::EREMOTEIO);
}
{
  is(SPVM::Errno->ERESTART, Errno::ERESTART);
}
{
  is(SPVM::Errno->EROFS, Errno::EROFS);
}
{
  is(SPVM::Errno->ESHUTDOWN, Errno::ESHUTDOWN);
}
{
  is(SPVM::Errno->ESPIPE, Errno::ESPIPE);
}
{
  is(SPVM::Errno->ESOCKTNOSUPPORT, Errno::ESOCKTNOSUPPORT);
}
{
  is(SPVM::Errno->ESRCH, Errno::ESRCH);
}
{
  is(SPVM::Errno->ESTALE, Errno::ESTALE);
}
{
  is(SPVM::Errno->ESTRPIPE, Errno::ESTRPIPE);
}
{
  is(SPVM::Errno->ETIME, Errno::ETIME);
}
{
  is(SPVM::Errno->ETIMEDOUT, Errno::ETIMEDOUT);
}
{
  is(SPVM::Errno->ETXTBSY, Errno::ETXTBSY);
}
{
  is(SPVM::Errno->EUCLEAN, Errno::EUCLEAN);
}
{
  is(SPVM::Errno->EUNATCH, Errno::EUNATCH);
}
{
  is(SPVM::Errno->EUSERS, Errno::EUSERS);
}
{
  is(SPVM::Errno->EWOULDBLOCK, Errno::EWOULDBLOCK);
}
{
  is(SPVM::Errno->EXDEV, Errno::EXDEV);
}
{
  is(SPVM::Errno->EXFULL, Errno::EXFULL);
}

done_testing;
