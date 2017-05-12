/*
 * $Id: checksum.h,v 1.1 2005/07/20 13:44:13 mchapman Exp $
 */

#ifndef _CDP_CHECKSUM_H
#define _CDP_CHECKSUM_H

#include <system.h>

/*
 * Calculate checksum for buffer.
 */
uint16_t cdp_checksum(const void *, size_t);

#endif /* _CDP_CHECKSUM_H */
