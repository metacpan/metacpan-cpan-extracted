#define BLOCK Perl_BLOCK

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "notesview.h"

static int
not_here(char *s)
{
    croak("%s not implemented on this architecture", s);
    return -1;
}

static IV
constant(char *name, int len, int arg)
{
	errno = 0;

	/* Notes Color Constants */

	if(strEQ(name,"COLOR_BLACK"))
		return NOTES_COLOR_BLACK;
	else if (strEQ(name,"COLOR_BLUE"))
		return NOTES_COLOR_BLUE;
	else if (strEQ(name,"COLOR_CYAN"))
		return NOTES_COLOR_CYAN;
	else if (strEQ(name,"COLOR_GREEN"))
		return NOTES_COLOR_GREEN;
	else if (strEQ(name,"COLOR_MAGENTA"))
		return NOTES_COLOR_MAGENTA;
	else if (strEQ(name,"COLOR_RED"))
		return NOTES_COLOR_RED;
	else if (strEQ(name,"COLOR_YELLOW"))
		return NOTES_COLOR_YELLOW;
	else if (strEQ(name,"COLOR_LIGHT_GRAY"))
		return NOTES_COLOR_LTGRAY;
	else if (strEQ(name,"COLOR_GRAY"))
		return NOTES_COLOR_GRAY;
	else if (strEQ(name,"COLOR_DARK_BLUE"))
		return NOTES_COLOR_DKBLUE;
	else if (strEQ(name,"COLOR_DARK_CYAN"))
		return NOTES_COLOR_DKCYAN;
	else if (strEQ(name,"COLOR_DARK_GREEN"))
		return NOTES_COLOR_DKGREEN;
	else if (strEQ(name,"COLOR_DARK_MAGENTA"))
		return NOTES_COLOR_DKMAGENTA;
	else if (strEQ(name,"COLOR_DARK_RED"))
		return NOTES_COLOR_DKRED;
	else if (strEQ(name,"COLOR_DARK_YELLOW"))
		return NOTES_COLOR_DKYELLOW;
	else if (strEQ(name,"COLOR_WHITE"))
		return NOTES_COLOR_WHITE;

	/* Notes View Row Spacing Constants */

	else if (strEQ(name,"VW_SPACING_SINGLE"))
		return VIEW_TABLE_SINGLE_SPACE;
	else if (strEQ(name,"VW_SPACING_ONE_POINT_25"))
		return VIEW_TABLE_ONE_POINT_25_SPACE;
	else if (strEQ(name,"VW_SPACING_ONE_POINT_50"))
		return VIEW_TABLE_ONE_POINT_50_SPACE;
	else if (strEQ(name,"VW_SPACING_ONE_POINT_75"))
		return VIEW_TABLE_ONE_POINT_75_SPACE;
	else if (strEQ(name,"VW_SPACING_DOUBLE"))
		return VIEW_TABLE_DOUBLE_SPACE;
	else
		not_here(name);

   	errno = EINVAL;
   	return 0;
}


MODULE = Notes::View   PACKAGE = Notes::Database


PROTOTYPES: DISABLE

