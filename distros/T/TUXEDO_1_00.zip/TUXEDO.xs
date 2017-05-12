#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <atmi.h>
#include <fml32.h>
#include <fml.h>

static int
not_here(char *s)
{
    croak("%s not implemented on this architecture", s);
    return -1;
}

static double
constant(char *name, int arg)
{
    errno = 0;
    switch (*name) {
    case 'A':
	if (strEQ(name, "ATMI_H"))
#ifdef ATMI_H
	    return ATMI_H;
#else
	    goto not_there;
#endif
	break;
    case 'B':
	if (strEQ(name, "BADFLDID"))
#ifdef BADFLDID
	    return BADFLDID;
#else
	    goto not_there;
#endif
	break;
    case 'C':
	break;
    case 'D':
	break;
    case 'E':
	break;
    case 'F':
	if (strEQ(name, "FADD"))
#ifdef FADD
	    return FADD;
#else
	    goto not_there;
#endif
	if (strEQ(name, "FALIGNERR"))
#ifdef FALIGNERR
	    return FALIGNERR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "FBADACM"))
#ifdef FBADACM
	    return FBADACM;
#else
	    goto not_there;
#endif
	if (strEQ(name, "FBADFLD"))
#ifdef FBADFLD
	    return FBADFLD;
#else
	    goto not_there;
#endif
	if (strEQ(name, "FBADNAME"))
#ifdef FBADNAME
	    return FBADNAME;
#else
	    goto not_there;
#endif
	if (strEQ(name, "FBADTBL"))
#ifdef FBADTBL
	    return FBADTBL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "FBADVIEW"))
#ifdef FBADVIEW
	    return FBADVIEW;
#else
	    goto not_there;
#endif
	if (strEQ(name, "FCONCAT"))
#ifdef FCONCAT
	    return FCONCAT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "FDEL"))
#ifdef FDEL
	    return FDEL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "FEINVAL"))
#ifdef FEINVAL
	    return FEINVAL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "FEUNIX"))
#ifdef FEUNIX
	    return FEUNIX;
#else
	    goto not_there;
#endif
	if (strEQ(name, "FFTOPEN"))
#ifdef FFTOPEN
	    return FFTOPEN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "FFTSYNTAX"))
#ifdef FFTSYNTAX
	    return FFTSYNTAX;
#else
	    goto not_there;
#endif
	if (strEQ(name, "FIRSTFLDID"))
#ifdef FIRSTFLDID
	    return FIRSTFLDID;
#else
	    goto not_there;
#endif
	if (strEQ(name, "FJOIN"))
#ifdef FJOIN
	    return FJOIN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "FLD_CARRAY"))
#ifdef FLD_CARRAY
	    return FLD_CARRAY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "FLD_CHAR"))
#ifdef FLD_CHAR
	    return FLD_CHAR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "FLD_DOUBLE"))
#ifdef FLD_DOUBLE
	    return FLD_DOUBLE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "FLD_FLOAT"))
#ifdef FLD_FLOAT
	    return FLD_FLOAT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "FLD_LONG"))
#ifdef FLD_LONG
	    return FLD_LONG;
#else
	    goto not_there;
#endif
	if (strEQ(name, "FLD_SHORT"))
#ifdef FLD_SHORT
	    return FLD_SHORT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "FLD_STRING"))
#ifdef FLD_STRING
	    return FLD_STRING;
#else
	    goto not_there;
#endif
	if (strEQ(name, "FLD_FML32"))
#ifdef FLD_FML32
	    return FLD_FML32;
#else
	    goto not_there;
#endif
	if (strEQ(name, "FLD_PTR"))
#ifdef FLD_PTR
	    return FLD_PTR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "FLD_VIEW32"))
#ifdef FLD_VIEW32
	    return FLD_VIEW32;
#else
	    goto not_there;
#endif
	if (strEQ(name, "FMALLOC"))
#ifdef FMALLOC
	    return FMALLOC;
#else
	    goto not_there;
#endif
	if (strEQ(name, "FMAXNULLSIZE"))
#ifdef FMAXNULLSIZE
	    return FMAXNULLSIZE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "FMAXVAL"))
#ifdef FMAXVAL
	    return FMAXVAL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "FMINVAL"))
