#define BLOCK Perl_BLOCK

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "notesviewcolumn.h"

MODULE = Notes::ViewColumn   PACKAGE = Notes::View

PROTOTYPES: DISABLE


void
columns( view, index = 1 )
      LN_View *   view;
      UV	      index;
   PREINIT:
      d_LN_XSVARS;
      NOTEHANDLE           hNote = NULLHANDLE;
      STATUS               ln_rc   = NOERROR;
	  HV  			     * ln_hash = (HV *) NULL;
	  SV 			     * sv      = (SV *) NULL;
	  WORD			       wDataType;
	  DWORD			       dwLength;
	  BLOCKID              ValueBlockID;
	  char                 szData[128];
	  char far           * pData;
	  char far           * pPackedData;
	  VIEW_FORMAT_HEADER * pHeaderFormat;
	  VIEW_TABLE_FORMAT  * pTableFormat;
	  VIEW_TABLE_FORMAT2 * pTableFormat2;
	  VIEW_COLUMN_FORMAT * pColumnFormat;
	  VIEW_COLUMN_FORMAT * pColumnFormat2;
	  VIEW_FORMAT_HEADER   formatHeader;
	  VIEW_TABLE_FORMAT    tableFormat;
	  VIEW_TABLE_FORMAT2   tableFormat2;
	  VIEW_COLUMN_FORMAT   viewColumn;
	  VIEW_COLUMN_FORMAT   viewColumn2;
	  void               * tempPtr;
	  WORD                 wColumn;
	  char far           * pFormula;
	  char far           * pFormulaText, *pTemp;
	  WORD                 wFormulaTextLen;
      HANDLE               hFormulaText;
   PPCODE:

       ln_hash = (HV *)sv_2mortal((SV *)newHV());

	   if (ln_rc = NSFNoteOpen(LN_DB_HANDLE(NOTESVIEW,view), LN_NOTE_ID(NOTESVIEW,view), 0, &hNote))
       {
           DEBUG(("Notes::ViewColumn object returning error %d at line %d", ln_rc, __LINE__));
           DEBUG(("DBHANDLE = %ld, NOTEID = %ld", LN_DB_HANDLE(NOTESVIEW,view), LN_NOTE_ID(NOTESVIEW,view)));
           LN_SET_IVX(view, ln_rc);
	       XSRETURN_NOT_OK;
	   }

   	   ln_rc = NSFItemInfo(hNote,
	                            VIEW_VIEW_FORMAT_ITEM,
	                            sizeof(VIEW_VIEW_FORMAT_ITEM) - 1,
	                            NULL,
	                            &wDataType,
	                            &ValueBlockID,
	                            &dwLength);

	   if (ln_rc || wDataType != TYPE_VIEW_FORMAT)
	   {
		   DEBUG(("Notes::ViewColumn object returning error %d at line %d", ln_rc, __LINE__));
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
	       DEBUG(("Notes::ViewColumn object returning error %d at line %d", ln_rc, __LINE__));
	       OSUnlockBlock(ValueBlockID);
	       NSFNoteClose(hNote);
	       LN_SET_IVX(view, ln_rc);
           XSRETURN_NOT_OK;
       }

	   /*
	    *  Read the table format ( which includes the view format header )
	    */

	   if ((pHeaderFormat->ViewStyle & VIEW_CLASS_MASK) == VIEW_CLASS_TABLE)
	   {
	       tempPtr = pData;
	       ODSReadMemory( &tempPtr, _VIEW_TABLE_FORMAT, &tableFormat, 1 );
	       pTableFormat = &tableFormat;

	       /*
	        * Make sure requested column index exists.
	        */
	       if(index <= 0 || index > pTableFormat->Columns)
	       {
			    DEBUG(("Notes::ViewColumn object returning error %d at line %d", ln_rc, __LINE__));
			   	OSUnlockBlock(ValueBlockID);
			   	NSFNoteClose(hNote);
           		XSRETURN_NOT_OK;
		   }

	       pData += ODSLength(_VIEW_TABLE_FORMAT);  /* point past the table format */

	       /*
	        *  Get a pointer to the packed data, which is located after the
	        *  column format structures. This data does not need to be converted
	        *  into host-specific byte ordering
	        */

	       pPackedData = pData + (ODSLength(_VIEW_COLUMN_FORMAT) * pTableFormat->Columns);

	       /*
	        *  Now unpack and read the column data
	        *  Skip columns we are not interested in...
	        */

	       tempPtr = pData + (ODSLength(_VIEW_COLUMN_FORMAT) * (index - 1));
		   ODSReadMemory( &tempPtr, _VIEW_COLUMN_FORMAT, &viewColumn2, 1 );
		   pColumnFormat = &viewColumn2;

	       for (wColumn = 1; wColumn < index; wColumn++)
	       {
			   tempPtr = pData;
			   ODSReadMemory( &tempPtr, _VIEW_COLUMN_FORMAT, &viewColumn, 1 );
			   pColumnFormat2 = &viewColumn;

			   pData += ODSLength(_VIEW_COLUMN_FORMAT);

	           pPackedData += pColumnFormat2->ItemNameSize;
	           pPackedData += pColumnFormat2->TitleSize;
	           pPackedData += pColumnFormat2->FormulaSize;
	           pPackedData += pColumnFormat2->ConstantValueSize;
		   }

			   /*
	            *  Column number
	            */

		   	   sv = newSViv(wColumn);
		       SvREADONLY_on(sv);
		       hv_store(ln_hash, "Position", 8, sv, 0);

	           /*
	            * Print Item Name, then advance data pointer
	            * past it.
	            */

	           memmove(szData, pPackedData,pColumnFormat->ItemNameSize);
	           szData[pColumnFormat->ItemNameSize] = '\0';

	           sv = newSVpv(szData,0);
			   SvREADONLY_on(sv);
			   hv_store(ln_hash, "ItemName", 8, sv, 0);

	           pPackedData += pColumnFormat->ItemNameSize;

	           /*
	            * Get the Title string, then advance data pointer to next item.
	            */

	           memmove(szData, pPackedData, pColumnFormat->TitleSize);
	           szData[pColumnFormat->TitleSize] = '\0';

	           sv = newSVpv(szData,0);
			   SvREADONLY_on(sv);
			   hv_store(ln_hash, "Title", 5, sv, 0);

	           pPackedData += pColumnFormat->TitleSize;

               /*
	            * Get the column width.
	            */
			   sv = newSViv((IV)pColumnFormat->DisplayWidth);
			   SvREADONLY_on(sv);
			   hv_store(ln_hash, "Width", 5, sv, 0);

	           /*
	            * Get the formula, advance data ptr to next item.
	            */
			   szData[0]='\0';
	           pFormula = pPackedData;
	           pPackedData += pColumnFormat->FormulaSize;
	           if (pColumnFormat->FormulaSize != 0)
	           {
	              ln_rc = NSFFormulaDecompile(pFormula,
	                                            FALSE,
	                                            &hFormulaText,
	                                            &wFormulaTextLen);

	              if (ln_rc)
	              {
					  DEBUG(("Notes::ViewColumn object returning error %d at line %d", ln_rc, __LINE__));;
	                  OSUnlockBlock(ValueBlockID);
	                  NSFNoteClose(hNote);
					  LN_SET_IVX(view, ln_rc);
			  		  XSRETURN_NOT_OK;
	              }

	              /*
	               *  Get pointer to formula text.
	               */

	              pFormulaText = OSLock(char, hFormulaText);

	              /*
	               *  Copy formula text to temp storage, and null terminate it.
	               *  Then copy formula text to output buffer.
	               */

	              pTemp = (char far *) malloc((size_t) wFormulaTextLen +1);

	              if (pTemp != NULL)
	              {
	                  memmove(pTemp, pFormulaText, (int) wFormulaTextLen);
	                  pTemp[wFormulaTextLen] = '\0';

			          sv = newSVpv(pTemp,0);
					  SvREADONLY_on(sv);
					  hv_store(ln_hash, "Formula", 7, sv, 0);

	                  free (pTemp);
	              }

	              OSUnlock(hFormulaText);
	              OSMemFree(hFormulaText);
	          } /* end if */

	          /*
	           * We're not interested in the Constant Value string,
	           * so advance data ptr to next item.
	           */

	          pPackedData += pColumnFormat->ConstantValueSize;

	          /*
	           *  See if this column is a sort key or not.
	           */

	          if (pColumnFormat->Flags1 & VCF1_M_Sort)
				  sv = newSViv(1);
		      else
		      	  sv = newSViv(0);

			  SvREADONLY_on(sv);
			  hv_store(ln_hash, "IsSorted", 8, sv, 0);


	          /*
	           *  See if this column is a category  or not.
	           */

	          if (pColumnFormat->Flags1 & VCF1_M_SortCategorize)
			  	  sv = newSViv(1);
  		      else
  		      	  sv = newSViv(0);

  			  SvREADONLY_on(sv);
			  hv_store(ln_hash, "IsCategory", 10, sv, 0);

	          /*
	           *  See how this column is sorted.
	           */

	          if (pColumnFormat->Flags1 & VCF1_M_SortDescending)
			  	  sv = newSViv(1);
  		      else
  		      	  sv = newSViv(0);

  			  SvREADONLY_on(sv);
			  hv_store(ln_hash, "IsSortDescending", 16, sv, 0);

			  if (pColumnFormat->Flags1 & VCF1_M_SortDescending)
			   	  sv = newSViv(0);
			  else
  		      	  sv = newSViv(1);

			  SvREADONLY_on(sv);
			  hv_store(ln_hash, "IsSortAscending", 15, sv, 0);

	          /*
	           *  See if this column is hidden.
	           */

	          if (pColumnFormat->Flags1 & VCF1_M_Hidden)
			   	  sv = newSViv(1);
			  else
  		      	  sv = newSViv(0);

			  SvREADONLY_on(sv);
			  hv_store(ln_hash, "IsHidden", 8, sv, 0);

	          /*
	           *  See if this column is a response column.
	           */

	          if (pColumnFormat->Flags1 & VCF1_M_Response)
			   	  sv = newSViv(1);
			  else
  		      	  sv = newSViv(0);

			  SvREADONLY_on(sv);
			  hv_store(ln_hash, "IsResponse", 10, sv, 0);

	          /*
	           *  See if this column shows details if it is a subtotaled column.
	           */

	          if (pColumnFormat->Flags1 & VCF1_M_HideDetail)
			   	  sv = newSViv(1);
			  else
  		      	  sv = newSViv(0);

			  SvREADONLY_on(sv);
			  hv_store(ln_hash, "IsHideDetail", 12, sv, 0);

	          /*
	           *  See if this column displays an icon INSTEAD of text as its title.
	           */

	          if (pColumnFormat->Flags1 & VCF1_M_Icon)
			   	  sv = newSViv(1);
			  else
  		      	  sv = newSViv(0);

			  SvREADONLY_on(sv);
			  hv_store(ln_hash, "IsIcon", 6, sv, 0);

	          /*
	           *  See if this column displays a twistie when categorized.
	           */

	          if (pColumnFormat->Flags1 & VCF1_M_Twistie)
			   	  sv = newSViv(1);
			  else
  		      	  sv = newSViv(0);

			  SvREADONLY_on(sv);
			  hv_store(ln_hash, "IsShowTwistie", 13, sv, 0);

	          /*
	           *  See if this column is resizable at runtime.
	           */

	          if (pColumnFormat->Flags1 & VCF1_M_NoResize)
			   	  sv = newSViv(0);
			  else
  		      	  sv = newSViv(1);

			  SvREADONLY_on(sv);
			  hv_store(ln_hash, "IsResize", 8, sv, 0);

	          /*
	           *  See if this column is resortable at runtime.
	           */

	          if (pColumnFormat->Flags1 & VCF1_M_ResortDescending)
			   	  sv = newSViv(1);
			  else
  		      	  sv = newSViv(0);

			  SvREADONLY_on(sv);
			  hv_store(ln_hash, "IsResortToView", 14, sv, 0);


	          if (pColumnFormat->Flags1 & VCF1_M_ResortDescending)
	          {
	               /*
	                *  See how this column is sorted, if resortable at runtime.
	                */

	              if (pColumnFormat->Flags1 & VCF1_S_ResortDescending)
				   	  sv = newSViv(1);
				  else
	  		      	  sv = newSViv(0);

				  SvREADONLY_on(sv);
				  hv_store(ln_hash, "IsResortDescending", 18, sv, 0);

				  if (pColumnFormat->Flags1 & VCF1_S_ResortAscending)
				   	  sv = newSViv(1);
				  else
				   	  sv = newSViv(0);

				  SvREADONLY_on(sv);
				  hv_store(ln_hash, "IsResortAscending", 17, sv, 0);
	          }

	          /*
	           *  See if this column is a secondary sort column
	           */

	          if (pColumnFormat->Flags1 & VCF1_M_SecondResort)
			   	  sv = newSViv(1);
			  else
  		      	  sv = newSViv(0);

			  SvREADONLY_on(sv);
			  hv_store(ln_hash, "IsSecondaryResort", 17, sv, 0);

	          /*
	           *  See if this column is sorted as secondary descending
	           */

	          if (pColumnFormat->Flags1 & VCF1_M_SecondResortDescending)
			   	  sv = newSViv(1);
			  else
  		      	  sv = newSViv(0);

			  SvREADONLY_on(sv);
			  hv_store(ln_hash, "IsSecondaryResortDescending", 27, sv, 0);

			  /*
	           *  See if this column is sorted as secondary ascending
	           */

	          if (pColumnFormat->Flags1 & VCF1_M_SecondResortDescending)
			   	  sv = newSViv(0);
			  else
  		      	  sv = newSViv(1);

			  SvREADONLY_on(sv);
			  hv_store(ln_hash, "IsSecondaryResortAscending", 26, sv, 0);

	       //} /*  End of for loop.  */
  	  }

	  OSUnlockBlock(ValueBlockID);
      NSFNoteClose(hNote);

	  LN_PUSH_NEW_HASH_OBJ( "Notes::ViewColumn", view );
	  LN_SET_OK( view );
	  XSRETURN ( 1 );


MODULE = Notes::ViewColumn	 PACKAGE = Notes::ViewColumn

void
DESTROY( col )
      LN_ViewColumn *   col;
   PPCODE:
      XSRETURN( 0 );