void
get_view( db, ln_view_name )
      LN_Database * db;
      char        * ln_view_name;
   PREINIT:
      d_LN_XSVARS;
	  NOTEID        ln_view_id;       /* note id of the view */
	  HCOLLECTION   hCollection;      /* collection handle */
      STATUS        ln_rc;
   ALIAS:
      get_view  = 0
      open_view = 0
      view      = 0
   PPCODE:
      if ( LN_IS_NOT_OK(db) )
      {
		  XSRETURN_NOT_OK;
	  }
	  /* Get the note id of the view we want. */
	  if (ln_rc = NIFFindView (LN_DB_HANDLE(NOTESDATABASE,db), ln_view_name, &ln_view_id))
	  {
	      LN_SET_IVX(db, ln_rc);
	      XSRETURN_NOT_OK;
   	  }

   	  /* Get a collection using this view. */
	  if (ln_rc = NIFOpenCollection(
	  		      LN_DB_HANDLE(NOTESDATABASE,db), /* handle of db with view */
	  		      LN_DB_HANDLE(NOTESDATABASE,db), /* handle of db with data */
	  		      ln_view_id,     				  /* note id of the view */
	  		      0,              				  /* collection open flags */
	  		      NULLHANDLE,     				  /* handle to unread ID list */
	  		      &hCollection,   			      /* collection handle */
	  		      NULLHANDLE,     			      /* handle to open view note */
	  		      NULL,           			      /* universal note id of view */
	  		      NULLHANDLE,     				  /* handle to collapsed list */
	  		      NULLHANDLE))    			 	  /* handle to selected list */
	  {
	      LN_SET_IVX(db, ln_rc);
	      XSRETURN_NOT_OK;
	  }

      LN_PUSH_NEW_OBJ( "Notes::View", db );
      LN_INIT_OBJ_STRUCT(NOTESVIEW, ln_obj);
      DEBUG(("Setting Notes::View DBHANDLE to %ld\n", LN_DB_HANDLE(NOTESDATABASE,db)));
      LN_SET_DB_HANDLE(NOTESVIEW, ln_obj, LN_DB_HANDLE(NOTESDATABASE,db));
      DEBUG(("Setting Notes::View HCOLLECTION to %ld\n", hCollection));
      LN_SET_HCOLLECTION(NOTESVIEW, ln_obj, hCollection);
      DEBUG(("Setting Notes::View NOTEID to %ld\n", ln_view_id));
      LN_SET_NOTE_ID(NOTESVIEW, ln_obj, ln_view_id);
      DEBUG(("Setting Notes::View NOTEPTR to %ld\n", 0));
      LN_SET_NOTE_PTR(NOTESVIEW, ln_obj, 0);
      LN_SET_OK( ln_obj );
      XSRETURN( 1 );


MODULE = Notes::View   PACKAGE = Notes::View

void
DESTROY( view )
      LN_View *   view;
   PREINIT:
      STATUS      ln_rc;
   PPCODE:
      ln_rc = NIFCloseCollection(LN_HCOLLECTION(NOTESVIEW, view));
      LN_FREE_OBJ_STRUCT(NOTESVIEW, view);
      //LN_SET_PARENT_IVX( db, ln_rc );
      XSRETURN( 0 );

void
top_level_entry_count( view )
      LN_View     * view;
   PREINIT:
      NOTEHANDLE           hNote = NULLHANDLE;
	  HCOLLECTION          hCollection;     /* collection handle */
	  COLLECTIONPOSITION   CollPosition;    /* position within collection */
	  HANDLE               hBuffer;         /* handle to buffer of note ids */
	  NOTEID             * IdList;          /* pointer to a note id */
	  DWORD                EntriesFound;    /* number of entries found */
	  DWORD                NotesFound = 0;  /* number of documents found */
	  WORD                 SignalFlag;      /* signal and share warning flags */
	  DWORD                i;               /* a counter */
      STATUS               ln_rc = NOERROR; /* return status from API calls */
   PPCODE:
	  hCollection = LN_HCOLLECTION(NOTESVIEW, view);

	  /* Set up the data structure, COLLECTIONPOSITION, that controls where in
	  the collection we will begin when we read the collection.  Specify that we
	  want to start at the beginning. */

	  CollPosition.Level = 0;
	  CollPosition.Tumbler[0] = 0;

	  /* Get a buffer with information about each entry in the collection.
	  Perform this routine in a loop.  Terminate loop when SignalFlag
	  indicates that there is no more information to get.   */

	  do
	  {
	     if ( ln_rc = NIFReadEntries(
	            hCollection,        /* handle to this collection */
	            &CollPosition,      /* where to start in collection */
	            NAVIGATE_NEXT,      /* order to use when skipping */
	            1L,                 /* number to skip */
	            NAVIGATE_NEXT,      /* order to use when reading */
	            0xFFFFFFFF,         /* max number to read */
	            READ_MASK_NOTEID,   /* info we want */
	            &hBuffer,           /* handle to info buffer */
	            NULL,               /* length of info buffer */
	            NULL,               /* entries skipped */
	            &EntriesFound,      /* entries read */
	            &SignalFlag))       /* share warning and more signal flag */
	     {
			DEBUG(("Notes::View object returning error %d at line %d", ln_rc, __LINE__));
	        LN_SET_IVX(view, ln_rc);
	        XSRETURN_NOT_OK;
	     }

	     /* Check to make sure there was a buffer of information returned.
	     (We would crash if we tried to proceed with a null buffer.) */

	     if (hBuffer == NULLHANDLE)
	     {
			DEBUG(("Notes::View object returning error %d at line %d", ln_rc, __LINE__));
	        LN_SET_IVX(view, ln_rc);
	        XSRETURN_NOT_OK;
	     }

	     /* Lock down (freeze the location) of the buffer of entry IDs. Cast
	     the resulting pointer to the type we need. */

	     IdList = (NOTEID *) OSLockObject (hBuffer);

	     for (i=0; i<EntriesFound; i++)
	     {
	        if (NOTEID_CATEGORY & IdList[i]) continue;
	        NotesFound++;
	     }

	     /* Unlock the list of IDs. */

	     OSUnlockObject (hBuffer);

	     /* Free the memory allocated by NIFReadEntries. */

	     OSMemFree (hBuffer);

	     /* Loop if the end of the collection has not been reached because the buffer
	     was full.  */

	  }  while (SignalFlag & SIGNAL_MORE_TO_DO);
	  XSRETURN_IV((IV)NotesFound);

