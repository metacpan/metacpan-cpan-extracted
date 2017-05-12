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
 * $Id: handler.c,v 1.48 2006/06/19 10:10:22 areggiori Exp $
 */ 

#include "dbms.h"
#include "dbms_comms.h"
#include "dbms_compat.h"
#include "dbmsd.h"

#include "deamon.h"
#include "mymalloc.h"
#include "handler.h"
#include "children.h"
#include "pathmake.h"

#include "rdfstore_flat_store.h"

dbase                 * first_dbp = NULL;

#ifdef STATIC_BUFF
static dbase * free_dbase_list = NULL;
static int free_dbase_list_len = 0;
static int free_dbase_list_keep = 2;
static int free_dbase_list_max = 8;
#endif
static int dbase_counter = 0;

#ifdef BERKELEY_DB_1_OR_2
static int rdfstore_backend_dbms_compare_int(
        const DBT *a,
        const DBT *b );
#else
static int rdfstore_backend_dbms_compare_int(
        DB *file,
        const DBT *a,
        const DBT *b );
#endif

#ifdef BERKELEY_DB_1_OR_2
static int rdfstore_backend_dbms_compare_double(
        const DBT *a,
        const DBT *b );
#else
static int rdfstore_backend_dbms_compare_double(
        DB *file,
        const DBT *a,
        const DBT *b );
#endif


char * iprt( DBT * r ) {
        static char tmp[ 128 ]; int i;
	if (r==NULL)
		return "<null>";
	if (r->data==NULL)
		return "<null ptr>";
	if (r->size < 0 || r->size > 1024*1024)
		return "<weird size>";

        for(i=0;i< ( r->size > 127 ? 127 : r->size);i++) {
		int c= ((char *)(r->data))[i];
		tmp[i] =  ((c<32) || (c>127)) ? '.' : c;
		};

        tmp[i]='\0';
        return tmp;
        }                      

char * eptr( int i ) {
	if (i==0) 
		return "Ok   ";
	else
	if (i==1)
		return "NtFnd";
	else
	if (i==2)
		return "Incmp";
	else
	if (i>2)
		return "+?   ";
	else
		return "Fail ";
	}

static int _dbclose(dbase *q)
{
	if ((q->handle->sync)(q->handle,0)) 
		return -1;

#ifdef DB_VERSION_MAJOR
	if (	(q->cursor->c_close(q->cursor)) ||
	   	((q->handle->close)(q->handle, 0)) )
#else
	if ((q->handle->close)(q->handle))
#endif
		return -1;
	return 0;
}

void
free_dbs(
	dbase * q
	)
{
	if ((q->handle) && (_dbclose(q)))
			dbms_log(L_ERROR,"Sync/Close(%s) returned an error during closing of db", q->name); 

#ifdef STATIC_BUFF
	if (free_dbase_list_len < free_dbase_list_keep) {
		q->nxt = free_dbase_list;
		free_dbase_list = q;	
		free_dbase_list_len ++;
	} else 
#endif
        	myfree(q);

#ifndef STATIC_BUFF
	if (q->pfile) myfree(q->pfile);
       	if (q->name) myfree(q->name);
#endif
	dbase_counter --;
};

void
zap_dbs (
	dbase * r
	)
{
	dbase * * p;
	connection * s;

	/* XXX we do not want this ?! before we 
	 * know it we end up in n**2 land
	 */
        for ( p = &first_dbp; *p && *p != r; )
                p = &((*p)->nxt);

        if ( *p == NULL) {
                dbms_log(L_ERROR,"DBase to zap not found");
                return;
                };

	/* should we not first check all the connections
	 * to see if there are (about to) close..
	 */
	for(s=client_list; s;s=s->next) 
		if (s->dbp == r) {
			s->close = 1; MX;
			};
        *p = r->nxt;
        free_dbs(r);
        }


void close_all_dbps() {
	dbase * p;

        for(p=first_dbp; p;) {
                dbase * q;
                q = p; p=p->nxt;
		free_dbs( q ); /* XXXX why am I not just calling ZAP ? */
		};
	first_dbp=NULL;
	}
                                            
/* opening of a local database..
 */
