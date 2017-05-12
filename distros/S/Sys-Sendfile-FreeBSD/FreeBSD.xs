
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <sys/socket.h>
#include <sys/types.h>

MODULE = Sys::Sendfile::FreeBSD   PACKAGE = Sys::Sendfile::FreeBSD

int
sendfile(fd, s, offset, size, sbytes)
     int fd
     int s
     off_t offset
     size_t size
     off_t &sbytes;
   PROTOTYPE: $$$$$
   CODE:
     RETVAL = sendfile(fd, s, offset, size, NULL, &sbytes, 0);
   OUTPUT:
     sbytes
     RETVAL
