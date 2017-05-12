   /* begin hide perl-typedef Block BLOCK */
#define BLOCK Perl_BLOCK

#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

   /* end hide perl-typedef Block BLOCK */
#undef BLOCK



   /* mask Perl's defines to avoid name clashes with Notes C API */
#ifdef  WORD
#define Perl_WORD WORD
#undef  WORD
#endif

#ifdef  LOCAL
#define Perl_LOCAL LOCAL
#undef  LOCAL
#endif



   /* inclusion of Notes C API Header files */
#include <global.h>
#include <osmem.h>
#include <nsfdb.h>
#include <names.h>
#include <dname.h>
#include <acl.h>
#include <miscerr.h>

  /* 
   * from here we could selectively make visible either
   * the Perl defines or the Notes C API ones
   *
   * Note: We do not fiddle around with our typedef ... BLOCK
   *       name clash, as we hardly need the Perl definition
   *       but probably the Notes C API one
   *
   */

#include   "ln_defines.h"
#include   "ln_typedefs.h"
#include   "ln_acl.h"



void LNPUBLIC
XS_Notes__AclEntry_enum_has_entryname(
      void*                 ln_enum_entry,
      char*                 ln_enum_entry_name,
      WORD                  ln_enum_entry_access_level,
      ACL_PRIVILEGES*       ln_enum_entry_roles,
      WORD                  ln_enum_entry_access_details
) {  
   LN_Acl_EnumEntry* ln_e = ln_enum_entry;

   /* prerequisite at start: found == LN_NOT_OK && stat == LN_OK */ 

   if ( 0 == strcmp( ln_enum_entry_name, ln_e->name )) {

      if   ( ln_e->found           == LN_NOT_OK  )
           { ln_e->found            = LN_OK;     }
      else { ln_e->stat             = LN_NOT_OK; }
   }
   return;
}



void LNPUBLIC
XS_Notes__AclEntry_enum_xpush_all_entryobjects(
      void*             ln_e,
      char*             ln_enum_entry_name,
      WORD              ln_enum_entry_access_level,
      ACL_PRIVILEGES*   ln_enum_entry_roles,
      WORD              ln_enum_entry_access_details
) {
   d_LN_XSVARS;
   dSP;       /* note: accesses _global_ stack_base/mark (Xsub.h/pp.h)*/
              /* note: this is problematic for multi-threading (?)    */

   int             ln_sp_i;
   char *          acl_entry_name;
   LN_Acl *        a;

      /* we avoid using SPAGAIN instead,          */
      /* because it adjusts the _global_ stack_sp */
   SP      = ( (LN_Acl_EnumEntry*)ln_e )->sp;
   ln_sp_i = ( (LN_Acl_EnumEntry*)ln_e )->items;

      /* parent obj for creation of new obj below */
   a       = ( (LN_Acl_EnumEntry*)ln_e )->obj;

      /* note: Notes C API docs says nothing about */
      /*       memory management for acl_entry_name;*/
      /* perl computes length and each string gets */
      /* _copied_ in a new SV on the perl stack    */
   Newz( 1,   acl_entry_name, strlen(ln_enum_entry_name) + 1, char );
   ln_stat = (acl_entry_name != (char *) NULL) ? LN_OK : LN_NOT_OK;

   if ( LN_IS_OK )  {

      strcpy(         acl_entry_name,          ln_enum_entry_name);

      LN_PUSH_NEW_O( "Notes::AclEntry",        a );
      LN_SET_H(       ln_o )          = (long) acl_entry_name;
      LN_SET_OK(      ln_o );
      ln_sp_i      += 1;
      ln_stat       = LN_OK;

   } else {
      ((LN_Acl_EnumEntry* )ln_e)->stat  = ln_stat;
   }
      /* we avoid using PUTBACK instead,          */
      /* because it adjusts the _global_ stack_sp */
   (   (LN_Acl_EnumEntry* )ln_e)->sp    = SP;
   (   (LN_Acl_EnumEntry* )ln_e)->items = ln_sp_i;

   return;
}



MODULE =    Notes::AclEntry   PACKAGE = Notes::Acl

PROTOTYPES: DISABLE

