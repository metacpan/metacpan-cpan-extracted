/*
 *     Copyright (c) 2000-2006 Alberto Reggiori <areggiori@webweaving.org>
 *                        Dirk-Willem van Gulik <dirkx@webweaving.org>
 *
 * NOTICE
 *
 * This product is distributed under a BSD/ASF like license as described in the 'LICENSE'
 * file you should have received together with this source code. If you did not get a
 * a copy of such a license agreement you can pick up one at:
 *
 *     http://rdfstore.sourceforge.net/LICENSE
 *
 */ 

#include "dbms.h"
#include "dbms_comms.h"

/* Number of fetch/store ops to try. */
#define N (50000)
#define M (100)

static void _note(dbms_cause_t event, int counter)
{
	fprintf(stderr,"Note %d callback\n",event);
	switch(event) {
	case DBMS_EVENT_RECONNECT:
		fprintf(stderr,"\tLost connection, is reconnecting.\n");
		break;

	case DBMS_EVENT_WAITING:
		fprintf(stderr,"\tIs connecting but long wait\n");
		break;

	default:
		fprintf(stderr,"\tUnk. callback event\n");
	};
}

static void _err(char * msg, int erx)
{
	fprintf(stderr,"Error %d - callback\n\t%s\n--\n",erx,msg);
}

int main(int argc, char * * argv) 
{
	dbms * d = dbms_connect( "test", NULL, 0, DBMS_XSMODE_DROP, NULL, NULL, &_note, &_err, 0);
	dbms_error_t e;

	if (!d) {
		perror("Duh");
		exit(1);
	} else
		printf("Open (and create) ok\n");

	e = dbms_comms(d, TOKEN_PING, NULL, NULL, NULL, NULL, NULL);
	if (e) {
		fprintf(stderr,"Op failed %s\n", dbms_get_error(d)); 
		exit(1);
	} else
		printf("Ping ok\n");

{
	DBT key,val;
	int r = 0;
	key.data = (char *) "Foo";
	key.size=strlen((char *)key.data);
	val.data = NULL;
	val.size = 0;
	e = dbms_comms(d, TOKEN_FETCH, &r, &key, NULL, NULL, &val);
	if (e) {
		fprintf(stderr,"Op FETCH failed %s\n", dbms_get_error(d)); 
		exit(1);
	} else
	if (r == 0) {
		fprintf(stderr,"Fetch returned a 'found' - EEK!\n");
		exit(1);
		}
	if (r != 1) {
		fprintf(stderr,"Fetch returned a strange value - EEK!\n");
		exit(1);
	} else
		printf("Fetch ok (it came up empty)\n");
}
{
	DBT key,val;
	int r = 0;

	/* include traling \0 to make printing on retrival easier */
	key.data = (char *) "Foo";
	key.size=strlen((char *)key.data)+1;

	val.data = (char *) "Bar";
	val.size = strlen((char *)val.data) + 1; 

	e = dbms_comms(d, TOKEN_STORE, &r, &key, &val, NULL, NULL);
	if (e) {
		fprintf(stderr,"Op STORE failed %s\n", dbms_get_error(d)); 
		exit(1);
	} else
	if (r != 0) {
		fprintf(stderr,"Fetch returned a strange value - EEK!\n");
		exit(1);
	} else
		printf("Store ok\n");
}
{
	DBT key,val;
	int r = 0;
	key.data = (char *) "Foo";
	key.size=strlen((char *)key.data)+1;
	e = dbms_comms(d, TOKEN_FETCH, &r, &key, NULL, NULL, &val);
	if (e) {
		fprintf(stderr,"Op FETCH failed %s\n", dbms_get_error(d)); 
		exit(1);
	} else
	if (r != 0) {
		fprintf(stderr,"Fetch returned a strange value - EEK!\n");
		exit(1);
	};

	if (strcmp((char *)(val.data),"Bar")) {
		fprintf(stderr,"Fetch failed (it came up with \"%s\")\n",
			(char *)(val.data));
		exit(1);
	};

	printf("Fetch ok (it came up with \"%s\")\n",
		(char *)(val.data));
	free(val.data);
}
{
int j;
char * pad = NULL;
for(j=0;j<M;j+=M/10) {
	pad = malloc(j)+1;
	memset(pad,'X',j);
	pad[j]='\0';
printf("Size %d\n",j);
{
	DBT key,val;
	char foo[ 10240 ];
	char bar[ 10240 ];
	int r,i;
	time_t start = time(NULL);
	for(i=0;i<N;i++) {
		snprintf(foo,sizeof(foo),"Foo %06d",i);
		snprintf(bar,sizeof(bar),"Bar %06d %s",i,pad);
		key.data = (char *) foo;
		key.size = strlen(foo)+1;
		val.data = (char *) bar;
		val.size = strlen(bar)+1;
		r = 0;
		e = dbms_comms(d, TOKEN_STORE, &r, &key, &val, NULL, NULL);
		if (e || r != 0) {
			fprintf(stderr,"%d store failed\n",i);
			exit(1);
		};
	};
	printf("%d ingests done: %f seconds or %.2f transactions/second\n",N,difftime(time(NULL),start),N/difftime(time(NULL),start));
}
{
	DBT key,val;
	char foo[ 10240 ], bar[ 10240 ];
	int r,i;
	time_t start = time(NULL);
	for(i=0;i<N;i++) {
		snprintf(foo,sizeof(foo),"Foo %06d",i);
		snprintf(bar,sizeof(bar),"Bar %06d %s",i,pad);
		key.data = (char *) foo;
		key.size = strlen(foo)+1;
		r = 0;
		e = dbms_comms(d, TOKEN_FETCH, &r, &key, NULL, NULL, &val);
		if (e || r != 0) {
			fprintf(stderr,"%d fetch failed\n",i);
			exit(1);
		} else
		if (strcmp((char *)(val.data),bar)) {
			fprintf(stderr,"Dud reply %s != %s\n",foo,(char *)val.data);
			exit(1);
		}
		free(val.data);
	};
	printf("%d fetches done: %f seconds %.2f transactions/second\n",N,difftime(time(NULL),start),N/difftime(time(NULL),start));
}
//free(pad);
}
}

	e = dbms_comms(d, TOKEN_DROP, NULL, NULL, NULL, NULL, NULL);
	if (e) {
		fprintf(stderr,"drop failed\n\t%s\n", dbms_get_error(d)); 
		exit(1);
	} else
		printf("Drop ok\n");


	e = dbms_comms(d, TOKEN_CLOSE, NULL, NULL, NULL, NULL, NULL);
	if (e) {
		fprintf(stderr,"close failed %s\n", dbms_get_error(d)); 
		exit(1);
	} else
		printf("Close ok\n");

	printf("Clean exit\n");
	exit(0);
}
