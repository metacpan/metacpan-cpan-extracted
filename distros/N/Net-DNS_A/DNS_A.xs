#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <netdb.h>

#include "ppport.h"

static struct gaicb gcb;
static int count = 0;

MODULE = Net::DNS_A		PACKAGE = Net::DNS_A		

void
lookup(host)
    char *host
    INIT:
    int res;
    struct sigevent sev;
    struct gaicb *gptr = &gcb;
    PPCODE:
    if (count) {
        XPUSHs(sv_2mortal(newSViv(0)));
        XPUSHs(sv_2mortal(newSVpv("Please call retrieve()", 0)));
    }
    else {
        gcb.ar_name = host;
        sev.sigev_notify = SIGEV_NONE;

        res = getaddrinfo_a(GAI_NOWAIT, &gptr, 1, &sev);
        if (res) {
            XPUSHs(sv_2mortal(newSViv(0)));
            XPUSHs(sv_2mortal(newSVpv(gai_strerror(res), strlen(gai_strerror(res)))));
        }
        else {
            ++count;
            XPUSHs(sv_2mortal(newSViv(1)));
        }
    }

void
retrieve()
    INIT:
    int res;
    char host[NI_MAXHOST];
    PPCODE:

    if (0 == count) {
        XPUSHs(sv_2mortal(newSViv(0)));
        XPUSHs(sv_2mortal(newSVpv("Please call lookup()", 0)));
    }
    else {
        res = gai_error(&gcb);

        if (EAI_INPROGRESS == res) {
            XPUSHs(sv_2mortal(newSViv(0)));
            XPUSHs(sv_2mortal(newSVpv("EAI_INPROGRESS", 0)));
        }
        else if (0 == res) {
            --count;
            res = getnameinfo(gcb.ar_result->ai_addr, gcb.ar_result->ai_addrlen,
                              host, sizeof(host),
                              NULL, 0, NI_NUMERICHOST);
            if (res) {
                XPUSHs(sv_2mortal(newSViv(0)));
                XPUSHs(sv_2mortal(newSVpv(gai_strerror(res), strlen(gai_strerror(res)))));
            }
            else {
                XPUSHs(sv_2mortal(newSViv(1)));
                XPUSHs(sv_2mortal(newSVpv(gcb.ar_name, strlen(gcb.ar_name))));
                XPUSHs(sv_2mortal(newSVpv(host, strlen(host))));
                freeaddrinfo(gcb.ar_result);
            }
        }
        else if (EAI_INPROGRESS != res) {
            --count;
            XPUSHs(sv_2mortal(newSViv(0)));
            XPUSHs(sv_2mortal(newSVpv(gai_strerror(res), strlen(gai_strerror(res)))));
        }
    }