void
entries_by_name( a, ... )
      LN_Acl *   a;
   PREINIT:
      d_LN_XSVARS;
      LN_Acl_Impl*        a_impl;
      HANDLE              a_h;
      int                 i;
      int                 sp_i;
      LN_Acl_EnumEntry    ae;
      char *              ae_name; 
   ALIAS:
      entries           = 0 
      entries_by_name   = 1 
   PPCODE:
      if ( items == 1 ) { XSRETURN( 0 ); }

      a_impl = (LN_Acl_Impl*) LN_H(a);
      a_h    = a_impl->h;

      for ( LN_SET_OK(a), i = 1, sp_i = 0; i < items; i++ ) {
     
         ln_stat = DNCanonicalize(
                      0L,
                      NULL,
                      SvPV( ST(i), na ),
                      ae.name,
                      MAXUSERNAME,
                      NULL
         );                              /* skip, if error in DNCanon */
         if ( LN_IS_NOT_OK )           { LN_STAT(a)=ln_stat; continue; }

         ae.found = LN_NOT_OK;
         ae.stat  = LN_OK;

         ln_stat = ACLEnumEntries(
                      a_h,
                     &XS_Notes__AclEntry_enum_has_entryname,
                     &ae
         );                              /* skip, if error in ACLEnum */
         if ( LN_IS_NOT_OK )           { LN_STAT(a)=ln_stat; continue; }

         ln_stat = ae.found;             /* skip, if name not found   */
         if ( LN_IS_NOT_OK )           { LN_STAT(a)=ln_stat; continue; }

         ln_stat = ae.stat;              /* skip, if multiply found   */
         if ( LN_IS_NOT_OK )           { LN_STAT(a)=ln_stat; continue; }

            /* name found once, so try to create new Notes::ACLEntry  */
         Newz( 1,   ae_name, strlen(ae.name) + 1, char );
         ln_stat = (ae_name != (char*) NULL) ? LN_OK : LN_NOT_OK;

                                         /* skip, if malloc problem   */
         if ( LN_IS_NOT_OK )           { LN_STAT(a)=ln_stat; continue; }

         strcpy( ae_name, ae.name );

         LN_PUSH_NEW_O( "Notes::AclEntry",        a );
         LN_SET_H(       ln_o )          = (long) ae_name;
         LN_SET_OK(      ln_o );
         sp_i         += 1;
         ln_stat       = LN_OK;

      }  /* end for i < items */
 
      XSRETURN( sp_i );



void
all_entryobjects( a )
      LN_Acl *    a;
   PREINIT:
      d_LN_XSVARS;
      LN_Acl_Impl*       a_impl;
      HANDLE             a_h;
      int                sp_i;
      LN_Acl_EnumEntry   ae;
   ALIAS:
      all_entries      = 0
      all_entryobjects = 1
   PPCODE:
      a_impl    = (LN_Acl_Impl*) LN_H(a);
      a_h       = a_impl->h;

      sp_i      = 0;
      ln_stat   = LN_OK;

      ae.sp   = SP;      /* we avoid using PUTBACK instead,    */
      ae.items= sp_i;    /* cause it adjusts _global_ stack ptr*/
      ae.stat = ln_stat;
      ae.obj  = a;

      LN_STAT(a) = ACLEnumEntries(
                      a_h,
                     &XS_Notes__AclEntry_enum_xpush_all_entryobjects,
                     &ae
      );

      SP      = ae.sp;   /* we avoid using SPAGAIN instead,    */
      sp_i    = ae.items;/* cause it adjusts _global_ stack ptr*/
      ln_stat = ae.stat;

      if ( LN_IS_NOT_OK ) { LN_STAT(a) = ln_stat; }

      XSRETURN( sp_i );



