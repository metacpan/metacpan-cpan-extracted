/*
 * 	Copyright (c) 2000-2006 All rights reserved
 * 	Alberto Reggiori <areggiori@webweaving.org>
 *	Dirk-Willem van Gulik <dirkx@webweaving.org>
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
 *       "This product includes software developed by
 *        Alberto Reggiori <areggiori@webweaving.org> and
 *        Dirk-Willem van Gulik <dirkx@webweaving.org>."
 *    Alternately, this acknowledgment may appear in the software itself,
 *    if and wherever such third-party acknowledgments normally appear.
 *
 * 4. All advertising materials mentioning features or use of this software
 *    must display the following acknowledgement:
 *    This product includes software developed by the University of
 *    California, Berkeley and its contributors.
 *
 * 5. Neither the name of the University nor the names of its contributors
 *    may be used to endorse or promote products derived from this software
 *    without specific prior written permission.
 *
 * 6. Products derived from this software may not be called "RDFStore"
 *    nor may "RDFStore" appear in their names without prior written
 *    permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE REGENTS AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESSED OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
 * NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * ====================================================================
 *
 * This software consists of work developed by Alberto Reggiori and
 * Dirk-Willem van Gulik. The RDF specific part is based based on public
 * domain software written at the Stanford University Database Group by
 * Sergey Melnik. For more information on the RDF API Draft work,
 * please see <http://www-db.stanford.edu/~melnik/rdf/api.html>
 * The DBMS TCP/IP server part is based on software originally written
 * by Dirk-Willem van Gulik for Web Weaving Internet Engineering m/v Enschede,
 * The Netherlands.
 *
 * $Id: rdfstore_digest.c,v 1.12 2006/06/19 10:10:21 areggiori Exp $
 *
 */

#include <stdio.h>

#include "rdfstore_digest.h"
#include "rdfstore_log.h"
#include "rdfstore_serializer.h"

/*
#define RDFSTORE_DEBUG_DIGEST
*/

#ifdef RDFSTORE_DEBUG_DIGEST
#define DIGEST_PRINT(dd) {\
		int             i = 0;\
		printf("Statement digest at line %s:%d is '",__FILE__,__LINE__);\
		for (i = 0; i < RDFSTORE_SHA_DIGESTSIZE; i++) {\
			printf("%02X", dd[i]);\
		};\
		printf("'\n");\
	}
#else
#define DIGEST_PRINT(dd) {}
#endif


int
rdfstore_digest_digest(unsigned char *input, int len, unsigned char digest[RDFSTORE_SHA_DIGESTSIZE])
{
	RDFSTORE_AP_SHA1_CTX sha_info;

	rdfstore_ap_SHA1Init(&sha_info);
	rdfstore_ap_SHA1Update(&sha_info, input, len);
	rdfstore_ap_SHA1Final(digest, &sha_info);

	DIGEST_PRINT(digest);
	return 0;
};

const char *
rdfstore_digest_get_digest_algorithm()
{
	return "SHA-1";
};

/* As it stands - this is a 32 bit (partial) hash - we are not using the full
 * 160 bots of a normal SHA1 operation
  */
static rdf_store_digest_t
rdfstore_digest_crc64(unsigned char * dd)
{
	if (dd == NULL)
		return 0;

	return (rdf_store_digest_t) htonl(*(uint32_t *) dd);
}

