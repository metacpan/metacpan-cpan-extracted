#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>

MODULE = Mknod		PACKAGE = Mknod		

int
mknod3(const char *pathname, mode_t mode, dev_t dev);
    CODE:
        int ret = mknod(pathname, mode, dev);
        if (ret==0)
            RETVAL = 1;
        else
            RETVAL = 0;
    OUTPUT:
        RETVAL

int
mknod2(const char *pathname, mode_t mode);
    CODE:
        int ret = mknod(pathname, mode, 0);
        if (ret==0)
            RETVAL = 1;
        else
            RETVAL = 0;
    OUTPUT:
        RETVAL

int
S_IFREG()
    CODE:
        RETVAL = S_IFREG;
    OUTPUT:
        RETVAL

int
S_IFCHR()
    CODE:
        RETVAL = S_IFCHR;
    OUTPUT:
        RETVAL

int
S_IFBLK()
    CODE:
        RETVAL = S_IFBLK;
    OUTPUT:
        RETVAL

int
S_IFIFO()
    CODE:
        RETVAL = S_IFIFO;
    OUTPUT:
        RETVAL

