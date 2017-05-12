#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <idna.h>
#include <punycode.h>
#include <stringprep.h>
#include <idn-free.h>

#ifdef HAVE_TLD
#include <tld.h>
#endif

#define MAX_DNSLEN 4096

static char * default_charset= "ISO-8859-1";

char *
idn_prep(char * string, char * charset, char * profile)
{
	char * output = NULL;
	char * res_str = NULL;
	char * utf8 = NULL;
	int res;
	
    utf8 = stringprep_convert(string, "UTF-8", charset);
	if (!utf8)
		return NULL;

	res = stringprep_profile(utf8, &output, profile, 0);
	idn_free(utf8);

	if( (res != STRINGPREP_OK) || !output)
		return NULL;

	res_str = stringprep_convert(output, charset, "UTF-8");
	idn_free(output);

	return res_str;
}

static double
constant(char *name, int len, int arg)
{
	errno = 0;
	if (0 + 5 >= len )
	{
		errno = EINVAL;
		return 0;
	}
	switch (name[0 + 5]) 
	{
		case 'A':
		if (strEQ(name + 0, "IDNA_ALLOW_UNASSIGNED"))
		{
			return IDNA_ALLOW_UNASSIGNED;
		}
    case 'U':
		if (strEQ(name + 0, "IDNA_USE_STD3_ASCII_RULES"))
		{
			return IDNA_USE_STD3_ASCII_RULES;
		}
	}
	errno = EINVAL;
	return 0;
}

MODULE = Net::LibIDN		PACKAGE = Net::LibIDN		


double
constant(sv,arg)
    PREINIT:
	STRLEN		len;
    INPUT:
	SV *		sv
	char *		s = SvPV(sv, len);
	int		arg
    CODE:
	RETVAL = constant(s,len,arg);
    OUTPUT:
	RETVAL


char *
idn_to_ascii(string, charset=default_charset, flags=0)
		char *	string
		char *	charset
		int flags
	PROTOTYPE: $;$$
	PREINIT:
		char *	utf8_str = NULL;
		char *	tmp_str = NULL;
		int		res;
	CODE:
		utf8_str = stringprep_convert(string, "UTF-8", charset);
		if (utf8_str)
		{
			res = idna_to_ascii_8z(utf8_str, &tmp_str, flags);
			idn_free(utf8_str);
		}
		else
		{
			XSRETURN_UNDEF;
		}
		if (res!=IDNA_SUCCESS)
		{
			XSRETURN_UNDEF;
		}
		RETVAL = tmp_str;
	OUTPUT:
		RETVAL
	CLEANUP:
		if (tmp_str)
			idn_free(tmp_str);


char *
idn_to_unicode(string, charset=default_charset, flags=0)
		char *	string
		char *	charset
		int flags;
	PROTOTYPE: $;$$
	PREINIT:
		char *	tmp_str = NULL;
		char *	res_str = NULL;
		int		res;
	CODE:
		res = idna_to_unicode_8z8z(string, &tmp_str, flags);
		if(res != IDNA_SUCCESS)
		{
			XSRETURN_UNDEF;
		}
		if (tmp_str)
		{
			res_str = stringprep_convert(tmp_str, charset, "UTF-8");
			idn_free(tmp_str);
		}
		else
		{
			XSRETURN_UNDEF;
		}
		if (!res_str)
		{
			XSRETURN_UNDEF;
		}
		RETVAL = res_str;
	OUTPUT:
		RETVAL
	CLEANUP:
		idn_free(res_str);


char *
idn_punycode_encode(string, charset=default_charset)
		char *	string
		char *	charset
	PROTOTYPE: $;$
	PREINIT:
		char *		utf8_str = NULL;
		uint32_t *	q = NULL;
		size_t		len,len2;
		char *		tmp_str = NULL;
		char *		res_str = NULL;
		int			res;
	CODE:
		utf8_str = stringprep_convert(string, "UTF-8", charset);
		if (utf8_str)
		{
			q = stringprep_utf8_to_ucs4(utf8_str, -1, &len);
			idn_free(utf8_str);
		}
		else
		{
			XSRETURN_UNDEF;
		}
	
		if (!q)
		{
			XSRETURN_UNDEF;
		}

		tmp_str = malloc(MAX_DNSLEN*sizeof(char));
		len2 = MAX_DNSLEN-1;
		res = punycode_encode(len, q, NULL, &len2, tmp_str);
		idn_free(q);

		if (res != PUNYCODE_SUCCESS)
		{
			XSRETURN_UNDEF;
		}

		tmp_str[len2] = '\0';	

		res_str = stringprep_convert(tmp_str, charset, "UTF-8");
		free(tmp_str);
		if (!res_str)
		{
			XSRETURN_UNDEF;
		}
		RETVAL = res_str;
	OUTPUT:
		RETVAL
	CLEANUP:
		idn_free(res_str);


