#define BLOCK Perl_BLOCK

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "notesdocument.h"

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

	/* NotesDocument Constants */

	if(1)
		return 0;
	else
		not_here(name);

   	errno = EINVAL;
   	return 0;
}

STATUS LNPUBLIC AppendNumberListField (
                     NOTEHANDLE hNote,
                     char * szFieldName,
                     NUMBER * aNumbers,
                     WORD  usCount)
{
    DWORD       dwValueLen;
    void       *pvoidItemValue;
    RANGE      *pRange;
    NUMBER     *pNumber;
    WORD        i;
    STATUS      error;

    /* Allocate a buffer to hold the RANGE structure followed by
       the NUMBERs in the number list */

    dwValueLen = sizeof(RANGE) + (usCount * sizeof(NUMBER));
    pvoidItemValue = (void *) malloc ((size_t)dwValueLen);

    if (pvoidItemValue == NULL)
    {
        printf ("malloc failed\n");
        return (ERR(PKG_NSF+52));
    }

    /* Store the RANGE structure in the buffer */

    pRange = (RANGE*)pvoidItemValue;
    pRange->ListEntries = usCount;
    pRange->RangeEntries = 0;
    pRange++;

    /* Store each of the NUMBERs in the buffer.  */
    pNumber = (NUMBER *)pRange;
    for (i = 0; i < usCount; i++)
    {
        memcpy ((void *)pNumber, (void *)(aNumbers + i), sizeof(NUMBER));
        pNumber++;
    }

    error = NSFItemAppend (hNote,
                ITEM_SUMMARY,
                szFieldName,
                (WORD) strlen(szFieldName),
                TYPE_NUMBER_RANGE,
                pvoidItemValue,
                dwValueLen);

    free (pvoidItemValue);

    return (ERR(error));
}


MODULE = Notes::Document   PACKAGE = Notes::View


PROTOTYPES: DISABLE

void
get_first_document( view )
      LN_View     * view;
   PREINIT:
      d_LN_XSVARS;
      NOTEHANDLE           hNote = NULLHANDLE;
      COLLECTIONPOSITION   CollPosition;    /* position within collection */
	  HANDLE               hBuffer;         /* handle to buffer of note ids */
	  NOTEID             * IdList;          /* pointer to a note id */
	  DWORD                EntriesFound;    /* number of entries found */
	  DWORD                NotesRead = 0;   /* number of documents found */
	  WORD                 SignalFlag;      /* signal and share warning flags */
	  HCOLLECTION          hCollection;     /* collection handle */
      STATUS               ln_rc;
   ALIAS:
      GetFirstDocument = 0
   PPCODE:
      if ( LN_IS_NOT_OK(view) )
      {
		  DEBUG(("Notes::View object is not OK at line %d\n", __LINE__));
		  XSRETURN_NOT_OK;
	  }
	  hCollection = LN_HCOLLECTION(NOTESVIEW, view);

	  /* Set up the data structure, COLLECTIONPOSITION, that controls where in
	     the collection we will begin when we read the collection.  Specify that we
	  	 want to start at the beginning. */

	  CollPosition.Level = 0;
	  CollPosition.Tumbler[0] = 0;

	  do
	  {
		  if ( ln_rc = NIFReadEntries(
						hCollection,        /* handle to this collection */
						&CollPosition,      /* where to start in collection */
						NAVIGATE_NEXT,      /* order to use when skipping */
						1L,                 /* number to skip */
						NAVIGATE_NEXT,      /* order to use when reading */
						1,                  /* max number to read */
						READ_MASK_NOTEID,   /* info we want */
						&hBuffer,           /* handle to info buffer */
						NULL,               /* length of info buffer */
						NULL,               /* entries skipped */
						&EntriesFound,      /* entries read */
						&SignalFlag))       /* share warning and more signal flag */
		  {
			 DEBUG(("Notes::Document object returning error %d at line %d\n", ln_rc, __LINE__));
			 LN_SET_IVX(view, ln_rc);
			 XSRETURN_NOT_OK;
		  }

		  NotesRead++;

		  /* Check to make sure there was a buffer of information returned.
		  (We would crash if we tried to proceed with a null buffer.) */

		  if (hBuffer == NULLHANDLE)
		  {
		  	 DEBUG(("Notes::View object returning End of Collection reached at line %d\n", __LINE__));
		  	 XSRETURN_UNDEF;
		  }

		  /* Lock down (freeze the location) of the buffer of entry IDs. Cast
		  the resulting pointer to the type we need. */

		  IdList = (NOTEID *) OSLockObject (hBuffer);

		  DEBUG(("GetFirstDocument() - Note ID is: %08lX\n", IdList[0]));

		  /* Unlock the list of IDs. */

		  OSUnlockObject (hBuffer);

		  /* Free the memory allocated by NIFReadEntries. */

		  OSMemFree (hBuffer);

		  /* Don't use a note ID if it is a "dummy" ID that
			 stands for a category in the collection. */

	  } while (NOTEID_CATEGORY & IdList[0]);

	  if (ln_rc = NSFNoteOpen(LN_DB_HANDLE(NOTESVIEW,view), IdList[0], 0, &hNote))
	  {
		 DEBUG(("Notes::View object returning error %d at line %d\n", ln_rc, __LINE__));
		 LN_SET_IVX(view, ln_rc);
		 XSRETURN_NOT_OK;
	  }

      LN_PUSH_NEW_OBJ( "Notes::Document", view );
      LN_INIT_OBJ_STRUCT(NOTESDOCUMENT, ln_obj);
      DEBUG(("Setting Notes::Document NOTEHANDLE to %ld\n", hNote));
      LN_SET_NOTE_HANDLE(NOTESDOCUMENT, ln_obj, hNote);
      DEBUG(("Setting Notes::View NOTEPTR to %ld\n", NotesRead));
      LN_SET_NOTE_PTR(NOTESVIEW, view, NotesRead);
      LN_SET_OK( ln_obj );
      XSRETURN( 1 );