void
add_entries_by_name( a, ... )
      LN_Acl *       a;
   PREINIT:
      d_LN_XSVARS;
      LN_Acl_Impl*   a_impl;
      HANDLE         a_h;
      int            i         = 0;
      int            sp_i      = 0;
      char           name[       MAXUSERNAME ]; 
      char *         ae_name; 
      WORD           level     = ACL_LEVEL_NOACCESS;
      ACL_PRIVILEGES rolebits  = { (0,0,0,0,0,0,0,0) };
      WORD           flags     = 0;
   ALIAS:
      # maybe the default should better be Author with no deletion
      # note: the Notes C API documentation don't show the flag
      #       values for person groups and server groups
      add_entries_by_name            = 0
      add_entries                    = 1
      # note: convenience alias with _same_ index
      add                            = 1
      add_persons_by_name            = 2
      add_persons                    = 3
      add_servers_by_name            = 4
      add_servers                    = 5
      add_groups_by_name             = 6
      add_groups                     = 7

      add_fullaccess_entries_by_name = 8
      add_fullaccess_entries         = 9
      # note: convenience alias with _same_ index
      add_with_fullaccess            = 9
      add_fullaccess_persons_by_name = 10
      add_fullaccess_persons         = 11
      add_fullaccess_servers_by_name = 12
      add_fullaccess_servers         = 13
      add_fullaccess_groups_by_name  = 14
      add_fullaccess_groups          = 15
   PPCODE:
      if ( items == 1 ) { XSRETURN_NOT_OK; }

         /*
          * list of all access level detail flags
          * we have found in the Notes C API 4.61 docs;
          * Note: ordering is with falling power/relevance
          * Note: we miss the flags for person groups and server groups
          *
          * ACL_FLAG_NODELETE
          * ACL_FLAG_AUTHOR_NOCREATE
          *
          * ACL_FLAG_CREATE_LOTUSSCRIPT
          * ACL_FLAG_CREATE_FOLDER
          * 
          * ACL_FLAG_CREATE_PRAGENT
          * ACL_FLAG_CREATE_PRFOLDER
          *
          * ACL_FLAG_PUBLICREADER
          * ACL_FLAG_PUBLICWRITER
          *
          * ACL_FLAG_PERSON
          * ACL_FLAG_SERVER
          * ACL_FLAG_GROUP
          * 
          * ACL_FLAG_ADMIN_SERVER
          * ACL_FLAG_ADMIN_READERAUTHOR
          */

      switch ( ix ) {        /* first, set level and detail rights   */ 
         case   0:  case  1: case  2: case  3:
         case   4:  case  5: case  6: case  7:
            level  =  ACL_LEVEL_AUTHOR;         /* default: author*/
            flags &=  LN_ACL_DETAILS_RESET_POSITIVES;
            flags |=  LN_ACL_DETAILS_SET_NEGATIVES;
            flags &= ~ACL_FLAG_AUTHOR_NOCREATE; /* allow creation */
            break;

         case   8:  case  9: case 10: case 11:
         case  12:  case 13: case 14: case 15:
            level  =    ACL_LEVEL_HIGHEST;
            flags |= LN_ACL_DETAILS_SET_POSITIVES;
            flags &= LN_ACL_DETAILS_RESET_NEGATIVES;
            break;
         default:
            XSRETURN_NOT_OK; 
            break;
      }
      switch ( ix ) {        /* finally, set detail entry type       */
         case   0:  case  1: case  8: case  9:
            flags &= LN_ACL_RESET_ANY_TYPE;
            break;
         case   2:  case  3: case 10: case 11:
            flags |=    ACL_FLAG_PERSON;
            break;
         case   4:  case  5: case 12: case 13:
            flags |=    ACL_FLAG_SERVER;
            break;
         case   6:  case  7: case 14: case 15:
            flags |=    ACL_FLAG_GROUP;
            break;
      }

      a_impl    = (LN_Acl_Impl*) LN_H(a);
      a_h       = a_impl->h;

      for ( LN_SET_OK(a), i = 1, sp_i = 0 ; i < items; i++ ) {
         /*
          * Note: the Notes C API docs say nothing about length
          *       restrictions for the input name to DNCanonicalize()
          *       and so we do _not_ truncate it;
          *       however we truncate our role names
          *       (see add_roles_by_name and remove_roles_by_name)
          */
         ln_stat = DNCanonicalize(
                      0L,
                      NULL,
                      SvPV( ST(i), na ),
                      name,
                      MAXUSERNAME,
                      NULL
         );
         if ( LN_IS_NOT_OK )           { LN_STAT(a)=ln_stat; continue; }

         ln_stat = ACLAddEntry( a_h, name, level, &rolebits, flags );

         if ( LN_IS_NOT_OK )           { LN_STAT(a)=ln_stat; continue; }

         Newz( 1,   ae_name, strlen(name) + 1, char );
         ln_stat = (ae_name != (char*) NULL) ? LN_OK : LN_NOT_OK;

         if ( LN_IS_NOT_OK )           { LN_STAT(a)=ln_stat; continue; }

         strcpy( ae_name, name );

         LN_PUSH_NEW_O( "Notes::AclEntry",        a );
         LN_SET_H(       ln_o )          = (long) ae_name;
         LN_SET_OK(      ln_o );
         sp_i         += 1;
         ln_stat       = LN_OK;

      }  /* end for i < items */
 
      XSRETURN( sp_i );



void
remove_entries_by_name( a, ... )
      LN_Acl *       a;
   PREINIT:
      d_LN_XSVARS;
      LN_Acl_Impl*   a_impl;
      HANDLE              a_h;
      int                 i;
      char                name[   MAXUSERNAME ]; 
   ALIAS:
      remove                  = 0
      remove_entries          = 1
      remove_entries_by_name  = 2
   PPCODE:
      a_impl              = (LN_Acl_Impl*) LN_H(a);
      a_h                 = a_impl->h;
      if ( items <= 1 ) { XSRETURN( 0 ); }

      for ( LN_SET_OK(a), i = 1; i < items; i++ ) { /* i=0 skipped */

         ln_stat =
           DNCanonicalize(0L,NULL,SvPV(ST(i),na),name,MAXUSERNAME,NULL);

         if ( LN_IS_OK )     { ln_stat    = ACLDeleteEntry(a_h, name); }
         if ( LN_IS_NOT_OK ) { LN_STAT(a) = ln_stat;                   }
      }
      XSRETURN( 0 );