char *
idn_punycode_decode(string, charset=default_charset)
		char *	string
		char *	charset;
	PROTOTYPE: $;$
	PREINIT:
		char *		utf8_str = NULL;
		uint32_t *	q = NULL;
		size_t		len;
		char *		res_str = NULL;
		int			res;
	CODE:
		len = MAX_DNSLEN-1;
		q = (uint32_t *) malloc(MAX_DNSLEN * sizeof(q[0]));
		
		if (q)
		{
			res = punycode_decode(strlen(string), string, &len, q, NULL );
		}
		else
		{
			XSRETURN_UNDEF;
		}
		if (res != PUNYCODE_SUCCESS)
		{
			XSRETURN_UNDEF;
		}
		q[len] = '\0';

		utf8_str = stringprep_ucs4_to_utf8(q, -1, NULL, NULL);
		free(q);

		if (utf8_str)
		{
			res_str = stringprep_convert(utf8_str, charset, "UTF-8");
			idn_free(utf8_str);
		}
		else
		{
			XSRETURN_UNDEF;
		}

		if (!res_str)
		{
			XSRETURN_UNDEF;
		}
		RETVAL = res_str;
	OUTPUT:
		RETVAL
	CLEANUP:
		idn_free(res_str);


char *
idn_prep_name(string, charset=default_charset)
		char *	string
		char *	charset;
	PROTOTYPE: $;$
	PREINIT:
		char *	res_str = NULL;
	CODE:
		res_str = idn_prep(string, charset, "Nameprep");
		if (!res_str)
		{
			XSRETURN_UNDEF;
		}
		RETVAL = res_str;
	OUTPUT:
		RETVAL
	CLEANUP:
		idn_free(res_str);


char *
idn_prep_kerberos5(string, charset=default_charset)
		char *	string
		char *	charset
	PROTOTYPE: $;$
	PREINIT:
		char *	res_str = NULL;
	CODE:
		res_str = idn_prep(string, charset, "KRBprep");
		if (!res_str)
		{
			XSRETURN_UNDEF;
		}
		RETVAL = res_str;
	OUTPUT:
		RETVAL
	CLEANUP:
		idn_free(res_str);

char *
idn_prep_node(string, charset=default_charset)
		char *	string
		char *	charset
	PROTOTYPE: $;$
	PREINIT:
		char *	res_str = NULL;
	CODE:
		res_str = idn_prep(string, charset, "Nodeprep");
		if (!res_str)
		{
			XSRETURN_UNDEF;
		}
		RETVAL = res_str;
	OUTPUT:
		RETVAL
	CLEANUP:
		idn_free(res_str);


char *
idn_prep_resource(string, charset=default_charset)
		char *	string
		char *	charset
	PROTOTYPE: $;$
	PREINIT:
		char *	res_str = NULL;
	CODE:
		res_str = idn_prep(string, charset, "Resourceprep");
		if (!res_str)
		{
			XSRETURN_UNDEF;
		}
		RETVAL = res_str;
	OUTPUT:
		RETVAL
	CLEANUP:
		idn_free(res_str);


char *
idn_prep_plain(string, charset=default_charset)
		char *	string
		char *	charset
	PROTOTYPE: $;$
	PREINIT:
		char *	res_str = NULL;
	CODE:
		res_str = idn_prep(string, charset, "plain");
		if (!res_str)
		{
			XSRETURN_UNDEF;
		}
		RETVAL = res_str;
	OUTPUT:
		RETVAL
	CLEANUP:
		idn_free(res_str);


char *
idn_prep_trace(string, charset=default_charset)
		char *	string
		char *	charset
	PROTOTYPE: $;$
	PREINIT:
		char *	res_str = NULL;
	CODE:
		res_str = idn_prep(string, charset, "trace");
		if (!res_str)
		{
			XSRETURN_UNDEF;
		}
		RETVAL = res_str;
	OUTPUT:
		RETVAL
	CLEANUP:
		idn_free(res_str);


