#define BLOCK Perl_BLOCK

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "notesreplication.h"

MODULE = Notes::Replication   PACKAGE = Notes::Database

PROTOTYPES: DISABLE


void
replication_info( db )
      LN_Database *   db;
   PREINIT:
      d_LN_XSVARS;
      STATUS          ln_rc;
      DBREPLICAINFO * ri;
   ALIAS:
      ReplicationInfo = 0
   PPCODE:
   	  Newz(1, ri, 1, DBREPLICAINFO);
      ln_rc = NSFDbReplicaInfoGet( LN_DB_HANDLE(NOTESDATABASE,db), ri );
      LN_PUSH_NEW_OBJ( "Notes::Replication", db );
      LN_INIT_OBJ_STRUCT(NOTESREPLICATION, ln_obj);
      //printf("SETTING DBHANDLE = %ld\n", LN_DB_HANDLE(NOTESDATABASE,db));
      LN_SET_DB_HANDLE(NOTESREPLICATION, ln_obj, LN_DB_HANDLE(NOTESDATABASE,db));
      //printf("STORED DBHANDLE = %ld\n", LN_DB_HANDLE(NOTESREPLICATION,ln_obj));
      //printf("SETTING DBREPLICAINFO = %ld\n", ri);
      LN_SET_DB_REPL_INFO(NOTESREPLICATION, ln_obj, ri);
      //printf("STORED DBREPLICAINFO = %ld\n", LN_DB_REPL_INFO(NOTESREPLICATION,ln_obj));
      LN_SET_OK      ( ln_obj );
      XSRETURN       ( 1 );


MODULE = Notes::Replication	 PACKAGE = Notes::Replication

void
DESTROY( repl )
      LN_Replication *   repl;
   PPCODE:
   	  Safefree( LN_DB_REPL_INFO(NOTESREPLICATION, repl) );
   	  LN_FREE_OBJ_STRUCT(NOTESREPLICATION, repl);
  	  //LN_SET_PARENT_IVX( repl, ln_rc );
      XSRETURN( 0 );


void
is_browsable( repl )
      LN_Replication *   repl;
   PREINIT:
      int             ln_query;
      DBREPLICAINFO * ri;
   ALIAS:
      is_browsable                = 0
      is_catalogable              = 1
	  is_replicating              = 2
	  is_never_replicating        = 3
	  is_receiving_deletions      = 4
	  is_sending_deletions        = 5
	  is_using_cutoff_interval    = 6
   	  is_running_scheduled_agents = 7
   PPCODE:
      if ( LN_IS_OK(repl) )
      {
		 ri = LN_DB_REPL_INFO(NOTESREPLICATION, repl);
         switch( ix )
         {
            case 0:   ln_query = !(ri->Flags & REPLFLG_DO_NOT_BROWSE);
                      break;
            case 1:   ln_query = !(ri->Flags & REPLFLG_DO_NOT_CATALOG);
                      break;
                      break;
            default:  XSRETURN_NOT_OK;
            		  break;
         }
         if (ln_query)
         {
			 XSRETURN_YES;
		 }
		 else
		 {
			 XSRETURN_NO;
		 }
       }
       else
       {
		   DEBUG(("Notes::Database object is not OK at line %d", __LINE__));
		   XSRETURN_NOT_OK;
	   }


void
set_browsable( repl )
      LN_Replication * repl;
   PREINIT:
      DBREPLICAINFO  * ri;
   ALIAS:
      set_browsable                      =  0
      set_not_browsable                  =  1
      set_catalogable                    =  2
      set_not_catalogable                =  3
	  disable_replication                =  4
	  enable_replication                 =  5
	  never_replicate_again              =  6
	  replicate_again                    =  7
	  receive_deletions                  =  8
	  do_not_receive_deletions           =  9
	  send_deletions                     = 10
	  do_not_send_deletions              = 11
	  keep_docs_not_in_cutoff_interval   = 12
	  delete_docs_not_in_cutoff_interval = 13
	  run_scheduled_agents               = 14
      do_not_run_scheduled_agents        = 15
   PPCODE:
      if ( LN_IS_OK(repl) )
      {
		 ri = LN_DB_REPL_INFO(NOTESREPLICATION, repl);
         switch( ix )
         {
            case 0:  ri->Flags &= ~REPLFLG_DO_NOT_BROWSE;
            break;
            case 1:  ri->Flags |=  REPLFLG_DO_NOT_BROWSE;
            break;
            case 2:  ri->Flags &= ~REPLFLG_DO_NOT_CATALOG;
            break;
            case 3:  ri->Flags |=  REPLFLG_DO_NOT_CATALOG;
            break;
            default: XSRETURN(0);
            break;
         }
         NSFDbReplicaInfoSet(LN_DB_HANDLE(NOTESREPLICATION,repl), ri );
      }
      XSRETURN_OK;