int open_dbp( dbase * p ) {

#if 0
        HASHINFO priv = { 
		16*1024, 	/* bsize; hash bucked size */ 
		8,		/* ffactor, # keys/bucket */
		3000,		/* nelements, guestimate */
		512*1024,	/* cache size */
		NULL,		/* hash function */
		0 		/* use current host order */
		}; 
#endif

#ifdef BERKELEY_DB_1_OR_2 /* Berkeley DB Version 1  or 2 */
#ifdef DB_VERSION_MAJOR
        DB_INFO       btreeinfo;
        memset(&btreeinfo, 0, sizeof(btreeinfo));
        btreeinfo.bt_compare = ( p->bt_compare_fcn_type == FLAT_STORE_BT_COMP_INT ) ? rdfstore_backend_dbms_compare_int : ( p->bt_compare_fcn_type == FLAT_STORE_BT_COMP_DOUBLE ) ? rdfstore_backend_dbms_compare_double : NULL ;
#else
        BTREEINFO       btreeinfo;
        memset(&btreeinfo, 0, sizeof(btreeinfo));
        btreeinfo.compare = ( p->bt_compare_fcn_type == FLAT_STORE_BT_COMP_INT ) ? rdfstore_backend_dbms_compare_int : ( p->bt_compare_fcn_type == FLAT_STORE_BT_COMP_DOUBLE ) ? rdfstore_backend_dbms_compare_double : NULL ;
#endif
#endif

        umask(0);

	/* XXX Do note that we _have_ a mode variable. We just ignore it.
	 * except for the create flag.
	 *
 	 * XXX we could also pass a &priv=NULL pointer to let the DB's work this
	 * one out..
	 */

#ifdef BERKELEY_DB_1_OR_2 /* Berkeley DB Version 1  or 2 */

#ifdef DB_VERSION_MAJOR
	if (    (db_open(	p->pfile, 
        			DB_BTREE,
				DB_CREATE, /* only create it should be ((ro==0) ? ( DB_CREATE ) : ( DB_RDONLY ) ) */
                                0666, NULL, &btreeinfo, &p->handle )) ||
#if DB_VERSION_MAJOR == 2 && DB_VERSION_MINOR < 6
                ((p->handle->cursor)(p->handle, NULL, &p->cursor))
#else
                ((p->handle->cursor)(p->handle, NULL, &p->cursor, 0))
#endif
                ) {
#else

#if defined(DB_LIBRARY_COMPATIBILITY_API) && DB_VERSION_MAJOR > 2
	if (!(p->handle = (DB *)__db185_open(	p->pfile, 
						p->mode,
                                                0666, DB_BTREE, &btreeinfo ))) {
#else
	if (!(p->handle = (DB *)dbopen(	p->pfile, 
					p->mode,
                                        0666, DB_BTREE, &btreeinfo ))) {
#endif /* DB_LIBRARY_COMPATIBILITY_API */

#endif

#else /* Berkeley DB Version > 2 */
	if (db_create(&p->handle, NULL,0))
		return errno;

	/* set the b-tree comparinson function to the one passed */
	if( p->bt_compare_fcn_type != NULL ) {
		p->handle->set_bt_compare(p->handle, ( p->bt_compare_fcn_type == FLAT_STORE_BT_COMP_INT ) ?
                                                        rdfstore_backend_dbms_compare_int : ( p->bt_compare_fcn_type == FLAT_STORE_BT_COMP_DOUBLE ) ?
                                                                                                rdfstore_backend_dbms_compare_double : NULL );
                        };

	p->handle->set_errfile(p->handle,stderr);
	p->handle->set_errpfx(p->handle,"DBMS BerkelyDB");

	if (    (p->handle->open(	p->handle,
#if DB_VERSION_MAJOR >= 4 && DB_VERSION_MINOR > 0 && DB_VERSION_PATCH >= 17
					NULL,
#endif
                                	p->pfile, 
                                	NULL,
                                	DB_BTREE, 
					DB_CREATE, /* only create it should be ((ro==0) ? ( DB_CREATE ) : ( DB_RDONLY ) ) */
                                	0666 )) ||
                ((p->handle->cursor)(p->handle, NULL, &p->cursor, 0)) ) {
#endif /* Berkeley DB Version > 2 */

		return errno;
		};

#ifndef BERKELEY_DB_1_OR_2 /* Berkeley DB Version > 2 */
/*
        (void)p->handle->set_h_ffactor(p->handle, 1024);
        (void)p->handle->set_h_nelem(p->handle, (u_int32_t)6000);
*/
#endif

	return 0;
        }


dbase * get_dbp (connection *r, dbms_xsmode_t xsmode, int bt_compare_fcn_type, DBT * v2 ) {
        dbase * p;
	char * pfile;
	char name[ 255 ], *n, *m;
	int i;
	int mode = 0;
	tops mops = T_NONE;

	/* Clean up the name */
	bzero(name,sizeof(name));
	for(m = (unsigned char *)(v2->data),n=name,i=0;i<v2->size && i<sizeof(name)-1;i++) 
		if (isalnum((int)(m[i]))) *n++ = m[i];
	*n='\0';

	r->op = allowed_ops_on_dbase(r->address.sin_addr.s_addr, name);
        dbms_log(L_DEBUG,"Permissions for %s/%s - %s",
		name, inet_ntoa(r->address.sin_addr),op2string(r->op));

	switch(xsmode) {
	case DBMS_XSMODE_RDONLY: 
		mops = T_RDONLY;
		mode = O_RDONLY;
		break;
		;;
	case DBMS_XSMODE_RDWR: 
		mops = T_RDWR;
		mode = O_RDWR;
		break;
		;;
	case DBMS_XSMODE_CREAT: 
		mops = T_CREAT;
		mode = O_RDWR | O_CREAT;
		break;
		;;
	case DBMS_XSMODE_DROP: 
		mops = T_DROP;
		mode = O_RDWR | O_CREAT;
		break;
	default:
		dbms_log(L_ERROR,"Impossible XSmode(bug) %d requed on %s",
			xsmode,name);
		return NULL;
		break;
	}

	if (mops > r->op) {
		char * ip = strdup(inet_ntoa(r->address.sin_addr));
                dbms_log(L_ERROR,"Access violation on %s: %s requested %s - but may up to %s",
			name, ip, op2string(mops),op2string(r->op));
		free(ip);
		return NULL;
	};

	/* Max allowed operation */
	r->op = MIN(mops,r->op);
        dbms_log(L_DEBUG,"Permissions for %s/%s - asked %s - granted %s",
		name, inet_ntoa(r->address.sin_addr),op2string(mops),
		op2string(r->op));

#if 0
	/* We always add a RDWR to the open - as it may be the case
	 * that some later connection needs RW. XXX fixme.
	 */
	mode = ( mode & (~ O_RDONLY)) | O_RDWR;
#endif

#ifndef RDFSTORE_PLATFORM_SOLARIS
#ifndef RDFSTORE_PLATFORM_LINUX
	/* Try to get an exclusive lock if possible */
	mode |= O_EXLOCK;
#endif
#endif

        for ( p = first_dbp; p; p=p->nxt)
		if (strcmp(p->name,name)==0) {
			int oldmode = p->mode;

			/* If the database has the b-tree comparinson function we need - simply
			 * return it. If we are forking - and this is not the process
			 * really handling the database - then ignore all this. Otherwise we
			 * fail with an error
			 */
			if ((((p->bt_compare_fcn_type) & bt_compare_fcn_type) == bt_compare_fcn_type )
#ifdef FORKING
				|| (!mum_pid) 
#endif
				) {
				return p;
			} else {
                		dbms_log(L_ERROR, "Wrong b-tree comparinson function %d on %s - it should be %d", 
						bt_compare_fcn_type, p->name, p->bt_compare_fcn_type );
				return NULL;
				};

			/* If the database already has the perm's we need - simply
			 * return it. If we are forking - and this is not the process
			 * really handling the database - then ignore all this
			 */
			if ((((p->mode) & mode) == mode )
#ifdef FORKING
				|| (!mum_pid) 
#endif
			) return p;

			/* we need to (re)open the database with the higher level perm's we
			 * we need this time.. 
			 */
			p->mode = mode;
			if (_dbclose(p) || open_dbp( p )) {
                		dbms_log(L_ERROR,
					"DBase %s could not be be reopened with the right permissions %d",
					p->name,p->mode);
				/* try to reopen the dbase with the old permissions
				 * (for the other connections still active)
				 */
				p->mode = oldmode;

				/* bail out - but not clean up de *p; as other
				 * connections are still using it.
				 */
				if (open_dbp(p)) 
               				 return NULL;
					
				/* give up - and have the DB removed (even for
				 * 	the other connections ! */	
				goto err_and_exit;
			}
			return p;
	}

	if (dbase_counter > HARD_MAX_DBASE) {
                dbms_log(L_ERROR,"Hard max number of dabases hit. (bug?)");
                return NULL;
                };

#ifdef STATIC_BUFF
	if (free_dbase_list)
	{
		p = free_dbase_list;
		free_dbase_list = free_dbase_list->nxt;
	} else {
		if (free_dbase_list_keep < free_dbase_list_max)
			free_dbase_list_keep += 2;
#else
{
#endif
        	p = mymalloc(sizeof(dbase));
	}

	if (p == NULL) {
               	dbms_log(L_ERROR,"No Memory (for another dbase 1)");
        	return NULL;
	};
	bzero(p,sizeof(dbase));
        p->nxt = first_dbp;
        first_dbp = p;
	dbase_counter ++;

#ifndef STATIC_BUFF
	p->name = NULL;
	p->pfile = NULL;
#else
  p->name[0] ='\0';
	p->pfile[0] = '\0';
#endif
	p->num_cls = 0;
	p->close = 0;
	p->mode = mode;
	p->bt_compare_fcn_type = bt_compare_fcn_type;
        p->sname = v2->size;
	p->handle = NULL;

#ifdef FORKING
	p->handled_by = NULL;
#endif

#ifdef STATIC_BUFF
	if ( 1+ v2->size > MAX_STATIC_NAME ) 
#else
	if ((p->name = mymalloc( 1+v2->size ))==NULL) 
#endif
	{
                dbms_log(L_ERROR,"No Memory (for another dbase 2)");
		goto clean_and_exit;
                };

        strcpy(p->name, name);

	if (!(pfile= mkpath(my_dir,p->name)))
		goto clean_and_exit;

#ifdef STATIC_BUFF
	if ( strlen(pfile)+1 > MAX_STATIC_PFILE ) 
#else
   if ((p->pfile = mymalloc(strlen(pfile)+1)) == NULL )
#endif
	{ 
                dbms_log(L_ERROR,"No Memory (for another dbase 3)");
		goto clean_and_exit;
                };
	strcpy(p->pfile,pfile);

	/* Check if the DB exists unless we are on an allowed
	 * create operations level.
	 */
	if (r->op < T_CREAT) {
		struct stat sb;
		int s=stat(p->pfile,&sb);
		if (s==-1) {
			dbms_log(L_ERROR,"DB %s not found\n",p->pfile);
			goto clean_and_exit;
		}
		/* DB exists - we are good. */
	};
		
#ifdef FORKING
	/* if we are the main process, then pass
	 * on the request to a suitable child;
	 * if we are the 'child' then do the
	 * actual work..
	 */
	if (!mum_pid) {
		int mdbs=0,c=0;
		struct child_rec * q, *best;

		/* count # of processes and get the least
		 * loaded one of the lot. Or create a
		 * fresh one. XXXX We could also go for 
		 * a rotational approach, modulo the counter.
		 * that would remove the need to loop, but
		 * spoil the load distribution.
		 */
		if (child_counter < max_processes) {
		  	q=create_new_child();
			/* fork/child or error */
		  	if ((q == NULL) && (errno))
				goto clean_and_exit;
			if (q == NULL)
				return NULL; /* just bail out if we are the child */
		  	best=q;
			}
		else {
			for(c=0,q=children; q; q=q->nxt)
				if ( mdbs == 0 || q->num_dbs < mdbs ) {
					mdbs = q->num_dbs;
					best = q;
					};
			};

		p->handled_by = best;
		p->handled_by->num_dbs ++;

		return p;	
	}; /* if mother */
	/* we are a child... just open normal. 
	 */
#endif
        if (open_dbp( p ) == 0) 
		return p;

err_and_exit:
	dbms_log(L_ERROR,"open_dbp(1) %s(mode %d) (bt_compare %d) failed: %s",p->pfile,p->mode,p->bt_compare_fcn_type, strerror(errno));

clean_and_exit:
	p->close = 1; MX;

	/* repair... and shuffle... */
        first_dbp = p->nxt;
#ifndef STATIC_BUFF
	if (p->pfile) myfree(p->pfile);
	if (p->name) myfree(p->name);
	if (p) myfree(p);
#else
	p->nxt = free_dbase_list;
	free_dbase_list = p;
#endif
	dbase_counter --;
	return NULL;
}

void do_init( connection * r) {
	DBT val;
	u_long proto;
	dbms_xsmode_t xsmode;
	int bt_compare_fcn_type;

        memset(&val, 0, sizeof(val));

	val.data = &proto;
	val.size = sizeof( u_long );

	xsmode = (dbms_xsmode_t)((u_long) ntohl( ((u_long *)(r->v1.data))[1] ));

#ifdef FORKING
	assert(mum_pid==0);
#endif
	if (r->v1.size == 0) {
		reply_log(r,L_ERROR,"No protocol version");
		return;
		};

	proto =((u_long *)(r->v1.data))[0];
	if ( ntohl(proto) != DBMS_PROTO ) {
		reply_log(r,L_ERROR,"Protocol not supported");
		return;
		};

	bt_compare_fcn_type = ((int) ntohl( ((u_long *)(r->v1.data))[2] ));
	if (	( bt_compare_fcn_type != 0 ) &&
		( bt_compare_fcn_type < FLAT_STORE_BT_COMP_INT ) &&
		( bt_compare_fcn_type > FLAT_STORE_BT_COMP_DATE ) ) {
		reply_log(r,L_ERROR,"B-tree sorting function not supported");
		return;
		};

	/* work out wether we have this dbase already open, 
	 * and open it if ness. 
	 */
	r->dbp = get_dbp( r, xsmode, bt_compare_fcn_type, &(r->v2)); /* returns NULL on error or if it is a child */

	if (r->dbp == NULL) {
		if (errno == ENOENT) {
			dbms_log(L_DEBUG,"Closing instantly with a not found");
			dispatch(r, TOKEN_INIT | F_NOTFOUND,&val,NULL);
			return;
			};
#ifdef FORKING
		if (!mum_pid)
#endif
			reply_log(r,L_ERROR,"Open2 database '%s' failed: %s",
				iprt(&(r->v2)),strerror(errno));
		return;
		};

	r->dbp->num_cls ++;
#ifdef FORKING
{
	/* We -also- need to record some xtra things which are lost acrss the connection. */
	u_long extra[4];
	extra[0] = ((u_long *)(r->v1.data))[0]; /* proto */
	extra[1] = ((u_long *)(r->v1.data))[1]; /* mode */
	extra[2] = ((u_long *)(r->v1.data))[2]; /* bt_compare_fcn_type */
	extra[3] = r->address.sin_addr.s_addr;
	r->v1.data = extra;
	r->v1.size = sizeof(extra);
	if (handoff_fd(r->dbp->handled_by, r)) 
		reply_log(r,L_ERROR,"handoff %s : %s",
				r->dbp->name,strerror(errno));
}
#else
	dispatch(r, TOKEN_INIT | F_FOUND,&val,NULL);
#endif
	return;
	}

#ifdef FORKING
void do_pass( connection * mums_r) {  
	/* this is not really a RQ coming in from a child.. bit instead
 	 * a warning that we are about to pass a file descriptor
	 * in the next message. There is no need to actually confirm
	 * anything if we are successfull, we should just be on the 
	 * standby to get the FD, and treat it as a new connection..
	 *
	 * note that the r->fd is _not_ a client fd, but the one to
	 * our mother.
	 */
	connection * r;
	int newfd;
	u_long proto;
	dbms_xsmode_t xsmode;
	DBT val;
	u_long bt_compare_fcn_type;

        memset(&val, 0, sizeof(val));
	assert(mums_r->v1.size = 4*sizeof(u_long));
	mums_r->address.sin_addr.s_addr = ((u_long *)(mums_r->v1.data))[3];

	assert(mum_pid);

	if ((newfd=takeon_fd(mum->clientfd))<0) {
		reply_log(mums_r,L_ERROR,"Take on failed: %s",
			strerror(errno));
		/* give up on the connection to mum ?*/
		mums_r->close = 1; MX;
		return;
		};

	/* try to take this FD on board.. and let it do
	 * whatever error moaning itself.
	 */
	proto =((u_long *)(mums_r->v1.data))[0];
	xsmode = (dbms_xsmode_t)((u_long) htonl(((u_long *)(mums_r->v1.data))[1]));

	dbms_log(L_INFORM,"PASS db='%s' mode %d",iprt(&(mums_r->v2)),xsmode);

	if ((r = handle_new_connection( newfd, C_CLIENT, mums_r->address)) == NULL)
		return;

	/* is this the sort of init data we can handle ? 
	 */
	if ( ntohl(proto) != DBMS_PROTO ) {
		reply_log(r,L_ERROR,"Protocol not supported");
		return;
		};

	bt_compare_fcn_type = ((int) ntohl( ((u_long *)(mums_r->v1.data))[2] ));
	if (	( bt_compare_fcn_type != 0 ) &&
		(	( bt_compare_fcn_type < FLAT_STORE_BT_COMP_INT ) ||
			( bt_compare_fcn_type > FLAT_STORE_BT_COMP_DATE ) ) ) {
		reply_log(r,L_ERROR,"B-tree sorting function not supported");
		return;
		};
	
	r->dbp = get_dbp( r, xsmode, bt_compare_fcn_type, &(mums_r->v2));

	if (r->dbp== NULL) {
		if (errno == ENOENT) {
			dispatch(r, TOKEN_INIT | F_NOTFOUND,&val,NULL);
			r->close = 1; MX;
			return;
			};
		reply_log(r,L_ERROR,"Open database %s failed: %s",
				iprt(&(mums_r->v2)),strerror(errno));
		return;
		};

	r->dbp->num_cls ++;
	r->dbp->handled_by = NULL;

	/* let the _real_ client know all is well. */
	proto=htonl(DBMS_PROTO);
	val.data= &proto;
	val.size = sizeof( u_long );

	dispatch(r, TOKEN_INIT | F_FOUND,&val,NULL);

	dbms_log(L_INFORM,"PASS send init repy on %d to client",r->clientfd);
	return;
	};
#endif

void do_fetch( connection * r) {
	DBT key, val;
	int err;

	memset(&key, 0, sizeof(key));
        memset(&val, 0, sizeof(val));

	if (r->type != C_CLIENT) {
		dbms_log(L_ERROR,"Command received from non-client command FETCH");
		return;
		};

	key.data = r->v1.data;
	key.size = r->v1.size;

#ifdef DB_VERSION_MAJOR
	err=(r->dbp->handle->get)(r->dbp->handle, NULL, &key, &val, 0);
#else
	err=(r->dbp->handle->get)(r->dbp->handle, &key, &val, 0);
#endif

	if (err == 0) 
		dispatch(r,TOKEN_FETCH | F_FOUND,&key,&val);
	else 
#ifdef DB_VERSION_MAJOR
	if (err == DB_NOTFOUND)
#else
	if (err == 1)
#endif
		dispatch(r,TOKEN_FETCH | F_NOTFOUND,NULL,NULL);
	else {
		errno=err;
		reply_log(r,L_ERROR,"fetch on %s failed: %s (klen=%d, vlen=%d, err=%d(1))",r->dbp->name,strerror(errno), key.size,val.size,err);
		}
	}

void do_inc ( connection * r) {
	DBT key, val;
	int err;
	unsigned long l;
	char * p;
	char outbuf[256]; /* surely shorter than UMAX_LONG */

	memset(&key, 0, sizeof(key));
        memset(&val, 0, sizeof(val));

	if (r->type != C_CLIENT) {
		dbms_log(L_ERROR,"Command received from non-client command FETCH");
		return;
		};

	/* all we get from the client is the key, and
	 * all we return is the (increased) value
	 */
	key.data = r->v1.data;
	key.size = r->v1.size;

#ifdef DB_VERSION_MAJOR
	err=(r->dbp->handle->get)( r->dbp->handle, NULL, &key, &val, 0);
#else
	err=(r->dbp->handle->get)( r->dbp->handle, &key, &val,0);
#endif

#ifdef DB_VERSION_MAJOR
	if ((err == DB_NOTFOUND) || (val.size == 0)) {
#else
	if ((err == 1) || (val.size == 0)) {
#endif
                dispatch(r,TOKEN_INC | F_NOTFOUND,NULL,NULL);
		return;
		}
	else
	if (err) {
#ifdef DB_VERSION_MAJOR
		errno=err;
#endif
		reply_log(r,L_ERROR,"inc on %s failed: %s",r->dbp->name,
			strerror(errno) );
		return;
		};

	/* XXX bit of a hack; but perl seems to deal with
         *     all storage as ascii strings in some un-
         *     specified locale.
         */
	bzero(outbuf,256);
	strncpy(outbuf,val.data,MIN( val.size, 255 ));
	l=strtoul( outbuf, &p, 10 );

	if (*p || l == ULONG_MAX || errno == ERANGE) {
		reply_log(r,L_ERROR,"inc on %s failed: %s",r->dbp->name,
			"Not the (entire) string is an unsigned integer"
			);
		return;
		};
	/* this is where it all happens... */
	l++;

	bzero(outbuf,256);
	snprintf(outbuf,255,"%lu",l);
	val.data = & outbuf;
	val.size = strlen(outbuf);
	
	/* and put it back.. 
	 *
 	 *  	Put routines return -1 on error (setting errno),  0
         *	on success, and 1 if the R_NOOVERWRITE flag was set
         *    	and the key already exists in the file.
	 */
#ifdef DB_VERSION_MAJOR
        err=(r->dbp->handle->put)( r->dbp->handle, NULL, &key, &val, 0);
#else
        err=(r->dbp->handle->put)( r->dbp->handle, &key, &val,0);
#endif

	/* just send it back as an ascii string
	 */
#ifdef DB_VERSION_MAJOR
	if (( err == 0 ) || ( err < 0 ))
#else
	if (( err == 0 ) || ( err == 1 ))
#endif
                dispatch(r,TOKEN_INC | F_FOUND,NULL,&val);
        else {
#ifdef DB_VERSION_MAJOR
		errno=err;
#endif
		reply_log(r,L_ERROR,"inc store on %s failed: %s",
			r->dbp->name,strerror(errno));
		};
	};

void do_dec ( connection * r) {
	DBT key, val;
	int err;
	unsigned long l;
	char * p;
	char outbuf[256]; /* surely shorter than UMAX_LONG */

	memset(&key, 0, sizeof(key));
        memset(&val, 0, sizeof(val));

	if (r->type != C_CLIENT) {
		dbms_log(L_ERROR,"Command received from non-client command FETCH");
		return;
		};

	/* all we get from the client is the key, and
	 * all we return is the (decreased) value
	 */
	key.data = r->v1.data;
	key.size = r->v1.size;

#ifdef DB_VERSION_MAJOR
        err=(r->dbp->handle->get)( r->dbp->handle, NULL, &key, &val, 0);
#else
        err=(r->dbp->handle->get)( r->dbp->handle, &key, &val,0);
#endif

#ifdef DB_VERSION_MAJOR
        if ((err == DB_NOTFOUND) || (val.size == 0)) {
#else
        if ((err == 1) || (val.size == 0)) {
#endif
                dispatch(r,TOKEN_DEC | F_NOTFOUND,NULL,NULL);
                return;
                }
        else
        if (err) {
#ifdef DB_VERSION_MAJOR
                errno=err;
#endif
                reply_log(r,L_ERROR,"dec on %s failed: %s",r->dbp->name,
                        strerror(errno) );
                return;
                };

	/* XXX bit of a hack; but perl seems to deal with
         *     all storage as ascii strings in some un-
         *     specified locale.
         */
	bzero(outbuf,256);
	strncpy(outbuf,val.data,MIN( val.size, 255 ));
	l=strtoul( outbuf, &p, 10 );

	if (*p || l == ULONG_MAX || l == 0 || errno == ERANGE) {
		reply_log(r,L_ERROR,"dec on %s failed: %s",r->dbp->name,
			"Not the (entire) string is an unsigned integer"
			);
		return;
		};
	/* this is where it all happens... */
	l--;

	bzero(outbuf,256);
	snprintf(outbuf,255,"%lu",l);
	val.data = & outbuf;
	val.size = strlen(outbuf);
	
	/* and put it back.. 
	 *
 	 *  	Put routines return -1 on error (setting errno),  0
         *	on success, and 1 if the R_NOOVERWRITE flag was set
         *    	and the key already exists in the file.
	 */
#ifdef DB_VERSION_MAJOR
        err=(r->dbp->handle->put)( r->dbp->handle, NULL, &key, &val, 0);
#else
        err=(r->dbp->handle->put)( r->dbp->handle, &key, &val,0);
#endif

        /* just send it back as an ascii string
         */
#ifdef DB_VERSION_MAJOR
        if (( err == 0 ) || ( err < 0 ))
#else
        if (( err == 0 ) || ( err == 1 ))
#endif
                dispatch(r,TOKEN_DEC | F_FOUND,NULL,&val);
        else
#ifdef DB_VERSION_MAJOR
		{
                errno=err;
                reply_log(r,L_ERROR,"dec store on %s failed: %s",
                        r->dbp->name,strerror(errno));
		};
#else
                reply_log(r,L_ERROR,"dec store on %s failed: %s",
                        r->dbp->name,strerror(errno));
#endif
	};

/* atomic packed increment */
void do_packinc ( connection * r) {
	DBT key, val;
	int err;
	dbms_counter l=0;
	unsigned char outbuf[256];

	memset(&key, 0, sizeof(key));
        memset(&val, 0, sizeof(val));

	if (r->type != C_CLIENT) {
		dbms_log(L_ERROR,"Command received from non-client command FETCH");
		return;
		};

	/* all we get from the client is the key, and
	 * all we return is the (increased) value
	 */
	key.data = r->v1.data;
	key.size = r->v1.size;

#ifdef DB_VERSION_MAJOR
        err=(r->dbp->handle->get)( r->dbp->handle, NULL, &key, &val, 0);
#else
        err=(r->dbp->handle->get)( r->dbp->handle, &key, &val,0);
#endif

#ifdef DB_VERSION_MAJOR
        if ((err == DB_NOTFOUND) || (val.size == 0)) {
#else
        if ((err == 1) || (val.size == 0)) {
#endif
                dispatch(r,TOKEN_PACKINC | F_NOTFOUND,NULL,NULL);
                return;
                }
        else
        if (err) {
#ifdef DB_VERSION_MAJOR
                errno=err;
#endif
                reply_log(r,L_ERROR,"packinc on %s failed: %s",r->dbp->name,
                        strerror(errno) );
                return;
                };

	l = ntohl(*(dbms_counter *)val.data);

	/* this is where it all happens... */
	l++;

        val.data = outbuf;
        val.size = sizeof(dbms_counter);

	*(dbms_counter *)val.data = htonl(l);

	/* and put it back.. 
	 *
 	 *  	Put routines return -1 on error (setting errno),  0
         *	on success, and 1 if the R_NOOVERWRITE flag was set
         *    	and the key already exists in the file.
	 */
#ifdef DB_VERSION_MAJOR
        err=(r->dbp->handle->put)( r->dbp->handle, NULL, &key, &val, 0);
#else
        err=(r->dbp->handle->put)( r->dbp->handle, &key, &val,0);
#endif

        /* just send it back as an ascii string
         */
#ifdef DB_VERSION_MAJOR
        if (( err == 0 ) || ( err < 0 ))
#else
        if (( err == 0 ) || ( err == 1 ))
#endif
                dispatch(r,TOKEN_PACKINC | F_FOUND,NULL,&val);
        else
#ifdef DB_VERSION_MAJOR
		{
                errno=err;
                reply_log(r,L_ERROR,"packinc store on %s failed: %s",
                        r->dbp->name,strerror(errno));
		};
#else
                reply_log(r,L_ERROR,"packinc store on %s failed: %s",
                        r->dbp->name,strerror(errno));
#endif
	};

/* atomic packed decrement */
void do_packdec ( connection * r) {
	DBT key, val;
	int err;
	dbms_counter l=0;
	unsigned char outbuf[256]; /* surely shorter than UMAX_LONG */

	memset(&key, 0, sizeof(key));
        memset(&val, 0, sizeof(val));

	if (r->type != C_CLIENT) {
		dbms_log(L_ERROR,"Command received from non-client command FETCH");
		return;
		};

	/* all we get from the client is the key, and
	 * all we return is the (increased) value
	 */
	key.data = r->v1.data;
	key.size = r->v1.size;

#ifdef DB_VERSION_MAJOR
        err=(r->dbp->handle->get)( r->dbp->handle, NULL, &key, &val, 0);
#else
        err=(r->dbp->handle->get)( r->dbp->handle, &key, &val,0);
#endif

#ifdef DB_VERSION_MAJOR
        if ((err == DB_NOTFOUND) || (val.size == 0)) {
#else
        if ((err == 1) || (val.size == 0)) {
#endif
                dispatch(r,TOKEN_PACKDEC | F_NOTFOUND,NULL,NULL);
                return;
                }
        else
        if (err) {
#ifdef DB_VERSION_MAJOR
                errno=err;
#endif
                reply_log(r,L_ERROR,"packdec on %s failed: %s",r->dbp->name,
                        strerror(errno) );
                return;
                };

	l = ntohl(*(dbms_counter *)val.data);
	/* this is where it all happens... */
	l--;


        val.data = outbuf;
        val.size = sizeof(uint32_t)+1;

	*(dbms_counter *)val.data = htonl(l);

	/* and put it back.. 
	 *
 	 *  	Put routines return -1 on error (setting errno),  0
         *	on success, and 1 if the R_NOOVERWRITE flag was set
         *    	and the key already exists in the file.
	 */
#ifdef DB_VERSION_MAJOR
        err=(r->dbp->handle->put)( r->dbp->handle, NULL, &key, &val, 0);
#else
        err=(r->dbp->handle->put)( r->dbp->handle, &key, &val,0);
#endif

        /* just send it back as an ascii string
         */
#ifdef DB_VERSION_MAJOR
        if (( err == 0 ) || ( err < 0 ))
#else
        if (( err == 0 ) || ( err == 1 ))
#endif
                dispatch(r,TOKEN_PACKDEC | F_FOUND,NULL,&val);
        else
#ifdef DB_VERSION_MAJOR
		{
                errno=err;
                reply_log(r,L_ERROR,"packdec store on %s failed: %s",
                        r->dbp->name,strerror(errno));
		};
#else
                reply_log(r,L_ERROR,"packdec store on %s failed: %s",
                        r->dbp->name,strerror(errno));
#endif
	};

void do_exists( connection * r) {
        DBT key, val;
        int err;

	memset(&key, 0, sizeof(key));
        memset(&val, 0, sizeof(val));

	if (r->type != C_CLIENT) {
		dbms_log(L_ERROR,"Command received from non-client command EXISTS");
		return;
		};

        key.data = r->v1.data;
        key.size = r->v1.size;

#ifdef DB_VERSION_MAJOR
        err=(r->dbp->handle->get)( r->dbp->handle, NULL, &key, &val, 0);
#else
        err=(r->dbp->handle->get)( r->dbp->handle, &key, &val,0);
#endif

        if ( err == 0 )
		dispatch(r,TOKEN_EXISTS | F_FOUND,NULL,NULL);
	else
#ifdef DB_VERSION_MAJOR
        if (err == DB_NOTFOUND)
                dispatch(r,TOKEN_EXISTS | F_NOTFOUND,NULL,NULL);
        else {
                errno=err;
                reply_log(r,L_ERROR,"exists on %s failed: %s",r->dbp->name,strerror(errno));
                }
#else
        if (err == 1)
                dispatch(r,TOKEN_EXISTS | F_NOTFOUND,NULL,NULL);
        else
                reply_log(r,L_ERROR,"exists on %s failed: %s",r->dbp->name,strerror(errno));
#endif
        };
   	
void do_delete( connection * r) {
        DBT key;
        int err;

	memset(&key, 0, sizeof(key));

	if (r->type != C_CLIENT) {
		dbms_log(L_ERROR,"Command received from non-client command DELETE");
		return;
		};

        key.data = r->v1.data;
        key.size = r->v1.size;

#ifdef DB_VERSION_MAJOR
        err=(r->dbp->handle->del)( r->dbp->handle, NULL, &key, 0);
#else
        err=(r->dbp->handle->del)( r->dbp->handle, &key,0);
#endif

        if ( err == 0 )
                dispatch(r,TOKEN_DELETE | F_FOUND,NULL,NULL);
        else
#ifdef DB_VERSION_MAJOR
        if (err == DB_NOTFOUND)
                dispatch(r,TOKEN_DELETE | F_NOTFOUND,NULL,NULL);
        else {
                errno=err;
		reply_log(r,L_ERROR,"delete on %s failed: %s",r->dbp->name,strerror(errno));
                }
#else
        if ( err == 1 )
                dispatch(r,TOKEN_DELETE | F_NOTFOUND,NULL,NULL);
        else
		reply_log(r,L_ERROR,"delete on %s failed: %s",r->dbp->name,strerror(errno));
#endif
        };        

void do_store( connection * r) {
        DBT key, val;
        int err;

	memset(&key, 0, sizeof(key));
	memset(&val, 0, sizeof(val));

	if (r->type != C_CLIENT) {
		dbms_log(L_ERROR,"Command received from non-client command STORE");
		return;
		};

        key.data = r->v1.data;
        key.size = r->v1.size;

        val.data = r->v2.data;
        val.size = r->v2.size;

#ifdef DB_VERSION_MAJOR
        err=(r->dbp->handle->put)( r->dbp->handle, NULL, &key, &val, 0);
#else
        err=(r->dbp->handle->put)( r->dbp->handle, &key, &val,0);
#endif

	if ( err == 0 )
                dispatch(r,TOKEN_STORE | F_FOUND,NULL,NULL); /* it was F_NOTFOUND wich was returning always 1 even if not there (F_NOTFOUND) */
        else
#ifdef DB_VERSION_MAJOR
        if ( err < 0 )
                dispatch(r,TOKEN_STORE | F_FOUND,NULL,NULL);
        else {
		errno=err;
		reply_log(r,L_ERROR,"store on %s failed: %s",r->dbp->name,strerror(errno));
		};
#else
        if ( err == 1 )
                dispatch(r,TOKEN_STORE | F_NOTFOUND,NULL,NULL); /* it was F_FOUND which was returning always 0 even if already there (F_FOUND) see above dispatch */
        else
		reply_log(r,L_ERROR,"store on %s failed: %s",r->dbp->name,strerror(errno));
#endif

        };
      
void do_sync( connection * r) {
        int err=0;

	if (r->type != C_CLIENT) {
		dbms_log(L_ERROR,"Command received from non-client command SYNC");
		return;
		};

        err=(r->dbp->handle->sync)( r->dbp->handle,0);

        if (err != 0 ) {
		reply_log(r,L_ERROR,"sync on %s failed: %s",r->dbp->name,strerror(errno));
                }
	else {
        	dispatch(r,TOKEN_SYNC,NULL,NULL);
		};
        };

void do_clear( connection * r) {
	int err;

	if (r->type != C_CLIENT) {
		dbms_log(L_ERROR,"Command received from non-client command CLEAR");
		return;
		};

	/* close the database, remove the file, and repoen... ? */	
	if ( (_dbclose(r->dbp)) ||
	     ((err=unlink(r->dbp->pfile)) !=0) ||
	     ((err=open_dbp( r->dbp )) != 0) ) 
	{
		reply_log(r,L_ERROR,"clear on %s failed: %s",r->dbp->name,strerror(errno));
                return;
                };

	trace("%6s %12s %s","SYNC",r->dbp->name,eptr(err));
	dispatch(r, TOKEN_CLEAR,NULL, NULL);
	};
                	
void do_list( connection * r) {
#if 0
        DBT key, val;
        int err;

	memset(&key, 0, sizeof(key));
        memset(&val, 0, sizeof(val));

	/* now the issue here is... do we want to do
	 * the entire array; as one HUGE malloc ?
	 */

	if (r->type != C_CLIENT) {
		dbms_log(L_ERROR,"Command received from non-client command LIST");
		return;
		};

	/* keep track of whom used the cursor last...*/
	r->dbp->lastfd = r->clientfd;

	f = R_FIRST;
        for(;;) {
        	err=(r->dbp->handle->seq)( r->dbp->handle, &key, &val,f);
		if ( err ) last;
		f = F_NEXT;

		};

        if ( err < 0 )
		reply_log(r,L_ERROR,"first on %s failed: %s",
			r->dbp->name,strerror(errno));
	else
	if ( err == 1 )
                dispatch(r,TOKEN_FIRSTKEY | F_NOTFOUND,NULL,NULL);
        else
                dispatch(r,TOKEN_LIST | F_FOUND,&key,&val);
#endif
	reply_log(r,L_ERROR,"Not implemented.. yet");
	}

void do_ping( connection * r) {
        dispatch(r,TOKEN_PING | F_FOUND,NULL,NULL);
	}

void do_drop( connection * r) {
	char dbpath[ 1024 ];
	dbms_log(L_INFORM,"Drop cmd");

	/* Construct name  - add .db where/if needed ?? */
	/* snprintf(dbpath,sizeof(dbpath),"%s.db",r->dbp->pfile); */
	snprintf(dbpath,sizeof(dbpath),"%s",r->dbp->pfile);

	/* or r->dbp->close = 2; */
	zap_dbs(r->dbp); 
	
	if (unlink(dbpath)) 
		reply_log(r,L_ERROR,
			"DB file %s could not be deleted: %s",
                        dbpath,strerror(errno));
	else
        	dispatch(r,TOKEN_DROP| F_FOUND,NULL,NULL);
}

void do_close( connection * r) {

	if (r->type != C_CLIENT) {
		dbms_log(L_ERROR,"Command received from non-client command CLOSE");
		return;
		};

        dispatch(r,TOKEN_CLOSE,NULL,NULL);
	r->close = 1; MX;
	}

/* Combined from function; from first record when flag==R_FIRST or DB_FIRST
 * or from the current cursor if flag=R_CURSOR or DB_SET_RANGE. If
 * no cursos is yet set; the latter two default to an R_FIRST or DB_FIRST.
 */
static
void _from( connection * r, DBT *key, DBT *val, int flag) {
        int err;

	if (r->type != C_CLIENT) {
		dbms_log(L_ERROR,"Command received from non-client command FIRST/FROM");
		return;
		};

	/* keep track of whom used the cursor last...*/
	r->dbp->lastfd = r->clientfd;

#ifdef DB_VERSION_MAJOR
        err=(r->dbp->cursor->c_get)( r->dbp->cursor, key, val, flag);
#else 
      	err=(r->dbp->handle->seq)( r->dbp->handle, key, val,flag);
#endif

#if DB_VERSION_MAJOR >= 2
        if (err == DB_NOTFOUND)
                dispatch(r,( (flag==DB_FIRST) ? TOKEN_FIRSTKEY : TOKEN_FROM ) | F_NOTFOUND,NULL,NULL);
        else
        if ( err == 0 )
                dispatch(r,( (flag==DB_FIRST) ? TOKEN_FIRSTKEY : TOKEN_FROM ) | F_FOUND,key,val);
        else {
                errno=err;
		reply_log(r,L_ERROR,"first on %s failed: %s",r->dbp->name,strerror(errno));
                }
#else
	if ( err == 1 )
                dispatch(r,( (flag==R_FIRST) ? TOKEN_FIRSTKEY : TOKEN_FROM ) | F_NOTFOUND,NULL,NULL);
        else
        if ( err == 0 )
                dispatch(r,( (flag==R_FIRST) ? TOKEN_FIRSTKEY : TOKEN_FROM ) | F_FOUND,key,val);
        else
		reply_log(r,L_ERROR,"first on %s failed: %s",r->dbp->name,strerror(errno));
#endif
};

void do_first(connection * r) {
        DBT key, val;
	memset(&key, 0, sizeof(key));
        memset(&val, 0, sizeof(val));

#if DB_VERSION_MAJOR >= 2     
	_from(r,&key,&val,DB_FIRST);
#else
	_from(r,&key,&val,R_FIRST);
#endif
}

void do_from(connection *r) {
        DBT key, val;
	memset(&key, 0, sizeof(key));
        memset(&val, 0, sizeof(val));

	key.data = r->v1.data; /* copy the requested closest key */
	key.size = r->v1.size;

#if DB_VERSION_MAJOR >= 2     
	_from(r,&key,&val,DB_SET_RANGE);
#else
	_from(r,&key,&val,R_CURSOR);
#endif
};


void do_next( connection * r) {
        DBT key, val;
        int err;

	memset(&key, 0, sizeof(key));
        memset(&val, 0, sizeof(val));

	if (r->type != C_CLIENT) {
		dbms_log(L_ERROR,"Command received from non-client command NEXT");
		return;
		};

	/* We need to set the cursor first, if we where 
	 * not the last using it. 
	 */
	if ( r->dbp->lastfd != r->clientfd ) {
		r->dbp->lastfd = r->clientfd;
        	key.data = r->v1.data; /* copy the previous key if any */
        	key.size = r->v1.size;

#if DB_VERSION_MAJOR >= 2     
                err=(r->dbp->cursor->c_get)(r->dbp->cursor, &key, &val, DB_NEXT);
#else
        	err=(r->dbp->handle->seq)( r->dbp->handle, &key, &val, R_NEXT);
#endif

#ifdef DB_VERSION_MAJOR
		if ( (err != 0) && (err != DB_NOTFOUND) ) {
                	reply_log(r,L_ERROR,"Internal DB Error %s",r->dbp->name);
			return;
			};
#else
		if (err<0 && errno ==0)
			dbms_log(L_WARN,"seq-cursor We have the impossible err=%d and %d",
				err,errno);

		if ((err != 0) && (err != 1) && (errno != 0) ) {
                	reply_log(r,L_ERROR,"Internal DB Error %s",r->dbp->name);
			return;
			};
#endif

		/* BUG: we could detect the fact that the previous key
	 	 *	the callee was aware of, has been zapped. For
	 	 *	now we note that, if the key is not there, we
	 	 *	have received the next greater key. Which we
		 * 	thus return ?! This is an issue.
		 */	
		} 
	else 
		err = 0;

        if (err == 0)
#if DB_VERSION_MAJOR >= 2     
                err=(r->dbp->cursor->c_get)(r->dbp->cursor, &key, &val, DB_NEXT);
#else 
		err=(r->dbp->handle->seq)( r->dbp->handle, &key, &val, R_NEXT);
#endif

	trace("%6s %12s %20s: %s %s","NEXT",
		r->dbp->name, iprt(&key), 
		iprt( err==0 ? &val : NULL ),eptr(err));

#ifdef DB_VERSION_MAJOR
        if ( ( err == DB_NOTFOUND ) || ( err > 0 ) )
		dispatch(r,TOKEN_NEXTKEY | F_NOTFOUND,NULL,NULL);
	else
#else
        if (( err == 1 ) || (( err <0 ) && (errno == 0)) )
		dispatch(r,TOKEN_NEXTKEY | F_NOTFOUND,NULL,NULL);
	else
#endif
	if ( err == 0 )
        	dispatch(r,TOKEN_NEXTKEY | F_FOUND,&key,&val);
        else {
#ifdef DB_VERSION_MAJOR
		errno=err;
#endif
		reply_log(r,L_ERROR,"next on %s failed: %s",r->dbp->name,strerror(errno));
		};
        };

struct command_req cmd_table[ TOKEN_MAX ];
#define IT(i,s,f,o) { cmd_table[i].cnt = 0; cmd_table[i].cmd = i; cmd_table[i].info = s; cmd_table[i].handler = f; cmd_table[i].op = o; }
void init_cmd_table( void )
{
	int i;
	for(i=0;i<TOKEN_MAX;i++) 
		IT( i, "VOID",NULL, T_NONE );

	IT( TOKEN_INIT,		"INIT",&do_init,	T_ERR);	/* chicken/egg - we do not know the error yet */
	IT( TOKEN_FETCH,	"FTCH",&do_fetch,	T_RDONLY);
	IT( TOKEN_STORE,	"STRE",&do_store,	T_RDWR);
	IT( TOKEN_DELETE,	"DELE",&do_delete,	T_RDWR);
	IT( TOKEN_CLOSE,	"CLSE",&do_close,	T_NONE);
	IT( TOKEN_NEXTKEY,	"NEXT",&do_next,	T_RDONLY);
	IT( TOKEN_FIRSTKEY,	"FRST",&do_first,	T_RDONLY);
	IT( TOKEN_EXISTS,	"EXST",&do_exists,	T_RDONLY);
	IT( TOKEN_SYNC,		"SYNC",&do_sync,	T_RDWR);
	IT( TOKEN_CLEAR,	"CLRS",&do_clear,	T_CREAT);
	IT( TOKEN_PING,		"PING",&do_ping,	T_NONE);
	IT( TOKEN_DROP,		"DROP",&do_drop,	T_DROP);
	IT( TOKEN_INC,		"INCR",&do_inc,		T_RDWR);
	IT( TOKEN_DEC,		"DECR",&do_dec,		T_RDWR);
	IT( TOKEN_PACKINC,	"PINC",&do_packinc,	T_RDWR);
	IT( TOKEN_PACKDEC,	"PDEC",&do_packdec,	T_RDWR);
	IT( TOKEN_LIST,		"LIST",&do_list,	T_RDONLY);
	IT( TOKEN_FROM,		"FROM",&do_from,	T_RDONLY);
#ifdef FORKING
	IT( TOKEN_FDPASS,"PASS",&do_pass,		T_ERR);
#endif
}

void parse_request( connection * r) {
	register int i = r->cmd.token;

	if ( i>=0 && i<= TOKEN_MAX && cmd_table[i].handler) {
		if (cmd_table[i].op <= r->op) {
			cmd_table[i].cnt++;
			(cmd_table[i].handler)(r);
		} else {
			char * ip = strdup(inet_ntoa(r->address.sin_addr));
			reply_log(r,L_ERROR,"Access violation for %s on %s (required is %s but IP is limited to %s)",
				ip,cmd_table[i].info,
				op2string(cmd_table[i].op),op2string(r->op));
			free(ip);
			r->close = 1; MX;
		}
		return;
	}

	reply_log(r,L_ERROR,"Unkown command token %d",i);
	r->close = 1; MX;
	return;
}

/* misc subroutines (copied from ../../backend_bdb_store.c - should be merged) */

/*
 * The following compare function are used for btree(s) for basic
 * XML-Schema data types xsd:integer, xsd:double (and will xsd:date)
 *
 * They return:
 *      < 0 if a < b
 *      = 0 if a = b
 *      > 0 if a > b
 */
#ifdef BERKELEY_DB_1_OR_2
static int rdfstore_backend_dbms_compare_int(
        const DBT *a,
        const DBT *b ) {
#else
static int rdfstore_backend_dbms_compare_int(
        DB *file,
        const DBT *a,
        const DBT *b ) {
#endif
        long ai, bi;

        memcpy(&ai, a->data, sizeof(long));
        memcpy(&bi, b->data, sizeof(long));

        return (ai - bi);
        };

#ifdef BERKELEY_DB_1_OR_2
static int rdfstore_backend_dbms_compare_double(
        const DBT *a,
        const DBT *b ) {
#else
static int rdfstore_backend_dbms_compare_double(
        DB *file,
        const DBT *a,
        const DBT *b ) {
#endif
        double ad,bd;

        memcpy(&ad, a->data, sizeof(double));
        memcpy(&bd, b->data, sizeof(double));

        if (  ad <  bd ) {
                return -1;
        } else if (  ad  >  bd) {
                return 1;
                };

        return 0;
        };