#ifdef FMINVAL
	    return FMINVAL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "FML32_H"))
#ifdef FML32_H
	    return FML32_H;
#else
	    goto not_there;
#endif
	if (strEQ(name, "FMLMOD"))
#ifdef FMLMOD
	    return FMLMOD;
#else
	    goto not_there;
#endif
	if (strEQ(name, "FNOCNAME"))
#ifdef FNOCNAME
	    return FNOCNAME;
#else
	    goto not_there;
#endif
	if (strEQ(name, "FNOSPACE"))
#ifdef FNOSPACE
	    return FNOSPACE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "FNOTFLD"))
#ifdef FNOTFLD
	    return FNOTFLD;
#else
	    goto not_there;
#endif
	if (strEQ(name, "FNOTPRES"))
#ifdef FNOTPRES
	    return FNOTPRES;
#else
	    goto not_there;
#endif
	if (strEQ(name, "FOJOIN"))
#ifdef FOJOIN
	    return FOJOIN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "FSTDXINT"))
#ifdef FSTDXINT
	    return FSTDXINT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "FSYNTAX"))
#ifdef FSYNTAX
	    return FSYNTAX;
#else
	    goto not_there;
#endif
	if (strEQ(name, "FTYPERR"))
#ifdef FTYPERR
	    return FTYPERR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "FUPDATE"))
#ifdef FUPDATE
	    return FUPDATE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "FVFOPEN"))
#ifdef FVFOPEN
	    return FVFOPEN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "FVFSYNTAX"))
#ifdef FVFSYNTAX
	    return FVFSYNTAX;
#else
	    goto not_there;
#endif
	if (strEQ(name, "FVIEWCACHESIZE"))
#ifdef FVIEWCACHESIZE
	    return FVIEWCACHESIZE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "FVIEWNAMESIZE"))
#ifdef FVIEWNAMESIZE
	    return FVIEWNAMESIZE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "F_BOTH"))
#ifdef F_BOTH
	    return F_BOTH;
#else
	    goto not_there;
#endif
	if (strEQ(name, "F_COUNT"))
#ifdef F_COUNT
	    return F_COUNT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "F_FTOS"))
#ifdef F_FTOS
	    return F_FTOS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "F_LENGTH"))
#ifdef F_LENGTH
	    return F_LENGTH;
#else
	    goto not_there;
#endif
	if (strEQ(name, "F_NONE"))
#ifdef F_NONE
	    return F_NONE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "F_OFF"))
#ifdef F_OFF
	    return F_OFF;
#else
	    goto not_there;
#endif
	if (strEQ(name, "F_OFFSET"))
#ifdef F_OFFSET
	    return F_OFFSET;
#else
	    goto not_there;
#endif
	if (strEQ(name, "F_PROP"))
#ifdef F_PROP
	    return F_PROP;
#else
	    goto not_there;
#endif
	if (strEQ(name, "F_SIZE"))
#ifdef F_SIZE
	    return F_SIZE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "F_STOF"))
#ifdef F_STOF
	    return F_STOF;
#else
	    goto not_there;
#endif
	if (strEQ(name, "Ferror32"))
#ifdef Ferror32
	    return Ferror32;
#else
	    goto not_there;
#endif
	break;
    case 'G':
	break;
    case 'H':
	break;
    case 'I':
	break;
    case 'J':
	break;
    case 'K':
	break;
    case 'L':
	break;
    case 'M':
	if (strEQ(name, "MAXFBLEN32"))
#ifdef MAXFBLEN32
	    return MAXFBLEN32;
#else
	    goto not_there;
#endif
	if (strEQ(name, "MAXTIDENT"))
#ifdef MAXTIDENT
	    return MAXTIDENT;
#else
	    goto not_there;
#endif
	break;
    case 'N':
	break;
    case 'O':
	break;
    case 'P':
	break;
    case 'Q':
	if (strEQ(name, "QMEABORTED"))
#ifdef QMEABORTED
	    return QMEABORTED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "QMEBADMSGID"))
#ifdef QMEBADMSGID
	    return QMEBADMSGID;
#else
	    goto not_there;
#endif
	if (strEQ(name, "QMEBADQUEUE"))
#ifdef QMEBADQUEUE
	    return QMEBADQUEUE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "QMEBADRMID"))
