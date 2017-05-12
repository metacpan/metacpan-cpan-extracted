#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <sys/ioctl.h>
#include <sys/stat.h>
#if defined(__DARWIN__) || defined(__FreeBSD__) || defined(__OpenBSD__)
#include <sys/ttycom.h>
#endif

#include <fcntl.h>
#include <limits.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>

typedef SV * Term_TtyWrite;

MODULE = Term::TtyWrite		PACKAGE = Term::TtyWrite		

void
DESTROY(obj)
    Term_TtyWrite obj

    CODE:
        SV **svp;
	if ((svp = hv_fetchs((HV*)obj, "fd", FALSE))) {
            if (SvOK(*svp) && SvIOK(*svp))
                close((int) SvIV(*svp));
	}

Term_TtyWrite
new(...)
    INIT:
    	char *classname;
        int fd;

	/* get the class name if called as an object method */
	if ( sv_isobject(ST(0)) ) {
	    classname = HvNAME(SvSTASH(SvRV(ST(0))));
	}
	else {
	    classname = (char *)SvPV_nolen(ST(0));
	}

    CODE:
    	/* This is a standard hash-based object */
    	RETVAL = (Term_TtyWrite)newHV();

	if (items == 2 && SvPOK(ST(1))) {
            if ((fd = open(SvPV_nolen(ST(1)), O_WRONLY)) == -1) {
	        Perl_croak(aTHX_ "could not open '%s': %s", SvPV_nolen(ST(1)), strerror(errno));
            }
	    hv_stores((HV *)RETVAL, "fd", newSViv(fd) );
        } else {
	    Perl_croak(aTHX_ "Usage: Term::TtyWrite->new(\"/dev/sometty\")\n");
	}

    OUTPUT:
    	RETVAL

void
write(obj, ...)
    Term_TtyWrite obj

    INIT:
	if (items != 2 || !SvPOK(ST(1)))
	    Perl_croak(aTHX_ "Usage: $obj->write(\"some data\")");

    CODE:
        char *str;
        int fd;
        STRLEN len;
    	SV **svp;
	if ((svp = hv_fetchs((HV*)obj, "fd", FALSE))) {
            if (SvOK(*svp) && SvIOK(*svp)) {
                fd = (int) SvIV(*svp);
                str = SvPV(ST(1),len);
                while(len-- > 0) {
                    ioctl(fd, TIOCSTI, str++);
                }
            } else {
                Perl_croak(aTHX_ "fd unexpectedly is not set");
            }
	}

void
write_delay(obj, ...)
    Term_TtyWrite obj

    INIT:
	if (items != 3 || !SvPOK(ST(1)) || !SvNIOK(ST(2)))
	    Perl_croak(aTHX_ "Usage: $obj->write_delay(\"some data\", 250)");

    CODE:
        char *str;
        int fd;
        IV delayms;
        STRLEN len;
    	SV **svp;
        useconds_t delay;

	if ((svp = hv_fetchs((HV*)obj, "fd", FALSE))) {
            if (SvOK(*svp) && SvIOK(*svp)) {
                fd = (int) SvIV(*svp);
                str = SvPV(ST(1),len);
                delayms = SvIV(ST(2));
                if (delayms > UINT_MAX / 1000) delayms = UINT_MAX / 1000;
                delay = delayms * 1000;
                while(len-- > 0) {
                    ioctl(fd, TIOCSTI, str++);
                    usleep(delay);
                }
            } else {
                Perl_croak(aTHX_ "fd unexpectedly is not set");
            }
	}