int 
rdfstore_digest_get_node_digest(RDF_Node * node, unsigned char dd[RDFSTORE_SHA_DIGESTSIZE], int unique)
{
	unsigned char  *input = NULL;
	int             status = 0;
	int             len = 0;

	if (node == NULL)
		return -1;

	if (node->type != 1) {
		if (node->value.resource.identifier == NULL)
			return -1;

#ifdef RDFSTORE_DEBUG_DIGEST
		printf("get_node_digest( RESOURCE '%s')\n", node->value.resource.identifier);
#endif

		len = node->value.resource.identifier_len;

		input = (unsigned char *) RDFSTORE_MALLOC(
			sizeof(unsigned char) * (len + 1)); /* also bNode bit flag below 1/0 */

		if (input == NULL)
			return -1;

		memcpy(input, node->value.resource.identifier,len);

		if( node->type == 2 ) {
			memcpy(input+len, "1", 1); /* is bNode */
		} else {
			memcpy(input+len, "0", 1);
			};
		len++;
	} else if (node->type == 1) {
		int len_lang,len_dt;
		/* literals can be empty i.e. node->value.literal.string can be NULL */

#ifdef RDFSTORE_DEBUG_DIGEST
		printf("get_node_digest( LITERAL '%s')\n", node->value.literal.string);
#endif

		len = (node->value.literal.string != NULL) ?  node->value.literal.string_len : 0;

		len_lang=0;
		len_dt=0;
		if( unique ) {
			if (node->value.literal.lang != NULL)
				len_lang = strlen(node->value.literal.lang);

			if (node->value.literal.parseType == 1)
				len_dt = strlen(RDFSTORE_RDF_PARSETYPE_LITERAL);
			else if (node->value.literal.dataType != NULL)
				len_dt= strlen(node->value.literal.dataType);
			};

		input = (unsigned char *) RDFSTORE_MALLOC(
			sizeof(unsigned char) * (len + len_lang + len_dt + 2)); /* the two double quotes signs to distinguish between resources and literals */

		if (input == NULL)
			return -1;

		/*
		 * the following assures that different digests are generated
		 * for the same string for Literal and URI ref of a Resource
		 * e.g. "http://www.google.com" and <http://www.google.com>
		 * would result in different digests
		 */
		memcpy(input, "\"", 1);
		if (node->value.literal.string != NULL) {
			memcpy(input+1, node->value.literal.string, len);
			};
		memcpy(input+1+len, "\"", 1);

		/* keep the digest unique per xml:lang and rdf:datatype if requested */
		if( unique ) {
			if (node->value.literal.lang != NULL)
				memcpy(input+1+len+1, node->value.literal.lang, len_lang);
                	if (node->value.literal.parseType == 1)
				memcpy(input+1+len+1+len_lang, RDFSTORE_RDF_PARSETYPE_LITERAL, len_dt);
                	else if (node->value.literal.dataType != NULL)
				memcpy(input+1+len+1+len_lang, node->value.literal.dataType, len_dt);
			};
		len += len_lang + len_dt + 2;
	} else {
		return -1;
		};

	status = rdfstore_digest_digest(input, len, dd);

	RDFSTORE_FREE(input);

	return status;
};

/*
 * crc64 of an SHA-1 cryptographic hash - see Stanford API Draft and GUID
 * stuff
 */
rdf_store_digest_t
rdfstore_digest_get_node_hashCode( RDF_Node * node, int unique )
{
	unsigned char   dd[RDFSTORE_SHA_DIGESTSIZE];
	rdf_store_digest_t hc = 0;

	if (node == NULL)
		return 0;

#ifdef RDFSTORE_DEBUG_DIGEST
	if (node->hashcode)
		printf("Node hashcode for '%s' already carried out '%d'\n", (node->type != 1) ? node->value.resource.identifier : node->value.literal.string, node->hashcode);
#endif

	if (node->hashcode)
		return node->hashcode;

	if ((rdfstore_digest_get_node_digest(node, dd, unique)) != 0) {
		hc = 0;
	} else {
		hc = rdfstore_digest_crc64(dd);
	};

	return hc;
};

