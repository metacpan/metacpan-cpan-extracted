/*	rblf_name.h	*/

#ifndef RBLF_NAME_H
# define RBLF_NAME_H 1

/*
 * rblf_unpack(msg, eom, src, dst, dstlim)
 *	Unpack a domain name from a message, source may be compressed.
 * return:
 *	-1 on failure, length of unpacked string on success
 *	Advance *ptrptr to skip over the compressed name it points at
 */

int rblf_unpack(unsigned char *msg, unsigned char *eom, unsigned char **ptrptr, unsigned char *dst, unsigned char *dstlim);

/*
 * rblf_skip(ptrptr, eom)
 *	Advance *ptrptr to skip over the compressed name it points at.
 * return:
 *	0 on success, -1 (with errno set) on failure.
 */

int rblf_skip(const unsigned char **ptrptr, const unsigned char *eom);

#endif