void
name( view )
      LN_View *   view;
   PREINIT:
      NOTEHANDLE           hNote = NULLHANDLE;
      STATUS               ln_rc = NOERROR;
      BLOCKID              ValueBlockID;
	  ORIGINATORID         NoteOID;
	  TIMEDATE             ModTimeDate;
      char                 szData[128];
      char                 szTimeDate[MAXALPHATIMEDATE + 1];
      char                 field_text[TEXT_BUFFER_LENGTH];
      char far           * pData;
	  DWORD                dwLength;
	  WORD                 wDataType;
	  WORD                 wStringLen;
      WORD                 ClassView;
      WORD                 field_len;
	  WORD                 list_entries;
	  WORD	     		   i;
	  BOOL                 bTimeRelativeFormulae;
   ALIAS:
      name             = 0
      added            = 1
      last_modified    = 2
      last_accessed    = 3
      created          = 4
      has_date_formula = 5
      universalid      = 6
      is_private       = 7
      is_default       = 8
      readers          = 9
   PPCODE:
    if (ln_rc = NSFNoteOpen(LN_DB_HANDLE(NOTESVIEW,view), LN_NOTE_ID(NOTESVIEW,view), 0, &hNote))
    {
		DEBUG(("Notes::View object returning error %d at line %d", ln_rc, __LINE__));
        LN_SET_IVX(view, ln_rc);
        XSRETURN_NOT_OK;
    }
	switch(ix)
	{
	    /*
	 	 * Read the title of the View from the View note.
		 */
		case 0 : if (ln_rc = NSFItemInfo(hNote,
		                        FIELD_TITLE,
		                        sizeof(FIELD_TITLE) - 1,
		                        NULL,
		                        &wDataType,
		                        &ValueBlockID,
		                        &dwLength))
		         {
					DEBUG(("Notes::View object returning error %d at line %d", ln_rc, __LINE__));
		     	    LN_SET_IVX(view, ln_rc);
	         	 	XSRETURN_NOT_OK;
                 }
		        /*
		         *  Lock the block returned, write title of View to the output buffer.
                 */
		         pData = OSLockBlock(char, ValueBlockID);
                 pData += sizeof(WORD);

                 memmove(szData, pData, (int) (dwLength - sizeof(WORD)));
                 szData[dwLength - sizeof(WORD)] = '\0';
                 XPUSHs(sv_2mortal(newSVpv(szData, 0)));
                 OSUnlockBlock(ValueBlockID);
    			 break;

    	/*
		 * Read the added date of the View from the View note.
		 */
    	case 1 : NSFNoteGetInfo(hNote, _NOTE_ADDED_TO_FILE, &ModTimeDate);
                 if (ln_rc = ConvertTIMEDATEToText(NULL,
                                           NULL,
                                           &ModTimeDate,
                                           szTimeDate,
                                           MAXALPHATIMEDATE,
                                           &wStringLen))
                 {
					 DEBUG(("Notes::View object returning error %d at line %d", ln_rc, __LINE__));
    	             NSFNoteClose(hNote);
    	             LN_SET_IVX(view, ln_rc);
                 	 XSRETURN_NOT_OK;
                 }
                 szTimeDate[wStringLen]='\0';
                 XPUSHs(sv_2mortal(newSVpv(szTimeDate,0)));
                 break;

    	/*
		 *  Get the time and date that the view was last modified.
         */
    	case 2 : NSFNoteGetInfo(hNote, _NOTE_MODIFIED, &ModTimeDate);
                 if (ln_rc = ConvertTIMEDATEToText(NULL,
                                           NULL,
                                           &ModTimeDate,
                                           szTimeDate,
                                           MAXALPHATIMEDATE,
                                           &wStringLen))
                 {
					 DEBUG(("Notes::View object returning error %d at line %d", ln_rc, __LINE__));
    	             NSFNoteClose(hNote);
    	             LN_SET_IVX(view, ln_rc);
                 	 XSRETURN_NOT_OK;
                 }
                 szTimeDate[wStringLen]='\0';
                 XPUSHs(sv_2mortal(newSVpv(szTimeDate,0)));
                 break;

		/*
		 *  Get the time and date that the view was last accessed.
         */
        case 3 : NSFNoteGetInfo(hNote, _NOTE_ACCESSED, &ModTimeDate);
		         if (ln_rc = ConvertTIMEDATEToText(NULL,
		                                   NULL,
		                                   &ModTimeDate,
		                                   szTimeDate,
		                                   MAXALPHATIMEDATE,
		                                   &wStringLen))
		         {
					 DEBUG(("Notes::View object returning error %d at line %d", ln_rc, __LINE__));
		             NSFNoteClose(hNote);
		             LN_SET_IVX(view, ln_rc);
		           	 XSRETURN_NOT_OK;
		         }
		         szTimeDate[wStringLen]='\0';
		         XPUSHs(sv_2mortal(newSVpv(szTimeDate,0)));
		         break;

		/*
		 *  Get the time and date that the view was created.
         */
		case 4 : NSFNoteGetInfo(hNote, _NOTE_OID, &NoteOID);
				 if (ln_rc = ConvertTIMEDATEToText(NULL,
				                           NULL,
				                           &NoteOID.Note,
				                           szTimeDate,
				                           MAXALPHATIMEDATE,
				                           &wStringLen))
				 {
					 DEBUG(("Notes::View object returning error %d at line %d", ln_rc, __LINE__));
				     NSFNoteClose(hNote);
				     LN_SET_IVX(view, ln_rc);
				   	 XSRETURN_NOT_OK;
				 }
				 szTimeDate[wStringLen]='\0';
				 XPUSHs(sv_2mortal(newSVpv(szTimeDate,0)));
		         break;

        /*
	     * If a VIEW_FORMULA_TIME_ITEM is present, then this view contains one
	     * or more time relative formulae ("@Now", for example).
         */
        case 5 : bTimeRelativeFormulae = NSFItemIsPresent(hNote,
                                           VIEW_FORMULA_TIME_ITEM,
                                           sizeof(VIEW_FORMULA_TIME_ITEM) -1);
                 NSFNoteClose(hNote);
                 if(bTimeRelativeFormulae)
                 {
					 XSRETURN_YES;
				 }
				 else
				 {
					 XSRETURN_NO;
				 }
				 break;

		/*
		 *  Get the view universal id (UNID).
		 */
		case 6 : NSFNoteGetInfo(hNote, _NOTE_OID, &NoteOID);
				 XPUSHs(sv_2mortal(
					 newSVpvf("%08lX%08lX%08lX%08lX",
				 				NoteOID.File.Innards[1],
				 				NoteOID.File.Innards[0],
				 				NoteOID.Note.Innards[1],
				 				NoteOID.Note.Innards[0]
				 		)));
		         break;

		/*
		 * Check if view is private.
		 */
		case 7 : if (ln_rc = NSFItemInfo(hNote,
		                        FIELD_PRIVATE_TYPE,
		                        sizeof(FIELD_PRIVATE_TYPE) - 1,
		                        NULL,
		                        &wDataType,
		                        &ValueBlockID,
		                        &dwLength))
		         {
					if(ln_rc == ERR_ITEM_NOT_FOUND)
					{
						NSFNoteClose(hNote);
						XSRETURN_NO;
					}
					else
					{
						DEBUG(("Notes::View object returning error %d at line %d", ln_rc, __LINE__));
						NSFNoteClose(hNote);
		     	    	LN_SET_IVX(view, ln_rc);
	         	 		XSRETURN_NOT_OK;
					}
                 }
		        /*
		         *  Lock the block returned, write title of View to the output buffer.
                 */
		         pData = OSLockBlock(char, ValueBlockID);
                 pData += sizeof(WORD);

                 memmove(szData, pData, (int) (dwLength - sizeof(WORD)));
                 szData[dwLength - sizeof(WORD)] = '\0';
                 OSUnlockBlock(ValueBlockID);
                 NSFNoteClose(hNote);

                 if(szData[0] == FIELD_PRIVATE_TYPE_VIEW)
                 {
					 XSRETURN_YES;
			 	 }
			 	 else
			 	 {
					 XSRETURN_NO;
			     }
    			 break;

    	/*
		 *  Check if this is the default view.
		 */
		case 8 : NSFNoteGetInfo(hNote, _NOTE_CLASS, &ClassView);
				 NSFNoteClose(hNote);
                 if((ClassView & NOTE_CLASS_DEFAULT) == NOTE_CLASS_DEFAULT)
                 {
					 XSRETURN_YES;
			 	 }
			 	 else
			 	 {
					 XSRETURN_NO;
			     }
    			 break;

    	/*
    	 * Get the values of the $Readers (DESIGN_READERS) field and return them.
    	 */
    	case 9 : list_entries = NSFItemGetTextListEntries (
                 				   hNote,
                 				   DESIGN_READERS);

				for(i = 0; i < list_entries; i++)
				{
        			field_len = NSFItemGetTextListEntry (
        			            hNote,
        			            DESIGN_READERS,
        			            i,
        			            field_text,
        			            (WORD) (sizeof (field_text) -1) );
        			XPUSHs(sv_2mortal(newSVpv(field_text,0)));
				}
				NSFNoteClose(hNote);
				XSRETURN( i );
				break;

		default: NSFNoteClose(hNote);
				 XSRETURN_NOT_OK;
		         break;
	}
    NSFNoteClose(hNote);
    XSRETURN( 1 );


