#define BLOCK Perl_BLOCK

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "notesdatabase.h"

MODULE = Notes::Database   PACKAGE = Notes::Session

PROTOTYPES: DISABLE

void
get_database( s, ln_server = "", ln_db_path, ln_network_port = NULL )
      LN_Session * s;
      char *       ln_db_path;
      char *       ln_server;
      char *       ln_network_port;
   PREINIT:
      d_LN_XSVARS;
      DBHANDLE      ln_db_handle;
      char          ln_db_path_canonical[ MAXPATH ];
      STATUS        ln_rc;
   ALIAS:
      get_database  = 0
      open_database = 0
      database      = 0
   PPCODE:
      ln_rc = OSPathNetConstruct(
                        ln_network_port,
                        ln_server,
                        ln_db_path,
                        ln_db_path_canonical
      					);
      if ( LN_IS_NOT_OK(s) )
      {
		  XSRETURN_NOT_OK;
	  }
      ln_rc = NSFDbOpen(
                    ln_db_path_canonical,
                    &ln_db_handle
      				);
      LN_SET_IVX(s, ln_rc);
      if ( LN_IS_NOT_OK(s) )
      {
		  XSRETURN_NOT_OK;
	  }

      LN_PUSH_NEW_OBJ( "Notes::Database", s );
      //printf("CREATED DBHANDLE: %ld\n", (long)ln_db_handle);
      LN_INIT_OBJ_STRUCT(NOTESDATABASE, ln_obj);
      LN_SET_DB_HANDLE(NOTESDATABASE, ln_obj, ln_db_handle);
      //printf("STORED DBHANDLE: %ld\n", (long)LN_DB_HANDLE(NOTESDATABASE,ln_obj));
      LN_SET_OK      ( ln_obj );
      XSRETURN       ( 1 );


void
create_database( s, ln_server = "", ln_db_path, bForceCreation = FALSE )
      LN_Session * s;
      char       * ln_db_path;
      char       * ln_server;
      BOOL         bForceCreation;
   PREINIT:
      d_LN_XSVARS;
      DBHANDLE      ln_db_handle;
      char          ln_db_path_canonical[ MAXPATH ];
      STATUS        ln_rc;
   ALIAS:
      createdatabase  = 0
   PPCODE:
      if ( LN_IS_NOT_OK(s) )
	  {
		  DEBUG(("Notes::Session object was not OK at line %d", __LINE__));
	      XSRETURN_NOT_OK;
	  }
	  ln_rc = OSPathNetConstruct(
	                NULL,
	                ln_server,
	                ln_db_path,
	                ln_db_path_canonical
	  				);
	  if (ln_rc != NOERROR)
	  {
		  DEBUG(("Notes::Database object returning error %d at line %d", ln_rc, __LINE__));
	  	  XSRETURN_NOT_OK;
  	  }
      if (ln_rc = NSFDbCreate (ln_db_path_canonical, DBCLASS_NOTEFILE, bForceCreation))
	  {
		  DEBUG(("Notes::Database object returning error %d at line %d", ln_rc, __LINE__));
		  LN_SET_IVX(s, ln_rc);
	      XSRETURN_NOT_OK;
	  }
	  if (ln_rc = NSFDbOpen(ln_db_path_canonical, &ln_db_handle))
	  {
		  DEBUG(("Notes::Database object returning error %d at line %d", ln_rc, __LINE__));
		  LN_SET_IVX(s, ln_rc);
	      XSRETURN_UNDEF;
	  }
	  LN_SET_IVX     ( s, ln_rc);
      LN_PUSH_NEW_OBJ( "Notes::Database", s );
      //printf("CREATED DBHANDLE: %ld\n", (long)ln_db_handle);
	  LN_INIT_OBJ_STRUCT(NOTESDATABASE, ln_obj);
	  LN_SET_DB_HANDLE(NOTESDATABASE, ln_obj, ln_db_handle);
      //printf("STORED DBHANDLE: %ld\n", (long)LN_DB_HANDLE(NOTESDATABASE,ln_obj));
      LN_SET_OK      ( ln_obj );
      XSRETURN       ( 1 );


MODULE = Notes::Database		PACKAGE = Notes::Database


