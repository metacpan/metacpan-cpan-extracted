/* ====================================================================
 * The Apache Software License, Version 1.1
 *
 * Copyright (c) 2000-2002 The Apache Software Foundation.  All rights
 * reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in
 *    the documentation and/or other materials provided with the
 *    distribution.
 *
 * 3. The end-user documentation included with the redistribution,
 *    if any, must include the following acknowledgment:
 *       "This product includes software developed by the
 *        Apache Software Foundation (http://www.apache.org/)."
 *    Alternately, this acknowledgment may appear in the software itself,
 *    if and wherever such third-party acknowledgments normally appear.
 *
 * 4. The names "Apache" and "Apache Software Foundation" must
 *    not be used to endorse or promote products derived from this
 *    software without prior written permission. For written
 *    permission, please contact apache@apache.org.
 *
 * 5. Products derived from this software may not be called "Apache",
 *    nor may "Apache" appear in their name, without prior written
 *    permission of the Apache Software Foundation.
 *
 * THIS SOFTWARE IS PROVIDED ``AS IS'' AND ANY EXPRESSED OR IMPLIED
 * WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 * OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED.  IN NO EVENT SHALL THE APACHE SOFTWARE FOUNDATION OR
 * ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF
 * USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT
 * OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 * ====================================================================
 *
 * This software consists of voluntary contributions made by many
 * individuals on behalf of the Apache Software Foundation.  For more
 * information on the Apache Software Foundation, please see
 * <http://www.apache.org/>.
 *
 * Portions of this software are based upon public domain software
 * originally written at the National Center for Supercomputing Applications,
 * University of Illinois, Urbana-Champaign.
 * 
 * $Id: rdfstore_ap_sha1.h,v 1.1 2003/05/05 17:57:43 areggiori Exp $
 */

/*
 * NIST Secure Hash Algorithm
 * 	heavily modified by Uwe Hollerbach uh@alumni.caltech edu
 * 	from Peter C. Gutmann's implementation as found in
 * 	Applied Cryptography by Bruce Schneier
 * 	This code is hereby placed in the public domain
 */

#ifndef RDFSTORE_APACHE_SHA1_H
#define RDFSTORE_APACHE_SHA1_H

#ifdef __cplusplus
extern "C" {
#endif

#define RDFSTORE_SHA_DIGESTSIZE 20

/*
 * Define the Magic String prefix that identifies a password as being
 * hashed using our algorithm.
 */
#define RDFSTORE_AP_SHA1PW_ID "{SHA}"
#define RDFSTORE_AP_SHA1PW_IDLEN 5

typedef unsigned long RDFSTORE_AP_LONG;     /* a 32-bit quantity */

typedef struct {
    RDFSTORE_AP_LONG digest[5];             /* message digest */
    RDFSTORE_AP_LONG count_lo, count_hi;    /* 64-bit bit count */
    RDFSTORE_AP_LONG data[16];              /* SHA data buffer */
    int local;                     /* unprocessed amount in data */
} RDFSTORE_AP_SHA1_CTX;

void rdfstore_ap_SHA1Init(RDFSTORE_AP_SHA1_CTX *context);
void rdfstore_ap_SHA1Update(RDFSTORE_AP_SHA1_CTX *context, const char *input,
			       unsigned int inputLen);
void rdfstore_ap_SHA1Update_binary(RDFSTORE_AP_SHA1_CTX *context,
				      const unsigned char *input,
				      unsigned int inputLen);
void rdfstore_ap_SHA1Final(unsigned char digest[RDFSTORE_SHA_DIGESTSIZE],
                              RDFSTORE_AP_SHA1_CTX *context);

#ifdef __cplusplus
}
#endif

#endif	/* !RDFSTORE_APACHE_SHA1_H */
