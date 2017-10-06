/* vim:set tabstop=4 shiftwidth=4 noexpandtab: */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <idn2.h>

MODULE = Net::LibIDN2            PACKAGE = Net::LibIDN2

PROTOTYPES: ENABLE

BOOT:
	HV * stash = gv_stashpv("Net::LibIDN2", TRUE);
	newCONSTSUB(stash, "IDN2_VERSION", newSVpv(IDN2_VERSION, strlen(IDN2_VERSION)));
	newCONSTSUB(stash, "IDN2_VERSION_NUMBER", newSViv(IDN2_VERSION_NUMBER));
	newCONSTSUB(stash, "IDN2_VERSION_MAJOR", newSViv(IDN2_VERSION_MAJOR));
	newCONSTSUB(stash, "IDN2_VERSION_MINOR", newSViv(IDN2_VERSION_MINOR));
	newCONSTSUB(stash, "IDN2_VERSION_PATCH", newSViv(IDN2_VERSION_PATCH));
	newCONSTSUB(stash, "IDN2_LABEL_MAX_LENGTH", newSViv(IDN2_LABEL_MAX_LENGTH));
	newCONSTSUB(stash, "IDN2_DOMAIN_MAX_LENGTH", newSViv(IDN2_DOMAIN_MAX_LENGTH));
	newCONSTSUB(stash, "IDN2_NFC_INPUT", newSViv(IDN2_NFC_INPUT));
	newCONSTSUB(stash, "IDN2_ALABEL_ROUNDTRIP", newSViv(IDN2_ALABEL_ROUNDTRIP));
	newCONSTSUB(stash, "IDN2_TRANSITIONAL", newSViv(IDN2_TRANSITIONAL));
	newCONSTSUB(stash, "IDN2_NONTRANSITIONAL", newSViv(IDN2_NONTRANSITIONAL));
	newCONSTSUB(stash, "IDN2_ALLOW_UNASSIGNED", newSViv(IDN2_ALLOW_UNASSIGNED));
	newCONSTSUB(stash, "IDN2_USE_STD3_ASCII_RULES", newSViv(IDN2_USE_STD3_ASCII_RULES));


const char *
idn2_strerror(rc)
		int rc
	PROTOTYPE: $
	CODE:
		RETVAL = idn2_strerror(rc);
	OUTPUT:
		RETVAL

const char *
idn2_strerror_name(rc)
		int rc
	PROTOTYPE: $
	CODE:
		RETVAL = idn2_strerror_name(rc);
	OUTPUT:
		RETVAL


const char *
idn2_check_version(req_version = NULL)
		const char * req_version
	PROTOTYPE: ;$
	CODE:
		RETVAL = idn2_check_version(req_version);
	OUTPUT:
		RETVAL

SV *
idn2_lookup_u8(src, flags = 0, result = NO_INIT)
		char * src
		int flags
		int result
	ALIAS:
		idn2_to_ascii_8 = 1
	PROTOTYPE: $;$$
	PREINIT:
		uint8_t * lookupname = NULL;
		int res;
		PERL_UNUSED_VAR(ix);
	CODE:
		if (items>1 && ST(1) == &PL_sv_undef)
			flags = 0;

		res = idn2_lookup_u8(
			(const uint8_t *)src,
			(uint8_t **)&lookupname,
			flags);

		if (res == IDN2_OK)
			RETVAL = newSVpv((const char*)lookupname, strlen((const char*)lookupname));
		else
			RETVAL = &PL_sv_undef;

		if (items>2 && ST(2) != &PL_sv_undef)
		{
			sv_setiv(ST(2), (IV)res);
			SvSETMAGIC(ST(2));
		}
	OUTPUT:
		RETVAL
	CLEANUP:
		if (res == IDN2_OK)
			idn2_free(lookupname);

SV *
idn2_lookup_ul(src, flags = 0, result = NO_INIT)
		char * src
		int flags
		int result
	ALIAS:
		idn2_to_ascii_l = 1
	PROTOTYPE: $;$$
	PREINIT:
		char * lookupname = NULL;
		int res;
		PERL_UNUSED_VAR(ix);
	CODE:
		if (items>1 && ST(1) == &PL_sv_undef)
			flags = 0;

		res = idn2_lookup_ul(
			src,
			&lookupname,
			flags);

		if (res == IDN2_OK)
			RETVAL = newSVpv(lookupname, strlen(lookupname));
		else
			RETVAL = &PL_sv_undef;

		if (items>2 && ST(2) != &PL_sv_undef)
		{
			sv_setiv(ST(2), (IV)res);
			SvSETMAGIC(ST(2));
		}
	OUTPUT:
		RETVAL
	CLEANUP:
		if (res == IDN2_OK)
			idn2_free(lookupname);