#ifdef QMEBADRMID
	    return QMEBADRMID;
#else
	    goto not_there;
#endif
	if (strEQ(name, "QMEINUSE"))
#ifdef QMEINUSE
	    return QMEINUSE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "QMEINVAL"))
#ifdef QMEINVAL
	    return QMEINVAL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "QMENOMSG"))
#ifdef QMENOMSG
	    return QMENOMSG;
#else
	    goto not_there;
#endif
	if (strEQ(name, "QMENOSPACE"))
#ifdef QMENOSPACE
	    return QMENOSPACE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "QMENOTA"))
#ifdef QMENOTA
	    return QMENOTA;
#else
	    goto not_there;
#endif
	if (strEQ(name, "QMENOTOPEN"))
#ifdef QMENOTOPEN
	    return QMENOTOPEN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "QMEOS"))
#ifdef QMEOS
	    return QMEOS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "QMEPROTO"))
#ifdef QMEPROTO
	    return QMEPROTO;
#else
	    goto not_there;
#endif
	if (strEQ(name, "QMESYSTEM"))
#ifdef QMESYSTEM
	    return QMESYSTEM;
#else
	    goto not_there;
#endif
	if (strEQ(name, "QMETRAN"))
#ifdef QMETRAN
	    return QMETRAN;
#else
	    goto not_there;
#endif
	break;
    case 'R':
	if (strEQ(name, "RESERVED_BIT1"))
#ifdef RESERVED_BIT1
	    return RESERVED_BIT1;
#else
	    goto not_there;
#endif
	break;
    case 'S':
	break;
    case 'T':
	if (strEQ(name, "TMCORRIDLEN"))
#ifdef TMCORRIDLEN
	    return TMCORRIDLEN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TMMSGIDLEN"))
#ifdef TMMSGIDLEN
	    return TMMSGIDLEN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TMQNAMELEN"))
#ifdef TMQNAMELEN
	    return TMQNAMELEN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TMSRVRFLAG_COBOL"))
#ifdef TMSRVRFLAG_COBOL
	    return TMSRVRFLAG_COBOL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TPABSOLUTE"))
#ifdef TPABSOLUTE
	    return TPABSOLUTE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TPACK"))
#ifdef TPACK
	    return TPACK;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TPAPPAUTH"))
#ifdef TPAPPAUTH
	    return TPAPPAUTH;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TPCONV"))
#ifdef TPCONV
	    return TPCONV;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TPCONVCLTID"))
#ifdef TPCONVCLTID
	    return TPCONVCLTID;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TPCONVMAXSTR"))
#ifdef TPCONVMAXSTR
	    return TPCONVMAXSTR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TPCONVTRANID"))
#ifdef TPCONVTRANID
	    return TPCONVTRANID;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TPCONVXID"))
#ifdef TPCONVXID
	    return TPCONVXID;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TPEABORT"))
#ifdef TPEABORT
	    return TPEABORT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TPEBADDESC"))
#ifdef TPEBADDESC
	    return TPEBADDESC;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TPEBLOCK"))
#ifdef TPEBLOCK
	    return TPEBLOCK;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TPEDIAGNOSTIC"))
#ifdef TPEDIAGNOSTIC
	    return TPEDIAGNOSTIC;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TPED_MAXVAL"))
#ifdef TPED_MAXVAL
	    return TPED_MAXVAL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TPED_MINVAL"))
#ifdef TPED_MINVAL
	    return TPED_MINVAL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TPED_SVCTIMEOUT"))
#ifdef TPED_SVCTIMEOUT
	    return TPED_SVCTIMEOUT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TPED_TERM"))
#ifdef TPED_TERM
	    return TPED_TERM;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TPEEVENT"))
#ifdef TPEEVENT
	    return TPEEVENT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TPEHAZARD"))
#ifdef TPEHAZARD
	    return TPEHAZARD;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TPEHEURISTIC"))
#ifdef TPEHEURISTIC
	    return TPEHEURISTIC;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TPEINVAL"))
#ifdef TPEINVAL
	    return TPEINVAL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TPEITYPE"))
#ifdef TPEITYPE
	    return TPEITYPE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TPELIMIT"))
#ifdef TPELIMIT
	    return TPELIMIT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TPEMATCH"))