void
get_next_document( view )
      LN_View     * view;
   PREINIT:
      d_LN_XSVARS;
      NOTEHANDLE           hNote = NULLHANDLE;
      COLLECTIONPOSITION   CollPosition;    /* position within collection */
	  HANDLE               hBuffer;         /* handle to buffer of note ids */
	  NOTEID             * IdList;          /* pointer to a note id */
	  DWORD                EntriesFound;    /* number of entries found */
	  DWORD                NotesRead = 0;   /* number of documents found */
	  DWORD                SkipCount;       /* number of documents to skip */
	  WORD                 SignalFlag;      /* signal and share warning flags */
	  HCOLLECTION          hCollection;     /* collection handle */
      STATUS               ln_rc;
   ALIAS:
      GetFirstDocument = 0
   PPCODE:
      if ( LN_IS_NOT_OK(view) )
      {
		  DEBUG(("Notes::View object is not OK at line %d\n", __LINE__));
		  XSRETURN_NOT_OK;
	  }

	  hCollection = LN_HCOLLECTION(NOTESVIEW, view);
	  SkipCount = (DWORD) LN_NOTE_PTR(NOTESVIEW, view);
	  DEBUG(("Current Notes::View Pointer = %ld\n", SkipCount));

	  /* Set up the data structure, COLLECTIONPOSITION, that controls where in
	     the collection we will begin when we read the collection.  Specify that we
	  	 want to start at the beginning. */

	  CollPosition.Level = 0;
	  CollPosition.Tumbler[0] = 0;

	  do
	  {
		  if ( ln_rc = NIFReadEntries(
						hCollection,        /* handle to this collection */
						&CollPosition,      /* where to start in collection */
						NAVIGATE_NEXT,      /* order to use when skipping */
						SkipCount + 1,      /* number to skip */
						NAVIGATE_NEXT,      /* order to use when reading */
						1,                  /* max number to read */
						READ_MASK_NOTEID,   /* info we want */
						&hBuffer,           /* handle to info buffer */
						NULL,               /* length of info buffer */
						NULL,               /* entries skipped */
						&EntriesFound,      /* entries read */
						&SignalFlag))       /* share warning and more signal flag */
		  {
			 DEBUG(("Notes::Document object returning error %d at line %d\n", ln_rc, __LINE__));
			 LN_SET_IVX(view, ln_rc);
			 XSRETURN_NOT_OK;
		  }

		  NotesRead++;


		  /* Check to make sure there was a buffer of information returned.
		  (We would crash if we tried to proceed with a null buffer.) */

		  if (hBuffer == NULLHANDLE)
		  {
			 DEBUG(("Notes::View object returning End of Collection reached at line %d\n", __LINE__));
			 XSRETURN_UNDEF;
		  }

		  /* Lock down (freeze the location) of the buffer of entry IDs. Cast
		  the resulting pointer to the type we need. */

		  IdList = (NOTEID *) OSLockObject (hBuffer);

		  DEBUG(("GetNextDocument() - Note ID is: %08lX\n", IdList[0]));

		  /* Unlock the list of IDs. */

		  OSUnlockObject (hBuffer);

		  /* Free the memory allocated by NIFReadEntries. */

		  OSMemFree (hBuffer);

		  /* Don't use a note ID if it is a "dummy" ID that
			 stands for a category in the collection. */

	  } while (NOTEID_CATEGORY & IdList[0]);

	  if (ln_rc = NSFNoteOpen(LN_DB_HANDLE(NOTESVIEW,view), IdList[0], 0, &hNote))
	  {
		 DEBUG(("Notes::View object returning error %d at line %d\n", ln_rc, __LINE__));
		 LN_SET_IVX(view, ln_rc);
		 XSRETURN_NOT_OK;
	  }

      LN_PUSH_NEW_OBJ( "Notes::Document", view );
      LN_INIT_OBJ_STRUCT(NOTESDOCUMENT, ln_obj);
      DEBUG(("Setting Notes::Document NOTEHANDLE to %ld\n", hNote));
      LN_SET_NOTE_HANDLE(NOTESDOCUMENT, ln_obj, hNote);
      DEBUG(("Setting Notes::View NOTEPTR to %ld\n", NotesRead + SkipCount));
      LN_SET_NOTE_PTR(NOTESVIEW, view, NotesRead + SkipCount);
      LN_SET_OK( ln_obj );
      XSRETURN( 1 );