char *
idn_prep_sasl(string, charset=default_charset)
		char *	string
		char *	charset
	PROTOTYPE: $;$
	PREINIT:
		char *	res_str = NULL;
	CODE:
		res_str = idn_prep(string, charset, "SASLprep");
		if (!res_str)
		{
			XSRETURN_UNDEF;
		}
		RETVAL = res_str;
	OUTPUT:
		RETVAL
	CLEANUP:
		idn_free(res_str);


char *
idn_prep_iscsi(string, charset=default_charset)
		char *	string
		char *	charset
	PROTOTYPE: $;$
	PREINIT:
		char *		res_str = NULL;
	CODE:
		res_str = idn_prep(string, charset, "ISCSIprep");
		if (!res_str)
		{
			XSRETURN_UNDEF;
		}
		RETVAL = res_str;
	OUTPUT:
		RETVAL
	CLEANUP:
		idn_free(res_str);


#ifdef HAVE_TLD

int
tld_check(string, errpos,  ...)
		char *string
		size_t errpos
	PROTOTYPE: $$;$$
	PREINIT:
		STRLEN	c_len;
		char * charset = default_charset;
		char * tld = NULL;
		const Tld_table * tld_table = NULL;
		uint32_t *q;
		size_t len;
		char * utf8_str = NULL;
		char * tmp_str = NULL;
		int res;
	CODE:
		if (items>2)
		{
			if (ST(2) != &PL_sv_undef)
				charset = (char*)SvPV(ST(2), c_len);
		}
		if (items>3)
		{
			tld =  (char*)SvPV(ST(3), c_len);
			tld_table = tld_default_table(tld, NULL);
		}
		utf8_str = stringprep_convert(string, "UTF-8", charset);
		if (!utf8_str)
		{
			XSRETURN_UNDEF;
		}
		res = stringprep_profile(utf8_str, &tmp_str, "Nameprep", 0);
		idn_free(utf8_str);
		if (res != STRINGPREP_OK)
		{
			XSRETURN_UNDEF;
		}
		if (tld)
		{
			q = stringprep_utf8_to_ucs4(tmp_str, -1, &len);
			idn_free(tmp_str);
			if (!q)
			{
				XSRETURN_UNDEF;
			}
			res = tld_check_4t(q, len, &errpos, tld_table);
			idn_free(q);
		}
		else
		{
			res = tld_check_8z(tmp_str, &errpos, NULL);
			idn_free(tmp_str);
		}
		if (res == TLD_SUCCESS)
		{
			RETVAL = 1;
		}
		else if (res == TLD_INVALID)
		{
			RETVAL = 0;
		}
		else
		{
			XSRETURN_UNDEF;
		}
	OUTPUT:
		RETVAL
		errpos

char *
tld_get(string)
		char *string
	PROTOTYPE: $
	PREINIT:
		char *res_str = NULL;
		int res;
	CODE:
		res = tld_get_z(string, &res_str);
		if (res == TLD_SUCCESS)
		{
			RETVAL = res_str;
		}
		else
		{
			XSRETURN_UNDEF;
		}
	OUTPUT:
		RETVAL
	CLEANUP:
		idn_free(res_str);


SV *
tld_get_table(tld)
		char * tld
	PROTOTYPE: $
	PREINIT:
		const Tld_table * tld_table = NULL;
		HV * rh, * reh;
		AV * ra;
		const Tld_table_element *e;
		size_t pos;
	CODE:
		tld_table = tld_default_table(tld, NULL);
		if (tld_table)
		{
			rh = (HV *)sv_2mortal((SV *)newHV());
			hv_store(rh, "name", 4, newSVpv(tld_table->name, 0), 0);
			hv_store(rh, "version", 7, newSVpv(tld_table->version, 0), 0);
			hv_store(rh, "nvalid", 6, newSVuv(tld_table->nvalid), 0);
			ra = (AV *)sv_2mortal((SV *)newAV());
			for (pos=0, e = tld_table->valid; pos<tld_table->nvalid; pos++,e++)
			{
				reh = (HV *)sv_2mortal((SV *)newHV());
				hv_store(reh, "start", 5, newSVuv(e->start), 0);
				hv_store(reh, "end", 3, newSVuv(e->end), 0);
				av_push(ra, newRV((SV *)reh));
			}
			hv_store(rh, "valid", 5, newRV((SV*)ra), 0);
			RETVAL = newRV((SV*)rh);
		}
		else
		{
			XSRETURN_UNDEF;
		}
	OUTPUT:
		RETVAL

#endif /* #ifdef HAVE_TLD */