#ifdef TPEMATCH
	    return TPEMATCH;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TPEMIB"))
#ifdef TPEMIB
	    return TPEMIB;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TPENOENT"))
#ifdef TPENOENT
	    return TPENOENT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TPEOS"))
#ifdef TPEOS
	    return TPEOS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TPEOTYPE"))
#ifdef TPEOTYPE
	    return TPEOTYPE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TPEPERM"))
#ifdef TPEPERM
	    return TPEPERM;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TPEPROTO"))
#ifdef TPEPROTO
	    return TPEPROTO;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TPERELEASE"))
#ifdef TPERELEASE
	    return TPERELEASE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TPERMERR"))
#ifdef TPERMERR
	    return TPERMERR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TPESVCERR"))
#ifdef TPESVCERR
	    return TPESVCERR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TPESVCFAIL"))
#ifdef TPESVCFAIL
	    return TPESVCFAIL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TPESYSTEM"))
#ifdef TPESYSTEM
	    return TPESYSTEM;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TPETIME"))
#ifdef TPETIME
	    return TPETIME;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TPETRAN"))
#ifdef TPETRAN
	    return TPETRAN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TPEVPERSIST"))
#ifdef TPEVPERSIST
	    return TPEVPERSIST;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TPEVQUEUE"))
#ifdef TPEVQUEUE
	    return TPEVQUEUE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TPEVSERVICE"))
#ifdef TPEVSERVICE
	    return TPEVSERVICE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TPEVTRAN"))
#ifdef TPEVTRAN
	    return TPEVTRAN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TPEV_DISCONIMM"))
#ifdef TPEV_DISCONIMM
	    return TPEV_DISCONIMM;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TPEV_SENDONLY"))
#ifdef TPEV_SENDONLY
	    return TPEV_SENDONLY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TPEV_SVCERR"))
#ifdef TPEV_SVCERR
	    return TPEV_SVCERR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TPEV_SVCFAIL"))
#ifdef TPEV_SVCFAIL
	    return TPEV_SVCFAIL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TPEV_SVCSUCC"))
#ifdef TPEV_SVCSUCC
	    return TPEV_SVCSUCC;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TPEXIT"))
#ifdef TPEXIT
	    return TPEXIT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TPFAIL"))
#ifdef TPFAIL
	    return TPFAIL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TPGETANY"))
#ifdef TPGETANY
	    return TPGETANY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TPGOTSIG"))
#ifdef TPGOTSIG
	    return TPGOTSIG;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TPMAXVAL"))
#ifdef TPMAXVAL
	    return TPMAXVAL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TPMINVAL"))
#ifdef TPMINVAL
	    return TPMINVAL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TPMULTICONTEXTS"))
#ifdef TPMULTICONTEXTS
	    return TPMULTICONTEXTS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TPNOAUTH"))
#ifdef TPNOAUTH
	    return TPNOAUTH;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TPNOBLOCK"))
#ifdef TPNOBLOCK
	    return TPNOBLOCK;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TPNOCHANGE"))
#ifdef TPNOCHANGE
	    return TPNOCHANGE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TPNOFLAGS"))
#ifdef TPNOFLAGS
	    return TPNOFLAGS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TPNOREPLY"))
#ifdef TPNOREPLY
	    return TPNOREPLY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TPNOTIME"))
#ifdef TPNOTIME
	    return TPNOTIME;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TPNOTRAN"))
#ifdef TPNOTRAN
	    return TPNOTRAN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TPQBEFOREMSGID"))
#ifdef TPQBEFOREMSGID
	    return TPQBEFOREMSGID;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TPQCORRID"))
#ifdef TPQCORRID
	    return TPQCORRID;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TPQFAILUREQ"))
#ifdef TPQFAILUREQ
	    return TPQFAILUREQ;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TPQGETBYCORRID"))
#ifdef TPQGETBYCORRID
	    return TPQGETBYCORRID;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TPQGETBYMSGID"))
#ifdef TPQGETBYMSGID
	    return TPQGETBYMSGID;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TPQMSGID"))
#ifdef TPQMSGID
	    return TPQMSGID;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TPQPEEK"))
#ifdef TPQPEEK
	    return TPQPEEK;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TPQPRIORITY"))
