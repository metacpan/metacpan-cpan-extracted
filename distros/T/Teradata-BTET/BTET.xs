#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "tdbtet.h"

 /* Global variables shared by subroutines */
int g_msglevel;
int g_activcount;
int g_errorcode;
char g_errormsg[260];
 /* SQLDA's for Host Variables (input to Teradata) */
struct sqlda sqldahv[3];
 /* SQLDA's for Results */
struct sqlda sqldares[3];

 /* Common variables within this file only */
static SV * c_msgl_sv;
static SV * c_actv_sv;
static SV * c_errc_sv;
static SV * c_emsg_sv;
 /* Data descriptors for Results */
struct datadescr ddesc[3];
 /* Data area for Host Variables */
uchar hv_data[3][MAX_RDA_LEN];
 /* Indicator area for Host Variables */
short hv_ind[3][MAX_FIELDS];

static int
not_here(char *s)
{
    croak("%s not implemented on this architecture", s);
    return -1;
}


MODULE = Teradata::BTET		PACKAGE = Teradata::BTET


 # CONNECT to Teradata
int
Xconnect(sv)
    PROTOTYPE:$
    INPUT:
	SV *		sv
    PREINIT:
	STRLEN		len;
	char *		logonstring = SvPV(sv, len);
    CODE:
	c_msgl_sv = get_sv("Teradata::BTET::msglevel", FALSE);
	c_actv_sv = get_sv("Teradata::BTET::activcount", FALSE);
	c_errc_sv = get_sv("Teradata::BTET::errorcode", FALSE);
	c_emsg_sv = get_sv("Teradata::BTET::errormsg", FALSE);
	g_msglevel = SvIV(c_msgl_sv);

	RETVAL = Zconnect(logonstring);

	sv_setiv(c_actv_sv, g_activcount);
	sv_setiv(c_errc_sv, g_errorcode);
	sv_setpv(c_emsg_sv, g_errormsg);
    OUTPUT:
	RETVAL

 # DISCONNECT
int
Xdisconnect()
    PROTOTYPE:
    CODE:
	g_msglevel = SvIV(c_msgl_sv);
	RETVAL = Zdisconnect();

	sv_setiv(c_actv_sv, g_activcount);
	sv_setiv(c_errc_sv, g_errorcode);
	sv_setpv(c_emsg_sv, g_errormsg);
    OUTPUT:
	RETVAL

 # PREPARE
int
Xprepare(sv,da)
    PROTOTYPE:$$
    INPUT:
	SV *		sv
	int		da
    PREINIT:
	STRLEN          len;
	char *		sql_stmt = SvPV(sv, len);
    CODE:
	g_msglevel = SvIV(c_msgl_sv);
	RETVAL = Zprepare(sql_stmt, da);
	 /* Simplify the data types. */
	simplify_sqlda(&(ddesc[da]), &(sqldares[da]));

	sv_setiv(c_actv_sv, g_activcount);
	sv_setiv(c_errc_sv, g_errorcode);
	sv_setpv(c_emsg_sv, g_errormsg);
    OUTPUT:
	RETVAL

 # EXECUTE with or without arguments