int 
rdfstore_digest_get_statement_digest(RDF_Statement * statement, RDF_Node * given_context, unsigned char dd[RDFSTORE_SHA_DIGESTSIZE])
{
	unsigned char   dds[RDFSTORE_SHA_DIGESTSIZE];
	unsigned char   ddp[RDFSTORE_SHA_DIGESTSIZE];
	unsigned char   ddo[RDFSTORE_SHA_DIGESTSIZE];
	unsigned char   ddc[RDFSTORE_SHA_DIGESTSIZE];
	/* unsigned char ddn[RDFSTORE_SHA_DIGESTSIZE]; */
	unsigned char  *input = NULL;
	RDF_Node       *context = NULL;
	int             status = 0;

	if (statement == NULL)
		return -1;

	if (given_context == NULL) {
		if (statement->context != NULL)
			context = statement->context;
	} else {
		/* use given context instead */
		context = given_context;
	};

	if ((rdfstore_digest_get_node_digest(statement->subject, dds, 1)) != 0)
		return -1;

	DIGEST_PRINT(dds);

	if ((rdfstore_digest_get_node_digest(statement->predicate, ddp, 1)) != 0)
		return -1;

	DIGEST_PRINT(ddp);

	if ((rdfstore_digest_get_node_digest(statement->object, ddo, 1)) != 0) /* distinguish RDF literal hashcode by xml:lang or rdf:datatype */
		return -1;

	DIGEST_PRINT(ddo);

	if (context != NULL) {
		if ((rdfstore_digest_get_node_digest(context, ddc, 1)) != 0)
			return -1;

		DIGEST_PRINT(ddc);

		input = (unsigned char *) RDFSTORE_MALLOC(
			sizeof(unsigned char) * (RDFSTORE_SHA_DIGESTSIZE * 4));	/* s,p,o,c */
	} else {
		input = (unsigned char *) RDFSTORE_MALLOC(
			sizeof(unsigned char) * (RDFSTORE_SHA_DIGESTSIZE * 3));	/* s,p,o */
	};

	if (input == NULL)
		return -1;

	memcpy(input, dds, RDFSTORE_SHA_DIGESTSIZE);
	memcpy(input + RDFSTORE_SHA_DIGESTSIZE, ddp, RDFSTORE_SHA_DIGESTSIZE);

	if (statement->object->type == 1) {
		register int    i;
		unsigned char   c = ddo[0];
		/*
		 * rotate one byte - see why at
		 * http://www-db.stanford.edu/~melnik/rdf/api.html#digest
		 * even if it says rotate to the left why is the right :)
		 */
		for (i = 0; i < RDFSTORE_SHA_DIGESTSIZE - 1; i++)
			ddo[i] = ddo[i + 1];
		ddo[RDFSTORE_SHA_DIGESTSIZE - 1] = c;
	};
	memcpy(input + (2 * RDFSTORE_SHA_DIGESTSIZE), ddo, RDFSTORE_SHA_DIGESTSIZE);

	if (context != NULL) 
		memcpy(input + (3 * RDFSTORE_SHA_DIGESTSIZE), ddc, RDFSTORE_SHA_DIGESTSIZE);

	status = rdfstore_digest_digest(input, 
		(context != NULL) ? (RDFSTORE_SHA_DIGESTSIZE * 4) : (RDFSTORE_SHA_DIGESTSIZE * 3), 
		dd);

	DIGEST_PRINT(dd);

	RDFSTORE_FREE(input);

	return status;
}

rdf_store_digest_t
rdfstore_digest_get_statement_hashCode(RDF_Statement * statement, RDF_Node * given_context)
{
	unsigned char   dd[RDFSTORE_SHA_DIGESTSIZE];
	rdf_store_digest_t hc = 0;

	if (statement == NULL)
		return 0;

#ifdef RDFSTORE_DEBUG_DIGEST
	if (statement->hashcode) {
		char           *ntriples_rep = rdfstore_ntriples_statement(statement, NULL);
		printf("Statement hashcode for '%s' already carried out '%d'\n", ntriples_rep, statement->hashcode);
		RDFSTORE_FREE(ntriples_rep);
	};
#endif

	if (statement->hashcode)
		return statement->hashcode;

	if ((rdfstore_digest_get_statement_digest(statement, given_context, dd)) != 0) {
		hc = 0;
	} else {
		/*
		 * perhaps it is instead => s.hashCode() * 7) + p.hashCode()) *
		 * 7 + o.hashCode() + c.hashCode()
		 */
		hc = rdfstore_digest_crc64(dd);
	};

#ifdef RDFSTORE_DEBUG_DIGEST
	{
		char           *ntriples_rep = rdfstore_ntriples_statement(statement, NULL);
		printf("Just computed statement hashcode for '%s' to '%d' %s\n", ntriples_rep, hc, (given_context != NULL) ? "(not to be cached)" : "");
		RDFSTORE_FREE(ntriples_rep);
	};
#endif

	return hc;
}