#ifdef TPQPRIORITY
	    return TPQPRIORITY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TPQREPLYQ"))
#ifdef TPQREPLYQ
	    return TPQREPLYQ;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TPQTIME_ABS"))
#ifdef TPQTIME_ABS
	    return TPQTIME_ABS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TPQTIME_REL"))
#ifdef TPQTIME_REL
	    return TPQTIME_REL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TPQTOP"))
#ifdef TPQTOP
	    return TPQTOP;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TPQWAIT"))
#ifdef TPQWAIT
	    return TPQWAIT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TPRECVONLY"))
#ifdef TPRECVONLY
	    return TPRECVONLY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TPSA_FASTPATH"))
#ifdef TPSA_FASTPATH
	    return TPSA_FASTPATH;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TPSA_PROTECTED"))
#ifdef TPSA_PROTECTED
	    return TPSA_PROTECTED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TPSENDONLY"))
#ifdef TPSENDONLY
	    return TPSENDONLY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TPSIGRSTRT"))
#ifdef TPSIGRSTRT
	    return TPSIGRSTRT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TPSUCCESS"))
#ifdef TPSUCCESS
	    return TPSUCCESS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TPSYSAUTH"))
#ifdef TPSYSAUTH
	    return TPSYSAUTH;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TPTOSTRING"))
#ifdef TPTOSTRING
	    return TPTOSTRING;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TPTRAN"))
#ifdef TPTRAN
	    return TPTRAN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TPU_DIP"))
#ifdef TPU_DIP
	    return TPU_DIP;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TPU_IGN"))
#ifdef TPU_IGN
	    return TPU_IGN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TPU_MASK"))
#ifdef TPU_MASK
	    return TPU_MASK;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TPU_SIG"))
#ifdef TPU_SIG
	    return TPU_SIG;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TP_CMT_COMPLETE"))
#ifdef TP_CMT_COMPLETE
	    return TP_CMT_COMPLETE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "TP_CMT_LOGGED"))
#ifdef TP_CMT_LOGGED
	    return TP_CMT_LOGGED;
#else
	    goto not_there;
#endif
	break;
    case 'U':
	break;
    case 'V':
	break;
    case 'W':
	break;
    case 'X':
	if (strEQ(name, "XATMI_SERVICE_NAME_LENGTH"))
#ifdef XATMI_SERVICE_NAME_LENGTH
	    return XATMI_SERVICE_NAME_LENGTH;
#else
	    goto not_there;
#endif
	break;
    case 'Y':
	break;
    case 'Z':
	break;
    case 'a':
	break;
    case 'b':
	break;
    case 'c':
	break;
    case 'd':
	break;
    case 'e':
	break;
    case 'f':
	break;
    case 'g':
	break;
    case 'h':
	break;
    case 'i':
	break;
    case 'j':
	break;
    case 'k':
	break;
    case 'l':
	break;
    case 'm':
	break;
    case 'n':
	break;
    case 'o':
	break;
    case 'p':
	break;
    case 'q':
	break;
    case 'r':
	break;
    case 's':
	break;
    case 't':
	break;
    case 'u':
	break;
    case 'v':
	break;
    case 'w':
	break;
    case 'x':
	break;
    case 'y':
	break;
    case 'z':
	break;
    case '_':
	if (strEQ(name, "_FLDID32"))
#ifdef _FLDID32
	    return _FLDID32;
#else
	    goto not_there;
#endif
	if (strEQ(name, "_QADDON"))
#ifdef _QADDON
	    return _QADDON;
#else
	    goto not_there;
#endif
	break;
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}


MODULE = TUXEDO		PACKAGE = TUXEDO		

double
constant(name,arg)
	char *		name
	int		arg

SV*
tpalloc(type,subtype,size)
	char *type
	char *subtype
	long size
	PREINIT:
	char *tuxbfr;
	CODE:
	tuxbfr = tpalloc(type,subtype,size);
	ST(0) = sv_newmortal();
	sv_setiv((SV*)ST(0), (IV)tuxbfr);

SV*
tprealloc(ptr,size)
	SV *ptr
	long size
	PREINIT:
	char *tuxbfr = (char *)SvIV(ptr);
	CODE:
	tuxbfr = tprealloc(tuxbfr,size);
	ST(0) = sv_newmortal();
	sv_setiv((SV*)ST(0), (IV)tuxbfr);