void
get_nth_document( view, index = 1 )
      LN_View     * view;
      long        index;
   PREINIT:
      d_LN_XSVARS;
      NOTEHANDLE           hNote = NULLHANDLE;
      COLLECTIONPOSITION   CollPosition;    /* position within collection */
	  HANDLE               hBuffer;         /* handle to buffer of note ids */
	  NOTEID             * IdList;          /* pointer to a note id */
	  DWORD                EntriesFound;    /* number of entries found */
	  DWORD                NotesRead = 0;   /* number of documents found */
	  WORD                 SignalFlag;      /* signal and share warning flags */
	  HCOLLECTION          hCollection;     /* collection handle */
      STATUS               ln_rc;
   ALIAS:
      GetFirstDocument = 0
   PPCODE:
      if ( LN_IS_NOT_OK(view) )
      {
		  DEBUG(("Notes::View object is not OK at line %d\n", __LINE__));
		  XSRETURN_NOT_OK;
	  }

	  hCollection = LN_HCOLLECTION(NOTESVIEW, view);

	  /* Set up the data structure, COLLECTIONPOSITION, that controls where in
	     the collection we will begin when we read the collection.  Specify that we
	  	 want to start at the beginning. */

	  CollPosition.Level = 0;
	  CollPosition.Tumbler[0] = 0;

	  do
	  {
		  if ( ln_rc = NIFReadEntries(
						hCollection,        /* handle to this collection */
						&CollPosition,      /* where to start in collection */
						NAVIGATE_NEXT,      /* order to use when skipping */
						(DWORD)index,       /* number to skip */
						NAVIGATE_NEXT,      /* order to use when reading */
						1,                  /* max number to read */
						READ_MASK_NOTEID,   /* info we want */
						&hBuffer,           /* handle to info buffer */
						NULL,               /* length of info buffer */
						NULL,               /* entries skipped */
						&EntriesFound,      /* entries read */
						&SignalFlag))       /* share warning and more signal flag */
		  {
			 DEBUG(("Notes::Document object returning error %d at line %d\n", ln_rc, __LINE__));
			 LN_SET_IVX(view, ln_rc);
			 XSRETURN_NOT_OK;
		  }

		  NotesRead++;


		  /* Check to make sure there was a buffer of information returned.
		  (We would crash if we tried to proceed with a null buffer.) */

		  if (hBuffer == NULLHANDLE)
		  {
			 DEBUG(("Notes::View object returning End of Collection reached at line %d\n", __LINE__));
			 XSRETURN_UNDEF;
		  }

		  /* Lock down (freeze the location) of the buffer of entry IDs. Cast
		  the resulting pointer to the type we need. */

		  IdList = (NOTEID *) OSLockObject (hBuffer);

		  DEBUG(("GetNthDocument() - Note ID is: %08lX\n", IdList[0]));

		  /* Unlock the list of IDs. */

		  OSUnlockObject (hBuffer);

		  /* Free the memory allocated by NIFReadEntries. */

		  OSMemFree (hBuffer);

		  /* Don't use a note ID if it is a "dummy" ID that
			 stands for a category in the collection. */

	  } while (NOTEID_CATEGORY & IdList[0]);

	  if (ln_rc = NSFNoteOpen(LN_DB_HANDLE(NOTESVIEW,view), IdList[0], 0, &hNote))
	  {
		 DEBUG(("Notes::View object returning error %d at line %d\n", ln_rc, __LINE__));
		 LN_SET_IVX(view, ln_rc);
		 XSRETURN_NOT_OK;
	  }

      LN_PUSH_NEW_OBJ( "Notes::Document", view );
      LN_INIT_OBJ_STRUCT(NOTESDOCUMENT, ln_obj);
      DEBUG(("Setting Notes::Document NOTEHANDLE to %ld\n", hNote));
      LN_SET_NOTE_HANDLE(NOTESDOCUMENT, ln_obj, hNote);
      DEBUG(("Setting Notes::View NOTEPTR to %ld\n", NotesRead + index));
      LN_SET_NOTE_PTR(NOTESVIEW, view, NotesRead + index);
      LN_SET_OK( ln_obj );
      XSRETURN( 1 );


void
get_last_document( view )
      LN_View     * view;
   PREINIT:
      d_LN_XSVARS;
      NOTEHANDLE           hNote = NULLHANDLE;
      COLLECTIONPOSITION   CollPosition;    /* position within collection */
	  HANDLE               hBuffer;         /* handle to buffer of note ids */
	  NOTEID             * IdList;          /* pointer to a note id */
	  DWORD                EntriesSkipped;  /* number of entries skipped */
	  WORD                 SignalFlag;      /* signal and share warning flags */
	  HCOLLECTION          hCollection;     /* collection handle */
      STATUS               ln_rc;
   ALIAS:
      GetFirstDocument = 0
   PPCODE:
      if ( LN_IS_NOT_OK(view) )
      {
		  DEBUG(("Notes::View object is not OK at line %d\n", __LINE__));
		  XSRETURN_NOT_OK;
	  }

	  hCollection = LN_HCOLLECTION(NOTESVIEW, view);

	  /* Set up the data structure, COLLECTIONPOSITION, that controls where in
	     the collection we will begin when we read the collection.  Specify that we
	  	 want to start at the beginning. */

	  CollPosition.Level = 0;
	  CollPosition.Tumbler[0] = 0;

	  do
	  {
		  if ( ln_rc = NIFReadEntries(
						hCollection,        /* handle to this collection */
						&CollPosition,      /* where to start in collection */
						NAVIGATE_NEXT | NAVIGATE_CONTINUE,      /* order to use when skipping */
						MAXDWORD,           /* number to skip */
						NAVIGATE_CURRENT,   /* order to use when reading */
						1,                  /* max number to read */
						READ_MASK_NOTEID,   /* info we want */
						&hBuffer,           /* handle to info buffer */
						NULL,               /* length of info buffer */
						&EntriesSkipped,    /* entries skipped */
						NULL,               /* entries read */
						&SignalFlag))       /* share warning and more signal flag */
		  {
			 DEBUG(("Notes::Document object returning error %d at line %d\n", ln_rc, __LINE__));
			 LN_SET_IVX(view, ln_rc);
			 XSRETURN_NOT_OK;
		  }

		  /* Check to make sure there was a buffer of information returned.
		  (We would crash if we tried to proceed with a null buffer.) */

		  if (hBuffer == NULLHANDLE)
		  {
			 DEBUG(("Notes::View object returning End of Collection reached at line %d\n", __LINE__));
			 XSRETURN_UNDEF;
		  }

		  /* Lock down (freeze the location) of the buffer of entry IDs. Cast
		  the resulting pointer to the type we need. */

		  IdList = (NOTEID *) OSLockObject (hBuffer);

		  DEBUG(("GetLastDocument() - Note ID is: %08lX\n", IdList[0]));

		  /* Unlock the list of IDs. */

		  OSUnlockObject (hBuffer);

		  /* Free the memory allocated by NIFReadEntries. */

		  OSMemFree (hBuffer);

		  /* Don't use a note ID if it is a "dummy" ID that
			 stands for a category in the collection. */

	  } while (NOTEID_CATEGORY & IdList[0]);

	  if (ln_rc = NSFNoteOpen(LN_DB_HANDLE(NOTESVIEW,view), IdList[0], 0, &hNote))
	  {
		 DEBUG(("Notes::View object returning error %d at line %d\n", ln_rc, __LINE__));
		 LN_SET_IVX(view, ln_rc);
		 XSRETURN_NOT_OK;
	  }

      LN_PUSH_NEW_OBJ( "Notes::Document", view );
      LN_INIT_OBJ_STRUCT(NOTESDOCUMENT, ln_obj);
      DEBUG(("Setting Notes::Document NOTEHANDLE to %ld\n", hNote));
      LN_SET_NOTE_HANDLE(NOTESDOCUMENT, ln_obj, hNote);
      DEBUG(("Setting Notes::View NOTEPTR to %ld\n", EntriesSkipped));
      LN_SET_NOTE_PTR(NOTESVIEW, view, EntriesSkipped);
      LN_SET_OK( ln_obj );
      XSRETURN( 1 );


