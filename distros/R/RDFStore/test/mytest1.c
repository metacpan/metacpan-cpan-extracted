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

#include "rdfstore.h"
#include "rdfstore_log.h"
#include "rdfstore_serializer.h"
#include "rdfstore_utf8.h"

int main ( int argc, char * * argv ) {
	rdfstore * me;
	DBT key, data, data1;
	int i,n=6000;
	RDF_Statement * statement;
	long int ttime=0;
	struct timeval tstart,tnow;

	gettimeofday(&tstart,NULL);	

	if (argc == 2)
		n = atoi(argv[1]);

	memset(&key, 0, sizeof(key));
        memset(&data, 0, sizeof(data));
        memset(&data1, 0, sizeof(data1));

	/* rdfstore_connect( &me, NULL, 0, 1, 0, 0, NULL,0 );*/
	/*if ( rdfstore_connect( &me, "cooltest", 0, 1, 0, 1, "localhost",1234 ) != 0 ) */
	/*if ( rdfstore_connect( &me, NULL, 0, 0, 0, 0, NULL,0,NULL,NULL,NULL,NULL ) != 0 ) */
	/* if ( rdfstore_connect( &me, "cooltest", 0, 1, 0, 0, NULL,0,NULL,NULL,NULL,NULL ) != 0 ) */
	/*if ( rdfstore_connect( &me, NULL, 0, 1, 0, 0, NULL,0,NULL,NULL,NULL,NULL ) != 0 )*/
	/*if ( rdfstore_connect( &me, NULL, 0, 0, 0, 0, NULL,0,NULL,NULL,NULL,NULL ) != 0 )*/
	if ( rdfstore_connect( &me, "cooltest", 0, 0, 0, 0, NULL,0,NULL,NULL,NULL,NULL ) != 0 )

	{
		printf("Cannot connect :( \n");
		return -1;
		};

/*
	if(rdfstore_is_empty( me )) {
		printf("rdfstore should be empty!\n");
		return -1;
	};
*/


	for ( i=1; i<n+1; i++ ) {
		#define BZ(x) { if ((x)==NULL) { fprintf(stderr,"No memory"); exit(1); }; bzero((x),sizeof(*(x))); }

		statement = (RDF_Statement *) RDFSTORE_MALLOC(sizeof(RDF_Statement));
		BZ(statement);

		statement->context = NULL;
		statement->hashcode = 0;
		statement->isreified = 0;

		statement->subject = (RDF_Node *) RDFSTORE_MALLOC(sizeof(RDF_Node));
		BZ(statement->subject);

		statement->subject->hashcode = 0;
		statement->subject->type = 0;

		statement->predicate = (RDF_Node *) RDFSTORE_MALLOC(sizeof(RDF_Node));
		BZ(statement->predicate);

		statement->predicate->hashcode = 0;
		statement->predicate->type = 0;

		statement->object = (RDF_Node *) RDFSTORE_MALLOC(sizeof(RDF_Node));
		BZ(statement->object);

		statement->object->hashcode = 0;
		statement->object->type = 1; /* literal */
		statement->node = NULL;
			
		statement->subject->value.resource.identifier = (char *) RDFSTORE_MALLOC(sizeof(char)*255);
		sprintf(statement->subject->value.resource.identifier,
			"http://www.w3.org/Home/Lassila/Creator%09d",i);
		statement->subject->value.resource.identifier_len = strlen(statement->subject->value.resource.identifier);

		statement->predicate->value.resource.identifier = (char *) RDFSTORE_MALLOC(sizeof(char)*255);
		strcpy(statement->predicate->value.resource.identifier,
			"http://description.org/schema/Creator");
		statement->predicate->value.resource.identifier_len = strlen(statement->predicate->value.resource.identifier);

		statement->object->value.literal.string = (char *) RDFSTORE_MALLOC(sizeof(char)*255);
		sprintf(statement->object->value.literal.string,
			"Ora Lassila %09d",i);
		statement->object->value.literal.string_len = strlen(statement->object->value.literal.string);

		statement->object->value.literal.parseType = 0;
		statement->object->value.literal.dataType = NULL;
		strcpy(statement->object->value.literal.lang,"");

/*
		ntriple = rdfstore_ntriples_statement( statement, NULL );
		if ( ntriple != NULL ) {
			printf("%s\n",ntriple);
			RDFSTORE_FREE( ntriple );
			};
*/

		if(rdfstore_insert( me, statement, NULL )) {
                	fprintf(stderr,"cannot insert statement\n");
                	return -1;
        		};

		RDFSTORE_FREE( statement->object->value.literal.string );
		RDFSTORE_FREE( statement->object );
		RDFSTORE_FREE( statement->predicate->value.resource.identifier );
		RDFSTORE_FREE( statement->predicate );
		RDFSTORE_FREE( statement->subject->value.resource.identifier );
		RDFSTORE_FREE( statement->subject );
		RDFSTORE_FREE( statement );

		if( (i % 100) == 0 || (i == n)) {
			gettimeofday(&tnow,NULL);
        		ttime += ( tnow.tv_sec - tstart.tv_sec ) * 1000000 + ( tnow.tv_usec - tstart.tv_usec ) * 1;
        		/*ttime = ( tnow.tv_sec - tstart.tv_sec ) * 1000000 + ( tnow.tv_usec - tstart.tv_usec ) * 1;*/
			printf("adding\t%d\t[%8d sec, %.02f #/sec]\n",i,(int)(ttime/1000000), 1000000.0*i/ttime);

			gettimeofday(&tstart,NULL);	
		};
	};

	exit(1);
	for ( i=1; i<n+1; i++ ) {
		#define BZ(x) { if ((x)==NULL) { fprintf(stderr,"No memory"); exit(1); }; bzero((x),sizeof(*(x))); }

		statement = (RDF_Statement *) RDFSTORE_MALLOC(sizeof(RDF_Statement));
		BZ(statement);

		statement->context = NULL;
		statement->hashcode = 0;
		statement->isreified = 0;

		statement->subject = (RDF_Node *) RDFSTORE_MALLOC(sizeof(RDF_Node));
		BZ(statement->subject);

		statement->subject->hashcode = 0;
		statement->subject->type = 0;

		statement->predicate = (RDF_Node *) RDFSTORE_MALLOC(sizeof(RDF_Node));
		BZ(statement->predicate);

		statement->predicate->hashcode = 0;
		statement->predicate->type = 0;

		statement->object = (RDF_Node *) RDFSTORE_MALLOC(sizeof(RDF_Node));
		BZ(statement->object);

		statement->object->hashcode = 0;
		statement->object->type = 1; /* literal */
		statement->node = NULL;
			
		statement->subject->value.resource.identifier = (char *) RDFSTORE_MALLOC(sizeof(char)*255);
		sprintf(statement->subject->value.resource.identifier,
			"http://www.w3.org/Home/Lassila/Creator%09d",i);
		statement->subject->value.resource.identifier_len = strlen(statement->subject->value.resource.identifier);

		statement->predicate->value.resource.identifier = (char *) RDFSTORE_MALLOC(sizeof(char)*255);
		strcpy(statement->predicate->value.resource.identifier,
			"http://description.org/schema/Creator");
		statement->predicate->value.resource.identifier_len = strlen(statement->predicate->value.resource.identifier);

		statement->object->value.literal.string = (char *) RDFSTORE_MALLOC(sizeof(char)*255);
		sprintf(statement->object->value.literal.string,
			"Ora Lassila %09d",i);
		statement->object->value.literal.string_len = strlen(statement->object->value.literal.string);

		statement->object->value.literal.parseType = 0;
		statement->object->value.literal.dataType = NULL;
		strcpy(statement->object->value.literal.lang,"");

		if(rdfstore_remove( me, statement, NULL )) {
                	printf("cannot remove statement\n");
                	return -1;
        		};

		RDFSTORE_FREE( statement->object->value.literal.string );
		RDFSTORE_FREE( statement->object );
		RDFSTORE_FREE( statement->predicate->value.resource.identifier );
		RDFSTORE_FREE( statement->predicate );
		RDFSTORE_FREE( statement->subject->value.resource.identifier );
		RDFSTORE_FREE( statement->subject );
		RDFSTORE_FREE( statement );

		if( (i % 100) == 0 || (i == n)) {
			gettimeofday(&tnow,NULL);
        		ttime += ( tnow.tv_sec - tstart.tv_sec ) * 1000000 + ( tnow.tv_usec - tstart.tv_usec ) * 1;
        		/*ttime = ( tnow.tv_sec - tstart.tv_sec ) * 1000000 + ( tnow.tv_usec - tstart.tv_usec ) * 1;*/
			printf("removing %d [%d sec]\n",i,(int)(ttime/1000000));

			gettimeofday(&tstart,NULL);	
		};
	};

	rdfstore_disconnect( me );

	return 0;
};