void
tpfree(ptr)
	SV *ptr;
	PREINIT:
	char *tuxbfr = (char *)SvIV(ptr);
	CODE:
	tpfree(tuxbfr);

long
tptypes(ptr,type,subtype)
	SV* ptr
	SV* type
	SV* subtype
	PREINIT:
	char _type[8];
	char _subtype[16];
	char *tuxbfr = (char *)SvIV(ptr);
	CODE:
	RETVAL = tptypes(tuxbfr,_type,_subtype);
	sv_setpv(type,_type);
	sv_setpv(subtype,_subtype);
	OUTPUT:
	RETVAL

void
tpreturn(rval,rcode,data,len,flags)
	int rval
	long rcode
	SV* data
	long len
	long flags
	PREINIT:
	char *tuxbfr = (char *)SvIV(data);
	CODE:
	tpreturn( rval, rcode, tuxbfr, len, flags );

int
AddField(fbfr,fname,value,len=0)
	SV* fbfr
	char * fname
	SV* value
	long len
	PREINIT:
	char *val;
	int rval;
	int ftype;
	unsigned long fieldid;
	char *convloc;
	FLDLEN convlen;
	long required_space;
	long new_size;
	long current_size;
	char *newbuf;
	FBFR *tuxbfr = (FBFR *)SvIV(fbfr);
	CODE:
	fieldid = Fldid(fname);
	if ( fieldid )
	{
		val = SvPV(value, PL_na);
		ftype = len ? FLD_CARRAY : FLD_STRING;
		RETVAL = CFadd( tuxbfr, fieldid, val, len, ftype );
		if ( RETVAL == -1 )
		{
			if ( Ferror == FNOSPACE )
			{
				convloc = Ftypcvt( &convlen, Fldtype(fieldid), val, ftype, len );
				required_space = Fneeded( 1, convlen );
				
				current_size = tptypes( (char *)tuxbfr, 0, 0 );
				new_size = current_size + required_space + 512;
				newbuf = tprealloc( (char *)tuxbfr, new_size );
				if ( newbuf )
				{
					tuxbfr = (FBFR *)newbuf;
					sv_setiv(fbfr,(IV)tuxbfr);
					/* try to add the value again */
					RETVAL = CFadd( tuxbfr, fieldid, val, len, ftype );
				}
			} 
		} 
	}
	else
		RETVAL = -1;
	OUTPUT:
	RETVAL


int
SetField(fbfr,fname,occ,value,len=0)
	SV* fbfr
	char * fname
	SV* value
	unsigned long occ
	long len
	PREINIT:
	char *val;
	int rval;
	int ftype;
	unsigned long fieldid;
	char *convloc;
	FLDLEN convlen;
	long required_space;
	long new_size;
	long current_size;
	char *newbuf;
	FBFR *tuxbfr = (FBFR *)SvIV(fbfr);
	CODE:
	fieldid = Fldid(fname);
	if ( fieldid )
	{
		val = SvPV(value, PL_na);
		ftype = len ? FLD_CARRAY : FLD_STRING;
		RETVAL = CFchg( tuxbfr, fieldid, occ, val, len, ftype );
		if ( RETVAL == -1 )
		{
			if ( Ferror == FNOSPACE )
			{
				convloc = Ftypcvt( &convlen, Fldtype(fieldid), val, ftype, len );
				required_space = Fneeded( 1, convlen );
				
				current_size = tptypes( (char *)tuxbfr, 0, 0 );
				new_size = current_size + required_space + 512;
				newbuf = tprealloc( (char *)tuxbfr, new_size );
				if ( newbuf )
				{
					tuxbfr = (FBFR *)newbuf;
					sv_setiv(fbfr,(IV)tuxbfr);
					/* try to add the value again */
					RETVAL = CFchg( tuxbfr, fieldid, occ, val, len, ftype );
				}
			} 
		} 
	}
	else
		RETVAL = -1;
	OUTPUT:
	RETVAL