void
create_copy( db, ln_server = "", ln_db_path )
      LN_Database * db;
      char        * ln_db_path;
      char        * ln_server;
   PREINIT:
      d_LN_XSVARS;
      DBHANDLE      ln_dst_handle;
      char          ln_src_db_path[ MAXPATH ];
      char 			ln_dst_can_server[ MAXUSERNAME ];
      char          ln_db_path_canonical[ MAXPATH ];
      STATUS        ln_rc;
   ALIAS:
      createcopy  = 0
      createfromtemplate = 1
      create_from_template = 1
      createreplica = 2
      create_replica = 2
   PPCODE:
      if ( LN_IS_NOT_OK(db) )
	  {
		  DEBUG(("Notes::Database object was not OK at line %d", __LINE__));
	      XSRETURN_NOT_OK;
	  }
	  ln_rc = DNCanonicalize( 0L, NULL, ln_server, (char FAR*)ln_dst_can_server,
     	    						MAXUSERNAME, NULL);
	  ln_rc = OSPathNetConstruct(
	                NULL,
	                ln_dst_can_server,
	                ln_db_path,
	                ln_db_path_canonical
	  				);
	  if (ln_rc != NOERROR)
	  {
		  DEBUG(("Notes::Database object returning error %d at line %d", ln_rc, __LINE__));
	  	  XSRETURN_NOT_OK;
  	  }

	  ln_rc = NSFDbPathGet( LN_DB_HANDLE(NOTESDATABASE,db), NULL, ln_src_db_path );
	  if (ln_rc != NOERROR)
	  {
		  DEBUG(("Notes::Database object returning error %d at line %d", ln_rc, __LINE__));
	  	  XSRETURN_NOT_OK;
  	  }

	  LN_SET_IVX(db, ln_rc);
	  if ( LN_IS_OK(db) )
      {
	  	  switch( ix )
	      {
              case   0: ln_rc = NSFDbCreateAndCopy(ln_src_db_path, ln_db_path_canonical, NOTE_CLASS_ALL, 0, 0, &ln_dst_handle);
                        break;
              case   1: ln_rc = NSFDbCreateAndCopy(ln_src_db_path, ln_db_path_canonical, NOTE_CLASS_ALLNONDATA, 0, 0, &ln_dst_handle);
	                    break;
	          case   2: ln_rc = NSFDbCreateAndCopy(ln_src_db_path, ln_db_path_canonical, NOTE_CLASS_ALL, 0, DBCOPY_REPLICA, &ln_dst_handle);
	                    break;
	          default:  XSRETURN_NOT_OK;
	                    break;
	      }
      }
      else
      {
	      XSRETURN_NOT_OK;
	  }
      LN_SET_IVX( db, ln_rc);
      if ( LN_IS_NOT_OK(db) )
	  {
		  DEBUG(("Notes::Database object was not OK at line %d", __LINE__));
	      XSRETURN_NOT_OK;
	  }

      LN_PUSH_NEW_OBJ( "Notes::Database", db );
      //printf("CREATED DBHANDLE: %ld\n", (long)ln_dst_handle);
	  LN_INIT_OBJ_STRUCT(NOTESDATABASE, ln_obj);
	  LN_SET_DB_HANDLE(NOTESDATABASE, ln_obj, ln_dst_handle);
      //printf("STORED DBHANDLE: %ld\n", (long)LN_DB_HANDLE(NOTESDATABASE,ln_obj));
      LN_SET_OK      ( ln_obj );
      XSRETURN       ( 1 );


void
DESTROY( db )
      LN_Database *   db;
   PREINIT:
      STATUS          ln_rc;
   PPCODE:
      //printf("CLOSING DBHANDLE: %ld\n", LN_DB_HANDLE(NOTESDATABASE, db));
      ln_rc = NSFDbClose( LN_DB_HANDLE(NOTESDATABASE, db) );
      LN_FREE_OBJ_STRUCT(NOTESDATABASE, db);
      //LN_SET_PARENT_IVX( db, ln_rc );
      XSRETURN( 0 );