void
column_count( view )
      LN_View *   view;
   PREINIT:
      NOTEHANDLE           hNote = NULLHANDLE;
      STATUS               ln_rc = NOERROR;
      char                 szData[128];
	  DWORD                dwLength;
	  WORD                 wDataType;
	  BLOCKID              ValueBlockID;
      char far           * pData;
      char far           * pPackedData;
      VIEW_FORMAT_HEADER * pHeaderFormat;
	  VIEW_TABLE_FORMAT  * pTableFormat;
	  VIEW_TABLE_FORMAT2 * pTableFormat2;
	  VIEW_COLUMN_FORMAT * pColumnFormat;
	  VIEW_FORMAT_HEADER   formatHeader;
	  VIEW_TABLE_FORMAT    tableFormat;
	  VIEW_TABLE_FORMAT2   tableFormat2;
	  VIEW_COLUMN_FORMAT   viewColumn;
	  void *               tempPtr;
	  WORD                 wColumn;
   ALIAS:
      column_count     = 0
      column_names     = 1
      auto_update      = 2
      background_color = 3
      row_lines        = 4
      header_lines     = 5
      spacing          = 6
      is_calendar	   = 7
      is_conflict      = 8
      is_hierarchical  = 9
   PPCODE:
   	if (ln_rc = NSFNoteOpen(LN_DB_HANDLE(NOTESVIEW,view), LN_NOTE_ID(NOTESVIEW,view), 0, &hNote))
    {
		DEBUG(("Notes::View object returning error %d at line %d", ln_rc, __LINE__));
    	LN_SET_IVX(view, ln_rc);
    	XSRETURN_NOT_OK;
    }

    /*
	 * Get the number of column in the view
	 */
	ln_rc = NSFItemInfo(hNote,
	                    VIEW_VIEW_FORMAT_ITEM,
	                    sizeof(VIEW_VIEW_FORMAT_ITEM) - 1,
	                    NULL,
	                    &wDataType,
	                    &ValueBlockID,
	                    &dwLength);

	if (ln_rc || wDataType != TYPE_VIEW_FORMAT)
	{
		DEBUG(("Notes::View object returning error %d at line %d", ln_rc, __LINE__));
		NSFNoteClose(hNote);
		LN_SET_IVX(view, ln_rc);
		XSRETURN_NOT_OK;
	}

	/*
	 *  Lock the block returned, Get the view format and check the version.
	 *  We need to do ODSMemory calls to ensure cross-platform compatibility.
	 */

	pData = OSLockBlock(char, ValueBlockID);
	pData += sizeof(WORD);

	tempPtr = pData;
	ODSReadMemory( &tempPtr, _VIEW_FORMAT_HEADER, &formatHeader, 1 );
	pHeaderFormat = &formatHeader;

	if (pHeaderFormat->Version != VIEW_FORMAT_VERSION)
	{
		DEBUG(("Notes::View object returning error %d at line %d", ln_rc, __LINE__));
		OSUnlockBlock(ValueBlockID);
		NSFNoteClose(hNote);
		LN_SET_IVX(view, ln_rc);
		XSRETURN_NOT_OK;
	}

	/*
	 *  Read the table format ( which includes the view format header )
	 */

	tempPtr = pData;
	ODSReadMemory( &tempPtr, _VIEW_TABLE_FORMAT, &tableFormat, 1 );
	pTableFormat = &tableFormat;

	pData += ODSLength(_VIEW_TABLE_FORMAT);  /* point past the table format */

	switch(ix)
	{
		/*
		 * Get the number of columns in the view.
		 */
		case 0 : wColumn = pTableFormat->Columns;
				 OSUnlockBlock(ValueBlockID);
				 NSFNoteClose(hNote);
				 XSRETURN_IV((IV)wColumn);
				 break;

		/*
		 * Get the names of the view columns and return them as
		 * a Perl array.
		 */
	    case 1 : pPackedData = pData + (ODSLength(_VIEW_COLUMN_FORMAT) * pTableFormat->Columns);

        		 /*
        		  *  Now unpack and read the column data
        		  */

	    		 for (wColumn = 1; wColumn <= pTableFormat->Columns; wColumn++)
				 {
					/*
					 *  Get the fixed portion of the column descriptor and
					 *  validate the signature.
					 */

					tempPtr = pData;
					ODSReadMemory( &tempPtr, _VIEW_COLUMN_FORMAT, &viewColumn, 1 );
					pColumnFormat = &viewColumn;

					pData += ODSLength(_VIEW_COLUMN_FORMAT);

					pPackedData += pColumnFormat->ItemNameSize;

					/*
					 * Get the Title string, then advance data pointer to next item.
					 */

					memmove(szData, pPackedData, pColumnFormat->TitleSize);
					szData[pColumnFormat->TitleSize] = '\0';
					XPUSHs(sv_2mortal(newSVpv(szData,0)));
					pPackedData += pColumnFormat->TitleSize;

					/* Skip unneeded values */
					pPackedData += pColumnFormat->FormulaSize;
					pPackedData += pColumnFormat->ConstantValueSize;

				 } /*  End of for loop.  */

				 OSUnlockBlock(ValueBlockID);
				 NSFNoteClose(hNote);
				 XSRETURN(wColumn - 1);
				 break;

		case 2 : pPackedData = pData + (ODSLength(_VIEW_COLUMN_FORMAT) * pTableFormat->Columns);

        		 /*
        		  *  Now unpack and read the column data
        		  */

	    		 for (wColumn = 1; wColumn <= pTableFormat->Columns; wColumn++)
				 {
					tempPtr = pData;
					ODSReadMemory( &tempPtr, _VIEW_COLUMN_FORMAT, &viewColumn, 1 );
					pColumnFormat = &viewColumn;

					pData += ODSLength(_VIEW_COLUMN_FORMAT);

					/* Skip unneeded values */
					pPackedData += pColumnFormat->ItemNameSize;
					pPackedData += pColumnFormat->TitleSize;
					pPackedData += pColumnFormat->FormulaSize;
					pPackedData += pColumnFormat->ConstantValueSize;

				 } /*  End of for loop.  */

				 tempPtr = pPackedData;
				 ODSReadMemory( &tempPtr, _VIEW_TABLE_FORMAT2, &tableFormat2, 1 );
				 pTableFormat2 = &tableFormat2;

				 OSUnlockBlock(ValueBlockID);
				 NSFNoteClose(hNote);
				 if(pTableFormat2->AutoUpdateSeconds == 0)
				 {
				 	XSRETURN_NO;
			 	 }
			 	 else
			 	 {
					XSRETURN_YES;
			     }
				 break;

		case 3 : pPackedData = pData + (ODSLength(_VIEW_COLUMN_FORMAT) * pTableFormat->Columns);

        		 /*
        		  *  Now unpack and read the column data
        		  */

	    		 for (wColumn = 1; wColumn <= pTableFormat->Columns; wColumn++)
				 {
					tempPtr = pData;
					ODSReadMemory( &tempPtr, _VIEW_COLUMN_FORMAT, &viewColumn, 1 );
					pColumnFormat = &viewColumn;

					pData += ODSLength(_VIEW_COLUMN_FORMAT);

					/* Skip unneeded values */
					pPackedData += pColumnFormat->ItemNameSize;
					pPackedData += pColumnFormat->TitleSize;
					pPackedData += pColumnFormat->FormulaSize;
					pPackedData += pColumnFormat->ConstantValueSize;

				 } /*  End of for loop.  */

				 tempPtr = pPackedData;
				 ODSReadMemory( &tempPtr, _VIEW_TABLE_FORMAT2, &tableFormat2, 1 );
				 pTableFormat2 = &tableFormat2;

				 OSUnlockBlock(ValueBlockID);
				 NSFNoteClose(hNote);
				 XSRETURN_IV((IV)pTableFormat2->BackgroundColor);
				 break;

		case 4 : pPackedData = pData + (ODSLength(_VIEW_COLUMN_FORMAT) * pTableFormat->Columns);

        		 /*
        		  *  Now unpack and read the column data
        		  */

	    		 for (wColumn = 1; wColumn <= pTableFormat->Columns; wColumn++)
				 {
					tempPtr = pData;
					ODSReadMemory( &tempPtr, _VIEW_COLUMN_FORMAT, &viewColumn, 1 );
					pColumnFormat = &viewColumn;

					pData += ODSLength(_VIEW_COLUMN_FORMAT);

					/* Skip unneeded values */
					pPackedData += pColumnFormat->ItemNameSize;
					pPackedData += pColumnFormat->TitleSize;
					pPackedData += pColumnFormat->FormulaSize;
					pPackedData += pColumnFormat->ConstantValueSize;

				 } /*  End of for loop.  */

				 tempPtr = pPackedData;
				 ODSReadMemory( &tempPtr, _VIEW_TABLE_FORMAT2, &tableFormat2, 1 );
				 pTableFormat2 = &tableFormat2;

				 OSUnlockBlock(ValueBlockID);
				 NSFNoteClose(hNote);
				 XSRETURN_IV((IV)pTableFormat2->LineCount);
				 break;

		case 5 : pPackedData = pData + (ODSLength(_VIEW_COLUMN_FORMAT) * pTableFormat->Columns);

        		 /*
        		  *  Now unpack and read the column data
        		  */

	    		 for (wColumn = 1; wColumn <= pTableFormat->Columns; wColumn++)
				 {
					tempPtr = pData;
					ODSReadMemory( &tempPtr, _VIEW_COLUMN_FORMAT, &viewColumn, 1 );
					pColumnFormat = &viewColumn;

					pData += ODSLength(_VIEW_COLUMN_FORMAT);

					/* Skip unneeded values */
					pPackedData += pColumnFormat->ItemNameSize;
					pPackedData += pColumnFormat->TitleSize;
					pPackedData += pColumnFormat->FormulaSize;
					pPackedData += pColumnFormat->ConstantValueSize;

				 } /*  End of for loop.  */

				 tempPtr = pPackedData;
				 ODSReadMemory( &tempPtr, _VIEW_TABLE_FORMAT2, &tableFormat2, 1 );
				 pTableFormat2 = &tableFormat2;
				 OSUnlockBlock(ValueBlockID);
				 NSFNoteClose(hNote);
				 XSRETURN_IV((IV)pTableFormat2->HeaderLineCount);
				 break;

		case 6 : pPackedData = pData + (ODSLength(_VIEW_COLUMN_FORMAT) * pTableFormat->Columns);

        		 /*
        		  *  Now unpack and read the column data
        		  */

	    		 for (wColumn = 1; wColumn <= pTableFormat->Columns; wColumn++)
				 {
					tempPtr = pData;
					ODSReadMemory( &tempPtr, _VIEW_COLUMN_FORMAT, &viewColumn, 1 );
					pColumnFormat = &viewColumn;

					pData += ODSLength(_VIEW_COLUMN_FORMAT);

					/* Skip unneeded values */
					pPackedData += pColumnFormat->ItemNameSize;
					pPackedData += pColumnFormat->TitleSize;
					pPackedData += pColumnFormat->FormulaSize;
					pPackedData += pColumnFormat->ConstantValueSize;

				 } /*  End of for loop.  */

				 tempPtr = pPackedData;
				 ODSReadMemory( &tempPtr, _VIEW_TABLE_FORMAT2, &tableFormat2, 1 );
				 pTableFormat2 = &tableFormat2;

				 OSUnlockBlock(ValueBlockID);
				 NSFNoteClose(hNote);
				 XSRETURN_IV((IV)pTableFormat2->Spacing);
				 break;

		/*
		 * Check to see if this view is a calendar view (VIEW_CLASS_CALENDAR)
		 */
		case 7 : if ((pHeaderFormat->ViewStyle & VIEW_CLASS_MASK) == VIEW_CLASS_CALENDAR)
				 {
					OSUnlockBlock(ValueBlockID);
					NSFNoteClose(hNote);
					XSRETURN_YES;
				 }
				 else
				 {
					OSUnlockBlock(ValueBlockID);
					NSFNoteClose(hNote);
					XSRETURN_NO;
				 }
				 break;

		/*
		 * Check if this view is enabled for conflict checking.
		 */
		case 8 : if((pTableFormat->Flags & VIEW_TABLE_FLAG_CONFLICT) == VIEW_TABLE_FLAG_CONFLICT)
				 {
					OSUnlockBlock(ValueBlockID);
				 	NSFNoteClose(hNote);
					XSRETURN_YES;
				 }
				 else
				 {
					OSUnlockBlock(ValueBlockID);
				 	NSFNoteClose(hNote);
					XSRETURN_NO;
				 }
				 break;

		/*
		 * Check if this view is hierarchical.
		 */
		case 9 : if((pTableFormat->Flags & VIEW_TABLE_FLAG_FLATINDEX) != VIEW_TABLE_FLAG_FLATINDEX)
				 {
					OSUnlockBlock(ValueBlockID);
					NSFNoteClose(hNote);
					XSRETURN_YES;
				 }
				 else
				 {
					OSUnlockBlock(ValueBlockID);
					NSFNoteClose(hNote);
					XSRETURN_NO;
				 }
				 break;

  		default: OSUnlockBlock(ValueBlockID);
  				 NSFNoteClose(hNote);
  				 XSRETURN_NOT_OK;
		         break;
	}
	/* If we got here something is horribly wrong! :) */
	DEBUG(("Code trap failed at line %d in file %s", ln_rc, __LINE__, __FILE__));
	XSRETURN_NOT_OK;


double
constant(sv,arg)
    PREINIT:
	STRLEN		len;
    INPUT:
	SV *		sv
	char *		s = SvPV(sv, len);
	int		arg
    CODE:
	RETVAL = constant(s,len,arg);
    OUTPUT:
	RETVAL