int
Xexecute(da, ...)
    PROTOTYPE:$
    INPUT:
	int		da
    PREINIT:
	int             i, wint;
	char *		sptr;
	STRLEN		slen;
	double		wdouble;
	uchar *         hvdata_ptr;
    CODE:
	g_msglevel = SvIV(c_msgl_sv);
	if (items == 1) {
	   RETVAL = Zexecute(da);
	} else {
           hvdata_ptr = hv_data[da];

	   for (i = 1; i < items; i++) {
	      if ( SvIOK(ST(i)) ) {
                 wint = SvIV(ST(i));
                 memcpy(hvdata_ptr, &wint, 4);
	         Zbind_int(da, i-1, hvdata_ptr );
	         hvdata_ptr += 4;
	      } else if ( SvNOK(ST(i)) ) {
	         wdouble = SvNV(ST(i));
                 memcpy(hvdata_ptr, &wdouble, 8);
	         Zbind_double(da, i-1, hvdata_ptr );
	         hvdata_ptr += 8;
	      } else if ( SvPOK(ST(i)) ) {
	         sptr = SvPV(ST(i), slen);
	         Zbind_string(da, i-1, sptr, slen );
	      } else {
                 wint = 0;
                 memcpy(hvdata_ptr, &wint, 4);
	         Zbind_null(da, i-1, hvdata_ptr );
	         hvdata_ptr += 4;
	      }
	   }
           RETVAL = Zexecute_args(da);
        }
	sv_setiv(c_actv_sv, g_activcount);
	sv_setiv(c_errc_sv, g_errorcode);
	sv_setpv(c_emsg_sv, g_errormsg);
    OUTPUT:
	RETVAL

# OPEN with or without arguments
int
Xopen(da, ...)
    PROTOTYPE:$
    INPUT:
	int		da
    PREINIT:
	int             i, wint;
	char *		sptr;
	STRLEN		slen;
	double		wdouble;
	uchar *         hvdata_ptr;
    CODE:
	g_msglevel = SvIV(c_msgl_sv);
	if (items == 1) {
	   RETVAL = Zopen(da);
	} else {
           hvdata_ptr = hv_data[da];

	   for (i = 1; i < items; i++) {
	      if ( SvIOK(ST(i)) ) {
                 wint = SvIV(ST(i));
                 memcpy(hvdata_ptr, &wint, 4);
	         Zbind_int(da, i-1, hvdata_ptr );
	         hvdata_ptr += 4;
	      } else if ( SvNOK(ST(i)) ) {
	         wdouble = SvNV(ST(i));
                 memcpy(hvdata_ptr, &wdouble, 8);
	         Zbind_double(da, i-1, hvdata_ptr );
	         hvdata_ptr += 8;
	      } else if ( SvPOK(ST(i)) ) {
	         sptr = SvPV(ST(i), slen);
	         Zbind_string(da, i-1, sptr, slen );
	      } else {
                 wint = 0;
                 memcpy(hvdata_ptr, &wint, 4);
	         Zbind_null(da, i-1, hvdata_ptr );
	         hvdata_ptr += 4;
	      }
	   }
           RETVAL = Zopen_args(da);
        }
	sv_setiv(c_actv_sv, g_activcount);
	sv_setiv(c_errc_sv, g_errorcode);
	sv_setpv(c_emsg_sv, g_errormsg);
    OUTPUT:
	RETVAL

 # FETCH. Second argument says whether this is fetching into a
 # hash or not.