SV*
GetField(fbfr,field,oc)
	SV* fbfr
	SV* field
	long oc
	PREINIT:
	char *val;
	unsigned long fid;
	FLDLEN flen;
	FBFR *tuxbfr = (FBFR *)SvIV(fbfr);
	CODE:
	if ( SvIOK(field) )
		fid = (unsigned long)SvIV(field);
	else if ( SvNOK(field) )
		fid = (unsigned long)SvNV(field);
	else
		fid = Fldid( SvPV(field,PL_na) );
	
	val = CFfind(tuxbfr, fid, oc, &flen, FLD_STRING);
	if ( !val ) val = "";
	ST(0) = sv_newmortal();
	sv_setpv((SV*)ST(0), val);


int
AddField32(fbfr,fname,value,len=0)
	SV* fbfr
	char * fname
	SV* value
	long len
	PREINIT:
	char *val;
	int rval;
	int ftype;
	FLDID32 fieldid;
	char *convloc;
	FLDLEN32 convlen;
	long required_space;
	long new_size;
	long current_size;
	char *newbuf;
	FBFR32 *tuxbfr = (FBFR32 *)SvIV(fbfr);
	CODE:
	fieldid = Fldid32(fname);
	if ( fieldid )
	{
		val = SvPV(value, PL_na);
		ftype = len ? FLD_CARRAY : FLD_STRING;
		RETVAL = CFadd32( tuxbfr, fieldid, val, len, ftype );
		if ( RETVAL == -1 )
		{
			if ( Ferror32 == FNOSPACE )
			{
				convloc = Ftypcvt32( &convlen, Fldtype32(fieldid), val, ftype, len );
				required_space = Fneeded32( 1, convlen );
				
				current_size = tptypes( (char *)tuxbfr, 0, 0 );
				new_size = current_size + required_space + 512;
				newbuf = tprealloc( (char *)tuxbfr, new_size );
				if ( newbuf )
				{
					tuxbfr = (FBFR32 *)newbuf;
					sv_setiv(fbfr,(IV)tuxbfr);
					/* try to add the value again */
					RETVAL = CFadd32( tuxbfr, fieldid, val, len, ftype );
				}
			} 
		} 
	}
	else
		RETVAL = -1;
	OUTPUT:
	RETVAL


int
SetField32(fbfr,fname,occ,value,len=0)
	SV* fbfr
	char * fname
	SV* value
	unsigned long occ
	long len
	PREINIT:
	char *val;
	int rval;
	int ftype;
	FLDID32 fieldid;
	char *convloc;
	FLDLEN32 convlen;
	long required_space;
	long new_size;
	long current_size;
	char *newbuf;
	FBFR32 *tuxbfr = (FBFR32 *)SvIV(fbfr);
	CODE:
	fieldid = Fldid32(fname);
	if ( fieldid )
	{
		val = SvPV(value, PL_na);
		ftype = len ? FLD_CARRAY : FLD_STRING;
		RETVAL = CFchg32( tuxbfr, fieldid, occ, val, len, ftype );
		if ( RETVAL == -1 )
		{
			if ( Ferror32 == FNOSPACE )
			{
				convloc = Ftypcvt32( &convlen, Fldtype32(fieldid), val, ftype, len );
				required_space = Fneeded32( 1, convlen );
				
				current_size = tptypes( (char *)tuxbfr, 0, 0 );
				new_size = current_size + required_space + 512;
				newbuf = tprealloc( (char *)tuxbfr, new_size );
				if ( newbuf )
				{
					tuxbfr = (FBFR32 *)newbuf;
					sv_setiv(fbfr,(IV)tuxbfr);
					/* try to add the value again */
					RETVAL = CFchg32( tuxbfr, fieldid, occ, val, len, ftype );
				}
			} 
		} 
	}
	else
		RETVAL = -1;
	OUTPUT:
	RETVAL


SV*
GetField32(fbfr,field,oc)
	SV* fbfr
	SV* field
	long oc
	PREINIT:
	char *val;
	FLDID32 fid;
	FLDLEN32 flen;
	FBFR32 *tuxbfr = (FBFR32 *)SvIV(fbfr);
	CODE:
	if ( SvIOK(field) )
		fid = (unsigned long)SvIV(field);
	else if ( SvNOK(field) )
		fid = (unsigned long)SvNV(field);
	else
		fid = Fldid32( SvPV(field,PL_na) );
	
	val = CFfind32(tuxbfr, fid, oc, &flen, FLD_STRING);
	if ( !val ) val = "";
	ST(0) = sv_newmortal();
	sv_setpv((SV*)ST(0), val);

