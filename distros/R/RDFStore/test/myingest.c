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
#include "rdfstore_utf8.h"
#include "rdfstore_serializer.h"

extern char *optarg;

int main ( int argc, char * * argv ) {
	rdfstore * me;
	DBT key, data, data1;
	int c, ch;
	char * db = "cooltest";
	char * host = NULL;
	long int ttime=0,ltime=0;
	struct timeval tstart,tnow;
	int line = 0;
	int freetext = 0, sync = 0, remote = 0;
	FILE * f;

	gettimeofday(&tstart,NULL);	

	while ((ch = getopt(argc, argv, "fmd:")) != -1)
             switch (ch) {
             case 'f':
                     freetext = 1;
                     break;
             case 'm':
                     db = NULL;
                     break;
             case 'd':
                     db = optarg;
                     break;
             case 'r':
		     remote = 1; 
                     host = optarg;
                     break;
             case '?':
             default:
                     fprintf(stderr,"%s: Usage [-f] [-m] [-d dbase] [-r host]\n",argv[0]);
     }
     	argc -= optind;
     	argv += optind;

	if (argc == 1)
		f = fopen(argv[0],"r");
	else
		f = stdin;

	memset(&key, 0, sizeof(key));
        memset(&data, 0, sizeof(data));
        memset(&data1, 0, sizeof(data1));

        if ( rdfstore_connect( &me, db, 0, freetext, sync, remote, host,0,NULL,NULL,NULL,NULL ) != 0 ) {
		printf("Cannot connect :( \n");
		return -1;
	};

	c=0;
	while(!feof(f)) {
		char buff[102400];
		char * v[3], *p;
		int vi =0;
		int t0,t1,t2;
		RDF_Statement statement;
		RDF_Node subject, object, predicate;
		
		/* Assume value <space> value <space> value 
	 	 * and values can be "-ed. 
		 */
		if (fgets(buff,sizeof(buff),f) == NULL) 
			exit(1);
		line++;
		for(p=buff;*p;p++) {
			char * e;

			if (isspace(*p)) 
				continue;

			if (*p == '"') {
				p++;
				if ((e = index(p,'"'))==NULL) {
					fprintf(stderr,"no closing \" at line %d\n",line);
					exit(1);
				};
			} else  {
				if ((e = index(p,' '))==NULL) 
					e = p+strlen(p)-1;
			};
			*e = '\0';
			if (vi<3)
				v[ vi ] = p;
			vi++;
			p=e;
		};
		if (vi != 3) {
			fprintf(stderr,"not 3 but %d items at line %d\n",vi,line);
			exit(1);
		};

		t0=t1=t2=1; 	/* assume all literals*/

		if (v[0][0]=='<') { v[0]++; v[0][strlen(v[0])-1]='\0'; t0=0; };
		if (v[1][0]=='<') { v[1]++; v[1][strlen(v[1])-1]='\0'; t1=0;};
		if (v[2][0]=='<') { v[2]++; v[2][strlen(v[2])-1]='\0'; t2=0; };

		if (0) printf("Triple: '%s','%s','%s'\n", v[0],v[1],v[2]);

		statement.subject = &subject;
		statement.predicate = &predicate;
		statement.object = &object;
		statement.node = NULL;
		statement.context = NULL;

		subject.value.resource.identifier = v[0];
		subject.value.resource.identifier_len = strlen(v[0]);
		statement.hashcode = 0;
		statement.isreified = 0;

		subject.hashcode = 0;
		subject.type =  t0;
assert(!t0);
assert(!t1);
		predicate.value.resource.identifier = v[1];
		predicate.value.resource.identifier_len = strlen(v[1]);
		predicate.hashcode = 0;
		predicate.type = t1;

		object.hashcode = 0;
		object.type = t2;
		if (t2) {
			object.value.literal.string = v[2];
			object.value.literal.string_len = strlen(v[2]);
			object.value.literal.parseType = 0;
			object.value.literal.dataType = NULL;
       			strcpy(object.value.literal.lang,"");	/* lang is not a ptr, but a char lang[10] */
		} else {
			object.value.resource.identifier = v[2];
			object.value.resource.identifier_len = strlen(v[2]);
		}

		if(rdfstore_insert( me, &statement, NULL )) {
                	fprintf(stderr,"cannot insert statement\n");
                	return -1;
        		};

#define DD (100)
		if( (c++ % DD) == 0 ) {
			gettimeofday(&tnow,NULL);
        		ttime = ( tnow.tv_sec - tstart.tv_sec ) * 1000.0 + ( tnow.tv_usec - tstart.tv_usec ) / 1000.0;
			printf("adding %d [%.1f sec, %.2f/second overall - %.2f/second now]\n",c,ttime/1000.0,1000.0*c/ttime,1000.0*DD/(ttime-ltime));
			ltime=ttime;
			};
		};

	rdfstore_disconnect( me );

	return 0;
};
