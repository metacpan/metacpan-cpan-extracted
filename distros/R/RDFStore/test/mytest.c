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

#include "rdfstore_log.h"
#include "rdfstore.h"

static const char * _sp(DBT t) {
	char out[1024];
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
	return strdup(out);
}

static const int _si(DBT t) {
	return (int)((int *)(t.data))[0];
}

int main ( int argc, char * * argv ) {
	rdfstore * me;
	DBT key, data, data1;
	int i;
	int test;
		
	test = -1234568;

	memset(&key, 0, sizeof(key));
        memset(&data, 0, sizeof(data));
        memset(&data1, 0, sizeof(data1));

	rdfstore_connect( &me, "cooltest", 0, 0, 0, 0, NULL,0,NULL,NULL,NULL,NULL );

	/* store */
        key.data = "memyselfI";
        key.size = sizeof("memyselfI");
        data.data = "Albe";
        data.size = strlen("Albe")+1;

	if( (rdfstore_flat_store_store( me->model, key, data )) != 0 )
		printf("Cannot store %s = %d\n",_sp(key),_si(data));

	if(rdfstore_flat_store_exists( me->model, key ) == 0 ) {
		printf("Ok key %s does exist\n",_sp(key));
	} else {
		printf("Ok key %s does NOT exist\n",_sp(key));
	};

	/* fetch */
	if( (rdfstore_flat_store_fetch( me->model, key, &data1 )) != 0 ) {
		printf("Cannot fetch %s \n",_sp(key));
	} else {
		RDFSTORE_FREE( data1.data ) ;
		};

	printf("Fetched '%s'\n",_sp(data1));

        key.data = "you";
        key.size = sizeof("you");
        data.data = "Albe";
        data.size = strlen("Albe")+1;

	if( (rdfstore_flat_store_store( me->model, key, data )) != 0 )
		printf("Cannot store %s = %d\n",_sp(key),_si(data));

        key.data = "counter";
        key.size = sizeof("counter");
        data.data = "0";
        data.size = strlen("0")+1;

	if( (rdfstore_flat_store_store( me->model, key, data )) != 0 )
		printf("Cannot store %s = %d\n",_sp(key),_si(data));

	/* fetch */
	if( (rdfstore_flat_store_fetch( me->model, key, &data1 )) != 0 ) {
		printf("Cannot fetch %s \n",_sp(key));
	} else {
		RDFSTORE_FREE( data1.data ) ;
		};

	printf("Fetched '%s'\n",_sp(data1));

	for ( i = 0; i <10000 ; i++ ) {
		/* inc */
		if( (rdfstore_flat_store_inc( me->model, key, &data1 )) != 0 ) {
			printf("Cannot inc %s \n",_sp(key));
		} else {
			RDFSTORE_FREE( data1.data ) ;
			};
	};

	/* fetch */
	if( (rdfstore_flat_store_fetch( me->model, key, &data1 )) != 0 ) {
		printf("Cannot fetch %s \n",_sp(key));
	} else {
		RDFSTORE_FREE( data1.data ) ;
		};

	printf("Fetched '%s'\n",_sp(data1));

	for ( i = 0; i <9999 ; i++ ) {
		/* dec */
		if( (rdfstore_flat_store_dec( me->model, key, &data1 )) != 0 ) {
			printf("Cannot dec %s \n",_sp(key));
		} else {
			RDFSTORE_FREE( data1.data ) ;
			};
	};

	/* NOTE: garbage collection of first and next is not done here */
	/* first */
	if( (rdfstore_flat_store_first( me->model, &data1 )) != 0 ) {
		printf("Cannot first \n");
		};

	/* next */
	while (rdfstore_flat_store_next( me->model, data1, &data ) == 0 ) {
		printf("GOT %s\n",_sp(data));
	};

	if(rdfstore_flat_store_exists( me->model, key ) == 0 ) {
		printf("Ok key %s does exist\n",_sp(key));
	} else {
		printf("Ok key %s does NOT exist\n",_sp(key));
	};

	/* delete */
	if( rdfstore_flat_store_delete ( me->model, key ) != 0 )
		printf("Cannot delete %s \n",_sp(key));

	if( rdfstore_flat_store_clear ( me->model ) != 0 )
		printf("Cannot clear \n");

        key.data = "you";
        key.size = sizeof("you");
	if(rdfstore_flat_store_exists( me->model, key ) == 0 ) {
		printf("Ok key %s does exist\n",_sp(key));
	} else {
		printf("Ok key %s does NOT exist\n",_sp(key));
	};

	if( rdfstore_flat_store_sync ( me->model ) != 0 )
		printf("Cannot sync \n");

	rdfstore_disconnect( me );

	return 0;
};