MODULE = Notes::Document   PACKAGE = Notes::Document


void
new ( CLASS, db )
      char        * CLASS;
      LN_Database * db;
   PREINIT:
      d_LN_XSVARS;
      NOTEHANDLE           hNote = NULLHANDLE;
      DBHANDLE             hDb   = NULLHANDLE;
      STATUS               ln_rc = NOERROR;
   PPCODE:
   	  hDb = LN_DB_HANDLE(NOTESDATABASE,db);
	  if (ln_rc = NSFNoteCreate(hDb, &hNote))
	  {
		 DEBUG(("Notes::Document object returning error %d at line %d\n", ln_rc, __LINE__));
		 XSRETURN_NOT_OK;
	  }

      LN_PUSH_NEW_OBJ( "Notes::Document", db );
      LN_INIT_OBJ_STRUCT(NOTESDOCUMENT, ln_obj);
      DEBUG(("Setting Notes::Document NOTEHANDLE to %ld\n", hNote));
      LN_SET_NOTE_HANDLE(NOTESDOCUMENT, ln_obj, hNote);
      LN_SET_OK( ln_obj );
      XSRETURN( 1 );


void
DESTROY( doc )
      LN_Document *   doc;
   PPCODE:
      NSFNoteClose(LN_NOTE_HANDLE(NOTESDOCUMENT, doc));
      LN_FREE_OBJ_STRUCT(NOTESDOCUMENT, doc);
      //LN_SET_PARENT_IVX( db, ln_rc );
      XSRETURN( 0 );

void
has_item( doc, itemname )
      LN_Document *   doc;
	  char        *   itemname;
   PREINIT:
      NOTEHANDLE      hNote = NULLHANDLE;
   PPCODE:
   	  if ( LN_IS_NOT_OK(doc) )
	  {
		  DEBUG(("Notes::Document object was not OK at line %d\n", __LINE__));
	      XSRETURN_NOT_OK;
	  }
	  if (itemname == NULL)
	  {
		  XSRETURN_NOT_OK;
      }
      hNote = LN_NOTE_HANDLE(NOTESDOCUMENT, doc);
	  if(NSFItemIsPresent(hNote, itemname, (WORD)strlen(itemname)))
	  {
		  XSRETURN_YES;
  	  }
  	  else
  	  {
		  XSRETURN_NO;
	  }

