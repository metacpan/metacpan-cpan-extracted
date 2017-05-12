/*
 * $Id: checksum.c,v 1.1 2005/07/20 13:44:13 mchapman Exp $
 */

#include <system.h>

/*
 * Actually, this is the standard IP checksum algorithm.
 */
uint16_t
cdp_checksum(const unsigned short *data, size_t length) {
	register long sum = 0;
	register const uint16_t *d = (const uint16_t *)data;

	assert(data);

	while (length > 1) {
		sum += *d++;
		length -= 2;
	}
	if (length)
		sum += htons(*(const uint8_t *)d);
	
	sum = (sum >> 16) + (sum & 0xffff);
	sum += (sum >> 16);
	return (uint16_t)~sum;
}