void
rename_entries_by_name( a, ... )
      LN_Acl *            a;
   PREINIT:
      d_LN_XSVARS;
      LN_Acl_Impl*        a_impl;
      HANDLE              a_h;
      int                 i;
      int                 sp_i;
      LN_Acl_EnumEntry    ae;
      char                new_name[    MAXUSERNAME ]; 
      char *              ae_name; 
   ALIAS:
      rename                 = 0
      rename_entries         = 1
      rename_entries_by_name = 2
      
   PPCODE:
      if ( (items % 2) == 0 ) { items  -= 1;   } /*enforce name pairs*/
      if (  items      <= 1 ) { XSRETURN( 0 ); }

      a_impl    = (LN_Acl_Impl*) LN_H(a);
      a_h       = a_impl->h;

                   /* skip Notes::ACL obj */
      for ( LN_STAT(a) = LN_OK, i = 1, sp_i = 0; i < items; i += 2 ) {
         /*
          * Note: the Notes C API docs say nothing about length
          *       restrictions for the input name to DNCanonicalize()
          *       and so we do _not_ truncate it;
          *       however we truncate our role names
          *       (see add_roles_by_name and remove_roles_by_name)
          */
         ln_stat = DNCanonicalize(
                      0L,
                      NULL,
                      SvPV( ST(i), na ),
                      ae.name,
                      MAXUSERNAME,
                      NULL
         );                              /* skip, if error in DNCanon */
         if ( LN_IS_NOT_OK )           { LN_STAT(a)=ln_stat; continue; }

         ae.found = LN_NOT_OK;
         ae.stat  = LN_OK;

         ln_stat = ACLEnumEntries(
                      a_h,
                     &XS_Notes__AclEntry_enum_has_entryname,
                     &ae
         );                              /* skip, if error in ACLEnum */
         if ( LN_IS_NOT_OK )           { LN_STAT(a)=ln_stat; continue; }

         ln_stat = ae.found;             /* skip, if name not found   */
         if ( LN_IS_NOT_OK )           { LN_STAT(a)=ln_stat; continue; }

         ln_stat = ae.stat;              /* skip, if multiply found   */
         if ( LN_IS_NOT_OK )           { LN_STAT(a)=ln_stat; continue; }

         ln_stat = DNCanonicalize(
                      0L,
                      NULL,
                      SvPV( ST(i+1), na ),
                      new_name,
                      MAXUSERNAME,
                      NULL
         );                              /* skip, if error in DNCanon */
         if ( LN_IS_NOT_OK )           { LN_STAT(a)=ln_stat; continue; }

         ln_stat = ACLUpdateEntry(
                      a_h,
                      ae.name,
                      ACL_UPDATE_NAME       | ACL_UPDATE_LEVEL
                    | ACL_UPDATE_PRIVILEGES | ACL_UPDATE_FLAGS,
                      new_name,
                      ae.level,
                     &ae.rolebits,
                      ae.flags
         );
         if ( LN_IS_NOT_OK )           { LN_STAT(a)=ln_stat; continue; }

         Newz( 1,   ae_name, strlen(new_name) + 1, char );
         ln_stat = (ae_name != (char*) NULL) ? LN_OK : LN_NOT_OK;

         if ( LN_IS_NOT_OK )           { LN_STAT(a)=ln_stat; continue; }

         strcpy(    ae_name, new_name );

         LN_PUSH_NEW_O( "Notes::AclEntry",        a );
         LN_SET_H(       ln_o )          = (long) ae_name;
         LN_SET_OK(      ln_o );
         sp_i         += 1;
         ln_stat       = LN_OK;

      }  /* end for i < items */

      XSRETURN( sp_i );



MODULE =    Notes::AclEntry   PACKAGE = Notes::AclEntry

PROTOTYPES: DISABLE



void
DESTROY( e )
      LN_AclEntry *   e;
   PREINIT:
      d_LN_XSVARS;
   PPCODE:
      Safefree( (char*) LN_H(e) ); 
      XSRETURN( 0 ); 



void
name( e )
      LN_AclEntry *   e;
   PREINIT:
      d_LN_XSVARS;
   PPCODE:
      XPUSHs( sv_2mortal( newSVpv( (char*) LN_H(e), 0 ) ) );
      XSRETURN( 1 );