void
cutoff_interval_days( repl )
      LN_Replication * repl;
   PREINIT:
      DBREPLICAINFO  * ri;
   PPCODE:
      if (LN_IS_OK(repl))
      {
		  ri = LN_DB_REPL_INFO(NOTESREPLICATION, repl);
		  XSRETURN_IV( (IV) ri->CutoffInterval );
	  }
      else
      {
		  DEBUG(("Notes::Database object is not OK at line %d", __LINE__));
	  	  XSRETURN_NOT_OK;
	  }


void
set_cutoff_interval_days( repl, ln_cutoff_interval_days )
      LN_Replication * repl;
      IV               ln_cutoff_interval_days;
   PREINIT:
      DBREPLICAINFO  * ri;
   PPCODE:
      if ( LN_IS_OK(repl) )
      {
		 ri = LN_DB_REPL_INFO(NOTESREPLICATION, repl);
         ri->CutoffInterval = (WORD) ln_cutoff_interval_days;
         NSFDbReplicaInfoSet(LN_DB_HANDLE(NOTESREPLICATION,repl), ri );
      }
      XSRETURN_OK;

void
gethistory( repl )
      LN_Replication * repl;
   PREINIT:
      STATUS 	         error = NOERROR;				 /* error code from API calls */
      HANDLE             hReplHist;
	  REPLHIST_SUMMARY   ReplHist;
	  REPLHIST_SUMMARY * pReplHist;
	  char               szTimedate[MAXALPHATIMEDATE + 1];
	  WORD               wLen;
	  DWORD              dwNumEntries, i;
	  char 		       * pServerName;                    /* terminating NULL not included */
	  char               szServerName[MAXUSERNAME + 1];
	  char             * pFileName;                      /* includes terminating NULL */
	  char               szDirection[10];                /* NEVER, SEND, RECEIVE */
   PPCODE:
	  /* Get the Replication History Summary */
	  error = NSFDbGetReplHistorySummary (LN_DB_HANDLE(NOTESREPLICATION,repl),
	                                      0,
	                                      &hReplHist,
	                                      &dwNumEntries);
	  if (error)
	  {
	      LN_SET_IVX(repl, error);
	      DEBUG(("Notes::Replication object returning error %d at line %d", error, __LINE__));
	      XSRETURN_NOT_OK;
      }
	  /* Obtain a pointer to the first member of the Replication History Summary array */
      pReplHist = OSLock (REPLHIST_SUMMARY, hReplHist);
      for (i = 0; i < dwNumEntries; i++)
      {
	  	ReplHist = pReplHist[i];
  		error = ConvertTIMEDATEToText (NULL, NULL, &(ReplHist.ReplicationTime),
  		                               szTimedate, MAXALPHATIMEDATE, &wLen);
  		if (error)
  		{
			DEBUG(("Notes::Replication object returning error %d at line %d", error, __LINE__));
  			OSUnlock (hReplHist);
  			OSMemFree (hReplHist);
  			LN_SET_IVX(repl, error);
	        XSRETURN_NOT_OK;
  		}
  		szTimedate[wLen] = '\0';
  		if (ReplHist.Direction == DIRECTION_NEVER)
    		strcpy (szDirection, "NEVER");
  		else if (ReplHist.Direction == DIRECTION_SEND)
  			strcpy (szDirection, "SEND");
  		else if (ReplHist.Direction == DIRECTION_RECEIVE)
  			strcpy (szDirection, "RECEIVE");
  		else
  			strcpy (szDirection, "");

  		pServerName = NSFGetSummaryServerNamePtr (pReplHist, i);
  		strncpy (szServerName, pServerName, ReplHist.ServerNameLength);
  		szServerName[ReplHist.ServerNameLength] = '\0';

  		/* FileName will be NULL terminated */
  		pFileName = NSFGetSummaryFileNamePtr (pReplHist, i);

  		/* Push entry on the stack as a new SV */
  		XPUSHs( sv_2mortal( newSVpvf( "%s,%s,%s,%s",
  		        szTimedate, szServerName, pFileName, szDirection)));
	  }
	  OSUnlock  (hReplHist);
	  OSMemFree (hReplHist);


void
clearhistory( repl )
	  LN_Replication * repl;
   PREINIT:
      STATUS error = NOERROR;
   PPCODE:
      if ( LN_IS_OK(repl) )
	  {
	      error = NSFDbClearReplHistory(LN_DB_HANDLE(NOTESREPLICATION,repl), 0);
      }
      XSRETURN_OK;