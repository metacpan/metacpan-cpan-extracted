/*
 * Copyright (c) 2000-2006 All rights reserved,
 *       Alberto Reggiori <areggiori@webweaving.org>,
 *       Dirk-Willem van Gulik <dirkx@webweaving.org>.
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 * 
 * 1. Redistributions of source code must retain the above copyright notice,
 * this list of conditions and the following disclaimer.
 * 
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 * this list of conditions and the following disclaimer in the documentation
 * and/or other materials provided with the distribution.
 * 
 * 3. The end-user documentation included with the redistribution, if any, must
 * include the following acknowledgment: "This product includes software
 * developed by Alberto Reggiori <areggiori@webweaving.org> and Dirk-Willem
 * van Gulik <dirkx@webweaving.org>." Alternately, this acknowledgment may
 * appear in the software itself, if and wherever such third-party
 * acknowledgments normally appear.
 * 
 * 4. All advertising materials mentioning features or use of this software must
 * display the following acknowledgement: This product includes software
 * developed by the University of California, Berkeley and its contributors.
 * 
 * 5. Neither the name of the University nor the names of its contributors may
 * be used to endorse or promote products derived from this software without
 * specific prior written permission.
 * 
 * 6. Products derived from this software may not be called "RDFStore" nor may
 * "RDFStore" appear in their names without prior written permission.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE REGENTS AND CONTRIBUTORS ``AS IS'' AND ANY
 * EXPRESSED OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 * 
 * ====================================================================
 * 
 * This software consists of work developed by Alberto Reggiori and Dirk-Willem
 * van Gulik. The RDF specific part is based based on public domain software
 * written at the Stanford University Database Group by Sergey Melnik. For
 * more information on the RDF API Draft work, please see
 * <http://www-db.stanford.edu/~melnik/rdf/api.html> The DBMS TCP/IP server
 * part is based on software originally written by Dirk-Willem van Gulik for
 * Web Weaving Internet Engineering m/v Enschede, The Netherlands.
 * 
 * $Id: rdfstore_kernel.c,v 1.113 2006/06/19 10:10:21 areggiori Exp $
 * 
 */

#if !defined(WIN32)
#include <sys/param.h>
#endif

#include <sys/types.h>
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <strings.h>
#include <fcntl.h>

#include <netinet/in.h>

#include <time.h>
#include <sys/stat.h>

#include "rdfstore_log.h"
#include "rdfstore_ms.h"
#include "rdfstore.h"
#include "rdfstore_iterator.h"
#include "rdfstore_serializer.h"
#include "rdfstore_digest.h"
#include "rdfstore_bits.h"
#include "rdfstore_utf8.h"
#include "rdfstore_xsd.h"

/*
#define MX	{ printf(" MX %s:%d - %p\n",__FILE__,__LINE__,me->nindex->free); }
*/
#define MX

/*
 * #define RDFSTORE_DEBUG
 */

/*
 * #define RDFSTORE_CONNECTIONS
 */
/*
 * #define RDFSTORE_DEBUG_CONNECTIONS
 */
/*
 * #define RDFSTORE_CONNECTIONS_REINDEXING
 */

char * rdfstore_get_version (
        rdfstore * me
        ) {
        return VERSION;
        };

int
rdfstore_connect(
		 rdfstore * *mme,
		 char *name,
		 int flags,
		 int freetext,
		 int sync,
		 int remote,
		 char *host,
		 int port,
/* Callbacks for memory management and error handling. */
		 void *(*_mmalloc) (size_t s),
		 void (*_mfree) (void *adr),
		 void (*_mcallback) (dbms_cause_t cause, int cnt),
		 void (*_merror) (char *err, int erx)
)
{
	rdfstore       *me = NULL;
	DBT             key, data;
	int             err = 0,comp_alg=RDFSTORE_COMPRESSION_TYPE_DEFAULT;
#ifdef RDFSTORE_CONNECTIONS
	int             comp_alg_connections=RDFSTORE_COMPRESSION_TYPE_BLOCK;/* comparing on some thesaurus like 10k triples this is the best */
#endif

	memset(&key, 0, sizeof(key));
	memset(&data, 0, sizeof(data));

	*mme = NULL;

	me = (rdfstore *) RDFSTORE_MALLOC(sizeof(rdfstore));

	if (me == NULL)
		return -1;

	me->model = NULL;
	me->nodes = NULL;
	me->subjects = NULL;
	me->predicates = NULL;
	me->objects = NULL;
#ifdef RDFSTORE_CONNECTIONS
	me->s_connections = NULL;
	me->p_connections = NULL;
	me->o_connections = NULL;
#endif
	me->languages = NULL;
	me->datatypes = NULL;
	me->xsd_integer = NULL;
	me->xsd_double = NULL;
	me->xsd_date = NULL;
	me->contexts = NULL;
	me->freetext = 0;
	me->statements = NULL;
	me->cursor = NULL;

	/* prefixes mapping stuff */
	me->prefixes = NULL;

	/* set/get options */
	me->flag = flags;
	me->sync = sync;
	me->remote = remote;

	if (me->remote) {
		if ((host != NULL) &&
		    (strlen(host) > 0))
			strcpy(me->host, host);
		me->port = port;
	} else {
		strcpy(me->host, "");
		me->port = 0;
		};
	me->context = NULL;

	/* name can also be file://.... for local or rdfstore://demo.asemantics.com:1234/nb for remote */
	if (!strncmp(name,"file://",(size_t)7)) {
        	fprintf(stderr,"Aborted: RDF/XML or N-Triples file will be supported with in-memory model and C level parsing done.\n");
		goto exitandclean;
	} else if (!strncmp(name,"rdfstore://",(size_t)11)) {
		char url_port[255];
		char * p;
		char * p1;
		name+=11;
		p = strstr(name,":");
		p1 = strstr(name,"/");
		if(p!=NULL) {
			/* get the host out */
			strncpy(me->host,name,p-name);
			me->host[p-name] = '\0';	
			if (strlen(me->host)<=0) {
                                fprintf(stderr,"Aborted: You really want an Internet hostname.\n");
				goto exitandclean;
				};
			host = me->host;
			/* get the port out */
			strncpy(url_port,p+1,p1-(p+1));
			port = atoi(url_port);
			if (port<=1) {
                                fprintf(stderr,"Aborted: You really want a port number >1.\n");
				goto exitandclean;
				};
			name=p1+1;
			me->port = port;

			remote = 1;
			me->remote = 1;
		} else if(p1!=NULL) {
			/* get the host out */
			strncpy(me->host,name,p1-name);
			me->host[p1-name] = '\0';	
			if (strlen(me->host)<=0) {
				remote = 0;
				me->remote = 0;
			} else {
				host = me->host;
				remote = 1;
				me->remote = 1;
				name=p1+1;
				};
			};
	} else if (!strncmp(name,"http://",(size_t)7)) {
        	fprintf(stderr,"Aborted: What are you trying to do? That's DAV like isn't it? ;-)\n");
		goto exitandclean;
		};

	err = rdfstore_flat_store_open(remote,
		      			flags,
				        &me->model,
				        name, (((name == NULL) || (strlen(name) == 0)) ? NULL : "/model"), 
					(unsigned int)(32 * 1024), host, port,
				     	_mmalloc, _mfree, _mcallback, _merror,
					0);
	if (err != 0) 
		goto exitandclean;

	/* check indexing version first or croak */
	key.data = RDFSTORE_INDEXING_VERSION_KEY;
	key.size = sizeof(RDFSTORE_INDEXING_VERSION_KEY);
	if ((rdfstore_flat_store_fetch(me->model, key, &data)) != 0) {
		if (!(me->flag)) {
			data.data = RDFSTORE_INDEXING_VERSION;
			data.size = strlen(RDFSTORE_INDEXING_VERSION) + 1;
			err = rdfstore_flat_store_store(me->model, key, data);
			if ((err != 0) &&
			    (err != FLAT_STORE_E_KEYEXIST)) {
				perror("rdfstore_connect");
				fprintf(stderr,"Could not store '%d' bytes for key '%s' in table model for store '%s': %s\n", (int)data.size, (char *)key.data, (char *)data.data, rdfstore_flat_store_get_error(me->model));

				goto exitandclean;
				};
		} else {
			if(	(name != NULL) &&
				(strlen(name) > 0) ) {
				perror("rdfstore_connect");
				fprintf(stderr,"Incompatible RDF database indexing version. This is version %s. You need to upgrade your database; dump your data, remove old database and re-ingest data.\n", RDFSTORE_INDEXING_VERSION );
				goto exitandclean;
				};
			};
		strcpy(me->version, RDFSTORE_INDEXING_VERSION);
	} else {
		/* just croak if different version for the moment */
		if (strncmp(	RDFSTORE_INDEXING_VERSION,
				data.data, data.size )) {
			perror("rdfstore_connect");
			fprintf(stderr,"Incompatible RDF database indexing version %s. This is version %s. You need to upgrade your database; dump your data, remove old database and re-ingest data.\n", (char *)data.data, RDFSTORE_INDEXING_VERSION );
			goto exitandclean;
			};
		strcpy(me->version, data.data);
		RDFSTORE_FREE(data.data);
		};

	if ((name != NULL) &&
	    (strlen(name) > 0)) {
		key.data = RDFSTORE_NAME_KEY;
                key.size = sizeof(RDFSTORE_NAME_KEY);
		if ((rdfstore_flat_store_fetch(me->model, key, &data)) != 0) {
			if (!(me->flag)) {
				data.data = name;
				data.size = strlen(name) + 1;
				err = rdfstore_flat_store_store(me->model, key, data);
				if ((err != 0) &&
				    (err != FLAT_STORE_E_KEYEXIST)) {
					perror("rdfstore_connect");
					fprintf(stderr,"Could not store '%d' bytes for key '%s' in table model for store '%s': %s\n", (int)data.size, (char *)key.data, (char *)data.data, rdfstore_flat_store_get_error(me->model));

					goto exitandclean;
				};
			} else {
				perror("rdfstore_connect");
				fprintf(stderr,"Store '%s' does not exist or is corrupted\n", name);
				goto exitandclean;
			};
			strcpy(me->name, name);
		} else {
			if (strncmp(name, data.data, strlen(name))) {	/* which is obvioulsy
									 * wrong but we avoid
									 * bother of ending
									 * slashes ;-) */
				RDFSTORE_FREE(data.data);
				perror("rdfstore_connect");
				fprintf(stderr,"It seems you have got the wrong store name '%s' instead of '%s'\n", name, (char *)data.data);
				goto exitandclean;
				};
			strcpy(me->name, data.data);
			RDFSTORE_FREE(data.data);
		};
	};

	key.data = RDFSTORE_FREETEXT_KEY;
        key.size = sizeof(RDFSTORE_FREETEXT_KEY);

	if ((rdfstore_flat_store_fetch(me->model, key, &data)) != 0) {
		if (!(me->flag)) {
			data.data = (freetext) ? "1" : "0";
			data.size = sizeof((freetext) ? "1" : "0") + 1;
			err = rdfstore_flat_store_store(me->model, key, data);
			if ((err != 0) &&
			    (err != FLAT_STORE_E_KEYEXIST)) {
				perror("rdfstore_connect");
				fprintf(stderr,"Could not store '%d' bytes for key '%s' in model for store '%s': %s\n", (int)data.size, (char *)key.data, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->model));
				goto exitandclean;
			};
		} else if ((me->name != NULL) &&
			   (strlen(me->name) > 0)) {
			perror("rdfstore_connect");
			fprintf(stderr,"Store '%s' seems corrupted\n", me->name);
			goto exitandclean;
		};
		me->freetext = (freetext) ? 1 : 0;
	} else {
		me->freetext = (strcmp(data.data, "0")) ? 1 : 0;
		RDFSTORE_FREE(data.data);
	};

	key.data = RDFSTORE_COMPRESSION_KEY;
        key.size = sizeof(RDFSTORE_COMPRESSION_KEY);
	if ((rdfstore_flat_store_fetch(me->model, key, &data)) != 0) {
		if (!(me->flag)) {
			unsigned char   outbuf[256];
                        packInt(comp_alg, outbuf);
                        data.data = outbuf;
                        data.size = sizeof(int);
			err = rdfstore_flat_store_store(me->model, key, data);
			if ((err != 0) &&
			    (err != FLAT_STORE_E_KEYEXIST)) {
				perror("rdfstore_connect");
				fprintf(stderr,"Could not store '%d' bytes for key '%s' in model for store '%s': %s\n", (int)data.size, (char *)key.data, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->model));
				goto exitandclean;
				};
			};
	} else {
		unpackInt(data.data, &comp_alg);
		RDFSTORE_FREE(data.data);
		};

	if (rdfstore_compress_init(comp_alg,&(me->func_decode),&(me->func_encode))) {
#ifdef RDFSTORE_DEBUG
		fprintf(stderr,"Could not init default compression function for algorithm '%d'\n",comp_alg);
#endif
		goto exitandclean;
		};

#ifdef RDFSTORE_CONNECTIONS
	key.data = RDFSTORE_COMPRESSION_CONNECTIONS_KEY;
        key.size = sizeof(RDFSTORE_COMPRESSION_CONNECTIONS_KEY);
	if ((rdfstore_flat_store_fetch(me->model, key, &data)) != 0) {
		if (!(me->flag)) {
			unsigned char   outbuf[256];
                        packInt(comp_alg_connections, outbuf);
                        data.data = outbuf;
                        data.size = sizeof(int);
			err = rdfstore_flat_store_store(me->model, key, data);
			if ((err != 0) &&
			    (err != FLAT_STORE_E_KEYEXIST)) {
				perror("rdfstore_connect");
				fprintf(stderr,"Could not store '%d' bytes for key '%s' in model for store '%s': %s\n", (int)data.size, (char *)key.data, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->model));
				goto exitandclean;
				};
			};
	} else {
		unpackInt(data.data, &comp_alg_connections);
		RDFSTORE_FREE(data.data);
		};

	/* now bear in mind we using this for sake of experiment on connections tables to see if it compresses better.... */
	if (rdfstore_compress_init(comp_alg_connections,&(me->func_decode_connections),&(me->func_encode_connections))) {
#ifdef RDFSTORE_DEBUG
		fprintf(stderr,"Could not init connections compression function for algorithm '%d'\n",comp_alg_connections);
#endif
		goto exitandclean;
		};
#endif

	err = rdfstore_flat_store_open(remote,
				       flags,
				       &me->nodes,
				       name, (((name == NULL) || (strlen(name) == 0)) ? NULL : "/nodes"), (unsigned int)(32 * 1024), host, port,
				     _mmalloc, _mfree, _mcallback, _merror,
					0);
	if (err != 0) {
		 goto exitandclean;
	};
	err = rdfstore_flat_store_open(remote,
				       flags,
				       &me->subjects,
				       name, (((name == NULL) || (strlen(name) == 0)) ? NULL : "/subjects"), (unsigned int)(32 * 1024), host, port,
				     _mmalloc, _mfree, _mcallback, _merror,
					0);
	if (err != 0) {
		 goto exitandclean;
	};
	err = rdfstore_flat_store_open(remote,
				       flags,
				       &me->predicates,
				       name, (((name == NULL) || (strlen(name) == 0)) ? NULL : "/predicates"), (unsigned int)(32 * 1024), host, port,
				     _mmalloc, _mfree, _mcallback, _merror,
					0);
	if (err != 0) {
		 goto exitandclean;
	};
	err = rdfstore_flat_store_open(remote,
				       flags,
				       &me->objects,
				       name, (((name == NULL) || (strlen(name) == 0)) ? NULL : "/objects"), (unsigned int)(32 * 1024), host, port,
				     _mmalloc, _mfree, _mcallback, _merror,
					0);
	if (err != 0) {
		 goto exitandclean;
	};
	err = rdfstore_flat_store_open(remote,
				       flags,
				       &me->contexts,
				       name, (((name == NULL) || (strlen(name) == 0)) ? NULL : "/contexts"), (unsigned int)(32 * 1024), host, port,
				     _mmalloc, _mfree, _mcallback, _merror,
					0);
	if (err != 0) {
		 goto exitandclean;
	};
#ifdef RDFSTORE_CONNECTIONS
	err = rdfstore_flat_store_open(remote,
				       flags,
				       &me->s_connections,
				       name, (((name == NULL) || (strlen(name) == 0)) ? NULL : "/s_connections"), (unsigned int)(32 * 1024), host, port,
				     _mmalloc, _mfree, _mcallback, _merror,
					0 );
	if (err != 0) {
		 goto exitandclean;
	};
	err = rdfstore_flat_store_open(remote,
				       flags,
				       &me->p_connections,
				       name, (((name == NULL) || (strlen(name) == 0)) ? NULL : "/p_connections"), (unsigned int)(32 * 1024), host, port,
				     _mmalloc, _mfree, _mcallback, _merror,
					0 );
	if (err != 0) {
		 goto exitandclean;
	};
	err = rdfstore_flat_store_open(remote,
				       flags,
				       &me->o_connections,
				       name, (((name == NULL) || (strlen(name) == 0)) ? NULL : "/o_connections"), (unsigned int)(32 * 1024), host, port,
				     _mmalloc, _mfree, _mcallback, _merror,
					0 );
	if (err != 0) {
		 goto exitandclean;
	};
#endif

	err = rdfstore_flat_store_open(remote,
				       flags,
				       &me->languages,
				       name, (((name == NULL) || (strlen(name) == 0)) ? NULL : "/languages"), (unsigned int)(32 * 1024), host, port,
				     _mmalloc, _mfree, _mcallback, _merror,
					0 );
	if (err != 0) {
		 goto exitandclean;
	};

	err = rdfstore_flat_store_open(remote,
				       flags,
				       &me->datatypes,
				       name, (((name == NULL) || (strlen(name) == 0)) ? NULL : "/datatypes"), (unsigned int)(32 * 1024), host, port,
				     _mmalloc, _mfree, _mcallback, _merror,
					0 );
	if (err != 0) {
		 goto exitandclean;
	};

	/* special table for integers */
	err = rdfstore_flat_store_open(remote,
				       flags,
				       &me->xsd_integer,
				       name, (((name == NULL) || (strlen(name) == 0)) ? NULL : "/xsd_integer"), (unsigned int)(32 * 1024), host, port,
				     _mmalloc, _mfree, _mcallback, _merror,
					FLAT_STORE_BT_COMP_INT );
	if (err != 0) {
		 goto exitandclean;
	};

	/* special table for doubles */
	err = rdfstore_flat_store_open(remote,
				       flags,
				       &me->xsd_double,
				       name, (((name == NULL) || (strlen(name) == 0)) ? NULL : "/xsd_double"), (unsigned int)(32 * 1024), host, port,
				     _mmalloc, _mfree, _mcallback, _merror,
					FLAT_STORE_BT_COMP_DOUBLE );
	if (err != 0) {
		 goto exitandclean;
	};

	/* special table for dates */
	err = rdfstore_flat_store_open(remote,
				       flags,
				       &me->xsd_date,
				       name, (((name == NULL) || (strlen(name) == 0)) ? NULL : "/xsd_date"), (unsigned int)(32 * 1024), host, port,
				     _mmalloc, _mfree, _mcallback, _merror,
					0); /* I guess lexicographical order for xsd:date and xsd:dateTime should work */
	if (err != 0) {
		 goto exitandclean;
	};

	if (me->freetext) {	/* just if we need free-text indexing */
		err = rdfstore_flat_store_open(remote,
					       flags,
					       &me->windex,
					       name, (((name == NULL) || (strlen(name) == 0)) ? NULL : "/windex"), (unsigned int)(32 * 1024), host, port,
				     _mmalloc, _mfree, _mcallback, _merror,
					0); /* might be default lexicographical order for words is not UTF-8 safe? yeah..... */
		if (err != 0) {
		 	goto exitandclean;
		};
	};

	err = rdfstore_flat_store_open(remote,
				       flags,
				       &me->statements,
				       name, (((name == NULL) || (strlen(name) == 0)) ? NULL : "/statements"), (unsigned int)(32 * 1024), host, port,
				     _mmalloc, _mfree, _mcallback, _merror,
					0);
	if (err != 0) {
		goto exitandclean;
	};

	/* this is just used internally and never gets returned to the user */
	me->cursor = NULL;
	me->cursor = (rdfstore_iterator *) RDFSTORE_MALLOC(sizeof(rdfstore_iterator));
	if (me->cursor == NULL) {
		perror("rdfstore_connect");
		fprintf(stderr,"Cannot create internal results cursor/iterator for store '%s'\n", (name != NULL) ? name : "(in-memory)");
		goto exitandclean;
	};

	/* initialize statements counters if necessary */

	/* keep the number of zapped statements */
	key.data = RDFSTORE_COUNTER_REMOVED_KEY;
        key.size = sizeof(RDFSTORE_COUNTER_REMOVED_KEY);
	if ((rdfstore_flat_store_exists(me->model, key)) != 0) {
		if (!(me->flag)) {
			unsigned char   outbuf[256];
			packInt(0, outbuf);
			data.data = outbuf;
			data.size = sizeof(int);
			err = rdfstore_flat_store_store(me->model, key, data);
			if ((err != 0) &&
			    (err != FLAT_STORE_E_KEYEXIST)) {
				perror("rdfstore_connect");
				fprintf(stderr,"Could not store '%d' bytes for key '%s' in model for store '%s': %s\n", (int)data.size, (char *)key.data, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->model));
				goto exitandclean;
			};
		} else if ((me->name != NULL) &&
			   (strlen(me->name) > 0)) {
			perror("rdfstore_connect");
			fprintf(stderr,"Store '%s' seems corrupted\n", (me->name != NULL) ? me->name : "(in-memory)");
			goto exitandclean;
		};
	};

	/* keep the total number of statements */
	key.data = RDFSTORE_COUNTER_KEY;
        key.size = sizeof(RDFSTORE_COUNTER_KEY);
	if ((rdfstore_flat_store_exists(me->model, key)) != 0) {
		if (!(me->flag)) {
			unsigned char   outbuf[256];
			packInt(0, outbuf);
			data.data = outbuf;
			data.size = sizeof(int);
			err = rdfstore_flat_store_store(me->model, key, data);
			if ((err != 0) &&
			    (err != FLAT_STORE_E_KEYEXIST)) {
				perror("rdfstore_connect");
				fprintf(stderr,"Could not store '%d' bytes for key '%s' in model for store '%s': %s\n", (int)data.size, (char *)key.data, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->model));
				goto exitandclean;
			};
		} else if ((me->name != NULL) &&
			   (strlen(me->name) > 0)) {
			perror("rdfstore_connect");
			fprintf(stderr,"Store '%s' seems corrupted\n", (me->name != NULL) ? me->name : "(in-memory)");
			goto exitandclean;
		};
	};

	me->cursor->store = me;
	/* bzero(me->cursor->ids,sizeof(unsigned char)*(RDFSTORE_MAXRECORDS_BYTES_SIZE)); */
	me->cursor->remove_holes = 0;	/* reset the total of holes */
	me->cursor->st_counter = 0;
	if ((me->name != NULL) &&
	    (strlen(me->name) > 0)) {
		rdfstore_size(me, &me->cursor->size);
	} else {
		me->cursor->size = 0;
	};
	me->cursor->ids_size = (me->cursor->size / 8);
	if (me->cursor->size % 8)
		me->cursor->ids_size++;
	me->cursor->pos = 0;

	me->attached = 0;	/* reset the number of items (cursors)
				 * currenlty attached */
	me->tobeclosed = 0;

	/* it seems BDB 1.8x needs this to start properly */
	if (!(me->flag)) {
		/*
		 * fprintf(stderr,"Initial sync for BDB 1.8x and flag = '%d' (must be
		 * 0)",me->flag);
		 */
		rdfstore_flat_store_sync(me->model);
		rdfstore_flat_store_sync(me->nodes);
		rdfstore_flat_store_sync(me->subjects);
		rdfstore_flat_store_sync(me->predicates);
		rdfstore_flat_store_sync(me->objects);
		if (me->contexts)
			rdfstore_flat_store_sync(me->contexts);
#ifdef RDFSTORE_CONNECTIONS
		if (me->s_connections)
			rdfstore_flat_store_sync(me->s_connections);
		if (me->p_connections)
			rdfstore_flat_store_sync(me->p_connections);
		if (me->o_connections)
			rdfstore_flat_store_sync(me->o_connections);
#endif
		if (me->languages)
			rdfstore_flat_store_sync(me->languages);
		if (me->datatypes)
			rdfstore_flat_store_sync(me->datatypes);
		if (me->xsd_integer)
			rdfstore_flat_store_sync(me->xsd_integer);
		if (me->xsd_double)
			rdfstore_flat_store_sync(me->xsd_double);
		if (me->xsd_date)
			rdfstore_flat_store_sync(me->xsd_date);
		if (me->freetext)
			rdfstore_flat_store_sync(me->windex);
		rdfstore_flat_store_sync(me->statements);
	};

#ifdef RDFSTORE_DEBUG
	{
		unsigned int    size = 0;
		if ((name != NULL) && (strlen(name) > 0)) {
			if (rdfstore_size(me, &size)) {
				perror("rdfstore_is_empty");
				fprintf(stderr,"Could not carry out model size for store '%s'\n", (me->name != NULL) ? me->name : "(in-memory)");
				goto exitandclean;
			};
		};
		fprintf(stderr,"Connected to database \n\tname='%s'\n\tremote='%d'\n\thost='%s'\n\tport='%d'\n\tfreetext='%d'\n\tsync='%d'\n\tsize='%d'", me->name, me->remote, me->host, me->port, me->freetext, me->sync, size);
	};
#endif

	*mme = me;

MX;
	return 0;

exitandclean:
	/* XX should we not also free the me->model, me->nodes and so on ? or at least close them ? */
	if (me->model) {
		if (!(me->flag)) rdfstore_flat_store_sync(me->model);
		rdfstore_flat_store_close(me->model);
		};
	if (me->nodes) {
		if (!(me->flag)) rdfstore_flat_store_sync(me->nodes);
		rdfstore_flat_store_close(me->nodes);
		};
	if (me->subjects) {
		if (!(me->flag)) rdfstore_flat_store_sync(me->subjects);
		rdfstore_flat_store_close(me->subjects);
		};
	if (me->predicates) {
		if (!(me->flag)) rdfstore_flat_store_sync(me->predicates);
		rdfstore_flat_store_close(me->predicates);
		};
	if (me->objects) {
		if (!(me->flag)) rdfstore_flat_store_sync(me->objects);
		rdfstore_flat_store_close(me->objects);
		};
	if (me->contexts) {
		if (!(me->flag)) rdfstore_flat_store_sync(me->contexts);
		rdfstore_flat_store_close(me->contexts);
		};
#ifdef RDFSTORE_CONNECTIONS
	if (me->s_connections) {
		if (!(me->flag)) rdfstore_flat_store_sync(me->s_connections);
		rdfstore_flat_store_close(me->s_connections);
		};
	if (me->p_connections) {
		if (!(me->flag)) rdfstore_flat_store_sync(me->p_connections);
		rdfstore_flat_store_close(me->p_connections);
		};
	if (me->o_connections) {
		if (!(me->flag)) rdfstore_flat_store_sync(me->o_connections);
		rdfstore_flat_store_close(me->o_connections);
		};
#endif
	if (me->languages) {
		if (!(me->flag)) rdfstore_flat_store_sync(me->languages);
		rdfstore_flat_store_close(me->languages);
		};
	if (me->datatypes) {
		if (!(me->flag)) rdfstore_flat_store_sync(me->datatypes);
		rdfstore_flat_store_close(me->datatypes);
		};
	if (me->xsd_integer) {
		if (!(me->flag)) rdfstore_flat_store_sync(me->xsd_integer);
		rdfstore_flat_store_close(me->xsd_integer);
		};
	if (me->xsd_double) {
		if (!(me->flag)) rdfstore_flat_store_sync(me->xsd_double);
		rdfstore_flat_store_close(me->xsd_double);
		};
	if (me->xsd_date) {
		if (!(me->flag)) rdfstore_flat_store_sync(me->xsd_date);
		rdfstore_flat_store_close(me->xsd_date);
		};
	if (me->windex) {
		if (!(me->flag)) rdfstore_flat_store_sync(me->windex);
		rdfstore_flat_store_close(me->windex);
		};
	if (me->statements) {
		if (!(me->flag)) rdfstore_flat_store_sync(me->statements);
		rdfstore_flat_store_close(me->statements);
		};
	if (me->cursor)	RDFSTORE_FREE(me->cursor);
	RDFSTORE_FREE(me);
	return -1;
};

int 
rdfstore_disconnect(rdfstore * me)
{

	if (me == NULL) {
#ifdef RDFSTORE_DEBUG
		printf(">>>>>>>>>>>>>>>>>>>>%p IMPOSSIBLE TO CLOSE\n", me);
#endif
		return -1;
	};

	if (me->attached > 0) {
#ifdef RDFSTORE_DEBUG
		printf(">>>>>>>>>>>>>>>>>>>>%p TO BE CLOSED\n", me);
#endif
		me->tobeclosed = 1;
		return 1;	/* wait the cursors to call me back :-) */
	} else {
#ifdef RDFSTORE_DEBUG
		printf("<<<<<<<<<<<<<<<<<<<<%p CLOSING\n", me);
#endif
		me->tobeclosed = 0;
	};
MX;

	if ((me->sync) &&
	    (!(me->flag))) {
		rdfstore_flat_store_sync(me->model);
		rdfstore_flat_store_sync(me->nodes);
		rdfstore_flat_store_sync(me->subjects);
		rdfstore_flat_store_sync(me->predicates);
		rdfstore_flat_store_sync(me->objects);
#ifdef RDFSTORE_CONNECTIONS
		if (me->s_connections)
			rdfstore_flat_store_sync(me->s_connections);
		if (me->p_connections)
			rdfstore_flat_store_sync(me->p_connections);
		if (me->o_connections)
			rdfstore_flat_store_sync(me->o_connections);
#endif
		if (me->languages)
			rdfstore_flat_store_sync(me->languages);
		if (me->datatypes)
			rdfstore_flat_store_sync(me->datatypes);
		if (me->xsd_integer)
			rdfstore_flat_store_sync(me->xsd_integer);
		if (me->xsd_double)
			rdfstore_flat_store_sync(me->xsd_double);
		if (me->xsd_date)
			rdfstore_flat_store_sync(me->xsd_date);
		if (me->freetext)
			rdfstore_flat_store_sync(me->windex);
		if (me->contexts)
			rdfstore_flat_store_sync(me->contexts);
		rdfstore_flat_store_sync(me->statements);
	};

	if (me->cursor != NULL)
		RDFSTORE_FREE(me->cursor);

	if (me->context != NULL) {
		RDFSTORE_FREE(me->context->value.resource.identifier);
		RDFSTORE_FREE(me->context);
	};

	rdfstore_flat_store_close(me->model);
	rdfstore_flat_store_close(me->nodes);
	rdfstore_flat_store_close(me->subjects);
	rdfstore_flat_store_close(me->predicates);
	rdfstore_flat_store_close(me->objects);
	if (me->contexts)
		rdfstore_flat_store_close(me->contexts);
#ifdef RDFSTORE_CONNECTIONS
	if (me->s_connections)
		rdfstore_flat_store_close(me->s_connections);
	if (me->p_connections)
		rdfstore_flat_store_close(me->p_connections);
	if (me->o_connections)
		rdfstore_flat_store_close(me->o_connections);
#endif
	if (me->languages)
		rdfstore_flat_store_close(me->languages);
	if (me->datatypes)
		rdfstore_flat_store_close(me->datatypes);
	if (me->xsd_integer)
		rdfstore_flat_store_close(me->xsd_integer);
	if (me->xsd_double)
		rdfstore_flat_store_close(me->xsd_double);
	if (me->xsd_date)
		rdfstore_flat_store_close(me->xsd_date);
	if (me->freetext)
		rdfstore_flat_store_close(me->windex);
	rdfstore_flat_store_close(me->statements);

	RDFSTORE_FREE(me);
	me = NULL;

	return 0;
};

int 
rdfstore_isconnected(
		     rdfstore * me
) {
	return (me->model != NULL) ? 0 : 1;
	};

/*
 * perhaps in the future we might have different tables on different servers
 * or some local/in-memory
 */
int 
rdfstore_isremote(
		  rdfstore * me
) {
	return ( (rdfstore_isconnected(me)==0) && ( rdfstore_flat_store_isremote(me->model) == 1 ) ) ? 0 : 1;
};

int 
rdfstore_size(
	      rdfstore * me,
	      unsigned int *size)
{

	DBT             key, data;
	unsigned int    removed = 0;

	memset(&key, 0, sizeof(key));
	memset(&data, 0, sizeof(data));

	key.data = RDFSTORE_COUNTER_REMOVED_KEY;
        key.size = sizeof(RDFSTORE_COUNTER_REMOVED_KEY);
	if ((rdfstore_flat_store_fetch(me->model, key, &data)) != 0) {
		perror("rdfstore_size");
		fprintf(stderr,"Could not find counter_removed_key for store '%s': %s\n", (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->model));
		return -1;
	};

	/* cast values to int */
	unpackInt(data.data, &removed);
	RDFSTORE_FREE(data.data);

	memset(&data, 0, sizeof(data));
	key.data = RDFSTORE_COUNTER_KEY;
        key.size = sizeof(RDFSTORE_COUNTER_KEY);
	if ((rdfstore_flat_store_fetch(me->model, key, &data)) != 0) {
		perror("rdfstore_size");
		fprintf(stderr,"Could not find counter_key for store '%s': %s\n", (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->model));
		return -1;
	};
	unpackInt(data.data, size);
	RDFSTORE_FREE(data.data);

#ifdef RDFSTORE_DEBUG
	fprintf(stderr,"size = %d - %d\n", (*size), removed);
#endif

	/* sum them */
	(*size) -= removed;

	return 0;
};

/* try to be as lightweight as possible here without requiring full-blown rdfstore connections, but just one to model */
int rdfstore_if_modified_since (
        char * name,
        char * since,
	/* Callbacks for memory management and error handling. */
	void *(*_mmalloc) (size_t s),
        void (*_mfree) (void *adr),
        void (*_mcallback) (dbms_cause_t cause, int cnt),
        void (*_merror) (char *err, int erx)
        ) {
	struct tm thedateval_tm;
	char thedateval[RDFSTORE_XSD_DATETIME_FORMAT_SIZE];
	DBT key, data;
	int err=0;
	FLATDB  * model;
	int port=0;
	int remote=0;
	char host[ MAXPATHLEN ];

	strcpy(host, "");

	if( name == NULL ) {
		return 0;
		};

	memset(&key, 0, sizeof(key));
	memset(&data, 0, sizeof(data));

	if( ! rdfstore_xsd_deserialize_dateTime( since, &thedateval_tm ) ) { /* get/normalize passed xsd:dateTime */
		return -1;
		};

	rdfstore_xsd_serialize_dateTime( thedateval_tm, thedateval );

	/* get the DB name */
	if (!strncmp(name,"rdfstore://",(size_t)11)) {
                char url_port[255];
                char * p;
                char * p1;
                name+=11;
                p = strstr(name,":");
                p1 = strstr(name,"/");
                if(p!=NULL) {
                        /* get the host out */
                        strncpy(host,name,p-name);
                        host[p-name] = '\0';        
                        if (strlen(host)<=0) { 
				return -1;
                                };
                        /* get the port out */ 
                        strncpy(url_port,p+1,p1-(p+1));
                        port = atoi(url_port);
                        if (port<=1) {
				return -1;
                                };
                        name=p1+1;
                        remote = 1;
                } else if(p1!=NULL) {
                        /* get the host out */
                        strncpy(host,name,p1-name);
                        host[p1-name] = '\0';
                        if (strlen(host)<=0) {
                                remote = 0;
                        } else {
                                name=p1+1;
                                remote = 1;
                                };
                        };
	} else if (	(!strncmp(name,"file://",(size_t)7)) ||
			(!strncmp(name,"http://",(size_t)7)) ) {
		return -1;
		};

	/* just one quick / simple connection to model */
	err = rdfstore_flat_store_open(remote,
		      			1, /* read only */
				        &model,
				        name, (((name == NULL) || (strlen(name) == 0)) ? NULL : "/model"), 
					(unsigned int)(32 * 1024), host, port,
				     	_mmalloc, _mfree, _mcallback, _merror,
					0);
	if (err != 0) {
		return -1;
		};

	key.data = RDFSTORE_LASTMODIFIED_KEY;
        key.size = sizeof(RDFSTORE_LASTMODIFIED_KEY);

	err = rdfstore_flat_store_fetch(model, key, &data);
	if (err != 0) {
		if (err != FLAT_STORE_E_NOTFOUND) {
			perror("rdfstore_if_modified_since");
			fprintf(stderr,"Could not find %s key for store '%s': %s\n", RDFSTORE_LASTMODIFIED_KEY, (name != NULL) ? name : "(in-memory)", rdfstore_flat_store_get_error(model));
			rdfstore_flat_store_close(model);

			return -1;
		} else {
			rdfstore_flat_store_close(model);

			return 1;
			};
	} else {
		if( strcmp( thedateval, data.data ) < 0 ) {
#ifdef RDFSTORE_DEBUG
			printf(" %s < %s \n", thedateval, (char*)(data.data) );
#endif
			rdfstore_flat_store_close(model);

			return 0;
		} else {
#ifdef RDFSTORE_DEBUG
			printf(" %s >= %s \n", thedateval, (char*)(data.data) );
#endif
			rdfstore_flat_store_close(model);

			return 1;
			};
		};
	};

int 
rdfstore_insert(
		rdfstore * me,
		RDF_Statement * statement,
		RDF_Node * given_context
)
{
	RDF_Node       *context = NULL;
	char           *buff = NULL;
	char           *_buff = NULL;
	unsigned int    outsize = 0;
	unsigned int    st_id = 0;
	DBT             key, data;
	unsigned char   outbuf[256];
	unsigned char   outbuf1[256];
	unsigned char   nodebuf[ 32 * 1024 ];
	unsigned char  *word;
	unsigned char   mask = 0;
	unsigned char  *utf8_casefolded_buff;
	unsigned int    utf8_size = 0;
	char           *sep = RDFSTORE_WORD_SPLITS;
	int             err, l, i = 0;
	rdf_store_digest_t  hc = 0;

	int islval=0;
	int isdval=0;
	long thelval;
	double thedval;
	struct tm thedateval_tm;
	struct tm* ptm;
	time_t now;
	char thedateval[RDFSTORE_XSD_DATETIME_FORMAT_SIZE];

	assert(sizeof(unsigned char)==1);

#ifdef RDFSTORE_CONNECTIONS
	/* buffers for connections matrixes */
	static unsigned char s_connections[RDFSTORE_MAXRECORDS_BYTES_SIZE];
	static unsigned char p_connections[RDFSTORE_MAXRECORDS_BYTES_SIZE];
	static unsigned char o_connections[RDFSTORE_MAXRECORDS_BYTES_SIZE];
	unsigned int    s_outsize = 0;
	unsigned int    p_outsize = 0;
	unsigned int    o_outsize = 0;

	bzero(s_connections,sizeof(RDFSTORE_MAXRECORDS_BYTES_SIZE));
	bzero(p_connections,sizeof(RDFSTORE_MAXRECORDS_BYTES_SIZE));
	bzero(o_connections,sizeof(RDFSTORE_MAXRECORDS_BYTES_SIZE));

#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
	rdfstore_iterator *reindex;
	unsigned int    pos = 0;
	RDF_Statement * neighbour;
	unsigned int    outsize_reindex = 0;
	static unsigned char reindex_encode[RDFSTORE_MAXRECORDS_BYTES_SIZE];
	static unsigned char reindex_decode[RDFSTORE_MAXRECORDS_BYTES_SIZE];

	bzero(reindex_encode,sizeof(RDFSTORE_MAXRECORDS_BYTES_SIZE));
	bzero(reindex_decode,sizeof(RDFSTORE_MAXRECORDS_BYTES_SIZE));
#endif

#endif

	/*
	  int ttime=0; struct timeval tstart,tnow;
	 */

	/*
	  gettimeofday(&tstart,NULL);
	 */

#ifdef RDFSTORE_FLAT_STORE_DEBUG /*&& RDFSTORE_COUNT_OPERATIONS_PER_STATEMENT*/
	rdfstore_flat_store_reset_debuginfo(me->model);
	rdfstore_flat_store_reset_debuginfo(me->statements);
	rdfstore_flat_store_reset_debuginfo(me->nodes);
	rdfstore_flat_store_reset_debuginfo(me->subjects);
	rdfstore_flat_store_reset_debuginfo(me->predicates);
	rdfstore_flat_store_reset_debuginfo(me->objects);
#ifdef RDFSTORE_CONNECTIONS
	if(me->s_connections)
		rdfstore_flat_store_reset_debuginfo(me->s_connections);
	if(me->p_connections)
		rdfstore_flat_store_reset_debuginfo(me->p_connections);
	if(me->o_connections)
		rdfstore_flat_store_reset_debuginfo(me->o_connections);
#endif
	if(me->languages)
		rdfstore_flat_store_reset_debuginfo(me->languages);
	if(me->datatypes)
		rdfstore_flat_store_reset_debuginfo(me->datatypes);
	if(me->xsd_integer)
		rdfstore_flat_store_reset_debuginfo(me->xsd_integer);
	if(me->xsd_double)
		rdfstore_flat_store_reset_debuginfo(me->xsd_double);
	if(me->xsd_date)
		rdfstore_flat_store_reset_debuginfo(me->xsd_date);
	if (context != NULL)
		rdfstore_flat_store_reset_debuginfo(me->contexts);
	if (me->freetext)
		rdfstore_flat_store_reset_debuginfo(me->windex);
        fprintf(stderr,"rdfstore_insert BEGIN (reset number of DB operations)\n");
#endif

	if ((statement == NULL) ||
	    (statement->subject == NULL) ||
	    (statement->predicate == NULL) ||
	    (statement->subject->value.resource.identifier == NULL) ||
	    (statement->predicate->value.resource.identifier == NULL) ||
	    (statement->object == NULL) ||
	    ((statement->object->type != 1) &&
	     (statement->object->value.resource.identifier == NULL)) ||
	    ((given_context != NULL) &&
	     (given_context->value.resource.identifier == NULL)) ||
	    ((statement->node != NULL) &&
	     (statement->node->value.resource.identifier == NULL))) {
#ifdef RDFSTORE_DEBUG
		fprintf(stderr,"Wrong params\n");
#endif
		return -1;
	}

	if (given_context == NULL) {
		if (statement->context != NULL)
			context = statement->context;
		else {
			/* use default context */
			if (me->context != NULL)
				context = me->context;
		};
	} else {
		/* use given context instead */
		context = given_context;
	};

#ifdef RDFSTORE_DEBUG
	fprintf(stderr,"TO ADD:\n");
	fprintf(stderr,"\tS='%s'\n", statement->subject->value.resource.identifier);
	fprintf(stderr,"\tP='%s'\n", statement->predicate->value.resource.identifier);
	if (statement->object->type != 1) {
		fprintf(stderr,"\tO='%s'\n", statement->object->value.resource.identifier);
	} else {
		fprintf(stderr,"\tOLIT='%s'", statement->object->value.literal.string);
		fprintf(stderr," LANG='%s'", statement->object->value.literal.lang);
                fprintf(stderr," TYPE='%s'", statement->object->value.literal.dataType);
                fprintf(stderr," PARSETYPE='%d'", statement->object->value.literal.parseType);
                fprintf(stderr,"\n");
		};
	if (context != NULL) {
		fprintf(stderr,"\tC='%s'\n", context->value.resource.identifier);
	};
	if (statement->node != NULL)
		fprintf(stderr,"\tSRES='%s'\n", statement->node->value.resource.identifier);
	fprintf(stderr," with options freetext='%d'\n", me->freetext);
	if ((buff = rdfstore_ntriples_statement(statement, context)) != NULL) {
		fprintf(stderr," N-triples: %s\n", buff);
		RDFSTORE_FREE(buff);
	};
#endif

	memset(&key, 0, sizeof(key));
	memset(&data, 0, sizeof(data));

#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
	/* init re-index iterator (needed below when filling up adjacency matrixes) */
	reindex = (rdfstore_iterator *) RDFSTORE_MALLOC(sizeof(rdfstore_iterator));
        if (reindex == NULL) {
                perror("rdfstore_insert");
                fprintf(stderr,"Cannot create reindex cursor/iterator for store '%s'\n", (me->name != NULL) ? me->name : "(in-memory)");
                return -1;
        	};
        reindex->store = me;
        reindex->store->attached++;
        reindex->remove_holes = 0;      /* reset the total number of holes */
        reindex->st_counter = 0;
        reindex->pos = 0;
        reindex->ids_size = 0;
        reindex->size = 0;
#endif

	/* compute statement hashcode */
	hc = rdfstore_digest_get_statement_hashCode(statement, context);

	/* cache the hashcode if the statement has a "proper" identity */
	if ((given_context == NULL) &&
	    (me->context == NULL))
		statement->hashcode = hc;

	/* we do not want duplicates (in the same context) */
	packInt(hc, outbuf);

#ifdef RDFSTORE_DEBUG
	printf("Statement hashcode is '%d' while packed is '", hc);
	for (i = 0; i < sizeof(int); i++) {
		printf("%02X", outbuf[i]);
		};
	printf("'\n");
#endif

	key.data = outbuf;
	key.size = sizeof(int);
	if ((rdfstore_flat_store_exists(me->statements, key)) == 0) {
#ifdef RDFSTORE_DEBUG
		if ((buff = rdfstore_ntriples_statement(statement, context)) != NULL) {
			fprintf(stderr,"Cannot insert multiple copies of the statement '%s' for store '%s' on key=%x\n", 
				buff, (me->name != NULL) ? me->name : "(in-memory)",(int)((int *)(outbuf)));
			RDFSTORE_FREE(buff);
			};
#endif
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
		rdfstore_iterator_close(reindex);
#endif
		return 1;
		};

	/*
	 * NOTE about interpretation of contexts:
	 * 
	 * E.g.   If the context is the timestamp of yesterday we can insert a
	 * statement in that context (temporal context); then we can retrieve
	 * it in the given context 'has somebody said something yesterday
	 * about the statement?'. The answer would be affermative. In case
	 * the context is not set it make a lot of sense ask to the database
	 * 'has never been said something about the statement (ever!)?'; the
	 * answer would be the same and affermative. If the context would be
	 * another one for example the timestamp of today, than the answer to
	 * the question 'has somebody said something today about the
	 * statement?' would be definitively *false*. This example can be
	 * applied to RSS1.0 feeds of news if you wish....
	 * 
	 * This to me is really much the same of 'views' (or grouping??!?)
	 * concept in traditional relational databases
	 */

	/*
	 * About the indexing algorithm see doc/SWADe-rdfstore.html
	 */

	/* store the STATEMENT */
	key.data = RDFSTORE_COUNTER_KEY;
        key.size = sizeof(RDFSTORE_COUNTER_KEY);

	/* increment statement counter */
	if ((rdfstore_flat_store_inc(me->model, key, &data)) != 0) {
		perror("rdfstore_insert");
		fprintf(stderr,"Could not increment statement counter for store '%s': %s\n", (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->model));
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
		rdfstore_iterator_close(reindex);
#endif
		return -1;
		};
	unpackInt(data.data,&st_id);

	RDFSTORE_FREE(data.data);

#ifdef RDFSTORE_DEBUG
	{
		fprintf(stderr, "New statement identifier: %d > %d\n", (int)st_id, (int)RDFSTORE_MAXRECORDS);
	};
#endif

	if (st_id > RDFSTORE_MAXRECORDS) {
		if ((rdfstore_flat_store_dec(me->model, key, &data)) == 0)
			RDFSTORE_FREE(data.data);
		perror("rdfstore_insert");
		fprintf(stderr,"RDFSTORE_MAXRECORDS(%d) reached (st_id=%d) - can not insert more statements in store '%s': %s\n", RDFSTORE_MAXRECORDS, st_id, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->model));
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
		rdfstore_iterator_close(reindex);
#endif
		return -1;
		};

	/* the counter starts from zero anyway! */
	st_id--;

	/* force this (or warning/error returned ?? ) */
	/*
	 * rdf:parseType="Literal" is like
	 * rdf:datatype="http://www.w3.org/1999/02/22-rdf-syntax-ns#XMLLiteral"  - is it still after new RDF specs?
	 */
	if (statement->object->type == 1) {
		if ((statement->object->value.literal.parseType == 1) &&
		    (statement->object->value.literal.dataType != NULL) &&
		    (strcmp(statement->object->value.literal.dataType, RDFSTORE_RDF_PARSETYPE_LITERAL))) {
			perror("rdfstore_insert");
			fprintf(stderr,"Statement object '%s' has rdf:parseType='Literal' but rdf:dataType='%s'\n", statement->object->value.literal.string, statement->object->value.literal.dataType);
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
			rdfstore_iterator_close(reindex);
#endif
			return -1;
		} else if ((statement->object->value.literal.dataType != NULL) &&
			   (strcmp(statement->object->value.literal.dataType, RDFSTORE_RDF_PARSETYPE_LITERAL) == 0) &&
			   (statement->object->value.literal.parseType != 1)) {
			perror("rdfstore_insert");
			fprintf(stderr,"Statement object '%s' has rdf:dataType='%s' but rdf:parseType='Resource'\n", statement->object->value.literal.string, RDFSTORE_RDF_PARSETYPE_LITERAL);
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
			rdfstore_iterator_close(reindex);
#endif
			return -1;
			};
		};

	/* nodes table */

	/* try to allocate just the necessary - this means that
         * we must use memcpy (and not strcpy) to fill it as other
         * wise the extra \0 throws us one off.
         */
        l = (sizeof(int) * 7) + sizeof(char) +
            (sizeof(char) * statement->subject->value.resource.identifier_len)+
            (sizeof(char) * statement->predicate->value.resource.identifier_len) +
            ((statement->object->type != 1) ?
                (sizeof(char) * statement->object->value.resource.identifier_len) :
                ((sizeof(char) * ((statement->object->value.literal.string != NULL) ? statement->object->value.literal.string_len : 0)) +
            (((statement->object->value.literal.lang != NULL) && (strlen(statement->object->value.literal.lang) > 0)) ?
                (sizeof(char) * strlen(statement->object->value.literal.lang)) : 0) +
            ((statement->object->value.literal.dataType != NULL) ? (sizeof(char) * strlen(statement->object->value.literal.dataType)) : 0))) +
            ((context != NULL) ?
                (sizeof(char) * context->value.resource.identifier_len) : 0) +
            ((statement->node != NULL) ?
                (sizeof(char) * statement->node->value.resource.identifier_len) : 0);

        if (l < sizeof(nodebuf))
                buff = nodebuf;
        else
                buff = _buff = (char *)RDFSTORE_MALLOC(l);

        if (buff == NULL) {
                perror("rdfstore_insert");
                fprintf(stderr,"Could not allocate memory for statement in store '%s'\n", (me->name != NULL) ? me->name : "(in-memory)");
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
		rdfstore_iterator_close(reindex);
#endif
                return -1;
        	};

	assert(sizeof(int) == 4);

	/* offsets */
	i = 0;

	/* subject */
	packInt(statement->subject->value.resource.identifier_len, outbuf);
	memcpy(buff + i, outbuf, sizeof(int));
	i += sizeof(int);

	/* predicate */
	packInt(statement->predicate->value.resource.identifier_len, outbuf);
	memcpy(buff + i, outbuf, sizeof(int));
	i += sizeof(int);

	/* object */
	packInt((statement->object->type != 1) ?
		statement->object->value.resource.identifier_len :
		(statement->object->value.literal.string != NULL) ? statement->object->value.literal.string_len : 0, outbuf);
	memcpy(buff + i, outbuf, sizeof(int));
	i += sizeof(int);

	/* object literal language */
	packInt(((statement->object->type == 1) && (statement->object->value.literal.lang != NULL) && (strlen(statement->object->value.literal.lang) > 0)) ? strlen(statement->object->value.literal.lang) : 0, outbuf);
	memcpy(buff + i, outbuf, sizeof(int));
	i += sizeof(int);

	/* object literal data type */
	packInt(((statement->object->type == 1) && (statement->object->value.literal.dataType != NULL)) ? strlen(statement->object->value.literal.dataType) : 0, outbuf);
	memcpy(buff + i, outbuf, sizeof(int));
	i += sizeof(int);

	/* context */
	packInt((context != NULL) ? context->value.resource.identifier_len : 0, outbuf);
	memcpy(buff + i, outbuf, sizeof(int));
	i += sizeof(int);

	/* statement resource hashcode (if statement is a resource) */
	packInt((statement->node != NULL) ? statement->node->value.resource.identifier_len : 0, outbuf);
	memcpy(buff + i, outbuf, sizeof(int));
	i += sizeof(int);

	/* mask for special byte */
	if (statement->object->type == 1)
		mask |= 1;

	if (statement->subject->type == 2)
		mask |= 2;

	if (statement->predicate->type == 2)
		mask |= 4;

	if (statement->object->type == 2)
		mask |= 8;

	if ((context != NULL) &&
	    (context->type == 2))
		mask |= 16;

	if (statement->isreified == 1)
		mask |= 32;

	memcpy(buff + i, &mask, 1);
	i++;

	/* subject */
	memcpy(buff + i, statement->subject->value.resource.identifier, statement->subject->value.resource.identifier_len);
	i += statement->subject->value.resource.identifier_len;

	/* predicate */
	memcpy(buff + i, statement->predicate->value.resource.identifier, statement->predicate->value.resource.identifier_len);
	i += statement->predicate->value.resource.identifier_len;

	/* object */
	if (statement->object->type == 1) {     
                /* object literal string itself */
                if (statement->object->value.literal.string != NULL) {
                        memcpy(buff + i, statement->object->value.literal.string, statement->object->value.literal.string_len);
                        i += statement->object->value.literal.string_len;
                	};
                /* object literal language */ 
                if (statement->object->value.literal.lang != NULL) {
                        memcpy(buff + i, statement->object->value.literal.lang, strlen(statement->object->value.literal.lang));
                        i += strlen(statement->object->value.literal.lang);
                	};
                /* object literal data type */
                if (statement->object->value.literal.dataType != NULL) {
                        memcpy(buff + i, statement->object->value.literal.dataType, strlen(statement->object->value.literal.dataType));
                        i += strlen(statement->object->value.literal.dataType);
                	};   
        } else {
                memcpy(buff + i, statement->object->value.resource.identifier, statement->object->value.resource.identifier_len);
                i += statement->object->value.resource.identifier_len;
        	};

	/* context */
	if (context != NULL) {
		memcpy(buff + i, context->value.resource.identifier, context->value.resource.identifier_len);
		i += context->value.resource.identifier_len;
		};

	/* statement as resource stuff */
	if (statement->node != NULL) {
		memcpy(buff + i, statement->node->value.resource.identifier, statement->node->value.resource.identifier_len);
		i += statement->node->value.resource.identifier_len;
		};

	/* Check out lenght calcuation.. */
        assert(l == i);

	/* store the whole content */
	packInt(st_id, outbuf);

	key.data = outbuf;
	key.size = sizeof(int);

	buff[i++] = '\0';	/* Terminate the string and increase the length */
	data.data = buff;
	data.size = i;

	err = rdfstore_flat_store_store(me->nodes, key, data);

	if (_buff)
                RDFSTORE_FREE(_buff);

	if ((err != 0) &&
	    (err != FLAT_STORE_E_KEYEXIST)) {
		perror("rdfstore_insert");
		fprintf(stderr,"Could not store '%d' bytes for statememt in nodes for store '%s': %s\n", (int)data.size, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->nodes));
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
		rdfstore_iterator_close(reindex);
#endif
		return -1;
		};

	/* index special literal stuff */
	if (statement->object->type == 1) {
		if (	(me->freetext) &&
		    	(statement->object->value.literal.string != NULL) &&
			(statement->object->value.literal.string_len > 0) ) {
			utf8_casefolded_buff = (unsigned char *)RDFSTORE_MALLOC(statement->object->value.literal.string_len * sizeof(unsigned char) * (RDFSTORE_UTF8_MAXLEN_FOLD + 1));	/* what about the ending '\0' here ?? */
			if (utf8_casefolded_buff == NULL) {
				perror("rdfstore_insert");
				fprintf(stderr,"Cannot compute case-folded string out of input literal for store '%s'\n", (me->name != NULL) ? me->name : "(in-memory)");
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
				rdfstore_iterator_close(reindex);
#endif
				return -1;
				};
			if (rdfstore_utf8_string_to_utf8_foldedcase(statement->object->value.literal.string_len, statement->object->value.literal.string, &utf8_size, utf8_casefolded_buff)) {
				perror("rdfstore_insert");
				fprintf(stderr,"Cannot compute case-folded string out of input literal for store '%s'\n", (me->name != NULL) ? me->name : "(in-memory)");
				RDFSTORE_FREE(utf8_casefolded_buff);
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
				rdfstore_iterator_close(reindex);
#endif
				return -1;
				};

			/* we do not even try to avoid duplicates for the moment */
			for (	word = strtok(utf8_casefolded_buff, sep);
			     	word;
			     	word = strtok(NULL, sep) ) {
				int jj=0;
				int kk=0;

				key.data = word;
				key.size = strlen(word);

				/*
				 * 
				 * bzero(me->bits_encode,sizeof(me->bits_encode
				 * ));
				 * bzero(me->bits_decode,sizeof(me->bits_decod
				 * e));
				 */
				err = rdfstore_flat_store_fetch_compressed(me->windex, me->func_decode, key, &outsize, me->bits_decode);
				if (err != 0) {
					if (err != FLAT_STORE_E_NOTFOUND) {
						RDFSTORE_FREE(utf8_casefolded_buff);
						perror("rdfstore_insert");
						fprintf(stderr,"Could not fetch windex of word '%s' for store '%s': %s\n", word, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->windex));
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
						rdfstore_iterator_close(reindex);
#endif
						return -1;
					} else {
						outsize = 0;
						};
					};

				rdfstore_bits_setmask(&outsize, me->bits_decode, st_id, 1, 1, sizeof(me->bits_decode));

				if (outsize) {
					err = rdfstore_flat_store_store_compressed(me->windex, me->func_encode, key, outsize, me->bits_decode,me->bits_encode );
					if (err == 0) {
#ifdef RDFSTORE_DEBUG_COMPRESSION
						fprintf(stderr,"Stored %d bytes for '%s' in windex for store '%s'\n", outsize, (char *)key.data, (me->name != NULL) ? me->name : "(in-memory)");
#endif
					} else {
						if (err != FLAT_STORE_E_KEYEXIST) {
							RDFSTORE_FREE(utf8_casefolded_buff);
							perror("rdfstore_insert");
							fprintf(stderr,"Could not store '%d' bytes for word '%s' in windex for store '%s': %s\n", (int)data.size, word, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->windex));
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
							rdfstore_iterator_close(reindex);
#endif
							return -1;
							};
						};

#ifdef RDFSTORE_DEBUG
					{
						int             i;
						if ((rdfstore_flat_store_fetch(me->windex, key, &data)) == 0) {
							me->func_decode(data.size, data.data, &outsize, me->bits_decode);
							RDFSTORE_FREE(data.data);
						};
						printf("ADDED (%d) windex for case-folded word '%s' -->'", st_id, word);
						for(i=0;i<8*outsize;i++) {
							printf("Rec %d %c\n", i, (me->bits_decode[i>>3] & (1<<(i&7))) ? '1':'0');
							};
						printf("'\n");
					}
#endif

					};
		
				/* 
				stemming code for ISO-Latin languiages (left-to-right) and shouild be UTF-8 aware
				ie. word = "stemming" -- do index --> "s", "st", "ste", ....
				*/
#if RDFSTORE_WORD_STEMMING > 0

				if(	( rdfstore_xsd_deserialize_integer( word, &thelval ) ) ||
					( rdfstore_xsd_deserialize_double( word, &thedval )  ) ||
					( rdfstore_xsd_deserialize_dateTime(	word,
										&thedateval_tm ) ) ||
					( rdfstore_xsd_deserialize_date(	word,
										&thedateval_tm ) ) || /* dates are skipped, even if rdf:datatype is not set */
					(strlen(word)<=1) )
					continue;

				/* for efficency we should check if the given partial stem has been already indexed for the same word!!! */
				jj=1;
				while (	( jj < strlen(word) ) &&
					( kk < RDFSTORE_WORD_STEMMING ) ) {
					char stem[MIN((RDFSTORE_WORD_STEMMING*RDFSTORE_UTF8_MAXLEN_FOLD),strlen(word))+1];

					bzero(stem,MIN((RDFSTORE_WORD_STEMMING*RDFSTORE_UTF8_MAXLEN_FOLD),strlen(word))+1);

					/* look for next utf8 char to add to stemming string */
					utf8_size=0;
					while (	( jj < strlen(word) ) &&
                                        	(!( rdfstore_utf8_is_utf8( word+jj, &utf8_size ) )) ) {
						jj++;
						};

					if (jj>strlen(word)) {
						strncpy(stem, word, jj-1);
					} else {
						strncpy(stem, word, jj);
						};

					key.data = stem;
					key.size = strlen(stem);

					err = rdfstore_flat_store_fetch(me->windex, key, &data);
					if (err != 0) {
						if (err != FLAT_STORE_E_NOTFOUND) {
							RDFSTORE_FREE(utf8_casefolded_buff);
							perror("rdfstore_insert");
							fprintf(stderr,"Could not fetch windex of stemming '%s' of word '%s' for store '%s': %s\n", stem, word, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->windex));
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
							rdfstore_iterator_close(reindex);
#endif
							return -1;
						} else {
							outsize = 0;
							};
					} else {
						me->func_decode(data.size, data.data, &outsize, me->bits_decode);	/* perhaps the
															 * compression for
															 * single bits could be
															 * different */
						RDFSTORE_FREE(data.data);
						};
					rdfstore_bits_setmask(&outsize, me->bits_decode, st_id, 1, 1, sizeof(me->bits_decode));

					me->func_encode(outsize, me->bits_decode, &outsize, me->bits_encode);
					if (outsize) {
						data.data = me->bits_encode;
						data.size = outsize;
						err = rdfstore_flat_store_store(me->windex, key, data);
						if (err == 0) {
#ifdef RDFSTORE_DEBUG_COMPRESSION
							fprintf(stderr,"Stored %d bytes for '%s' in windex for store '%s'\n", outsize, (char *)key.data, (me->name != NULL) ? me->name : "(in-memory)");
#endif
						} else {
							if (err != FLAT_STORE_E_KEYEXIST) {
								RDFSTORE_FREE(utf8_casefolded_buff);
								perror("rdfstore_insert");
								fprintf(stderr,"Could not store '%d' bytes for stemming '%s' in windex for store '%s': %s\n", (int)data.size, stem, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->windex));
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
								rdfstore_iterator_close(reindex);
#endif
								return -1;
								};
							};

#ifdef RDFSTORE_DEBUG
					{
						int             i;
						if ((rdfstore_flat_store_fetch(me->windex, key, &data)) == 0) {
							me->func_decode(data.size, data.data, &outsize, me->bits_decode);
							RDFSTORE_FREE(data.data);
						};
						printf("ADDED (%d) windex for case-folded stemming '%s' of word '%s' -->'", st_id, stem, word);
						for (i = 0; i < outsize; i++) {
							printf("%02X", me->bits_decode[i]);
						};
						printf("'\n");
					}
#endif

						};
					jj++;
					kk++;
					};
#endif
				};
			RDFSTORE_FREE(utf8_casefolded_buff);
			};

		/* languages table */
		if (	(statement->object->value.literal.lang != NULL) &&
			(strlen(statement->object->value.literal.lang) > 0) ) {
			utf8_casefolded_buff = (unsigned char *)RDFSTORE_MALLOC(strlen(statement->object->value.literal.lang) * sizeof(unsigned char) * (RDFSTORE_UTF8_MAXLEN_FOLD + 1));
			if (utf8_casefolded_buff == NULL) {
				perror("rdfstore_insert");
				fprintf(stderr,"Cannot compute case-folded string for literal language code '%s' for store '%s'\n", statement->object->value.literal.lang, (me->name != NULL) ? me->name : "(in-memory)");
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
				rdfstore_iterator_close(reindex);
#endif
				return -1;
				};
			if (rdfstore_utf8_string_to_utf8_foldedcase(strlen(statement->object->value.literal.lang), statement->object->value.literal.lang, &utf8_size, utf8_casefolded_buff)) {
				perror("rdfstore_insert");
				fprintf(stderr,"Cannot compute case-folded string for literal language code '%s' for store '%s'\n", statement->object->value.literal.lang, (me->name != NULL) ? me->name : "(in-memory)");
				RDFSTORE_FREE(utf8_casefolded_buff);
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
				rdfstore_iterator_close(reindex);
#endif
				return -1;
				};

			key.data = utf8_casefolded_buff;
			key.size = utf8_size;

			err = rdfstore_flat_store_fetch(me->languages, key, &data);
			if (err != 0) {
				if (err != FLAT_STORE_E_NOTFOUND) {
					RDFSTORE_FREE(utf8_casefolded_buff);
					perror("rdfstore_insert");
					fprintf(stderr,"Could not fetch language '%s' of literal '%s' for store '%s': %s\n", statement->object->value.literal.lang, statement->object->value.literal.string, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->languages));
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
					rdfstore_iterator_close(reindex);
#endif
					return -1;
				} else {
					outsize = 0;
					};
			} else {
				me->func_decode(data.size, data.data, &outsize, me->bits_decode);
				RDFSTORE_FREE(data.data);
				};
			rdfstore_bits_setmask(&outsize, me->bits_decode, st_id, 1, 1, sizeof(me->bits_decode));

			me->func_encode(outsize, me->bits_decode, &outsize, me->bits_encode);
			if (outsize) {
				data.data = me->bits_encode;
				data.size = outsize;
				err = rdfstore_flat_store_store(me->languages, key, data);
				if (err == 0) {
#ifdef RDFSTORE_DEBUG_COMPRESSION
					fprintf(stderr,"Stored %d bytes for '%s' in languages for store '%s'\n", outsize, (char *)key.data, (me->name != NULL) ? me->name : "(in-memory)");
#endif
				} else {
					if (err != FLAT_STORE_E_KEYEXIST) {
						RDFSTORE_FREE(utf8_casefolded_buff);
						perror("rdfstore_insert");
						fprintf(stderr,"Could not store '%d' bytes for language '%s' in languages for store '%s': %s\n", (int)data.size, statement->object->value.literal.lang, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->languages));
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
						rdfstore_iterator_close(reindex);
#endif
						return -1;
						};
					};

#ifdef RDFSTORE_DEBUG
				{
				int             i;
				if ((rdfstore_flat_store_fetch(me->languages, key, &data)) == 0) {
					me->func_decode(data.size, data.data, &outsize, me->bits_decode);
					RDFSTORE_FREE(data.data);
				};
				printf("ADDED (%d) language '%s' of literal '%s' -->'", st_id, statement->object->value.literal.lang, statement->object->value.literal.string);
				for (i = 0; i < outsize; i++) {
					printf("%02X", me->bits_decode[i]);
					};
				printf("'\n");
				}
#endif

				};

			RDFSTORE_FREE(utf8_casefolded_buff);
			};

		/* datatypes table */
		if (	(statement->object->value.literal.dataType != NULL) &&
			(strlen(statement->object->value.literal.dataType) > 0) ) {
			key.data = statement->object->value.literal.dataType;
			key.size = strlen(statement->object->value.literal.dataType);

			err = rdfstore_flat_store_fetch(me->datatypes, key, &data);
			if (err != 0) {
				if (err != FLAT_STORE_E_NOTFOUND) {
					perror("rdfstore_insert");
					fprintf(stderr,"Could not fetch datatype '%s' of literal '%s' for store '%s': %s\n", statement->object->value.literal.dataType, statement->object->value.literal.string, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->datatypes));
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
					rdfstore_iterator_close(reindex);
#endif
					return -1;
				} else {
					outsize = 0;
					};
			} else {
				me->func_decode(data.size, data.data, &outsize, me->bits_decode);
				RDFSTORE_FREE(data.data);
				};
			rdfstore_bits_setmask(&outsize, me->bits_decode, st_id, 1, 1, sizeof(me->bits_decode));

			me->func_encode(outsize, me->bits_decode, &outsize, me->bits_encode);
			if (outsize) {
				data.data = me->bits_encode;
				data.size = outsize;
				err = rdfstore_flat_store_store(me->datatypes, key, data);
				if (err == 0) {
#ifdef RDFSTORE_DEBUG_COMPRESSION
					fprintf(stderr,"Stored %d bytes for '%s' in datatypes for store '%s'\n", outsize, (char *)key.data, (me->name != NULL) ? me->name : "(in-memory)");
#endif
				} else {
					if (err != FLAT_STORE_E_KEYEXIST) {
						perror("rdfstore_insert");
						fprintf(stderr,"Could not store '%d' bytes for datatype '%s' in datatypes for store '%s': %s\n", (int)data.size, statement->object->value.literal.dataType, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->datatypes));
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
						rdfstore_iterator_close(reindex);
#endif
						return -1;
						};
					};

#ifdef RDFSTORE_DEBUG
				{
				int             i;
				if ((rdfstore_flat_store_fetch(me->datatypes, key, &data)) == 0) {
					me->func_decode(data.size, data.data, &outsize, me->bits_decode);
					RDFSTORE_FREE(data.data);
				};
				printf("ADDED (%d) datatype '%s' of literal '%s' -->'", st_id, statement->object->value.literal.dataType, statement->object->value.literal.string);
				for (i = 0; i < outsize; i++) {
					printf("%02X", me->bits_decode[i]);
					};
				printf("'\n");
				}
#endif

				};

			/* date type indexing only if rdf:datatype is set accordingly to xsd:date or xsd:dateTime */
			if(	(strcmp(statement->object->value.literal.dataType,RDFSTORE_MS_XSD_DATE)==0) ||
				(strcmp(statement->object->value.literal.dataType,RDFSTORE_MS_XSD_DATETIME)==0) ) {
				if (	( rdfstore_xsd_deserialize_dateTime(	statement->object->value.literal.string,
										&thedateval_tm ) ) ||
					( rdfstore_xsd_deserialize_date(	statement->object->value.literal.string,
										&thedateval_tm ) ) ) {

					rdfstore_xsd_serialize_dateTime( thedateval_tm, thedateval ); /* we index xsd:dataTime version anyway */

					key.data = thedateval;
					key.size = strlen(thedateval)+1;

#ifdef RDFSTORE_DEBUG
fprintf(stderr, "INDEX DATE '%s' for LITERAL '%s' \n",thedateval, statement->object->value.literal.string);
#endif

					err = rdfstore_flat_store_fetch(me->xsd_date, key, &data);
					if (err != 0) {
						if (err != FLAT_STORE_E_NOTFOUND) {
							perror("rdfstore_insert");
							fprintf(stderr,"Could not fetch from date table value '%s' for store '%s': %s\n", statement->object->value.literal.string, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->xsd_date));
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
							rdfstore_iterator_close(reindex);
#endif
							return -1;
						} else {
							outsize = 0;
							};
					} else {
						me->func_decode(data.size, data.data, &outsize, me->bits_decode);
						RDFSTORE_FREE(data.data);
						};
					rdfstore_bits_setmask(&outsize, me->bits_decode, st_id, 1, 1, sizeof(me->bits_decode));

					me->func_encode(outsize, me->bits_decode, &outsize, me->bits_encode);
					if (outsize) {
						data.data = me->bits_encode;
						data.size = outsize;
						err = rdfstore_flat_store_store(me->xsd_date, key, data);
						if (err == 0) {
#ifdef RDFSTORE_DEBUG_COMPRESSION
							fprintf(stderr,"Stored %d bytes for date '%s' in literal '%s' in integer table for store '%s'\n", outsize, thedateval, statement->object->value.literal.string, (me->name != NULL) ? me->name : "(in-memory)");
#endif
						} else {
							if (err != FLAT_STORE_E_KEYEXIST) {
								perror("rdfstore_insert");
								fprintf(stderr,"Could not store '%d' bytes for date '%s' in literal '%s' in date table for store '%s': %s\n", (int)data.size, thedateval, statement->object->value.literal.string, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->xsd_date));
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
								rdfstore_iterator_close(reindex);
#endif
								return -1;
								};
							};

#ifdef RDFSTORE_DEBUG
						{
						int             i;
						if ((rdfstore_flat_store_fetch(me->xsd_date, key, &data)) == 0) {
							me->func_decode(data.size, data.data, &outsize, me->bits_decode);
							RDFSTORE_FREE(data.data);
							};
						printf("ADDED (%d) date '%s' of literal '%s' -->'", st_id, thedateval, statement->object->value.literal.string);
						for (i = 0; i < outsize; i++) {
							printf("%02X", me->bits_decode[i]);
							};
						printf("'\n");
						}
#endif

						};
					};
				}; /* end of date indexing */
			};

		/* for xsd:integer alike literals use special b-tree sorted index if strtol() works.... */
		if( ( islval = rdfstore_xsd_deserialize_integer( statement->object->value.literal.string, &thelval ) ) != 0 ) {
			key.data = (long*) &thelval; /* should pack int perhaps... */
			key.size = sizeof(long);

#ifdef RDFSTORE_DEBUG
fprintf(stderr, "INDEX INTEGER '%ld' for LITERAL '%s' \n",(long)thelval, statement->object->value.literal.string);
#endif

			err = rdfstore_flat_store_fetch(me->xsd_integer, key, &data);
			if (err != 0) {
				if (err != FLAT_STORE_E_NOTFOUND) {
					perror("rdfstore_insert");
					fprintf(stderr,"Could not fetch from integer table value '%s' for store '%s': %s\n", statement->object->value.literal.string, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->xsd_integer));
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
					rdfstore_iterator_close(reindex);
#endif
					return -1;
				} else {
					outsize = 0;
					};
			} else {
				me->func_decode(data.size, data.data, &outsize, me->bits_decode);
				RDFSTORE_FREE(data.data);
				};
			rdfstore_bits_setmask(&outsize, me->bits_decode, st_id, 1, 1, sizeof(me->bits_decode));

			me->func_encode(outsize, me->bits_decode, &outsize, me->bits_encode);
			if (outsize) {
				data.data = me->bits_encode;
				data.size = outsize;
				err = rdfstore_flat_store_store(me->xsd_integer, key, data);
				if (err == 0) {
#ifdef RDFSTORE_DEBUG_COMPRESSION
					fprintf(stderr,"Stored %d bytes for integer '%ld' in literal '%s' in integer table for store '%s'\n", outsize, (long)thelval, statement->object->value.literal.string, (me->name != NULL) ? me->name : "(in-memory)");
#endif
				} else {
					if (err != FLAT_STORE_E_KEYEXIST) {
						perror("rdfstore_insert");
						fprintf(stderr,"Could not store '%d' bytes for integer '%ld' in literal '%s' in integer table for store '%s': %s\n", (int)data.size, (long)thelval, statement->object->value.literal.string, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->xsd_integer));
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
						rdfstore_iterator_close(reindex);
#endif
						return -1;
						};
					};

#ifdef RDFSTORE_DEBUG
				{
				int             i;
				if ((rdfstore_flat_store_fetch(me->xsd_integer, key, &data)) == 0) {
					me->func_decode(data.size, data.data, &outsize, me->bits_decode);
					RDFSTORE_FREE(data.data);
				};
				printf("ADDED (%d) integer '%ld' of literal '%s' -->'", st_id, (long)thelval, statement->object->value.literal.string);
				for (i = 0; i < outsize; i++) {
					printf("%02X", me->bits_decode[i]);
					};
				printf("'\n");
				}
#endif

				};

			};

		/* for xsd:double or xsd:float alike literals use special b-tree sorted index if strtod() works.... */
		if(	( islval == 0 ) && /* do not index xsd:integer(s) twice also as xsd:double */
			( ( isdval = rdfstore_xsd_deserialize_double( statement->object->value.literal.string, &thedval ) ) != 0 ) ) {
			key.data = (double*) &thedval; /* should pack int perhaps... */
			key.size = sizeof(double);

#ifdef RDFSTORE_DEBUG
fprintf(stderr, "INDEX DOUBLE '%f' for LITERAL '%s' \n",thedval, statement->object->value.literal.string);
#endif

			err = rdfstore_flat_store_fetch(me->xsd_double, key, &data);
			if (err != 0) {
				if (err != FLAT_STORE_E_NOTFOUND) {
					perror("rdfstore_insert");
					fprintf(stderr,"Could not fetch from double table value '%s' for store '%s': %s\n", statement->object->value.literal.string, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->xsd_double));
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
					rdfstore_iterator_close(reindex);
#endif
					return -1;
				} else {
					outsize = 0;
					};
			} else {
				me->func_decode(data.size, data.data, &outsize, me->bits_decode);
				RDFSTORE_FREE(data.data);
				};
			rdfstore_bits_setmask(&outsize, me->bits_decode, st_id, 1, 1, sizeof(me->bits_decode));

			me->func_encode(outsize, me->bits_decode, &outsize, me->bits_encode);
			if (outsize) {
				data.data = me->bits_encode;
				data.size = outsize;
				err = rdfstore_flat_store_store(me->xsd_double, key, data);
				if (err == 0) {
#ifdef RDFSTORE_DEBUG_COMPRESSION
					fprintf(stderr,"Stored %d bytes for double '%f' in literal '%s' in double table for store '%s'\n", outsize, thedval, statement->object->value.literal.string, (me->name != NULL) ? me->name : "(in-memory)");
#endif
				} else {
					if (err != FLAT_STORE_E_KEYEXIST) {
						perror("rdfstore_insert");
						fprintf(stderr,"Could not store '%d' bytes for double '%f' in literal '%s' in double table for store '%s': %s\n", (int)data.size, thedval, statement->object->value.literal.string, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->xsd_double));
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
						rdfstore_iterator_close(reindex);
#endif
						return -1;
						};
					};

#ifdef RDFSTORE_DEBUG
				{
				int             i;
				if ((rdfstore_flat_store_fetch(me->xsd_double, key, &data)) == 0) {
					me->func_decode(data.size, data.data, &outsize, me->bits_decode);
					RDFSTORE_FREE(data.data);
				};
				printf("ADDED (%d) double '%f' of literal '%s' -->'", st_id, thedval, statement->object->value.literal.string);
				for (i = 0; i < outsize; i++) {
					printf("%02X", me->bits_decode[i]);
					};
				printf("'\n");
				}
#endif

				};

			};
		}; /* end index special literal stuff */

	/*
	 * gettimeofday(&tnow,NULL); ttime = ( tnow.tv_sec - tstart.tv_sec ) *
	 * 1000000 + ( tnow.tv_usec - tstart.tv_usec ) * 1;
	 * printf("rdfstore_insert DONE [%d micro sec]\n",ttime);
	 */

	/* adjacency matrixes (tables) i.e. subjects, predicates, objects, contexts and connections */

	/*
	 * compute other hashcodes (the should be cached because the
	 * underlying digest is carried out also for the statement->hashcode
	 * above)
	 */
	statement->subject->hashcode = rdfstore_digest_get_node_hashCode(statement->subject, 0);
	statement->predicate->hashcode = rdfstore_digest_get_node_hashCode(statement->predicate, 0);
	statement->object->hashcode = rdfstore_digest_get_node_hashCode(statement->object, 0);
	if (context != NULL)
		context->hashcode = rdfstore_digest_get_node_hashCode(context, 0);

	/*
         * possible connections (see doc/SWADe-rdfstore.html)
         *
	 *
         * subjects table template:
         * -------------------------------------
	 *               st_num   01234567 89..
         *  node
         * -------------------------------------
         *  subject-node          10000010 00
         * -------------------------------------
         *                        ^     ^
         *                        |     |
	 *   st_num(0)->subject --+     |
	 *                              |
	 *   st_num(6)->subject --------+
	 *
	 *
	 * Similarly the other predicates and objects tables
	 * are being generated - similarly contexts table is
	 * filled in for particulat context-node(s) for a
	 * a given statement.
	 *
	 *
	 * connections tables template: (to be completed)
	 *
	 *	--> it maps DUG (normalized DLG) graph nodes to their connections and
	 *	    corresponding statements
         *
	 *
	 * Anoatomy of connections insertion/updation
         *
         * here are all the possible connections a new statement might get into (i.e. "swiss army knife problem"):
         *
         *              a4                     a6               a8
         *               \                      \                \
         *                \                      \                \
         *                 \---> A =============> B =============> C------>b9----->c9
         *                     / ^\              /^\               ^\
         *                    /  | \            / | \              | \
         *             b5<---/   |  \--->c4    /  |  \--->c6       |  \--->c8
         *            /          b1           /   b2               b3
         *           /           ^     b7<---/    ^                ^
         *    c5<---/            |     \          |                |
         *                       |      \         |                |
	 *                       a1      \--->c7  a2               a3
         *
         *
         * where  A======>B======>C is the new statement to add
         *
         * then each A, B or C gets it respective connections (s_connection, p_connections or o_connections) table
         * set with ALL the possible other connections with the existing statements - the possible connections are
         * carried out by a permutation on all possible positions of each s,p,o component node on the subject, predicates
         * or objects table values (who has which node). Due that no intrisic ordering of statement can be assumed, quite a 
         * lot of re-indexing is required when inserting a new statement - such overhaead can be roughly estimated up to 6*3 
         * re-indexing operations per statement. This is the case when the new statement is being connected to mostly any other 
         * neighbour statement already existing - the re-indexing require to set the right bitno into connections tables for each 
         * neighbour its components (see code below now). Of course molteplicity of connections on arcs is assumed not to be a
         * problem in the resulting Directed Unlabelled Graph (DUG) of nodes.
         *
         */

	/* subjects */
	packInt(statement->subject->hashcode, outbuf);
	key.data = outbuf;
	key.size = sizeof(int);

	/*
	 * bzero(me->bits_encode,sizeof(me->bits_encode));
	 * bzero(me->bits_decode,sizeof(me->bits_decode));
	 */

	err = rdfstore_flat_store_fetch(me->subjects, key, &data);
	if (err != 0) {
		if (err != FLAT_STORE_E_NOTFOUND) {
			perror("rdfstore_insert");
			fprintf(stderr,"Could not fetch key '%s' for subject in subjects table for store '%s': %s\n", (char *)key.data, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->subjects));
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
			rdfstore_iterator_close(reindex);
#endif
			return -1;
		} else {
			outsize = 0;
			};
	} else {
		me->func_decode(data.size, data.data, &outsize, me->bits_decode);	/* perhaps the
											 * compression for
											 * single bits could be
											 * different */
		RDFSTORE_FREE(data.data);
		};

#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
	/*
		We need to re-index quite a lot for each new statement component now - hope caching will 
		help here!! i.e. the swiss army nife problem (see SWAD-E paper and preso)

		1.1) add this new statement (st_id) to p_connections(neighbour->predicate) and o_connections(neighbour->object)
		   tables of each other statement (neighbour) connected to this one via subjects(SUBJECT) node
		1.2) add this new statement (st_id) to s_connections(neighbour->subject) and o_connections(neighbour->object)
		   tables of each other statement (neighbour) connected to this one via predicates(SUBJECT) node
		1.3) add this new statement (st_id) to s_connections(neighbour->subject) and p_connections(neighbour->predicate)
		   tables of each other statement (neighbour) connected to this one via objects(SUBJECT) node
	*/

	/* 1.1) reindex st_id for connections to subjects(SUBJECT) node */

	/* copy the subjects(SUBJECT) bits through the reindex iterator array */
        memcpy(reindex->ids, me->bits_decode, outsize);
        reindex->ids_size = outsize;
        /* set the size - inefficient!! */
        pos = 0;
        reindex->size = 0;
        /* count the ones (inefficient still) */
        while ((pos = rdfstore_bits_getfirstsetafter(outsize, me->bits_decode, pos)) < 8 * outsize) {
                reindex->size++;
                pos++;
        	};

	/* scan the obtained iterator */
	while ( ( neighbour = rdfstore_iterator_each ( reindex ) ) != NULL ) {

#ifdef RDFSTORE_DEBUG_CONNECTIONS
		printf("(insert)REINDEXING predicate '%s' for connections to subjects('%s') node in st_id=%d\n",neighbour->predicate->value.resource.identifier,statement->subject->value.resource.identifier,st_id);
#endif
		neighbour->predicate->hashcode = rdfstore_digest_get_node_hashCode(neighbour->predicate, 0);

		/* fetch p_connections(neighbour->predicate) */
		packInt(neighbour->predicate->hashcode, outbuf); /* wrong */
		key.data = outbuf;
		key.size = sizeof(int);

		err = rdfstore_flat_store_fetch(me->p_connections, key, &data);
		if (err != 0) {
			if (err != FLAT_STORE_E_NOTFOUND) {
				perror("rdfstore_insert");
				fprintf(stderr,"Could not fetch key '%s' for predicate in p_connections table for store '%s': %s\n", (char *)key.data, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->p_connections));
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
				rdfstore_iterator_close(reindex);
#endif
				return -1;
			} else {
				outsize_reindex = 0;
			};
		} else {
			me->func_decode_connections(data.size, data.data, &outsize_reindex, reindex_decode);
			RDFSTORE_FREE(data.data);
			};

		/* set the corresponding bit of this statement */
		rdfstore_bits_setmask(&outsize_reindex, reindex_decode, st_id, 1, 1, sizeof(reindex_decode));

		/* store it back */
		me->func_encode_connections(outsize_reindex, reindex_decode, &outsize_reindex, reindex_encode);

		data.data = reindex_encode;
		data.size = outsize_reindex;
		err = rdfstore_flat_store_store(me->p_connections, key, data);
		if (err != 0) {
			if (err != FLAT_STORE_E_KEYEXIST) {
				perror("rdfstore_insert");
				fprintf(stderr,"Could not store '%d' bytes for predicate in p_connections table for store '%s': %s\n", (int)data.size, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->p_connections));
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
				rdfstore_iterator_close(reindex);
#endif
				return -1;
				};
			};

#ifdef RDFSTORE_DEBUG_CONNECTIONS
		printf("(insert)REINDEXING object '%s' for connections to subjects('%s') node in st_id=%d\n",(neighbour->object->type==1) ? neighbour->object->value.literal.string : neighbour->object->value.resource.identifier,statement->subject->value.resource.identifier,st_id);
#endif
		neighbour->object->hashcode = rdfstore_digest_get_node_hashCode(neighbour->object, 0);

		/* fetch o_connections(neighbour->object) */
		packInt(neighbour->object->hashcode, outbuf); /* wrong */
		key.data = outbuf;
		key.size = sizeof(int);

		err = rdfstore_flat_store_fetch(me->o_connections, key, &data);
		if (err != 0) {
			if (err != FLAT_STORE_E_NOTFOUND) {
				perror("rdfstore_insert");
				fprintf(stderr,"Could not fetch key '%s' for object in o_connections table for store '%s': %s\n", (char *)key.data, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->o_connections));
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
				rdfstore_iterator_close(reindex);
#endif
				return -1;
			} else {
				outsize_reindex = 0;
			};
		} else {
			me->func_decode_connections(data.size, data.data, &outsize_reindex, reindex_decode);
			RDFSTORE_FREE(data.data);
			};

		/* set the corresponding bit of this statement */
		rdfstore_bits_setmask(&outsize_reindex, reindex_decode, st_id, 1, 1, sizeof(reindex_decode));

		/* store it back */
		me->func_encode_connections(outsize_reindex, reindex_decode, &outsize_reindex, reindex_encode);

		data.data = reindex_encode;
		data.size = outsize_reindex;
		err = rdfstore_flat_store_store(me->o_connections, key, data);
		if (err != 0) {
			if (err != FLAT_STORE_E_KEYEXIST) {
				perror("rdfstore_insert");
				fprintf(stderr,"Could not store '%d' bytes for object in o_connections table for store '%s': %s\n", (int)data.size, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->o_connections));
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
				rdfstore_iterator_close(reindex);
#endif
				return -1;
				};
			};

		/* free neighbour */
                RDFSTORE_FREE( neighbour->subject->value.resource.identifier );
                RDFSTORE_FREE( neighbour->subject );
                RDFSTORE_FREE( neighbour->predicate->value.resource.identifier );
                RDFSTORE_FREE( neighbour->predicate );
                if ( neighbour->object->type == 1 ) {
                        if ( neighbour->object->value.literal.dataType != NULL )
                                RDFSTORE_FREE( neighbour->object->value.literal.dataType );
                        RDFSTORE_FREE( neighbour->object->value.literal.string );
                } else {
                        RDFSTORE_FREE( neighbour->object->value.resource.identifier );
                        };
                RDFSTORE_FREE( neighbour->object );
                if ( neighbour->context != NULL ) {
                        RDFSTORE_FREE( neighbour->context->value.resource.identifier );
                        RDFSTORE_FREE( neighbour->context );
                        };
                if ( neighbour->node != NULL ) {
                        RDFSTORE_FREE( neighbour->node->value.resource.identifier );
                        RDFSTORE_FREE( neighbour->node );
                        };
                RDFSTORE_FREE( neighbour );
		};
#endif

	rdfstore_bits_setmask(&outsize, me->bits_decode, st_id, 1, 1, sizeof(me->bits_decode));

#ifdef RDFSTORE_CONNECTIONS
	/* COPY subjects(SUBJECT) to s_connections(SUBJECT) */
        bcopy(me->bits_decode, s_connections, outsize);   /* slow? */
	s_outsize = outsize;

	/* COPY subjects(SUBJECT) to p_connections(PREDICATE) */
        bcopy(me->bits_decode, p_connections, outsize);   /* slow? */
	p_outsize = outsize;

	/* COPY subjects(SUBJECT) to o_connections(OBJECT) */
        bcopy(me->bits_decode, o_connections, outsize);   /* slow? */
	o_outsize = outsize;
#endif

	me->func_encode(outsize, me->bits_decode, &outsize, me->bits_encode);
	if (outsize) {

		/* regenerate it due to the re-indexing above which uses key already */
		packInt(statement->subject->hashcode, outbuf);
		key.data = outbuf;
		key.size = sizeof(int);

		data.data = me->bits_encode;
		data.size = outsize;
		err = rdfstore_flat_store_store(me->subjects, key, data);
		if (err == 0) {
#ifdef RDFSTORE_DEBUG_COMPRESSION
			fprintf(stderr,"Stored %d bytes for '%s' in subjects table for store '%s'\n", outsize, (char *)key.data, (me->name != NULL) ? me->name : "(in-memory)");
#endif
		} else {
			if (err != FLAT_STORE_E_KEYEXIST) {
				perror("rdfstore_insert");
				fprintf(stderr,"Could not store '%d' bytes for subject in subjects table for store '%s': %s\n", (int)data.size, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->subjects));
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
				rdfstore_iterator_close(reindex);
#endif
				return -1;
			};
		};

#ifdef RDFSTORE_DEBUG
		{
			int             i=0;
			if ((rdfstore_flat_store_fetch(me->subjects, key, &data)) == 0) {
				me->func_decode(data.size, data.data, &outsize, me->bits_decode);
				RDFSTORE_FREE(data.data);
			};
			printf("ADDED st_num=%d bitno=%d subjects for S '%s' -->'", st_id, st_id, statement->subject->value.resource.identifier);
			for(i=0;i<8*outsize;i++) {
				printf("Rec %d %c\n", i, (me->bits_decode[i>>3] & (1<<(i&7))) ? '1':'0');
                                };
			printf("'\n");
		}
#endif

	};

MX;
	/* predicates */
	packInt(statement->predicate->hashcode, outbuf);
	key.data = outbuf;
	key.size = sizeof(int);
MX;

	/*
	 * bzero(me->bits_encode,sizeof(me->bits_encode));
	 * bzero(me->bits_decode,sizeof(me->bits_decode));
	 */
	err = rdfstore_flat_store_fetch(me->predicates, key, &data);
MX;
	if (err != 0) {
		if (err != FLAT_STORE_E_NOTFOUND) {
			perror("rdfstore_insert");
			fprintf(stderr,"Could not fetch key '%s' for predicate in predicates table for store '%s': %s\n", (char *)key.data, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->predicates));
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
			rdfstore_iterator_close(reindex);
#endif
			return -1;
		} else {
			outsize = 0;
		};
MX;
	} else {
MX;
		me->func_decode(data.size, data.data, &outsize, me->bits_decode);
MX;
		RDFSTORE_FREE(data.data);
	};

#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
        /* 2.2) reindex st_id for connections to predicates(PREDICATE) node */

	/* copy the predicates(PREDICATE) bits through the reindex iterator array */
        memcpy(reindex->ids, me->bits_decode, outsize);
        reindex->ids_size = outsize;
        /* set the size - inefficient!! */
        pos = 0;
        reindex->size = 0;
        /* count the ones (inefficient still) */
        while ((pos = rdfstore_bits_getfirstsetafter(outsize, me->bits_decode, pos)) < 8 * outsize) {
                reindex->size++;
                pos++;
        	};

	/* scan the obtained iterator */
	while ( ( neighbour = rdfstore_iterator_each ( reindex ) ) != NULL ) {

#ifdef RDFSTORE_DEBUG_CONNECTIONS
		printf("(insert)REINDEXING subject '%s' for connections to predicates('%s') node in st_id=%d\n",neighbour->subject->value.resource.identifier,statement->predicate->value.resource.identifier,st_id);
#endif
		neighbour->subject->hashcode = rdfstore_digest_get_node_hashCode(neighbour->subject, 0);

		/* fetch s_connections(neighbour->subject) */
		packInt(neighbour->subject->hashcode, outbuf); /* wrong */
		key.data = outbuf;
		key.size = sizeof(int);

		err = rdfstore_flat_store_fetch(me->s_connections, key, &data);
		if (err != 0) {
			if (err != FLAT_STORE_E_NOTFOUND) {
				perror("rdfstore_insert");
				fprintf(stderr,"Could not fetch key '%s' for subject in s_connections table for store '%s': %s\n", (char *)key.data, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->s_connections));
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
				rdfstore_iterator_close(reindex);
#endif
				return -1;
			} else {
				outsize_reindex = 0;
			};
		} else {
			me->func_decode_connections(data.size, data.data, &outsize_reindex, reindex_decode);
			RDFSTORE_FREE(data.data);
			};

		/* set the corresponding bit of this statement */
		rdfstore_bits_setmask(&outsize_reindex, reindex_decode, st_id, 1, 1, sizeof(reindex_decode));

		/* store it back */
		me->func_encode_connections(outsize_reindex, reindex_decode, &outsize_reindex, reindex_encode);

		data.data = reindex_encode;
		data.size = outsize_reindex;
		err = rdfstore_flat_store_store(me->s_connections, key, data);
		if (err != 0) {
			if (err != FLAT_STORE_E_KEYEXIST) {
				perror("rdfstore_insert");
				fprintf(stderr,"Could not store '%d' bytes for subject in s_connections table for store '%s': %s\n", (int)data.size, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->s_connections));
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
				rdfstore_iterator_close(reindex);
#endif
				return -1;
				};
			};

#ifdef RDFSTORE_DEBUG_CONNECTIONS
		printf("(insert)REINDEXING object '%s' for connections to predicates('%s') node in st_id=%d\n",(neighbour->object->type==1) ? neighbour->object->value.literal.string : neighbour->object->value.resource.identifier,statement->predicate->value.resource.identifier,st_id);
#endif
		neighbour->object->hashcode = rdfstore_digest_get_node_hashCode(neighbour->object, 0);

		/* fetch o_connections(neighbour->object) */
		packInt(neighbour->object->hashcode, outbuf); /* wrong */
		key.data = outbuf;
		key.size = sizeof(int);

		err = rdfstore_flat_store_fetch(me->o_connections, key, &data);
		if (err != 0) {
			if (err != FLAT_STORE_E_NOTFOUND) {
				perror("rdfstore_insert");
				fprintf(stderr,"Could not fetch key '%s' for object in o_connections table for store '%s': %s\n", (char *)key.data, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->o_connections));
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
				rdfstore_iterator_close(reindex);
#endif
				return -1;
			} else {
				outsize_reindex = 0;
			};
		} else {
			me->func_decode_connections(data.size, data.data, &outsize_reindex, reindex_decode);
			RDFSTORE_FREE(data.data);
			};

		/* set the corresponding bit of this statement */
		rdfstore_bits_setmask(&outsize_reindex, reindex_decode, st_id, 1, 1, sizeof(reindex_decode));

		/* store it back */
		me->func_encode_connections(outsize_reindex, reindex_decode, &outsize_reindex, reindex_encode);

		data.data = reindex_encode;
		data.size = outsize_reindex;
		err = rdfstore_flat_store_store(me->o_connections, key, data);
		if (err != 0) {
			if (err != FLAT_STORE_E_KEYEXIST) {
				perror("rdfstore_insert");
				fprintf(stderr,"Could not store '%d' bytes for object in o_connections table for store '%s': %s\n", (int)data.size, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->o_connections));
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
				rdfstore_iterator_close(reindex);
#endif
				return -1;
				};
			};

		/* free neighbour */
                RDFSTORE_FREE( neighbour->subject->value.resource.identifier );
                RDFSTORE_FREE( neighbour->subject );
                RDFSTORE_FREE( neighbour->predicate->value.resource.identifier );
                RDFSTORE_FREE( neighbour->predicate );
                if ( neighbour->object->type == 1 ) {
                        if ( neighbour->object->value.literal.dataType != NULL )
                                RDFSTORE_FREE( neighbour->object->value.literal.dataType );
                        RDFSTORE_FREE( neighbour->object->value.literal.string );
                } else {
                        RDFSTORE_FREE( neighbour->object->value.resource.identifier );
                        };
                RDFSTORE_FREE( neighbour->object );
                if ( neighbour->context != NULL ) {
                        RDFSTORE_FREE( neighbour->context->value.resource.identifier );
                        RDFSTORE_FREE( neighbour->context );
                        };
                if ( neighbour->node != NULL ) {
                        RDFSTORE_FREE( neighbour->node->value.resource.identifier );
                        RDFSTORE_FREE( neighbour->node );
                        };
                RDFSTORE_FREE( neighbour );
		};
#endif

MX;
	rdfstore_bits_setmask(&outsize, me->bits_decode, st_id, 1, 1, sizeof(me->bits_decode));
MX;

#ifdef RDFSTORE_CONNECTIONS
	/* OR predicates(PREDICATE) to s_connections(SUBJECT) */
        s_outsize = rdfstore_bits_or(outsize, me->bits_decode, s_outsize, s_connections, me->bits_encode); /* use me->bits_encode for easyness 
													     no problem due is rest with encode 
													     operation below here */
        bcopy(me->bits_encode, s_connections, s_outsize);   /* slow? */


	/* OR predicates(PREDICATE) to p_connections(PREDICATE) */
        p_outsize = rdfstore_bits_or(outsize, me->bits_decode, p_outsize, p_connections, me->bits_encode);
        bcopy(me->bits_encode, p_connections, p_outsize);   /* slow? */

	/* OR predicates(PREDICATE) to o_connections(OBJECT) */
        o_outsize = rdfstore_bits_or(outsize, me->bits_decode, o_outsize, o_connections, me->bits_encode);
        bcopy(me->bits_encode, o_connections, o_outsize);   /* slow? */
#endif

	me->func_encode(outsize, me->bits_decode, &outsize, me->bits_encode);
	if (outsize) {

		/* regenerate it due to the re-indexing above which uses key already */
		packInt(statement->predicate->hashcode, outbuf);
		key.data = outbuf;
		key.size = sizeof(int);

		data.data = me->bits_encode;
		data.size = outsize;
		err = rdfstore_flat_store_store(me->predicates, key, data);
		if (err == 0) {
#ifdef RDFSTORE_DEBUG_COMPRESSION
			fprintf(stderr,"Stored %d bytes for '%s' in predicates table for store '%s'\n", outsize, (char *)key.data, (me->name != NULL) ? me->name : "(in-memory)");
#endif
		} else {
			if (err != FLAT_STORE_E_KEYEXIST) {
				perror("rdfstore_insert");
				fprintf(stderr,"Could not store '%d' bytes for predicate in predicates table for store '%s': %s\n", (int)data.size, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->predicates));
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
				rdfstore_iterator_close(reindex);
#endif
				return -1;
			};
		};

#ifdef RDFSTORE_DEBUG
		{
			int             i=0;
			if ((rdfstore_flat_store_fetch(me->predicates, key, &data)) == 0) {
				me->func_decode(data.size, data.data, &outsize, me->bits_decode);
				RDFSTORE_FREE(data.data);
			};
			printf("ADDED st_num=%d bitno=%d predicates for P '%s' -->'", st_id, st_id, statement->predicate->value.resource.identifier);
			for(i=0;i<8*outsize;i++) {
				printf("Rec %d %c\n", i, (me->bits_decode[i>>3] & (1<<(i&7))) ? '1':'0');
                                };
			printf("'\n");
		}
#endif

	};

	/* objects */
	packInt(statement->object->hashcode, outbuf);
	key.data = outbuf;
	key.size = sizeof(int);

	/*
	 * bzero(me->bits_encode,sizeof(me->bits_encode));
	 * bzero(me->bits_decode,sizeof(me->bits_decode));
	 */

	err = rdfstore_flat_store_fetch(me->objects, key, &data);
	if (err != 0) {
		if (err != FLAT_STORE_E_NOTFOUND) {
			perror("rdfstore_insert");
			fprintf(stderr,"Could not fetch key '%s' for object in objects table for store '%s': %s\n", (char *)key.data, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->objects));
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
			rdfstore_iterator_close(reindex);
#endif
			return -1;
		} else {
			outsize = 0;
		};
	} else {
		me->func_decode(data.size, data.data, &outsize, me->bits_decode);	/* perhaps the
												 * compression for
												 * single bits could be
												 * different */
		RDFSTORE_FREE(data.data);
	};

#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
        /* 3.3) reindex st_id for connections to objects(OBJECT) node */

	/* copy the objects(OBJECT) bits through the reindex iterator array */
        memcpy(reindex->ids, me->bits_decode, outsize);
        reindex->ids_size = outsize;
        /* set the size - inefficient!! */
        pos = 0;
        reindex->size = 0;
        /* count the ones (inefficient still) */
        while ((pos = rdfstore_bits_getfirstsetafter(outsize, me->bits_decode, pos)) < 8 * outsize) {
                reindex->size++;
                pos++;
        	};

	/* scan the obtained iterator */
	while ( ( neighbour = rdfstore_iterator_each ( reindex ) ) != NULL ) {

#ifdef RDFSTORE_DEBUG_CONNECTIONS
		printf("(insert)REINDEXING subject '%s' for connections to objects('%s') node in st_id=%d\n",neighbour->subject->value.resource.identifier,(statement->object->type==1) ? statement->object->value.literal.string : statement->object->value.resource.identifier,st_id);
#endif
		neighbour->subject->hashcode = rdfstore_digest_get_node_hashCode(neighbour->subject, 0);

		/* fetch s_connections(neighbour->subject) */
		packInt(neighbour->subject->hashcode, outbuf); /* wrong */
		key.data = outbuf;
		key.size = sizeof(int);

		err = rdfstore_flat_store_fetch(me->s_connections, key, &data);
		if (err != 0) {
			if (err != FLAT_STORE_E_NOTFOUND) {
				perror("rdfstore_insert");
				fprintf(stderr,"Could not fetch key '%s' for subject in s_connections table for store '%s': %s\n", (char *)key.data, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->s_connections));
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
				rdfstore_iterator_close(reindex);
#endif
				return -1;
			} else {
				outsize_reindex = 0;
			};
		} else {
			me->func_decode_connections(data.size, data.data, &outsize_reindex, reindex_decode);
			RDFSTORE_FREE(data.data);
			};

		/* set the corresponding bit of this statement */
		rdfstore_bits_setmask(&outsize_reindex, reindex_decode, st_id, 1, 1, sizeof(reindex_decode));

		/* store it back */
		me->func_encode_connections(outsize_reindex, reindex_decode, &outsize_reindex, reindex_encode);

		data.data = reindex_encode;
		data.size = outsize_reindex;
		err = rdfstore_flat_store_store(me->s_connections, key, data);
		if (err != 0) {
			if (err != FLAT_STORE_E_KEYEXIST) {
				perror("rdfstore_insert");
				fprintf(stderr,"Could not store '%d' bytes for subject in s_connections table for store '%s': %s\n", (int)data.size, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->s_connections));
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
				rdfstore_iterator_close(reindex);
#endif
				return -1;
				};
			};

#ifdef RDFSTORE_DEBUG_CONNECTIONS
		printf("(insert)REINDEXING predicate '%s' for connections to objects('%s') node in st_id=%d\n",neighbour->predicate->value.resource.identifier,(statement->object->type==1) ? statement->object->value.literal.string : statement->object->value.resource.identifier,st_id);
#endif
		neighbour->predicate->hashcode = rdfstore_digest_get_node_hashCode(neighbour->predicate, 0);

		/* fetch p_connections(neighbour->predicate) */
		packInt(neighbour->predicate->hashcode, outbuf); /* wrong */
		key.data = outbuf;
		key.size = sizeof(int);

		err = rdfstore_flat_store_fetch(me->p_connections, key, &data);
		if (err != 0) {
			if (err != FLAT_STORE_E_NOTFOUND) {
				perror("rdfstore_insert");
				fprintf(stderr,"Could not fetch key '%s' for predicate in p_connections table for store '%s': %s\n", (char *)key.data, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->p_connections));
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
				rdfstore_iterator_close(reindex);
#endif
				return -1;
			} else {
				outsize_reindex = 0;
			};
		} else {
			me->func_decode_connections(data.size, data.data, &outsize_reindex, reindex_decode);
			RDFSTORE_FREE(data.data);
			};

		/* set the corresponding bit of this statement */
		rdfstore_bits_setmask(&outsize_reindex, reindex_decode, st_id, 1, 1, sizeof(reindex_decode));

		/* store it back */
		me->func_encode_connections(outsize_reindex, reindex_decode, &outsize_reindex, reindex_encode);

		data.data = reindex_encode;
		data.size = outsize_reindex;
		err = rdfstore_flat_store_store(me->p_connections, key, data);
		if (err != 0) {
			if (err != FLAT_STORE_E_KEYEXIST) {
				perror("rdfstore_insert");
				fprintf(stderr,"Could not store '%d' bytes for predicate in p_connections table for store '%s': %s\n", (int)data.size, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->p_connections));
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
				rdfstore_iterator_close(reindex);
#endif
				return -1;
				};
			};

		/* free neighbour */
                RDFSTORE_FREE( neighbour->subject->value.resource.identifier );
                RDFSTORE_FREE( neighbour->subject );
                RDFSTORE_FREE( neighbour->predicate->value.resource.identifier );
                RDFSTORE_FREE( neighbour->predicate );
                if ( neighbour->object->type == 1 ) {
                        if ( neighbour->object->value.literal.dataType != NULL )
                                RDFSTORE_FREE( neighbour->object->value.literal.dataType );
                        RDFSTORE_FREE( neighbour->object->value.literal.string );
                } else {
                        RDFSTORE_FREE( neighbour->object->value.resource.identifier );
                        };
                RDFSTORE_FREE( neighbour->object );
                if ( neighbour->context != NULL ) {
                        RDFSTORE_FREE( neighbour->context->value.resource.identifier );
                        RDFSTORE_FREE( neighbour->context );
                        };
                if ( neighbour->node != NULL ) {
                        RDFSTORE_FREE( neighbour->node->value.resource.identifier );
                        RDFSTORE_FREE( neighbour->node );
                        };
                RDFSTORE_FREE( neighbour );
		};
#endif

	rdfstore_bits_setmask(&outsize, me->bits_decode, st_id, 1, 1, sizeof(me->bits_decode));

#ifdef RDFSTORE_CONNECTIONS
        /* OR objects(OBJECT) to s_connections(SUBJECT) */
        s_outsize = rdfstore_bits_or(outsize, me->bits_decode, s_outsize, s_connections, me->bits_encode);
        bcopy(me->bits_encode, s_connections, s_outsize);   /* slow? */

	/* OR objects(OBJECT) to p_connections(PREDICATE) */
        p_outsize = rdfstore_bits_or(outsize, me->bits_decode, p_outsize, p_connections, me->bits_encode);
        bcopy(me->bits_encode, p_connections, p_outsize);   /* slow? */

	/* OR objects(OBJECT) to o_connections(OBJECT) */
        o_outsize = rdfstore_bits_or(outsize, me->bits_decode, o_outsize, o_connections, me->bits_encode);
        bcopy(me->bits_encode, o_connections, o_outsize);   /* slow? */
#endif

	me->func_encode(outsize, me->bits_decode, &outsize, me->bits_encode);
	if (outsize) {

		/* regenerate it due to the re-indexing above which uses key already */
		packInt(statement->object->hashcode, outbuf);
		key.data = outbuf;
		key.size = sizeof(int);

		data.data = me->bits_encode;
		data.size = outsize;
		err = rdfstore_flat_store_store(me->objects, key, data);
		if (err == 0) {
#ifdef RDFSTORE_DEBUG_COMPRESSION
			fprintf(stderr,"Stored %d bytes for '%s' in objects table for store '%s'\n", outsize, (char *)key.data, (me->name != NULL) ? me->name : "(in-memory)");
#endif
		} else {
			if (err != FLAT_STORE_E_KEYEXIST) {
				perror("rdfstore_insert");
				fprintf(stderr,"Could not store '%d' bytes for object in objects table for store '%s': %s\n", (int)data.size, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->objects));
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
				rdfstore_iterator_close(reindex);
#endif
				return -1;
			};
		};

#ifdef RDFSTORE_DEBUG
		{
			int             i=0;
			if ((rdfstore_flat_store_fetch(me->objects, key, &data)) == 0) {
				me->func_decode(data.size, data.data, &outsize, me->bits_decode);
				RDFSTORE_FREE(data.data);
			};
			printf("ADDED st_num=%d bitno=%d objects for O '%s' -->'", st_id, st_id, (statement->object->type != 1) ? statement->object->value.resource.identifier : statement->object->value.literal.string);
			for(i=0;i<8*outsize;i++) {
				printf("Rec %d %c\n", i, (me->bits_decode[i>>3] & (1<<(i&7))) ? '1':'0');
                                };
			printf("'\n");
		}
#endif

	};

#ifdef RDFSTORE_CONNECTIONS
	/* fill up all the rest of s_connections, p_connections and o_connections i.e. carry out remaining permutations of each component */

	/* fetch subjects(PREDICATE) i.e. statements which has PREDICATE as subject */
	packInt(statement->predicate->hashcode, outbuf);
	key.data = outbuf;
	key.size = sizeof(int);

	err = rdfstore_flat_store_fetch(me->subjects, key, &data);
	if (err != 0) {
		if (err != FLAT_STORE_E_NOTFOUND) {
			perror("rdfstore_insert");
			fprintf(stderr,"Could not fetch key '%s' for predicate in subjects table for store '%s': %s\n", (char *)key.data, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->subjects));
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
			rdfstore_iterator_close(reindex);
#endif
			return -1;
		} else {
			outsize = 0;
		};
	} else {
		me->func_decode(data.size, data.data, &outsize, me->bits_decode);
		RDFSTORE_FREE(data.data);
		};

#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
	/*
                We need to re-index quite a lot for each new statement component now - hope caching will
                help here!! i.e. the swiss army nife problem (see SWAD-E paper and preso)

                2.1) add this new statement (st_id) to p_connections(neighbour->predicate) and o_connections(neighbour->object)
                   tables of each other statement (neighbour) connected to this one via subjects(PREDICATE) node
                2.2) add this new statement (st_id) to s_connections(neighbour->subject) and o_connections(neighbour->object)
                   tables of each other statement (neighbour) connected to this one via predicates(PREDICATE) node
                2.3) add this new statement (st_id) to s_connections(neighbour->subject) and p_connections(neighbour->predicate)
                   tables of each other statement (neighbour) connected to this one via objects(PREDICATE) node
        */

        /* 2.1) reindex st_id for connections to subjects(PREDICATE) node */

	/* copy the subjects(PREDICATE) bits through the reindex iterator array */
        memcpy(reindex->ids, me->bits_decode, outsize);
        reindex->ids_size = outsize;
        /* set the size - inefficient!! */
        pos = 0;
        reindex->size = 0;
        /* count the ones (inefficient still) */
        while ((pos = rdfstore_bits_getfirstsetafter(outsize, me->bits_decode, pos)) < 8 * outsize) {
                reindex->size++;
                pos++;
        	};

	/* scan the obtained iterator */
	while ( ( neighbour = rdfstore_iterator_each ( reindex ) ) != NULL ) {

#ifdef RDFSTORE_DEBUG_CONNECTIONS
		printf("(insert)REINDEXING predicate '%s' for connections to subjects('%s') node in st_id=%d\n",neighbour->predicate->value.resource.identifier,statement->predicate->value.resource.identifier,st_id);
#endif
		neighbour->predicate->hashcode = rdfstore_digest_get_node_hashCode(neighbour->predicate, 0);

		/* fetch p_connections(neighbour->predicate) */
		packInt(neighbour->predicate->hashcode, outbuf); /* wrong */
		key.data = outbuf;
		key.size = sizeof(int);

		err = rdfstore_flat_store_fetch(me->p_connections, key, &data);
		if (err != 0) {
			if (err != FLAT_STORE_E_NOTFOUND) {
				perror("rdfstore_insert");
				fprintf(stderr,"Could not fetch key '%s' for predicate in p_connections table for store '%s': %s\n", (char *)key.data, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->p_connections));
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
				rdfstore_iterator_close(reindex);
#endif
				return -1;
			} else {
				outsize_reindex = 0;
			};
		} else {
			me->func_decode_connections(data.size, data.data, &outsize_reindex, reindex_decode);
			RDFSTORE_FREE(data.data);
			};

		/* set the corresponding bit of this statement */
		rdfstore_bits_setmask(&outsize_reindex, reindex_decode, st_id, 1, 1, sizeof(reindex_decode));

		/* store it back */
		me->func_encode_connections(outsize_reindex, reindex_decode, &outsize_reindex, reindex_encode);

		data.data = reindex_encode;
		data.size = outsize_reindex;
		err = rdfstore_flat_store_store(me->p_connections, key, data);
		if (err != 0) {
			if (err != FLAT_STORE_E_KEYEXIST) {
				perror("rdfstore_insert");
				fprintf(stderr,"Could not store '%d' bytes for predicate in p_connections table for store '%s': %s\n", (int)data.size, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->p_connections));
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
				rdfstore_iterator_close(reindex);
#endif
				return -1;
				};
			};

#ifdef RDFSTORE_DEBUG_CONNECTIONS
		printf("(insert)REINDEXING object '%s' for connections to subjects('%s') node in st_id=%d\n",(neighbour->object->type==1) ? neighbour->object->value.literal.string : neighbour->object->value.resource.identifier,statement->predicate->value.resource.identifier,st_id);
#endif
		neighbour->object->hashcode = rdfstore_digest_get_node_hashCode(neighbour->object, 0);

		/* fetch o_connections(neighbour->object) */
		packInt(neighbour->object->hashcode, outbuf); /* wrong */
		key.data = outbuf;
		key.size = sizeof(int);

		err = rdfstore_flat_store_fetch(me->o_connections, key, &data);
		if (err != 0) {
			if (err != FLAT_STORE_E_NOTFOUND) {
				perror("rdfstore_insert");
				fprintf(stderr,"Could not fetch key '%s' for object in o_connections table for store '%s': %s\n", (char *)key.data, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->o_connections));
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
				rdfstore_iterator_close(reindex);
#endif
				return -1;
			} else {
				outsize_reindex = 0;
			};
		} else {
			me->func_decode_connections(data.size, data.data, &outsize_reindex, reindex_decode);
			RDFSTORE_FREE(data.data);
			};

		/* set the corresponding bit of this statement */
		rdfstore_bits_setmask(&outsize_reindex, reindex_decode, st_id, 1, 1, sizeof(reindex_decode));

		/* store it back */
		me->func_encode_connections(outsize_reindex, reindex_decode, &outsize_reindex, reindex_encode);

		data.data = reindex_encode;
		data.size = outsize_reindex;
		err = rdfstore_flat_store_store(me->o_connections, key, data);
		if (err != 0) {
			if (err != FLAT_STORE_E_KEYEXIST) {
				perror("rdfstore_insert");
				fprintf(stderr,"Could not store '%d' bytes for object in o_connections table for store '%s': %s\n", (int)data.size, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->o_connections));
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
				rdfstore_iterator_close(reindex);
#endif
				return -1;
				};
			};

		/* free neighbour */
                RDFSTORE_FREE( neighbour->subject->value.resource.identifier );
                RDFSTORE_FREE( neighbour->subject );
                RDFSTORE_FREE( neighbour->predicate->value.resource.identifier );
                RDFSTORE_FREE( neighbour->predicate );
                if ( neighbour->object->type == 1 ) {
                        if ( neighbour->object->value.literal.dataType != NULL )
                                RDFSTORE_FREE( neighbour->object->value.literal.dataType );
                        RDFSTORE_FREE( neighbour->object->value.literal.string );
                } else {
                        RDFSTORE_FREE( neighbour->object->value.resource.identifier );
                        };
                RDFSTORE_FREE( neighbour->object );
                if ( neighbour->context != NULL ) {
                        RDFSTORE_FREE( neighbour->context->value.resource.identifier );
                        RDFSTORE_FREE( neighbour->context );
                        };
                if ( neighbour->node != NULL ) {
                        RDFSTORE_FREE( neighbour->node->value.resource.identifier );
                        RDFSTORE_FREE( neighbour->node );
                        };
                RDFSTORE_FREE( neighbour );
		};
#endif

	/* OR subjects(PREDICATE) to s_connections(SUBJECT) */
        s_outsize = rdfstore_bits_or(outsize, me->bits_decode, s_outsize, s_connections, me->bits_encode); 
        bcopy(me->bits_encode, s_connections, s_outsize);   /* slow? */

	/* OR subjects(PREDICATE) to p_connections(PREDICATE) */
        p_outsize = rdfstore_bits_or(outsize, me->bits_decode, p_outsize, p_connections, me->bits_encode); 
        bcopy(me->bits_encode, p_connections, p_outsize);   /* slow? */

	/* OR subjects(PREDICATE) to o_connections(OBJECT) */
        o_outsize = rdfstore_bits_or(outsize, me->bits_decode, o_outsize, o_connections, me->bits_encode); 
        bcopy(me->bits_encode, o_connections, o_outsize);   /* slow? */

	/* fetch subjects(OBJECT) */
	packInt(statement->object->hashcode, outbuf);
	key.data = outbuf;
	key.size = sizeof(int);

	err = rdfstore_flat_store_fetch(me->subjects, key, &data);
	if (err != 0) {
		if (err != FLAT_STORE_E_NOTFOUND) {
			perror("rdfstore_insert");
			fprintf(stderr,"Could not fetch key '%s' for object in subjects table for store '%s': %s\n", (char *)key.data, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->subjects));
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
			rdfstore_iterator_close(reindex);
#endif
			return -1;
		} else {
			outsize = 0;
		};
	} else {
		me->func_decode(data.size, data.data, &outsize, me->bits_decode);
		RDFSTORE_FREE(data.data);
		};

#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
	/*
                We need to re-index quite a lot for each new statement component now - hope caching will
                help here!! i.e. the swiss army nife problem (see SWAD-E paper and preso)

                3.1) add this new statement (st_id) to p_connections(neighbour->predicate) and o_connections(neighbour->object)
                   tables of each other statement (neighbour) connected to this one via subjects(OBJECT) node
                3.2) add this new statement (st_id) to s_connections(neighbour->subject) and o_connections(neighbour->object)
                   tables of each other statement (neighbour) connected to this one via predicates(OBJECT) node
                3.3) add this new statement (st_id) to s_connections(neighbour->subject) and p_connections(neighbour->predicate)
                   tables of each other statement (neighbour) connected to this one via objects(OBJECT) node
        */

        /* 3.1) reindex st_id for connections to subjects(OBJECT) node */

	/* copy the subjects(OBJECT) bits through the reindex iterator array */
        memcpy(reindex->ids, me->bits_decode, outsize);
        reindex->ids_size = outsize;
        /* set the size - inefficient!! */
        pos = 0;
        reindex->size = 0;
        /* count the ones (inefficient still) */
        while ((pos = rdfstore_bits_getfirstsetafter(outsize, me->bits_decode, pos)) < 8 * outsize) {
                reindex->size++;
                pos++;
        	};

	/* scan the obtained iterator */
	while ( ( neighbour = rdfstore_iterator_each ( reindex ) ) != NULL ) {

#ifdef RDFSTORE_DEBUG_CONNECTIONS
		printf("(insert)REINDEXING predicate '%s' for connections to subjects('%s') node in st_id=%d\n",neighbour->predicate->value.resource.identifier,(statement->object->type==1) ? statement->object->value.literal.string : statement->object->value.resource.identifier,st_id);
#endif
		neighbour->predicate->hashcode = rdfstore_digest_get_node_hashCode(neighbour->predicate, 0);

		/* fetch p_connections(neighbour->predicate) */
		packInt(neighbour->predicate->hashcode, outbuf); /* wrong */
		key.data = outbuf;
		key.size = sizeof(int);

		err = rdfstore_flat_store_fetch(me->p_connections, key, &data);
		if (err != 0) {
			if (err != FLAT_STORE_E_NOTFOUND) {
				perror("rdfstore_insert");
				fprintf(stderr,"Could not fetch key '%s' for predicate in p_connections table for store '%s': %s\n", (char *)key.data, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->p_connections));
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
				rdfstore_iterator_close(reindex);
#endif
				return -1;
			} else {
				outsize_reindex = 0;
			};
		} else {
			me->func_decode_connections(data.size, data.data, &outsize_reindex, reindex_decode);
			RDFSTORE_FREE(data.data);
			};

		/* set the corresponding bit of this statement */
		rdfstore_bits_setmask(&outsize_reindex, reindex_decode, st_id, 1, 1, sizeof(reindex_decode));

		/* store it back */
		me->func_encode_connections(outsize_reindex, reindex_decode, &outsize_reindex, reindex_encode);

		data.data = reindex_encode;
		data.size = outsize_reindex;
		err = rdfstore_flat_store_store(me->p_connections, key, data);
		if (err != 0) {
			if (err != FLAT_STORE_E_KEYEXIST) {
				perror("rdfstore_insert");
				fprintf(stderr,"Could not store '%d' bytes for predicate in p_connections table for store '%s': %s\n", (int)data.size, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->p_connections));
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
				rdfstore_iterator_close(reindex);
#endif
				return -1;
				};
			};

#ifdef RDFSTORE_DEBUG_CONNECTIONS
		printf("(insert)REINDEXING object '%s' for connections to subjects('%s') node in st_id=%d\n",(neighbour->object->type==1) ? neighbour->object->value.literal.string : neighbour->object->value.resource.identifier,(statement->object->type==1) ? statement->object->value.literal.string : statement->object->value.resource.identifier,st_id);
#endif
		neighbour->object->hashcode = rdfstore_digest_get_node_hashCode(neighbour->object, 0);

		/* fetch o_connections(neighbour->object) */
		packInt(neighbour->object->hashcode, outbuf); /* wrong */
		key.data = outbuf;
		key.size = sizeof(int);

		err = rdfstore_flat_store_fetch(me->o_connections, key, &data);
		if (err != 0) {
			if (err != FLAT_STORE_E_NOTFOUND) {
				perror("rdfstore_insert");
				fprintf(stderr,"Could not fetch key '%s' for object in o_connections table for store '%s': %s\n", (char *)key.data, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->o_connections));
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
				rdfstore_iterator_close(reindex);
#endif
				return -1;
			} else {
				outsize_reindex = 0;
			};
		} else {
			me->func_decode_connections(data.size, data.data, &outsize_reindex, reindex_decode);
			RDFSTORE_FREE(data.data);
			};

		/* set the corresponding bit of this statement */
		rdfstore_bits_setmask(&outsize_reindex, reindex_decode, st_id, 1, 1, sizeof(reindex_decode));

		/* store it back */
		me->func_encode_connections(outsize_reindex, reindex_decode, &outsize_reindex, reindex_encode);

		data.data = reindex_encode;
		data.size = outsize_reindex;
		err = rdfstore_flat_store_store(me->o_connections, key, data);
		if (err != 0) {
			if (err != FLAT_STORE_E_KEYEXIST) {
				perror("rdfstore_insert");
				fprintf(stderr,"Could not store '%d' bytes for object in o_connections table for store '%s': %s\n", (int)data.size, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->o_connections));
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
				rdfstore_iterator_close(reindex);
#endif
				return -1;
				};
			};

		/* free neighbour */
                RDFSTORE_FREE( neighbour->subject->value.resource.identifier );
                RDFSTORE_FREE( neighbour->subject );
                RDFSTORE_FREE( neighbour->predicate->value.resource.identifier );
                RDFSTORE_FREE( neighbour->predicate );
                if ( neighbour->object->type == 1 ) {
                        if ( neighbour->object->value.literal.dataType != NULL )
                                RDFSTORE_FREE( neighbour->object->value.literal.dataType );
                        RDFSTORE_FREE( neighbour->object->value.literal.string );
                } else {
                        RDFSTORE_FREE( neighbour->object->value.resource.identifier );
                        };
                RDFSTORE_FREE( neighbour->object );
                if ( neighbour->context != NULL ) {
                        RDFSTORE_FREE( neighbour->context->value.resource.identifier );
                        RDFSTORE_FREE( neighbour->context );
                        };
                if ( neighbour->node != NULL ) {
                        RDFSTORE_FREE( neighbour->node->value.resource.identifier );
                        RDFSTORE_FREE( neighbour->node );
                        };
                RDFSTORE_FREE( neighbour );
		};
#endif

	/* OR subjects(OBJECT) to s_connections(SUBJECT) */
        s_outsize = rdfstore_bits_or(outsize, me->bits_decode, s_outsize, s_connections, me->bits_encode); 
        bcopy(me->bits_encode, s_connections, s_outsize);   /* slow? */

	/* OR subjects(OBJECT) to p_connections(PREDICATE) */
        p_outsize = rdfstore_bits_or(outsize, me->bits_decode, p_outsize, p_connections, me->bits_encode); 
        bcopy(me->bits_encode, p_connections, p_outsize);   /* slow? */

	/* OR subjects(OBJECT) to o_connections(OBJECT) */
        o_outsize = rdfstore_bits_or(outsize, me->bits_decode, o_outsize, o_connections, me->bits_encode); 
        bcopy(me->bits_encode, o_connections, o_outsize);   /* slow? */

	/* fetch predicates(SUBJECT) */
	packInt(statement->subject->hashcode, outbuf);
	key.data = outbuf;
	key.size = sizeof(int);

	err = rdfstore_flat_store_fetch(me->predicates, key, &data);
	if (err != 0) {
		if (err != FLAT_STORE_E_NOTFOUND) {
			perror("rdfstore_insert");
			fprintf(stderr,"Could not fetch key '%s' for subject in predicates table for store '%s': %s\n", (char *)key.data, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->predicates));
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
			rdfstore_iterator_close(reindex);
#endif
			return -1;
		} else {
			outsize = 0;
		};
	} else {
		me->func_decode(data.size, data.data, &outsize, me->bits_decode);
		RDFSTORE_FREE(data.data);
		};

#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
	/* 1.2) reindex st_id for connections to predicates(SUBJECT) node */

	/* copy the predicates(SUBJECT) bits through the reindex iterator array */
        memcpy(reindex->ids, me->bits_decode, outsize);
        reindex->ids_size = outsize;
        /* set the size - inefficient!! */
        pos = 0;
        reindex->size = 0;
        /* count the ones (inefficient still) */
        while ((pos = rdfstore_bits_getfirstsetafter(outsize, me->bits_decode, pos)) < 8 * outsize) {
                reindex->size++;
                pos++;
        	};

	/* scan the obtained iterator */
	while ( ( neighbour = rdfstore_iterator_each ( reindex ) ) != NULL ) {

#ifdef RDFSTORE_DEBUG_CONNECTIONS
		printf("(insert)REINDEXING subject '%s' for connections to predicates('%s') node in st_id=%d\n",neighbour->subject->value.resource.identifier,statement->subject->value.resource.identifier,st_id);
#endif
		neighbour->subject->hashcode = rdfstore_digest_get_node_hashCode(neighbour->subject, 0);

		/* fetch s_connections(neighbour->subject) */
		packInt(neighbour->subject->hashcode, outbuf); /* wrong */
		key.data = outbuf;
		key.size = sizeof(int);

		err = rdfstore_flat_store_fetch(me->s_connections, key, &data);
		if (err != 0) {
			if (err != FLAT_STORE_E_NOTFOUND) {
				perror("rdfstore_insert");
				fprintf(stderr,"Could not fetch key '%s' for subject in s_connections table for store '%s': %s\n", (char *)key.data, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->s_connections));
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
				rdfstore_iterator_close(reindex);
#endif
				return -1;
			} else {
				outsize_reindex = 0;
			};
		} else {
			me->func_decode_connections(data.size, data.data, &outsize_reindex, reindex_decode);
			RDFSTORE_FREE(data.data);
			};

		/* set the corresponding bit of this statement */
		rdfstore_bits_setmask(&outsize_reindex, reindex_decode, st_id, 1, 1, sizeof(reindex_decode));

		/* store it back */
		me->func_encode_connections(outsize_reindex, reindex_decode, &outsize_reindex, reindex_encode);

		data.data = reindex_encode;
		data.size = outsize_reindex;
		err = rdfstore_flat_store_store(me->s_connections, key, data);
		if (err != 0) {
			if (err != FLAT_STORE_E_KEYEXIST) {
				perror("rdfstore_insert");
				fprintf(stderr,"Could not store '%d' bytes for subject in s_connections table for store '%s': %s\n", (int)data.size, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->s_connections));
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
				rdfstore_iterator_close(reindex);
#endif
				return -1;
				};
			};

#ifdef RDFSTORE_DEBUG_CONNECTIONS
		printf("(insert)REINDEXING object '%s' for connections to predicates('%s') node in st_id=%d\n",(neighbour->object->type==1) ? neighbour->object->value.literal.string : neighbour->object->value.resource.identifier,statement->subject->value.resource.identifier,st_id);
#endif
		neighbour->object->hashcode = rdfstore_digest_get_node_hashCode(neighbour->object, 0);

		/* fetch o_connections(neighbour->object) */
		packInt(neighbour->object->hashcode, outbuf); /* wrong */
		key.data = outbuf;
		key.size = sizeof(int);

		err = rdfstore_flat_store_fetch(me->o_connections, key, &data);
		if (err != 0) {
			if (err != FLAT_STORE_E_NOTFOUND) {
				perror("rdfstore_insert");
				fprintf(stderr,"Could not fetch key '%s' for object in o_connections table for store '%s': %s\n", (char *)key.data, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->o_connections));
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
				rdfstore_iterator_close(reindex);
#endif
				return -1;
			} else {
				outsize_reindex = 0;
			};
		} else {
			me->func_decode_connections(data.size, data.data, &outsize_reindex, reindex_decode);
			RDFSTORE_FREE(data.data);
			};

		/* set the corresponding bit of this statement */
		rdfstore_bits_setmask(&outsize_reindex, reindex_decode, st_id, 1, 1, sizeof(reindex_decode));

		/* store it back */
		me->func_encode_connections(outsize_reindex, reindex_decode, &outsize_reindex, reindex_encode);

		data.data = reindex_encode;
		data.size = outsize_reindex;
		err = rdfstore_flat_store_store(me->o_connections, key, data);
		if (err != 0) {
			if (err != FLAT_STORE_E_KEYEXIST) {
				perror("rdfstore_insert");
				fprintf(stderr,"Could not store '%d' bytes for object in o_connections table for store '%s': %s\n", (int)data.size, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->o_connections));
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
				rdfstore_iterator_close(reindex);
#endif
				return -1;
				};
			};

		/* free neighbour */
                RDFSTORE_FREE( neighbour->subject->value.resource.identifier );
                RDFSTORE_FREE( neighbour->subject );
                RDFSTORE_FREE( neighbour->predicate->value.resource.identifier );
                RDFSTORE_FREE( neighbour->predicate );
                if ( neighbour->object->type == 1 ) {
                        if ( neighbour->object->value.literal.dataType != NULL )
                                RDFSTORE_FREE( neighbour->object->value.literal.dataType );
                        RDFSTORE_FREE( neighbour->object->value.literal.string );
                } else {
                        RDFSTORE_FREE( neighbour->object->value.resource.identifier );
                        };
                RDFSTORE_FREE( neighbour->object );
                if ( neighbour->context != NULL ) {
                        RDFSTORE_FREE( neighbour->context->value.resource.identifier );
                        RDFSTORE_FREE( neighbour->context );
                        };
                if ( neighbour->node != NULL ) {
                        RDFSTORE_FREE( neighbour->node->value.resource.identifier );
                        RDFSTORE_FREE( neighbour->node );
                        };
                RDFSTORE_FREE( neighbour );
		};
#endif

	/* OR predicates(SUBJECT) to s_connections(SUBJECT) */
        s_outsize = rdfstore_bits_or(outsize, me->bits_decode, s_outsize, s_connections, me->bits_encode); 
        bcopy(me->bits_encode, s_connections, s_outsize);   /* slow? */

	/* OR predicates(SUBJECT) to p_connections(PREDICATE) */
        p_outsize = rdfstore_bits_or(outsize, me->bits_decode, p_outsize, p_connections, me->bits_encode); 
        bcopy(me->bits_encode, p_connections, p_outsize);   /* slow? */

	/* OR predicates(SUBJECT) to o_connections(OBJECT) */
        o_outsize = rdfstore_bits_or(outsize, me->bits_decode, o_outsize, o_connections, me->bits_encode); 
        bcopy(me->bits_encode, o_connections, o_outsize);   /* slow? */

	/* fetch predicates(OBJECT) */
	packInt(statement->object->hashcode, outbuf);
	key.data = outbuf;
	key.size = sizeof(int);

	err = rdfstore_flat_store_fetch(me->predicates, key, &data);
	if (err != 0) {
		if (err != FLAT_STORE_E_NOTFOUND) {
			perror("rdfstore_insert");
			fprintf(stderr,"Could not fetch key '%s' for object in predicates table for store '%s': %s\n", (char *)key.data, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->predicates));
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
			rdfstore_iterator_close(reindex);
#endif
			return -1;
		} else {
			outsize = 0;
		};
	} else {
		me->func_decode(data.size, data.data, &outsize, me->bits_decode);
		RDFSTORE_FREE(data.data);
		};

#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
        /* 3.2) reindex st_id for connections to predicates(OBJECT) node */

	/* copy the predicates(OBJECT) bits through the reindex iterator array */
        memcpy(reindex->ids, me->bits_decode, outsize);
        reindex->ids_size = outsize;
        /* set the size - inefficient!! */
        pos = 0;
        reindex->size = 0;
        /* count the ones (inefficient still) */
        while ((pos = rdfstore_bits_getfirstsetafter(outsize, me->bits_decode, pos)) < 8 * outsize) {
                reindex->size++;
                pos++;
        	};

	/* scan the obtained iterator */
	while ( ( neighbour = rdfstore_iterator_each ( reindex ) ) != NULL ) {

#ifdef RDFSTORE_DEBUG_CONNECTIONS
		printf("(insert)REINDEXING subject '%s' for connections to predicates('%s') node in st_id=%d\n",neighbour->subject->value.resource.identifier,(statement->object->type==1) ? statement->object->value.literal.string : statement->object->value.resource.identifier,st_id);
#endif
		neighbour->subject->hashcode = rdfstore_digest_get_node_hashCode(neighbour->subject, 0);

		/* fetch s_connections(neighbour->subject) */
		packInt(neighbour->subject->hashcode, outbuf); /* wrong */
		key.data = outbuf;
		key.size = sizeof(int);

		err = rdfstore_flat_store_fetch(me->s_connections, key, &data);
		if (err != 0) {
			if (err != FLAT_STORE_E_NOTFOUND) {
				perror("rdfstore_insert");
				fprintf(stderr,"Could not fetch key '%s' for subject in s_connections table for store '%s': %s\n", (char *)key.data, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->s_connections));
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
				rdfstore_iterator_close(reindex);
#endif
				return -1;
			} else {
				outsize_reindex = 0;
			};
		} else {
			me->func_decode_connections(data.size, data.data, &outsize_reindex, reindex_decode);
			RDFSTORE_FREE(data.data);
			};

		/* set the corresponding bit of this statement */
		rdfstore_bits_setmask(&outsize_reindex, reindex_decode, st_id, 1, 1, sizeof(reindex_decode));

		/* store it back */
		me->func_encode_connections(outsize_reindex, reindex_decode, &outsize_reindex, reindex_encode);

		data.data = reindex_encode;
		data.size = outsize_reindex;
		err = rdfstore_flat_store_store(me->s_connections, key, data);
		if (err != 0) {
			if (err != FLAT_STORE_E_KEYEXIST) {
				perror("rdfstore_insert");
				fprintf(stderr,"Could not store '%d' bytes for subject in s_connections table for store '%s': %s\n", (int)data.size, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->s_connections));
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
				rdfstore_iterator_close(reindex);
#endif
				return -1;
				};
			};

#ifdef RDFSTORE_DEBUG_CONNECTIONS
		printf("(insert)REINDEXING object '%s' for connections to predicates('%s') node in st_id=%d\n",(neighbour->object->type==1) ? neighbour->object->value.literal.string : neighbour->object->value.resource.identifier,(statement->object->type==1) ? statement->object->value.literal.string : statement->object->value.resource.identifier,st_id);
#endif
		neighbour->object->hashcode = rdfstore_digest_get_node_hashCode(neighbour->object, 0);

		/* fetch o_connections(neighbour->object) */
		packInt(neighbour->object->hashcode, outbuf); /* wrong */
		key.data = outbuf;
		key.size = sizeof(int);

		err = rdfstore_flat_store_fetch(me->o_connections, key, &data);
		if (err != 0) {
			if (err != FLAT_STORE_E_NOTFOUND) {
				perror("rdfstore_insert");
				fprintf(stderr,"Could not fetch key '%s' for object in o_connections table for store '%s': %s\n", (char *)key.data, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->o_connections));
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
				rdfstore_iterator_close(reindex);
#endif
				return -1;
			} else {
				outsize_reindex = 0;
			};
		} else {
			me->func_decode_connections(data.size, data.data, &outsize_reindex, reindex_decode);
			RDFSTORE_FREE(data.data);
			};

		/* set the corresponding bit of this statement */
		rdfstore_bits_setmask(&outsize_reindex, reindex_decode, st_id, 1, 1, sizeof(reindex_decode));

		/* store it back */
		me->func_encode_connections(outsize_reindex, reindex_decode, &outsize_reindex, reindex_encode);

		data.data = reindex_encode;
		data.size = outsize_reindex;
		err = rdfstore_flat_store_store(me->o_connections, key, data);
		if (err != 0) {
			if (err != FLAT_STORE_E_KEYEXIST) {
				perror("rdfstore_insert");
				fprintf(stderr,"Could not store '%d' bytes for object in o_connections table for store '%s': %s\n", (int)data.size, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->o_connections));
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
				rdfstore_iterator_close(reindex);
#endif
				return -1;
				};
			};

		/* free neighbour */
                RDFSTORE_FREE( neighbour->subject->value.resource.identifier );
                RDFSTORE_FREE( neighbour->subject );
                RDFSTORE_FREE( neighbour->predicate->value.resource.identifier );
                RDFSTORE_FREE( neighbour->predicate );
                if ( neighbour->object->type == 1 ) {
                        if ( neighbour->object->value.literal.dataType != NULL )
                                RDFSTORE_FREE( neighbour->object->value.literal.dataType );
                        RDFSTORE_FREE( neighbour->object->value.literal.string );
                } else {
                        RDFSTORE_FREE( neighbour->object->value.resource.identifier );
                        };
                RDFSTORE_FREE( neighbour->object );
                if ( neighbour->context != NULL ) {
                        RDFSTORE_FREE( neighbour->context->value.resource.identifier );
                        RDFSTORE_FREE( neighbour->context );
                        };
                if ( neighbour->node != NULL ) {
                        RDFSTORE_FREE( neighbour->node->value.resource.identifier );
                        RDFSTORE_FREE( neighbour->node );
                        };
                RDFSTORE_FREE( neighbour );
		};
#endif

	/* OR predicates(OBJECT) to s_connections(SUBJECT) */
        s_outsize = rdfstore_bits_or(outsize, me->bits_decode, s_outsize, s_connections, me->bits_encode); 
        bcopy(me->bits_encode, s_connections, s_outsize);   /* slow? */

	/* OR predicates(OBJECT) to p_connections(PREDICATE) */
        p_outsize = rdfstore_bits_or(outsize, me->bits_decode, p_outsize, p_connections, me->bits_encode); 
        bcopy(me->bits_encode, p_connections, p_outsize);   /* slow? */

	/* OR predicates(OBJECT) to o_connections(OBJECT) */
        o_outsize = rdfstore_bits_or(outsize, me->bits_decode, o_outsize, o_connections, me->bits_encode); 
        bcopy(me->bits_encode, o_connections, o_outsize);   /* slow? */

	/* fetch objects(SUBJECT) */
	packInt(statement->subject->hashcode, outbuf);
	key.data = outbuf;
	key.size = sizeof(int);

	err = rdfstore_flat_store_fetch(me->objects, key, &data);
	if (err != 0) {
		if (err != FLAT_STORE_E_NOTFOUND) {
			perror("rdfstore_insert");
			fprintf(stderr,"Could not fetch key '%s' for subject in objects table for store '%s': %s\n", (char *)key.data, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->objects));
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
			rdfstore_iterator_close(reindex);
#endif
			return -1;
		} else {
			outsize = 0;
		};
	} else {
		me->func_decode(data.size, data.data, &outsize, me->bits_decode);
		RDFSTORE_FREE(data.data);
		};

#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
	/* 1.3) reindex st_id for connections to objects(SUBJECT) node */

	/* copy the objects(SUBJECT) bits through the reindex iterator array */
        memcpy(reindex->ids, me->bits_decode, outsize);
        reindex->ids_size = outsize;
        /* set the size - inefficient!! */
        pos = 0;
        reindex->size = 0;
        /* count the ones (inefficient still) */
        while ((pos = rdfstore_bits_getfirstsetafter(outsize, me->bits_decode, pos)) < 8 * outsize) {
                reindex->size++;
                pos++;
        	};

	/* scan the obtained iterator */
	while ( ( neighbour = rdfstore_iterator_each ( reindex ) ) != NULL ) {

#ifdef RDFSTORE_DEBUG_CONNECTIONS
		printf("(insert)REINDEXING subject '%s' for connections to objects('%s') node in st_id=%d\n",neighbour->subject->value.resource.identifier,statement->subject->value.resource.identifier,st_id);
#endif
		neighbour->subject->hashcode = rdfstore_digest_get_node_hashCode(neighbour->subject, 0);

		/* fetch s_connections(neighbour->subject) */
		packInt(neighbour->subject->hashcode, outbuf); /* wrong */
		key.data = outbuf;
		key.size = sizeof(int);

		err = rdfstore_flat_store_fetch(me->s_connections, key, &data);
		if (err != 0) {
			if (err != FLAT_STORE_E_NOTFOUND) {
				perror("rdfstore_insert");
				fprintf(stderr,"Could not fetch key '%s' for subject in s_connections table for store '%s': %s\n", (char *)key.data, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->s_connections));
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
				rdfstore_iterator_close(reindex);
#endif
				return -1;
			} else {
				outsize_reindex = 0;
			};
		} else {
			me->func_decode_connections(data.size, data.data, &outsize_reindex, reindex_decode);
			RDFSTORE_FREE(data.data);
			};

		/* set the corresponding bit of this statement */
		rdfstore_bits_setmask(&outsize_reindex, reindex_decode, st_id, 1, 1, sizeof(reindex_decode));

		/* store it back */
		me->func_encode_connections(outsize_reindex, reindex_decode, &outsize_reindex, reindex_encode);

		data.data = reindex_encode;
		data.size = outsize_reindex;
		err = rdfstore_flat_store_store(me->s_connections, key, data);
		if (err != 0) {
			if (err != FLAT_STORE_E_KEYEXIST) {
				perror("rdfstore_insert");
				fprintf(stderr,"Could not store '%d' bytes for subject in s_connections table for store '%s': %s\n", (int)data.size, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->s_connections));
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
				rdfstore_iterator_close(reindex);
#endif
				return -1;
				};
			};

#ifdef RDFSTORE_DEBUG_CONNECTIONS
		printf("(insert)REINDEXING predicate '%s' for connections to objects('%s') node in st_id=%d\n",neighbour->predicate->value.resource.identifier,statement->subject->value.resource.identifier,st_id);
#endif
		neighbour->predicate->hashcode = rdfstore_digest_get_node_hashCode(neighbour->predicate, 0);

		/* fetch p_connections(neighbour->predicate) */
		packInt(neighbour->predicate->hashcode, outbuf); /* wrong */
		key.data = outbuf;
		key.size = sizeof(int);

		err = rdfstore_flat_store_fetch(me->p_connections, key, &data);
		if (err != 0) {
			if (err != FLAT_STORE_E_NOTFOUND) {
				perror("rdfstore_insert");
				fprintf(stderr,"Could not fetch key '%s' for predicate in p_connections table for store '%s': %s\n", (char *)key.data, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->p_connections));
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
				rdfstore_iterator_close(reindex);
#endif
				return -1;
			} else {
				outsize_reindex = 0;
			};
		} else {
			me->func_decode_connections(data.size, data.data, &outsize_reindex, reindex_decode);
			RDFSTORE_FREE(data.data);
			};

		/* set the corresponding bit of this statement */
		rdfstore_bits_setmask(&outsize_reindex, reindex_decode, st_id, 1, 1, sizeof(reindex_decode));

		/* store it back */
		me->func_encode_connections(outsize_reindex, reindex_decode, &outsize_reindex, reindex_encode);

		data.data = reindex_encode;
		data.size = outsize_reindex;
		err = rdfstore_flat_store_store(me->p_connections, key, data);
		if (err != 0) {
			if (err != FLAT_STORE_E_KEYEXIST) {
				perror("rdfstore_insert");
				fprintf(stderr,"Could not store '%d' bytes for predicate in p_connections table for store '%s': %s\n", (int)data.size, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->p_connections));
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
				rdfstore_iterator_close(reindex);
#endif
				return -1;
				};
			};

		/* free neighbour */
                RDFSTORE_FREE( neighbour->subject->value.resource.identifier );
                RDFSTORE_FREE( neighbour->subject );
                RDFSTORE_FREE( neighbour->predicate->value.resource.identifier );
                RDFSTORE_FREE( neighbour->predicate );
                if ( neighbour->object->type == 1 ) {
                        if ( neighbour->object->value.literal.dataType != NULL )
                                RDFSTORE_FREE( neighbour->object->value.literal.dataType );
                        RDFSTORE_FREE( neighbour->object->value.literal.string );
                } else {
                        RDFSTORE_FREE( neighbour->object->value.resource.identifier );
                        };
                RDFSTORE_FREE( neighbour->object );
                if ( neighbour->context != NULL ) {
                        RDFSTORE_FREE( neighbour->context->value.resource.identifier );
                        RDFSTORE_FREE( neighbour->context );
                        };
                if ( neighbour->node != NULL ) {
                        RDFSTORE_FREE( neighbour->node->value.resource.identifier );
                        RDFSTORE_FREE( neighbour->node );
                        };
                RDFSTORE_FREE( neighbour );
		};
#endif

	/* OR objects(SUBJECT) to s_connections(SUBJECT) */
        s_outsize = rdfstore_bits_or(outsize, me->bits_decode, s_outsize, s_connections, me->bits_encode); 
        bcopy(me->bits_encode, s_connections, s_outsize);   /* slow? */

	/* OR objects(SUBJECT) to p_connections(PREDICATE) */
        p_outsize = rdfstore_bits_or(outsize, me->bits_decode, p_outsize, p_connections, me->bits_encode); 
        bcopy(me->bits_encode, p_connections, p_outsize);   /* slow? */

	/* OR objects(SUBJECT) to o_connections(OBJECT) */
        o_outsize = rdfstore_bits_or(outsize, me->bits_decode, o_outsize, o_connections, me->bits_encode); 
        bcopy(me->bits_encode, o_connections, o_outsize);   /* slow? */

	/* fetch objects(PREDICATE) */
	packInt(statement->predicate->hashcode, outbuf);
	key.data = outbuf;
	key.size = sizeof(int);

	err = rdfstore_flat_store_fetch(me->objects, key, &data);
	if (err != 0) {
		if (err != FLAT_STORE_E_NOTFOUND) {
			perror("rdfstore_insert");
			fprintf(stderr,"Could not fetch key '%s' for predicate in objects table for store '%s': %s\n", (char *)key.data, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->objects));
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
			rdfstore_iterator_close(reindex);
#endif
			return -1;
		} else {
			outsize = 0;
		};
	} else {
		me->func_decode(data.size, data.data, &outsize, me->bits_decode);
		RDFSTORE_FREE(data.data);
		};

#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
        /* 2.3) reindex st_id for connections to objects(PREDICATE) node */

	/* copy the objects(PREDICATE) bits through the reindex iterator array */
        memcpy(reindex->ids, me->bits_decode, outsize);
        reindex->ids_size = outsize;
        /* set the size - inefficient!! */
        pos = 0;
        reindex->size = 0;
        /* count the ones (inefficient still) */
        while ((pos = rdfstore_bits_getfirstsetafter(outsize, me->bits_decode, pos)) < 8 * outsize) {
                reindex->size++;
                pos++;
        	};

	/* scan the obtained iterator */
	while ( ( neighbour = rdfstore_iterator_each ( reindex ) ) != NULL ) {

#ifdef RDFSTORE_DEBUG_CONNECTIONS
		printf("(insert)REINDEXING subject '%s' for connections to objects('%s') node in st_id=%d\n",neighbour->subject->value.resource.identifier,statement->predicate->value.resource.identifier,st_id);
#endif
		neighbour->subject->hashcode = rdfstore_digest_get_node_hashCode(neighbour->subject, 0);

		/* fetch s_connections(neighbour->subject) */
		packInt(neighbour->subject->hashcode, outbuf); /* wrong */
		key.data = outbuf;
		key.size = sizeof(int);

		err = rdfstore_flat_store_fetch(me->s_connections, key, &data);
		if (err != 0) {
			if (err != FLAT_STORE_E_NOTFOUND) {
				perror("rdfstore_insert");
				fprintf(stderr,"Could not fetch key '%s' for subject in s_connections table for store '%s': %s\n", (char *)key.data, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->s_connections));
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
				rdfstore_iterator_close(reindex);
#endif
				return -1;
			} else {
				outsize_reindex = 0;
			};
		} else {
			me->func_decode_connections(data.size, data.data, &outsize_reindex, reindex_decode);
			RDFSTORE_FREE(data.data);
			};

		/* set the corresponding bit of this statement */
		rdfstore_bits_setmask(&outsize_reindex, reindex_decode, st_id, 1, 1, sizeof(reindex_decode));

		/* store it back */
		me->func_encode_connections(outsize_reindex, reindex_decode, &outsize_reindex, reindex_encode);

		data.data = reindex_encode;
		data.size = outsize_reindex;
		err = rdfstore_flat_store_store(me->s_connections, key, data);
		if (err != 0) {
			if (err != FLAT_STORE_E_KEYEXIST) {
				perror("rdfstore_insert");
				fprintf(stderr,"Could not store '%d' bytes for subject in s_connections table for store '%s': %s\n", (int)data.size, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->s_connections));
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
				rdfstore_iterator_close(reindex);
#endif
				return -1;
				};
			};

#ifdef RDFSTORE_DEBUG_CONNECTIONS
		printf("(insert)REINDEXING predicate '%s' for connections to objects('%s') node in st_id=%d\n",neighbour->predicate->value.resource.identifier,statement->predicate->value.resource.identifier,st_id);
#endif
		neighbour->predicate->hashcode = rdfstore_digest_get_node_hashCode(neighbour->predicate, 0);

		/* fetch p_connections(neighbour->predicate) */
		packInt(neighbour->predicate->hashcode, outbuf); /* wrong */
		key.data = outbuf;
		key.size = sizeof(int);

		err = rdfstore_flat_store_fetch(me->p_connections, key, &data);
		if (err != 0) {
			if (err != FLAT_STORE_E_NOTFOUND) {
				perror("rdfstore_insert");
				fprintf(stderr,"Could not fetch key '%s' for predicate in p_connections table for store '%s': %s\n", (char *)key.data, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->p_connections));
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
				rdfstore_iterator_close(reindex);
#endif
				return -1;
			} else {
				outsize_reindex = 0;
			};
		} else {
			me->func_decode_connections(data.size, data.data, &outsize_reindex, reindex_decode);
			RDFSTORE_FREE(data.data);
			};

		/* set the corresponding bit of this statement */
		rdfstore_bits_setmask(&outsize_reindex, reindex_decode, st_id, 1, 1, sizeof(reindex_decode));

		/* store it back */
		me->func_encode_connections(outsize_reindex, reindex_decode, &outsize_reindex, reindex_encode);

		data.data = reindex_encode;
		data.size = outsize_reindex;
		err = rdfstore_flat_store_store(me->p_connections, key, data);
		if (err != 0) {
			if (err != FLAT_STORE_E_KEYEXIST) {
				perror("rdfstore_insert");
				fprintf(stderr,"Could not store '%d' bytes for predicate in p_connections table for store '%s': %s\n", (int)data.size, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->p_connections));
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
				rdfstore_iterator_close(reindex);
#endif
				return -1;
				};
			};

		/* free neighbour */
                RDFSTORE_FREE( neighbour->subject->value.resource.identifier );
                RDFSTORE_FREE( neighbour->subject );
                RDFSTORE_FREE( neighbour->predicate->value.resource.identifier );
                RDFSTORE_FREE( neighbour->predicate );
                if ( neighbour->object->type == 1 ) {
                        if ( neighbour->object->value.literal.dataType != NULL )
                                RDFSTORE_FREE( neighbour->object->value.literal.dataType );
                        RDFSTORE_FREE( neighbour->object->value.literal.string );
                } else {
                        RDFSTORE_FREE( neighbour->object->value.resource.identifier );
                        };
                RDFSTORE_FREE( neighbour->object );
                if ( neighbour->context != NULL ) {
                        RDFSTORE_FREE( neighbour->context->value.resource.identifier );
                        RDFSTORE_FREE( neighbour->context );
                        };
                if ( neighbour->node != NULL ) {
                        RDFSTORE_FREE( neighbour->node->value.resource.identifier );
                        RDFSTORE_FREE( neighbour->node );
                        };
                RDFSTORE_FREE( neighbour );
		};
#endif

	/* OR objects(PREDICATE) to s_connections(SUBJECT) */
        s_outsize = rdfstore_bits_or(outsize, me->bits_decode, s_outsize, s_connections, me->bits_encode); 
        bcopy(me->bits_encode, s_connections, s_outsize);   /* slow? */

	/* OR objects(PREDICATE) to p_connections(PREDICATE) */
        p_outsize = rdfstore_bits_or(outsize, me->bits_decode, p_outsize, p_connections, me->bits_encode); 
        bcopy(me->bits_encode, p_connections, p_outsize);   /* slow? */

	/* OR objects(PREDICATE) to o_connections(OBJECT) */
        o_outsize = rdfstore_bits_or(outsize, me->bits_decode, o_outsize, o_connections, me->bits_encode); 
        bcopy(me->bits_encode, o_connections, o_outsize);   /* slow? */

	/* SUBJECT - we need to OR s_connections(SUBJECT) with generated s_connections and store */

	/* fetch s_connections(SUBJECT) */
	packInt(statement->subject->hashcode, outbuf);
	key.data = outbuf;
	key.size = sizeof(int);

	err = rdfstore_flat_store_fetch(me->s_connections, key, &data);
	if (err != 0) {
		if (err != FLAT_STORE_E_NOTFOUND) {
			perror("rdfstore_insert");
			fprintf(stderr,"Could not fetch key '%s' for subject in s_connections table for store '%s': %s\n", (char *)key.data, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->s_connections));
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
			rdfstore_iterator_close(reindex);
#endif
			return -1;
		} else {
			outsize = 0;
		};
	} else {
		me->func_decode_connections(data.size, data.data, &outsize, me->bits_decode);
		RDFSTORE_FREE(data.data);
		};

	/* OR s_connections(SUBJECT) to generated s_connections */
        s_outsize = rdfstore_bits_or(outsize, me->bits_decode, s_outsize, s_connections, me->bits_encode); 
        bcopy(me->bits_encode, s_connections, s_outsize);   /* slow? */

	me->func_encode_connections(s_outsize, s_connections, &outsize, me->bits_encode);
	if (outsize) {
		data.data = me->bits_encode;
		data.size = outsize;
		err = rdfstore_flat_store_store(me->s_connections, key, data);
		if (err == 0) {
#ifdef RDFSTORE_DEBUG_COMPRESSION
			fprintf(stderr,"Stored %d bytes for '%s' in s_connections table for store '%s'\n", outsize, (char *)key.data, (me->name != NULL) ? me->name : "(in-memory)");
#endif
		} else {
			if (err != FLAT_STORE_E_KEYEXIST) {
				perror("rdfstore_insert");
				fprintf(stderr,"Could not store '%d' bytes for subject in s_connections table for store '%s': %s\n", (int)data.size, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->s_connections));
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
				rdfstore_iterator_close(reindex);
#endif
				return -1;
			};
		};

#ifdef RDFSTORE_DEBUG
		{
			int             i=0;
			if ((rdfstore_flat_store_fetch(me->s_connections, key, &data)) == 0) {
				me->func_decode_connections(data.size, data.data, &outsize, me->bits_decode);
				RDFSTORE_FREE(data.data);
			};
			printf("ADDED st_num=%d bitno=%d s_connections for subject '%s' -->'", st_id, st_id, statement->subject->value.resource.identifier);
			for(i=0;i<8*outsize;i++) {
				printf("Rec %d %c\n", i, (me->bits_decode[i>>3] & (1<<(i&7))) ? '1':'0');
                                };
			printf("'\n");
		}
#endif

	};

	/* PREDICATE - we need to OR p_connections(PREDICATE) with generated p_connections and store */

	/* fetch p_connections(PREDICATE) */
	packInt(statement->predicate->hashcode, outbuf);
	key.data = outbuf;
	key.size = sizeof(int);

	err = rdfstore_flat_store_fetch(me->p_connections, key, &data);
	if (err != 0) {
		if (err != FLAT_STORE_E_NOTFOUND) {
			perror("rdfstore_insert");
			fprintf(stderr,"Could not fetch key '%s' for predicate in p_connections table for store '%s': %s\n", (char *)key.data, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->p_connections));
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
			rdfstore_iterator_close(reindex);
#endif
			return -1;
		} else {
			outsize = 0;
		};
	} else {
		me->func_decode_connections(data.size, data.data, &outsize, me->bits_decode);
		RDFSTORE_FREE(data.data);
		};

	/* OR p_connections(PREDICATE) to generated p_connections */
        p_outsize = rdfstore_bits_or(outsize, me->bits_decode, p_outsize, p_connections, me->bits_encode); 
        bcopy(me->bits_encode, p_connections, p_outsize);   /* slow? */

	me->func_encode_connections(p_outsize, p_connections, &outsize, me->bits_encode);
	if (outsize) {
		data.data = me->bits_encode;
		data.size = outsize;
		err = rdfstore_flat_store_store(me->p_connections, key, data);
		if (err == 0) {
#ifdef RDFSTORE_DEBUG_COMPRESSION
			fprintf(stderr,"Stored %d bytes for '%s' in p_connections table for store '%s'\n", outsize, (char *)key.data, (me->name != NULL) ? me->name : "(in-memory)");
#endif
		} else {
			if (err != FLAT_STORE_E_KEYEXIST) {
				perror("rdfstore_insert");
				fprintf(stderr,"Could not store '%d' bytes for predicate in p_connections table for store '%s': %s\n", (int)data.size, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->p_connections));
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
				rdfstore_iterator_close(reindex);
#endif
				return -1;
			};
		};

#ifdef RDFSTORE_DEBUG
		{
			int             i=0;
			if ((rdfstore_flat_store_fetch(me->p_connections, key, &data)) == 0) {
				me->func_decode_connections(data.size, data.data, &outsize, me->bits_decode);
				RDFSTORE_FREE(data.data);
			};
			printf("ADDED st_num=%d bitno=%d p_connections for predicate '%s' -->'", st_id, st_id, statement->predicate->value.resource.identifier);
			for(i=0;i<8*outsize;i++) {
				printf("Rec %d %c\n", i, (me->bits_decode[i>>3] & (1<<(i&7))) ? '1':'0');
                                };
			printf("'\n");
		}
#endif

	};

	/* OBJECT - we need to OR o_connections(OBJECT) with generated o_connections and store */

	/* fetch o_connections(OBJECT) */
	packInt(statement->object->hashcode, outbuf);
	key.data = outbuf;
	key.size = sizeof(int);

	err = rdfstore_flat_store_fetch(me->o_connections, key, &data);
	if (err != 0) {
		if (err != FLAT_STORE_E_NOTFOUND) {
			perror("rdfstore_insert");
			fprintf(stderr,"Could not fetch key '%s' for object in o_connections table for store '%s': %s\n", (char *)key.data, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->o_connections));
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
			rdfstore_iterator_close(reindex);
#endif
			return -1;
		} else {
			outsize = 0;
		};
	} else {
		me->func_decode_connections(data.size, data.data, &outsize, me->bits_decode);
		RDFSTORE_FREE(data.data);
		};

	/* OR o_connections(OBJECT) to generated o_connections */
        o_outsize = rdfstore_bits_or(outsize, me->bits_decode, o_outsize, o_connections, me->bits_encode); 
        bcopy(me->bits_encode, o_connections, o_outsize);   /* slow? */

	me->func_encode_connections(o_outsize, o_connections, &outsize, me->bits_encode);
	if (outsize) {
		data.data = me->bits_encode;
		data.size = outsize;
		err = rdfstore_flat_store_store(me->o_connections, key, data);
		if (err == 0) {
#ifdef RDFSTORE_DEBUG_COMPRESSION
			fprintf(stderr,"Stored %d bytes for '%s' in o_connections table for store '%s'\n", outsize, (char *)key.data, (me->name != NULL) ? me->name : "(in-memory)");
#endif
		} else {
			if (err != FLAT_STORE_E_KEYEXIST) {
				perror("rdfstore_insert");
				fprintf(stderr,"Could not store '%d' bytes for object in o_connections table for store '%s': %s\n", (int)data.size, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->o_connections));
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
				rdfstore_iterator_close(reindex);
#endif
				return -1;
			};
		};

#ifdef RDFSTORE_DEBUG
		{
			int             i=0;
			if ((rdfstore_flat_store_fetch(me->o_connections, key, &data)) == 0) {
				me->func_decode_connections(data.size, data.data, &outsize, me->bits_decode);
				RDFSTORE_FREE(data.data);
			};
			printf("ADDED st_num=%d bitno=%d o_connections for object '%s' -->'", st_id, st_id, (statement->object->type != 1) ? statement->object->value.resource.identifier : statement->object->value.literal.string );
			for(i=0;i<8*outsize;i++) {
				printf("Rec %d %c\n", i, (me->bits_decode[i>>3] & (1<<(i&7))) ? '1':'0');
                                };
			printf("'\n");
		}
#endif

	};

#endif /* RDFSTORE_CONNECTIONS */

	/* contexts table */

	if (context != NULL) {
		/* context */
		packInt(context->hashcode, outbuf);
		key.data = outbuf;
		key.size = sizeof(int);

		/*
		 * bzero(me->bits_encode,sizeof(me->bits_encode));
		 * bzero(me->bits_decode,sizeof(me->bits_decode));
		 */

		err = rdfstore_flat_store_fetch(me->contexts, key, &data);
		if (err != 0) {
			if (err != FLAT_STORE_E_NOTFOUND) {
				perror("rdfstore_insert");
				fprintf(stderr,"Could not fetch key '%s' in contexts table for store '%s': %s\n", (char *)key.data, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->contexts));
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
				rdfstore_iterator_close(reindex);
#endif
				return -1;
			} else {
				outsize = 0;
			};
		} else {
			me->func_decode(data.size, data.data, &outsize, me->bits_decode);	/* perhaps the
													 * compression for
													 * single bits could be
													 * different */
			RDFSTORE_FREE(data.data);
		};
		rdfstore_bits_setmask(&outsize, me->bits_decode, st_id, 1, 1, sizeof(me->bits_decode));

		me->func_encode(outsize, me->bits_decode, &outsize, me->bits_encode);
		if (outsize) {
			data.data = me->bits_encode;
			data.size = outsize;
			err = rdfstore_flat_store_store(me->contexts, key, data);
			if (err == 0) {
#ifdef RDFSTORE_DEBUG_COMPRESSION
				fprintf(stderr,"Stored %d bytes for '%s' in contexts table for store '%s'\n", outsize, (char *)key.data, (me->name != NULL) ? me->name : "(in-memory)");
#endif
			} else {
				if (err != FLAT_STORE_E_KEYEXIST) {
					perror("rdfstore_insert");
					fprintf(stderr,"Could not store '%d' bytes in contexts table for store '%s': %s\n", (int)data.size, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->contexts));
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
					rdfstore_iterator_close(reindex);
#endif
					return -1;
				};
			};

#ifdef RDFSTORE_DEBUG
			{
				int             i;
				if ((rdfstore_flat_store_fetch(me->contexts, key, &data)) == 0) {
					me->func_decode(data.size, data.data, &outsize, me->bits_decode);
					RDFSTORE_FREE(data.data);
				};
				printf("ADDED st_num=%d bitno=%d contexts for C '%s' -->'", st_id, st_id, context->value.resource.identifier);
				for(i=0;i<8*outsize;i++) {
					printf("Rec %d %c\n", i, (me->bits_decode[i>>3] & (1<<(i&7))) ? '1':'0');
                                        };
				printf("'\n");
			}
#endif
		};
	};

	/* store the statement internal identifier */
	packInt(hc, outbuf);
	key.data = outbuf;
	key.size = sizeof(int);

	packInt(st_id, outbuf1);
	data.data = outbuf1;
	data.size = sizeof(int);

	err = rdfstore_flat_store_store(me->statements, key, data);
	if (err != 0) {
		perror("rdfstore_insert");
		fprintf(stderr,"Could not store statement internal identifier in statements for store '%s': %s\n", (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->statements));
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
		rdfstore_iterator_close(reindex);
#endif
		return -1;
	} else {
		/* touch DB last modified date */
        	bzero(&thedateval_tm, sizeof( struct tm ) );

        	time(&now);

        	ptm = gmtime(&now);
        	memcpy(&thedateval_tm, ptm, sizeof(struct tm));

        	rdfstore_xsd_serialize_dateTime( thedateval_tm, thedateval );

        	key.data = RDFSTORE_LASTMODIFIED_KEY;
        	key.size = sizeof(RDFSTORE_LASTMODIFIED_KEY);

		data.data = thedateval;
		data.size = strlen(thedateval) + 1;

		err = rdfstore_flat_store_store(me->model, key, data);
		if (	(err != 0) &&
			(err != FLAT_STORE_E_KEYEXIST) ) {
			perror("rdfstore_insert");
			fprintf(stderr,"Could not store last modified date in model for store '%s': %s\n", (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->model));
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
			rdfstore_iterator_close(reindex);
#endif
			return -1;
			};
		};

	if ((me->sync) &&
	    (!(me->flag))) {
		/* sync :( */
		rdfstore_flat_store_sync(me->model);
                rdfstore_flat_store_sync(me->nodes);
                rdfstore_flat_store_sync(me->subjects);
                rdfstore_flat_store_sync(me->predicates);
                rdfstore_flat_store_sync(me->objects);
		if (context != NULL)
                        rdfstore_flat_store_sync(me->contexts);
#ifdef RDFSTORE_CONNECTIONS
                if (me->s_connections)
                        rdfstore_flat_store_sync(me->s_connections);
                if (me->p_connections)
                        rdfstore_flat_store_sync(me->p_connections);
                if (me->o_connections)
                        rdfstore_flat_store_sync(me->o_connections);
#endif
                if (me->languages)
                        rdfstore_flat_store_sync(me->languages);
                if (me->datatypes)
                        rdfstore_flat_store_sync(me->datatypes);
                if (me->xsd_integer)
                        rdfstore_flat_store_sync(me->xsd_integer);
                if (me->xsd_double)
                        rdfstore_flat_store_sync(me->xsd_double);
                if (me->xsd_date)
                        rdfstore_flat_store_sync(me->xsd_date);
                if (me->freetext)
                        rdfstore_flat_store_sync(me->windex);
		};

	/*
	 * gettideofday(&tnow,NULL); ttime = ( tnow.tv_eec - tstart.tv_sec ) *
	 * 1000000 + ( tnow.tv_usec - tstart.tv_usec ) * 1;
	 * printf("rdfstore_insert DONE [%d micro sec]\n",ttime);
	 */

#ifdef RDFSTORE_FLAT_STORE_DEBUG /*&& RDFSTORE_COUNT_OPERATIONS_PER_STATEMENT*/
	fprintf(stderr,"rdfstore_insert DONE\n");
#endif

#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
	rdfstore_iterator_close(reindex);
#endif

	return 0;
	};

int 
rdfstore_remove(
		rdfstore * me,
		RDF_Statement * statement,
		RDF_Node * given_context
)
{
	RDF_Node       *context = NULL;
	unsigned int    outsize = 0;
	unsigned int    st_id = 0;
	DBT             key, data;
	unsigned char   outbuf[256];
	unsigned char  *word;
	unsigned char  *utf8_casefolded_buff;
	unsigned int    utf8_size = 0, pos = 0;
	char           *sep = RDFSTORE_WORD_SPLITS;
	int             err;
	rdf_store_digest_t hc = 0;

	int islval=0;
	int isdval=0;
	long thelval;
	double thedval;
	struct tm thedateval_tm;
	struct tm* ptm;
	time_t now;
	char thedateval[RDFSTORE_XSD_DATETIME_FORMAT_SIZE];

#ifdef RDFSTORE_CONNECTIONS
        /* buffers for connections matrixes */
        static unsigned char s_connections[RDFSTORE_MAXRECORDS_BYTES_SIZE];
        static unsigned char p_connections[RDFSTORE_MAXRECORDS_BYTES_SIZE];
        static unsigned char o_connections[RDFSTORE_MAXRECORDS_BYTES_SIZE];
        unsigned int    s_outsize = 0;
        unsigned int    p_outsize = 0;
        unsigned int    o_outsize = 0;

	bzero(s_connections,sizeof(RDFSTORE_MAXRECORDS_BYTES_SIZE));
        bzero(p_connections,sizeof(RDFSTORE_MAXRECORDS_BYTES_SIZE));
        bzero(o_connections,sizeof(RDFSTORE_MAXRECORDS_BYTES_SIZE));

#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
        rdfstore_iterator *reindex;
        RDF_Statement * neighbour;
        unsigned int    outsize_reindex = 0;
        static unsigned char reindex_encode[RDFSTORE_MAXRECORDS_BYTES_SIZE];
        static unsigned char reindex_decode[RDFSTORE_MAXRECORDS_BYTES_SIZE];

	bzero(reindex_encode,sizeof(RDFSTORE_MAXRECORDS_BYTES_SIZE));
	bzero(reindex_decode,sizeof(RDFSTORE_MAXRECORDS_BYTES_SIZE));
#endif

#endif

	if ((statement == NULL) ||
	    (statement->subject == NULL) ||
	    (statement->predicate == NULL) ||
	    (statement->subject->value.resource.identifier == NULL) ||
	    (statement->predicate->value.resource.identifier == NULL) ||
	    (statement->object == NULL) ||
	    ((statement->object->type != 1) &&
	     (statement->object->value.resource.identifier == NULL)) ||
	    ((given_context != NULL) &&
	     (given_context->value.resource.identifier == NULL)) ||
	    ((statement->node != NULL) &&
	     (statement->node->value.resource.identifier == NULL)))
		return -1;

	if (given_context == NULL) {
		if (statement->context != NULL)
			context = statement->context;
		else {
			/* use default context */
			if (me->context != NULL)
				context = me->context;
		};
	} else {
		/* use given context instead */
		context = given_context;
	};

#ifdef RDFSTORE_DEBUG
	fprintf(stderr,"TO REMOVE:\n");
	fprintf(stderr,"\tS='%s'\n", statement->subject->value.resource.identifier);
	fprintf(stderr,"\tP='%s'\n", statement->predicate->value.resource.identifier);
	if (statement->object->type != 1) {
		fprintf(stderr,"\tO='%s'\n", statement->object->value.resource.identifier);
	} else {
		fprintf(stderr,"\tOLIT='%s'", statement->object->value.literal.string);
                fprintf(stderr," LANG='%s'", statement->object->value.literal.lang);
                fprintf(stderr," TYPE='%s'", statement->object->value.literal.dataType);
                fprintf(stderr," PARSETYPE='%d'", statement->object->value.literal.parseType);
                fprintf(stderr,"\n");
		};
	if (context != NULL) {
		fprintf(stderr,"\tC='%s'\n", context->value.resource.identifier);
	};
	if (statement->node != NULL)
		fprintf(stderr,"\tSRES='%s'\n", statement->node->value.resource.identifier);
	fprintf(stderr," with options freetext='%d'\n", me->freetext);

	{
	char * buff = NULL;
	if ((buff = rdfstore_ntriples_statement(statement, context)) != NULL) {
		fprintf(stderr," N-triples: %s\n", buff);
		RDFSTORE_FREE(buff);
	};
	};
#endif

	/* look for the statement internal identifier */

	memset(&key, 0, sizeof(key));
	memset(&data, 0, sizeof(data));

#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
	/* init re-index iterator (needed below when filling up adjacency matrixes) */
        reindex = (rdfstore_iterator *) RDFSTORE_MALLOC(sizeof(rdfstore_iterator));
        if (reindex == NULL) {
                perror("rdfstore_insert");
                fprintf(stderr,"Cannot create reindex cursor/iterator for store '%s'\n", (me->name != NULL) ? me->name : "(in-memory)");
                return -1;
        };
        reindex->store = me;
        reindex->store->attached++;
        reindex->remove_holes = 0;      /* reset the total number of holes */
        reindex->st_counter = 0;
        reindex->pos = 0;
        reindex->ids_size = 0;
        reindex->size = 0;
#endif

	/* compute statement hashcode */
	hc = rdfstore_digest_get_statement_hashCode(statement, context);

	/* cache the hashcode if the statement has a "proper" identity */
	if ((given_context == NULL) &&
	    (me->context == NULL))
		statement->hashcode = hc;

	packInt(hc, outbuf);

#ifdef RDFSTORE_DEBUG
	{
		int             i = 0;
		printf("Statement hashcode is '%d' while packed is '", hc);
		for (i = 0; i < sizeof(int); i++) {
			printf("%02X", outbuf[i]);
		};
		printf("'\n");
	}
#endif

	key.data = outbuf;
	key.size = sizeof(int);
	if ((rdfstore_flat_store_fetch(me->statements, key, &data)) != 0) {
#ifdef RDFSTORE_DEBUG
		{
		char * buff = NULL;
		if ((buff = rdfstore_ntriples_statement(statement, context)) != NULL) {
			fprintf(stderr,"Statement '%s' does not exists in store '%s'\n", buff, (me->name != NULL) ? me->name : "(in-memory)");
			RDFSTORE_FREE(buff);
		};
		};
#endif
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
		rdfstore_iterator_close(reindex);
#endif
		return 1;
	};
	/* sort out statement id */
	unpackInt(data.data, &st_id);
	RDFSTORE_FREE(data.data);

	/*
	 * remove statement components (also the statement as resource stuff???)
	 */
	packInt(st_id, outbuf);
	key.data = outbuf;
	key.size = sizeof(int);
	err = rdfstore_flat_store_delete(me->nodes, key);
	if (err != 0) {
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
                rdfstore_iterator_close(reindex);
#endif
                if (err != FLAT_STORE_E_NOTFOUND) {
                	perror("rdfstore_remove");
                	fprintf(stderr,"Could not delete statement for store '%s': %s\n", (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->nodes));
                	return -1;
		} else {
                	return 1;
			};
                };

	/* remove adjacency matrixes stuff */

	/*
	 * compute other hashcodes (the should be cached because the
	 * underlying digest is carried out also for the statement->hashcode
	 * above)
	 */
	statement->subject->hashcode = rdfstore_digest_get_node_hashCode(statement->subject, 0);
	statement->predicate->hashcode = rdfstore_digest_get_node_hashCode(statement->predicate, 0);
	statement->object->hashcode = rdfstore_digest_get_node_hashCode(statement->object, 0);
	if (context != NULL)
		context->hashcode = rdfstore_digest_get_node_hashCode(context, 0);

	/*
	 *
	 * Anoatomy of connections removal
	 *
         * here are all the possible connections an existing statement might get into (i.e. "swiss army knife problem"):
         *
         *              a4                     a6               a8
         *               \                      \                \
         *                \            * *       \       * *      \
         *                 \---> A =====*=======> B ======*======> C------>b9----->c9
         *                     / ^\    * *       /^\     * *       ^\
         *                    /  | \            / | \              | \
         *             b5<---/   |  \--->c4    /  |  \--->c6       |  \--->c8
         *            /          b1           /   b2               b3
         *           /           ^     b7<---/    ^                ^
         *    c5<---/            |     \          |                |
         *                       |      \         |                |
	 *                       a1      \--->c7  a2               a3
         *
         *
         * where  A======>B======>C is the statement to remove and '*' flags edges/arcs to zap
         *
	 * when a statement is removed e.g. (A,B,C) the corresponding connections tables need to be updated; together with the
         * ones of its neighbours. First, the two graph edges connecting the statement components (see '*' signs in the above pic)
         * need to be pruned; then each other connection to neighbours need to be reset accordingly for the statement (st_id) being
         * removed. By removing the connection arcs for the statements the corresponding connections to the connected components
         * need to be removed from each node connection too; this means if a specific node is being a component of more than one
         * statement e.g. C in the above pic - we need for example to reset each connection due to each other component of the statement
         * being removed. For example, by removing the above statement the C nods needs to reset its connections to other statemnts
         * due to A and B nodes (which WERE its subject and object before the statement was removed) - clear enough???!
	 * In practice, when carrying out the connections tables for the statement components being removed we just keep the connections
	 * due to each node self (e.g. for C its subjects(C), predicates(C) and object(C) - of course if not empty - clear?) and do not 
         * consider (reset) all the other set during insertion/updation - which now are not more used.
	 *
	 */

	/* subjects */
	packInt(statement->subject->hashcode, outbuf);
	key.data = outbuf;
	key.size = sizeof(int);

	/*
	 * bzero(me->bits_encode,sizeof(me->bits_encode));
	 * bzero(me->bits_decode,sizeof(me->bits_decode));
	 */
	err = rdfstore_flat_store_fetch(me->subjects, key, &data);
	if (err != 0) {
		if (err != FLAT_STORE_E_NOTFOUND) {
			perror("rdfstore_remove");
			fprintf(stderr,"Could not fetch key '%s' for subject in subjects for store '%s': %s\n", (char *)key.data, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->subjects));
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
			rdfstore_iterator_close(reindex);
#endif
			return -1;
		} else {
			outsize = 0;
		};
	} else {
		me->func_decode(data.size, data.data, &outsize, me->bits_decode);
		RDFSTORE_FREE(data.data);
	};

	/* reset the right bit to zero */
	rdfstore_bits_setmask(&outsize, me->bits_decode, st_id, 1, 0, sizeof(me->bits_decode));

#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
	/*
                We need to re-index quite a lot for each new statement component now - hope caching will
                help here!! i.e. the swiss army nife problem (see SWAD-E paper and preso)

                1.1) remove this new statement (st_id) from p_connections(neighbour->predicate) and o_connections(neighbour->object)
                   tables of each other statement (neighbour) connected to this one via subjects(SUBJECT) node
                1.2) remove this new statement (st_id) from s_connections(neighbour->subject) and o_connections(neighbour->object)
                   tables of each other statement (neighbour) connected to this one via predicates(SUBJECT) node
                1.3) remove this new statement (st_id) from s_connections(neighbour->subject) and p_connections(neighbour->predicate)
                   tables of each other statement (neighbour) connected to this one via objects(SUBJECT) node
        */

        /* 1.1) reindex st_id for connections to subjects(SUBJECT) node */

	/* copy the subjects(SUBJECT) bits through the reindex iterator array */
        memcpy(reindex->ids, me->bits_decode, outsize);
        reindex->ids_size = outsize;
        /* set the size - inefficient!! */
        pos = 0;
        reindex->size = 0;
        /* count the ones (inefficient still) */
        while ((pos = rdfstore_bits_getfirstsetafter(outsize, me->bits_decode, pos)) < 8 * outsize) {
                reindex->size++;
                pos++;
        	};

	/* scan the obtained iterator */
	while ( ( neighbour = rdfstore_iterator_each ( reindex ) ) != NULL ) {

#ifdef RDFSTORE_DEBUG_CONNECTIONS
		printf("(remove)REINDEXING predicate '%s' for connections to subjects('%s') node in st_id=%d\n",neighbour->predicate->value.resource.identifier,statement->subject->value.resource.identifier,st_id);
#endif
		neighbour->predicate->hashcode = rdfstore_digest_get_node_hashCode(neighbour->predicate, 0);

		/* fetch p_connections(neighbour->predicate) */
		packInt(neighbour->predicate->hashcode, outbuf); /* wrong */
		key.data = outbuf;
		key.size = sizeof(int);

		err = rdfstore_flat_store_fetch(me->p_connections, key, &data);
		if (err != 0) {
			if (err != FLAT_STORE_E_NOTFOUND) {
				perror("rdfstore_remove");
				fprintf(stderr,"Could not fetch key '%s' for predicate in p_connections table for store '%s': %s\n", (char *)key.data, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->p_connections));
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
				rdfstore_iterator_close(reindex);
#endif
				return -1;
			} else {
				outsize_reindex = 0;
			};
		} else {
			me->func_decode_connections(data.size, data.data, &outsize_reindex, reindex_decode);
			RDFSTORE_FREE(data.data);
			};

		/* reset the corresponding bit of this statement */
		rdfstore_bits_setmask(&outsize_reindex, reindex_decode, st_id, 1, 0, sizeof(reindex_decode));

		/* store it back */
		me->func_encode_connections(outsize_reindex, reindex_decode, &outsize_reindex, reindex_encode);

		data.data = reindex_encode;
		data.size = outsize_reindex;
		err = rdfstore_flat_store_store(me->p_connections, key, data);
		if (err != 0) {
			if (err != FLAT_STORE_E_KEYEXIST) {
				perror("rdfstore_remove");
				fprintf(stderr,"Could not store '%d' bytes for predicate in p_connections table for store '%s': %s\n", (int)data.size, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->p_connections));
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
				rdfstore_iterator_close(reindex);
#endif
				return -1;
				};
			};

#ifdef RDFSTORE_DEBUG_CONNECTIONS
		printf("(remove)REINDEXING object '%s' for connections to subjects('%s') node in st_id=%d\n",(neighbour->object->type==1) ? neighbour->object->value.literal.string : neighbour->object->value.resource.identifier,statement->subject->value.resource.identifier,st_id);
#endif
		neighbour->object->hashcode = rdfstore_digest_get_node_hashCode(neighbour->object, 0);

		/* fetch o_connections(neighbour->object) */
		packInt(neighbour->object->hashcode, outbuf); /* wrong */
		key.data = outbuf;
		key.size = sizeof(int);

		err = rdfstore_flat_store_fetch(me->o_connections, key, &data);
		if (err != 0) {
			if (err != FLAT_STORE_E_NOTFOUND) {
				perror("rdfstore_remove");
				fprintf(stderr,"Could not fetch key '%s' for object in o_connections table for store '%s': %s\n", (char *)key.data, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->o_connections));
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
				rdfstore_iterator_close(reindex);
#endif
				return -1;
			} else {
				outsize_reindex = 0;
			};
		} else {
			me->func_decode_connections(data.size, data.data, &outsize_reindex, reindex_decode);
			RDFSTORE_FREE(data.data);
			};

		/* reset the corresponding bit of this statement */
		rdfstore_bits_setmask(&outsize_reindex, reindex_decode, st_id, 1, 0, sizeof(reindex_decode));

		/* store it back */
		me->func_encode_connections(outsize_reindex, reindex_decode, &outsize_reindex, reindex_encode);

		/* now: we do not need/must check whther or not to remove this key because the other statement is sitll there */

		data.data = reindex_encode;
		data.size = outsize_reindex;
		err = rdfstore_flat_store_store(me->o_connections, key, data);
		if (err != 0) {
			if (err != FLAT_STORE_E_KEYEXIST) {
				perror("rdfstore_remove");
				fprintf(stderr,"Could not store '%d' bytes for object in o_connections table for store '%s': %s\n", (int)data.size, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->o_connections));
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
				rdfstore_iterator_close(reindex);
#endif
				return -1;
				};
			};

		/* free neighbour */
                RDFSTORE_FREE( neighbour->subject->value.resource.identifier );
                RDFSTORE_FREE( neighbour->subject );
                RDFSTORE_FREE( neighbour->predicate->value.resource.identifier );
                RDFSTORE_FREE( neighbour->predicate );
                if ( neighbour->object->type == 1 ) {
                        if ( neighbour->object->value.literal.dataType != NULL )
                                RDFSTORE_FREE( neighbour->object->value.literal.dataType );
                        RDFSTORE_FREE( neighbour->object->value.literal.string );
                } else {
                        RDFSTORE_FREE( neighbour->object->value.resource.identifier );
                        };
                RDFSTORE_FREE( neighbour->object );
                if ( neighbour->context != NULL ) {
                        RDFSTORE_FREE( neighbour->context->value.resource.identifier );
                        RDFSTORE_FREE( neighbour->context );
                        };
                if ( neighbour->node != NULL ) {
                        RDFSTORE_FREE( neighbour->node->value.resource.identifier );
                        RDFSTORE_FREE( neighbour->node );
                        };
                RDFSTORE_FREE( neighbour );
		};
#endif

	/* regenerate it due to the re-indexing above which uses key already */
	packInt(statement->subject->hashcode, outbuf);
	key.data = outbuf;
	key.size = sizeof(int);

	outsize = rdfstore_bits_shorten(outsize, me->bits_decode);

	if ( outsize > 0 ) {
		me->func_encode(outsize, me->bits_decode, &outsize, me->bits_encode);
		if (outsize) {
			data.data = me->bits_encode;
			data.size = outsize;
			err = rdfstore_flat_store_store(me->subjects, key, data);
			if (err == 0) {
#ifdef RDFSTORE_DEBUG_COMPRESSION
				fprintf(stderr,"Stored %d bytes for '%s' in subjects for store '%s'\n", outsize, (char *)key.data, (me->name != NULL) ? me->name : "(in-memory)");
#endif
			} else {
				if (err != FLAT_STORE_E_KEYEXIST) {
					perror("rdfstore_remove");
					fprintf(stderr,"Could not store '%d' bytes for subject in subjects for store '%s': %s\n", (int)data.size, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->subjects));
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
					rdfstore_iterator_close(reindex);
#endif
					return -1;
				};
			};

#ifdef RDFSTORE_DEBUG
			{
				int             i=0;
				if ((rdfstore_flat_store_fetch(me->subjects, key, &data)) == 0) {
					me->func_decode(data.size, data.data, &outsize, me->bits_decode);
					RDFSTORE_FREE(data.data);
				};
				printf("REMOVED st_num=%d bitno=%d subjects for S -->'", st_id, st_id);
				for(i=0;i<8*outsize;i++) {
					printf("Rec %d %c\n", i, (me->bits_decode[i>>3] & (1<<(i&7))) ? '1':'0');
                                        };
				printf("'\n");
			}
#endif

		};

#ifdef RDFSTORE_CONNECTIONS
        	/* COPY subjects(SUBJECT) to s_connections(SUBJECT) */
        	bcopy(me->bits_decode, s_connections, outsize);   /* slow? */
        	s_outsize = outsize;
#endif
	} else {
		err = rdfstore_flat_store_delete(me->subjects, key);
		if (err != 0) {
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
                	rdfstore_iterator_close(reindex);
#endif
			if (err != FLAT_STORE_E_NOTFOUND) {
                		perror("rdfstore_remove");
                		fprintf(stderr,"Could not delete statement for store '%s': %s\n", (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->subjects));
                		return -1;
			} else {
				return 1;
				};
                	};
#ifdef RDFSTORE_DEBUG
		printf("DELETED (%d) subjects for S\n", st_id);
#endif
		};

MX;
	/* predicates */
	packInt(statement->predicate->hashcode, outbuf);
	key.data = outbuf;
	key.size = sizeof(int);
MX;

	/*
	 * bzero(me->bits_encode,sizeof(me->bits_encode));
	 * bzero(me->bits_decode,sizeof(me->bits_decode));
	 */
	err = rdfstore_flat_store_fetch(me->predicates, key, &data);
	if (err != 0) {
		if (err != FLAT_STORE_E_NOTFOUND) {
			perror("rdfstore_remove");
			fprintf(stderr,"Could not fetch key '%s' for predicate in predicates for store '%s': %s\n", (char *)key.data, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->predicates));
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
			rdfstore_iterator_close(reindex);
#endif
			return -1;
		} else {
			outsize = 0;
		};
	} else {
		me->func_decode(data.size, data.data, &outsize, me->bits_decode);	/* perhaps the
												 * compression for
												 * single bits could be
												 * different */
		RDFSTORE_FREE(data.data);
		};

MX;
	/* reset the right bits to zero */
	rdfstore_bits_setmask(&outsize, me->bits_decode, st_id, 1, 0, sizeof(me->bits_decode));

#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
        /* 2.2) reindex st_id for connections to predicates(PREDICATE) node */

	/* copy the predicates(PREDICATE) bits through the reindex iterator array */
        memcpy(reindex->ids, me->bits_decode, outsize);
        reindex->ids_size = outsize;
        /* set the size - inefficient!! */
        pos = 0;
        reindex->size = 0;
        /* count the ones (inefficient still) */
        while ((pos = rdfstore_bits_getfirstsetafter(outsize, me->bits_decode, pos)) < 8 * outsize) {
                reindex->size++;
                pos++;
        	};

	/* scan the obtained iterator */
	while ( ( neighbour = rdfstore_iterator_each ( reindex ) ) != NULL ) {

#ifdef RDFSTORE_DEBUG_CONNECTIONS
		printf("(remove)REINDEXING subject '%s' for connections to predicates('%s') node in st_id=%d\n",neighbour->subject->value.resource.identifier,statement->predicate->value.resource.identifier,st_id);
#endif
		neighbour->subject->hashcode = rdfstore_digest_get_node_hashCode(neighbour->subject, 0);

		/* fetch s_connections(neighbour->subject) */
		packInt(neighbour->subject->hashcode, outbuf); /* wrong */
		key.data = outbuf;
		key.size = sizeof(int);

		err = rdfstore_flat_store_fetch(me->s_connections, key, &data);
		if (err != 0) {
			if (err != FLAT_STORE_E_NOTFOUND) {
				perror("rdfstore_remove");
				fprintf(stderr,"Could not fetch key '%s' for subject in s_connections table for store '%s': %s\n", (char *)key.data, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->s_connections));
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
				rdfstore_iterator_close(reindex);
#endif
				return -1;
			} else {
				outsize_reindex = 0;
			};
		} else {
			me->func_decode_connections(data.size, data.data, &outsize_reindex, reindex_decode);
			RDFSTORE_FREE(data.data);
			};

		/* reset the corresponding bit of this statement */
		rdfstore_bits_setmask(&outsize_reindex, reindex_decode, st_id, 1, 0, sizeof(reindex_decode));

		/* store it back */
		me->func_encode_connections(outsize_reindex, reindex_decode, &outsize_reindex, reindex_encode);

		data.data = reindex_encode;
		data.size = outsize_reindex;
		err = rdfstore_flat_store_store(me->s_connections, key, data);
		if (err != 0) {
			if (err != FLAT_STORE_E_KEYEXIST) {
				perror("rdfstore_remove");
				fprintf(stderr,"Could not store '%d' bytes for subject in s_connections table for store '%s': %s\n", (int)data.size, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->s_connections));
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
				rdfstore_iterator_close(reindex);
#endif
				return -1;
				};
			};

#ifdef RDFSTORE_DEBUG_CONNECTIONS
		printf("(remove)REINDEXING object '%s' for connections to predicates('%s') node in st_id=%d\n",(neighbour->object->type==1) ? neighbour->object->value.literal.string : neighbour->object->value.resource.identifier,statement->predicate->value.resource.identifier,st_id);
#endif
		neighbour->object->hashcode = rdfstore_digest_get_node_hashCode(neighbour->object, 0);

		/* fetch o_connections(neighbour->object) */
		packInt(neighbour->object->hashcode, outbuf); /* wrong */
		key.data = outbuf;
		key.size = sizeof(int);

		err = rdfstore_flat_store_fetch(me->o_connections, key, &data);
		if (err != 0) {
			if (err != FLAT_STORE_E_NOTFOUND) {
				perror("rdfstore_remove");
				fprintf(stderr,"Could not fetch key '%s' for object in o_connections table for store '%s': %s\n", (char *)key.data, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->o_connections));
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
				rdfstore_iterator_close(reindex);
#endif
				return -1;
			} else {
				outsize_reindex = 0;
			};
		} else {
			me->func_decode_connections(data.size, data.data, &outsize_reindex, reindex_decode);
			RDFSTORE_FREE(data.data);
			};

		/* reset the corresponding bit of this statement */
		rdfstore_bits_setmask(&outsize_reindex, reindex_decode, st_id, 1, 0, sizeof(reindex_decode));

		/* store it back */
		me->func_encode_connections(outsize_reindex, reindex_decode, &outsize_reindex, reindex_encode);

		data.data = reindex_encode;
		data.size = outsize_reindex;
		err = rdfstore_flat_store_store(me->o_connections, key, data);
		if (err != 0) {
			if (err != FLAT_STORE_E_KEYEXIST) {
				perror("rdfstore_remove");
				fprintf(stderr,"Could not store '%d' bytes for object in o_connections table for store '%s': %s\n", (int)data.size, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->o_connections));
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
				rdfstore_iterator_close(reindex);
#endif
				return -1;
				};
			};

		/* free neighbour */
                RDFSTORE_FREE( neighbour->subject->value.resource.identifier );
                RDFSTORE_FREE( neighbour->subject );
                RDFSTORE_FREE( neighbour->predicate->value.resource.identifier );
                RDFSTORE_FREE( neighbour->predicate );
                if ( neighbour->object->type == 1 ) {
                        if ( neighbour->object->value.literal.dataType != NULL )
                                RDFSTORE_FREE( neighbour->object->value.literal.dataType );
                        RDFSTORE_FREE( neighbour->object->value.literal.string );
                } else {
                        RDFSTORE_FREE( neighbour->object->value.resource.identifier );
                        };
                RDFSTORE_FREE( neighbour->object );
                if ( neighbour->context != NULL ) {
                        RDFSTORE_FREE( neighbour->context->value.resource.identifier );
                        RDFSTORE_FREE( neighbour->context );
                        };
                if ( neighbour->node != NULL ) {
                        RDFSTORE_FREE( neighbour->node->value.resource.identifier );
                        RDFSTORE_FREE( neighbour->node );
                        };
                RDFSTORE_FREE( neighbour );
		};
#endif

	/* regenerate it due to the re-indexing above which uses key already */
	packInt(statement->predicate->hashcode, outbuf);
	key.data = outbuf;
	key.size = sizeof(int);

	outsize = rdfstore_bits_shorten(outsize, me->bits_decode);
	if ( outsize > 0 ) {
		me->func_encode(outsize, me->bits_decode, &outsize, me->bits_encode);
		if (outsize) {
			data.data = me->bits_encode;
			data.size = outsize;
			err = rdfstore_flat_store_store(me->predicates, key, data);
			if (err == 0) {
#ifdef RDFSTORE_DEBUG_COMPRESSION
				fprintf(stderr,"Stored %d bytes for '%s' in predicates for store '%s'\n", outsize, (char *)key.data, (me->name != NULL) ? me->name : "(in-memory)");
#endif
			} else {
				if (err != FLAT_STORE_E_KEYEXIST) {
					perror("rdfstore_remove");
					fprintf(stderr,"Could not store '%d' bytes for predicate in predicates for store '%s': %s\n", (int)data.size, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->predicates));
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
					rdfstore_iterator_close(reindex);
#endif
					return -1;
				};
			};

#ifdef RDFSTORE_DEBUG
			{
				int             i=0;
				if ((rdfstore_flat_store_fetch(me->predicates, key, &data)) == 0) {
					me->func_decode(data.size, data.data, &outsize, me->bits_decode);
					RDFSTORE_FREE(data.data);
				};
				printf("REMOVED st_num=%d bitno=%d predicates for P -->'", st_id,st_id);
				for(i=0;i<8*outsize;i++) {
					printf("Rec %d %c\n", i, (me->bits_decode[i>>3] & (1<<(i&7))) ? '1':'0');
                                        };
				printf("'\n");
			}
#endif

		};
#ifdef RDFSTORE_CONNECTIONS
        	/* OR predicates(PREDICATE) to p_connections(PREDICATE) */
        	p_outsize = rdfstore_bits_or(outsize, me->bits_decode, p_outsize, p_connections, me->bits_encode);
        	bcopy(me->bits_encode, p_connections, p_outsize);   /* slow? */
#endif
	} else { 
		err = rdfstore_flat_store_delete(me->predicates, key);
		if (err != 0) {
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
                        rdfstore_iterator_close(reindex);
#endif
                        if (err != FLAT_STORE_E_NOTFOUND) {
                        	perror("rdfstore_remove");
                        	fprintf(stderr,"Could not delete statement for store '%s': %s\n", (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->predicates));
                        	return -1;
			} else {
				return 1;
				};
                        };
#ifdef RDFSTORE_DEBUG
		printf("DELETED (%d) predicates for P\n", st_id);
#endif
		};

MX;

	/* objects */
	packInt(statement->object->hashcode, outbuf);
	key.data = outbuf;
	key.size = sizeof(int);

	/*
	 * bzero(me->bits_encode,sizeof(me->bits_encode));
	 * bzero(me->bits_decode,sizeof(me->bits_decode));
	 */
	err = rdfstore_flat_store_fetch(me->objects, key, &data);
	if (err != 0) {
		if (err != FLAT_STORE_E_NOTFOUND) {
			perror("rdfstore_remove");
			fprintf(stderr,"Could not fetch key '%s' for object in objects for store '%s': %s\n", (char *)key.data, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->objects));
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
			rdfstore_iterator_close(reindex);
#endif
			return -1;
		} else {
			outsize = 0;
		};
	} else {
		me->func_decode(data.size, data.data, &outsize, me->bits_decode);	/* perhaps the
												 * compression for
												 * single bits could be
												 * different */
		RDFSTORE_FREE(data.data);
	};

	/* reset the right bit to zero */
	rdfstore_bits_setmask(&outsize, me->bits_decode, st_id, 1, 0, sizeof(me->bits_decode));

#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
        /* 3.3) reindex st_id for connections to objects(OBJECT) node */

	/* copy the objects(OBJECT) bits through the reindex iterator array */
        memcpy(reindex->ids, me->bits_decode, outsize);
        reindex->ids_size = outsize;
        /* set the size - inefficient!! */
        pos = 0;
        reindex->size = 0;
        /* count the ones (inefficient still) */
        while ((pos = rdfstore_bits_getfirstsetafter(outsize, me->bits_decode, pos)) < 8 * outsize) {
                reindex->size++;
                pos++;
        	};

	/* scan the obtained iterator */
	while ( ( neighbour = rdfstore_iterator_each ( reindex ) ) != NULL ) {

#ifdef RDFSTORE_DEBUG_CONNECTIONS
		printf("(remove)REINDEXING subject '%s' for connections to objects('%s') node in st_id=%d\n",neighbour->subject->value.resource.identifier,(statement->object->type==1) ? statement->object->value.literal.string : statement->object->value.resource.identifier,st_id);
#endif
		neighbour->subject->hashcode = rdfstore_digest_get_node_hashCode(neighbour->subject, 0);

		/* fetch s_connections(neighbour->subject) */
		packInt(neighbour->subject->hashcode, outbuf); /* wrong */
		key.data = outbuf;
		key.size = sizeof(int);

		err = rdfstore_flat_store_fetch(me->s_connections, key, &data);
		if (err != 0) {
			if (err != FLAT_STORE_E_NOTFOUND) {
				perror("rdfstore_remove");
				fprintf(stderr,"Could not fetch key '%s' for subject in s_connections table for store '%s': %s\n", (char *)key.data, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->s_connections));
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
				rdfstore_iterator_close(reindex);
#endif
				return -1;
			} else {
				outsize_reindex = 0;
			};
		} else {
			me->func_decode_connections(data.size, data.data, &outsize_reindex, reindex_decode);
			RDFSTORE_FREE(data.data);
			};

		/* reset the corresponding bit of this statement */
		rdfstore_bits_setmask(&outsize_reindex, reindex_decode, st_id, 1, 0, sizeof(reindex_decode));

		/* store it back */
		me->func_encode_connections(outsize_reindex, reindex_decode, &outsize_reindex, reindex_encode);

		data.data = reindex_encode;
		data.size = outsize_reindex;
		err = rdfstore_flat_store_store(me->s_connections, key, data);
		if (err != 0) {
			if (err != FLAT_STORE_E_KEYEXIST) {
				perror("rdfstore_remove");
				fprintf(stderr,"Could not store '%d' bytes for subject in s_connections table for store '%s': %s\n", (int)data.size, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->s_connections));
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
				rdfstore_iterator_close(reindex);
#endif
				return -1;
				};
			};

#ifdef RDFSTORE_DEBUG_CONNECTIONS
		printf("(remove)REINDEXING predicate '%s' for connections to objects('%s') node in st_id=%d\n",neighbour->predicate->value.resource.identifier,(statement->object->type==1) ? statement->object->value.literal.string : statement->object->value.resource.identifier,st_id);
#endif
		neighbour->predicate->hashcode = rdfstore_digest_get_node_hashCode(neighbour->predicate, 0);

		/* fetch p_connections(neighbour->predicate) */
		packInt(neighbour->predicate->hashcode, outbuf); /* wrong */
		key.data = outbuf;
		key.size = sizeof(int);

		err = rdfstore_flat_store_fetch(me->p_connections, key, &data);
		if (err != 0) {
			if (err != FLAT_STORE_E_NOTFOUND) {
				perror("rdfstore_remove");
				fprintf(stderr,"Could not fetch key '%s' for predicate in p_connections table for store '%s': %s\n", (char *)key.data, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->p_connections));
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
				rdfstore_iterator_close(reindex);
#endif
				return -1;
			} else {
				outsize_reindex = 0;
			};
		} else {
			me->func_decode_connections(data.size, data.data, &outsize_reindex, reindex_decode);
			RDFSTORE_FREE(data.data);
			};

		/* reset the corresponding bit of this statement */
		rdfstore_bits_setmask(&outsize_reindex, reindex_decode, st_id, 1, 0, sizeof(reindex_decode));

		/* store it back */
		me->func_encode_connections(outsize_reindex, reindex_decode, &outsize_reindex, reindex_encode);

		data.data = reindex_encode;
		data.size = outsize_reindex;
		err = rdfstore_flat_store_store(me->p_connections, key, data);
		if (err != 0) {
			if (err != FLAT_STORE_E_KEYEXIST) {
				perror("rdfstore_remove");
				fprintf(stderr,"Could not store '%d' bytes for predicate in p_connections table for store '%s': %s\n", (int)data.size, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->p_connections));
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
				rdfstore_iterator_close(reindex);
#endif
				return -1;
				};
			};

		/* free neighbour */
                RDFSTORE_FREE( neighbour->subject->value.resource.identifier );
                RDFSTORE_FREE( neighbour->subject );
                RDFSTORE_FREE( neighbour->predicate->value.resource.identifier );
                RDFSTORE_FREE( neighbour->predicate );
                if ( neighbour->object->type == 1 ) {
                        if ( neighbour->object->value.literal.dataType != NULL )
                                RDFSTORE_FREE( neighbour->object->value.literal.dataType );
                        RDFSTORE_FREE( neighbour->object->value.literal.string );
                } else {
                        RDFSTORE_FREE( neighbour->object->value.resource.identifier );
                        };
                RDFSTORE_FREE( neighbour->object );
                if ( neighbour->context != NULL ) {
                        RDFSTORE_FREE( neighbour->context->value.resource.identifier );
                        RDFSTORE_FREE( neighbour->context );
                        };
                if ( neighbour->node != NULL ) {
                        RDFSTORE_FREE( neighbour->node->value.resource.identifier );
                        RDFSTORE_FREE( neighbour->node );
                        };
                RDFSTORE_FREE( neighbour );
		};
#endif

	/* regenerate it due to the re-indexing above which uses key already */
	packInt(statement->object->hashcode, outbuf);
	key.data = outbuf;
	key.size = sizeof(int);

	outsize = rdfstore_bits_shorten(outsize, me->bits_decode);
	if ( outsize > 0 ) {
		me->func_encode(outsize, me->bits_decode, &outsize, me->bits_encode);
		if (outsize) {
			data.data = me->bits_encode;
			data.size = outsize;
			err = rdfstore_flat_store_store(me->objects, key, data);
			if (err == 0) {
#ifdef RDFSTORE_DEBUG_COMPRESSION
				fprintf(stderr,"Stored %d bytes for '%s' in objects for store '%s'\n", outsize, (char *)key.data, (me->name != NULL) ? me->name : "(in-memory)");
#endif
			} else {
				if (err != FLAT_STORE_E_KEYEXIST) {
					perror("rdfstore_remove");
					fprintf(stderr,"Could not store '%d' bytes for object in objects for store '%s': %s\n", (int)data.size, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->objects));
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
					rdfstore_iterator_close(reindex);
#endif
					return -1;
				};
			};

#ifdef RDFSTORE_DEBUG
			{
				int             i=0;
				if ((rdfstore_flat_store_fetch(me->objects, key, &data)) == 0) {
					me->func_decode(data.size, data.data, &outsize, me->bits_decode);
					RDFSTORE_FREE(data.data);
				};
				printf("REMOVED st_num=%d bitno=%d objects for O -->'", st_id, st_id);
				for(i=0;i<8*outsize;i++) {
					printf("Rec %d %c\n", i, (me->bits_decode[i>>3] & (1<<(i&7))) ? '1':'0');
                                        };
				printf("'\n");
			}
#endif

		};
#ifdef RDFSTORE_CONNECTIONS
        	/* OR objects(OBJECT) to o_connections(OBJECT) */
        	o_outsize = rdfstore_bits_or(outsize, me->bits_decode, o_outsize, o_connections, me->bits_encode);
        	bcopy(me->bits_encode, o_connections, o_outsize);   /* slow? */
#endif
	} else {
		err = rdfstore_flat_store_delete(me->objects, key);
		if (err != 0) {
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
                        rdfstore_iterator_close(reindex);
#endif
                        if (err != FLAT_STORE_E_NOTFOUND) {
				perror("rdfstore_remove");
                        	fprintf(stderr,"Could not delete statement for store '%s': %s\n", (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->objects));
                        	return -1;
			} else {
				return 1;
				};
                        };
#ifdef RDFSTORE_DEBUG
		printf("DELETED (%d) objects for O\n", st_id);
#endif
	};

#ifdef RDFSTORE_CONNECTIONS
	/* fill up all the rest of s_connections, p_connections and o_connections i.e. carry out remaining permutations of each component */

        /* fetch subjects(PREDICATE) i.e. statements which has PREDICATE as subject */
        packInt(statement->predicate->hashcode, outbuf);
        key.data = outbuf;
        key.size = sizeof(int);

        err = rdfstore_flat_store_fetch(me->subjects, key, &data);
        if (err != 0) {
                if (err != FLAT_STORE_E_NOTFOUND) {
                        perror("rdfstore_remove");
                        fprintf(stderr,"Could not fetch key '%s' for predicate in subjects table for store '%s': %s\n", (char *)key.data, (me->name != NULL) ?  me->name : "(in-memory)", rdfstore_flat_store_get_error(me->subjects));
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
			rdfstore_iterator_close(reindex);
#endif
                        return -1;
                } else {
                        outsize = 0;
                };
        } else {
                me->func_decode(data.size, data.data, &outsize, me->bits_decode);
                RDFSTORE_FREE(data.data);
                };

#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
	/*
                We need to re-index quite a lot for each new statement component now - hope caching will
                help here!! i.e. the swiss army nife problem (see SWAD-E paper and preso)

                2.1) remove this new statement (st_id) from p_connections(neighbour->predicate) and o_connections(neighbour->object)
                   tables of each other statement (neighbour) connected to this one via subjects(PREDICATE) node
                2.2) remove this new statement (st_id) from s_connections(neighbour->subject) and o_connections(neighbour->object)
                   tables of each other statement (neighbour) connected to this one via predicates(PREDICATE) node
                2.3) remove this new statement (st_id) from s_connections(neighbour->subject) and p_connections(neighbour->predicate)
                   tables of each other statement (neighbour) connected to this one via objects(PREDICATE) node
        */

        /* 2.1) reindex st_id for connections to subjects(PREDICATE) node */

	/* copy the subjects(PREDICATE) bits through the reindex iterator array */
        memcpy(reindex->ids, me->bits_decode, outsize);
        reindex->ids_size = outsize;
        /* set the size - inefficient!! */
        pos = 0;
        reindex->size = 0;
        /* count the ones (inefficient still) */
        while ((pos = rdfstore_bits_getfirstsetafter(outsize, me->bits_decode, pos)) < 8 * outsize) {
                reindex->size++;
                pos++;
        	};

	/* scan the obtained iterator */
	while ( ( neighbour = rdfstore_iterator_each ( reindex ) ) != NULL ) {

#ifdef RDFSTORE_DEBUG_CONNECTIONS
		printf("(remove)REINDEXING predicate '%s' for connections to subjects('%s') node in st_id=%d\n",neighbour->predicate->value.resource.identifier,statement->predicate->value.resource.identifier,st_id);
#endif
		neighbour->predicate->hashcode = rdfstore_digest_get_node_hashCode(neighbour->predicate, 0);

		/* fetch p_connections(neighbour->predicate) */
		packInt(neighbour->predicate->hashcode, outbuf); /* wrong */
		key.data = outbuf;
		key.size = sizeof(int);

		err = rdfstore_flat_store_fetch(me->p_connections, key, &data);
		if (err != 0) {
			if (err != FLAT_STORE_E_NOTFOUND) {
				perror("rdfstore_remove");
				fprintf(stderr,"Could not fetch key '%s' for predicate in p_connections table for store '%s': %s\n", (char *)key.data, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->p_connections));
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
				rdfstore_iterator_close(reindex);
#endif
				return -1;
			} else {
				outsize_reindex = 0;
			};
		} else {
			me->func_decode_connections(data.size, data.data, &outsize_reindex, reindex_decode);
			RDFSTORE_FREE(data.data);
			};

		/* reset the corresponding bit of this statement */
		rdfstore_bits_setmask(&outsize_reindex, reindex_decode, st_id, 1, 0, sizeof(reindex_decode));

		/* store it back */
		me->func_encode_connections(outsize_reindex, reindex_decode, &outsize_reindex, reindex_encode);

		data.data = reindex_encode;
		data.size = outsize_reindex;
		err = rdfstore_flat_store_store(me->p_connections, key, data);
		if (err != 0) {
			if (err != FLAT_STORE_E_KEYEXIST) {
				perror("rdfstore_remove");
				fprintf(stderr,"Could not store '%d' bytes for predicate in p_connections table for store '%s': %s\n", (int)data.size, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->p_connections));
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
				rdfstore_iterator_close(reindex);
#endif
				return -1;
				};
			};

#ifdef RDFSTORE_DEBUG_CONNECTIONS
		printf("(remove)REINDEXING object '%s' for connections to subjects('%s') node in st_id=%d\n",(neighbour->object->type==1) ? neighbour->object->value.literal.string : neighbour->object->value.resource.identifier,statement->predicate->value.resource.identifier,st_id);
#endif
		neighbour->object->hashcode = rdfstore_digest_get_node_hashCode(neighbour->object, 0);

		/* fetch o_connections(neighbour->object) */
		packInt(neighbour->object->hashcode, outbuf); /* wrong */
		key.data = outbuf;
		key.size = sizeof(int);

		err = rdfstore_flat_store_fetch(me->o_connections, key, &data);
		if (err != 0) {
			if (err != FLAT_STORE_E_NOTFOUND) {
				perror("rdfstore_remove");
				fprintf(stderr,"Could not fetch key '%s' for object in o_connections table for store '%s': %s\n", (char *)key.data, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->o_connections));
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
				rdfstore_iterator_close(reindex);
#endif
				return -1;
			} else {
				outsize_reindex = 0;
			};
		} else {
			me->func_decode_connections(data.size, data.data, &outsize_reindex, reindex_decode);
			RDFSTORE_FREE(data.data);
			};

		/* reset the corresponding bit of this statement */
		rdfstore_bits_setmask(&outsize_reindex, reindex_decode, st_id, 1, 0, sizeof(reindex_decode));

		/* store it back */
		me->func_encode_connections(outsize_reindex, reindex_decode, &outsize_reindex, reindex_encode);

		/* now: we do not need/must check whther or not to remove this key because the other statement is sitll there */

		data.data = reindex_encode;
		data.size = outsize_reindex;
		err = rdfstore_flat_store_store(me->o_connections, key, data);
		if (err != 0) {
			if (err != FLAT_STORE_E_KEYEXIST) {
				perror("rdfstore_remove");
				fprintf(stderr,"Could not store '%d' bytes for object in o_connections table for store '%s': %s\n", (int)data.size, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->o_connections));
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
				rdfstore_iterator_close(reindex);
#endif
				return -1;
				};
			};

		/* free neighbour */
                RDFSTORE_FREE( neighbour->subject->value.resource.identifier );
                RDFSTORE_FREE( neighbour->subject );
                RDFSTORE_FREE( neighbour->predicate->value.resource.identifier );
                RDFSTORE_FREE( neighbour->predicate );
                if ( neighbour->object->type == 1 ) {
                        if ( neighbour->object->value.literal.dataType != NULL )
                                RDFSTORE_FREE( neighbour->object->value.literal.dataType );
                        RDFSTORE_FREE( neighbour->object->value.literal.string );
                } else {
                        RDFSTORE_FREE( neighbour->object->value.resource.identifier );
                        };
                RDFSTORE_FREE( neighbour->object );
                if ( neighbour->context != NULL ) {
                        RDFSTORE_FREE( neighbour->context->value.resource.identifier );
                        RDFSTORE_FREE( neighbour->context );
                        };
                if ( neighbour->node != NULL ) {
                        RDFSTORE_FREE( neighbour->node->value.resource.identifier );
                        RDFSTORE_FREE( neighbour->node );
                        };
                RDFSTORE_FREE( neighbour );
		};
#endif

	/* OR subjects(PREDICATE) to s_connections(SUBJECT) */
        s_outsize = rdfstore_bits_or(outsize, me->bits_decode, s_outsize, s_connections, me->bits_encode); 
        bcopy(me->bits_encode, s_connections, s_outsize);   /* slow? */

        /* fetch subjects(OBJECT) */
        packInt(statement->object->hashcode, outbuf);
        key.data = outbuf;
        key.size = sizeof(int);

	err = rdfstore_flat_store_fetch(me->subjects, key, &data);
        if (err != 0) {
                if (err != FLAT_STORE_E_NOTFOUND) {
                        perror("rdfstore_remove");
                        fprintf(stderr,"Could not fetch key '%s' for object in subjects table for store '%s': %s\n", (char *)key.data, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->subjects));
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
			rdfstore_iterator_close(reindex);
#endif
                        return -1;
                } else {
                        outsize = 0;
                };
        } else {
                me->func_decode(data.size, data.data, &outsize, me->bits_decode);
                RDFSTORE_FREE(data.data);
                };

#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
	/*
                We need to re-index quite a lot for each new statement component now - hope caching will
                help here!! i.e. the swiss army nife problem (see SWAD-E paper and preso)

                3.1) remove this new statement (st_id) from p_connections(neighbour->predicate) and o_connections(neighbour->object)
                   tables of each other statement (neighbour) connected to this one via subjects(OBJECT) node
                3.2) remove this new statement (st_id) from s_connections(neighbour->subject) and o_connections(neighbour->object)
                   tables of each other statement (neighbour) connected to this one via predicates(OBJECT) node
                3.3) remove this new statement (st_id) from s_connections(neighbour->subject) and p_connections(neighbour->predicate)
                   tables of each other statement (neighbour) connected to this one via objects(OBJECT) node
        */

        /* 3.1) reindex st_id for connections to subjects(OBJECT) node */

	/* copy the subjects(OBJECT) bits through the reindex iterator array */
        memcpy(reindex->ids, me->bits_decode, outsize);
        reindex->ids_size = outsize;
        /* set the size - inefficient!! */
        pos = 0;
        reindex->size = 0;
        /* count the ones (inefficient still) */
        while ((pos = rdfstore_bits_getfirstsetafter(outsize, me->bits_decode, pos)) < 8 * outsize) {
                reindex->size++;
                pos++;
        	};

	/* scan the obtained iterator */
	while ( ( neighbour = rdfstore_iterator_each ( reindex ) ) != NULL ) {

#ifdef RDFSTORE_DEBUG_CONNECTIONS
		printf("(remove)REINDEXING predicate '%s' for connections to subjects('%s') node in st_id=%d\n",neighbour->predicate->value.resource.identifier,(statement->object->type==1) ? statement->object->value.literal.string : statement->object->value.resource.identifier,st_id);
#endif
		neighbour->predicate->hashcode = rdfstore_digest_get_node_hashCode(neighbour->predicate, 0);

		/* fetch p_connections(neighbour->predicate) */
		packInt(neighbour->predicate->hashcode, outbuf); /* wrong */
		key.data = outbuf;
		key.size = sizeof(int);

		err = rdfstore_flat_store_fetch(me->p_connections, key, &data);
		if (err != 0) {
			if (err != FLAT_STORE_E_NOTFOUND) {
				perror("rdfstore_remove");
				fprintf(stderr,"Could not fetch key '%s' for predicate in p_connections table for store '%s': %s\n", (char *)key.data, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->p_connections));
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
				rdfstore_iterator_close(reindex);
#endif
				return -1;
			} else {
				outsize_reindex = 0;
			};
		} else {
			me->func_decode_connections(data.size, data.data, &outsize_reindex, reindex_decode);
			RDFSTORE_FREE(data.data);
			};

		/* reset the corresponding bit of this statement */
		rdfstore_bits_setmask(&outsize_reindex, reindex_decode, st_id, 1, 0, sizeof(reindex_decode));

		/* store it back */
		me->func_encode_connections(outsize_reindex, reindex_decode, &outsize_reindex, reindex_encode);

		data.data = reindex_encode;
		data.size = outsize_reindex;
		err = rdfstore_flat_store_store(me->p_connections, key, data);
		if (err != 0) {
			if (err != FLAT_STORE_E_KEYEXIST) {
				perror("rdfstore_remove");
				fprintf(stderr,"Could not store '%d' bytes for predicate in p_connections table for store '%s': %s\n", (int)data.size, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->p_connections));
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
				rdfstore_iterator_close(reindex);
#endif
				return -1;
				};
			};

#ifdef RDFSTORE_DEBUG_CONNECTIONS
		printf("(remove)REINDEXING object '%s' for connections to subjects('%s') node in st_id=%d\n",(neighbour->object->type==1) ? neighbour->object->value.literal.string : neighbour->object->value.resource.identifier,(statement->object->type==1) ? statement->object->value.literal.string : statement->object->value.resource.identifier,st_id);
#endif
		neighbour->object->hashcode = rdfstore_digest_get_node_hashCode(neighbour->object, 0);

		/* fetch o_connections(neighbour->object) */
		packInt(neighbour->object->hashcode, outbuf); /* wrong */
		key.data = outbuf;
		key.size = sizeof(int);

		err = rdfstore_flat_store_fetch(me->o_connections, key, &data);
		if (err != 0) {
			if (err != FLAT_STORE_E_NOTFOUND) {
				perror("rdfstore_remove");
				fprintf(stderr,"Could not fetch key '%s' for object in o_connections table for store '%s': %s\n", (char *)key.data, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->o_connections));
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
				rdfstore_iterator_close(reindex);
#endif
				return -1;
			} else {
				outsize_reindex = 0;
			};
		} else {
			me->func_decode_connections(data.size, data.data, &outsize_reindex, reindex_decode);
			RDFSTORE_FREE(data.data);
			};

		/* reset the corresponding bit of this statement */
		rdfstore_bits_setmask(&outsize_reindex, reindex_decode, st_id, 1, 0, sizeof(reindex_decode));

		/* store it back */
		me->func_encode_connections(outsize_reindex, reindex_decode, &outsize_reindex, reindex_encode);

		/* now: we do not need/must check whther or not to remove this key because the other statement is sitll there */

		data.data = reindex_encode;
		data.size = outsize_reindex;
		err = rdfstore_flat_store_store(me->o_connections, key, data);
		if (err != 0) {
			if (err != FLAT_STORE_E_KEYEXIST) {
				perror("rdfstore_remove");
				fprintf(stderr,"Could not store '%d' bytes for object in o_connections table for store '%s': %s\n", (int)data.size, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->o_connections));
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
				rdfstore_iterator_close(reindex);
#endif
				return -1;
				};
			};

		/* free neighbour */
                RDFSTORE_FREE( neighbour->subject->value.resource.identifier );
                RDFSTORE_FREE( neighbour->subject );
                RDFSTORE_FREE( neighbour->predicate->value.resource.identifier );
                RDFSTORE_FREE( neighbour->predicate );
                if ( neighbour->object->type == 1 ) {
                        if ( neighbour->object->value.literal.dataType != NULL )
                                RDFSTORE_FREE( neighbour->object->value.literal.dataType );
                        RDFSTORE_FREE( neighbour->object->value.literal.string );
                } else {
                        RDFSTORE_FREE( neighbour->object->value.resource.identifier );
                        };
                RDFSTORE_FREE( neighbour->object );
                if ( neighbour->context != NULL ) {
                        RDFSTORE_FREE( neighbour->context->value.resource.identifier );
                        RDFSTORE_FREE( neighbour->context );
                        };
                if ( neighbour->node != NULL ) {
                        RDFSTORE_FREE( neighbour->node->value.resource.identifier );
                        RDFSTORE_FREE( neighbour->node );
                        };
                RDFSTORE_FREE( neighbour );
		};
#endif

	/* OR subjects(OBJECT) to s_connections(SUBJECT) */
        s_outsize = rdfstore_bits_or(outsize, me->bits_decode, s_outsize, s_connections, me->bits_encode); 
        bcopy(me->bits_encode, s_connections, s_outsize);   /* slow? */

        /* fetch predicates(SUBJECT) */
        packInt(statement->subject->hashcode, outbuf);
        key.data = outbuf;
        key.size = sizeof(int);

	err = rdfstore_flat_store_fetch(me->predicates, key, &data);
        if (err != 0) {
                if (err != FLAT_STORE_E_NOTFOUND) {
                        perror("rdfstore_remove");
                        fprintf(stderr,"Could not fetch key '%s' for subject in predicates table for store '%s': %s\n", (char *)key.data, (me->name != NULL) ?  me->name : "(in-memory)", rdfstore_flat_store_get_error(me->predicates));
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
			rdfstore_iterator_close(reindex);
#endif
                        return -1;
                } else {
                        outsize = 0;
                };
        } else {
                me->func_decode(data.size, data.data, &outsize, me->bits_decode);
                RDFSTORE_FREE(data.data);
                };

#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
	/* 1.2) reindex st_id for connections to predicates(SUBJECT) node */

	/* copy the predicates(SUBJECT) bits through the reindex iterator array */
        memcpy(reindex->ids, me->bits_decode, outsize);
        reindex->ids_size = outsize;
        /* set the size - inefficient!! */
        pos = 0;
        reindex->size = 0;
        /* count the ones (inefficient still) */
        while ((pos = rdfstore_bits_getfirstsetafter(outsize, me->bits_decode, pos)) < 8 * outsize) {
                reindex->size++;
                pos++;
        	};

	/* scan the obtained iterator */
	while ( ( neighbour = rdfstore_iterator_each ( reindex ) ) != NULL ) {

#ifdef RDFSTORE_DEBUG_CONNECTIONS
		printf("(remove)REINDEXING subject '%s' for connections to predicates('%s') node in st_id=%d\n",neighbour->subject->value.resource.identifier,statement->subject->value.resource.identifier,st_id);
#endif
		neighbour->subject->hashcode = rdfstore_digest_get_node_hashCode(neighbour->subject, 0);

		/* fetch s_connections(neighbour->subject) */
		packInt(neighbour->subject->hashcode, outbuf); /* wrong */
		key.data = outbuf;
		key.size = sizeof(int);

		err = rdfstore_flat_store_fetch(me->s_connections, key, &data);
		if (err != 0) {
			if (err != FLAT_STORE_E_NOTFOUND) {
				perror("rdfstore_remove");
				fprintf(stderr,"Could not fetch key '%s' for subject in s_connections table for store '%s': %s\n", (char *)key.data, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->s_connections));
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
				rdfstore_iterator_close(reindex);
#endif
				return -1;
			} else {
				outsize_reindex = 0;
			};
		} else {
			me->func_decode_connections(data.size, data.data, &outsize_reindex, reindex_decode);
			RDFSTORE_FREE(data.data);
			};

		/* reset the corresponding bit of this statement */
		rdfstore_bits_setmask(&outsize_reindex, reindex_decode, st_id, 1, 0, sizeof(reindex_decode));

		/* store it back */
		me->func_encode_connections(outsize_reindex, reindex_decode, &outsize_reindex, reindex_encode);

		data.data = reindex_encode;
		data.size = outsize_reindex;
		err = rdfstore_flat_store_store(me->s_connections, key, data);
		if (err != 0) {
			if (err != FLAT_STORE_E_KEYEXIST) {
				perror("rdfstore_remove");
				fprintf(stderr,"Could not store '%d' bytes for subject in s_connections table for store '%s': %s\n", (int)data.size, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->s_connections));
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
				rdfstore_iterator_close(reindex);
#endif
				return -1;
				};
			};

#ifdef RDFSTORE_DEBUG_CONNECTIONS
		printf("(remove)REINDEXING object '%s' for connections to predicates('%s') node in st_id=%d\n",(neighbour->object->type==1) ? neighbour->object->value.literal.string : neighbour->object->value.resource.identifier,statement->subject->value.resource.identifier,st_id);
#endif
		neighbour->object->hashcode = rdfstore_digest_get_node_hashCode(neighbour->object, 0);

		/* fetch o_connections(neighbour->object) */
		packInt(neighbour->object->hashcode, outbuf); /* wrong */
		key.data = outbuf;
		key.size = sizeof(int);

		err = rdfstore_flat_store_fetch(me->o_connections, key, &data);
		if (err != 0) {
			if (err != FLAT_STORE_E_NOTFOUND) {
				perror("rdfstore_remove");
				fprintf(stderr,"Could not fetch key '%s' for object in o_connections table for store '%s': %s\n", (char *)key.data, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->o_connections));
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
				rdfstore_iterator_close(reindex);
#endif
				return -1;
			} else {
				outsize_reindex = 0;
			};
		} else {
			me->func_decode_connections(data.size, data.data, &outsize_reindex, reindex_decode);
			RDFSTORE_FREE(data.data);
			};

		/* reset the corresponding bit of this statement */
		rdfstore_bits_setmask(&outsize_reindex, reindex_decode, st_id, 1, 0, sizeof(reindex_decode));

		/* store it back */
		me->func_encode_connections(outsize_reindex, reindex_decode, &outsize_reindex, reindex_encode);

		data.data = reindex_encode;
		data.size = outsize_reindex;
		err = rdfstore_flat_store_store(me->o_connections, key, data);
		if (err != 0) {
			if (err != FLAT_STORE_E_KEYEXIST) {
				perror("rdfstore_remove");
				fprintf(stderr,"Could not store '%d' bytes for object in o_connections table for store '%s': %s\n", (int)data.size, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->o_connections));
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
				rdfstore_iterator_close(reindex);
#endif
				return -1;
				};
			};

		/* free neighbour */
                RDFSTORE_FREE( neighbour->subject->value.resource.identifier );
                RDFSTORE_FREE( neighbour->subject );
                RDFSTORE_FREE( neighbour->predicate->value.resource.identifier );
                RDFSTORE_FREE( neighbour->predicate );
                if ( neighbour->object->type == 1 ) {
                        if ( neighbour->object->value.literal.dataType != NULL )
                                RDFSTORE_FREE( neighbour->object->value.literal.dataType );
                        RDFSTORE_FREE( neighbour->object->value.literal.string );
                } else {
                        RDFSTORE_FREE( neighbour->object->value.resource.identifier );
                        };
                RDFSTORE_FREE( neighbour->object );
                if ( neighbour->context != NULL ) {
                        RDFSTORE_FREE( neighbour->context->value.resource.identifier );
                        RDFSTORE_FREE( neighbour->context );
                        };
                if ( neighbour->node != NULL ) {
                        RDFSTORE_FREE( neighbour->node->value.resource.identifier );
                        RDFSTORE_FREE( neighbour->node );
                        };
                RDFSTORE_FREE( neighbour );
		};
#endif

        /* OR predicates(SUBJECT) to p_connections(PREDICATE) */
        p_outsize = rdfstore_bits_or(outsize, me->bits_decode, p_outsize, p_connections, me->bits_encode); 
        bcopy(me->bits_encode, p_connections, p_outsize);   /* slow? */

        /* fetch predicates(OBJECT) */
        packInt(statement->object->hashcode, outbuf);
        key.data = outbuf;
        key.size = sizeof(int);

	err = rdfstore_flat_store_fetch(me->predicates, key, &data);
        if (err != 0) {
                if (err != FLAT_STORE_E_NOTFOUND) {
                        perror("rdfstore_remove");
                        fprintf(stderr,"Could not fetch key '%s' for object in predicates table for store '%s': %s\n", (char *)key.data, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->predicates));
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
			rdfstore_iterator_close(reindex);
#endif
                        return -1;
                } else {
                        outsize = 0;
                };
        } else {
                me->func_decode(data.size, data.data, &outsize, me->bits_decode);
                RDFSTORE_FREE(data.data);
                };

#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
        /* 3.2) reindex st_id for connections to predicates(OBJECT) node */

	/* copy the predicates(OBJECT) bits through the reindex iterator array */
        memcpy(reindex->ids, me->bits_decode, outsize);
        reindex->ids_size = outsize;
        /* set the size - inefficient!! */
        pos = 0;
        reindex->size = 0;
        /* count the ones (inefficient still) */
        while ((pos = rdfstore_bits_getfirstsetafter(outsize, me->bits_decode, pos)) < 8 * outsize) {
                reindex->size++;
                pos++;
        	};

	/* scan the obtained iterator */
	while ( ( neighbour = rdfstore_iterator_each ( reindex ) ) != NULL ) {

#ifdef RDFSTORE_DEBUG_CONNECTIONS
		printf("(remove)REINDEXING subject '%s' for connections to predicates('%s') node in st_id=%d\n",neighbour->subject->value.resource.identifier,(statement->object->type==1) ? statement->object->value.literal.string : statement->object->value.resource.identifier,st_id);
#endif
		neighbour->subject->hashcode = rdfstore_digest_get_node_hashCode(neighbour->subject, 0);

		/* fetch s_connections(neighbour->subject) */
		packInt(neighbour->subject->hashcode, outbuf); /* wrong */
		key.data = outbuf;
		key.size = sizeof(int);

		err = rdfstore_flat_store_fetch(me->s_connections, key, &data);
		if (err != 0) {
			if (err != FLAT_STORE_E_NOTFOUND) {
				perror("rdfstore_remove");
				fprintf(stderr,"Could not fetch key '%s' for subject in s_connections table for store '%s': %s\n", (char *)key.data, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->s_connections));
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
				rdfstore_iterator_close(reindex);
#endif
				return -1;
			} else {
				outsize_reindex = 0;
			};
		} else {
			me->func_decode_connections(data.size, data.data, &outsize_reindex, reindex_decode);
			RDFSTORE_FREE(data.data);
			};

		/* reset the corresponding bit of this statement */
		rdfstore_bits_setmask(&outsize_reindex, reindex_decode, st_id, 1, 0, sizeof(reindex_decode));

		/* store it back */
		me->func_encode_connections(outsize_reindex, reindex_decode, &outsize_reindex, reindex_encode);

		data.data = reindex_encode;
		data.size = outsize_reindex;
		err = rdfstore_flat_store_store(me->s_connections, key, data);
		if (err != 0) {
			if (err != FLAT_STORE_E_KEYEXIST) {
				perror("rdfstore_remove");
				fprintf(stderr,"Could not store '%d' bytes for subject in s_connections table for store '%s': %s\n", (int)data.size, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->s_connections));
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
				rdfstore_iterator_close(reindex);
#endif
				return -1;
				};
			};

#ifdef RDFSTORE_DEBUG_CONNECTIONS
		printf("(remove)REINDEXING object '%s' for connections to predicates('%s') node in st_id=%d\n",(neighbour->object->type==1) ? neighbour->object->value.literal.string : neighbour->object->value.resource.identifier,(statement->object->type==1) ? statement->object->value.literal.string : statement->object->value.resource.identifier,st_id);
#endif
		neighbour->object->hashcode = rdfstore_digest_get_node_hashCode(neighbour->object, 0);

		/* fetch o_connections(neighbour->object) */
		packInt(neighbour->object->hashcode, outbuf); /* wrong */
		key.data = outbuf;
		key.size = sizeof(int);

		err = rdfstore_flat_store_fetch(me->o_connections, key, &data);
		if (err != 0) {
			if (err != FLAT_STORE_E_NOTFOUND) {
				perror("rdfstore_remove");
				fprintf(stderr,"Could not fetch key '%s' for object in o_connections table for store '%s': %s\n", (char *)key.data, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->o_connections));
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
				rdfstore_iterator_close(reindex);
#endif
				return -1;
			} else {
				outsize_reindex = 0;
			};
		} else {
			me->func_decode_connections(data.size, data.data, &outsize_reindex, reindex_decode);
			RDFSTORE_FREE(data.data);
			};

		/* reset the corresponding bit of this statement */
		rdfstore_bits_setmask(&outsize_reindex, reindex_decode, st_id, 1, 0, sizeof(reindex_decode));

		/* store it back */
		me->func_encode_connections(outsize_reindex, reindex_decode, &outsize_reindex, reindex_encode);

		data.data = reindex_encode;
		data.size = outsize_reindex;
		err = rdfstore_flat_store_store(me->o_connections, key, data);
		if (err != 0) {
			if (err != FLAT_STORE_E_KEYEXIST) {
				perror("rdfstore_remove");
				fprintf(stderr,"Could not store '%d' bytes for object in o_connections table for store '%s': %s\n", (int)data.size, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->o_connections));
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
				rdfstore_iterator_close(reindex);
#endif
				return -1;
				};
			};

		/* free neighbour */
                RDFSTORE_FREE( neighbour->subject->value.resource.identifier );
                RDFSTORE_FREE( neighbour->subject );
                RDFSTORE_FREE( neighbour->predicate->value.resource.identifier );
                RDFSTORE_FREE( neighbour->predicate );
                if ( neighbour->object->type == 1 ) {
                        if ( neighbour->object->value.literal.dataType != NULL )
                                RDFSTORE_FREE( neighbour->object->value.literal.dataType );
                        RDFSTORE_FREE( neighbour->object->value.literal.string );
                } else {
                        RDFSTORE_FREE( neighbour->object->value.resource.identifier );
                        };
                RDFSTORE_FREE( neighbour->object );
                if ( neighbour->context != NULL ) {
                        RDFSTORE_FREE( neighbour->context->value.resource.identifier );
                        RDFSTORE_FREE( neighbour->context );
                        };
                if ( neighbour->node != NULL ) {
                        RDFSTORE_FREE( neighbour->node->value.resource.identifier );
                        RDFSTORE_FREE( neighbour->node );
                        };
                RDFSTORE_FREE( neighbour );
		};
#endif

        /* OR predicates(OBJECT) to p_connections(PREDICATE) */
        p_outsize = rdfstore_bits_or(outsize, me->bits_decode, p_outsize, p_connections, me->bits_encode); 
        bcopy(me->bits_encode, p_connections, p_outsize);   /* slow? */

        /* fetch objects(SUBJECT) */
        packInt(statement->subject->hashcode, outbuf);
        key.data = outbuf;
        key.size = sizeof(int);

	err = rdfstore_flat_store_fetch(me->objects, key, &data);
        if (err != 0) {
                if (err != FLAT_STORE_E_NOTFOUND) {
                        perror("rdfstore_remove");
                        fprintf(stderr,"Could not fetch key '%s' for subject in objects table for store '%s': %s\n", (char *)key.data, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->objects));
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
			rdfstore_iterator_close(reindex);
#endif
                        return -1;
                } else {
                        outsize = 0;
                };
        } else {
                me->func_decode(data.size, data.data, &outsize, me->bits_decode);
                RDFSTORE_FREE(data.data);
                };

#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
        /* 1.3) reindex st_id for connections to objects(SUBJECT) node */

	/* copy the objects(SUBJECT) bits through the reindex iterator array */
        memcpy(reindex->ids, me->bits_decode, outsize);
        reindex->ids_size = outsize;
        /* set the size - inefficient!! */
        pos = 0;
        reindex->size = 0;
        /* count the ones (inefficient still) */
        while ((pos = rdfstore_bits_getfirstsetafter(outsize, me->bits_decode, pos)) < 8 * outsize) {
                reindex->size++;
                pos++;
        	};

	/* scan the obtained iterator */
	while ( ( neighbour = rdfstore_iterator_each ( reindex ) ) != NULL ) {

#ifdef RDFSTORE_DEBUG_CONNECTIONS
		printf("(remove)REINDEXING subject '%s' for connections to objects('%s') node in st_id=%d\n",neighbour->subject->value.resource.identifier,statement->subject->value.resource.identifier,st_id);
#endif
		neighbour->subject->hashcode = rdfstore_digest_get_node_hashCode(neighbour->subject, 0);

		/* fetch s_connections(neighbour->subject) */
		packInt(neighbour->subject->hashcode, outbuf); /* wrong */
		key.data = outbuf;
		key.size = sizeof(int);

		err = rdfstore_flat_store_fetch(me->s_connections, key, &data);
		if (err != 0) {
			if (err != FLAT_STORE_E_NOTFOUND) {
				perror("rdfstore_remove");
				fprintf(stderr,"Could not fetch key '%s' for subject in s_connections table for store '%s': %s\n", (char *)key.data, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->s_connections));
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
				rdfstore_iterator_close(reindex);
#endif
				return -1;
			} else {
				outsize_reindex = 0;
			};
		} else {
			me->func_decode_connections(data.size, data.data, &outsize_reindex, reindex_decode);
			RDFSTORE_FREE(data.data);
			};

		/* reset the corresponding bit of this statement */
		rdfstore_bits_setmask(&outsize_reindex, reindex_decode, st_id, 1, 0, sizeof(reindex_decode));

		/* store it back */
		me->func_encode_connections(outsize_reindex, reindex_decode, &outsize_reindex, reindex_encode);

		data.data = reindex_encode;
		data.size = outsize_reindex;
		err = rdfstore_flat_store_store(me->s_connections, key, data);
		if (err != 0) {
			if (err != FLAT_STORE_E_KEYEXIST) {
				perror("rdfstore_remove");
				fprintf(stderr,"Could not store '%d' bytes for subject in s_connections table for store '%s': %s\n", (int)data.size, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->s_connections));
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
				rdfstore_iterator_close(reindex);
#endif
				return -1;
				};
			};

#ifdef RDFSTORE_DEBUG_CONNECTIONS
		printf("(remove)REINDEXING predicate '%s' for connections to objects('%s') node in st_id=%d\n",neighbour->predicate->value.resource.identifier,statement->subject->value.resource.identifier,st_id);
#endif
		neighbour->predicate->hashcode = rdfstore_digest_get_node_hashCode(neighbour->predicate, 0);

		/* fetch p_connections(neighbour->predicate) */
		packInt(neighbour->predicate->hashcode, outbuf); /* wrong */
		key.data = outbuf;
		key.size = sizeof(int);

		err = rdfstore_flat_store_fetch(me->p_connections, key, &data);
		if (err != 0) {
			if (err != FLAT_STORE_E_NOTFOUND) {
				perror("rdfstore_remove");
				fprintf(stderr,"Could not fetch key '%s' for predicate in p_connections table for store '%s': %s\n", (char *)key.data, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->p_connections));
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
				rdfstore_iterator_close(reindex);
#endif
				return -1;
			} else {
				outsize_reindex = 0;
			};
		} else {
			me->func_decode_connections(data.size, data.data, &outsize_reindex, reindex_decode);
			RDFSTORE_FREE(data.data);
			};

		/* reset the corresponding bit of this statement */
		rdfstore_bits_setmask(&outsize_reindex, reindex_decode, st_id, 1, 0, sizeof(reindex_decode));

		/* store it back */
		me->func_encode_connections(outsize_reindex, reindex_decode, &outsize_reindex, reindex_encode);

		data.data = reindex_encode;
		data.size = outsize_reindex;
		err = rdfstore_flat_store_store(me->p_connections, key, data);
		if (err != 0) {
			if (err != FLAT_STORE_E_KEYEXIST) {
				perror("rdfstore_remove");
				fprintf(stderr,"Could not store '%d' bytes for predicate in p_connections table for store '%s': %s\n", (int)data.size, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->p_connections));
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
				rdfstore_iterator_close(reindex);
#endif
				return -1;
				};
			};

		/* free neighbour */
                RDFSTORE_FREE( neighbour->subject->value.resource.identifier );
                RDFSTORE_FREE( neighbour->subject );
                RDFSTORE_FREE( neighbour->predicate->value.resource.identifier );
                RDFSTORE_FREE( neighbour->predicate );
                if ( neighbour->object->type == 1 ) {
                        if ( neighbour->object->value.literal.dataType != NULL )
                                RDFSTORE_FREE( neighbour->object->value.literal.dataType );
                        RDFSTORE_FREE( neighbour->object->value.literal.string );
                } else {
                        RDFSTORE_FREE( neighbour->object->value.resource.identifier );
                        };
                RDFSTORE_FREE( neighbour->object );
                if ( neighbour->context != NULL ) {
                        RDFSTORE_FREE( neighbour->context->value.resource.identifier );
                        RDFSTORE_FREE( neighbour->context );
                        };
                if ( neighbour->node != NULL ) {
                        RDFSTORE_FREE( neighbour->node->value.resource.identifier );
                        RDFSTORE_FREE( neighbour->node );
                        };
                RDFSTORE_FREE( neighbour );
		};
#endif

        /* OR objects(SUBJECT) to o_connections(OBJECT) */
        o_outsize = rdfstore_bits_or(outsize, me->bits_decode, o_outsize, o_connections, me->bits_encode); 
        bcopy(me->bits_encode, o_connections, o_outsize);   /* slow? */

        /* fetch objects(PREDICATE) */
        packInt(statement->predicate->hashcode, outbuf);
        key.data = outbuf;
        key.size = sizeof(int);

	err = rdfstore_flat_store_fetch(me->objects, key, &data);
        if (err != 0) {
                if (err != FLAT_STORE_E_NOTFOUND) {
                        perror("rdfstore_remove");
                        fprintf(stderr,"Could not fetch key '%s' for predicate in objects table for store '%s': %s\n", (char *)key.data, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->objects));
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
			rdfstore_iterator_close(reindex);
#endif
                        return -1;
                } else {
                        outsize = 0;
                };
        } else {
                me->func_decode(data.size, data.data, &outsize, me->bits_decode);
                RDFSTORE_FREE(data.data);
                };

#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
        /* 2.3) reindex st_id for connections to objects(PREDICATE) node */

	/* copy the objects(PREDICATE) bits through the reindex iterator array */
        memcpy(reindex->ids, me->bits_decode, outsize);
        reindex->ids_size = outsize;
        /* set the size - inefficient!! */
        pos = 0;
        reindex->size = 0;
        /* count the ones (inefficient still) */
        while ((pos = rdfstore_bits_getfirstsetafter(outsize, me->bits_decode, pos)) < 8 * outsize) {
                reindex->size++;
                pos++;
        	};

	/* scan the obtained iterator */
	while ( ( neighbour = rdfstore_iterator_each ( reindex ) ) != NULL ) {

#ifdef RDFSTORE_DEBUG_CONNECTIONS
		printf("(remove)REINDEXING subject '%s' for connections to objects('%s') node in st_id=%d\n",neighbour->subject->value.resource.identifier,statement->predicate->value.resource.identifier,st_id);
#endif
		neighbour->subject->hashcode = rdfstore_digest_get_node_hashCode(neighbour->subject, 0);

		/* fetch s_connections(neighbour->subject) */
		packInt(neighbour->subject->hashcode, outbuf); /* wrong */
		key.data = outbuf;
		key.size = sizeof(int);

		err = rdfstore_flat_store_fetch(me->s_connections, key, &data);
		if (err != 0) {
			if (err != FLAT_STORE_E_NOTFOUND) {
				perror("rdfstore_remove");
				fprintf(stderr,"Could not fetch key '%s' for subject in s_connections table for store '%s': %s\n", (char *)key.data, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->s_connections));
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
				rdfstore_iterator_close(reindex);
#endif
				return -1;
			} else {
				outsize_reindex = 0;
			};
		} else {
			me->func_decode_connections(data.size, data.data, &outsize_reindex, reindex_decode);
			RDFSTORE_FREE(data.data);
			};

		/* reset the corresponding bit of this statement */
		rdfstore_bits_setmask(&outsize_reindex, reindex_decode, st_id, 1, 0, sizeof(reindex_decode));

		/* store it back */
		me->func_encode_connections(outsize_reindex, reindex_decode, &outsize_reindex, reindex_encode);

		data.data = reindex_encode;
		data.size = outsize_reindex;
		err = rdfstore_flat_store_store(me->s_connections, key, data);
		if (err != 0) {
			if (err != FLAT_STORE_E_KEYEXIST) {
				perror("rdfstore_remove");
				fprintf(stderr,"Could not store '%d' bytes for subject in s_connections table for store '%s': %s\n", (int)data.size, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->s_connections));
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
				rdfstore_iterator_close(reindex);
#endif
				return -1;
				};
			};

#ifdef RDFSTORE_DEBUG_CONNECTIONS
		printf("(remove)REINDEXING predicate '%s' for connections to objects('%s') node in st_id=%d\n",neighbour->predicate->value.resource.identifier,statement->predicate->value.resource.identifier,st_id);
#endif
		neighbour->predicate->hashcode = rdfstore_digest_get_node_hashCode(neighbour->predicate, 0);

		/* fetch p_connections(neighbour->predicate) */
		packInt(neighbour->predicate->hashcode, outbuf); /* wrong */
		key.data = outbuf;
		key.size = sizeof(int);

		err = rdfstore_flat_store_fetch(me->p_connections, key, &data);
		if (err != 0) {
			if (err != FLAT_STORE_E_NOTFOUND) {
				perror("rdfstore_remove");
				fprintf(stderr,"Could not fetch key '%s' for predicate in p_connections table for store '%s': %s\n", (char *)key.data, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->p_connections));
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
				rdfstore_iterator_close(reindex);
#endif
				return -1;
			} else {
				outsize_reindex = 0;
			};
		} else {
			me->func_decode_connections(data.size, data.data, &outsize_reindex, reindex_decode);
			RDFSTORE_FREE(data.data);
			};

		/* reset the corresponding bit of this statement */
		rdfstore_bits_setmask(&outsize_reindex, reindex_decode, st_id, 1, 0, sizeof(reindex_decode));

		/* store it back */
		me->func_encode_connections(outsize_reindex, reindex_decode, &outsize_reindex, reindex_encode);

		data.data = reindex_encode;
		data.size = outsize_reindex;
		err = rdfstore_flat_store_store(me->p_connections, key, data);
		if (err != 0) {
			if (err != FLAT_STORE_E_KEYEXIST) {
				perror("rdfstore_remove");
				fprintf(stderr,"Could not store '%d' bytes for predicate in p_connections table for store '%s': %s\n", (int)data.size, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->p_connections));
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
				rdfstore_iterator_close(reindex);
#endif
				return -1;
				};
			};

		/* free neighbour */
                RDFSTORE_FREE( neighbour->subject->value.resource.identifier );
                RDFSTORE_FREE( neighbour->subject );
                RDFSTORE_FREE( neighbour->predicate->value.resource.identifier );
                RDFSTORE_FREE( neighbour->predicate );
                if ( neighbour->object->type == 1 ) {
                        if ( neighbour->object->value.literal.dataType != NULL )
                                RDFSTORE_FREE( neighbour->object->value.literal.dataType );
                        RDFSTORE_FREE( neighbour->object->value.literal.string );
                } else {
                        RDFSTORE_FREE( neighbour->object->value.resource.identifier );
                        };
                RDFSTORE_FREE( neighbour->object );
                if ( neighbour->context != NULL ) {
                        RDFSTORE_FREE( neighbour->context->value.resource.identifier );
                        RDFSTORE_FREE( neighbour->context );
                        };
                if ( neighbour->node != NULL ) {
                        RDFSTORE_FREE( neighbour->node->value.resource.identifier );
                        RDFSTORE_FREE( neighbour->node );
                        };
                RDFSTORE_FREE( neighbour );
		};
#endif

        /* OR objects(PREDICATE) to o_connections(OBJECT) */
        o_outsize = rdfstore_bits_or(outsize, me->bits_decode, o_outsize, o_connections, me->bits_encode); 
        bcopy(me->bits_encode, o_connections, o_outsize);   /* slow? */

	/* SUBJECT - reset the right bits for s_connections - we need to AND s_connections(SUBJECT) with generated s_connections and store */

        /* fetch s_connections(SUBJECT) */
        packInt(statement->subject->hashcode, outbuf);
        key.data = outbuf;
        key.size = sizeof(int);

	err = rdfstore_flat_store_fetch(me->s_connections, key, &data);
	if (err != 0) {
               	if (err != FLAT_STORE_E_NOTFOUND) {
                       	perror("rdfstore_remove");
                       	fprintf(stderr,"Could not fetch key '%s' for subject in s_connections for store '%s': %s\n", (char *)key.data, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->s_connections));
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
			rdfstore_iterator_close(reindex);
#endif
			return -1;
		} else {
                       	outsize = 0;
               		};
        } else {
               	me->func_decode_connections(data.size, data.data, &outsize, me->bits_decode);
               	RDFSTORE_FREE(data.data);
		};

	/* AND s_connections(SUBJECT) to generated s_connections */
        outsize = rdfstore_bits_and(outsize, me->bits_decode, s_outsize, s_connections, me->bits_encode); 
        bcopy(me->bits_encode, me->bits_decode, outsize);   /* slow? */

	outsize = rdfstore_bits_shorten(outsize, me->bits_decode);
	if ( outsize > 0 ) {
		me->func_encode_connections(outsize, me->bits_decode, &outsize, me->bits_encode);
		if (outsize) {
			data.data = me->bits_encode;
			data.size = outsize;
			err = rdfstore_flat_store_store(me->s_connections, key, data);
			if (err == 0) {
#ifdef RDFSTORE_DEBUG_COMPRESSION
				fprintf(stderr,"Stored %d bytes for '%s' in s_connections for store '%s'\n", outsize, (char *)key.data, (me->name != NULL) ? me->name : "(in-memory)");
#endif
			} else {
				if (err != FLAT_STORE_E_KEYEXIST) {
					perror("rdfstore_remove");
					fprintf(stderr,"Could not store '%d' bytes for subject in s_connections for store '%s': %s\n", (int)data.size, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->s_connections));
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
					rdfstore_iterator_close(reindex);
#endif
					return -1;
				};
			};

#ifdef RDFSTORE_DEBUG
			{
			int             i=0;
			if ((rdfstore_flat_store_fetch(me->s_connections, key, &data)) == 0) {
				me->func_decode_connections(data.size, data.data, &outsize, me->bits_decode);
				RDFSTORE_FREE(data.data);
				};
			printf("REMOVED st_num=%d bitno=%d s_connections for S '%s' -->'", st_id, st_id,statement->subject->value.resource.identifier);
			for(i=0;i<8*outsize;i++) {
				printf("Rec %d %c\n", i, (me->bits_decode[i>>3] & (1<<(i&7))) ? '1':'0');
                                       };
			printf("'\n");
			}
#endif

			};
	} else {
		err = rdfstore_flat_store_delete(me->s_connections, key);
		if (err != 0) {
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
                        rdfstore_iterator_close(reindex);
#endif
                        if (err != FLAT_STORE_E_NOTFOUND) {
				perror("rdfstore_remove");
                        	fprintf(stderr,"Could not delete statement for store '%s': %s\n", (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->s_connections));
                        	return -1;
			} else {
				return 1;
				};
                        };
#ifdef RDFSTORE_DEBUG
		printf("DELETED (%d) s_connections for S '%s'\n", st_id,statement->subject->value.resource.identifier);
#endif
		};

	/* PREDICATE - reset the right bits for p_connections - we need to AND p_connections(PREDICATE) with generated p_connections and store */

        /* fetch p_connections(PREDICATE) */
	packInt(statement->predicate->hashcode, outbuf);
        key.data = outbuf;
	key.size = sizeof(int);

        err = rdfstore_flat_store_fetch(me->p_connections, key, &data);
	if (err != 0) {
		if (err != FLAT_STORE_E_NOTFOUND) {
			perror("rdfstore_remove");
			fprintf(stderr,"Could not fetch key '%s' for predicate in p_connections for store '%s': %s\n", (char *)key.data, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->p_connections));
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
			rdfstore_iterator_close(reindex);
#endif
			return -1;
		} else {
			outsize = 0;
			};
        } else {
               	me->func_decode_connections(data.size, data.data, &outsize, me->bits_decode);       
               	RDFSTORE_FREE(data.data);
		};

	/* AND p_connections(PREDICATE) to generated p_connections */
        outsize = rdfstore_bits_and(outsize, me->bits_decode, p_outsize, p_connections, me->bits_encode);  
        bcopy(me->bits_encode, me->bits_decode, outsize);   /* slow? */

        outsize = rdfstore_bits_shorten(outsize, me->bits_decode);
	if ( outsize > 0 ) {
		me->func_encode_connections(outsize, me->bits_decode, &outsize, me->bits_encode);
		if (outsize) {
			data.data = me->bits_encode;
			data.size = outsize;
			err = rdfstore_flat_store_store(me->p_connections, key, data);
			if (err == 0) {
#ifdef RDFSTORE_DEBUG_COMPRESSION
				fprintf(stderr,"Stored %d bytes for '%s' in p_connections for store '%s'\n", outsize, (char *)key.data, (me->name != NULL) ? me->name : "(in-memory)");
#endif
			} else {
				if (err != FLAT_STORE_E_KEYEXIST) {
					perror("rdfstore_remove");
					fprintf(stderr,"Could not store '%d' bytes for predicate in p_connections for store '%s': %s\n", (int)data.size, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->p_connections));
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
					rdfstore_iterator_close(reindex);
#endif
					return -1;
					};
				};

#ifdef RDFSTORE_DEBUG
			{
			int             i=0;
			if ((rdfstore_flat_store_fetch(me->p_connections, key, &data)) == 0) {
				me->func_decode_connections(data.size, data.data, &outsize, me->bits_decode);
				RDFSTORE_FREE(data.data);
				};
			printf("REMOVED st_num=%d bitno=%d p_connections for P '%s' -->'", st_id, st_id, statement->predicate->value.resource.identifier);
			for(i=0;i<8*outsize;i++) {
				printf("Rec %d %c\n", i, (me->bits_decode[i>>3] & (1<<(i&7))) ? '1':'0');
                                      };
			printf("'\n");
			}
#endif

			};
	} else {
		err = rdfstore_flat_store_delete(me->p_connections, key);
		if (err != 0) {
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
                        rdfstore_iterator_close(reindex);
#endif
                        if (err != FLAT_STORE_E_NOTFOUND) {
				perror("rdfstore_remove");
                        	fprintf(stderr,"Could not delete statement for store '%s': %s\n", (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->p_connections));
                        	return -1;
			} else {
				return 1;
				};
                        };
#ifdef RDFSTORE_DEBUG
		printf("DELETED (%d) p_connections for P '%s'\n", st_id,statement->predicate->value.resource.identifier);
#endif
		};

	/* OBJECT - reset the right bits for o_connections - we need to AND o_connections(OBJECT) with generated o_connections and store */

        /* fetch o_connections(OBJECT) */
	packInt(statement->object->hashcode, outbuf);
        key.data = outbuf;
	key.size = sizeof(int);

        err = rdfstore_flat_store_fetch_compressed(me->o_connections, me->func_decode_connections, key, &outsize, me->bits_decode);
	if (err != 0) {
		if (err != FLAT_STORE_E_NOTFOUND) {
			perror("rdfstore_remove");
			fprintf(stderr,"Could not fetch key '%s' for object in o_connections for store '%s': %s\n", (char *)key.data, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->o_connections));
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
			rdfstore_iterator_close(reindex);
#endif
			return -1;
		} else {
			outsize = 0;
			};
		};

	/* AND o_connections(OBJECT) to generated o_connections */
        outsize = rdfstore_bits_and(outsize, me->bits_decode, o_outsize, o_connections, me->bits_encode);  
        bcopy(me->bits_encode, me->bits_decode, outsize);   /* slow? */

	outsize = rdfstore_bits_shorten(outsize, me->bits_decode);
	if ( outsize > 0 ) {
		if (outsize) {
			err = rdfstore_flat_store_store_compressed(me->o_connections, me->func_encode_connections, 
				key, outsize, me->bits_decode, me->bits_encode);

			if (err == 0) {
#ifdef RDFSTORE_DEBUG_COMPRESSION
				fprintf(stderr,"Stored %d bytes for '%s' in o_connections for store '%s'\n", outsize, (char *)key.data, (me->name != NULL) ? me->name : "(in-memory)");
#endif
			} else {
				if (err != FLAT_STORE_E_KEYEXIST) {
					perror("rdfstore_remove");
					fprintf(stderr,"Could not store '%d' bytes for object in o_connections for store '%s': %s\n", (int)data.size, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->o_connections));
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
					rdfstore_iterator_close(reindex);
#endif
					return -1;
					};
				};

#ifdef RDFSTORE_DEBUG
			{
			int             i=0;
			if ((rdfstore_flat_store_fetch(me->o_connections, key, &data)) == 0) {
				me->func_decode_connections(data.size, data.data, &outsize, me->bits_decode);
				RDFSTORE_FREE(data.data);
				};
			printf("REMOVED st_num=%d bitno=%d o_connections for O '%s' -->'", st_id, st_id, (statement->object->type != 1) ? statement->object->value.resource.identifier : statement->object->value.literal.string);
			for(i=0;i<8*outsize;i++) {
				printf("Rec %d %c\n", i, (me->bits_decode[i>>3] & (1<<(i&7))) ? '1':'0');
                                       };
			printf("'\n");
			}
#endif

			};
	} else {
		err = rdfstore_flat_store_delete(me->o_connections, key);
		if (err != 0) {
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
                        rdfstore_iterator_close(reindex);
#endif
                        if (err != FLAT_STORE_E_NOTFOUND) {
				perror("rdfstore_remove");
                        	fprintf(stderr,"Could not delete statement for store '%s': %s\n", (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->o_connections));
                        	return -1;
			} else {
				return 1;
				};
                        };
#ifdef RDFSTORE_DEBUG
		printf("DELETED (%d) o_connections for O '%s'\n", st_id, (statement->object->type != 1) ? statement->object->value.resource.identifier : statement->object->value.literal.string);
#endif
		};

#endif /* RDFSTORE_CONNECTIONS */

	if (context != NULL) {
		/* context */
		packInt(context->hashcode, outbuf);
		key.data = outbuf;
		key.size = sizeof(int);

		/*
		 * bzero(me->bits_encode,sizeof(me->bits_encode));
		 * bzero(me->bits_decode,sizeof(me->bits_decode));
		 */

		err = rdfstore_flat_store_fetch_compressed(me->contexts, me->func_decode, key, &outsize, me->bits_decode);
		if (err != 0) {
			if (err != FLAT_STORE_E_NOTFOUND) {
				perror("rdfstore_remove");
				fprintf(stderr,"Could not fetch key '%s' in contexts for store '%s': %s\n", (char *)key.data, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->contexts));
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
				rdfstore_iterator_close(reindex);
#endif
				return -1;
			} else {
				outsize = 0;
			};
		};

		/* reset the right bit to zero */
		rdfstore_bits_setmask(&outsize, me->bits_decode, st_id, 1, 0, sizeof(me->bits_decode));
		outsize = rdfstore_bits_shorten(outsize, me->bits_decode);
		if ( outsize > 0 ) {
			err = rdfstore_flat_store_store_compressed(me->contexts, me->func_encode,
				key, outsize,me->bits_decode,me->bits_encode);
			if (err == 0) {
#ifdef RDFSTORE_DEBUG_COMPRESSION
				fprintf(stderr,"Stored %d bytes for '%s' in contexts for store '%s'\n", outsize, (char *)key.data, (me->name != NULL) ? me->name : "(in-memory)");
#endif
			} else {
				if (err != FLAT_STORE_E_KEYEXIST) {
					perror("rdfstore_remove");
					fprintf(stderr,"Could not store '%d' bytes in contexts for store '%s': %s\n", (int)data.size, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->contexts));
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
					rdfstore_iterator_close(reindex);
#endif
					return -1;
					};
				};

#ifdef RDFSTORE_DEBUG
				{
				int             i;
				if ((rdfstore_flat_store_fetch(me->contexts, key, &data)) == 0) {
					me->func_decode(data.size, data.data, &outsize, me->bits_decode);
					RDFSTORE_FREE(data.data);
				};
				printf("REMOVED st_num=%d bitno=%d contexts for C -->'", st_id, st_id);
				for(i=0;i<8*outsize;i++) {
					printf("Rec %d %c\n", i, (me->bits_decode[i>>3] & (1<<(i&7))) ? '1':'0');
                                               };
				printf("'\n");
				}
#endif
		} else {
			err = rdfstore_flat_store_delete(me->contexts, key);
			if (err != 0) {
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
                        	rdfstore_iterator_close(reindex);
#endif
				if (err != FLAT_STORE_E_NOTFOUND) {
                        		perror("rdfstore_remove");
                        		fprintf(stderr,"Could not delete statement for store '%s': %s\n", (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->contexts));
                        		return -1;
				} else {
					return 1;
					};
                        	};
#ifdef RDFSTORE_DEBUG
			printf("DELETED (%d) contexts for C\n", st_id);
#endif
		};
	};

	/* remove special literal stuff */
	if (statement->object->type == 1) {
		if (	(me->freetext) &&
		    	(statement->object->value.literal.string != NULL) &&
			(statement->object->value.literal.string_len > 0) ) {
			utf8_casefolded_buff = (unsigned char *)RDFSTORE_MALLOC(statement->object->value.literal.string_len * sizeof(unsigned char) * (RDFSTORE_UTF8_MAXLEN_FOLD + 1));	/* what about the ending '\0' here ?? */
			if (utf8_casefolded_buff == NULL) {
				perror("rdfstore_remove");
				fprintf(stderr,"Cannot compute case-folded string out of input literal for store '%s'\n", (me->name != NULL) ? me->name : "(in-memory)");
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
				rdfstore_iterator_close(reindex);
#endif
				return -1;
				};
			if (rdfstore_utf8_string_to_utf8_foldedcase(statement->object->value.literal.string_len, statement->object->value.literal.string, &utf8_size, utf8_casefolded_buff)) {
				perror("rdfstore_remove");
				fprintf(stderr,"Cannot compute case-folded string out of input literal for store '%s'\n", (me->name != NULL) ? me->name : "(in-memory)");
				RDFSTORE_FREE(utf8_casefolded_buff);
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
				rdfstore_iterator_close(reindex);
#endif
				return -1;
				};

			for (	word = strtok(utf8_casefolded_buff, sep);
		     		word;
		     		word = strtok(NULL, sep) ) {
				int jj=0;
				int kk=0;

				key.data = word;
				key.size = strlen(word);
				err = rdfstore_flat_store_fetch_compressed(me->windex, me->func_decode, key, &outsize, me->bits_decode);
				if (err != 0) {
					if (err != FLAT_STORE_E_NOTFOUND) {
						RDFSTORE_FREE(utf8_casefolded_buff);
						perror("rdfstore_remove");
						fprintf(stderr,"Could not fetch windex of word '%s' for store '%s': %s\n", word, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->windex));
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
						rdfstore_iterator_close(reindex);
#endif
						return -1;
					} else {
						outsize = 0;
						};
					};

				/*
				NOTE: perhaps the code below should be substituted as in the above other single-bit tables with

				rdfstore_bits_setmask(&outsize, me->bits_decode, st_id, 1, 0, sizeof(me->bits_decode));

                		outsize = rdfstore_bits_shorten(outsize, me->bits_decode);
				*/

				/*
			 	 * match stuff for literal words - we have one bit
			 	 * only for free-text then we use
			 	 * rdfstore_bits_getfirstsetafter()
			 	*/
				pos = 0;
				if ((pos = rdfstore_bits_getfirstsetafter(outsize, me->bits_decode, pos)) < outsize * 8)	/* matched once */
					pos++;	/* hop to the next record */
				if ((pos < outsize * 8) &&
			    		((pos = rdfstore_bits_getfirstsetafter(outsize, me->bits_decode, pos)) < outsize * 8)) {	/* matched more the one
															 * record */
#ifdef RDFSTORE_DEBUG
					fprintf(stderr,"object literal word '%s' matched TWICE at pos=%d\n", word, pos);
#endif
					/* reset the right bit to zero */
					rdfstore_bits_setmask(&outsize, me->bits_decode, st_id, 1, 0, sizeof(me->bits_decode));
					if (outsize) {
						err = rdfstore_flat_store_store_compressed(me->windex, me->func_encode,key, outsize, me->bits_decode,me->bits_encode);
						if (err == 0) {
#ifdef RDFSTORE_DEBUG_COMPRESSION
							fprintf(stderr,"Stored %d bytes for '%s' in windex for store '%s'\n", outsize, (char *)key.data, (me->name != NULL) ? me->name : "(in-memory)");
#endif
						} else {
							if (err != FLAT_STORE_E_KEYEXIST) {
								RDFSTORE_FREE(utf8_casefolded_buff);
								perror("rdfstore_remove");
								fprintf(stderr,"Could not store '%d' bytes for word '%s' in windex for store '%s': %s\n", (int)data.size, word, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->windex));
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
								rdfstore_iterator_close(reindex);
#endif
								return -1;
								};
							};

#ifdef RDFSTORE_DEBUG
						{
						int             i;
						if ((rdfstore_flat_store_fetch(me->windex, key, &data)) == 0) {
							me->func_decode(data.size, data.data, &outsize, me->bits_decode);
							RDFSTORE_FREE(data.data);
						};
						printf("REMOVED (%d) windex for case-folded word '%s' -->'", st_id, word);
						for(i=0;i<8*outsize;i++) {
							printf("Rec %d %c\n", i, (me->bits_decode[i>>3] & (1<<(i&7))) ? '1':'0');
                                                        };
						printf("'\n");
						}
#endif

						};
				} else {
					err = rdfstore_flat_store_delete(me->windex, key);
					/* 	due that words and stems can be duplicated into the same literal we 
						do not check if FLAT_STORE_E_NOTFOUND which means several delete operation might
						be failing for the same literal - this could be avoided by checking duplicates
						of words and stems into the input string */
					if (err != 0) {
						if (err != FLAT_STORE_E_NOTFOUND) {
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
                        				rdfstore_iterator_close(reindex);
#endif
							perror("rdfstore_remove");
							fprintf(stderr,"Could not delete statement for store '%s': %s\n", (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->windex));
                        				return -1;
							};
                        			};
#ifdef RDFSTORE_DEBUG
					printf("DELETED (%d) windex for case-folded word '%s'\n", st_id, word);
#endif
					};

#if RDFSTORE_WORD_STEMMING > 0

				if(	( rdfstore_xsd_deserialize_integer( word, &thelval ) ) ||
					( rdfstore_xsd_deserialize_double( word, &thedval )  ) ||
					( rdfstore_xsd_deserialize_dateTime(	word,
										&thedateval_tm ) ) ||
					( rdfstore_xsd_deserialize_date(	word,
										&thedateval_tm ) ) || /* dates are skipped, even if rdf:datatype is not set */
					(strlen(word)<=1) )
					continue;

                        	/* for efficency we should check if the given partial stem has been already indexed for the same word!!! */
                        	jj=1;
                        	while ( ( jj < strlen(word) ) &&
                                	( kk < RDFSTORE_WORD_STEMMING ) ) {
                                	char stem[MIN((RDFSTORE_WORD_STEMMING*RDFSTORE_UTF8_MAXLEN_FOLD),strlen(word))+1];

                                	bzero(stem,MIN((RDFSTORE_WORD_STEMMING*RDFSTORE_UTF8_MAXLEN_FOLD),strlen(word))+1);

                                	/* look for next utf8 char to add to stemming string */
                                	utf8_size=0;
                                	while ( ( jj < strlen(word) ) &&
                                        	(!( rdfstore_utf8_is_utf8( word+jj, &utf8_size ) )) ) {
                                        	jj++;
                                        	};

                                	if (jj>strlen(word)) {
                                        	strncpy(stem, word, jj-1);
                                	} else {
                                        	strncpy(stem, word, jj);
                                        	};

                                	key.data = stem;
                                	key.size = strlen(stem);

					err = rdfstore_flat_store_fetch_compressed(me->windex, me->func_decode, key, &outsize, me->bits_decode);
					if (err != 0) {
						if (err != FLAT_STORE_E_NOTFOUND) {
							RDFSTORE_FREE(utf8_casefolded_buff);
							perror("rdfstore_remove");
							fprintf(stderr,"Could not fetch windex for stemming '%s' of word '%s' for store '%s': %s\n", stem, word, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->windex));
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
							rdfstore_iterator_close(reindex);
#endif
							return -1;
						} else {
							outsize = 0;
							};
						};
					/*
					NOTE: perhaps the code below should be substituted as in the above other single-bit tables with

					rdfstore_bits_setmask(&outsize, me->bits_decode, st_id, 1, 0, sizeof(me->bits_decode));

                			outsize = rdfstore_bits_shorten(outsize, me->bits_decode);
					*/

					/*
			 		 * match stuff for literal words - we have one bit
			 		 * only for free-text then we use
			 		 * rdfstore_bits_getfirstsetafter()
			 		 */
					pos = 0;
					if ((pos = rdfstore_bits_getfirstsetafter(outsize, me->bits_decode, pos)) < outsize * 8)	/* matched once */
						pos++;	/* hop to the next record */
					if ((pos < outsize * 8) &&
			    			((pos = rdfstore_bits_getfirstsetafter(outsize, me->bits_decode, pos)) < outsize * 8)) {	/* matched more the one
															 		* record */
#ifdef RDFSTORE_DEBUG
						fprintf(stderr,"object literal stem '%s' matched TWICE at pos=%d\n", word, pos);
#endif
						/* reset the right bit to zero */
						rdfstore_bits_setmask(&outsize, me->bits_decode, st_id, 1, 0, sizeof(me->bits_decode));
						if (outsize) {
							err = rdfstore_flat_store_store_compressed(me->windex, me->func_encode, 
								key, outsize, me->bits_decode, me->bits_encode);
							if (err == 0) {
#ifdef RDFSTORE_DEBUG_COMPRESSION
								fprintf(stderr,"Stored %d bytes for stemming '%s' in windex for store '%s'\n", outsize, (char *)key.data, (me->name != NULL) ? me->name : "(in-memory)");
#endif
							} else {
								if (err != FLAT_STORE_E_KEYEXIST) {
									RDFSTORE_FREE(utf8_casefolded_buff);
									perror("rdfstore_remove");
									fprintf(stderr,"Could not store '%d' bytes for stemming '%s' of word '%s' in windex for store '%s': %s\n", (int)data.size, stem, word, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->windex));
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
									rdfstore_iterator_close(reindex);
#endif
									return -1;
									};
								};

#ifdef RDFSTORE_DEBUG
							{
							int             i;
							if ((rdfstore_flat_store_fetch(me->windex, key, &data)) == 0) {
								me->func_decode(data.size, data.data, &outsize, me->bits_decode);
								RDFSTORE_FREE(data.data);
								};
							printf("REMOVED (%d) windex for case-folded stemming '%s' of word '%s' -->'", st_id, stem, word);
							for (i = 0; i < outsize; i++) {
								printf("%02X", me->bits_decode[i]);
								};
							printf("'\n");
							}
#endif

							};
					} else {
						err = rdfstore_flat_store_delete(me->windex, key);
						if (err != 0) {
							/* 	due that words and stems can be duplicated into the same literal we 
								do not check if FLAT_STORE_E_NOTFOUND which means several delete operation might
								be failing for the same literal - this could be avoided by checking duplicates
								of words and stems into the input string */
							if (err != FLAT_STORE_E_NOTFOUND) {
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
                        					rdfstore_iterator_close(reindex);
#endif
								perror("rdfstore_remove");
								fprintf(stderr,"Could not delete statement for store '%s': %s\n", (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->windex));
                        					return -1;
								};
                        				};
#ifdef RDFSTORE_DEBUG
						printf("DELETED (%d) windex for case-folded stem '%s'\n", st_id, word);
#endif
						};
					jj++;
					kk++;
					};
#endif

				};
			RDFSTORE_FREE(utf8_casefolded_buff);
			};

		/* languages table */
		if (	(statement->object->value.literal.lang != NULL) &&
			(strlen(statement->object->value.literal.lang) > 0) ) {
			utf8_casefolded_buff = (unsigned char *)RDFSTORE_MALLOC(strlen(statement->object->value.literal.lang) * sizeof(unsigned char) * (RDFSTORE_UTF8_MAXLEN_FOLD + 1));
			if (utf8_casefolded_buff == NULL) {
				perror("rdfstore_remove");
				fprintf(stderr,"Cannot compute case-folded string out of input literal language for store '%s'\n", (me->name != NULL) ? me->name : "(in-memory)");
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
				rdfstore_iterator_close(reindex);
#endif
				return -1;
				};
			if (rdfstore_utf8_string_to_utf8_foldedcase(strlen(statement->object->value.literal.lang), statement->object->value.literal.lang, &utf8_size, utf8_casefolded_buff)) {
				perror("rdfstore_remove");
				fprintf(stderr,"Cannot compute case-folded string out of input literal language for store '%s'\n", (me->name != NULL) ? me->name : "(in-memory)");
				RDFSTORE_FREE(utf8_casefolded_buff);
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
				rdfstore_iterator_close(reindex);
#endif
				return -1;
				};

			key.data = utf8_casefolded_buff;
			key.size = utf8_size;

			err = rdfstore_flat_store_fetch_compressed(me->languages, me->func_decode, key, &outsize, me->bits_decode);
			if (err != 0) {
				if (err != FLAT_STORE_E_NOTFOUND) {
					RDFSTORE_FREE(utf8_casefolded_buff);
					perror("rdfstore_remove");
					fprintf(stderr,"Could not fetch language '%s' of literal '%s' for store '%s': %s\n", statement->object->value.literal.lang, statement->object->value.literal.string, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->languages));
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
					rdfstore_iterator_close(reindex);
#endif
					return -1;
				} else {
					outsize = 0;
					};
				};

			/* reset the right bit to zero */
			rdfstore_bits_setmask(&outsize, me->bits_decode, st_id, 1, 0, sizeof(me->bits_decode));

                	outsize = rdfstore_bits_shorten(outsize, me->bits_decode);
			if (outsize) {
				err = rdfstore_flat_store_store_compressed(me->languages, me->func_encode, 
							key, outsize, me->bits_decode, me->bits_encode);
				if (err == 0) {
#ifdef RDFSTORE_DEBUG_COMPRESSION
					fprintf(stderr,"Stored %d bytes for language '%s' in languages for store '%s'\n", outsize, (char *)key.data, (me->name != NULL) ? me->name : "(in-memory)");
#endif
				} else {
					if (err != FLAT_STORE_E_KEYEXIST) {
						RDFSTORE_FREE(utf8_casefolded_buff);
						perror("rdfstore_remove");
						fprintf(stderr,"Could not store '%d' bytes for language '%s' of literal '%s' in languages for store '%s': %s\n", (int)data.size, statement->object->value.literal.lang, statement->object->value.literal.string, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->languages));
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
						rdfstore_iterator_close(reindex);
#endif
						return -1;
						};
					};

#ifdef RDFSTORE_DEBUG
				{
				int             i;
				if ((rdfstore_flat_store_fetch(me->languages, key, &data)) == 0) {
					me->func_decode(data.size, data.data, &outsize, me->bits_decode);
					RDFSTORE_FREE(data.data);
				};
				printf("REMOVED (%d) language '%s' of literal '%s' -->'", st_id, statement->object->value.literal.lang, statement->object->value.literal.string);
				for (i = 0; i < outsize; i++) {
					printf("%02X", me->bits_decode[i]);
				};
				printf("'\n");
				}
#endif
			} else {
				err = rdfstore_flat_store_delete(me->languages, key);
				if (err != 0) {
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
                        		rdfstore_iterator_close(reindex);
#endif
					if (err != FLAT_STORE_E_NOTFOUND) {
						perror("rdfstore_remove");
						fprintf(stderr,"Could not delete statement for store '%s': %s\n", (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->languages));
               					return -1;
					} else {
						return 1;
						};
               				};
#ifdef RDFSTORE_DEBUG
				printf("DELETED (%d) languages for case-folded literal language '%s'\n", st_id, statement->object->value.literal.lang);
#endif
				};

			RDFSTORE_FREE(utf8_casefolded_buff);
			};

		/* datatypes table */
		if (	(statement->object->value.literal.dataType != NULL) &&
			(strlen(statement->object->value.literal.dataType) > 0) ) {
			key.data = statement->object->value.literal.dataType;
			key.size = strlen(statement->object->value.literal.dataType);

			err = rdfstore_flat_store_fetch_compressed(me->datatypes, me->func_decode, key, &outsize, me->bits_decode);
			if (err != 0) {
				if (err != FLAT_STORE_E_NOTFOUND) {
					perror("rdfstore_remove");
					fprintf(stderr,"Could not fetch datatype '%s' of literal '%s' for store '%s': %s\n", statement->object->value.literal.dataType, statement->object->value.literal.string, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->datatypes));
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
					rdfstore_iterator_close(reindex);
#endif
					return -1;
				} else {
					outsize = 0;
					};
				};

			/* reset the right bit to zero */
			rdfstore_bits_setmask(&outsize, me->bits_decode, st_id, 1, 0, sizeof(me->bits_decode));

                	outsize = rdfstore_bits_shorten(outsize, me->bits_decode);
			if (outsize) {
				err = rdfstore_flat_store_store_compressed(me->datatypes, me->func_encode, 
							key, outsize, me->bits_decode, me->bits_encode);
				if (err == 0) {
#ifdef RDFSTORE_DEBUG_COMPRESSION
					fprintf(stderr,"Stored %d bytes for datatype '%s' in datatypes for store '%s'\n", outsize, (char *)key.data, (me->name != NULL) ? me->name : "(in-memory)");
#endif
				} else {
					if (err != FLAT_STORE_E_KEYEXIST) {
						perror("rdfstore_remove");
						fprintf(stderr,"Could not store '%d' bytes for datatype '%s' of literal '%s' in datatypes for store '%s': %s\n", (int)data.size, statement->object->value.literal.dataType, statement->object->value.literal.string, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->datatypes));
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
						rdfstore_iterator_close(reindex);
#endif
						return -1;
						};
					};

#ifdef RDFSTORE_DEBUG
				{
				int             i;
				if ((rdfstore_flat_store_fetch(me->datatypes, key, &data)) == 0) {
					me->func_decode(data.size, data.data, &outsize, me->bits_decode);
					RDFSTORE_FREE(data.data);
				};
				printf("REMOVED (%d) datatype '%s' of literal '%s' -->'", st_id, statement->object->value.literal.dataType, statement->object->value.literal.string);
				for (i = 0; i < outsize; i++) {
					printf("%02X", me->bits_decode[i]);
				};
				printf("'\n");
				}
#endif
			} else {
				err = rdfstore_flat_store_delete(me->datatypes, key);
				if (err != 0) {
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
                        		rdfstore_iterator_close(reindex);
#endif
					if (err != FLAT_STORE_E_NOTFOUND) {
						perror("rdfstore_remove");
						fprintf(stderr,"Could not delete statement for store '%s': %s\n", (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->datatypes));
               					return -1;
					} else {
						return 1;
						};
               				};
#ifdef RDFSTORE_DEBUG
				printf("DELETED (%d) datatypes literal datatype '%s'\n", st_id, statement->object->value.literal.dataType);
#endif
				};

			/* date type indexing only if rdf:datatype is set accordingly to xsd:date or xsd:dateTime */
                        if(     (strcmp(statement->object->value.literal.dataType,RDFSTORE_MS_XSD_DATE)==0) ||
                                (strcmp(statement->object->value.literal.dataType,RDFSTORE_MS_XSD_DATETIME)==0) ) {
                                if(	( rdfstore_xsd_deserialize_dateTime(	statement->object->value.literal.string,
										&thedateval_tm ) ) ||
					( rdfstore_xsd_deserialize_date(	statement->object->value.literal.string,
										&thedateval_tm ) ) ) {

					rdfstore_xsd_serialize_dateTime( thedateval_tm, thedateval ); /* we index xsd:dataTime version anyway */

                                        key.data = thedateval;
                                        key.size = strlen(thedateval)+1;

#ifdef RDFSTORE_DEBUG
fprintf(stderr, "REMOVE DATE '%s' for LITERAL '%s' \n", thedateval, statement->object->value.literal.string);
#endif

					err = rdfstore_flat_store_fetch_compressed(me->xsd_date, me->func_decode, key, &outsize, me->bits_decode);
					if (err != 0) {
						if (err != FLAT_STORE_E_NOTFOUND) {
							perror("rdfstore_remove");
							fprintf(stderr,"Could not fetch date '%ld' of literal '%s' for store '%s': %s\n", thedateval, statement->object->value.literal.string, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->xsd_date));
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
							rdfstore_iterator_close(reindex);
#endif
							return -1;
						} else {
							outsize = 0;
							};
						};

					/* reset the right bit to zero */
					rdfstore_bits_setmask(&outsize, me->bits_decode, st_id, 1, 0, sizeof(me->bits_decode));

                			outsize = rdfstore_bits_shorten(outsize, me->bits_decode);
					if (outsize) {
						err = rdfstore_flat_store_store_compressed(me->xsd_date, me->func_encode, 
									key, outsize, me->bits_decode, me->bits_encode);
						if (err == 0) {
#ifdef RDFSTORE_DEBUG_COMPRESSION
							fprintf(stderr,"Stored %d bytes for date '%s' in date table for store '%s'\n", outsize, thedateval, (me->name != NULL) ? me->name : "(in-memory)");
#endif
						} else {
							if (err != FLAT_STORE_E_KEYEXIST) {
								perror("rdfstore_remove");
								fprintf(stderr,"Could not store '%d' bytes for date '%s' of literal '%s' in date table for store '%s': %s\n", (int)data.size, thedateval, statement->object->value.literal.string, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->xsd_date));
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
								rdfstore_iterator_close(reindex);
#endif
								return -1;
								};
							};

#ifdef RDFSTORE_DEBUG
						{
						int             i;
						if ((rdfstore_flat_store_fetch(me->xsd_date, key, &data)) == 0) {
							me->func_decode(data.size, data.data, &outsize, me->bits_decode);
							RDFSTORE_FREE(data.data);
							};
						printf("REMOVED (%d) date '%s' of literal '%s' -->'", st_id, thedateval, statement->object->value.literal.string);
						for (i = 0; i < outsize; i++) {
							printf("%02X", me->bits_decode[i]);
							};
						printf("'\n");
						}
#endif
					} else {
						err = rdfstore_flat_store_delete(me->xsd_date, key);
						if (err != 0) {
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
                        				rdfstore_iterator_close(reindex);
#endif
							if (err != FLAT_STORE_E_NOTFOUND) {
								perror("rdfstore_remove");
								fprintf(stderr,"Could not delete statement for store '%s': %s\n", (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->xsd_date));
               							return -1;
							} else {
								return 1;
								};
               						};
#ifdef RDFSTORE_DEBUG
						printf("DELETED (%d) date table date '%s'\n", st_id, thedateval);
#endif
						};
					};
				}; /* end of date indexing */

			};

		/* for xsd:integer alike literals use special b-tree sorted index if strtol() works.... */
		if( ( islval = rdfstore_xsd_deserialize_integer( statement->object->value.literal.string, &thelval ) ) != 0 ) {
			key.data = (long*) &thelval; /* should pack int perhaps... */
			key.size = sizeof(long);

#ifdef RDFSTORE_DEBUG
fprintf(stderr, "REMOVE INTEGER '%ld' for LITERAL '%s' \n",(long)thelval, statement->object->value.literal.string);
#endif

			err = rdfstore_flat_store_fetch_compressed(me->xsd_integer, me->func_decode, key, &outsize, me->bits_decode);
			if (err != 0) {
				if (err != FLAT_STORE_E_NOTFOUND) {
					perror("rdfstore_remove");
					fprintf(stderr,"Could not fetch integer '%ld' of literal '%s' for store '%s': %s\n", (long)thelval, statement->object->value.literal.string, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->xsd_integer));
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
					rdfstore_iterator_close(reindex);
#endif
					return -1;
				} else {
					outsize = 0;
					};
				};

			/* reset the right bit to zero */
			rdfstore_bits_setmask(&outsize, me->bits_decode, st_id, 1, 0, sizeof(me->bits_decode));

                	outsize = rdfstore_bits_shorten(outsize, me->bits_decode);
			if (outsize) {
				err = rdfstore_flat_store_store_compressed(me->xsd_integer, me->func_encode, 
							key, outsize, me->bits_decode, me->bits_encode);
				if (err == 0) {
#ifdef RDFSTORE_DEBUG_COMPRESSION
					fprintf(stderr,"Stored %d bytes for integer '%ld' in integer table for store '%s'\n", outsize, (long)thelval, (me->name != NULL) ? me->name : "(in-memory)");
#endif
				} else {
					if (err != FLAT_STORE_E_KEYEXIST) {
						perror("rdfstore_remove");
						fprintf(stderr,"Could not store '%d' bytes for integer '%ld' of literal '%s' in integer table for store '%s': %s\n", (int)data.size, (long)thelval, statement->object->value.literal.string, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->xsd_integer));
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
						rdfstore_iterator_close(reindex);
#endif
						return -1;
						};
					};

#ifdef RDFSTORE_DEBUG
				{
				int             i;
				if ((rdfstore_flat_store_fetch(me->xsd_integer, key, &data)) == 0) {
					me->func_decode(data.size, data.data, &outsize, me->bits_decode);
					RDFSTORE_FREE(data.data);
				};
				printf("REMOVED (%d) integer '%ld' of literal '%s' -->'", st_id, (long)thelval, statement->object->value.literal.string);
				for (i = 0; i < outsize; i++) {
					printf("%02X", me->bits_decode[i]);
				};
				printf("'\n");
				}
#endif
			} else {
				err = rdfstore_flat_store_delete(me->xsd_integer, key);
				if (err != 0) {
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
                        		rdfstore_iterator_close(reindex);
#endif
					if (err != FLAT_STORE_E_NOTFOUND) {
						perror("rdfstore_remove");
						fprintf(stderr,"Could not delete statement for store '%s': %s\n", (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->xsd_integer));
               					return -1;
					} else {
						return 1;
						};
               				};
#ifdef RDFSTORE_DEBUG
				printf("DELETED (%d) integer table integer '%ld'\n", st_id, (long)thelval);
#endif
				};
			};

		/* for xsd:double or xsd:float alike literals use special b-tree sorted index if strtod() works.... */
		if(	( islval == 0 ) && /* do not index xsd:integer(s) twice also as xsd:double */
			( ( isdval = rdfstore_xsd_deserialize_double( statement->object->value.literal.string, &thedval ) ) != 0 ) ) {
			key.data = (double*) &thedval; /* should pack int perhaps... */
			key.size = sizeof(double);

#ifdef RDFSTORE_DEBUG
fprintf(stderr, "REMOVE DOUBLE '%f' for LITERAL '%s' \n",thedval, statement->object->value.literal.string);
#endif

			err = rdfstore_flat_store_fetch_compressed(me->xsd_double, me->func_decode, key, &outsize, me->bits_decode);
			if (err != 0) {
				if (err != FLAT_STORE_E_NOTFOUND) {
					perror("rdfstore_remove");
					fprintf(stderr,"Could not fetch double '%f' of literal '%s' for store '%s': %s\n", thedval, statement->object->value.literal.string, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->xsd_double));
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
					rdfstore_iterator_close(reindex);
#endif
					return -1;
				} else {
					outsize = 0;
					};
				};

			/* reset the right bit to zero */
			rdfstore_bits_setmask(&outsize, me->bits_decode, st_id, 1, 0, sizeof(me->bits_decode));

                	outsize = rdfstore_bits_shorten(outsize, me->bits_decode);
			if (outsize) {
				err = rdfstore_flat_store_store_compressed(me->xsd_double, me->func_encode, 
							key, outsize, me->bits_decode, me->bits_encode);
				if (err == 0) {
#ifdef RDFSTORE_DEBUG_COMPRESSION
					fprintf(stderr,"Stored %d bytes for double '%f' in double table for store '%s'\n", outsize, thedval, (me->name != NULL) ? me->name : "(in-memory)");
#endif
				} else {
					if (err != FLAT_STORE_E_KEYEXIST) {
						perror("rdfstore_remove");
						fprintf(stderr,"Could not store '%d' bytes for double '%f' of literal '%s' in double table for store '%s': %s\n", (int)data.size, thedval, statement->object->value.literal.string, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->xsd_double));
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
						rdfstore_iterator_close(reindex);
#endif
						return -1;
						};
					};

#ifdef RDFSTORE_DEBUG
				{
				int             i;
				if ((rdfstore_flat_store_fetch(me->xsd_double, key, &data)) == 0) {
					me->func_decode(data.size, data.data, &outsize, me->bits_decode);
					RDFSTORE_FREE(data.data);
				};
				printf("REMOVED (%d) double '%f' of literal '%s' -->'", st_id, thedval, statement->object->value.literal.string);
				for (i = 0; i < outsize; i++) {
					printf("%02X", me->bits_decode[i]);
				};
				printf("'\n");
				}
#endif
			} else {
				err = rdfstore_flat_store_delete(me->xsd_double, key);
				if (err != 0) {
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
                        		rdfstore_iterator_close(reindex);
#endif
					if (err != FLAT_STORE_E_NOTFOUND) {
						perror("rdfstore_remove");
						fprintf(stderr,"Could not delete statement for store '%s': %s\n", (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->xsd_double));
               					return -1;
					} else {
						return 1;
						};
               				};
#ifdef RDFSTORE_DEBUG
				printf("DELETED (%d) double table double '%f'\n", st_id, thedval);
#endif
				};
			};

		}; /* end remove special literal stuff */

	/* removed one statement */
	key.data = RDFSTORE_COUNTER_REMOVED_KEY;
        key.size = sizeof(RDFSTORE_COUNTER_REMOVED_KEY);
	if ((rdfstore_flat_store_inc(me->model, key, &data)) != 0) {
		perror("rdfstore_remove");
		fprintf(stderr,"Could not decrement statement counter for store '%s': %s\n", (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->model));
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
		rdfstore_iterator_close(reindex);
#endif
		return -1;
	};
	RDFSTORE_FREE(data.data);

	/* delete the statement internal identifier */
	packInt(hc, outbuf);
	key.data = outbuf;
	key.size = sizeof(int);
	err = rdfstore_flat_store_delete(me->statements, key);
	if (err != 0) {
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
		rdfstore_iterator_close(reindex);
#endif
		if (err != FLAT_STORE_E_NOTFOUND) {
			perror("rdfstore_remove");
			fprintf(stderr,"Could not delete statement for store '%s': %s\n", (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->statements));
			return -1;
		} else {
			return 1;
			};
	} else {
		/* touch DB last modified date */
		bzero(&thedateval_tm, sizeof( struct tm ) );

        	time(&now);

        	ptm = gmtime(&now);
        	memcpy(&thedateval_tm, ptm, sizeof(struct tm));

        	rdfstore_xsd_serialize_dateTime( thedateval_tm, thedateval );

        	key.data = RDFSTORE_LASTMODIFIED_KEY;
        	key.size = sizeof(RDFSTORE_LASTMODIFIED_KEY);

        	data.data = thedateval;
        	data.size = strlen(thedateval) + 1;

        	err = rdfstore_flat_store_store(me->model, key, data);
        	if (    (err != 0) &&
                	(err != FLAT_STORE_E_KEYEXIST) ) {
			perror("rdfstore_remove");
                	fprintf(stderr,"Could not store last modified date in model for store '%s': %s\n", (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->model));
#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
                	rdfstore_iterator_close(reindex);
#endif
                	return -1;
                	};
		};

	if ((me->sync) &&
	    (!(me->flag))) {
		/* sync :( */
		rdfstore_flat_store_sync(me->model);
                rdfstore_flat_store_sync(me->nodes);
                rdfstore_flat_store_sync(me->subjects);
                rdfstore_flat_store_sync(me->predicates);
                rdfstore_flat_store_sync(me->objects);
                if (context != NULL)
                        rdfstore_flat_store_sync(me->contexts);
#ifdef RDFSTORE_CONNECTIONS
                if (me->s_connections)
                        rdfstore_flat_store_sync(me->s_connections);
                if (me->p_connections)
                        rdfstore_flat_store_sync(me->p_connections);
                if (me->o_connections)
                        rdfstore_flat_store_sync(me->o_connections);
#endif
                if (me->languages)
                        rdfstore_flat_store_sync(me->languages);
                if (me->datatypes)
                        rdfstore_flat_store_sync(me->datatypes);
                if (me->xsd_integer)
                        rdfstore_flat_store_sync(me->xsd_integer);
                if (me->xsd_double)
                        rdfstore_flat_store_sync(me->xsd_double);
                if (me->xsd_date)
                        rdfstore_flat_store_sync(me->xsd_date);
                if (me->freetext)
                        rdfstore_flat_store_sync(me->windex);
	};

#if defined(RDFSTORE_CONNECTIONS) && defined(RDFSTORE_CONNECTIONS_REINDEXING)
	rdfstore_iterator_close(reindex);
#endif

	return 0;
	};

rdfstore_iterator *
rdfstore_search(rdfstore * me, RDF_Triple_Pattern * tp, int search_type) {
	RDF_Triple_Pattern_Part * tpj=NULL;
	rdfstore_iterator *results;
	DBT             key, data;
	int             err = 0;
	unsigned char  *utf8_casefolded_buff;	/* dyn alloc for saving
						 * memory */
	unsigned int    utf8_size = 0;

	/* bear in mind that with a single nindex table these index tables should be bigger than this! (RDFSTORE_MAXRECORDS*NUM_BITS_IN_TABLE) */
	static unsigned char bits[RDFSTORE_MAXRECORDS_BYTES_SIZE];	/* for logical
							 * operations -
							 * expensive to
							 * allocate??? */
	static unsigned char bits1[RDFSTORE_MAXRECORDS_BYTES_SIZE]; /* general temporary */
	static unsigned char bits2[RDFSTORE_MAXRECORDS_BYTES_SIZE]; /* temporary for OR of s,p,o,c */
	unsigned int    outsize1 = 0;
	unsigned int    outsize2 = 0;
	unsigned int    outsize3 = 0;
	unsigned int    pos = 0;
	unsigned char   outbuf[256];

	/* expensive :-(( - calloc() would help here perhaps */
	bzero(bits, sizeof(bits));
	bzero(bits1, sizeof(bits1));
	bzero(bits2, sizeof(bits2));

	/* check inputs */
	if (tp != NULL) {
		if ( tp->subjects != NULL ) {
			tpj = tp->subjects;	
			do {
	      			if ( tpj->type != RDFSTORE_TRIPLE_PATTERN_PART_RESOURCE_NODE )
					return NULL;
			} while ( ( tpj = tpj->next ) != NULL );

			if (	(tp->subjects_operator < 0) ||
				(tp->subjects_operator > 2) )
				return NULL;
			};
		if ( tp->predicates != NULL ) {
			tpj = tp->predicates;	
			do {
	      			if ( tpj->type != RDFSTORE_TRIPLE_PATTERN_PART_RESOURCE_NODE )
					return NULL;
			} while ( ( tpj = tpj->next ) != NULL );

			if (	(tp->predicates_operator < 0) ||
				(tp->predicates_operator > 2) )
				return NULL;
			};
		if ( tp->objects != NULL ) {
			tpj = tp->objects;	
			do {
	      			if ( !  ( ( tpj->type == RDFSTORE_TRIPLE_PATTERN_PART_LITERAL_NODE ) ||
					  ( tpj->type == RDFSTORE_TRIPLE_PATTERN_PART_RESOURCE_NODE ) ) )
					return NULL;
			} while ( ( tpj = tpj->next ) != NULL );

			if (	(tp->objects_operator < 0) ||
				(tp->objects_operator > 2) )
				return NULL;
			};
		if ( tp->contexts != NULL ) {
			tpj = tp->contexts;	
			do {
	      			if ( tpj->type != RDFSTORE_TRIPLE_PATTERN_PART_RESOURCE_NODE )
					return NULL;
			} while ( ( tpj = tpj->next ) != NULL );

			if (	(tp->contexts_operator < 0) ||
				(tp->contexts_operator > 2) )
				return NULL;
			};
		if ( tp->langs != NULL ) {
			tpj = tp->langs;	
			do {
	      			if ( tpj->type != RDFSTORE_TRIPLE_PATTERN_PART_STRING )
					return NULL;
			} while ( ( tpj = tpj->next ) != NULL );

			if (	(tp->langs_operator < 0) ||
				(tp->langs_operator > 2) )
				return NULL;
			};
		if ( tp->dts != NULL ) {
			tpj = tp->dts;	
			do {
	      			if ( tpj->type != RDFSTORE_TRIPLE_PATTERN_PART_STRING )
					return NULL;
			} while ( ( tpj = tpj->next ) != NULL );

			if (	(tp->dts_operator < 0) ||
				(tp->dts_operator > 2) )
				return NULL;
			};
		if ( tp->words != NULL ) {
			tpj = tp->words;	
			do {
	      			if ( tpj->type != RDFSTORE_TRIPLE_PATTERN_PART_STRING )
					return NULL;
			} while ( ( tpj = tpj->next ) != NULL );

			if (	(tp->words_operator < 0) ||
				(tp->words_operator > 2) )
				return NULL;
			};
		if ( tp->ranges != NULL ) {
			tpj = tp->ranges;	
			do {
	      			if ( tpj->type != RDFSTORE_TRIPLE_PATTERN_PART_STRING )
					return NULL;
			} while ( ( tpj = tpj->next ) != NULL );

			if (	(tp->ranges_operator < 0 ) || /* it is unsigned int anyway... */
				(tp->ranges_operator > 10) )
				return NULL;
			};
		};

	if (	( me->freetext ) &&
	    	( tp != NULL ) &&
	    	( tp->words != NULL ) &&
	    	( tp->objects != NULL ) ) {
		perror("rdfstore_search");
		fprintf(stderr,"Could search literal and free-text word at the same time for store '%s'\n", (me->name != NULL) ? me->name : "(in-memory)");
		return NULL;
		};

	memset(&key, 0, sizeof(key));
	memset(&data, 0, sizeof(data));

#ifdef RDFSTORE_DEBUG
	fprintf(stderr,"TO SEARCH:\n");
	fprintf(stderr,"search type=%d\n",search_type);
	rdfstore_triple_pattern_dump( tp );
	fprintf(stderr," with options freetext='%d'\n", me->freetext);
#endif

	/* if the query was empty return the whole thing */
	if ( (tp == NULL) ||
	     ((tp != NULL) &&
	      (tp->subjects == NULL) &&
	      (tp->predicates == NULL) &&
	      (tp->objects == NULL) &&
	      (tp->contexts == NULL) &&
	      (tp->langs == NULL) &&
	      (tp->dts == NULL) &&
	      (tp->words == NULL) &&
	      (tp->ranges == NULL) ) ) {
		return rdfstore_elements(me);
		};

	/* note: due we do not distinguish hash keys for literals with same value byt different xml:lang or rdf:datatype and we keep special
                 indexes for those literal components - we should re-write the query accordingly but for the moment we just warn the user */
#ifdef RDFSTORE_VERBOSE
	if (	(tp->words != NULL) &&
		(tp->objects != NULL) ) {
		tpj = tp->objects;
		do {
			if( tpj->part.node->type == 1 ) {
				if(	( strlen(tpj->part.node->value.literal.lang) > 0 ) ||
					( tpj->part.node->value.literal.dataType != NULL ) )
					fprintf(stderr,"WARNING: rdfstore_search() - RDF literal ");
				if( strlen(tpj->part.node->value.literal.lang) > 0 )
					fprintf(stderr,"xml:lang='%s' ",tpj->part.node->value.literal.lang);

				if( tpj->part.node->value.literal.dataType != NULL )
					fprintf(stderr,"rdf:datatype='%s' ",tpj->part.node->value.literal.dataType);
				if(	( strlen(tpj->part.node->value.literal.lang) > 0 ) ||
					( tpj->part.node->value.literal.dataType != NULL ) )
					fprintf(stderr,"component(s) can no be searched as part of the literal - please use the explicit rdfstore_search() syntax modifiers languages and datatypes.\n");
				};
			} while ( ( tpj = tpj->next ) != NULL );
		};
#endif

	results = (rdfstore_iterator *) RDFSTORE_MALLOC(sizeof(rdfstore_iterator));
	if (results == NULL) {
		perror("rdfstore_search");
		fprintf(stderr,"Cannot create results cursor/iterator for store '%s'\n", (me->name != NULL) ? me->name : "(in-memory)");
		return NULL;
	};
	results->store = me;
	results->store->attached++;
	/* bzero(results->ids,sizeof(unsigned char)*(RDFSTORE_MAXRECORDS_BYTES_SIZE)); */
	results->remove_holes = 0;	/* reset the total number of holes */
	results->st_counter = 0;
	results->pos = 0;
	results->ids_size = 0;
	results->size = 0;

	/* do any words combination first */
	if (	( me->freetext ) &&
		( tp->words != NULL ) ) {
		tpj = tp->words;
		do {
			utf8_casefolded_buff = (unsigned char *)RDFSTORE_MALLOC(strlen(tpj->part.string) * sizeof(unsigned char) * 
									(RDFSTORE_UTF8_MAXLEN_FOLD + 1));	/* what about the ending '\0' here ?? */
			if (utf8_casefolded_buff == NULL) {
				perror("rdfstore_search");
				fprintf(stderr,"Cannot compute case-folded string out of input word for store '%s'\n", (me->name != NULL) ? me->name : "(in-memory)");
				rdfstore_iterator_close(results);
				return NULL;
				};
			/* not UTF-8 safe strlen() anyway... */
			if (rdfstore_utf8_string_to_utf8_foldedcase(strlen(tpj->part.string), tpj->part.string, &utf8_size, utf8_casefolded_buff)) {
				perror("rdfstore_search");
				fprintf(stderr,"Cannot compute case-folded string out of input word for store '%s'\n", (me->name != NULL) ? me->name : "(in-memory)");
				RDFSTORE_FREE(utf8_casefolded_buff);
				rdfstore_iterator_close(results);
				return NULL;
				};
			key.data = utf8_casefolded_buff;
			key.size = utf8_size;
			err = rdfstore_flat_store_fetch(me->windex, key, &data);
			if (err != 0) {
				RDFSTORE_FREE(utf8_casefolded_buff);
				if (err != FLAT_STORE_E_NOTFOUND) {
					perror("rdfstore_search");
					fprintf(stderr,"Could not fetch key '%s' in windex for store '%s': %s\n", (char *)key.data, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->windex));
					rdfstore_iterator_close(results);
					return NULL;
				} else {
					continue;
				};
			} else {
				if (outsize1 > 0) {
					me->func_decode(data.size, data.data, &outsize2, me->bits_decode);
					if (tp->words_operator == 1) {
						/* and them */
						outsize1 = rdfstore_bits_and(outsize1, bits, outsize2, me->bits_decode, bits1);
					} else if (tp->words_operator == 0) {
						/* or them */
						outsize1 = rdfstore_bits_or(outsize1, bits, outsize2, me->bits_decode, bits1);
					} else if (tp->words_operator == 2) {
						fprintf(stderr,"The boolean NOT operator on words is not implemented yet :)\n");
						};
					outsize1 = rdfstore_bits_shorten(outsize1, bits1);	/* really useful due to
												 * the odd statements
												 * shortness */
					bcopy(bits1, bits, outsize1);	/* slow? */
				} else {
					me->func_decode(data.size, data.data, &outsize1, bits);
				};
				RDFSTORE_FREE(data.data);
			};

#ifdef RDFSTORE_DEBUG
			{
				int             j;
				printf("SEARCH windex for word '%s' case-folded as '%s' with tp->words_operator '%d' (words only bits) -->'", tpj->part.string, utf8_casefolded_buff, tp->words_operator);
				for(j=0;j<8*outsize1;j++) {
					printf("Rec %d %c\n", j, (bits[j>>3] & (1<<(j&7))) ? '1':'0');           
                        		};
				printf("'\n");
			}
#endif

			RDFSTORE_FREE(utf8_casefolded_buff);

			} while ( ( tpj = tpj->next ) != NULL );

#ifdef RDFSTORE_DEBUG
		{
		int             i;
		printf("SEARCH windex for words '");
		tpj = tp->words;
		do {
			fprintf(stderr," %s ", tpj->part.string );
			} while ( ( tpj = tpj->next ) != NULL );
		printf("' -->'");
		for(i=0;i<8*outsize1;i++) {
                       	printf("Rec %d %c\n", i, (bits[i>>3] & (1<<(i&7))) ? '1':'0');           
                       	};
		printf("'\n");
		}
#endif

		/* no words matched? */
		if (!outsize1)
			return results;
		};

	/*
	 * this happens when we got a fixed object or free-text; otherwise we
	 * need a double fetch + shifting of bits to generate the iterator
	 */
	if (tp != NULL) {
		if ( tp->subjects != NULL ) {
			outsize3=0;
			tpj = tp->subjects;
			do {

				/* compute subject hashcode */
				tpj->part.node->hashcode = rdfstore_digest_get_node_hashCode(tpj->part.node, 0);

				packInt(tpj->part.node->hashcode, outbuf);
				key.data = outbuf;
				key.size = sizeof(int);

#ifdef RDFSTORE_CONNECTIONS
				err = rdfstore_flat_store_fetch((search_type==0) ? me->subjects : me->s_connections, key, &data);
#else
				err = rdfstore_flat_store_fetch( me->subjects, key, &data);
#endif
				if (err != 0) {
                                	if (err != FLAT_STORE_E_NOTFOUND) {
                                        	perror("rdfstore_search");
#ifdef RDFSTORE_CONNECTIONS
                                        	fprintf(stderr,"Could not fetch key '%s' for subject pattern for store '%s': %s\n", (char *)key.data, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error((search_type==0) ? me->subjects : me->s_connections));
#else
                                        	fprintf(stderr,"Could not fetch key '%s' for subject pattern for store '%s': %s\n", (char *)key.data, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error( me->subjects ));
#endif
                                        	rdfstore_iterator_close(results);
                                        	return NULL;
                                	} else {
                                        	/* cannot join */
						continue;
						};
				} else {
					if (outsize3 > 0) {
#ifdef RDFSTORE_CONNECTIONS
						if(search_type==0) {
							me->func_decode(data.size, data.data, &outsize2, me->bits_decode);
						} else {
							me->func_decode_connections(data.size, data.data, &outsize2, me->bits_decode);
							};
#else
						me->func_decode(data.size, data.data, &outsize2, me->bits_decode);
#endif

						if (tp->subjects_operator == 1) {
                                                	/* and them i.e. URL1, URL2, URL3....URLn */
                                                	outsize3 = rdfstore_bits_and(outsize3, bits2, outsize2, me->bits_decode, bits1);
                                        	} else if (tp->subjects_operator == 0) {
                                                	/* or them i.e. URL1, URL2, URL3....URLn */
                                                	outsize3 = rdfstore_bits_or(outsize3, bits2, outsize2, me->bits_decode, bits1);
                                        	} else if (tp->subjects_operator == 2) {
                                                	fprintf(stderr,"The boolean NOT operator on subjects is not implemented yet :)\n");
                                                	};

                                        	outsize3 = rdfstore_bits_shorten(outsize3, bits1); /* why shorten? inefficient??? */
                                        	bcopy(bits1, bits2, outsize3);   /* slow? */
					} else {
#ifdef RDFSTORE_CONNECTIONS
						if(search_type==0) {
							me->func_decode(data.size, data.data, &outsize3, bits2);
                                                } else {
							me->func_decode_connections(data.size, data.data, &outsize3, bits2);
                                                        };
#else
						me->func_decode(data.size, data.data, &outsize3, bits2);
#endif
						};
					RDFSTORE_FREE(data.data);
					};

#ifdef RDFSTORE_DEBUG
				{
				int             j;
				printf("SEARCH subjects[%d] for S -->'",i);
				for(j=0;j<8*outsize3;j++) {
					printf("Rec %d %c\n", j, (bits2[j>>3] & (1<<(j&7))) ? '1':'0');           
                        		};
				printf("'\n");
				}
#endif
				} while ( ( tpj = tpj->next ) != NULL );

			/* no subjects matched? */
			if (!outsize3)
				return results;

			/* AND in all subjects to previous words now */
			if (outsize1 > 0) {
				/* and them */
                                outsize1 = rdfstore_bits_and(outsize1, bits, outsize3, bits2, bits1);
				outsize1 = rdfstore_bits_shorten(outsize1, bits1);

				/* cannot join */
				if (!outsize1) {
					return results;
					};

				bcopy(bits1, bits, outsize1);	/* slow? */
			} else {
				/* or OR them */
                                outsize1 = rdfstore_bits_or(outsize3, bits, outsize3, bits2, bits1);
				bcopy(bits1, bits, outsize3);	/* slow? */
				};

#ifdef RDFSTORE_DEBUG
                                {
                                int             j;
                                printf("SEARCH subjects for S -->'");
                                for(j=0;j<8*outsize1;j++) {
                                        printf("Rec %d %c\n", j, (bits[j>>3] & (1<<(j&7))) ? '1':'0');
                                        };
                                printf("'\n");
                                }
#endif
			};

		if ( tp->predicates != NULL ) {
			outsize3=0;
			tpj = tp->predicates;
			do {

				/* compute subject hashcode */
				tpj->part.node->hashcode = rdfstore_digest_get_node_hashCode(tpj->part.node, 0);

				packInt(tpj->part.node->hashcode, outbuf);
				key.data = outbuf;
				key.size = sizeof(int);

#ifdef RDFSTORE_CONNECTIONS
				err = rdfstore_flat_store_fetch((search_type==0) ? me->predicates : me->p_connections, key, &data);
#else
				err = rdfstore_flat_store_fetch( me->predicates, key, &data);
#endif
				if (err != 0) {
                                	if (err != FLAT_STORE_E_NOTFOUND) {
                                        	perror("rdfstore_search");
#ifdef RDFSTORE_CONNECTIONS
                                        	fprintf(stderr,"Could not fetch key '%s' for predicate pattern for store '%s': %s\n", (char *)key.data, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error((search_type==0) ? me->predicates : me->p_connections));
#else
                                        	fprintf(stderr,"Could not fetch key '%s' for predicate pattern for store '%s': %s\n", (char *)key.data, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error( me->predicates ));
#endif
                                        	rdfstore_iterator_close(results);
                                        	return NULL;
                                	} else {
						continue;
						};
				} else {
					if (outsize3 > 0) {
#ifdef RDFSTORE_CONNECTIONS
						if(search_type==0) {
							me->func_decode(data.size, data.data, &outsize2, me->bits_decode);
                                                } else {
                                                        me->func_decode_connections(data.size, data.data, &outsize2, me->bits_decode);
                                                        };
#else
						me->func_decode(data.size, data.data, &outsize2, me->bits_decode);
#endif

						if (tp->predicates_operator == 1) {
                                                        /* and them i.e. URL1, URL2, URL3....URLn */
                                                        outsize3 = rdfstore_bits_and(outsize3, bits2, outsize2, me->bits_decode, bits1);
                                                } else if (tp->predicates_operator == 0) {
                                                        /* or them i.e. URL1, URL2, URL3....URLn */
                                                        outsize3 = rdfstore_bits_or(outsize3, bits2, outsize2, me->bits_decode, bits1);
                                                } else if (tp->predicates_operator == 2) {
                                                        fprintf(stderr,"The boolean NOT operator on predicates is not implemented yet :)\n");
                                                        };

                                        	outsize3 = rdfstore_bits_shorten(outsize3, bits1);
                                        	bcopy(bits1, bits2, outsize3);   /* slow? */
					} else {
#ifdef RDFSTORE_CONNECTIONS
						if(search_type==0) {
                                                        me->func_decode(data.size, data.data, &outsize3, bits2);
                                                } else {
                                                        me->func_decode_connections(data.size, data.data, &outsize3, bits2);
                                                        };
#else
                                                me->func_decode(data.size, data.data, &outsize3, bits2);
#endif
						};
					RDFSTORE_FREE(data.data);
					};

#ifdef RDFSTORE_DEBUG
                                {
                                int             j;
                                printf("SEARCH predicates[%d] for P -->'",i);
                                for(j=0;j<8*outsize3;j++) {
                                        printf("Rec %d %c\n", j, (bits2[j>>3] & (1<<(j&7))) ? '1':'0');
                                        };
                                printf("'\n");
                                }
#endif
				} while ( ( tpj = tpj->next ) != NULL );

			/* no predicates matched? */
			if (!outsize3)
				return results;

			/* AND in all predicates to previous words and subjects now */
                        if (outsize1 > 0) {
                                /* and them */
                                outsize1 = rdfstore_bits_and(outsize1, bits, outsize3, bits2, bits1);
                                outsize1 = rdfstore_bits_shorten(outsize1, bits1);

                                /* cannot join */
                                if (!outsize1) {
                                        return results;
                                        };

                                bcopy(bits1, bits, outsize1);   /* slow? */
                        } else {
                                /* or OR them */
                                outsize1 = rdfstore_bits_or(outsize3, bits, outsize3, bits2, bits1); 
                                bcopy(bits1, bits, outsize3);   /* slow? */
                                };

#ifdef RDFSTORE_DEBUG
                                {
                                int             j;
                                printf("SEARCH predicates for P -->'");      
                                for(j=0;j<8*outsize1;j++) {
                                        printf("Rec %d %c\n", j, (bits[j>>3] & (1<<(j&7))) ? '1':'0'); 
                                        };
                                printf("'\n");
                                }
#endif

			};

		if ( tp->objects != NULL ) {
			outsize3=0;
			tpj = tp->objects;
			do {

				/* compute subject hashcode */
				tpj->part.node->hashcode = rdfstore_digest_get_node_hashCode(tpj->part.node, 0);

				packInt(tpj->part.node->hashcode, outbuf);
				key.data = outbuf;
				key.size = sizeof(int);

#ifdef RDFSTORE_CONNECTIONS
				err = rdfstore_flat_store_fetch((search_type==0) ? me->objects : me->o_connections, key, &data);
#else
				err = rdfstore_flat_store_fetch( me->objects, key, &data);
#endif
				if (err != 0) {
					if (err != FLAT_STORE_E_NOTFOUND) {
						perror("rdfstore_search");
#ifdef RDFSTORE_CONNECTIONS
						fprintf(stderr,"Could not fetch key '%s' for object for store '%s': %s\n", (char *)key.data, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error((search_type==0) ? me->objects : me->o_connections));
#else
						fprintf(stderr,"Could not fetch key '%s' for object for store '%s': %s\n", (char *)key.data, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error( me->objects ));
#endif
						rdfstore_iterator_close(results);
						return NULL;
					} else {
						continue;
					};
				} else {
					if (outsize3 > 0) {
#ifdef RDFSTORE_CONNECTIONS
						if(search_type==0) {
                                                        me->func_decode(data.size, data.data, &outsize2, me->bits_decode);
                                                } else {
                                                        me->func_decode_connections(data.size, data.data, &outsize2, me->bits_decode);
                                                        };
#else
                                                me->func_decode(data.size, data.data, &outsize2, me->bits_decode);
#endif

						if (tp->objects_operator == 1) {
                                                        /* and them i.e. URL1, URL2, URL3....URLn */
                                                        outsize3 = rdfstore_bits_and(outsize3, bits2, outsize2, me->bits_decode, bits1);
                                                } else if (tp->objects_operator == 0) {
                                                        /* or them i.e. URL1, URL2, URL3....URLn */
                                                        outsize3 = rdfstore_bits_or(outsize3, bits2, outsize2, me->bits_decode, bits1);
                                                } else if (tp->objects_operator == 2) {
                                                        fprintf(stderr,"The boolean NOT operator on objects is not implemented yet :)\n"); 
                                                        };

                                        	outsize3 = rdfstore_bits_shorten(outsize3, bits1);
                                        	bcopy(bits1, bits2, outsize3);   /* slow? */
					} else {
#ifdef RDFSTORE_CONNECTIONS
						if(search_type==0) {
                                                        me->func_decode(data.size, data.data, &outsize3, bits2);
                                                } else {
                                                        me->func_decode_connections(data.size, data.data, &outsize3, bits2);
                                                        };
#else
                                                me->func_decode(data.size, data.data, &outsize3, bits2);
#endif
						};
					RDFSTORE_FREE(data.data);
					};

#ifdef RDFSTORE_DEBUG
                                {
                                int             j;
                                printf("SEARCH objects[%d] for O -->'",i);
                                for(j=0;j<8*outsize3;j++) {
                                        printf("Rec %d %c\n", j, (bits2[j>>3] & (1<<(j&7))) ? '1':'0');
                                        };
                                printf("'\n");
                                }
#endif
				} while ( ( tpj = tpj->next ) != NULL );

			/* no objects matched? */
			if (!outsize3)
				return results;

			/* AND in all objects to previous words, subjects and predicates now */
                        if (outsize1 > 0) {
                                /* and them */
                                outsize1 = rdfstore_bits_and(outsize1, bits, outsize3, bits2, bits1);
                                outsize1 = rdfstore_bits_shorten(outsize1, bits1);

                                /* cannot join */
                                if (!outsize1) {
                                        return results;
                                        };

                                bcopy(bits1, bits, outsize1);   /* slow? */
                        } else {
                                /* or OR them */
                                outsize1 = rdfstore_bits_or(outsize3, bits, outsize3, bits2, bits1); 
                                bcopy(bits1, bits, outsize3);   /* slow? */
                                };

#ifdef RDFSTORE_DEBUG
                                {
                                int             j;
                                printf("SEARCH objects for O -->'");
                                for(j=0;j<8*outsize1;j++) {
					printf("Rec %d %c\n", j, (bits[j>>3] & (1<<(j&7))) ? '1':'0');
                                        };
                                printf("'\n");
                                }
#endif
			};

		/* xml:lang ones */
		if ( tp->langs != NULL)  {
			outsize3=0;
			tpj = tp->langs;
			do {

				utf8_casefolded_buff = (unsigned char *)RDFSTORE_MALLOC(strlen(tpj->part.string) * sizeof(unsigned char) * (RDFSTORE_UTF8_MAXLEN_FOLD + 1));
				if (utf8_casefolded_buff == NULL) {
					perror("rdfstore_search");
					fprintf(stderr,"Cannot compute case-folded string out of input literal language for store '%s'\n", (me->name != NULL) ? me->name : "(in-memory)");
					rdfstore_iterator_close(results);
					return NULL;
					};
				/* even if strlen() is not UTF-8 safe... */
				if (rdfstore_utf8_string_to_utf8_foldedcase(strlen(tpj->part.string), tpj->part.string, &utf8_size, utf8_casefolded_buff)) {
					perror("rdfstore_search");
					fprintf(stderr,"Cannot compute case-folded string out of input literal language for store '%s'\n", (me->name != NULL) ? me->name : "(in-memory)");
					RDFSTORE_FREE(utf8_casefolded_buff);
					rdfstore_iterator_close(results);
					return NULL;
					};

				key.data = utf8_casefolded_buff;
				key.size = utf8_size;

				err = rdfstore_flat_store_fetch( me->languages, key, &data);
				if (err != 0) {
					if (err != FLAT_STORE_E_NOTFOUND) {
						perror("rdfstore_search");
						fprintf(stderr,"Could not fetch key '%s' for literal language for store '%s': %s\n", (char *)key.data, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error( me->languages ));
						RDFSTORE_FREE(utf8_casefolded_buff);
						rdfstore_iterator_close(results);
						return NULL;
					} else {
						continue;
					};
				} else {
					if (outsize3 > 0) {
                                                me->func_decode(data.size, data.data, &outsize2, me->bits_decode);

						if (tp->langs_operator == 1) {
                                                        /* and them i.e. lang1, lang2, lang3....langn */
                                                        outsize3 = rdfstore_bits_and(outsize3, bits2, outsize2, me->bits_decode, bits1);
                                                } else if (tp->langs_operator == 0) {
                                                        /* or them i.e. lang1, lang2, lang3....langn */
                                                        outsize3 = rdfstore_bits_or(outsize3, bits2, outsize2, me->bits_decode, bits1);
                                                } else if (tp->langs_operator == 2) {
                                                        fprintf(stderr,"The boolean NOT operator on objects literal language is not implemented yet :)\n"); 
                                                        };

                                        	outsize3 = rdfstore_bits_shorten(outsize3, bits1);
                                        	bcopy(bits1, bits2, outsize3);   /* slow? */
					} else {
                                                me->func_decode(data.size, data.data, &outsize3, bits2);
						};
					RDFSTORE_FREE(data.data);
					};

#ifdef RDFSTORE_DEBUG
                                {
                                int             j;
                                printf("SEARCH languages[%d] for O xml:lang -->'",i);
                                for(j=0;j<8*outsize3;j++) {
                                        printf("Rec %d %c\n", j, (bits2[j>>3] & (1<<(j&7))) ? '1':'0');
                                        };
                                printf("'\n");
                                }
#endif

				RDFSTORE_FREE(utf8_casefolded_buff);

				} while ( ( tpj = tpj->next ) != NULL );

			/* no objects matched? */
			if (!outsize3)
				return results;

			/* AND in all xml:lang to previous words, subjects, predicates and objects now */
                        if (outsize1 > 0) {
                                /* and them */
                                outsize1 = rdfstore_bits_and(outsize1, bits, outsize3, bits2, bits1);
                                outsize1 = rdfstore_bits_shorten(outsize1, bits1);

                                /* cannot join */
                                if (!outsize1) {
                                        return results;
                                        };

                                bcopy(bits1, bits, outsize1);   /* slow? */
                        } else {
                                /* or OR them */
                                outsize1 = rdfstore_bits_or(outsize3, bits, outsize3, bits2, bits1); 
                                bcopy(bits1, bits, outsize3);   /* slow? */
                                };

#ifdef RDFSTORE_DEBUG
                                {
                                int             j;
                                printf("SEARCH languages for O xml:lang -->'");
                                for(j=0;j<8*outsize1;j++) {
                                        printf("Rec %d %c\n", j, (bits[j>>3] & (1<<(j&7))) ? '1':'0');
                                        };
                                printf("'\n");
                                }
#endif
			};

		/* rdf:datatype ones */
		if ( tp->dts != NULL ) {
			outsize3=0;
			tpj = tp->dts;
			do {

				key.data = tpj->part.string;
				key.size = strlen(tpj->part.string); /* even if strlen() is not UTF-8 safe... */

				err = rdfstore_flat_store_fetch( me->datatypes, key, &data);
				if (err != 0) {
					if (err != FLAT_STORE_E_NOTFOUND) {
						perror("rdfstore_search");
						fprintf(stderr,"Could not fetch key '%s' for literal datatype for store '%s': %s\n", (char *)key.data, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error( me->datatypes ));
						rdfstore_iterator_close(results);
						return NULL;
					} else {
						continue;
					};
				} else {
					if (outsize3 > 0) {
                                                me->func_decode(data.size, data.data, &outsize2, me->bits_decode);

						if (tp->dts_operator == 1) {
                                                        /* and them i.e. URL1, URL2, URL3....URLn */
                                                        outsize3 = rdfstore_bits_and(outsize3, bits2, outsize2, me->bits_decode, bits1);
                                                } else if (tp->dts_operator == 0) {
                                                        /* or them i.e. URL1, URL2, URL3....URLn */
                                                        outsize3 = rdfstore_bits_or(outsize3, bits2, outsize2, me->bits_decode, bits1);
                                                } else if (tp->dts_operator == 2) {
                                                        fprintf(stderr,"The boolean NOT operator on objects literal datatype is not implemented yet :)\n"); 
                                                        };

                                        	outsize3 = rdfstore_bits_shorten(outsize3, bits1);
                                        	bcopy(bits1, bits2, outsize3);   /* slow? */
					} else {
                                                me->func_decode(data.size, data.data, &outsize3, bits2);
						};
					RDFSTORE_FREE(data.data);
					};

#ifdef RDFSTORE_DEBUG
                                {
                                int             j;
                                printf("SEARCH datatypes[%d] for O rdf:datatype -->'",i);
                                for(j=0;j<8*outsize3;j++) {
                                        printf("Rec %d %c\n", j, (bits2[j>>3] & (1<<(j&7))) ? '1':'0');
                                        };
                                printf("'\n");
                                }
#endif

				} while ( ( tpj = tpj->next ) != NULL );

			/* no objects matched? */
			if (!outsize3)
				return results;

			/* AND in all rdf:datatype to previous words, subjects, predicates, objects and languages now */
                        if (outsize1 > 0) {
                                /* and them */
                                outsize1 = rdfstore_bits_and(outsize1, bits, outsize3, bits2, bits1);
                                outsize1 = rdfstore_bits_shorten(outsize1, bits1);

                                /* cannot join */
                                if (!outsize1) {
                                        return results;
                                        };

                                bcopy(bits1, bits, outsize1);   /* slow? */
                        } else {
                                /* or OR them */
                                outsize1 = rdfstore_bits_or(outsize3, bits, outsize3, bits2, bits1); 
                                bcopy(bits1, bits, outsize3);   /* slow? */
                                };

#ifdef RDFSTORE_DEBUG
                                {
                                int             j;
                                printf("SEARCH datatypes for O rdf:datatype -->'");
                                for(j=0;j<8*outsize1;j++) {
                                        printf("Rec %d %c\n", j, (bits[j>>3] & (1<<(j&7))) ? '1':'0');
                                        };
                                printf("'\n");
                                }
#endif
			};

		/* numerical comparinson one */
		if ( tp->ranges != NULL ) {
			int islval=0;
			int isdval=0;
			int isdateval=0;
			long thelval[2];
			long alval;
			double thedval[2];
			double adval;
			struct tm thedateval_tm[2];
			char thedateval[2][RDFSTORE_XSD_DATETIME_FORMAT_SIZE];
			char adateval[RDFSTORE_XSD_DATETIME_FORMAT_SIZE];
			int last=0;

			tpj = tp->ranges; /* we simply just take the first/head of the list */

			/* guess out the type from the given string */
			if( ( islval = rdfstore_xsd_deserialize_integer( tpj->part.string, &thelval[0] ) ) == 0 ) /* do not fetch xsd:integer(s) twice also as xsd:double */
				isdval = rdfstore_xsd_deserialize_double( tpj->part.string, &thedval[0] );

			if(	(! islval) &&
				(! isdval) ) {
				isdateval = rdfstore_xsd_deserialize_dateTime( tpj->part.string, &thedateval_tm[0] );

				if( ! isdateval ) {
					isdateval = rdfstore_xsd_deserialize_date( tpj->part.string, &thedateval_tm[0] );
					};
				
				if( ! isdateval ) {
					/* unknown... */
					rdfstore_iterator_close(results);
                                	return NULL;
					};

				rdfstore_xsd_serialize_dateTime( thedateval_tm[0], thedateval[0] ); /* we index xsd:dataTime version anyway */
				};

			if (    (tp->ranges_operator > 6 ) &&
                                (tp->ranges_operator < 11) ) {
				tpj = tpj->next;

				if ( tpj == NULL ) {
					/* error... */
					rdfstore_iterator_close(results);
                                	return NULL;
					};

				/* we can use ranges of the same kind only */
				if(islval!=0) {
					if( rdfstore_xsd_deserialize_integer( tpj->part.string, &thelval[1] ) == 0 ) {
						/* error... */
						rdfstore_iterator_close(results);
                                		return NULL;
						};
				} else if(isdval!=0) {
					if( rdfstore_xsd_deserialize_double( tpj->part.string, &thedval[1] ) == 0 ) {
						/* error... */
						rdfstore_iterator_close(results);
                                		return NULL;
						};
				} else {
					if( rdfstore_xsd_deserialize_dateTime( tpj->part.string, &thedateval_tm[1] ) == 0 ) {
						if( rdfstore_xsd_deserialize_date( tpj->part.string, &thedateval_tm[1] ) == 0 ) {
							/* error... */
							rdfstore_iterator_close(results);
                                			return NULL;
							};
						};

					rdfstore_xsd_serialize_dateTime( thedateval_tm[1], thedateval[1] ); /* we index xsd:dataTime version anyway */
					};
				};

			outsize3=0;

			if (	( tp->ranges_operator == 1 ) ||
				( tp->ranges_operator == 2 ) ) { /* x < a  or x <= a */
				if (rdfstore_flat_store_first( (islval!=0) ? me->xsd_integer : (isdval!=0) ? me->xsd_double : me->xsd_date , &key) == 0) {
					do {
						if(islval!=0) {
							memcpy( &alval, key.data, sizeof(long) );
							if( alval == thelval[0] ) {
								if( tp->ranges_operator == 2 ) { /* x <= a */
									last=1;
								} else {
									RDFSTORE_FREE(key.data);	/* dispose the key fetched above */
									break; /* stop here - anything from the first key till x (excluded) */
									};
							} else if ( alval > thelval[0] ) {
								RDFSTORE_FREE(key.data);
								break;
								};
						} else if(isdval!=0) {
							memcpy( &adval, key.data, sizeof(double) );
							if( adval == thedval[0] ) {
								if( tp->ranges_operator == 2 ) { /* x <= a */
									last=1;
								} else {
									RDFSTORE_FREE(key.data);	/* dispose the key fetched above */
									break; /* stop here - anything from the first key till x (excluded) */
									};
							} else if ( adval > thedval[0] ) {
								RDFSTORE_FREE(key.data);
								break;
								};
						} else {
							memcpy( adateval, key.data, key.size );
							if( strcmp( adateval, thedateval[0] ) == 0 ) {
								if( tp->ranges_operator == 2 ) { /* x <= a */
									last=1;
								} else {
									RDFSTORE_FREE(key.data);	/* dispose the key fetched above */
									break; /* stop here - anything from the first key till x (excluded) */
									};
							} else if ( strcmp( adateval, thedateval[0] ) > 0 ) {
								RDFSTORE_FREE(key.data);
								break;
								};
							};
						err = rdfstore_flat_store_fetch( (islval!=0) ? me->xsd_integer : (isdval!=0) ? me->xsd_double : me->xsd_date, key, &data);
						if (err != 0) {
							if (err != FLAT_STORE_E_NOTFOUND) {
								perror("rdfstore_search");
								fprintf(stderr,"Could not fetch key '%s' for range for store '%s': %s\n", (char *)key.data, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error( (islval!=0) ? me->xsd_integer : (isdval!=0) ? me->xsd_double : me->xsd_date ));
								rdfstore_iterator_close(results);
								return NULL;
							} else {
								continue;
								};
						} else {
							if (outsize3 > 0) {
                                                		me->func_decode(data.size, data.data, &outsize2, me->bits_decode);

                                                		/* or each of them  */
                                                        	outsize3 = rdfstore_bits_or(outsize3, bits2, outsize2, me->bits_decode, bits1);

                                        			outsize3 = rdfstore_bits_shorten(outsize3, bits1);
                                        			bcopy(bits1, bits2, outsize3);   /* slow? */
							} else {
                                                		me->func_decode(data.size, data.data, &outsize3, bits2);
								};
							RDFSTORE_FREE(data.data);
							};

#ifdef RDFSTORE_DEBUG
                                		{
                                		int             j;
						if(islval!=0) {
                                			printf("SEARCH '%ld' <%s '%ld' -->'", (long)alval, ( ( tp->ranges_operator == 2 ) ? "=" : "" ), (long)thelval[0]);
						} else if(isdval!=0) {
                                			printf("SEARCH '%f' <%s '%f' -->'", adval, ( ( tp->ranges_operator == 2 ) ? "=" : "" ), thedval[0]);
						} else {
                                			printf("SEARCH '%s' <%s '%s' -->'", adateval, ( ( tp->ranges_operator == 2 ) ? "=" : "" ), thedateval[0]);
							};
                                		for(j=0;j<8*outsize3;j++) {
                                        		printf("Rec %d %c\n", j, (bits2[j>>3] & (1<<(j&7))) ? '1':'0');
                                        		};
                                		printf("'\n");
                                		}
#endif
			
						if(last) {
							RDFSTORE_FREE(key.data);	/* dispose the key fetched above */
							break; /* x <= a */
							};

						/* hup the next one in b-tree order */
						err = rdfstore_flat_store_next((islval!=0) ? me->xsd_integer : (isdval!=0) ? me->xsd_double : me->xsd_date, key, &data);
						RDFSTORE_FREE(key.data);	/* dispose the previous/current key */
						if (err == 0) {
							key = data;
							};
						} while (err == 0);
					};
			} else if ( tp->ranges_operator == 3 ) { /* x == y */
				/* simple fetch and AND */
				if(islval!=0) {
					key.data = (long*) &thelval[0]; /* should pack int perhaps... */
					key.size = sizeof(long);
				} else if(isdval!=0) {
					key.data = (double*) &thedval[0]; /* should pack int perhaps... */
					key.size = sizeof(double);
				} else {
					key.data = thedateval[0];
					key.size = strlen(thedateval[0])+1;
					};
				err = rdfstore_flat_store_fetch( (islval!=0) ? me->xsd_integer : (isdval!=0) ? me->xsd_double : me->xsd_date, key, &data);
				if (err != 0) {
					if (err != FLAT_STORE_E_NOTFOUND) {
						perror("rdfstore_search");
						fprintf(stderr,"Could not fetch key '%s' for range for store '%s': %s\n", (char *)key.data, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error( (islval!=0) ? me->xsd_integer : (isdval!=0) ? me->xsd_double : me->xsd_date ));
						rdfstore_iterator_close(results);
						return NULL;
					} else {
						/* error or no matches?... */
						rdfstore_iterator_close(results);
						return NULL;
						};
				} else {
					if (outsize3 > 0) {
                                       		me->func_decode(data.size, data.data, &outsize2, me->bits_decode);

                                       		/* or each of them  */
                                               	outsize3 = rdfstore_bits_or(outsize3, bits2, outsize2, me->bits_decode, bits1);

                                       		outsize3 = rdfstore_bits_shorten(outsize3, bits1);
                                       		bcopy(bits1, bits2, outsize3);   /* slow? */
					} else {
                                       		me->func_decode(data.size, data.data, &outsize3, bits2);
						};
					RDFSTORE_FREE(data.data);
					};

#ifdef RDFSTORE_DEBUG
                                {
                                int             j;
				if(islval!=0) {
                                	printf("SEARCH '%ld' == '%ld' -->'", (long)alval, (long)thelval[0]);
				} else if(isdval!=0) {
                                	printf("SEARCH '%f' == '%f' -->'", adval, thedval[0]);
				} else {
                                	printf("SEARCH '%s' == '%s' -->'", adateval, thedateval[0]);
					};
                                for(j=0;j<8*outsize3;j++) {
                                       	printf("Rec %d %c\n", j, (bits2[j>>3] & (1<<(j&7))) ? '1':'0');
                                       	};
                                printf("'\n");
                                }
#endif
			} else if ( tp->ranges_operator == 4 ) { /* x != y */
				if (rdfstore_flat_store_first( (islval!=0) ? me->xsd_integer : (isdval!=0) ? me->xsd_double : me->xsd_date , &key) == 0) {
					do {
						if(islval!=0) {
							memcpy( &alval, key.data, sizeof(long) );
							if( alval == thelval[0] ) {
								/* hup the next one in b-tree order */
								err = rdfstore_flat_store_next((islval!=0) ? me->xsd_integer : (isdval!=0) ? me->xsd_double : me->xsd_date, key, &data);
								RDFSTORE_FREE(key.data);	/* dispose the previous/current key */
								if (err == 0) {
									key = data;
									};
								continue;
								};
						} else if(isdval!=0) {
							memcpy( &adval, key.data, sizeof(double) );
							if( adval == thedval[0] ) {
								/* hup the next one in b-tree order */
								err = rdfstore_flat_store_next((islval!=0) ? me->xsd_integer : (isdval!=0) ? me->xsd_double : me->xsd_date, key, &data);
								RDFSTORE_FREE(key.data);	/* dispose the previous/current key */
								if (err == 0) {
									key = data;
									};
								continue;
								};
						} else {
							memcpy( adateval, key.data, key.size );
							if( strcmp( adateval, thedateval[0] ) == 0 ) {
								/* hup the next one in b-tree order */
								err = rdfstore_flat_store_next((islval!=0) ? me->xsd_integer : (isdval!=0) ? me->xsd_double : me->xsd_date, key, &data);
								RDFSTORE_FREE(key.data);	/* dispose the previous/current key */
								if (err == 0) {
									key = data;
									};
								continue;
								};
							};
						err = rdfstore_flat_store_fetch( (islval!=0) ? me->xsd_integer : (isdval!=0) ? me->xsd_double : me->xsd_date, key, &data);
						if (err != 0) {
							if (err != FLAT_STORE_E_NOTFOUND) {
								perror("rdfstore_search");
								fprintf(stderr,"Could not fetch key '%s' for range for store '%s': %s\n", (char *)key.data, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error( (islval!=0) ? me->xsd_integer : (isdval!=0) ? me->xsd_double : me->xsd_date ));
								rdfstore_iterator_close(results);
								return NULL;
							} else {
								continue;
								};
						} else {
							if (outsize3 > 0) {
                                                		me->func_decode(data.size, data.data, &outsize2, me->bits_decode);

                                                		/* or each of them  */
                                                        	outsize3 = rdfstore_bits_or(outsize3, bits2, outsize2, me->bits_decode, bits1);

                                        			outsize3 = rdfstore_bits_shorten(outsize3, bits1);
                                        			bcopy(bits1, bits2, outsize3);   /* slow? */
							} else {
                                                		me->func_decode(data.size, data.data, &outsize3, bits2);
								};
							RDFSTORE_FREE(data.data);
							};

						/* hup the next one in b-tree order */
						err = rdfstore_flat_store_next((islval!=0) ? me->xsd_integer : (isdval!=0) ? me->xsd_double : me->xsd_date, key, &data);
						RDFSTORE_FREE(key.data);	/* dispose the previous/current key */
						if (err == 0) {
							key = data;
							};
						} while (err == 0);
					};
			} else if (	( tp->ranges_operator == 5 ) ||
					( tp->ranges_operator == 6 ) ) { /* x >= a  or x > a */
				if(islval!=0) {
					data.data = (long*) &thelval[0]; /* should pack int perhaps... */
					data.size = sizeof(long);
				} else if(isdval!=0) {
					data.data = (double*) &thedval[0]; /* should pack int perhaps... */
					data.size = sizeof(double);
				} else {
					data.data = thedateval[0];
					data.size = strlen(thedateval[0])+1;
					};
				if (rdfstore_flat_store_from( (islval!=0) ? me->xsd_integer : (isdval!=0) ? me->xsd_double : me->xsd_date, data, &key) == 0) {
					do {
						if(islval!=0) {
							memcpy( &alval, key.data, sizeof(long) );
							if( alval == thelval[0] ) {
								if( tp->ranges_operator == 6 ) { /* x > a */
									/* hup the next one in b-tree order */
									err = rdfstore_flat_store_next((islval!=0) ? me->xsd_integer : (isdval!=0) ? me->xsd_double : me->xsd_date, key, &data);
									RDFSTORE_FREE(key.data);	/* dispose the previous/current key */
									if (err == 0) {
										key = data;
										continue;
									} else {
										break;
										};
									};
								};
						} else if(isdval!=0) {
							memcpy( &adval, key.data, sizeof(double) );
							if( adval == thedval[0] ) {
								if( tp->ranges_operator == 6 ) { /* x > a */
									/* hup the next one in b-tree order */
									err = rdfstore_flat_store_next((islval!=0) ? me->xsd_integer : (isdval!=0) ? me->xsd_double : me->xsd_date, key, &data);
									RDFSTORE_FREE(key.data);	/* dispose the previous/current key */
									if (err == 0) {
										key = data;
										continue;
									} else {
										break;
										};
									};
								};
						} else {
							memcpy( adateval, key.data, key.size );
							if( strcmp( adateval, thedateval[0] ) == 0 ) {
								if( tp->ranges_operator == 6 ) { /* x > a */
									/* hup the next one in b-tree order */
									err = rdfstore_flat_store_next((islval!=0) ? me->xsd_integer : (isdval!=0) ? me->xsd_double : me->xsd_date, key, &data);
									RDFSTORE_FREE(key.data);	/* dispose the previous/current key */
									if (err == 0) {
										key = data;
										continue;
									} else {
										break;
										};
									};
								};
							};
						err = rdfstore_flat_store_fetch( (islval!=0) ? me->xsd_integer : (isdval!=0) ? me->xsd_double : me->xsd_date, key, &data);
						if (err != 0) {
							if (err != FLAT_STORE_E_NOTFOUND) {
								perror("rdfstore_search");
								fprintf(stderr,"Could not fetch key '%s' for range for store '%s': %s\n", (char *)key.data, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error( (islval!=0) ? me->xsd_integer : (isdval!=0) ? me->xsd_double : me->xsd_date ));
								rdfstore_iterator_close(results);
								return NULL;
							} else {
								continue;
								};
						} else {
							if (outsize3 > 0) {
                                                		me->func_decode(data.size, data.data, &outsize2, me->bits_decode);

                                                		/* or each of them  */
                                                        	outsize3 = rdfstore_bits_or(outsize3, bits2, outsize2, me->bits_decode, bits1);

                                        			outsize3 = rdfstore_bits_shorten(outsize3, bits1);
                                        			bcopy(bits1, bits2, outsize3);   /* slow? */
							} else {
                                                		me->func_decode(data.size, data.data, &outsize3, bits2);
								};
							RDFSTORE_FREE(data.data);
							};

#ifdef RDFSTORE_DEBUG
                                		{
                                		int             j;
						if(islval!=0) {
                                			printf("SEARCH '%ld' >%s '%ld' -->'", (long)alval, ( ( tp->ranges_operator == 5 ) ? "=" : "" ), (long)thelval[0]);
						} else if(isdval!=0) {
                                			printf("SEARCH '%f' >%s '%f' -->'", adval, ( ( tp->ranges_operator == 5 ) ? "=" : "" ), thedval[0]);
						} else {
                                			printf("SEARCH '%s' >%s '%s' -->'", adateval, ( ( tp->ranges_operator == 5 ) ? "=" : "" ), thedateval[0]);
							};
                                		for(j=0;j<8*outsize3;j++) {
                                        		printf("Rec %d %c\n", j, (bits2[j>>3] & (1<<(j&7))) ? '1':'0');
                                        		};
                                		printf("'\n");
                                		}
#endif
			
						/* hup the next one in b-tree order */
						err = rdfstore_flat_store_next((islval!=0) ? me->xsd_integer : (isdval!=0) ? me->xsd_double : me->xsd_date, key, &data);
						RDFSTORE_FREE(key.data);	/* dispose the previous/current key */
						if (err == 0) {
							key = data;
							};
						} while (err == 0);
					};
			} else if (	( tp->ranges_operator > 6 ) &&
					( tp->ranges_operator < 11 ) ) { /* 2 vars ranges */

				/* b > a || b >= a */
				if(islval!=0) {
					data.data = (long*) &thelval[0]; /* should pack int perhaps... */
					data.size = sizeof(long);
				} else if(isdval!=0) {
					data.data = (double*) &thedval[0]; /* should pack int perhaps... */
					data.size = sizeof(double);
				} else {
					data.data = thedateval[0];
					data.size = strlen(thedateval[0])+1;
					};
				if (rdfstore_flat_store_from( (islval!=0) ? me->xsd_integer : (isdval!=0) ? me->xsd_double : me->xsd_date, data, &key) == 0) {
					do {
						if(islval!=0) {
							memcpy( &alval, key.data, sizeof(long) );
							if( alval == thelval[0] ) {
								if(	( tp->ranges_operator == 7 ) ||
									( tp->ranges_operator == 10 ) ) { /* x > a */
									/* hup the next one in b-tree order */
									err = rdfstore_flat_store_next((islval!=0) ? me->xsd_integer : (isdval!=0) ? me->xsd_double : me->xsd_date, key, &data);
									RDFSTORE_FREE(key.data);	/* dispose the previous/current key */
									if (err == 0) {
										key = data;
										continue;
									} else {
										break;
										};
									};
								};
						} else if(isdval!=0) {
							memcpy( &adval, key.data, sizeof(double) );
							if( adval == thedval[0] ) {
								if(	( tp->ranges_operator == 7 ) ||
									( tp->ranges_operator == 10 ) ) { /* x > a */
									/* hup the next one in b-tree order */
									err = rdfstore_flat_store_next((islval!=0) ? me->xsd_integer : (isdval!=0) ? me->xsd_double : me->xsd_date, key, &data);
									RDFSTORE_FREE(key.data);	/* dispose the previous/current key */
									if (err == 0) {
										key = data;
										continue;
									} else {
										break;
										};
									};
								};
						} else {
							memcpy( adateval, key.data, key.size );
							if( strcmp( adateval, thedateval[0] ) == 0 ) {
								if(	( tp->ranges_operator == 7 ) ||
									( tp->ranges_operator == 10 ) ) { /* x > a */
									/* hup the next one in b-tree order */
									err = rdfstore_flat_store_next((islval!=0) ? me->xsd_integer : (isdval!=0) ? me->xsd_double : me->xsd_date, key, &data);
									RDFSTORE_FREE(key.data);	/* dispose the previous/current key */
									if (err == 0) {
										key = data;
										continue;
									} else {
										break;
										};
									};
								};
							};
						err = rdfstore_flat_store_fetch( (islval!=0) ? me->xsd_integer : (isdval!=0) ? me->xsd_double : me->xsd_date, key, &data);
						if (err != 0) {
							if (err != FLAT_STORE_E_NOTFOUND) {
								perror("rdfstore_search");
								fprintf(stderr,"Could not fetch key '%s' for range for store '%s': %s\n", (char *)key.data, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error( (islval!=0) ? me->xsd_integer : (isdval!=0) ? me->xsd_double : me->xsd_date ));
								rdfstore_iterator_close(results);
								return NULL;
							} else {
								continue;
								};
						} else {
							if (outsize3 > 0) {
                                                		me->func_decode(data.size, data.data, &outsize2, me->bits_decode);

                                                		/* or each of them  */
                                                        	outsize3 = rdfstore_bits_or(outsize3, bits2, outsize2, me->bits_decode, bits1);

                                        			outsize3 = rdfstore_bits_shorten(outsize3, bits1);
                                        			bcopy(bits1, bits2, outsize3);   /* slow? */
							} else {
                                                		me->func_decode(data.size, data.data, &outsize3, bits2);
								};
							RDFSTORE_FREE(data.data);
							};

#ifdef RDFSTORE_DEBUG
                                		{
                                		int             j;
						if(islval!=0) {
                                			printf("SEARCH '%ld' >%s '%ld' -->'", (long)alval, ( ( ( tp->ranges_operator == 8 ) || ( tp->ranges_operator == 9 ) ) ? "=" : "" ), (long)thelval[0]);
						} else if(isdval!=0) {
                                			printf("SEARCH '%f' >%s '%f' -->'", adval, ( ( ( tp->ranges_operator == 8 ) || ( tp->ranges_operator == 9 ) ) ? "=" : "" ), thedval[0]);
						} else {
                                			printf("SEARCH '%s' >%s '%s' -->'", adateval, ( ( ( tp->ranges_operator == 8 ) || ( tp->ranges_operator == 9 ) ) ? "=" : "" ), thedateval[0]);
							};
                                		for(j=0;j<8*outsize3;j++) {
                                        		printf("Rec %d %c\n", j, (bits2[j>>3] & (1<<(j&7))) ? '1':'0');
                                        		};
                                		printf("'\n");
                                		}
#endif
			
						/* hup the next one in b-tree order */
						err = rdfstore_flat_store_next((islval!=0) ? me->xsd_integer : (isdval!=0) ? me->xsd_double : me->xsd_date, key, &data);
						RDFSTORE_FREE(key.data);	/* dispose the previous/current key */
						if (err == 0) {
							key = data;
							};
						} while (err == 0);
					};

				/* no matches */
				if (!outsize3)
					return results;

				/* AND in all numerical comparinsons to previous rdf:datatype, words, subjects, predicates, objects and languages now */
                        	if (outsize1 > 0) {
                                	/* and them */
                                	outsize1 = rdfstore_bits_and(outsize1, bits, outsize3, bits2, bits1);
                                	outsize1 = rdfstore_bits_shorten(outsize1, bits1);

                                	/* cannot join */
                                	if (!outsize1) {
                                        	return results;
                                        	};

                                	bcopy(bits1, bits, outsize1);   /* slow? */
                        	} else {
                                	/* or OR them */
                                	outsize1 = rdfstore_bits_or(outsize3, bits, outsize3, bits2, bits1); 
                                	bcopy(bits1, bits, outsize3);   /* slow? */
                                	};

				/* b < c || b <= c */
				outsize3=0;

				if (rdfstore_flat_store_first( (islval!=0) ? me->xsd_integer : (isdval!=0) ? me->xsd_double : me->xsd_date , &key) == 0) {
					do {
						if(islval!=0) {
							memcpy( &alval, key.data, sizeof(long) );
							if( alval == thelval[1] ) {
								if(	( tp->ranges_operator == 9 ) ||
									( tp->ranges_operator == 10 ) ) { /* x <= a */
									last=1;
								} else {
									RDFSTORE_FREE(key.data);	/* dispose the key fetched above */
									break; /* stop here - anything from the first key till x (excluded) */
									};
							} else if ( alval > thelval[1] ) {
								RDFSTORE_FREE(key.data);
								break;
								};
						} else if(isdval!=0) {
							memcpy( &adval, key.data, sizeof(double) );
							if( adval == thedval[1] ) {
								if(	( tp->ranges_operator == 9 ) ||
									( tp->ranges_operator == 10 ) ) { /* x <= a */
									last=1;
								} else {
									RDFSTORE_FREE(key.data);	/* dispose the key fetched above */
									break; /* stop here - anything from the first key till x (excluded) */
									};
							} else if( adval > thedval[1] ) {
								RDFSTORE_FREE(key.data);
								break;
								};
						} else {
							memcpy( adateval, key.data, key.size );
							if( strcmp( adateval, thedateval[1] ) == 0 ) {
								if(	( tp->ranges_operator == 9 ) ||
									( tp->ranges_operator == 10 ) ) { /* x <= a */
									last=1;
								} else {
									RDFSTORE_FREE(key.data);	/* dispose the key fetched above */
									break; /* stop here - anything from the first key till x (excluded) */
									};
							} else if( strcmp( adateval, thedateval[1] ) > 0 ) {
								RDFSTORE_FREE(key.data);
								break;
								};
							};
						err = rdfstore_flat_store_fetch( (islval!=0) ? me->xsd_integer : (isdval!=0) ? me->xsd_double : me->xsd_date, key, &data);
						if (err != 0) {
							if (err != FLAT_STORE_E_NOTFOUND) {
								perror("rdfstore_search");
								fprintf(stderr,"Could not fetch key '%s' for range for store '%s': %s\n", (char *)key.data, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error( (islval!=0) ? me->xsd_integer : (isdval!=0) ? me->xsd_double : me->xsd_date ));
								rdfstore_iterator_close(results);
								return NULL;
							} else {
								continue;
								};
						} else {
							if (outsize3 > 0) {
                                                		me->func_decode(data.size, data.data, &outsize2, me->bits_decode);

                                                		/* or each of them  */
                                                        	outsize3 = rdfstore_bits_or(outsize3, bits2, outsize2, me->bits_decode, bits1);

                                        			outsize3 = rdfstore_bits_shorten(outsize3, bits1);
                                        			bcopy(bits1, bits2, outsize3);   /* slow? */
							} else {
                                                		me->func_decode(data.size, data.data, &outsize3, bits2);
								};
							RDFSTORE_FREE(data.data);
							};

#ifdef RDFSTORE_DEBUG
                                		{
                                		int             j;
						if(islval!=0) {
                                			printf("SEARCH '%ld' <%s '%ld' -->'", (long)alval, ( ( ( tp->ranges_operator == 9 ) || ( tp->ranges_operator == 10 ) ) ? "=" : "" ), (long)thelval[1]);
						} else if(isdval!=0) {
                                			printf("SEARCH '%f' <%s '%f' -->'", adval, ( ( ( tp->ranges_operator == 9 ) || ( tp->ranges_operator == 10 ) ) ? "=" : "" ), thedval[1]);
						} else {
                                			printf("SEARCH '%s' <%s '%s' -->'", adateval, ( ( ( tp->ranges_operator == 9 ) || ( tp->ranges_operator == 10 ) ) ? "=" : "" ), thedateval[1]);
							};
                                		for(j=0;j<8*outsize3;j++) {
                                        		printf("Rec %d %c\n", j, (bits2[j>>3] & (1<<(j&7))) ? '1':'0');
                                        		};
                                		printf("'\n");
                                		}
#endif
			
						if(last) {
							RDFSTORE_FREE(key.data);	/* dispose the key fetched above */
							break; /* x <= a */
							};

						/* hup the next one in b-tree order */
						err = rdfstore_flat_store_next((islval!=0) ? me->xsd_integer : (isdval!=0) ? me->xsd_double : me->xsd_date, key, &data);
						RDFSTORE_FREE(key.data);	/* dispose the previous/current key */
						if (err == 0) {
							key = data;
							};
						} while (err == 0);
					};
				};

			/* no matches */
			if (!outsize3)
				return results;

			/* AND in all numerical comparinsons to previous rdf:datatype, words, subjects, predicates, objects and languages now */
                        if (outsize1 > 0) {
                                /* and them */
                                outsize1 = rdfstore_bits_and(outsize1, bits, outsize3, bits2, bits1);
                                outsize1 = rdfstore_bits_shorten(outsize1, bits1);

                                /* cannot join */
                                if (!outsize1) {
                                        return results;
                                        };

                                bcopy(bits1, bits, outsize1);   /* slow? */
                        } else {
                                /* or OR them */
                                outsize1 = rdfstore_bits_or(outsize3, bits, outsize3, bits2, bits1); 
                                bcopy(bits1, bits, outsize3);   /* slow? */
                                };

#ifdef RDFSTORE_DEBUG
                                {
                                int             j;
				if(islval!=0) {
                                	printf("SEARCH X %s '%ld' -->'", (tp->ranges_operator ==1) ? "<" :
									 (tp->ranges_operator ==2) ? "<=" :
									 (tp->ranges_operator ==3) ? "==" :
									 (tp->ranges_operator ==4) ? "!=" :
									 (tp->ranges_operator ==5) ? ">=": 
									 (tp->ranges_operator ==6) ? ">": 
									 (tp->ranges_operator ==7) ? "a < b < c": 
									 (tp->ranges_operator ==8) ? "a <= b < c": 
									 (tp->ranges_operator ==9) ? "a <= b <= c": "a < b <= c", (long)thelval[0]);
				} else {
                                	printf("SEARCH X %s '%f' -->'", (tp->ranges_operator ==1) ? "<" :
									(tp->ranges_operator ==2) ? "<=" :
									(tp->ranges_operator ==3) ? "==" :
									(tp->ranges_operator ==4) ? "!=" :
									(tp->ranges_operator ==5) ? ">=": 
									(tp->ranges_operator ==6) ? ">": 
									(tp->ranges_operator ==7) ? "a < b < c": 
									(tp->ranges_operator ==8) ? "a <= b < c": 
									(tp->ranges_operator ==9) ? "a <= b <= c": "a < b <= c", thedval[0]);
					};
                                for(j=0;j<8*outsize1;j++) {
                                        printf("Rec %d %c\n", j, (bits[j>>3] & (1<<(j&7))) ? '1':'0');
                                        };
                                printf("'\n");
                                }
#endif
			};
		};

	if ( tp->contexts != NULL ) {
		outsize3=0;
		tpj = tp->contexts;
		do {

			/* compute subject hashcode */
			tpj->part.node->hashcode = rdfstore_digest_get_node_hashCode(tpj->part.node, 0);

			packInt(tpj->part.node->hashcode, outbuf);
			key.data = outbuf;
			key.size = sizeof(int);

			err = rdfstore_flat_store_fetch(me->contexts, key, &data);
			if (err != 0) {
				if (err != FLAT_STORE_E_NOTFOUND) {
					perror("rdfstore_search");
					fprintf(stderr,"Could not fetch key '%s' in contexts for store '%s': %s\n", (char *)key.data, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->contexts));
					rdfstore_iterator_close(results);
					return NULL;
				} else {
					continue;
				};
			} else {
				if (outsize3 > 0) {
					me->func_decode(data.size, data.data, &outsize2, me->bits_decode);

					if (tp->contexts_operator == 1) {
                                        	/* and them i.e. URL1, URL2, URL3....URLn */
                                        	outsize3 = rdfstore_bits_and(outsize3, bits2, outsize2, me->bits_decode, bits1);
                                        } else if (tp->contexts_operator == 0) {
                                        	/* or them i.e. URL1, URL2, URL3....URLn */
                                                outsize3 = rdfstore_bits_or(outsize3, bits2, outsize2, me->bits_decode, bits1);
                                        } else if (tp->contexts_operator == 2) {
                                        	fprintf(stderr,"The boolean NOT operator on contexts is not implemented yet :)\n"); 
                                                };

                                        outsize3 = rdfstore_bits_shorten(outsize3, bits1);
                                        bcopy(bits1, bits2, outsize3);   /* slow? */
				} else {
					me->func_decode(data.size, data.data, &outsize3, bits2);
					};
				RDFSTORE_FREE(data.data);
				};

#ifdef RDFSTORE_DEBUG
                                {
                                int             j;
                                printf("SEARCH contexts[%d] for C -->'",i);
                                for(j=0;j<8*outsize3;j++) {
                                        printf("Rec %d %c\n", j, (bits2[j>>3] & (1<<(j&7))) ? '1':'0');
                                        };
                                printf("'\n");
                                }
#endif
				} while ( ( tpj = tpj->next ) != NULL );

		/* no contexts matched? */
		if (!outsize3)
			return results;

		/* AND in all contexts to previous words now */
		if (outsize1 > 0) {
			/* and them */
			outsize1 = rdfstore_bits_and(outsize1, bits, outsize3, bits2, bits1);
			outsize1 = rdfstore_bits_shorten(outsize1, bits1);

			/* cannot join */
			if (!outsize1) {
				return results;
				};
			bcopy(bits1, bits, outsize1);	/* slow? */
		} else {
			outsize1=outsize3;
			bcopy(bits2, bits, outsize3);	/* slow? */
			};

#ifdef RDFSTORE_DEBUG
                {
                int             j;
                printf("SEARCH contexts for C -->'");
                for(j=0;j<8*outsize1;j++) {
                	printf("Rec %d %c\n", j, (bits[j>>3] & (1<<(j&7))) ? '1':'0');
                       	};
                printf("'\n");
                }
#endif
		};

#ifdef RDFSTORE_DEBUG
	{
		int             i;
		printf("SEARCH (whole) -->'");
		for(i=0;i<8*outsize1;i++) {
			printf("Rec %d %c\n", i, (bits[i>>3] & (1<<(i&7))) ? '1':'0');           
                        };
		printf("'\n");
	}
#endif

	/* just copy the bits through the iterator array */
	memcpy(results->ids, bits, outsize1);
	results->ids_size = outsize1;
	/*
	 * just copy the bits through the iterator array shifting them to the
	 * right position (odd or even)
	 */
	pos = 0;
	/* count the ones (inefficient still) */
	while ((pos = rdfstore_bits_getfirstsetafter(outsize1, bits, pos)) < 8 * outsize1) {
		results->size++;
		pos++;
	};

#ifdef RDFSTORE_DEBUG
	{
		printf("Actually matched (bits only) '");
		for(i=0;i<8*results->ids_size;i++) {
                        printf("%c", (results->ids[i>>3] & (1<<(i&7))) ? '1':'0');
                        };
		printf("' (%d/%d)\n", results->ids_size, results->size);
	}
	{
		RDF_Statement  *r;
		rdfstore_iterator *results1;
		printf("search MATCHED (statements) :\n");
		results1 = rdfstore_iterator_duplicate(results);
		for (r = rdfstore_iterator_first(results1);
		     rdfstore_iterator_hasnext(results1);
		     r = rdfstore_iterator_next(results1)) {
			fprintf(stderr,"\tS='%s'\n", r->subject->value.resource.identifier);
			fprintf(stderr,"\tP='%s'\n", r->predicate->value.resource.identifier);
			if (r->object->type != 1) {
				fprintf(stderr,"\tO='%s'\n", r->object->value.resource.identifier);
			} else {
				fprintf(stderr,"\tOLIT='%s'", r->object->value.literal.string);
				fprintf(stderr," LANG='%s'", r->object->value.literal.lang);
				fprintf(stderr," TYPE='%s'", r->object->value.literal.dataType);
				fprintf(stderr," PARSETYPE='%d'", r->object->value.literal.parseType);
				fprintf(stderr,"\n");
			};
		};
		rdfstore_iterator_close(results1);
	};
#endif

	return results;		/* we should distinguish between errors and
				 * empty return values in a future version */
	};

/*
 * "get all relevant RDF about this thing in the repository"
 *
 * i.e. get a "concise bounded description" of a given resource/thing
 * 
 * Given a URI denoting some resource, a concise bounded description of that resource is a set of RDF statements, 
 * explicitly asserted and/or inferred, comprised of the following:
 *
 * 	1. All statements where the subject of the statement denotes the resource in question; and
 *
 *	2. Recursively, for all statements included in the description thus far, for all anonymous node objects,
 *         all statements where the subject of the statement denotes anonymous resource in question; and
 *
 *	3. Recursively, for all statements included in the description thus far, for all reifications of each statement,
 *         the concise bounded description of each reification.
 *
 * This results in an RDF graph where the terminal nodes are either URI references, literals, or anonymous nodes not 
 * serving as the subject of any statement, insofar as the describing agent is aware; effectively constraining the description
 * to only those statements made explicitly about the resource in question or about other directly related anonymous resources, 
 * and any associated reifications. (http://sw.nokia.com/uriqa/URIQA.html)
 *
 * see also http://www.joseki.org/RDF_data_objects.html and http://lists.w3.org/Archives/Public/www-rdf-dspace/2003Jun/0047.html
 *
 * NOTE: once connections table will be place this operations should be carried out much more efficently
 *
 */

int
_rdfstore_recursive_fetch_object( rdfstore * me, 
				  RDF_Node * resource, 
				  unsigned char * given_context, 
				  unsigned int given_context_size, 
				  int level, rdfstore_iterator * out ) {
        rdfstore_iterator *subject_results;
        DBT             key;
        int             err = 0;
        unsigned int    outsize = 0;
        unsigned char   outbuf[256];
	RDF_Node       *sub_object = NULL;

	if(level==RDFSTORE_MAX_FETCH_OBJECT_DEEPNESS) { /* fire safe :) */
		return 0;
		};

	memset(&key, 0, sizeof(key));

	subject_results = (rdfstore_iterator *) RDFSTORE_MALLOC(sizeof(rdfstore_iterator));
        if (subject_results == NULL) {
                perror("recursive_fetch_object");
		fprintf(stderr,"Cannot create results cursor/iterator for store '%s'\n", (me->name != NULL) ? me->name : "(in-memory)");
                return -1;
                };
        subject_results->store = me;
        subject_results->store->attached++;
        /* bzero(subject_results->ids,sizeof(unsigned char)*(RDFSTORE_MAXRECORDS_BYTES_SIZE)); */
        subject_results->remove_holes = 0;      /* reset the total number of holes */
        subject_results->st_counter = 0;
        subject_results->pos = 0;
        subject_results->ids_size = 0;
        subject_results->size = 0;

        /* compute subject hashcode */
        resource->hashcode = rdfstore_digest_get_node_hashCode(resource, 0);

        packInt(resource->hashcode, outbuf);
        key.data = outbuf;
        key.size = sizeof(int);

        err = rdfstore_flat_store_fetch_compressed(me->subjects, me->func_decode, key, &outsize, me->bits_decode);
        if (err != 0) {
                if (err != FLAT_STORE_E_NOTFOUND) {
                	perror("recursive_fetch_object");
                        fprintf(stderr,"Could not fetch subject resource '%s' for store '%s': %s\n", resource->value.resource.identifier, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->subjects));
                        rdfstore_iterator_close(subject_results);
                        return -1;
                } else {
                        outsize = 0;
                        };
                };

	/* just keep the ones not visited to avoid recursion i.e. bits set in subjects but not set in out */
	subject_results->ids_size = rdfstore_bits_exor( outsize, me->bits_decode, out->ids_size, out->ids, subject_results->ids );

	if(	( given_context != NULL ) &&
		( given_context_size > 0 ) ) {
		/* AND context constraint if passed */
		subject_results->ids_size = rdfstore_bits_and( subject_results->ids_size, subject_results->ids, 
								given_context_size, given_context, me->bits_decode );
		bcopy(me->bits_decode, subject_results->ids, subject_results->ids_size);
		};
        subject_results->ids_size = rdfstore_bits_shorten( subject_results->ids_size, subject_results->ids);
	
	/* count the ones (inefficient still) */
	subject_results->size = 0;
        subject_results->pos = 0;
        while ( (subject_results->pos = rdfstore_bits_getfirstsetafter(subject_results->ids_size, 
							subject_results->ids, subject_results->pos)) < 8*(subject_results->ids_size) ) {
                subject_results->pos++;
                subject_results->size++;
                };
        subject_results->pos = 0;

	/* scan the obtained iterator */
        while ( ( sub_object = rdfstore_iterator_each_object ( subject_results ) ) != NULL ) {
		if ( sub_object->type == 2 ) {
			if ( _rdfstore_recursive_fetch_object( me, sub_object, given_context, given_context_size, 
									level+1, out ) == -1 ) {/* recurse */
				if ( sub_object->type == 1 ) {
                       			if ( sub_object->value.literal.dataType != NULL )
                               			RDFSTORE_FREE( sub_object->value.literal.dataType );
                       			RDFSTORE_FREE( sub_object->value.literal.string );
                		} else {
                       			RDFSTORE_FREE( sub_object->value.resource.identifier );
                       			};
                		RDFSTORE_FREE( sub_object );
        			rdfstore_iterator_close(subject_results);
				return -1;
				};
			};

#ifdef RDFSTORE_DEBUG
		if (sub_object->type != 1) {
			fprintf(stderr,"\t>>>GOT OBJECT='%s'\n", sub_object->value.resource.identifier);
		} else {
			fprintf(stderr,"\t>>>GOT OLIT='%s'", sub_object->value.literal.string);
			fprintf(stderr," LANG='%s'", sub_object->value.literal.lang);
			fprintf(stderr," TYPE='%s'", sub_object->value.literal.dataType);
			fprintf(stderr," PARSETYPE='%d'", sub_object->value.literal.parseType);
			fprintf(stderr,"\n");
			};
#endif

		if ( sub_object->type == 1 ) {
                        if ( sub_object->value.literal.dataType != NULL )
                                RDFSTORE_FREE( sub_object->value.literal.dataType );
                        RDFSTORE_FREE( sub_object->value.literal.string );
                } else {
                        RDFSTORE_FREE( sub_object->value.resource.identifier );
                        };
                RDFSTORE_FREE( sub_object );
		};

	/* add the processed ones to out (main results) */
	out->ids_size = rdfstore_bits_or( out->ids_size, out->ids, subject_results->ids_size, subject_results->ids, me->bits_decode );
	bcopy(me->bits_decode, out->ids, out->ids_size);

	/* count the ones (inefficient still) */
	out->size = 0;
        out->pos = 0;
        while ( (out->pos = rdfstore_bits_getfirstsetafter(out->ids_size, out->ids, out->pos)) < 8*(out->ids_size) ) {
                out->pos++;
                out->size++;
                };
        out->pos = 0;

        rdfstore_iterator_close(subject_results);

        return 0;
	};

/*
   Work in progress implementation of http://www.w3.org/Submission/CBD/ - it does not implement "Inverse Functional Bounded Description" yet
   See also http://www.w3.org/TR/rdf-sparql-query/#describe
   */
rdfstore_iterator *
rdfstore_fetch_object( rdfstore * me, RDF_Node * resource, RDF_Node * given_context ) {
	RDF_Node       *context = NULL;
	rdfstore_iterator *results;
        DBT             key;
        int             err = 0;
        unsigned int    context_outsize = 0;
        unsigned char   outbuf[256];
	static unsigned char bits[RDFSTORE_MAXRECORDS_BYTES_SIZE];

	/* just start from a resource (URI or bNode) and follow its associated bNodes (connected to its statements) */
	if ( (resource == NULL) ||
	     (resource->type == RDFSTORE_NODE_TYPE_LITERAL) ||
	     (resource->value.resource.identifier == NULL) ||
	     (	(given_context != NULL) &&
		(given_context->value.resource.identifier == NULL)) )
		return NULL;

	/* use given context instead */
	context = given_context;

	memset(&key, 0, sizeof(key));

	if(context!=NULL) {
        	/* compute context hashcode */
        	context->hashcode = rdfstore_digest_get_node_hashCode(context, 0);

        	packInt(context->hashcode, outbuf);
        	key.data = outbuf;
        	key.size = sizeof(int);

        	err = rdfstore_flat_store_fetch_compressed(me->contexts, me->func_decode, key, &context_outsize, me->bits_decode);
        	if (err != 0) {
                	if (err != FLAT_STORE_E_NOTFOUND) {
                        	perror("rdfstore_fetch_object");
                        	fprintf(stderr,"Could not fetch context resource '%s' for store '%s': %s\n", context->value.resource.identifier, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->contexts));
                        	return NULL;
                	} else {
                        	context_outsize = 0;
                        	};
                	};
		bcopy(me->bits_decode, bits, context_outsize);
		};

	results = (rdfstore_iterator *) RDFSTORE_MALLOC(sizeof(rdfstore_iterator));
	if (results == NULL) {
		perror("rdfstore_fetch_object");
		fprintf(stderr,"Cannot create results cursor/iterator for store '%s'\n", (me->name != NULL) ? me->name : "(in-memory)");
		return NULL;
		};
	results->store = me;
	results->store->attached++;
	/*bzero(results->ids,sizeof(unsigned char)*(RDFSTORE_MAXRECORDS_BYTES_SIZE));*/
	results->remove_holes = 0;	/* reset the total number of holes */
	results->st_counter = 0;
	results->pos = 0;
	results->ids_size = 0;
	results->size = 0;

#ifdef RDFSTORE_DEBUG
	{
	char           *buff;
	fprintf(stderr,"FETCH OBJECT:\n");
	fprintf(stderr,"\tresource='%s'\n", resource->value.resource.identifier);
	if (context != NULL) {
		fprintf(stderr,"\tC='%s'\n", context->value.resource.identifier);
		};
	if ((buff = rdfstore_ntriples_node(resource)) != NULL) {
		fprintf(stderr," Resource (N-Triples part): %s\n", buff);
		RDFSTORE_FREE(buff);
		};
	}
#endif

	if(	(context!=NULL) &&
		(context_outsize==0) )
		return results; /* empty */

	/* start visiting the graph from this subject resource downwards... */
	if ( _rdfstore_recursive_fetch_object( me, resource, ((context!=NULL) ? bits : NULL ), ((context!=NULL) ? context_outsize : 0 ), 
							0, results ) == -1 ) {
		rdfstore_iterator_close(results);
		return NULL;
		};

#ifdef RDFSTORE_DEBUG
	{
	int i=0;
	printf("Actually matched (bits only) '");
	for(i=0;i<8*results->ids_size;i++) {
        	printf("%c", (results->ids[i>>3] & (1<<(i&7))) ? '1':'0');
                };
	printf("' (%d/%d)\n", results->ids_size, results->size);
	}
	{
	RDF_Statement  *r;
	rdfstore_iterator *results1;
	printf("fetch_object MATCHED (statements) :\n");
	results1 = rdfstore_iterator_duplicate(results);
	for (r = rdfstore_iterator_first(results1);
	     rdfstore_iterator_hasnext(results1);
	     r = rdfstore_iterator_next(results1)) {
		fprintf(stderr,"\tS='%s'\n", r->subject->value.resource.identifier);
		fprintf(stderr,"\tP='%s'\n", r->predicate->value.resource.identifier);
		if (r->object->type != 1) {
			fprintf(stderr,"\tO='%s'\n", r->object->value.resource.identifier);
		} else {
			fprintf(stderr,"\tOLIT='%s'", r->object->value.literal.string);
			fprintf(stderr," LANG='%s'", r->object->value.literal.lang);
			fprintf(stderr," TYPE='%s'", r->object->value.literal.dataType);
			fprintf(stderr," PARSETYPE='%d'", r->object->value.literal.parseType);
			fprintf(stderr,"\n");
			};
	};
	rdfstore_iterator_close(results1);
	};
#endif

	return results;
	};

/* end fetch object */

/* return != 0 if not contained */
int 
rdfstore_contains(
		  rdfstore * me,
		  RDF_Statement * statement,
		  RDF_Node * given_context
)
{
	RDF_Node       *context = NULL;
	int             err = 0;
	rdf_store_digest_t 	 hc = 0;
	DBT             key, data;
	unsigned char   outbuf[256];

	if ((statement == NULL) ||
	    (statement->subject == NULL) ||
	    (statement->predicate == NULL) ||
	    (statement->subject->value.resource.identifier == NULL) ||
	    (statement->predicate->value.resource.identifier == NULL) ||
	    (statement->object == NULL) ||
	    ((statement->object->type != 1) &&
	     (statement->object->value.resource.identifier == NULL)) ||
	    ((given_context != NULL) &&
	     (given_context->value.resource.identifier == NULL)) ||
	    ((statement->node != NULL) &&
	     (statement->node->value.resource.identifier == NULL)))
		return -1;

	if (given_context == NULL) {
		if (statement->context != NULL)
			context = statement->context;
	} else {
		/* use given context instead */
		context = given_context;
		};

#ifdef RDFSTORE_DEBUG
	{
		char           *buff;
		fprintf(stderr,"CONTAINS:\n");
		fprintf(stderr,"\tS='%s'\n", statement->subject->value.resource.identifier);
		fprintf(stderr,"\tP='%s'\n", statement->predicate->value.resource.identifier);
		if (statement->object->type != 1) {
			fprintf(stderr,"\tO='%s'\n", statement->object->value.resource.identifier);
		} else {
			fprintf(stderr,"\tOLIT='%s'", statement->object->value.literal.string);
			fprintf(stderr," LANG='%s'", statement->object->value.literal.lang);
			fprintf(stderr," TYPE='%s'", statement->object->value.literal.dataType);
			fprintf(stderr," PARSETYPE='%d'", statement->object->value.literal.parseType);
			fprintf(stderr,"\n");
			};
		if (context != NULL) {
			fprintf(stderr,"\tC='%s'\n", context->value.resource.identifier);
		};
		if (statement->node != NULL)
			fprintf(stderr,"\tSRES='%s'\n", statement->node->value.resource.identifier);
		if ((buff = rdfstore_ntriples_statement(statement, context)) != NULL) {
			fprintf(stderr," N-triples: %s\n", buff);
			RDFSTORE_FREE(buff);
		};
	}
#endif

	memset(&key, 0, sizeof(key));
	memset(&data, 0, sizeof(data));

	/* compute statement hashcode */
	hc = rdfstore_digest_get_statement_hashCode(statement, context);

	/* cache the hashcode if the statement has a "proper" identity */
	if ((given_context == NULL) &&
	    (me->context == NULL))
		statement->hashcode = hc;

	/* look for the statement internal identifier */
	packInt(hc, outbuf);

#ifdef RDFSTORE_DEBUG
	{
		int             i = 0;
		printf("Statement hashcode is '%d' while packed is '", hc);
		for (i = 0; i < sizeof(int); i++) {
			printf("%02X", outbuf[i]);
		};
		printf("'\n");
	}
#endif

	key.data = outbuf;
	key.size = sizeof(int);
	err = rdfstore_flat_store_fetch(me->statements, key, &data);
	if (err != 0) {
		if (err != FLAT_STORE_E_NOTFOUND) {
			perror("rdfstore_contains");
			fprintf(stderr,"Could not fetch key '%s' in statements for store '%s': %s\n", (char *)key.data, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->statements));
			return -1;
		} else {
#ifdef RDFSTORE_DEBUG
			{
				char           *buff;
				if ((buff = rdfstore_ntriples_statement(statement, context)) != NULL) {
					fprintf(stderr,"Statement %s is NOT contained\n", buff);
					RDFSTORE_FREE(buff);
				};
			};
#endif
			return 1;
		};
	} else {
		RDFSTORE_FREE(data.data);
		return 0;
	};
};

/*
 * set a context for the statements (i.e. each asserted statement will get
 * such a context automatically by insert() ) NOTE: this stuff I can not
 * still understand how could be related to reification/logic/inference but
 * it should...
 */
int 
rdfstore_set_context(
		     rdfstore * me,
		     RDF_Node * given_context
)
{
	int             i = 0;

	/*
	 * NOTE: bear in mind that here we use a ref/pointer instead to
	 * really allocate and copy the stuff across; correct??
	 */
	if ((me->context == NULL) && /* we explicitly need to reset_context() first if need to replace the current one */
	    (given_context != NULL)) {

#ifdef RDFSTORE_DEBUG
		fprintf(stderr,"SET CONTEXT:\n");
		fprintf(stderr,"\tC='%s'\n", given_context->value.resource.identifier);
#endif

		me->context = (RDF_Node *) RDFSTORE_MALLOC(sizeof(RDF_Node));
		if (me->context == NULL) {
			perror("rdfstore_set_context");
			fprintf(stderr,"Cannot set statement context for store '%s'\n", (me->name != NULL) ? me->name : "(in-memory)");
			return -1;
		};
		me->context->hashcode = 0;
		me->context->type = given_context->type;

		me->context->value.resource.identifier = NULL;
		me->context->value.resource.identifier = (char *)RDFSTORE_MALLOC(sizeof(char) * (given_context->value.resource.identifier_len + 1));
		if (me->context->value.resource.identifier == NULL) {
			perror("rdfstore_set_context");
			fprintf(stderr,"Cannot set statement context for store '%s'\n", (me->name != NULL) ? me->name : "(in-memory)");
			RDFSTORE_FREE(me->context);
			return -1;
		};
		i = 0;
		memcpy(me->context->value.resource.identifier + i, given_context->value.resource.identifier, given_context->value.resource.identifier_len);
		i += given_context->value.resource.identifier_len;
		memcpy(me->context->value.resource.identifier + i, "\0", 1);
		i++;
		me->context->value.resource.identifier_len = given_context->value.resource.identifier_len;

		return 0;
	} else {
		return 1;
	};
};

/*
 * reset the context for the statements (i.e. each asserted statement will be
 * put in no context by insert() unless specified )
 */
int 
rdfstore_reset_context(
		       rdfstore * me
)
{

	if (me->context != NULL) {
		RDFSTORE_FREE(me->context->value.resource.identifier);
		RDFSTORE_FREE(me->context);
	} else {
		return 1;
		};

	me->context = NULL;

	return 0;
};

/* return actual defined context of the model */
RDF_Node       *
rdfstore_get_context(
		     rdfstore * me
)
{
	if (me->context != NULL) {
		return me->context;
	} else {
		return NULL;
		};
};

int 
rdfstore_set_source_uri(
			rdfstore * me,
			char *uri
)
{
	DBT             key, data;
	int             err;

	memset(&key, 0, sizeof(key));
	memset(&data, 0, sizeof(data));

	if ((uri != NULL) &&
	    (strlen(uri) > 0)) {
		key.data = "uri";
		key.size = sizeof("uri");
		data.data = uri;
		data.size = strlen(uri) + 1;
		err = rdfstore_flat_store_store(me->model, key, data);
		if ((err != 0) &&
		    (err != FLAT_STORE_E_KEYEXIST)) {
			perror("rdfstore_set_source_uri");
			fprintf(stderr,"Could not store '%d' bytes for key '%s' in model for store '%s': %s\n", (int)data.size, (char *)key.data, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->model));
			return -1;
		};
		strcpy(me->uri, data.data);

		return 0;
	} else {
		return -1;
	};
};

int 
rdfstore_get_source_uri(
			rdfstore * me,
			char *uri
)
{
	DBT             key, data;

	memset(&key, 0, sizeof(key));
	memset(&data, 0, sizeof(data));

	key.data = "uri";
	key.size = sizeof("uri");
	if ((rdfstore_flat_store_fetch(me->model, key, &data)) == 0) {
		strcpy(uri, data.data);
		strcpy(me->uri, data.data);

		RDFSTORE_FREE(data.data);

		return 0;
	} else {
		return -1;
	};
};

/* return 0 if the store is empty */
int 
rdfstore_is_empty(
		  rdfstore * me
)
{
	unsigned int    size;

	if (rdfstore_size(me, &size)) {
		perror("rdfstore_is_empty");
		fprintf(stderr,"Could carry out model size for store '%s'\n", (me->name != NULL) ? me->name : "(in-memory)");
		return -1;
	};

	return (size > 0) ? 1 : 0;
};

/*
 * return a statement iterator; the returned object must be garbage-collected
 * by the caller via rdfstore_iterator_close()
 */
rdfstore_iterator *
rdfstore_elements(
		  rdfstore * me
)
{
	rdfstore_iterator *cursor;
	DBT             key, data;
	int             retval = 0;
	unsigned int    st_id = 0;

	memset(&key, 0, sizeof(key));
	memset(&data, 0, sizeof(data));

	cursor = (rdfstore_iterator *) RDFSTORE_MALLOC(sizeof(rdfstore_iterator));
	if (cursor == NULL) {
		perror("rdfstore_elements");
		fprintf(stderr,"Cannot create elements cursor/iterator for store '%s'\n", (me->name != NULL) ? me->name : "(in-memory)");
		return NULL;
	};
	cursor->store = me;
	me->attached++;

	/* bzero(cursor->ids,sizeof(unsigned char)*(RDFSTORE_MAXRECORDS_BYTES_SIZE)); */
	cursor->size = 0;
	cursor->remove_holes = 0;	/* reset the total of holes */
	cursor->st_counter = 0;
	cursor->pos = 0;
	cursor->ids_size = 0;

	if (rdfstore_flat_store_first(me->statements, &key) == 0) {
		do {
			retval = 0;
			if (rdfstore_flat_store_fetch(me->statements, key, &data) == 0) {
				unpackInt(data.data, &st_id);
				RDFSTORE_FREE(data.data);

				/*
				 * not sure rdfstore_bits_setmask() actually
				 * sets ids_size right.....
				 */
				rdfstore_bits_setmask(&cursor->ids_size, cursor->ids, st_id, 1, 1, sizeof(cursor->ids));

				cursor->size++;
			} else {
				RDFSTORE_FREE(key.data);
				RDFSTORE_FREE(cursor);
				perror("rdfstore_elements");
				fprintf(stderr,"Could not fetch key '%s' in statements for store '%s': %s\n", (char *)key.data, (me->name != NULL) ? me->name : "(in-memory)", rdfstore_flat_store_get_error(me->statements));
				return NULL;
			};
			/* set the right bit */
			retval = rdfstore_flat_store_next(me->statements, key, &data);
			RDFSTORE_FREE(key.data);	/* dispose the key
							 * fetched above */
			if (retval == 0) {
				key = rdfstore_flat_store_kvdup(me->statements, data);
				RDFSTORE_FREE(data.data);
			};
		} while (retval == 0);
	};

#ifdef RDFSTORE_DEBUG
	{
		register int    i;
		printf("Actually matched (bits only) '");
		for(i=0;i<8*cursor->ids_size;i++) {
                        printf("%c", (cursor->ids[i>>3] & (1<<(i&7))) ? '1':'0');
                        };
		printf("' (%d)\n", cursor->ids_size);
	}
#endif

	return cursor;
};

#ifndef packInt
/* pack the integer */
void
packInt(uint32_t value, unsigned char *buffer)
{
        /* bzero(buffer, sizeof(int)); */
        *(uint32_t *)buffer=htonl(value);
}
#endif

#ifndef unpackInt
/* unpack the integer */
void
unpackInt(unsigned char *buffer, uint32_t * value)
{
        *value = ntohl(*(uint32_t *)buffer);
}
#endif

/* core API implementation */

/* see http://www.w3.org/TR/1999/REC-xml-names-19990114/#NT-NCName */
int _rdfstore_is_xml_name(
	unsigned char * name_char ) {

        if (    ( ! isalpha((int)*name_char) ) &&
                ( *name_char != '_' ) )
                return 0;

        name_char++;
        while( *name_char ) {
                if (    ( ! isalnum((int)*name_char) ) &&
                        ( *name_char != '_' ) &&
                        ( *name_char != '-' ) &&
                        ( *name_char != '.' ) )
                        return 0;
                name_char++;
                };

        return 1;
        };

RDF_Node * rdfstore_node_new() {
	RDF_Node * node = NULL;

        node = (RDF_Node *) RDFSTORE_MALLOC(sizeof(RDF_Node));

        if( node == NULL ) {
                return NULL;
                };

	bzero( node, sizeof(RDF_Node) );

	node->type = -1; /* unset */

	/* init the union parts - correct? */
	node->value.resource.identifier = NULL;
	node->value.resource.identifier_len = 0;
        node->value.literal.string = NULL;
        node->value.literal.string_len = 0;
        node->value.literal.dataType = NULL;
	strcpy(node->value.literal.lang,"");
        node->value.literal.parseType = 0;

	return node;
	};

RDF_Node * rdfstore_node_clone( RDF_Node * node ) {

	if ( node == NULL )
		return NULL;

	if ( node->type == RDFSTORE_NODE_TYPE_LITERAL ) {
		return rdfstore_literal_clone( node );
	} else {
		return rdfstore_resource_clone( node );
		};
	};

int rdfstore_node_set_type(
	RDF_Node * node,
	int type ) {

	if (	( node == NULL ) ||
		( ! ( ( type == RDFSTORE_NODE_TYPE_RESOURCE ) ||
		      ( type == RDFSTORE_NODE_TYPE_LITERAL ) ||
		      ( type == RDFSTORE_NODE_TYPE_BNODE ) ) ) )
		return 0;

	node->type = type;

	return 1;
	};

int rdfstore_node_get_type(
	RDF_Node * node ) {

	if ( node == NULL )
		return -1;

	return node->type;
	};

unsigned char * rdfstore_node_get_label(
	RDF_Node * node,
	int * len ) {
	*len = 0;

	if ( node == NULL )
		return NULL;

	*len = ( node->type != RDFSTORE_NODE_TYPE_LITERAL ) ? node->value.resource.identifier_len : node->value.literal.string_len;

	return ( node->type != RDFSTORE_NODE_TYPE_LITERAL ) ? node->value.resource.identifier : node->value.literal.string;
	};

unsigned char * rdfstore_node_to_string(
	RDF_Node * node,
	int * len ) {

	return rdfstore_node_get_label( node, len );

	};

unsigned char * rdfstore_node_get_digest(
	RDF_Node * node,
	int * len ) {
	static unsigned char dd[RDFSTORE_SHA_DIGESTSIZE]; /* NOTE: static is not thread safe due is coming from process mem and not from stack */
	*len = 0;

	if ( node == NULL )
		return NULL;

	if ( rdfstore_digest_get_node_digest( node, dd, 1 ) == 0 ) { /* get unique digest by xml:lang and rdf:datatype if necessary */
		*len = RDFSTORE_SHA_DIGESTSIZE;

		return dd;
	} else {
		return NULL;
		};
	};

int rdfstore_node_equals(
	RDF_Node * node1,
	RDF_Node * node2 ) {
	unsigned char * dd1=NULL;
	int ll1=0;
	unsigned char * dd2=NULL;
	int ll2=0;

	if (	( node1 == NULL ) ||
		( node2 == NULL ) ||
		( node1->type != node2->type ) )
		return 0;

	/* try to compare crypto digests if possible */
	if (	( ( dd1 = rdfstore_node_get_digest( node1, &ll1 ) ) != NULL ) &&
		( ll1 > 0 ) &&
		( ( dd2 = rdfstore_node_get_digest( node2, &ll2 ) ) != NULL ) &&
		( ll2 > 0 ) &&
		( ll1 == ll2 ) ) {
		return ( memcmp( dd1, dd2, MAX( ll1, ll2 ) ) == 0 ) ? 1 : 0 ;
	} else {
		/* otherwise memcmp their labels... */
		if ( node1->type == RDFSTORE_NODE_TYPE_LITERAL ) {
			return ( memcmp( node1->value.literal.string, node2->value.literal.string, MAX( node1->value.literal.string_len, node2->value.literal.string_len ) ) == 0 ) ? 1 : 0 ;
		} else {
			return ( memcmp( node1->value.resource.identifier, node2->value.resource.identifier, MAX( node1->value.resource.identifier_len, node2->value.resource.identifier_len ) ) == 0 ) ? 1 : 0 ;
			};
		};
	};

int rdfstore_node_free(
	RDF_Node * node ) {

	if ( node == NULL )
		return 0;

	if ( node->type == RDFSTORE_NODE_TYPE_LITERAL ) {
		if ( node->value.literal.string != NULL ) /* due we have also empty literals */
			RDFSTORE_FREE( node->value.literal.string );
		if ( node->value.literal.dataType != NULL )
			RDFSTORE_FREE( node->value.literal.dataType );
	} else if (	( node->type == RDFSTORE_NODE_TYPE_RESOURCE ) ||
			( node->type == RDFSTORE_NODE_TYPE_BNODE ) ) {
		if ( node->value.resource.identifier != NULL ) /* due we do NOT use this API everywhere we need to check */
			RDFSTORE_FREE( node->value.resource.identifier );
		};

	RDFSTORE_FREE( node );

	return 1;
	};

void rdfstore_node_dump(
	RDF_Node * node ) {

	unsigned char * buff=NULL;

	buff = rdfstore_ntriples_node( node );

	if ( buff ) {
		fprintf(stderr, "(type='%s') %s\n", ( node->type == RDFSTORE_NODE_TYPE_LITERAL ) ? "literal" : ( node->type == RDFSTORE_NODE_TYPE_BNODE ) ? "bNode" : "URI", buff );
		RDFSTORE_FREE( buff );
		};

	};

 /* for resource centric API ala Jena */
int rdfstore_node_set_model(
	RDF_Node * node,
	rdfstore * model ) {
	
	if (	( node == NULL ) ||
		( model == NULL ) )
		return 0;

	node->model = model; /* tell it there is a guy attached to it??? */

	return 1;
	};

int rdfstore_node_reset_model(
	RDF_Node * node ) {

	if ( node == NULL )
		return 0;

	node->model = NULL;

	return 1;
	};

rdfstore * rdfstore_node_get_model(
	RDF_Node * node ) {

	if ( node == NULL )
		return 0;

	return node->model;
	};

/* RDF literals */

RDF_Node * rdfstore_literal_new(
	unsigned char * string,
	int len,
	int parseType,
	unsigned char * lang,
	unsigned char * dt ) {
	RDF_Node * node = NULL;

	if(     (parseType) &&
                (dt!=NULL) &&
                (strlen(dt) > 0) &&
                (strcmp(dt,RDFSTORE_RDF_PARSETYPE_LITERAL)) ) {
                return NULL;
                };

	node = rdfstore_node_new();

	if (	( node == NULL ) ||
		( ! ( ( parseType == RDFSTORE_PARSE_TYPE_NORMAL ) ||
		      ( parseType == RDFSTORE_PARSE_TYPE_LITERAL ) ) ) )
		return NULL;

	if ( ! rdfstore_node_set_type( node, RDFSTORE_NODE_TYPE_LITERAL ) ) {
		rdfstore_node_free( node );
		return NULL;
		};

	node->value.literal.string = NULL;
	node->value.literal.string_len = 0;

	if (	( string != NULL ) &&
		( len > 0 ) ) {

		node->value.literal.string = (unsigned char *) RDFSTORE_MALLOC( sizeof(unsigned char) * ( len + 1 ) );

		if ( node->value.literal.string == NULL ) {
			rdfstore_node_free( node );
			return NULL;
			};
		node->value.literal.string_len = len;

		memcpy( node->value.literal.string, string, len );
		memcpy( node->value.literal.string+len,"\0",1);
		};
	
	node->value.literal.parseType = parseType;

	/* FORCE this - rdf:parseType="Literal" is the same as rdf:datatype="http://www.w3.org/1999/02/22-rdf-syntax-ns#XMLLiteral" */
        if( parseType ==  RDFSTORE_PARSE_TYPE_LITERAL ) {
                dt = RDFSTORE_RDF_PARSETYPE_LITERAL;
                };

	node->value.literal.dataType = NULL;

	/* set rdf:datatype */
	if (	( dt != NULL ) &&
		( strlen(dt) > 0 ) ) {
		node->value.literal.dataType = (unsigned char *) RDFSTORE_MALLOC( sizeof(unsigned char) * ( strlen(dt) + 1 ) );

		if ( node->value.literal.dataType == NULL ) {
			rdfstore_node_free( node );
			return NULL;
			};
		strcpy( node->value.literal.dataType, dt );
		};

	/* set xml:lang */
	if (	( lang != NULL ) &&
                ( strlen(lang) > 0 ) ) {
		if ( strlen(lang) > RDFSTORE_MAX_LANG_LENGTH ) {
			perror("rdfstore_literal_new");
			fprintf(stderr,"Literal xml:lang '%s' is too long. Max allowed is %d characters long\n", lang, RDFSTORE_MAX_LANG_LENGTH );
			rdfstore_node_free( node );
			return NULL;
			};

		strcpy( node->value.literal.lang, lang );
	} else {
		strcpy( node->value.literal.lang, "\0" ); /* or =NULL ? */
		};

	return node;
	};

RDF_Node * rdfstore_literal_clone(
	RDF_Node * node ) {

	if (	( node == NULL ) ||
		( node->type != RDFSTORE_NODE_TYPE_LITERAL ) )
		return NULL;

	return rdfstore_literal_new(	node->value.literal.string, 
					node->value.literal.string_len,
					node->value.literal.parseType,
					node->value.literal.lang,
					node->value.literal.dataType );
	};

unsigned char * rdfstore_literal_get_label(
	RDF_Node * node,
        int * len ) {

	return rdfstore_node_get_label( node, len );
	
	};

unsigned char * rdfstore_literal_to_string(
	RDF_Node * node,
        int * len ) {

	return rdfstore_node_to_string( node, len );

	};

unsigned char * rdfstore_literal_get_digest(
        RDF_Node * node,
        int * len ) {

	return rdfstore_node_get_digest( node, len );

	};

int rdfstore_literal_equals(
	RDF_Node * node1,
	RDF_Node * node2 ) {

	return rdfstore_node_equals( node1, node2 );

	};

int rdfstore_literal_set_string(
	RDF_Node * node,
	unsigned char * string,
	int len ) {

	if (	( node == NULL ) ||
		( node->type != RDFSTORE_NODE_TYPE_LITERAL ) )
		return 0;

	if (	( string != NULL ) &&
		( len > 0 ) ) {

		if ( node->value.literal.string != NULL )
			RDFSTORE_FREE( node->value.literal.string );

		node->value.literal.string = (unsigned char *) RDFSTORE_MALLOC( sizeof(unsigned char) * ( len + 1 ) );

		if ( node->value.literal.string == NULL ) {
			return 0;
			};
		node->value.literal.string_len = len;

		memcpy( node->value.literal.string, string, len );
		memcpy( node->value.literal.string+len,"\0",1);
		};

	return 1;
	};

int rdfstore_literal_set_lang(
	RDF_Node * node,
	unsigned char * lang ) {

	if (	( node == NULL ) ||
		( node->type != RDFSTORE_NODE_TYPE_LITERAL ) )
		return 0;

	/* set xml:lang */
	if (	( lang != NULL ) &&
                ( strlen(lang) > 0 ) )
		strcpy( node->value.literal.lang, lang );

	return 1;
	};

unsigned char * rdfstore_literal_get_lang(
	RDF_Node * node ) {
	
	if (	( node == NULL ) ||
		( node->type != RDFSTORE_NODE_TYPE_LITERAL ) )
		return NULL;

	return node->value.literal.lang;
	};

int rdfstore_literal_set_datatype(
	RDF_Node * node,
	unsigned char * dt ) {

	if (	( node == NULL ) ||
		( node->type != RDFSTORE_NODE_TYPE_LITERAL ) )
		return 0;

	/* set rdf:datatype */
	if ( dt != NULL ) {
		if ( node->value.literal.dataType != NULL )
			RDFSTORE_FREE( node->value.literal.dataType );

		node->value.literal.dataType = (unsigned char *) RDFSTORE_MALLOC( sizeof(unsigned char) * ( strlen(dt) + 1 ) );

		if ( node->value.literal.dataType == NULL ) {
			return 0;
			};
		strcpy( node->value.literal.dataType, dt );
		};

	return 1;
	};

unsigned char * rdfstore_literal_get_datatype(
	RDF_Node * node ) {

	if (	( node == NULL ) ||
		( node->type != RDFSTORE_NODE_TYPE_LITERAL ) )
		return NULL;

	return node->value.literal.dataType;
	};

int rdfstore_literal_set_parsetype(
	RDF_Node * node,
	int parseType ) {

	if (    ( node == NULL ) ||
		( node->type != RDFSTORE_NODE_TYPE_LITERAL ) ||
                ( ! ( ( parseType == RDFSTORE_PARSE_TYPE_NORMAL ) ||
                      ( parseType == RDFSTORE_PARSE_TYPE_LITERAL ) ) ) )
                return 0;

	/* FORCE this - rdf:parseType="Literal" is the same as rdf:datatype="http://www.w3.org/1999/02/22-rdf-syntax-ns#XMLLiteral" */
        if( parseType ==  RDFSTORE_PARSE_TYPE_LITERAL ) {
		node->value.literal.parseType = parseType;

                if ( ! rdfstore_literal_set_datatype( node, RDFSTORE_RDF_PARSETYPE_LITERAL ) )
			return 0;
		};

	return 1;
	};

int rdfstore_literal_get_parsetype(
	RDF_Node * node ) {

	if (	( node == NULL ) ||
		( node->type != RDFSTORE_NODE_TYPE_LITERAL ) )
		return -1;

	return node->value.literal.parseType;
	};

int rdfstore_literal_free(
	RDF_Node * node ) {

	return rdfstore_node_free( node );

	};

void rdfstore_literal_dump(
	RDF_Node * node ) {

	rdfstore_node_dump( node );
	};

/* for resource centric API ala Jena */
int rdfstore_literal_set_model(
	RDF_Node * node,
	rdfstore * model ) {

	return rdfstore_node_set_model( node, model );
	};

int rdfstore_literal_reset_model(
	RDF_Node * node ) {

	return rdfstore_node_reset_model( node );

	};

rdfstore * rdfstore_literal_get_model(
	RDF_Node * node ) {

	return rdfstore_node_get_model( node );

	};

/* RDF resources (URIs or bNodes) */

RDF_Node * rdfstore_resource_new(
	unsigned char * identifier,
	int len,
	int type ) {
	RDF_Node * node = NULL;

	if (	( ! ( ( type == RDFSTORE_NODE_TYPE_RESOURCE ) ||
	              ( type == RDFSTORE_NODE_TYPE_BNODE ) ) ) ||
		( identifier == NULL ) ||
		( len <= 0 ) )
		return NULL;

	node = rdfstore_node_new();

	if ( node == NULL )
		return NULL;

	if ( ! rdfstore_node_set_type( node, type ) ) {
		rdfstore_node_free( node );
		return NULL;
		};

	node->value.resource.identifier = (unsigned char *) RDFSTORE_MALLOC( sizeof(unsigned char) * ( len + 1 ) );

	if ( node->value.resource.identifier == NULL ) {
		rdfstore_node_free( node );
		return NULL;
		};
	node->value.resource.identifier_len = len;

	memcpy( node->value.resource.identifier, identifier, len );
	memcpy( node->value.resource.identifier+len,"\0",1);
	
	return node;
	};

RDF_Node * rdfstore_resource_new_from_qname(
	unsigned char * namespace,
	int nsl,
	unsigned char * localname,
	int lnl,
	int type ) {
	RDF_Node * node = NULL;

	if (    ( namespace == NULL ) ||
		( nsl <= 0 ) ||
                ( localname == NULL ) ||
                ( lnl <= 0 ) ||
		( type != RDFSTORE_NODE_TYPE_RESOURCE ) )
		return NULL;

	node = rdfstore_node_new();

	if ( node == NULL )
		return NULL;

	rdfstore_node_set_type( node, type );

	/* check whether or not is a valid XML localname */
	if ( ! _rdfstore_is_xml_name( localname ) ) {
		/* invalid resource local name */
		rdfstore_node_free( node );
		return NULL;
		};

	node->value.resource.identifier = (unsigned char *) RDFSTORE_MALLOC( sizeof(unsigned char) * (lnl + nsl + 1) );

	if ( node->value.resource.identifier == NULL ) {
		rdfstore_node_free( node );
		return NULL;
		};
	memcpy( node->value.resource.identifier, namespace, nsl );
	memcpy( node->value.resource.identifier+nsl, localname, lnl );
	memcpy( node->value.resource.identifier+nsl+lnl, "\0", 1);

	node->value.resource.identifier_len = lnl + nsl;

	return node;
	};


RDF_Node * rdfstore_resource_clone( RDF_Node * node ) {

	if (	( node == NULL ) ||
		( ! ( ( node->type == RDFSTORE_NODE_TYPE_RESOURCE ) ||
	              ( node->type == RDFSTORE_NODE_TYPE_BNODE ) ) ) )
		return NULL;

	return rdfstore_resource_new(	node->value.resource.identifier,
					node->value.resource.identifier_len,
					node->type );
	};

unsigned char * rdfstore_resource_get_label(
	RDF_Node * node,
        int * len ) {

	return rdfstore_node_get_label( node, len );

	};

unsigned char * rdfstore_resource_to_string(
	RDF_Node * node,
        int * len ) {

	return rdfstore_node_to_string( node, len );

	};

unsigned char * rdfstore_resource_get_digest(
        RDF_Node * node,
        int * len ) {

	return rdfstore_node_get_digest( node, len );

	};

int rdfstore_resource_equals(
	RDF_Node * node1,
	RDF_Node * node2 ) {

	return rdfstore_node_equals( node1, node2 );

	};

int rdfstore_resource_set_uri(
	RDF_Node * node,
	unsigned char * identifier,
	int len ) {

	if (	( node == NULL ) ||
		( identifier == NULL ) ||
		( len <= 0 ) ||
		( ! ( ( node->type == RDFSTORE_NODE_TYPE_RESOURCE ) ||
	              ( node->type == RDFSTORE_NODE_TYPE_BNODE ) ) ) )
		return 0;

	if ( node->value.resource.identifier != NULL )
		RDFSTORE_FREE( node->value.resource.identifier );

	node->value.resource.identifier = (unsigned char *) RDFSTORE_MALLOC( sizeof(unsigned char) * ( len + 1 ) );

	if ( node->value.resource.identifier == NULL ) {
		return 0;
		};
	node->value.resource.identifier_len = len;

	memcpy( node->value.resource.identifier, identifier, len );
	memcpy( node->value.resource.identifier+len,"\0",1);

	return 1;
	};

unsigned char * rdfstore_resource_get_uri(
	RDF_Node * node,
	int * len ) {
	*len = 0;

	if (	( node == NULL ) ||
		( ! ( ( node->type == RDFSTORE_NODE_TYPE_RESOURCE ) ||
	              ( node->type == RDFSTORE_NODE_TYPE_BNODE ) ) ) )
		return NULL;

	*len = node->value.resource.identifier_len;

	return node->value.resource.identifier;
	};

int rdfstore_resource_is_anonymous(
	RDF_Node * node ) {

	if ( node == NULL )
		return -1;

	return ( node->type == RDFSTORE_NODE_TYPE_BNODE ) ? 1 : 0 ;
	};

int rdfstore_resource_is_bnode(
	RDF_Node * node ) {

	return rdfstore_resource_is_anonymous( node );

	};

unsigned char * rdfstore_resource_get_namespace(
	RDF_Node * node,
	int * len ) {
	unsigned char * nc=NULL;
	*len = 0;

	if (	( node == NULL ) ||
		( node->type != RDFSTORE_NODE_TYPE_RESOURCE )  )
		return NULL;

        nc = rdfstore_resource_get_localname( node, len );

        if ( nc == NULL ) {
		*len = 0;
		return NULL;
        } else {
                *len = (int)( (unsigned char * ) nc - (unsigned char *) node->value.resource.identifier );
                };

	return (*len > 0 ) ? node->value.resource.identifier : NULL ; /* and the caller will use len to sort out how long the namespace is */
	};

unsigned char * rdfstore_resource_get_localname(
	RDF_Node * node,
	int * len ) {
	unsigned char * localname=NULL;
	unsigned char * nc=NULL;
	*len = 0;

	if (	( node == NULL ) ||
		( node->type != RDFSTORE_NODE_TYPE_RESOURCE )  )
		return NULL;

        /* try to get out XML QName LocalName from resource identifier */
        nc = node->value.resource.identifier + ( node->value.resource.identifier_len - 1 );
        while( nc >= node->value.resource.identifier ) {
                if( _rdfstore_is_xml_name( nc ) ) {
			localname = nc;
			*len = (int)( ( (unsigned char *)(node->value.resource.identifier_len) ) - ( (unsigned char *)(localname) - (unsigned char *)(node->value.resource.identifier) ) ); /* correct??? */
			};
                nc--;
                };

        if( !localname ) {
		localname = node->value.resource.identifier;
		*len = node->value.resource.identifier_len;
                };

	return localname;
	};

unsigned char * rdfstore_resource_get_bnode(
	RDF_Node * node,
	int * len ) {
	node = NULL;
	*len = 0;

	if (	( node == NULL ) ||
		( node->type != RDFSTORE_NODE_TYPE_BNODE )  )
		return NULL;

	return rdfstore_node_get_label( node, len );

	};

unsigned char * rdfstore_resource_get_nodeid(
	RDF_Node * node,
	int * len ) {

	return rdfstore_resource_get_bnode( node, len );

	};

int rdfstore_resource_free(
	RDF_Node * node ) {

	return rdfstore_node_free( node );

	};

void rdfstore_resource_dump(
	RDF_Node * node ) {

	return rdfstore_node_dump( node );

	};

/* for resource centric API ala Jena */

int rdfstore_resource_set_model(
	RDF_Node * node,
	rdfstore * model ) {

	return rdfstore_node_set_model( node, model );

	};
int rdfstore_resource_reset_model(
	RDF_Node * node ) {

	return rdfstore_node_reset_model( node );

	};

rdfstore * rdfstore_resource_get_model(
	RDF_Node * node ) {

	return rdfstore_node_get_model( node );

	};

/* RDF statements */

/* create a new statement from given components - then the components are being owned by the statement and freed on error/destruction - and they
   must not be used by the caller after this call */
RDF_Statement * rdfstore_statement_new(
	RDF_Node * s,
	RDF_Node * p,
	RDF_Node * o,
	RDF_Node * c,
	RDF_Node * node,
	int isreified ) {
	RDF_Statement * st=NULL;

	if (	( s == NULL ) ||
		( p == NULL ) ||
		( o == NULL ) )
		return NULL;

	st = (RDF_Statement *) RDFSTORE_MALLOC( sizeof(RDF_Statement) );

	if ( st == NULL ) {
		rdfstore_resource_free( s );
		rdfstore_resource_free( p );
		rdfstore_node_free( o );
		rdfstore_resource_free( c );
		rdfstore_resource_free( node );
		return NULL;
		};

	st->hashcode = 0;
        st->isreified = (isreified) ? 1 : 0;

        st->subject = s;
        st->predicate = p;
        st->object = o;
        st->context = (c != NULL) ? c : NULL ;

	st->node = NULL;

	/* create st->node if we need an explicit label for it, otherwise getLabel is systematically calculating the URI even after stored */
	if ( node != NULL ) {
		if ( ! st->isreified ) {
			rdfstore_statement_free( st );
			/* Statement can have an identfier (be a resource) only if it is reified */
			return NULL;
			};
        	st->node = node;
	} else if ( st->isreified ) {
		unsigned char * label=NULL;
		int ll=0;
		/* for reified statements we dynamically assign a node to it as resource */
		if (	( ( label = rdfstore_statement_get_label( st, &ll ) ) != NULL ) &&
			( ll > 0 ) ) {
        		st->node = rdfstore_resource_new( label, ll, RDFSTORE_NODE_TYPE_RESOURCE );
			if ( st->node == NULL ) {
				rdfstore_statement_free( st );
				return NULL;
				};
			};
		};

        st->model = NULL;

	return st;
	};

RDF_Statement * rdfstore_statement_clone(
	RDF_Statement * st ) {

	if ( st == NULL )
		return NULL;

	return rdfstore_statement_new(	rdfstore_resource_clone( st->subject ),
					rdfstore_resource_clone( st->predicate ),
					rdfstore_node_clone( st->object ),
					rdfstore_resource_clone( st->context ),
					rdfstore_resource_clone( st->node ),
					st->isreified );
	};

unsigned char * rdfstore_statement_get_label(
	RDF_Statement * st,
        int * len ) {
	*len = 0;

	if ( st == NULL )
		return NULL;

	if ( st->node != NULL ) {
		*len = st->node->value.resource.identifier_len;
                return st->node->value.resource.identifier;
	} else {
		int i=0,status=0;
                unsigned char dd[RDFSTORE_SHA_DIGESTSIZE];
                static unsigned char label[9+10+(RDFSTORE_SHA_DIGESTSIZE*2)]; /* assume strlen( rdfstore_digest_get_digest_algorithm() ) up to 10 chars */

		/* NOTE: the static above is not thread safe due is coming from process mem and not from stack */

                /* e.g. urn:rdf:SHA-1-d2619b606c7ecac3dcf9151dae104c4ae7554786 */
                sprintf( label, "urn:rdf:%s-", rdfstore_digest_get_digest_algorithm() );
                status = rdfstore_digest_get_statement_digest( st, NULL, dd );
                if ( status != 0 )
                        return NULL;

                for ( i=0; i< RDFSTORE_SHA_DIGESTSIZE ; i++ ) {
                        char cc[2];
                        sprintf( cc, "%02X", dd[i] );
                        strncat(label, cc, 2);
                        };
                *len = 9 + 10 + (RDFSTORE_SHA_DIGESTSIZE*2);
		return label;
		};
	};

unsigned char * rdfstore_statement_to_string(
	RDF_Statement * st,
        int * len ) {
	unsigned char * ntriple=NULL;
	*len = 0;

	if ( st == NULL )
		return ntriple;

	ntriple = rdfstore_ntriples_statement( st, NULL );

	*len = strlen( ntriple );

	return ntriple;
	};

unsigned char * rdfstore_statement_get_digest(
        RDF_Statement * st,
        int * len ) {
	static unsigned char dd[RDFSTORE_SHA_DIGESTSIZE]; /* NOTE: static is not thread safe due is coming from process mem and not from stack */
	*len = 0;

	if ( st == NULL )
		return NULL;

	if ( ! rdfstore_digest_get_statement_digest( st, NULL, dd ) )
		return NULL;

	*len = RDFSTORE_SHA_DIGESTSIZE;

	return dd;
	};

int rdfstore_statement_is_anonymous(
	RDF_Statement * st ) {

	if ( st == NULL )
		return -1;

	return 0;
	};

int rdfstore_statement_is_bnode(
	RDF_Statement * st ) {

	return rdfstore_statement_is_anonymous( st );

	};

unsigned char * rdfstore_statement_get_localname(
	RDF_Statement * st,
	int * len ) {

	return rdfstore_statement_get_label( st, len );

	};

unsigned char * rdfstore_statement_get_namespace(
	RDF_Statement * st,
	int * len ) {
	*len = 0;

	return NULL;
	};

unsigned char * rdfstore_statement_get_uri(
	RDF_Statement * st,
	int * len ) {

	return rdfstore_statement_get_label( st, len );

	};

int rdfstore_statement_equals(
	RDF_Statement * st1,
	RDF_Statement * st2 ) {
	int ls1=0, ls2=0, lp1=0, lp2=0, lo1=0, lo2=0;

	if (	( st1 == NULL ) ||
		( st2 == NULL ) )
		return 0;

	if (	( st1->context != NULL ) &&
		( st2->context != NULL ) ) {
		int lc1=0, lc2=0;
		return (	( memcmp(	rdfstore_resource_get_label( st1->subject, &ls1 ), 
						rdfstore_resource_get_label( st2->subject, &ls2 ), MAX(ls1, ls2) ) == 0 ) &&
				( ls1 > 0 ) && ( ls2 > 0 ) &&
				( memcmp(	rdfstore_resource_get_label( st1->predicate, &lp1 ), 
						rdfstore_resource_get_label( st2->predicate, &lp2 ), MAX(lp1, lp2) ) == 0 ) &&
				( lp1 > 0 ) && ( lp2 > 0 ) &&
				( memcmp(	rdfstore_node_get_label( st1->object, &lo1 ), 
						rdfstore_node_get_label( st2->object, &lo2 ), MAX(lo1, lo2) ) == 0 ) &&
				( memcmp(	rdfstore_resource_get_label( st1->context, &lc1 ), 
						rdfstore_resource_get_label( st2->context, &lc2 ), MAX(lc1, lc2) ) == 0 ) &&
				( lc1 > 0 ) && ( lc2 > 0 ) ) ? 1 : 0 ;
	} else {
		return (	( memcmp(	rdfstore_resource_get_label( st1->subject, &ls1 ), 
						rdfstore_resource_get_label( st2->subject, &ls2 ), MAX(ls1, ls2) ) == 0 ) &&
				( ls1 > 0 ) && ( ls2 > 0 ) &&
				( memcmp(	rdfstore_resource_get_label( st1->predicate, &lp1 ), 
						rdfstore_resource_get_label( st2->predicate, &lp2 ), MAX(lp1, lp2) ) == 0 ) &&
				( lp1 > 0 ) && ( lp2 > 0 ) &&
				( memcmp(	rdfstore_node_get_label( st1->object, &lo1 ), 
						rdfstore_node_get_label( st2->object, &lo2 ), MAX(lo1, lo2) ) == 0 ) ) ? 1 : 0 ;
		};
	};

int rdfstore_statement_isreified(
	RDF_Statement * st ) {

	if ( st == NULL )
		return -1;

	return st->isreified;	
	};

RDF_Node * rdfstore_statement_get_subject(
	RDF_Statement * st ) {

	if ( st == NULL )
		return 0;

	return st->subject;
	};

int rdfstore_statement_set_subject(
	RDF_Statement * st,
	RDF_Node * s ) {

	if ( st == NULL )
		return 0;

	rdfstore_resource_free( st->subject );

	st->subject = s;

	return 1;
	};

RDF_Node * rdfstore_statement_get_predicate(
	RDF_Statement * st ) {

	if ( st == NULL )
		return 0;

	return st->predicate;
	};

int rdfstore_statement_set_predicate(
	RDF_Statement * st,
	RDF_Node * p ) {

	if ( st == NULL )
		return 0;

	rdfstore_resource_free( st->predicate );

	st->predicate = p;

	return 1;
	};

RDF_Node * rdfstore_statement_get_object(
	RDF_Statement * st ) {

	if ( st == NULL )
		return 0;

	return st->object;
	};

int rdfstore_statement_set_object(
	RDF_Statement * st,
	RDF_Node * o ) {

	if ( st == NULL )
		return 0;

	rdfstore_node_free( st->object );

	st->object = o;

	return 1;
	};

RDF_Node * rdfstore_statement_get_context(
	RDF_Statement * st ) {

	if ( st == NULL )
		return 0;

	return st->context;
	};

int rdfstore_statement_set_context(
	RDF_Statement * st,
	RDF_Node * c ) {

	if ( st == NULL )
		return 0;

	rdfstore_resource_free( st->context );

	st->context = c;

	return 1;
	};

RDF_Node * rdfstore_statement_get_node(
	RDF_Statement * st ) {

	if ( st == NULL )
		return 0;

	return st->node;
	};

int rdfstore_statement_set_node(
	RDF_Statement * st,
	RDF_Node * node ) {

	if ( st == NULL )
		return 0;

	rdfstore_resource_free( st->node );

	st->node = node;

	return 1;
	};

int rdfstore_statement_free(
	RDF_Statement * st ) {

	if ( st == NULL )
		return 0;

	rdfstore_resource_free( st->subject );
	rdfstore_resource_free( st->predicate );
	rdfstore_node_free( st->object );
	rdfstore_resource_free( st->context );
	rdfstore_resource_free( st->node );

	RDFSTORE_FREE( st );

	return 1;
	};

void rdfstore_statement_dump(
	RDF_Statement * st ) {
	unsigned char * buff=NULL;

	if ( st == NULL )
		return;

	buff = rdfstore_ntriples_statement( st, NULL );

	if ( buff ) {
		fprintf(stderr, "(statement) %s\n", buff);
		RDFSTORE_FREE( buff );
		};
	};

/* for resource centric API ala Jena */

int rdfstore_statement_set_model(
	RDF_Statement * st,
	rdfstore * model ) {

        if (    ( st == NULL ) ||
                ( model == NULL ) )
                return 0;

        st->model = model; /* tell it there is a guy attached to it??? */

        return 1;
	};

int rdfstore_statement_reset_model(
	RDF_Statement * st ) {

        if ( st == NULL )
                return 0;

        st->model = NULL;

        return 1;
	};

rdfstore * rdfstore_statement_get_model(
	RDF_Statement * st ) {

	if ( st == NULL )
		return 0;

	return st->model;
	};

/* RDF_Triple_Pattern related ones */

RDF_Triple_Pattern * rdfstore_triple_pattern_new() {
	RDF_Triple_Pattern * tp=NULL;

	tp = (RDF_Triple_Pattern *)RDFSTORE_MALLOC(sizeof(RDF_Triple_Pattern));

        if( tp == NULL )
		return NULL;

	tp->subjects=NULL;
	tp->subjects_operator=0;
	tp->predicates=NULL;
	tp->predicates_operator=0;
	tp->objects=NULL;
	tp->objects_operator=0;
	tp->contexts=NULL;
	tp->contexts_operator=0;
	tp->langs=NULL;
	tp->langs_operator=0;
	tp->dts=NULL;
	tp->dts_operator=0;
	tp->words=NULL;
	tp->words_operator=0;
	tp->ranges=NULL;
	tp->ranges_operator=0;

	return tp;
	};

RDF_Triple_Pattern_Part * rdfstore_triple_pattern_add_subject(
	RDF_Triple_Pattern * tp,
	RDF_Node * node ) {
	RDF_Triple_Pattern_Part * li=NULL;
	RDF_Triple_Pattern_Part * li1=NULL;
	RDF_Triple_Pattern_Part * tail=NULL;

	if (	( tp == NULL ) ||
		( node == NULL ) ||
		( node->type == RDFSTORE_NODE_TYPE_LITERAL ) )
		return NULL;

	li = (RDF_Triple_Pattern_Part *)RDFSTORE_MALLOC(sizeof(RDF_Triple_Pattern_Part));

        if( li == NULL )
                return NULL;

	li->type = RDFSTORE_TRIPLE_PATTERN_PART_RESOURCE_NODE;
	li->part.string = NULL;
	li->part.node = node;
	li->next = NULL;

	if ( tp->subjects != NULL ) {
        	li1 = tp->subjects;
		do {
			tail = li1;
		} while ( ( li1 = li1->next ) != NULL );
		tail->next = li;
	} else {
		tp->subjects = li;
		};

        return li;
	};

int rdfstore_triple_pattern_set_subjects_operator(
	RDF_Triple_Pattern * tp,
	int op ) {
	if (	( tp == NULL ) ||
		( op < 0 ) ||
		( op > 2 ) )
		return 0;

	tp->subjects_operator = op;

	return 1;
	};

RDF_Triple_Pattern_Part * rdfstore_triple_pattern_add_predicate(
	RDF_Triple_Pattern * tp,
	RDF_Node * node ) {
	RDF_Triple_Pattern_Part * li=NULL;
	RDF_Triple_Pattern_Part * li1=NULL;
	RDF_Triple_Pattern_Part * tail=NULL;

	if (	( tp == NULL ) ||
		( node == NULL ) ||
		( node->type == RDFSTORE_NODE_TYPE_LITERAL ) )
		return NULL;

	li = (RDF_Triple_Pattern_Part *)RDFSTORE_MALLOC(sizeof(RDF_Triple_Pattern_Part));

        if( li == NULL )
                return NULL;

	li->type = RDFSTORE_TRIPLE_PATTERN_PART_RESOURCE_NODE;
	li->part.string = NULL;
	li->part.node = node;
	li->next = NULL;

        if ( tp->predicates != NULL ) {
                li1 = tp->predicates;
                do {
                        tail = li1;
                } while ( ( li1 = li1->next ) != NULL );
                tail->next = li;
        } else {
                tp->predicates = li;
                };

        return li;
	};

int rdfstore_triple_pattern_set_predicates_operator(
	RDF_Triple_Pattern * tp,
	int op ) {
	if (    ( tp == NULL ) ||
                ( op < 0 ) ||
                ( op > 2 ) )
                return 0;

        tp->predicates_operator = op;

        return 1;
	};

RDF_Triple_Pattern_Part * rdfstore_triple_pattern_add_object(
	RDF_Triple_Pattern * tp,
	RDF_Node * node ) {
	RDF_Triple_Pattern_Part * li=NULL;
	RDF_Triple_Pattern_Part * li1=NULL;
	RDF_Triple_Pattern_Part * tail=NULL;

        if (    ( tp == NULL ) ||
		( node == NULL ) )
                return NULL;

        li = (RDF_Triple_Pattern_Part *)RDFSTORE_MALLOC(sizeof(RDF_Triple_Pattern_Part));

        if( li == NULL )
                return NULL;

        li->type = ( node->type == RDFSTORE_NODE_TYPE_LITERAL ) ? RDFSTORE_TRIPLE_PATTERN_PART_LITERAL_NODE : RDFSTORE_TRIPLE_PATTERN_PART_RESOURCE_NODE ;
	li->part.string = NULL;
        li->part.node = node;
	li->next = NULL;

        if ( tp->objects != NULL ) {
                li1 = tp->objects;
                do {
                        tail = li1;
                } while ( ( li1 = li1->next ) != NULL );
                tail->next = li;
        } else {
                tp->objects = li;
                };

        return li;
	};

int rdfstore_triple_pattern_set_objects_operator(
	RDF_Triple_Pattern * tp,
	int op ) {
	if (    ( tp == NULL ) ||
                ( op < 0 ) ||
                ( op > 2 ) )
                return 0;

        tp->objects_operator = op;

        return 1;
	};

RDF_Triple_Pattern_Part *  rdfstore_triple_pattern_add_context(
	RDF_Triple_Pattern * tp,
	RDF_Node * node ) {
	RDF_Triple_Pattern_Part * li=NULL;
	RDF_Triple_Pattern_Part * li1=NULL;
	RDF_Triple_Pattern_Part * tail=NULL;

	if (	( tp == NULL ) ||
		( node == NULL ) ||
		( node->type == RDFSTORE_NODE_TYPE_LITERAL ) )
		return NULL;

	li = (RDF_Triple_Pattern_Part *)RDFSTORE_MALLOC(sizeof(RDF_Triple_Pattern_Part));

        if( li == NULL )
                return NULL;

	li->type = RDFSTORE_TRIPLE_PATTERN_PART_RESOURCE_NODE;
	li->part.string = NULL;
	li->part.node = node;
	li->next = NULL;

        if ( tp->contexts != NULL ) {
                li1 = tp->contexts;
                do {
                        tail = li1;
                } while ( ( li1 = li1->next ) != NULL );
                tail->next = li;
        } else {
                tp->contexts = li;
                };

        return li;
	};

int rdfstore_triple_pattern_set_contexts_operator(
	RDF_Triple_Pattern * tp,
	int op ) {
	if (    ( tp == NULL ) ||
                ( op < 0 ) ||
                ( op > 2 ) )
                return 0;

        tp->contexts_operator = op;

        return 1;
	};

RDF_Triple_Pattern_Part * rdfstore_triple_pattern_add_lang(
	RDF_Triple_Pattern * tp,
	char * lang ) {
	RDF_Triple_Pattern_Part * li=NULL;
	RDF_Triple_Pattern_Part * li1=NULL;
	RDF_Triple_Pattern_Part * tail=NULL;

        if (    ( tp == NULL ) ||
                ( lang == NULL ) ||
		( strlen( lang ) <= 0 ) )
                return NULL;

        li = (RDF_Triple_Pattern_Part *)RDFSTORE_MALLOC(sizeof(RDF_Triple_Pattern_Part));

        if( li == NULL )
                return NULL;

        li->type = RDFSTORE_TRIPLE_PATTERN_PART_STRING;
	li->part.node = NULL;
	li->part.string = NULL;
        li->part.string = (unsigned char *) RDFSTORE_MALLOC( sizeof(unsigned char) * ( strlen(lang) + 1 ) );
	if ( li->part.string == NULL ) {
		RDFSTORE_FREE( li );
		return NULL;
		};
        strcpy( li->part.string, lang);
	li->next = NULL;

        if ( tp->langs != NULL ) {
                li1 = tp->langs;
                do {
                        tail = li1;
                } while ( ( li1 = li1->next ) != NULL );
                tail->next = li;
        } else {
                tp->langs = li;
                };

        return li;
	};

int rdfstore_triple_pattern_set_langs_operator(
	RDF_Triple_Pattern * tp,
	int op ) {
	if (    ( tp == NULL ) ||
                ( op < 0 ) ||
                ( op > 2 ) )
                return 0;

        tp->langs_operator = op;

        return 1;
	};

RDF_Triple_Pattern_Part * rdfstore_triple_pattern_add_datatype(
	RDF_Triple_Pattern * tp,
	char * dt,
	int len ) {
	RDF_Triple_Pattern_Part * li=NULL;
	RDF_Triple_Pattern_Part * li1=NULL;
	RDF_Triple_Pattern_Part * tail=NULL;

        if (    ( tp == NULL ) ||
                ( dt == NULL ) ||
		( len <= 0 ) )
                return NULL;

        li = (RDF_Triple_Pattern_Part *)RDFSTORE_MALLOC(sizeof(RDF_Triple_Pattern_Part));

        if( li == NULL )
                return NULL;

        li->type = RDFSTORE_TRIPLE_PATTERN_PART_STRING;
	li->part.node = NULL;

	li->part.string = NULL;
        li->part.string = (unsigned char *) RDFSTORE_MALLOC( sizeof(unsigned char) * len ); 
        if ( li->part.string == NULL ) {
                RDFSTORE_FREE( li );
                return NULL;
                };
        memcpy( li->part.string, dt, len );
	memcpy( li->part.string+len, "\0", 1);

	li->next = NULL;

        if ( tp->dts != NULL ) {
                li1 = tp->dts;
                do {
                        tail = li1;
                } while ( ( li1 = li1->next ) != NULL );
                tail->next = li;
        } else {
                tp->dts = li;
                };

        return li;
	};

int rdfstore_triple_pattern_set_datatypes_operator(
	RDF_Triple_Pattern * tp,
	int op ) {
	if (    ( tp == NULL ) ||
                ( op < 0 ) ||
                ( op > 2 ) )
                return 0;

        tp->dts_operator = op;

        return 1;
	};

RDF_Triple_Pattern_Part * rdfstore_triple_pattern_add_word(
	RDF_Triple_Pattern * tp,
	unsigned char * word,
	int len ) {
	RDF_Triple_Pattern_Part * li=NULL;
	RDF_Triple_Pattern_Part * li1=NULL;
	RDF_Triple_Pattern_Part * tail=NULL;

        if (    ( tp == NULL ) ||
                ( word == NULL ) ||
		( len <= 0 ) )
                return NULL;

        li = (RDF_Triple_Pattern_Part *)RDFSTORE_MALLOC(sizeof(RDF_Triple_Pattern_Part));

        if( li == NULL )
                return NULL;

        li->type = RDFSTORE_TRIPLE_PATTERN_PART_STRING;
	li->part.node = NULL;

	li->part.string = NULL;
        li->part.string = (unsigned char *) RDFSTORE_MALLOC( sizeof(unsigned char) * len );
        if ( li->part.string == NULL ) {
                RDFSTORE_FREE( li );
                return NULL;
                };
        memcpy( li->part.string, word, len );
        memcpy( li->part.string+len, "\0", 1);

	li->next = NULL;

        if ( tp->words != NULL ) {
                li1 = tp->words;
                do {
                        tail = li1;
                } while ( ( li1 = li1->next ) != NULL );
                tail->next = li;
        } else {
                tp->words = li;
                };

        return li;
	};

int rdfstore_triple_pattern_set_words_operator(
	RDF_Triple_Pattern * tp,
	int op ) {
	if (    ( tp == NULL ) ||
                ( op < 0 ) ||
                ( op > 2 ) )
                return 0;

        tp->words_operator = op;

        return 1;
	};

RDF_Triple_Pattern_Part * rdfstore_triple_pattern_add_ranges(
	RDF_Triple_Pattern * tp,
	char * num,
	int len ) {
	RDF_Triple_Pattern_Part * li=NULL;
	RDF_Triple_Pattern_Part * li1=NULL;
	RDF_Triple_Pattern_Part * tail=NULL;

        if (    ( tp == NULL ) ||
                ( num == NULL ) ||
		( len <= 0 ) )
                return NULL;

        li = (RDF_Triple_Pattern_Part *)RDFSTORE_MALLOC(sizeof(RDF_Triple_Pattern_Part));

        if( li == NULL )
                return NULL;

        li->type = RDFSTORE_TRIPLE_PATTERN_PART_STRING;
	li->part.node = NULL;

	li->part.string = NULL;
        li->part.string = (unsigned char *) RDFSTORE_MALLOC( sizeof(unsigned char) * len );
        if ( li->part.string == NULL ) {
                RDFSTORE_FREE( li );
                return NULL;
                };
        memcpy( li->part.string, num, len );
        memcpy( li->part.string+len, "\0", 1);

	li->next = NULL;

        if ( tp->ranges != NULL ) {
                li1 = tp->ranges;
                do {
                        tail = li1;
                } while ( ( li1 = li1->next ) != NULL );
                tail->next = li;
        } else {
                tp->ranges = li;
                };

        return li;
	};

int rdfstore_triple_pattern_set_ranges_operator(
	RDF_Triple_Pattern * tp,
	int op ) {
	if (    ( tp == NULL ) ||
		( op < 0 ) ||
		( op > 10 ) )
                return 0;

        tp->ranges_operator = op;

        return 1;
	};

int _rdfstore_triple_pattern_free_part(
	RDF_Triple_Pattern_Part * list ) {
	if ( list == NULL )
                return 0;

        _rdfstore_triple_pattern_free_part( list->next );

	if ( list->type == RDFSTORE_TRIPLE_PATTERN_PART_STRING ) {
		if ( list->part.string != NULL )
			RDFSTORE_FREE( list->part.string );
	} else {
		rdfstore_node_free( list->part.node );
		};

        RDFSTORE_FREE( list );
	
	return 1;
	};

int rdfstore_triple_pattern_free(
	RDF_Triple_Pattern * tp ) {

	if ( tp == NULL )
		return 0;

	if ( tp->subjects != NULL )
		_rdfstore_triple_pattern_free_part( tp->subjects );

	if ( tp->predicates != NULL )
		_rdfstore_triple_pattern_free_part( tp->predicates );

	if ( tp->objects != NULL )
		_rdfstore_triple_pattern_free_part( tp->objects );

	if ( tp->contexts != NULL )
		_rdfstore_triple_pattern_free_part( tp->contexts );

	if ( tp->langs != NULL )
		_rdfstore_triple_pattern_free_part( tp->langs );

	if ( tp->dts != NULL )
		_rdfstore_triple_pattern_free_part( tp->dts );

	if ( tp->ranges != NULL )
		_rdfstore_triple_pattern_free_part( tp->ranges );

	if ( tp->words != NULL )
		_rdfstore_triple_pattern_free_part( tp->words );

	RDFSTORE_FREE( tp );

	return 1;
	};

void rdfstore_triple_pattern_dump(
	RDF_Triple_Pattern * tp ) {
	RDF_Triple_Pattern_Part * tpj=NULL;

        if (tp != NULL) {
		fprintf(stderr,"Triple pattern search:\n");
                if (tp->subjects != NULL) {
                        fprintf(stderr,"Subjects: (%s)\n", ( tp->subjects_operator == 0 ) ? "OR" : ( tp->subjects_operator == 1 ) ? "AND" : "NOT" );
                        tpj = tp->subjects;     
                        do {
				fprintf(stderr,"\tS='%s'\n", tpj->part.node->value.resource.identifier );
                                } while ( ( tpj = tpj->next ) != NULL );
                        };
                if (tp->predicates != NULL) {
                        fprintf(stderr,"Predicates: (%s)\n", ( tp->predicates_operator == 0 ) ? "OR" : ( tp->predicates_operator == 1 ) ? "AND" : "NOT");
                        tpj = tp->predicates;   
                        do {
                                fprintf(stderr,"\tP='%s'\n", tpj->part.node->value.resource.identifier );
                                } while ( ( tpj = tpj->next ) != NULL );
                        };
                if (tp->objects != NULL) {
                        fprintf(stderr,"Objects: (%s)\n", ( tp->objects_operator == 0 ) ? "OR" : ( tp->objects_operator == 1 ) ? "AND" : "NOT");
                        tpj = tp->objects;      
                        do {
                                if ( tpj->part.node->type != RDFSTORE_NODE_TYPE_LITERAL ) {
                                        fprintf(stderr,"\tO='%s'\n", tpj->part.node->value.resource.identifier );
                                } else {
                                        fprintf(stderr,"\tOLIT='%s'", tpj->part.node->value.literal.string );
/* do not search parser type in RDQL/BRQL??
                                        fprintf(stderr," PARSETYPE='%d'", tpj->part.node->value.literal.parseType);
*/
                                        fprintf(stderr,"\n");
                                        };
                                } while ( ( tpj = tpj->next ) != NULL );
                        };
                if (tp->langs != NULL) {
                        fprintf(stderr,"Languages: (%s)\n", ( tp->langs_operator == 0 ) ? "OR" : ( tp->langs_operator == 1 ) ? "AND" : "NOT");
                        tpj = tp->langs;        
                        do {
				fprintf(stderr,"\txml:lang='%s'\n", tpj->part.string );
                                } while ( ( tpj = tpj->next ) != NULL );
                        };
                if (tp->dts != NULL) {
                        fprintf(stderr,"Datatypes: (%s)\n", ( tp->dts_operator == 0 ) ? "OR" : ( tp->dts_operator == 1 ) ? "AND" : "NOT");
                        tpj = tp->dts;  
                        do {
                                fprintf(stderr,"\trdf:datatype='%s'\n", tpj->part.string );
                                } while ( ( tpj = tpj->next ) != NULL );
                        };
                if (tp->ranges != NULL) {
                        fprintf(stderr,"Ranges: (%s)\n", ( tp->ranges_operator == 1 ) ? "<" :
									( tp->ranges_operator == 2 ) ? "<=" :
									( tp->ranges_operator == 3 ) ? "==" :
									( tp->ranges_operator == 4 ) ? "!=" :
									( tp->ranges_operator == 5 ) ? ">=" :
									( tp->ranges_operator == 6 ) ? ">": 
									( tp->ranges_operator == 7 ) ? "a < b < c": 
									( tp->ranges_operator == 8 ) ? "a <= b < c": 
									( tp->ranges_operator == 9 ) ? "a <= b <= c": "a < b <= c" );
                        tpj = tp->ranges; /* it will have one element only anyway */
                        do {
                                fprintf(stderr,"\tterm='%s'\n", tpj->part.string );
                                } while ( ( tpj = tpj->next ) != NULL );
                        };
                if (tp->words != NULL) {
                        fprintf(stderr,"Words: (%s)\n", ( tp->words_operator == 0 ) ? "OR" : ( tp->words_operator == 1 ) ? "AND" : "NOT");
                        tpj = tp->words;        
                        do {
                                fprintf(stderr,"\tword/stem='%s'\n", tpj->part.string );
                                } while ( ( tpj = tpj->next ) != NULL );
                        };
                if (tp->contexts != NULL) {
                        fprintf(stderr,"Contexts: (%s)\n", ( tp->contexts_operator == 0 ) ? "OR" : ( tp->contexts_operator == 1 ) ? "AND" : "NOT");
                        tpj = tp->contexts;     
                        do {
                                fprintf(stderr,"\tC='%s'\n", tpj->part.node->value.resource.identifier );
                                } while ( ( tpj = tpj->next ) != NULL );
                        };
                };
	};

