#include <sys/types.h>
#include <sys/time.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <unistd.h>

#include <time.h>

/*#include <sys/syslimits.h>*/
#if !defined(WIN32)
#include <sys/param.h>
#endif
#include <sys/file.h>
#include <sys/stat.h>
#include <sys/socket.h>
#include <sys/errno.h>
#include <sys/uio.h>

#include "rdfstore_compress.h"
#include "rdfstore_flat_store.h"
#include "rdfstore_log.h"
#include "rdfstore_iterator.h"
#include "rdfstore_serializer.h"


static const char * _sp(DBT t) {
        static char out[1024];
        char tmp[16];
        int i;

        out[0]='\0';
        for(i=0;i<t.size && i<(sizeof(out)-1)/4;i++) {
                int c = ((unsigned char *)(t.data))[i];
                if (c<32 || c > 127) {
                        snprintf(tmp,sizeof(tmp),"/%02x/",c);
                } else {
                        snprintf(tmp,sizeof(tmp),"%c",c);
                }
                strcat(out,tmp);
        }
        return out;
}

/* print some stats (nibbles/bytes) for each index table concerning the compression algorithm used */
int main ( int argc, char * argv[]) {
	rdfstore * me;
	FLATDB  * db;
	DBT key, data, key1, data1;
	static unsigned char bits[RDFSTORE_MAXRECORDS_BYTES_SIZE];
	unsigned int outsize1=0;
	int i, items, s1,s2;
	long global_bytes_stats[256];
	long bytes_stats[256];
	long global_nibbles_stats[16];
	long nibbles_stats[16];
	char * host=NULL;
	int port=0;
	char * name=NULL;
	rdfstore_iterator * results=NULL;
	RDF_Node * node;
	char * buff;

	for( i=1; i<argc; i++) {
                if ((!strcmp(argv[i],"-port")) && (i+1<argc)) {
			port=atoi(argv[++i]);
                        if (port<=1) {
                                fprintf(stderr,"Aborted: You really want a port number >1.\n");
                                exit(1);
                                };
                } else {
			if ((!strcmp(argv[i],"-host")) && (i+1<argc)) {
				host = argv[++i];
                	} else {
				if (!strcmp(argv[i],"-v")) {
					fprintf(stderr,"Not implemented yet :)\n");
					exit(1);
				} else {
					char * cc;
					if ( (!strcmp(argv[i],"-h")) || ( (cc=strchr(argv[i],'-')) && (cc!=NULL) && (cc==argv[i]) ) ) {
						fprintf(stderr,"Syntax: %s [-host <dbms server name>] [-port <port>] databasename \n",argv[0]);
						exit(1);
					} else {
						/* rest is DB name */
						name = argv[i];
						};
                			};
				};
			};
		};
	
	memset(&key, 0, sizeof(key));
	memset(&key1, 0, sizeof(key1));
        memset(&data, 0, sizeof(data));
        memset(&data1, 0, sizeof(data1));

	if ( rdfstore_connect( &me, name, 1, 0, 0, (port || (host!=NULL)) ? 1 : 0, host,port,NULL,NULL,NULL,NULL ) != 0 ) {
		printf("Cannot connect to %s\n",name);
		return -1;
		};

	results = (rdfstore_iterator *) RDFSTORE_MALLOC(sizeof(rdfstore_iterator));
        if (results == NULL)
		return -1;
        results->store = me;
        results->remove_holes = 0;
	results->st_counter = 0;
	results->pos = 0;
	results->ids_size = 0;
	results->size = 1; /* just want the first one each time i.e. key ;) */

	/* subjects */
	db = me->subjects;

	for ( i=0; i<256; i++ ) {
		global_bytes_stats[i]=0;
		};
	for ( i=0; i<16; i++ ) {
		global_nibbles_stats[i]=0;
		};
	/* NOTE: garbage collection of first, fetch and next is not done here */
	if ( rdfstore_flat_store_first( db, &key ) == 0 ) {
        	do {
                	if ( rdfstore_flat_store_fetch( db, key, &data )) {
                        	outsize1=0;
				printf("subjects: LENGTH ZERO\n");
				continue;
                        	};

			/* Decode bit array */
                       	me->func_decode( data.size, data.data, &outsize1, bits);

			/* hack ;) */
			memcpy(results->ids, bits, outsize1);
			results->ids_size = outsize1;

			if((node=rdfstore_iterator_first_subject(results))!=NULL) {
				buff=rdfstore_ntriples_node( node );
				printf("subjects: key=%s\n",buff);
				RDFSTORE_FREE( buff );
				RDFSTORE_FREE( node->value.resource.identifier );
				RDFSTORE_FREE( node );
			} else {
				if (key.size == 4) 
					printf("subjects: key=%x (hex, 4byte int)\n",*(unsigned int *)(key.data));
				else
					printf("subjects: key=\"%s\" (len %d)'\n",_sp(key),key.size);
				};

			items ++;
			s1 += data.size;
			s2 += outsize1;

			for ( i=0; i<256; i++ ) {
				bytes_stats[i]=0;
				};
			for ( i=0; i<16; i++ ) {
				nibbles_stats[i]=0;
				};
			for ( i=0; i<outsize1; i++ ) {
				global_bytes_stats[bits[i]]++;
				bytes_stats[bits[i]]++;
				};

			printf("subjects: val_len_comp   = %d\n",(int)data.size);
			printf("subjects: val_len_decomp = %d\n",outsize1);
			printf("subjects: ratio = %f\n",(double)data.size/(double)outsize1);
			printf("subjects: byte symbols:\n");
			for ( i=0; i<256; i++ ) {
				if(bytes_stats[i]>0) {
					printf("\tb %02X = %d\n",i,(int)bytes_stats[i]);
					};
				};
			for ( i=0; i<outsize1; i++ ) {
				global_nibbles_stats[bits[i] & 0x0f]++;
				global_nibbles_stats[bits[i] >> 4]++;
				nibbles_stats[bits[i] & 0x0f]++;
				nibbles_stats[bits[i] >> 4]++;
				};
			printf("subjects: nibble symbols:\n");
			for ( i=0; i<16; i++ ) {
				if(nibbles_stats[i]>0) {
					printf("\tn %0X = %d\n",i,(int)nibbles_stats[i]);
					};
				};
			printf("-----------------------------\n");
        	} while ( rdfstore_flat_store_next( db, key, &key ) == 0 );
		printf("subjects: Global byte symbols:\n");
		for ( i=0; i<256; i++ ) {
			if(global_bytes_stats[i]>0) {
				printf("\tgb %02X = %d\n",i,(int)global_bytes_stats[i]);
				};
			};
		printf("subjects: Global nibble symbols:\n");
		for ( i=0; i<16; i++ ) {
			if(global_nibbles_stats[i]>0) {
				printf("\tgn %0X = %d\n",i,(int)global_nibbles_stats[i]);
				};
			};

		printf("Items in subjects: %d\n",items);
 		printf("Total size of subjects: %d (uncompressed %d)\n",s1,s2);

        	};

	/* predicates */
	db = me->predicates;

	for ( i=0; i<256; i++ ) {
		global_bytes_stats[i]=0;
		};
	for ( i=0; i<16; i++ ) {
		global_nibbles_stats[i]=0;
		};
	/* NOTE: garbage collection of first, fetch and next is not done here */
	if ( rdfstore_flat_store_first( db, &key ) == 0 ) {
        	do {
                	if ( rdfstore_flat_store_fetch( db, key, &data )) {
                        	outsize1=0;
				printf("predicates: LENGTH ZERO\n");
				continue;
                        	};

			/* Decode bit array */
                       	me->func_decode( data.size, data.data, &outsize1, bits);

			/* hack ;) */
                        memcpy(results->ids, bits, outsize1);
                        results->ids_size = outsize1;

                        if((node=rdfstore_iterator_first_predicate(results))!=NULL) {
				buff=rdfstore_ntriples_node( node );               
                                printf("predicates: key=%s\n",buff);                               
                                RDFSTORE_FREE( buff );
				RDFSTORE_FREE( node->value.resource.identifier );
                                RDFSTORE_FREE( node );
                        } else {
                                if (key.size == 4)
                                        printf("predicates: key=%x (hex, 4byte int)\n",*(unsigned int *)(key.data));
                                else
                                        printf("predicates: key=\"%s\" (len %d)'\n",_sp(key),key.size);
                                };

			items ++;
			s1 += data.size;
			s2 += outsize1;

			for ( i=0; i<256; i++ ) {
				bytes_stats[i]=0;
				};
			for ( i=0; i<16; i++ ) {
				nibbles_stats[i]=0;
				};
			for ( i=0; i<outsize1; i++ ) {
				global_bytes_stats[bits[i]]++;
				bytes_stats[bits[i]]++;
				};

			printf("predicates: val_len_comp   = %d\n",(int)data.size);
			printf("predicates: val_len_decomp = %d\n",outsize1);
			printf("predicates: ratio = %f\n",(double)data.size/(double)outsize1);
			printf("predicates: byte symbols:\n");
			for ( i=0; i<256; i++ ) {
				if(bytes_stats[i]>0) {
					printf("\tb %02X = %d\n",i,(int)bytes_stats[i]);
					};
				};
			for ( i=0; i<outsize1; i++ ) {
				global_nibbles_stats[bits[i] & 0x0f]++;
				global_nibbles_stats[bits[i] >> 4]++;
				nibbles_stats[bits[i] & 0x0f]++;
				nibbles_stats[bits[i] >> 4]++;
				};
			printf("predicates: nibble symbols:\n");
			for ( i=0; i<16; i++ ) {
				if(nibbles_stats[i]>0) {
					printf("\tn %0X = %d\n",i,(int)nibbles_stats[i]);
					};
				};
			printf("-----------------------------\n");
        	} while ( rdfstore_flat_store_next( db, key, &key ) == 0 );
		printf("predicates: Global byte symbols:\n");
		for ( i=0; i<256; i++ ) {
			if(global_bytes_stats[i]>0) {
				printf("\tgb %02X = %d\n",i,(int)global_bytes_stats[i]);
				};
			};
		printf("predicates: Global nibble symbols:\n");
		for ( i=0; i<16; i++ ) {
			if(global_nibbles_stats[i]>0) {
				printf("\tgn %0X = %d\n",i,(int)global_nibbles_stats[i]);
				};
			};

		printf("Items in predicates: %d\n",items);
 		printf("Total size of predicates: %d (uncompressed %d)\n",s1,s2);

        	};

	/* objects */
	db = me->objects;

	for ( i=0; i<256; i++ ) {
		global_bytes_stats[i]=0;
		};
	for ( i=0; i<16; i++ ) {
		global_nibbles_stats[i]=0;
		};
	/* NOTE: garbage collection of first, fetch and next is not done here */
	if ( rdfstore_flat_store_first( db, &key ) == 0 ) {
        	do {
                	if ( rdfstore_flat_store_fetch( db, key, &data )) {
                        	outsize1=0;
				printf("objects: LENGTH ZERO\n");
				continue;
                        	};

			/* Decode bit array */
                       	me->func_decode( data.size, data.data, &outsize1, bits);

			/* hack ;) */
                        memcpy(results->ids, bits, outsize1);
                        results->ids_size = outsize1;

                        if((node=rdfstore_iterator_first_object(results))!=NULL) {
				buff=rdfstore_ntriples_node( node );
				printf("objects: key=%s\n",buff);
				RDFSTORE_FREE( buff );
				if ( node->type == 1 ) {
					if ( node->value.literal.dataType != NULL )
						RDFSTORE_FREE( node->value.literal.dataType );
                        		RDFSTORE_FREE( node->value.literal.string );
                		} else {
					RDFSTORE_FREE( node->value.resource.identifier );
                        		};	
                                RDFSTORE_FREE( node );
                        } else {
                                if (key.size == 4)
                                        printf("objects: key=%x (hex, 4byte int)\n",*(unsigned int *)(key.data));
                                else
                                        printf("objects: key=\"%s\" (len %d)'\n",_sp(key),key.size);
                                };

			items ++;
			s1 += data.size;
			s2 += outsize1;

			for ( i=0; i<256; i++ ) {
				bytes_stats[i]=0;
				};
			for ( i=0; i<16; i++ ) {
				nibbles_stats[i]=0;
				};
			for ( i=0; i<outsize1; i++ ) {
				global_bytes_stats[bits[i]]++;
				bytes_stats[bits[i]]++;
				};

			printf("objects: val_len_comp   = %d\n",(int)data.size);
			printf("objects: val_len_decomp = %d\n",outsize1);
			printf("objects: ratio = %f\n",(double)data.size/(double)outsize1);
			printf("objects: byte symbols:\n");
			for ( i=0; i<256; i++ ) {
				if(bytes_stats[i]>0) {
					printf("\tb %02X = %d\n",i,(int)bytes_stats[i]);
					};
				};
			for ( i=0; i<outsize1; i++ ) {
				global_nibbles_stats[bits[i] & 0x0f]++;
				global_nibbles_stats[bits[i] >> 4]++;
				nibbles_stats[bits[i] & 0x0f]++;
				nibbles_stats[bits[i] >> 4]++;
				};
			printf("objects: nibble symbols:\n");
			for ( i=0; i<16; i++ ) {
				if(nibbles_stats[i]>0) {
					printf("\tn %0X = %d\n",i,(int)nibbles_stats[i]);
					};
				};
			printf("-----------------------------\n");
        	} while ( rdfstore_flat_store_next( db, key, &key ) == 0 );
		printf("objects: Global byte symbols:\n");
		for ( i=0; i<256; i++ ) {
			if(global_bytes_stats[i]>0) {
				printf("\tgb %02X = %d\n",i,(int)global_bytes_stats[i]);
				};
			};
		printf("objects: Global nibble symbols:\n");
		for ( i=0; i<16; i++ ) {
			if(global_nibbles_stats[i]>0) {
				printf("\tgn %0X = %d\n",i,(int)global_nibbles_stats[i]);
				};
			};

		printf("Items in objects: %d\n",items);
 		printf("Total size of objects: %d (uncompressed %d)\n",s1,s2);

        	};

	/* contexts */
	items=s1=s2=0;
	db = me->contexts;

	for ( i=0; i<256; i++ ) {
		global_bytes_stats[i]=0;
		};
	for ( i=0; i<16; i++ ) {
		global_nibbles_stats[i]=0;
		};

	/* NOTE: garbage collection of first, fetch and next is not done here */
	if ( rdfstore_flat_store_first( db, &key ) == 0 ) {
        	do {
                	if ( rdfstore_flat_store_fetch( db, key, &data ) == 0 ) {
                        	me->func_decode( data.size, data.data, &outsize1, bits);
                	} else {
                        	outsize1=0;
				printf("contexts: LENGTH ZERO\n");
				continue;
                        	};

			/* hack ;) */
                        memcpy(results->ids, bits, outsize1);
                        results->ids_size = outsize1;

                        if((node=rdfstore_iterator_first_context(results))!=NULL) {
				buff=rdfstore_ntriples_node( node );               
                                printf("contexts: key=%s\n",buff);                               
                                RDFSTORE_FREE( buff );
                                RDFSTORE_FREE( node->value.resource.identifier );
                                RDFSTORE_FREE( node );
                        } else {
                                if (key.size == 4)
                                        printf("contexts: key=%x (hex, 4byte int)\n",*(unsigned int *)(key.data));
                                else
                                        printf("contexts: key=\"%s\" (len %d)'\n",_sp(key),key.size);
                                };

			items ++;
			s1 += data.size;
			s2 += outsize1;

			for ( i=0; i<256; i++ ) {
				bytes_stats[i]=0;
				};
			for ( i=0; i<16; i++ ) {
				nibbles_stats[i]=0;
				};
			for ( i=0; i<outsize1; i++ ) {
				global_bytes_stats[bits[i]]++;
				bytes_stats[bits[i]]++;
				};
			printf("contexts: val_len_comp   = %d\n",(int)data.size);
			printf("contexts: val_len_decomp = %d\n",outsize1);
			printf("contexts: ratio = %f\n",(double)data.size/(double)outsize1);
			printf("contexts: byte symbols:\n");
			for ( i=0; i<256; i++ ) {
				if(bytes_stats[i]>0) {
					printf("\tb %02X = %d\n",i,(int)bytes_stats[i]);
					};
				};
			for ( i=0; i<outsize1; i++ ) {
				global_nibbles_stats[bits[i] & 0x0f]++;
				global_nibbles_stats[bits[i] >> 4]++;
				nibbles_stats[bits[i] & 0x0f]++;
				nibbles_stats[bits[i] >> 4]++;
				};
			printf("contexts: nibble symbols:\n");
			for ( i=0; i<16; i++ ) {
				if(nibbles_stats[i]>0) {
					printf("\tn %0X = %d\n",i,(int)nibbles_stats[i]);
					};
				};
			printf("-----------------------------\n");
        	} while ( rdfstore_flat_store_next( db, key, &key ) == 0 );
		printf("contexts: Global byte symbols:\n");
		for ( i=0; i<256; i++ ) {
			if(global_bytes_stats[i]>0) {
				printf("\tgb %02X = %d\n",i,(int)global_bytes_stats[i]);
				};
			};
		printf("contexts: Global nibble symbols:\n");
		for ( i=0; i<16; i++ ) {
			if(global_nibbles_stats[i]>0) {
				printf("\tgn %0X = %d\n",i,(int)global_nibbles_stats[i]);
				};
			};

		printf("Items in contexts: %d\n",items);
        	printf("Total size of contexts: %d (uncompressed %d)\n",s1,s2);
        };

	if(me->windex != NULL) {

	/* windex */
	items=s1=s2=0;
	db = me->windex;

	for ( i=0; i<256; i++ ) {
		global_bytes_stats[i]=0;
		};
	for ( i=0; i<16; i++ ) {
		global_nibbles_stats[i]=0;
		};
	/* NOTE: garbage collection of first, fetch and next is not done here */
	if ( rdfstore_flat_store_first( db, &key ) == 0 ) {
        	do {
			if (key.size == 4)
                                printf("windex: key=%x (hex, 4byte int) ",*(unsigned int *)(key.data));
                        else
                                printf("windex: key=\"%s\" (len %d)'",_sp(key),key.size);

                	if ( rdfstore_flat_store_fetch( db, key, &data ) == 0 ) {
                        	me->func_decode( data.size, data.data, &outsize1, bits);
                	} else {
                        	outsize1=0;
				printf("windex: LENGTH ZERO\n");
				continue;
                        	};

			items ++;
			s1 += data.size;
			s2 += outsize1;

			for ( i=0; i<256; i++ ) {
				bytes_stats[i]=0;
				};
			for ( i=0; i<16; i++ ) {
				nibbles_stats[i]=0;
				};
			for ( i=0; i<outsize1; i++ ) {
				global_bytes_stats[bits[i]]++;
				bytes_stats[bits[i]]++;
				};
			printf("windex: val_len_comp   = %d\n",(int)data.size);
			printf("windex: val_len_decomp = %d\n",outsize1);
			printf("windex: ratio = %f\n",(double)data.size/(double)outsize1);
			printf("windex: byte symbols:\n");
			for ( i=0; i<256; i++ ) {
				if(bytes_stats[i]>0) {
					printf("\tb %02X = %d\n",i,(int)bytes_stats[i]);
					};
				};
			for ( i=0; i<outsize1; i++ ) {
				global_nibbles_stats[bits[i] & 0x0f]++;
				global_nibbles_stats[bits[i] >> 4]++;
				nibbles_stats[bits[i] & 0x0f]++;
				nibbles_stats[bits[i] >> 4]++;
				};
			printf("windex: nibble symbols:\n");
			for ( i=0; i<16; i++ ) {
				if(nibbles_stats[i]>0) {
					printf("\tn %0X = %d\n",i,(int)nibbles_stats[i]);
					};
				};
			printf("-----------------------------\n");
        	} while ( rdfstore_flat_store_next( db, key, &key ) == 0 );

		printf("windex: Global byte symbols:\n");
		for ( i=0; i<256; i++ ) {
			if(global_bytes_stats[i]>0) {
				printf("\tgb %02X = %d\n",i,(int)global_bytes_stats[i]);
				};
			};
		printf("windex: Global nibble symbols:\n");
		for ( i=0; i<16; i++ ) {
			if(global_nibbles_stats[i]>0) {
				printf("\tgn %0X = %d\n",i,(int)global_nibbles_stats[i]);
				};
			};

		printf("Items in windex: %d\n",items);
        	printf("Total size of windex: %d (uncompressed %d)\n",s1,s2);

        	};
	};

#ifdef RDFSTORE_NEW_INDEX
	/* s_connections */
	db = me->s_connections;

	for ( i=0; i<256; i++ ) {
		global_bytes_stats[i]=0;
		};
	for ( i=0; i<16; i++ ) {
		global_nibbles_stats[i]=0;
		};
	/* NOTE: garbage collection of first, fetch and next is not done here */
	if ( rdfstore_flat_store_first( db, &key ) == 0 ) {
        	do {
                	if ( rdfstore_flat_store_fetch( db, key, &data )) {
                        	outsize1=0;
				printf("s_connections: LENGTH ZERO\n");
				continue;
                        	};

			/* Decode bit array */
                       	me->func_decode_connections( data.size, data.data, &outsize1, bits);

			/* hack ;) */
                        memcpy(results->ids, bits, outsize1);  
                        results->ids_size = outsize1;

                        if((node=rdfstore_iterator_first_subject(results))!=NULL) {   
                                buff=rdfstore_ntriples_node( node );
                                printf("s_connections: key=%s\n",buff);   
                                RDFSTORE_FREE( buff );
                                if ( node->type == 1 ) {
                                        if ( node->value.literal.dataType != NULL )
                                                RDFSTORE_FREE( node->value.literal.dataType );
                                        RDFSTORE_FREE( node->value.literal.string );
                                } else {
                                        RDFSTORE_FREE( node->value.resource.identifier );
                                        };
                                RDFSTORE_FREE( node );
                        } else {
                                if (key.size == 4)
                                        printf("s_connections: key=%x (hex, 4byte int)\n",*(unsigned int *)(key.data));
                                else   
                                        printf("s_connections: key=\"%s\" (len %d)'\n",_sp(key),key.size);
                                };

			items ++;
			s1 += data.size;
			s2 += outsize1;

			for ( i=0; i<256; i++ ) {
				bytes_stats[i]=0;
				};
			for ( i=0; i<16; i++ ) {
				nibbles_stats[i]=0;
				};
			for ( i=0; i<outsize1; i++ ) {
				global_bytes_stats[bits[i]]++;
				bytes_stats[bits[i]]++;
				};

			printf("s_connections: val_len_comp   = %d\n",(int)data.size);
			printf("s_connections: val_len_decomp = %d\n",outsize1);
			printf("s_connections: ratio = %f\n",(double)data.size/(double)outsize1);
			printf("s_connections: byte symbols:\n");
			for ( i=0; i<256; i++ ) {
				if(bytes_stats[i]>0) {
					printf("\tb %02X = %d\n",i,(int)bytes_stats[i]);
					};
				};
			for ( i=0; i<outsize1; i++ ) {
				global_nibbles_stats[bits[i] & 0x0f]++;
				global_nibbles_stats[bits[i] >> 4]++;
				nibbles_stats[bits[i] & 0x0f]++;
				nibbles_stats[bits[i] >> 4]++;
				};
			printf("s_connections: nibble symbols:\n");
			for ( i=0; i<16; i++ ) {
				if(nibbles_stats[i]>0) {
					printf("\tn %0X = %d\n",i,(int)nibbles_stats[i]);
					};
				};
			printf("-----------------------------\n");
        	} while ( rdfstore_flat_store_next( db, key, &key ) == 0 );
		printf("s_connections: Global byte symbols:\n");
		for ( i=0; i<256; i++ ) {
			if(global_bytes_stats[i]>0) {
				printf("\tgb %02X = %d\n",i,(int)global_bytes_stats[i]);
				};
			};
		printf("s_connections: Global nibble symbols:\n");
		for ( i=0; i<16; i++ ) {
			if(global_nibbles_stats[i]>0) {
				printf("\tgn %0X = %d\n",i,(int)global_nibbles_stats[i]);
				};
			};

		printf("Items in s_connections: %d\n",items);
 		printf("Total size of s_connections: %d (uncompressed %d)\n",s1,s2);

        	};

	/* p_connections */
	db = me->p_connections;

	for ( i=0; i<256; i++ ) {
		global_bytes_stats[i]=0;
		};
	for ( i=0; i<16; i++ ) {
		global_nibbles_stats[i]=0;
		};
	/* NOTE: garbage collection of first, fetch and next is not done here */
	if ( rdfstore_flat_store_first( db, &key ) == 0 ) {
        	do {
                	if ( rdfstore_flat_store_fetch( db, key, &data )) {
                        	outsize1=0;
				printf("p_connections: LENGTH ZERO\n");
				continue;
                        	};

			/* Decode bit array */
                       	me->func_decode_connections( data.size, data.data, &outsize1, bits);

			/* hack ;) */
                        memcpy(results->ids, bits, outsize1);
                        results->ids_size = outsize1;

                        if((node=rdfstore_iterator_first_predicate(results))!=NULL) {
                                buff=rdfstore_ntriples_node( node );
                                printf("p_connections: key=%s\n",buff);
                                RDFSTORE_FREE( buff );
                                if ( node->type == 1 ) {
                                        if ( node->value.literal.dataType != NULL )
                                                RDFSTORE_FREE( node->value.literal.dataType );
                                        RDFSTORE_FREE( node->value.literal.string );
                                } else {
                                        RDFSTORE_FREE( node->value.resource.identifier );
                                        };
                                RDFSTORE_FREE( node );
                        } else {
                                if (key.size == 4)
                                        printf("p_connections: key=%x (hex, 4byte int)\n",*(unsigned int *)(key.data));
                                else
                                        printf("p_connections: key=\"%s\" (len %d)'\n",_sp(key),key.size);
                                };

			items ++;
			s1 += data.size;
			s2 += outsize1;

			for ( i=0; i<256; i++ ) {
				bytes_stats[i]=0;
				};
			for ( i=0; i<16; i++ ) {
				nibbles_stats[i]=0;
				};
			for ( i=0; i<outsize1; i++ ) {
				global_bytes_stats[bits[i]]++;
				bytes_stats[bits[i]]++;
				};

			printf("p_connections: val_len_comp   = %d\n",(int)data.size);
			printf("p_connections: val_len_decomp = %d\n",outsize1);
			printf("p_connections: ratio = %f\n",(double)data.size/(double)outsize1);
			printf("p_connections: byte symbols:\n");
			for ( i=0; i<256; i++ ) {
				if(bytes_stats[i]>0) {
					printf("\tb %02X = %d\n",i,(int)bytes_stats[i]);
					};
				};
			for ( i=0; i<outsize1; i++ ) {
				global_nibbles_stats[bits[i] & 0x0f]++;
				global_nibbles_stats[bits[i] >> 4]++;
				nibbles_stats[bits[i] & 0x0f]++;
				nibbles_stats[bits[i] >> 4]++;
				};
			printf("p_connections: nibble symbols:\n");
			for ( i=0; i<16; i++ ) {
				if(nibbles_stats[i]>0) {
					printf("\tn %0X = %d\n",i,(int)nibbles_stats[i]);
					};
				};
			printf("-----------------------------\n");
        	} while ( rdfstore_flat_store_next( db, key, &key ) == 0 );
		printf("p_connections: Global byte symbols:\n");
		for ( i=0; i<256; i++ ) {
			if(global_bytes_stats[i]>0) {
				printf("\tgb %02X = %d\n",i,(int)global_bytes_stats[i]);
				};
			};
		printf("p_connections: Global nibble symbols:\n");
		for ( i=0; i<16; i++ ) {
			if(global_nibbles_stats[i]>0) {
				printf("\tgn %0X = %d\n",i,(int)global_nibbles_stats[i]);
				};
			};

		printf("Items in p_connections: %d\n",items);
 		printf("Total size of p_connections: %d (uncompressed %d)\n",s1,s2);

        	};

	/* o_connections */
	db = me->o_connections;

	for ( i=0; i<256; i++ ) {
		global_bytes_stats[i]=0;
		};
	for ( i=0; i<16; i++ ) {
		global_nibbles_stats[i]=0;
		};
	/* NOTE: garbage collection of first, fetch and next is not done here */
	if ( rdfstore_flat_store_first( db, &key ) == 0 ) {
        	do {
                	if ( rdfstore_flat_store_fetch( db, key, &data )) {
                        	outsize1=0;
				printf("o_connections: LENGTH ZERO\n");
				continue;
                        	};

			/* Decode bit array */
                       	me->func_decode_connections( data.size, data.data, &outsize1, bits);

			/* hack ;) */
                        memcpy(results->ids, bits, outsize1);
                        results->ids_size = outsize1;

                        if((node=rdfstore_iterator_first_object(results))!=NULL) {
                                buff=rdfstore_ntriples_node( node );
                                printf("o_connections: key=%s\n",buff);
                                RDFSTORE_FREE( buff );
                                if ( node->type == 1 ) {
                                        if ( node->value.literal.dataType != NULL )
                                                RDFSTORE_FREE( node->value.literal.dataType );
                                        RDFSTORE_FREE( node->value.literal.string );
                                } else {
                                        RDFSTORE_FREE( node->value.resource.identifier );
                                        };
                                RDFSTORE_FREE( node );
                        } else {
                                if (key.size == 4)
                                        printf("o_connections: key=%x (hex, 4byte int)\n",*(unsigned int *)(key.data));
                                else
                                        printf("o_connections: key=\"%s\" (len %d)'\n",_sp(key),key.size);
                                };
			
			items ++;
			s1 += data.size;
			s2 += outsize1;

			for ( i=0; i<256; i++ ) {
				bytes_stats[i]=0;
				};
			for ( i=0; i<16; i++ ) {
				nibbles_stats[i]=0;
				};
			for ( i=0; i<outsize1; i++ ) {
				global_bytes_stats[bits[i]]++;
				bytes_stats[bits[i]]++;
				};

			printf("o_connections: val_len_comp   = %d\n",(int)data.size);
			printf("o_connections: val_len_decomp = %d\n",outsize1);
			printf("o_connections: ratio = %f\n",(double)data.size/(double)outsize1);
			printf("o_connections: byte symbols:\n");
			for ( i=0; i<256; i++ ) {
				if(bytes_stats[i]>0) {
					printf("\tb %02X = %d\n",i,(int)bytes_stats[i]);
					};
				};
			for ( i=0; i<outsize1; i++ ) {
				global_nibbles_stats[bits[i] & 0x0f]++;
				global_nibbles_stats[bits[i] >> 4]++;
				nibbles_stats[bits[i] & 0x0f]++;
				nibbles_stats[bits[i] >> 4]++;
				};
			printf("o_connections: nibble symbols:\n");
			for ( i=0; i<16; i++ ) {
				if(nibbles_stats[i]>0) {
					printf("\tn %0X = %d\n",i,(int)nibbles_stats[i]);
					};
				};
			printf("-----------------------------\n");
        	} while ( rdfstore_flat_store_next( db, key, &key ) == 0 );
		printf("o_connections: Global byte symbols:\n");
		for ( i=0; i<256; i++ ) {
			if(global_bytes_stats[i]>0) {
				printf("\tgb %02X = %d\n",i,(int)global_bytes_stats[i]);
				};
			};
		printf("o_connections: Global nibble symbols:\n");
		for ( i=0; i<16; i++ ) {
			if(global_nibbles_stats[i]>0) {
				printf("\tgn %0X = %d\n",i,(int)global_nibbles_stats[i]);
				};
			};

		printf("Items in o_connections: %d\n",items);
 		printf("Total size of o_connections: %d (uncompressed %d)\n",s1,s2);

        	};
#endif

	rdfstore_iterator_close(results);

	rdfstore_disconnect( me );

	return 0;
};