void
filename( db )
      LN_Database *   db;
   PREINIT:
      char            ln_canonical_path[ MAXPATH ];
      char            ln_expanded_path [ MAXPATH ];
      STATUS          ln_rc;
   ALIAS:
      filename		  = 0
      canonical_path  = 0
      expanded_path   = 1
      path            = 1
      filepath        = 1
   PPCODE:
      ln_rc = NSFDbPathGet( LN_DB_HANDLE(NOTESDATABASE,db), ln_canonical_path, ln_expanded_path );
      LN_SET_IVX(db, ln_rc);
      if ( LN_IS_OK(db) )
      {
         switch( ix )
         {
            case   0: XPUSHs(sv_2mortal(newSVpv(ln_canonical_path, 0)));
                      XSRETURN( 1 );
                      break;
            case   1: XPUSHs(sv_2mortal(newSVpv(ln_expanded_path,  0)));
                      XSRETURN( 1 );
                      break;
            default:  XSRETURN_NOT_OK;
                      break;
         }
      }
      else
      {
		  DEBUG(("Notes::Database object was not OK at line %d", __LINE__));
		  XSRETURN_NOT_OK;
	  }


void
title( db )
      LN_Database *   db;
   PREINIT:
      char            ln_buffer[NSF_INFO_SIZE];    /* database info buffer */
      char            ln_value[NSF_INFO_SIZE];     /* database title */
      STATUS          ln_rc;
   ALIAS:
      title = 0
      categories = 1
      template = 2
      inherited_template = 3
   PPCODE:
    /* Get the database buffer. */
    ln_rc = NSFDbInfoGet (LN_DB_HANDLE(NOTESDATABASE,db), ln_buffer);
    LN_SET_IVX(db, ln_rc);
	if ( LN_IS_NOT_OK(db) )
	{
		DEBUG(("Notes::Database object was not OK at line %d", __LINE__));
		XSRETURN_NOT_OK;
	}

	switch( ix )
	{
	   	case  0:  NSFDbInfoParse (ln_buffer, INFOPARSE_TITLE, ln_value, NSF_INFO_SIZE - 1);
	              break;
	    case  1:  NSFDbInfoParse (ln_buffer, INFOPARSE_CATEGORIES, ln_value, NSF_INFO_SIZE - 1);
	              break;
	    case  2:  NSFDbInfoParse (ln_buffer, INFOPARSE_CLASS, ln_value, NSF_INFO_SIZE - 1);
	              break;
	    case  3:  NSFDbInfoParse (ln_buffer, INFOPARSE_DESIGN_CLASS, ln_value, NSF_INFO_SIZE - 1);
	              break;
	    default:  XSRETURN_NOT_OK;
	              break;
	}
	XPUSHs(sv_2mortal(newSVpv(ln_value, 0)));
	XSRETURN( 1 );

void
is_public_address_book( db )
      LN_Database *   db;
   PREINIT:
      char            ln_buffer[NSF_INFO_SIZE];    /* database info buffer */
      char            ln_value[NSF_INFO_SIZE];     /* database title */
      STATUS          ln_rc;
   ALIAS:
      is_public_address_book = 0
      is_personal_address_book = 1
   PPCODE:
    /* Get the database buffer. */
    ln_rc = NSFDbInfoGet (LN_DB_HANDLE(NOTESDATABASE,db), ln_buffer);
    LN_SET_IVX(db, ln_rc);
	if ( LN_IS_NOT_OK(db) )
	{
		DEBUG(("Notes::Database object was not OK at line %d", __LINE__));
		XSRETURN_NOT_OK;
	}
	NSFDbInfoParse (ln_buffer, INFOPARSE_DESIGN_CLASS, ln_value, NSF_INFO_SIZE - 1);

	switch( ix )
	{
	   	case  0:  if(strEQ(ln_value, PUBLIC_ADDRESSBOOK_TEMPLATE_NAME))
	   			  {
					  XSRETURN_YES;
			      }
	              break;
	    case  1:  if(strEQ(ln_value, PERSONAL_ADDRESSBOOK_TEMPLATE_NAME))
	              {
					  XSRETURN_YES;
			      }
	              break;
	    default:  XSRETURN_NOT_OK;
	              break;
	}
	XSRETURN_NO;

