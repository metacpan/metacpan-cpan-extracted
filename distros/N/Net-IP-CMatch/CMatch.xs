#define PERL_NO_GET_CONTEXT     /* we want efficiency */
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#ifdef __cplusplus
extern "C" {
#endif

static unsigned long parse_ip_and_mask (char *cip, unsigned long *ipm)
{
	int i1, i2, i3, i4, m;
	unsigned long iip, mask;
	char *c;

	i1 = i2 = i3 = i4 = m = 0;
	c = cip;

	// skip leading non-numerics
	for ( ; *c && (*c < '0' || *c > '9'); c++)
		;
	// load first node
	for ( ; *c >= '0' && *c <= '9'; c++)
		i1 = i1 * 10 + (*c - '0');
	// skip non-numerics
	for ( ; *c && (*c < '0' || *c > '9'); c++)
		;
	// load second node
	for ( ; *c >= '0' && *c <= '9'; c++)
		i2 = i2 * 10 + (*c - '0');
	// skip non-numerics
	for ( ; *c && (*c < '0' || *c > '9'); c++)
		;
	// load third node
	for ( ; *c >= '0' && *c <= '9'; c++)
		i3 = i3 * 10 + (*c - '0');
	// skip non-numerics
	for ( ; *c && (*c < '0' || *c > '9'); c++)
		;
	// load forth node
	for ( ; *c >= '0' && *c <= '9'; c++)
		i4 = i4 * 10 + (*c - '0');
	// skip non-numerics
	for ( ; *c && (*c < '0' || *c > '9'); c++)
		;
	// load mask
	for ( ; *c >= '0' && *c <= '9'; c++)
		m = m * 10 + (*c - '0');

	// build numeric ip address
	iip = 
		(i1 << 24) |
		((i2 & 0xff) << 16) |
		((i3 & 0xff) << 8) |
		(i4 & 0xff);

	// mask it
	mask = (m) ?  0xffffffff << ((32 - m) & 31) : 0xffffffff;
	iip &= mask;
	if (ipm)
		*ipm = mask;

	return iip;
}

#ifdef __cplusplus
}
#endif

MODULE = Net::IP::CMatch		PACKAGE = Net::IP::CMatch		

int
match_ip (ip, ...)
	char *ip

	PREINIT:
		int i;
		unsigned long iip, mip, mask;
		STRLEN n_a;

	CODE:
		RETVAL = 0;
		iip = parse_ip_and_mask (ip, &mask);
		for (i = 1; i < items; i++) {
			mip = parse_ip_and_mask ((char *) SvPV (ST (i), n_a), &mask);
			if ((iip & mask) == mip) {
				RETVAL = 1;
				break;
				}
			}

	OUTPUT:
		RETVAL
		


