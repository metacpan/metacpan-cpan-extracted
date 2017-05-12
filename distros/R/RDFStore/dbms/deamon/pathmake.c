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
 *
 * $Id: pathmake.c,v 1.9 2006/06/19 10:10:22 areggiori Exp $
 */ 

#include "dbms.h"
#include "dbms_compat.h"
#include "dbms_comms.h"
#include "deamon.h"
#include "pathmake.h"

/* returns null and/or full path
 * to a hashed directory tree. 
 * the final filename is hashed out
 * within that three. Way to complex
 * by now. Lifted from another project
 * which needed more.
 */
char *
mkpath(char * base, char * infile)
{
	char * file; int i,j;
    	char * slash,* dirname;
	static char tmp[ MAXPATHLEN ];
	char * inpath;
	char tmp2[ MAXPATHLEN ];
#define MAXHASH 2
	static char hash[ MAXHASH+1 ];

	strcpy(inpath=tmp2,infile);

	memset(hash,'_',MAXHASH);
	hash[ MAXHASH ]='\0';

	if (base==NULL)
		base="/";

	if (inpath==NULL || inpath[0] == '\0') {
		dbms_log(L_ERROR,"No filename or path for the database specified");
		return NULL;
		};

	/* remove our standard docroot if present
	 * so we can work with something relative.
	 * really a legacy thing from older perl DBMS.pm
	 * versions. Can go now.
	 */
	if (!(strncmp(base,inpath,strlen(base))))
		inpath += strlen(base);

        /* fetch the last leaf name 
	 */
	if((file = strrchr(inpath, '/')) != NULL) {
		*file = '\0';
		file++;
		} 
	else {
		file = inpath;
		inpath = "/";
		};

	if (!strlen(file)) {
		dbms_log(L_ERROR,"No filename for the database specified");
		return NULL;
		};
 
	strncpy(hash,file,MIN(strlen(file),MAXHASH));

//	strcat(tmp,base,"/",inpath,"/",hash,"/",file,NULL);
	strcpy(tmp,"/");
	strcat(tmp,base);
	strcat(tmp,"/");
	strcat(tmp,inpath);
	strcat(tmp,"/");
	strcat(tmp,hash);
	strcat(tmp,"/");
	strcat(tmp,file);

// 	sanity for leaf names...
//	actually this is really bad.. 
//
	if ((slash=strrchr(tmp,'.')) !=NULL) {
		if ( (!strcasecmp(slash+1,"db")) ||
		     (!strcasecmp(slash+1,"dbm")) ||
		     (!strcasecmp(slash+1,"gdb"))
		   ) *slash = '\0';
		};

	strcat(tmp,".db");

	for(i=0,j=0; tmp[i]; i++) {
		if (i && tmp[i]=='/' && tmp[i-1] =='/')
			continue;
		if (i != j) tmp[j] = tmp[i];
		j++;
		};
	tmp[j] = '\0';
	

	/* run through the full path name, and verify that
	 * each directory along the path actually exists
	 */
    	slash = tmp;
    	dirname = tmp;

  	while((slash=strchr(slash+1,'/')) != NULL) {
	    	struct stat s;
	    	*slash='\0';
    		*dirname='/';
    		/* check if tmp exists and is a directory (or a link
    		 * to one.. if not, create it, else give an error 
    		 */
    		if (stat(tmp,&s) == 0) {
			/* something exists.. it must be a directory 
			 */
			if ((s.st_mode & S_IFDIR) == 0) {
				dbms_log(L_ERROR,"Creation of %s failed; path element not directory",tmp);
				return NULL;
				};
			} 
		else if ( errno == ENOENT ) {
    			if ((mkdir(tmp,(S_IRWXU | S_IRWXG | S_IRWXO))) != 0) {
				dbms_log(L_ERROR,"Creation of %s failed; %s",tmp, strerror(errno));
				return NULL;
				};
			} 
   		 else {
			dbms_log(L_ERROR,"Path creation to failed at %s:%s",tmp,strerror(errno));
			return NULL;
    			};
   		 dirname=slash;
  		}
    	*dirname='/';

	return tmp;
	};