int
Xfetch(da, hash)
    PROTOTYPE:$$
    INPUT:
	int		da
	int		hash
    PREINIT:
	int		i, fetrc, decp, decs;
	STRLEN		slen;
	char *		sptr;
	struct sqlda *	res_ptr;
	int		wint;
	double		wdouble;
	char		wstring[24];
    PPCODE:
	g_msglevel = SvIV(c_msgl_sv);
	fetrc = Zfetch(da);
	res_ptr = &(sqldares[da]);
	if (fetrc == 1) {
	   for (i = 0; i < res_ptr->sqld; i++) {
	       /* If this is a hash request, push the name first. */
	      if (hash) {
	         slen = res_ptr->sqlvar[i].sqlname.length;
	         sptr = (char *)res_ptr->sqlvar[i].sqlname.data;
	         XPUSHs(sv_2mortal(newSVpv(sptr, slen)));
	      }

	       /* Now push the value. */
	      if (*(res_ptr->sqlvar[i].sqlind) < 0) {
	         XPUSHs(&PL_sv_undef);
	         continue;
	      }

	      switch (ddesc[da].sqlvar[i].sqltype) {
	       case INTEGER_N:
	          wint = *((int *)res_ptr->sqlvar[i].sqldata) + 0;
	          XPUSHs(sv_2mortal(newSViv(wint)));
	          break;
	       case SMALLINT_N:
	          wint = *((short *)res_ptr->sqlvar[i].sqldata) + 0;
	          XPUSHs(sv_2mortal(newSViv(wint)));
	          break;
	       case BYTEINT_N:
	          wint = *((char *)res_ptr->sqlvar[i].sqldata) + 0;
	          XPUSHs(sv_2mortal(newSViv(wint)));
	          break;
	       case CHAR_N:
	          slen = res_ptr->sqlvar[i].sqllen;
	          sptr = (char *) res_ptr->sqlvar[i].sqldata;
	          XPUSHs(sv_2mortal(newSVpv(sptr, slen)));
	          break;
	       case VARCHAR_N:
	          slen = *((unsigned short *) res_ptr->sqlvar[i].sqldata);
	          sptr = (char *) (res_ptr->sqlvar[i].sqldata + 2);
	          XPUSHs(sv_2mortal(newSVpv(sptr, slen)));
	          break;
	       case DECIMAL_N:
	            /* Decimal precision and scale */
	          decp = ddesc[da].sqlvar[i].datalen;
	          decs = ddesc[da].sqlvar[i].decscale;
	          if (decp <= 9) {
	             wdouble = _dec_to_double(res_ptr->sqlvar[i].sqldata, decp, decs);
	             XPUSHs(sv_2mortal(newSVnv(wdouble)));
	          } else {
	             _dec_to_string(wstring, res_ptr->sqlvar[i].sqldata, decs);
	             slen = strlen(wstring);
	             XPUSHs(sv_2mortal(newSVpv(wstring, slen)));
	          }
	          break;
	       case FLOAT_N:
	          wdouble = *((double *) res_ptr->sqlvar[i].sqldata);
	          XPUSHs(sv_2mortal(newSVnv(wdouble)));
	          break;
	       default:
	          warn("Data type %d not supported\n",
	           res_ptr->sqlvar[i].sqltype);
	      }
	   }
	}

	sv_setiv(c_actv_sv, g_activcount);
	sv_setiv(c_errc_sv, g_errorcode);
	sv_setpv(c_emsg_sv, g_errormsg);

 # CLOSE
int
Xclose(da)
    PROTOTYPE:$
    INPUT:
	int		da
    CODE:
	g_msglevel = SvIV(c_msgl_sv);
	RETVAL = Zclose(da);

	sv_setiv(c_actv_sv, g_activcount);
	sv_setiv(c_errc_sv, g_errorcode);
	sv_setpv(c_emsg_sv, g_errormsg);
    OUTPUT:
	RETVAL

 # BEGIN TRANSACTION
int
Xbegin_tran()
    PROTOTYPE:
    CODE:
	g_msglevel = SvIV(c_msgl_sv);
	RETVAL = Zbegin_tran();

	sv_setiv(c_actv_sv, g_activcount);
	sv_setiv(c_errc_sv, g_errorcode);
	sv_setpv(c_emsg_sv, g_errormsg);
    OUTPUT:
	RETVAL

 # END TRANSACTION
int
Xend_tran()
    PROTOTYPE:
    CODE:
	g_msglevel = SvIV(c_msgl_sv);
	RETVAL = Zend_tran();

	sv_setiv(c_actv_sv, g_activcount);
	sv_setiv(c_errc_sv, g_errorcode);
	sv_setpv(c_emsg_sv, g_errormsg);

    OUTPUT:
	RETVAL

 # ABORT (ROLLBACK)
int
Xabort()
    PROTOTYPE:
    CODE:
	g_msglevel = SvIV(c_msgl_sv);
	RETVAL = Zabort();

	sv_setiv(c_actv_sv, g_activcount);
	sv_setiv(c_errc_sv, g_errorcode);
	sv_setpv(c_emsg_sv, g_errormsg);
    OUTPUT:
	RETVAL