void
get_item_value( doc, itemname )
	  LN_Document *   doc;
	  char        *   itemname;
   PREINIT:
      NOTEHANDLE      hNote = NULLHANDLE;
      RANGE           field_range;
      BLOCKID         field_block;
	  DWORD           field_length,text_length;
      WORD            field_type;
	  char        *   field_text;
	  char far    *   pData;
	  HANDLE          text_buffer;
      char        *   text_ptr;
	  WORD            counter;
	  WORD            num_entries;
	  WORD			  field_len;
	  WORD			  i;
	  NUMBER	      number_value;
	  TIMEDATE		  timedate_value;
	  STATUS		  ln_rc = NOERROR;
   PPCODE:
   	  if ( LN_IS_NOT_OK(doc) )
	  {
		  DEBUG(("Notes::Document object was not OK at line %d\n", __LINE__));
	      XSRETURN_NOT_OK;
	  }
	  if (itemname == NULL)
	  {
		  XSRETURN_NOT_OK;
      }
      hNote = LN_NOTE_HANDLE(NOTESDOCUMENT, doc);

      ln_rc = NSFItemInfo (
	              hNote,               		/* note handle */
	              itemname,            		/* field we want */
	              (WORD)strlen(itemname),	/* length of above */
	              NULL,                		/* full field (return) */
	              &field_type,         		/* field type (return) */
	              &field_block,        		/* field contents (return) */
                  &field_length);      		/* field length (return) */

      DEBUG(("Field type is: %ld, length: %ld\n", field_type, field_length));

	  switch(field_type)
	  {
		  case TYPE_TEXT:
		  	Newz(1, field_text, field_length, char);
		  	if(field_text == (char *) NULL)
		  	{
		  		DEBUG(("Notes::Document object returning memory error (Newz()) at line %d\n", ln_rc, __LINE__));
		  		XSRETURN_NOT_OK;
		  	}

			NSFItemGetText (
			               hNote,
			               itemname,
			               field_text,
                           (WORD)(field_length - 1));

	        XPUSHs(sv_2mortal(newSVpv(field_text,0)));
	        Safefree(field_text);
	        XSRETURN(1);
	        break;

	      case TYPE_TEXT_LIST:
	        Newz(1, field_text, field_length, char);
			if(field_text == (char *) NULL)
			{
				DEBUG(("Notes::Document object returning memory error (Newz()) at line %d\n", ln_rc, __LINE__));
				XSRETURN_NOT_OK;
			}

			num_entries = NSFItemGetTextListEntries(hNote, itemname);
			for (counter = 0; counter < num_entries; counter++)
			{
				field_len = NSFItemGetTextListEntry (
			   			    hNote,
					    	itemname,
						    counter,  /* which field to get */
						    field_text,
				            (WORD)(field_length - 1));
				XPUSHs(sv_2mortal(newSVpv(field_text,0)));
				Zero(field_text, field_length, char);
			}
			Safefree(field_text);
			XSRETURN(num_entries);
	        break;

	      case TYPE_NUMBER:
	        if (NSFItemGetNumber (hNote, itemname, &number_value))
	        {
				XSRETURN_NV((NV) number_value);
			}
			else
			{
				XSRETURN_NOT_OK;
			}
			break;

		  case TYPE_NUMBER_RANGE:
			pData = OSLockBlock(char, field_block);
  			pData += sizeof(WORD);
  			memcpy(&field_range, pData, (int) sizeof(RANGE));
  			pData += sizeof(RANGE);
  			for(i=0;i < field_range.ListEntries;i++)
  			{
				memcpy (&number_value, pData, (int) sizeof(NUMBER));
        		pData += sizeof(NUMBER);
        		XPUSHs(sv_2mortal(newSVnv((NV)number_value)));
		    }
			OSUnlockBlock(field_block);
			XSRETURN(field_range.ListEntries);
			break;

		  case TYPE_TIME:
		  	Newz(1, field_text, MAXALPHATIMEDATE + 1, char);
			if(field_text == (char *) NULL)
			{
				DEBUG(("Notes::Document object returning memory error (Newz()) at line %d\n", ln_rc, __LINE__));
				XSRETURN_NOT_OK;
			}
		    field_len = NSFItemConvertToText (
			                hNote,
			                itemname,
			                field_text,
			                (WORD)(MAXALPHATIMEDATE),
                		    ';'); /* multi-value separator */
            XPUSHs(sv_2mortal(newSVpv(field_text,0)));
            Safefree(field_text);
            XSRETURN(1);
            break;

          case TYPE_TIME_RANGE:
            Newz(1, field_text, MAXALPHATIMEDATE + 1, char);
            if(field_text == (char *) NULL)
			{
				DEBUG(("Notes::Document object returning memory error (Newz()) at line %d\n", ln_rc, __LINE__));
				XSRETURN_NOT_OK;
			}
           	pData = OSLockBlock(char, field_block);
			pData += sizeof(WORD);
			memcpy(&field_range, pData, (int) sizeof(RANGE));
			pData += sizeof(RANGE);
			for(i=0;i < field_range.ListEntries;i++)
			{
				memcpy (&timedate_value, pData, (int) sizeof(TIMEDATE));
				pData += sizeof(TIMEDATE);
				if (ln_rc = ConvertTIMEDATEToText(NULL, NULL,
				                       &timedate_value, field_text,
                                       MAXALPHATIMEDATE, &field_len))
                {
					LN_SET_IVX(doc, (IV)ln_rc);
					XSRETURN_NOT_OK;
				}
				XPUSHs(sv_2mortal(newSVpv(field_text,0)));
				Zero(field_text, MAXALPHATIMEDATE + 1, char);
			}
			OSUnlockBlock(field_block);
			Safefree(field_text);
			XSRETURN(field_range.ListEntries);
			break;

		  case TYPE_COMPOSITE:	/* Rich Text Field */
			if (ln_rc = ConvertItemToText (
			                field_block,     /* BLOCKID of field */
			                field_length,    /* length of field */
			                "\n",            /* line separator for output */
			                80,              /* line length in output */
			                &text_buffer,    /* output buffer */
			                &text_length,    /* output length */
			                TRUE))           /* strip tabs */

            {
				LN_SET_IVX(doc, (IV)ln_rc);
				XSRETURN_NOT_OK;
			}
			/* Lock the memory allocated for the text buffer. Cast the resulting
			pointer to the type we need. */

	        text_ptr = (char *) OSLockObject (text_buffer);

			Newz(1, field_text, text_length, char);
			if(field_text == (char *) NULL)
			{
				DEBUG(("Notes::Document object returning memory error (Newz()) at line %d\n", ln_rc, __LINE__));
				XSRETURN_NOT_OK;
			}
	        memcpy (field_text, text_ptr, (short) text_length);

			/* Unlock and free the text buffer. */

        	OSUnlockObject (text_buffer);
        	OSMemFree (text_buffer);
			XPUSHs(sv_2mortal(newSVpv(field_text,0)));
			Safefree(field_text);
			XSRETURN(1);
			break;

      }
      XSRETURN_NOT_OK;