SV *
idn2_register_u8(ulabel, alabel = NULL, flags = 0, result = NO_INIT)
		char * ulabel
		char * alabel
		int flags
		int result
	PROTOTYPE: $;$$$
	PREINIT:
		uint8_t * insertname = NULL;
		int res;
	CODE:
		if (items>1 && ST(1) == &PL_sv_undef)
			alabel = NULL;

		if (items>2 && ST(2) == &PL_sv_undef)
			flags = 0;

		res = idn2_register_u8(
			(const uint8_t *)ulabel,
			(const uint8_t *)alabel,
			(uint8_t **)&insertname,
			flags);

		if (res == IDN2_OK)
			RETVAL = newSVpv((const char*)insertname, strlen((const char*)insertname));
		else
			RETVAL = &PL_sv_undef;

		if (items>3 && ST(3) != &PL_sv_undef)
		{
			sv_setiv(ST(3), (IV)res);
			SvSETMAGIC(ST(3));
		}
	OUTPUT:
		RETVAL
	CLEANUP:
		if (res == IDN2_OK)
			idn2_free(insertname);

SV *
idn2_register_ul(ulabel, alabel = NULL, flags = 0, result = NO_INIT)
		char * ulabel
		char * alabel
		int flags
		int result
	PROTOTYPE: $;$$$
	PREINIT:
		char * insertname = NULL;
		int res;
	CODE:
		if (items>1 && ST(1) == &PL_sv_undef)
			alabel = NULL;

		if (items>2 && ST(2) == &PL_sv_undef)
			flags = 0;

		res = idn2_register_ul(
			ulabel,
			alabel,
			&insertname,
			flags);

		if (res == IDN2_OK)
			RETVAL = newSVpv(insertname, strlen(insertname));
		else
			RETVAL = &PL_sv_undef;

		if (items>3 && ST(3) != &PL_sv_undef)
		{
			sv_setiv(ST(3), (IV)res);
			SvSETMAGIC(ST(3));
		}
	OUTPUT:
		RETVAL
	CLEANUP:
		if (res == IDN2_OK)
			idn2_free(insertname);


SV *
idn2_to_unicode_88(input, flags = 0, result = NO_INIT)
		char * input
		int flags
		int result
	ALIAS:
		idn2_to_unicode_u8 = 1
	PROTOTYPE: $;$$
	PREINIT:
		char * output = NULL;
		int res;
		PERL_UNUSED_VAR(ix);
	CODE:
		if (items>1 && ST(1) == &PL_sv_undef)
			flags = 0;

		res = idn2_to_unicode_8z8z(
			input,
			&output,
			flags);

		if (res == IDN2_OK)
			RETVAL = newSVpv(output, strlen(output));
		else
			RETVAL = &PL_sv_undef;

		if (items>2 && ST(2) != &PL_sv_undef)
		{
			sv_setiv(ST(2), (IV)res);
			SvSETMAGIC(ST(2));
		}
	OUTPUT:
		RETVAL
	CLEANUP:
		if (res == IDN2_OK)
			idn2_free(output);

SV *
idn2_to_unicode_8l(input, flags = 0, result = NO_INIT)
		char * input
		int flags
		int result
	PROTOTYPE: $;$$
	PREINIT:
		char * output = NULL;
		int res;
	CODE:
		if (items>1 && ST(1) == &PL_sv_undef)
			flags = 0;

		res = idn2_to_unicode_8zlz(
			input,
			&output,
			flags);

		if (res == IDN2_OK)
			RETVAL = newSVpv(output, strlen(output));
		else
			RETVAL = &PL_sv_undef;

		if (items>2 && ST(2) != &PL_sv_undef)
		{
			sv_setiv(ST(2), (IV)res);
			SvSETMAGIC(ST(2));
		}
	OUTPUT:
		RETVAL
	CLEANUP:
		if (res == IDN2_OK)
			idn2_free(output);

SV *
idn2_to_unicode_ll(input, flags = 0, result = NO_INIT)
		char * input
		int flags
		int result
	ALIAS:
		idn2_to_unicode_ul = 1
	PROTOTYPE: $;$$
	PREINIT:
		char * output = NULL;
		int res;
		PERL_UNUSED_VAR(ix);
	CODE:
		if (items>1 && ST(1) == &PL_sv_undef)
			flags = 0;

		res = idn2_to_unicode_lzlz(
			input,
			&output,
			flags);

		if (res == IDN2_OK)
			RETVAL = newSVpv(output, strlen(output));
		else
			RETVAL = &PL_sv_undef;

		if (items>2 && ST(2) != &PL_sv_undef)
		{
			sv_setiv(ST(2), (IV)res);
			SvSETMAGIC(ST(2));
		}
	OUTPUT:
		RETVAL
	CLEANUP:
		if (res == IDN2_OK)
			idn2_free(output);
