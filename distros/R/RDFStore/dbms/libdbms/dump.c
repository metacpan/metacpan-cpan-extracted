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

static char hex[] = "0123456789abcdef";
	
static const char * cls(DBT  * p) {
	char * q = (char *) p->data;
	static char buff[ 1024 ];
	char * r = buff;
	int i;
	for(i=0; i<sizeof(buff)-4 && i < p->size;i++, q++) {
		if ((*q == '\\')) 
			*r++ = *q;

		if (isprint((int)*q) && (*q != '\n') && (*q != '\r'))
			*r++ = *q;
		else {
			*r++ = '\\';
			*r++ = hex[ (*q >> 4) & 0x0F ];
			*r++ = hex[ *q & 0x0F ];
		}
	}

	* r = '\0';
	return buff;
}

static const char * xls(DBT  * p) {
	char * q = (char *) p->data;
	static char buff[ 1024 ];
	char * r = buff;
	int i;
	for(i=0; i<sizeof(buff)-6 && i < p->size;i++, q++) {

		if (isprint((int)*q) && (*q != '<') && (*q != '>')) {
			*r++ = *q;
		}
		else if ((*q == '<') || (*q == '>')) {
			*r++ = '&';
			*r++ = (*q == '<') ? 'l' : 'g';
			*r++ = 't';
			*r++ = ';';
		} else {
			*r++ = '&';
			*r++ = '#';
			*r++ = hex[ *q / 100 ];
			*r++ = hex[ (*q / 10 ) % 10 ];
			*r++ = hex[ *q % 10 ];
			*r++ = ';';
		}
	}

	* r = '\0';
	return buff;
}

int main(int argc, char * * argv) 
{
	dbms_error_t e;
	DBT key,val;
	int t,i, r;
	dbms * d;
	int xml = ((argc == 3) && (strcmp(argv[1],"-x") == 0)) ? 1 : 0;

	if ((argc < 2 || argc > 3) || ((argc == 3) && (!xml))) {
		fprintf(stderr,"Syntax: %s [-x] <dbname>\n",
			argv[0]);
		exit(1);	
	};

 	if (!(d = dbms_connect(argv[argc-1], NULL, 0, 
		DBMS_XSMODE_RDONLY, NULL, NULL, NULL, NULL, 0))) 
	{
		fprintf(stderr,"Failed to connect\n");
		exit(1);
	};

	val.data = NULL;
	val.size = 0;
	key.data = NULL;
	key.size = 0;

	if (xml) printf(
		"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
		"<!DOCTYPE plist PUBLIC \"-//@Semantics S.R.L.//DTD PLIST 1.0//EN\" "
			"\"http://www.asemanitcs.com/dtds/simple.dtd\">\n"
		"<dbase id=\"%s\">\n",argv[argc-1]);


	for(t = TOKEN_FIRSTKEY,i = 0, r = 0; r==0; t = TOKEN_NEXTKEY) {
		DBT nkey = { NULL, 0 };
		DBT nval = { NULL, 0 };

		e = dbms_comms(d, t, &r, &key, &val, &nkey, &nval);
		if (e) {
			fprintf(stderr,"Op NEXT failed %s\n", 
				dbms_get_error(d)); 
			exit(1);
		};
	
		if (xml) {
			printf("  <item id=\"%06d\">\n",++i);
			printf("    <key>%s</key>\n",xls(&key));
			printf("    <val>%s</val>\n",xls(&val));
			printf("  </item>\n");
		} else {
			printf("Key/Value pair # %06d\n",++i);
			printf("%s\n",	cls(&key));
			printf("%s\n\n",cls(&val));
		}

		if (key.size && key.data) free(key.data);
		if (val.size && val.data) free(val.data);
		val = nval;
		key = nkey;
	};
	if (xml) 
		printf("</dbase>\n");

	e = dbms_comms(d, TOKEN_CLOSE, NULL, NULL, NULL, NULL, NULL);
	if (e) {
		fprintf(stderr,"close failed %s\n", dbms_get_error(d)); 
		exit(1);
	};

	exit(0);
}
