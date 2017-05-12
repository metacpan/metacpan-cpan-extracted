#define BLOCK Perl_BLOCK

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "notesobject.h"

MODULE = Notes::Object		PACKAGE = Notes::Object

PROTOTYPES: DISABLE


void
is_ok( o )
      LN_Object *   o;
   PREINIT:
      d_LN_XSVARS;
   PPCODE:
      if ( LN_IS_OK(o) )
      {
		  XSRETURN_OK;
	  }
	  else
	  {
		  XSRETURN_NOT_OK;
	  }



void
is_not_ok( o )
      LN_Object *   o;
   PREINIT:
      d_LN_XSVARS;
   PPCODE:
      if ( LN_IS_NOT_OK(o) )
      {
		  XSRETURN_OK;
	  }
	  else
	  {
		  XSRETURN_NOT_OK;
	  }



void
status( o )
      LN_Object *   o;
   PREINIT:
      d_LN_XSVARS;
   PPCODE:
      XSRETURN_IV( (IV) LN_IVX( o ) );



void
set_status( o, ln_stat_value )
      LN_Object *     o;
      int             ln_stat_value;
   PREINIT:
      d_LN_XSVARS;
   PPCODE:
      LN_SET_IVX( o, ln_stat_value );
      XSRETURN( 0 );



void
status_text( o )
      LN_Object *   o;
   PREINIT:
      d_LN_XSVARS;
      char * ln_stat_text_lmbcs;
      char * ln_stat_text_native;
      WORD   ln_stat_text_length;
   PPCODE:
      /* Dynamically allocate our two status text buffers */
      Newz(1,ln_stat_text_lmbcs, LN_STAT_TEXT_LMBCS_LENGTH, char);
      if(ln_stat_text_lmbcs == (char *) NULL)
      {
		  XSRETURN_NOT_OK;
	  }

      /* Fetch Notes' status string in LMBCS, i.e.
       * MIXED Multi-Byte charstring format.
       */
      ln_stat_text_length = OSLoadString(
                               NULLHANDLE,
                               ERR( LN_IVX( o ) ),
                               ln_stat_text_lmbcs,
                               LN_STAT_TEXT_LMBCS_LENGTH
                            );
      if(ln_stat_text_length <= 0)
      {
         Safefree(ln_stat_text_lmbcs);
         XSRETURN_NOT_OK;
      }

      Newz(1, ln_stat_text_native, LN_STAT_TEXT_NATIVE_LENGTH, char);
      if(ln_stat_text_native == (char *) NULL)
      {
		  XSRETURN_NOT_OK;
	  }

      /* Translate from LMBCS to native, i.e. (single or double byte)
       * charstring to Native formatted text.
       */
      ln_stat_text_length = OSTranslate(
                               OS_TRANSLATE_LMBCS_TO_NATIVE,
                               ln_stat_text_lmbcs,
                               ln_stat_text_length,
                               ln_stat_text_native,
                               LN_STAT_TEXT_NATIVE_LENGTH
                            );
      if (ln_stat_text_length <= 0)
      {
         Safefree(ln_stat_text_lmbcs);
         Safefree(ln_stat_text_native);
         XSRETURN_NOT_OK;
      }

      XSRETURN_PV(ln_stat_text_native);