void
compact( db )
      LN_Database *   db;
   PREINIT:
      char            ln_db_path[MAXPATH];
      DWORD           stats[2];      /* status return code */
      STATUS          ln_rc;
   ALIAS:
      compact_mailbox = 1
      compactmailbox = 1
   PPCODE:
    if ( LN_IS_NOT_OK(db) )
	{
		DEBUG(("Notes::Database object was not OK at line %d", __LINE__));
		XSRETURN_NOT_OK;
	}

	/* Get the database path. */
    if(ln_rc = NSFDbPathGet(LN_DB_HANDLE(NOTESDATABASE,db), NULL, ln_db_path))
	{
		DEBUG(("Notes::Database object returning error %d at line %d", ln_rc, __LINE__));
		XSRETURN_NOT_OK;
	}
	switch( ix )
	{
	   	case  0:  ln_rc = NSFDbCompact (ln_db_path, 0, &stats[0]);
	              break;
	    case  1:  ln_rc = NSFDbCompact (ln_db_path, DBCOMPACT_MAILBOX, &stats[0]);
	              break;
	    default:  XSRETURN_NOT_OK;
	              break;
	}
	LN_SET_IVX(db, ln_rc);
	if ( LN_IS_NOT_OK(db) )
	{
		DEBUG(("Notes::Database object was not OK at line %d", __LINE__));
		XSRETURN_NOT_OK;
	}
	/* Return a perl array of the db size (in bytes)
	before and after compact() respectively. */
	XPUSHs(sv_2mortal(newSViv(stats[0])));
	XPUSHs(sv_2mortal(newSViv(stats[1])));
	XSRETURN( 2 );


void
current_access_level( db )
      LN_Database *   db;
   PREINIT:
      WORD			  wAccessLevel;
      WORD			  wAccessFlag;
   ALIAS:
      currentaccess = 0
      currentaccesslevel = 0
   PPCODE:
    if ( LN_IS_NOT_OK(db) )
	{
		DEBUG(("Notes::Database object was not OK at line %d", __LINE__));
		XSRETURN_NOT_OK;
	}

	NSFDbAccessGet(	LN_DB_HANDLE(NOTESDATABASE,db), &wAccessLevel, &wAccessFlag);

	/* Return a perl array of the ACCESS_LEVEL and
	ACCESS_FLAGS respectively. */
	XPUSHs(sv_2mortal(newSViv((IV)wAccessLevel)));
	XPUSHs(sv_2mortal(newSViv((IV)wAccessFlag)));
	XSRETURN( 2 );

void
server( db )
      LN_Database *   db;
   PREINIT:
      STATUS          ln_rc;
      char		   	  ln_db_path[ MAXPATH ];
      char		   	  ln_server[ MAXUSERNAME ];
      char		   	  ln_server_canonical[ MAXUSERNAME ];
   ALIAS:
      server_name = 0
      servername = 0
   PPCODE:
    if ( LN_IS_NOT_OK(db) )
	{
		DEBUG(("Notes::Database object was not OK at line %d", __LINE__));
		XSRETURN_NOT_OK;
	}

	if(ln_rc = NSFDbPathGet(LN_DB_HANDLE(NOTESDATABASE,db), NULL, ln_db_path ))
	{
		DEBUG(("Notes::Database object returning error %d at line %d", ln_rc, __LINE__));
	    XSRETURN_NOT_OK;
  	}
  	if(ln_rc = OSPathNetParse(ln_db_path, NULL, ln_server, NULL))
	{
		DEBUG(("Notes::Database object returning error %d at line %d", ln_rc, __LINE__));
	    XSRETURN_NOT_OK;
  	}
  	if(ln_rc = DNCanonicalize( 0L, NULL, ln_server, (char FAR *)ln_server_canonical,
	     	    			   MAXUSERNAME, NULL))
	{
		DEBUG(("Notes::Database object returning error %d at line %d", ln_rc, __LINE__));
	    XSRETURN_NOT_OK;
  	}

	XPUSHs(sv_2mortal(newSVpv(ln_server_canonical,0)));
	XSRETURN( 1 );


void
is_encrypted(db)
      LN_Database *   db;
    PREINIT:
      int             ln_is_encrypted;
      STATUS          ln_rc;
    ALIAS:
      isencrypted = 0
      is_locally_encrypted = 0
    PPCODE:
      if(ln_rc = NSFDbIsLocallyEncrypted(LN_DB_HANDLE(NOTESDATABASE,db),&ln_is_encrypted))
      {
		  DEBUG(("Notes::Database object returning error %d at line %d", ln_rc, __LINE__));
	  	  XSRETURN_NOT_OK;
	  }
      if (ln_is_encrypted)
        XSRETURN_YES;
      else
        XSRETURN_NO;