void
replace_item_value( doc, itemname, value, ...)
	  LN_Document *   doc;
	  char        *   itemname;
	  SV		  *	  value;
   PREINIT:
      SV          **  entry;
	  AV	      *   array;
	  HV          *   hash;
      NOTEHANDLE      hNote = NULLHANDLE;
      char            temp[MAXALPHANUMBER];
      BLOCKID         field_block;
      WORD            field_type;
      DWORD           field_length;
	  I32             num_entries;
	  WORD			  i = 0, cnt;
	  NUMBER      *   number_list;
	  NUMBER	      number_value;
	  TIMEDATE		  timedate_value;
	  STATUS		  ln_rc = NOERROR;
   PPCODE:
   	  if( LN_IS_NOT_OK(doc) )
	  {
		  DEBUG(("Notes::Document object was not OK at line %d\n", __LINE__));
	      XSRETURN_NOT_OK;
	  }
	  if(itemname == NULL)
	  {
		  XSRETURN_NOT_OK;
      }
      if(!SvOK(value))
	  {
	  	  XSRETURN_NOT_OK;
	  }

      hNote = LN_NOTE_HANDLE(NOTESDOCUMENT, doc);

      ln_rc = NSFItemInfo (
	  	              hNote,               		/* note handle */
	  	              itemname,            		/* field we want */
	  	              (WORD)strlen(itemname),	/* length of above */
	  	              NULL,                		/* full field (return) */
	  	              &field_type,         		/* field type (return) */
	  	              &field_block,        		/* field contents (return) */
                      &field_length);      		/* field length (return) */
      if(ln_rc && ln_rc != ERR_ITEM_NOT_FOUND)
      {
		  DEBUG(("Notes::Document object returning error %d at line %d\n", ln_rc, __LINE__));
		  LN_SET_IVX(doc, (IV)ln_rc);
		  XSRETURN_NOT_OK;
	  }

	  printf("SvTYPE is: %d\n", SvTYPE(value));

	  while(SvTYPE(value) == SVt_RV)
	  	value = (SV*)SvRV(value);

 	  switch(SvTYPE(value))
 	  {
		  case SVt_NULL:  DEBUG(("Setting field %s to empty string from undef (SVt_NULL)\n", itemname));
		                  if(ln_rc = NSFItemSetText ( hNote,
                		   					itemname,
                							"",
                							MAXWORD))
                		  {
							  DEBUG(("Notes::Document object returning error %d at line %d\n", ln_rc, __LINE__));
					  		  LN_SET_IVX(doc, (IV)ln_rc);
					  		  XSRETURN_NOT_OK;
	  					  }
		  				  break;

		  case SVt_IV:
		  case SVt_PVIV:  if(field_type == TYPE_NUMBER || field_type == TYPE_NUMBER_RANGE || field_type == TYPE_INVALID_OR_UNKNOWN)
		  			      {
							  if(!SvIOK(value))
							   	break;

							  DEBUG(("Setting field %s to number from (SVt_IV or SVt_PVIV)\n", itemname));
							  if (ln_rc = NSFItemSetNumber (hNote, itemname, (NUMBER *)SvIVX(value)))
		  			      	  {
								DEBUG(("Notes::Document object returning error %d at line %d\n", ln_rc, __LINE__));
							  	LN_SET_IVX(doc, (IV)ln_rc);
							  	XSRETURN_NOT_OK;
						  	  }
						  }
						  else if(field_type == TYPE_TEXT || field_type == TYPE_TEXT_LIST)
						  {
							  if(!SvPOK(value))
							   	break;

							  DEBUG(("Setting field %s to text from (SVt_IV or SVt_PVIV)\n", itemname));
							  sprintf(temp, "%ld", (long)SvIV(value));
							  if(ln_rc = NSFItemSetText ( hNote,
							  					itemname,
							  					temp,
							  					MAXWORD))
							  {
								  DEBUG(("Notes::Document object returning error %d at line %d\n", ln_rc, __LINE__));
							  	  LN_SET_IVX(doc, (IV)ln_rc);
							  	  XSRETURN_NOT_OK;
	  					      }
					      }
					      else
					      	warn("Can't set field %s value - type mismatch", itemname);
		  				  break;

	      case SVt_NV:
	      case SVt_PVNV:  if(field_type == TYPE_NUMBER || field_type == TYPE_NUMBER_RANGE || field_type == TYPE_INVALID_OR_UNKNOWN)
                          {
							  if(!SvNOK(value))
							   	break;

							  DEBUG(("Setting field %s to number from (SVt_NV or SVt_PVNV)\n", itemname));
							  number_value = (NUMBER)SvNV(value);
							  if (ln_rc = NSFItemSetNumber (hNote, itemname, &number_value))
		  			      	  {
								DEBUG(("Notes::Document object returning error %d at line %d\n", ln_rc, __LINE__));
							  	LN_SET_IVX(doc, (IV)ln_rc);
							  	XSRETURN_NOT_OK;
						  	  }
						  }
						  else if(field_type == TYPE_TEXT || field_type == TYPE_TEXT_LIST)
						  {
							  if(!SvPOK(value))
							   	break;

							  DEBUG(("Setting field %s to text from (SVt_NV or SVt_PVNV)\n", itemname));
							  sprintf(temp, "%lf", (NUMBER)SvNV(value));
							  if(ln_rc = NSFItemSetText ( hNote,
							  					itemname,
							  					temp,
							  					MAXWORD))
							  {
								  DEBUG(("Notes::Document object returning error %d at line %d\n", ln_rc, __LINE__));
							  	  LN_SET_IVX(doc, (IV)ln_rc);
							  	  XSRETURN_NOT_OK;
	  					      }
					      }
					      else
					      	warn("Can't set field %s value - type mismatch", itemname);
		  				  break;

	      case SVt_PV:    if(!SvPOK(value))
							  	break;

	      				  if(field_type == TYPE_TIME || field_type == TYPE_TIME_RANGE || field_type == TYPE_INVALID_OR_UNKNOWN)
	      				  {
							  ln_rc = ConvertTextToTIMEDATE(NULL,
							                  NULL,
											  &SvPVX(value),
											  (WORD)SvCUR(value),
										      &timedate_value);
							  if(ln_rc == NOERROR)
							  {
								  DEBUG(("Setting field %s to time/date from (SVt_PV)\n", itemname));
								  if (ln_rc = NSFItemSetTime (hNote, itemname, &timedate_value))
								  {
									  DEBUG(("Notes::Document object returning error %d at line %d\n", ln_rc, __LINE__));
									  LN_SET_IVX(doc, (IV)ln_rc);
									  XSRETURN_NOT_OK;
								  }
								  else
								  {
									  XSRETURN_YES;
							      }
							  }
							  else
							  {
							  	if(ln_rc == ERR_TDI_CONV)
							  	{
									if(field_type != TYPE_INVALID_OR_UNKNOWN)
									{
										warn("Can't set field %s value - type mismatch", itemname);
										break;
									}
								}
							  }
					      }
						  if(field_type == TYPE_TEXT || field_type == TYPE_TEXT_LIST || field_type == TYPE_INVALID_OR_UNKNOWN)
						  {
							  DEBUG(("Setting field %s to text from (SVt_PV)\n", itemname));
							  if(ln_rc = NSFItemSetText ( hNote,
												itemname,
												SvPVX(value),
												MAXWORD))
							  {
								  DEBUG(("Notes::Document object returning error %d at line %d\n", ln_rc, __LINE__));
								  LN_SET_IVX(doc, (IV)ln_rc);
								  XSRETURN_NOT_OK;
							  }
						  }
						  else
							warn("Can't set field %s value - type mismatch", itemname);
					      break;

	      case SVt_PVAV:  array = (AV *) value;

	      				  num_entries = av_len(array) + 1;
	      				  Newz(1, number_list, 1, NUMBER);

						  if(field_type == TYPE_NUMBER || field_type == TYPE_NUMBER_RANGE)
						  {
							  DEBUG(("Setting field %s to number list from (SVt_AV)\n", itemname));

							  for(cnt = 0; cnt < num_entries; cnt++)
							  {
								  entry = av_fetch(array, cnt, 0);
								  if(!entry || (!SvNOK(*entry) && !SvIOK(*entry)))
										continue;

								  Renew(number_list, i + 1, NUMBER);
								  if(SvIOK(*entry))
								  {
									number_value = (NUMBER)SvIV(*entry);
								  	number_list[i] = number_value;
							  	  }
								  else
								    number_list[i] = (NUMBER)SvNV(*entry);
								  i++;
							  }
							  printf("Item 0 is: %lf\n", number_list[0]);
							  Safefree(number_list);
					  	  }
					  	  break;

					      if(field_type == TYPE_TEXT || field_type == TYPE_TEXT_LIST || field_type == TYPE_INVALID_OR_UNKNOWN)
						  {
							  DEBUG(("Setting field %s to text list from (SVt_AV)\n", itemname));
							  for(cnt = 0; cnt < num_entries; cnt++)
							  {
								  entry = av_fetch(array, cnt, 0);

								  if(!entry || !SvPOK(*entry))
								  	continue;

								  if(!i)
								  {
									  /* First time through */
									  if (ln_rc = NSFItemCreateTextList(hNote,
															 itemname,
															 SvPVX(*entry),
															 MAXWORD))
									  {
										  DEBUG(("Notes::Document object returning error %d at line %d\n", ln_rc, __LINE__));
										  LN_SET_IVX(doc, (IV)ln_rc);
										  XSRETURN_NOT_OK;
									  }
									  i++;
								  }
								  else
								  {
									  if (ln_rc = NSFItemAppendTextList (hNote,
															 itemname,
															 SvPVX(*entry),
															 MAXWORD,
															 TRUE))
									  {
										  DEBUG(("Notes::Document object returning error %d at line %d\n", ln_rc, __LINE__));
										  LN_SET_IVX(doc, (IV)ln_rc);
										  XSRETURN_NOT_OK;
									  }
								  }
							  }
						  }
		  				  break;

	      case SVt_PVHV:  printf("Hash\n");
		  				  break;
	      default:	      XSRETURN_NOT_OK;
		                  break;
      }
      XSRETURN_YES;

	  /*

	      case TYPE_TEXT_LIST:
	        Newz(1, field_text, field_length, char);
			if(field_text == (char *) NULL)
			{
				DEBUG(("Notes::Document object returning memory error (Newz()) at line %d\n", ln_rc, __LINE__));
				XSRETURN_NOT_OK;
			}

			num_entries = NSFItemGetTextListEntries(hNote, itemname);
			for (counter = 0; counter < num_entries; counter++)
			{
				field_len = NSFItemGetTextListEntry (
			   			    hNote,
					    	itemname,
						    counter,
						    field_text,
				            (WORD)(field_length - 1));
				XPUSHs(sv_2mortal(newSVpv(field_text,0)));
				Zero(field_text, field_length, char);
			}
			Safefree(field_text);
			XSRETURN(num_entries);
	        break;

	      case TYPE_NUMBER:
	        if (NSFItemGetNumber (hNote, itemname, &number_value))
	        {
				XSRETURN_NV((NV) number_value);
			}
			else
			{
				XSRETURN_NOT_OK;
			}
			break;

		  case TYPE_NUMBER_RANGE:
			pData = OSLockBlock(char, field_block);
  			pData += sizeof(WORD);
  			memcpy(&field_range, pData, (int) sizeof(RANGE));
  			pData += sizeof(RANGE);
  			for(i=0;i < field_range.ListEntries;i++)
  			{
				memcpy (&number_value, pData, (int) sizeof(NUMBER));
        		pData += sizeof(NUMBER);
        		XPUSHs(sv_2mortal(newSVnv((NV)number_value)));
		    }
			OSUnlockBlock(field_block);
			XSRETURN(field_range.ListEntries);
			break;

		  case TYPE_TIME:
		  	Newz(1, field_text, MAXALPHATIMEDATE + 1, char);
			if(field_text == (char *) NULL)
			{
				DEBUG(("Notes::Document object returning memory error (Newz()) at line %d\n", ln_rc, __LINE__));
				XSRETURN_NOT_OK;
			}
		    field_len = NSFItemConvertToText (
			                hNote,
			                itemname,
			                field_text,
			                (WORD)(MAXALPHATIMEDATE),
                		    ';');
            XPUSHs(sv_2mortal(newSVpv(field_text,0)));
            Safefree(field_text);
            XSRETURN(1);
            break;

          case TYPE_TIME_RANGE:
            Newz(1, field_text, MAXALPHATIMEDATE + 1, char);
            if(field_text == (char *) NULL)
			{
				DEBUG(("Notes::Document object returning memory error (Newz()) at line %d\n", ln_rc, __LINE__));
				XSRETURN_NOT_OK;
			}
           	pData = OSLockBlock(char, field_block);
			pData += sizeof(WORD);
			memcpy(&field_range, pData, (int) sizeof(RANGE));
			pData += sizeof(RANGE);
			for(i=0;i < field_range.ListEntries;i++)
			{
				memcpy (&timedate_value, pData, (int) sizeof(TIMEDATE));
				pData += sizeof(TIMEDATE);
				if (ln_rc = ConvertTIMEDATEToText(NULL, NULL,
				                       &timedate_value, field_text,
                                       MAXALPHATIMEDATE, &field_len))
                {
					LN_SET_IVX(doc, (IV)ln_rc);
					XSRETURN_NOT_OK;
				}
				XPUSHs(sv_2mortal(newSVpv(field_text,0)));
				Zero(field_text, MAXALPHATIMEDATE + 1, char);
			}
			OSUnlockBlock(field_block);
			Safefree(field_text);
			XSRETURN(field_range.ListEntries);
			break;
      }*/
      XSRETURN_NOT_OK;