int
tpinit(tpinitbfr)
	SV *tpinitbfr
	PREINIT:
	TPINIT *ibfr = (TPINIT *)SvIV(tpinitbfr);
	CODE:
	RETVAL = tpinit(ibfr);
	OUTPUT:
	RETVAL

void
tpterm()
	CODE:
	tpterm();

int
tpcall(svc,idata,ilen,odata,olen,flags)
	char *svc
	SV* idata
	long ilen
	SV* odata
	long &olen
	long flags
	PREINIT:
	char *ibfr = (char *)SvIV(idata);
	char *obfr = (char *)SvIV(odata);
	CODE:
	RETVAL = tpcall(svc,ibfr,ilen,&obfr,&olen,flags);
	sv_setiv(odata,(IV)obfr);
	OUTPUT:
	RETVAL
	olen

int
Fprint32(fbfr)
	SV*	fbfr
	PREINIT:
	FBFR32 *tuxbfr = (FBFR32 *)SvIV(fbfr);
	CODE:
	RETVAL = Fprint32(tuxbfr);
	OUTPUT:
	RETVAL

unsigned long
Fmkfldid32(fldtype,fldnum)
    int fldtype
    unsigned long fldnum
    CODE:
    RETVAL = Fmkfldid32( fldtype, fldnum );
    OUTPUT:
    RETVAL

int 
SetTpinitField(tpinitbfr,field,value)
	SV*	tpinitbfr
	int	field
	char *value
	PREINIT:
	long datasize;
	long currentsize;
	char *newbuf;
	TPINIT *tuxbfr = (TPINIT *)SvIV(tpinitbfr);
	CODE:
	RETVAL = 1;
	switch ( field )
	{
		case 1: /* usrname */ 
					strncpy( tuxbfr->usrname, value, MAXTIDENT + 2 );
					break;
		case 2: /* clientname */ 
					strncpy( tuxbfr->cltname, value, MAXTIDENT + 2 );
					break;
		case 3: /* password */ 
					strncpy( tuxbfr->passwd, value, MAXTIDENT + 2 );
					break;
		case 4: /* data */ 
					datasize = strlen( value ) + 1;
					currentsize = tptypes( (char *)tuxbfr, 0, 0 );
					if ( currentsize < (long)TPINITNEED(datasize) )
					{
						/* attempt to reallocate the buffer */
						newbuf = tprealloc( (char *)tuxbfr, (long)TPINITNEED(datasize) );
						if ( !newbuf )
						{
							RETVAL = 0;
							break;
						}
						tuxbfr = (TPINIT *)newbuf;
						sv_setiv(tpinitbfr,(IV)tuxbfr);
					}
					memcpy( (char *)&tuxbfr->data, value, datasize );
					break;
		case 5: /* flags */ 
					tuxbfr->flags = atoi(value);
					break;
		default:
					RETVAL = 0;
					break;
	} /* end switch */
	OUTPUT:
	RETVAL

char * 
GetTpinitField(tpinitbfr,field)
	SV*	tpinitbfr
	int	field
	PREINIT:
	TPINIT *tuxbfr = (TPINIT *)SvIV(tpinitbfr);
	CODE:
	RETVAL = "";
	switch ( field )
	{
		case 1: /* usrname */ 
					RETVAL = tuxbfr->usrname;
					break;
		case 2: /* clientname */ 
					RETVAL = tuxbfr->cltname;
					break;
		case 3: /* password */ 
					RETVAL = tuxbfr->passwd;
					break;
		case 4: /* data */ 
					RETVAL = (char *)&tuxbfr->data;
					break;
		case 5: /* flags */ 
                    {
                    char flags_str[16];
                    sprintf( flags_str, "%d", tuxbfr->flags );
					RETVAL = (char *)flags_str;
                    }
					break;
		default:
					break;
	} /* end switch */
	OUTPUT:
	RETVAL

char *
tuxerrormsg()
	CODE:
	RETVAL = tpstrerror(tperrno);
	OUTPUT:
	RETVAL

char *
fml32errormsg()
	CODE:
	RETVAL = Fstrerror32(Ferror32);
	OUTPUT:
	RETVAL

