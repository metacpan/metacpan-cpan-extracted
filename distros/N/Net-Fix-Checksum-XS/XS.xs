#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

/* Limit on the output message size, including the checksum and \0.
   This mean we can receive up to 4090 chars incl. \0. */
#ifndef FIX_MAX_MSG_LENGTH
	#define FIX_MAX_MSG_LENGTH 4096
#endif


MODULE = Net::Fix::Checksum::XS		PACKAGE = Net::Fix::Checksum::XS

static char *
generate_checksum(fixmsg)
		const char * fixmsg
	PROTOTYPE: $
	CODE:
		char *tmpptr;
		unsigned int len;

		char cksum[4]; /* checksum value only */
		unsigned int idx;
		unsigned int cks;

		/* Find and extract the checksum */
		len = strlen(fixmsg);
		/* Check message is properly terminated */
		if (fixmsg[len-1] != '\001') XSRETURN_UNDEF;

		if (tmpptr = strstr(fixmsg, "\00110=")) {
			len = tmpptr - fixmsg + 1;
		}

		for (idx = 0, cks = 0; idx < len; cks += (unsigned int) fixmsg[idx++]);
		snprintf(cksum, 4, "%03d", (cks % 256));

		RETVAL = cksum;
	OUTPUT:
		RETVAL

static char *
replace_checksum(fixmsg)
		const char * fixmsg
	PROTOTYPE: $
	CODE:
		char tmpmsg[FIX_MAX_MSG_LENGTH];
		char *tmpptr;
		unsigned int len;

		unsigned int idx;
		unsigned int cks;

		/* First remove any trailing checksum form the string */
		len = strlen(fixmsg);
		/* Check message is properly terminated */
		if (fixmsg[len-1] != '\001') XSRETURN_UNDEF;

		if (tmpptr = strstr(fixmsg, "\00110=")) {
			if (len > FIX_MAX_MSG_LENGTH - 1) XSRETURN_UNDEF;
			len = tmpptr - fixmsg + 1;
			strncpy(tmpmsg, fixmsg, len);
			/* tmpmsg[len] = '\0'; // Will be null-padded later anyway */
		} else {
			if (len > FIX_MAX_MSG_LENGTH - 8) XSRETURN_UNDEF; /* minus 7 checksum bytes and \0 */
			strncpy(tmpmsg, fixmsg, len + 1);
		}

		for (idx = 0, cks = 0; idx < len; cks += (unsigned int) tmpmsg[idx++]);
		sprintf(tmpmsg + len, "10=%03d\001", (unsigned int) (cks % 256));

		RETVAL = tmpmsg;
	OUTPUT:
		RETVAL

static int
validate_checksum(fixmsg)
		const char * fixmsg
	PROTOTYPE: $
	CODE:
		char *tmpptr;
		int checksum;
		unsigned int len;

		unsigned int idx;
		unsigned int cks;

		/* Find and extract the checksum */
		len = strlen(fixmsg);
		if (tmpptr = strstr(fixmsg, "\00110=")) {
			len = tmpptr - fixmsg + 1;
			/* Check and get checksum */
			if (strspn(tmpptr + 4, "0123456789\001") != 4) XSRETURN_UNDEF;
			checksum = atoi(tmpptr + 4);
			/* checksum must be in range 0-255) */
			if (checksum >= 256) XSRETURN_UNDEF;
		} else {
			XSRETURN_UNDEF;
		}

		for (idx = 0, cks = 0; idx < len; cks += (unsigned int) fixmsg[idx++]);

		RETVAL = ((cks % 256) == checksum);
	OUTPUT:
		RETVAL