void
remove_item( doc, itemname )
	  LN_Document *   doc;
	  char        *   itemname;
   PREINIT:
      NOTEHANDLE      hNote = NULLHANDLE;
	  STATUS		  ln_rc = NOERROR;
   PPCODE:
   	  if ( LN_IS_NOT_OK(doc) )
	  {
		  DEBUG(("Notes::Document object was not OK at line %d\n", __LINE__));
	      XSRETURN_NOT_OK;
	  }
	  if (itemname == NULL)
	  {
		  XSRETURN_NOT_OK;
      }
      hNote = LN_NOTE_HANDLE(NOTESDOCUMENT, doc);

	  if(ln_rc = NSFItemDelete(hNote, itemname, (WORD) strlen(itemname)))
	  {
		  DEBUG(("Notes::View object returning error %d at line %d\n", ln_rc, __LINE__));
		  LN_SET_IVX(doc, ln_rc);
		  XSRETURN_NOT_OK;
      }
      else
      {
		  XSRETURN_YES;
      }

void
save( doc, force = FALSE )
	  LN_Document *   doc;
	  BOOL            force;
   PREINIT:
      NOTEHANDLE      hNote = NULLHANDLE;
	  STATUS		  ln_rc = NOERROR;
	  WORD            update_flags = 0;
   PPCODE:
   	  if ( LN_IS_NOT_OK(doc) )
	  {
		  DEBUG(("Notes::Document object was not OK at line %d\n", __LINE__));
	      XSRETURN_NOT_OK;
	  }
      hNote = LN_NOTE_HANDLE(NOTESDOCUMENT, doc);

	  if(force)
	  	update_flags = UPDATE_FORCE;

	  if(ln_rc = NSFNoteUpdate(hNote, update_flags))
	  {
		  DEBUG(("Notes::View object returning error %d at line %d\n", ln_rc, __LINE__));
		  LN_SET_IVX(doc, ln_rc);
		  XSRETURN_NOT_OK;
      }
      else
      {
		  XSRETURN_YES;
      }

double
constant(sv,arg)
    PREINIT:
	STRLEN   len;
    INPUT:
	SV     * sv
	char   * s = SvPV(sv, len);
	int		 arg
    CODE:
	RETVAL = constant(s,len,arg);
    OUTPUT:
	RETVAL