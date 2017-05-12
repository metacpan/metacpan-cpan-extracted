#define BLOCK Perl_BLOCK

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "notesacl.h"

   /* Note: + the function below is made exported
    *         as it gets called as a callback by the Notes C API
    *       + the export status can be controlled by the
    *         DL_FUNCS statement in Makefile.PL and finally produces
    *         the *.def and *.exp files for the linker on Win32
    *       + DL_FUNCS also controls the function's name(space) mangling
    *         except for the prefix XS_, but this is probably good so
    *         (see ExtUtils::Makemaker and Extutils::MkSysmlists)
    *
    *       examples for iterator callbacks in the Notes C API are:
    *         NSFSearch()           (scans all server-dir's or db-doc's)
    *         ACLEnumEntries()      (scans all ACL entries)
    *         NSFItemScan()         (scans all document items)
    *         EnumCompositeBuffer() (scans all CD-records in a RT-item)
    *         EnumCompositeFile()   (scans all CD-records in disc image
    *                                of a [possibly large] RT-item)
    *
    *       examples for "event" callbacks in the Notes C API are the:
    *         Extension Manager callbacks
    *         (e.g. password callback hook)
    *
    */

void LNPUBLIC
XS_Notes__Acl_enum_has_entryname(
      void*                 ln_enum_entry,
      char*                 ln_enum_entry_name,
      WORD                  ln_enum_entry_access_level,
      ACL_PRIVILEGES*       ln_enum_entry_rolebits,
      WORD                  ln_enum_entry_access_details)
{
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
XS_Notes__Acl_enum_xpush_all_entrynames(
      void*             ln_e,
      char*             ln_enum_entry_name,
      WORD              ln_enum_entry_access_level,
      ACL_PRIVILEGES*   ln_enum_entry_rolebits,
      WORD              ln_enum_entry_access_details)
{
   d_LN_XSVARS;
   dSP;       /* note: accesses _global_ stack_base/mark (Xsub.h/pp.h)*/
              /* note: this is problematic for multi-threading (?)    */

   int             ln_sp_i;
   char            ln_abbrev_name[ MAXUSERNAME ];
   WORD            ln_len_abbrev_name;
   LN_Acl *        a;

      /* we avoid using SPAGAIN instead,          */
      /* because it adjusts the _global_ stack_sp */
   SP      = ( (LN_Acl_EnumEntry*)ln_e )->sp;
   ln_sp_i = ( (LN_Acl_EnumEntry*)ln_e )->items;

   ln_stat = DNAbbreviate( 0L, NULL,
	        ln_enum_entry_name,
	        ln_abbrev_name,
                MAXUSERNAME,
               &ln_len_abbrev_name);
   if ( LN_IS_OK ) {

         /* note: Notes C API docs says nothing about */
         /*       memory management for acl_entry_name;*/
      XPUSHs( sv_2mortal( newSVpv( ln_abbrev_name, 0 ) ) );
      ln_sp_i                   += 1;
      ln_stat                    = LN_OK;

   } else {
      ((LN_Acl_EnumEntry* )ln_e)->stat  = ln_stat;
   }
      /* we avoid using PUTBACK instead,          */
      /* because it adjusts the _global_ stack_sp */
   (   (LN_Acl_EnumEntry* )ln_e)->sp    = sp;
   (   (LN_Acl_EnumEntry* )ln_e)->items = ln_sp_i;

   return;
}



MODULE =    Notes::Acl   PACKAGE = Notes::Database

PROTOTYPES: DISABLE

void
get_acl( db )
      LN_Database *   db;
   PREINIT:
      d_LN_XSVARS;
      LN_Acl_Impl *   a_impl;
      int             i;
      LN_RoleName     role_name;
      int             len;
      char*           role;
   ALIAS:
      acl     = 0
      get_acl = 1
   PPCODE:
      Newz( 1, a_impl, sizeof(LN_Acl_Impl),  LN_Acl_Impl );

      if (a_impl==A_NO_MEM) { LN_SET_NOT_OK(db); XSRETURN_NOT_OK; }

      LN_STAT(db) = NSFDbReadACL( (DBHANDLE) LN_H(db), &(a_impl->h) );

      if ( LN_IS_NOT_OK )   { Safefree(a_impl);  XSRETURN_NOT_OK; }

         /* get all privilege _and_ role names */
      for ( i = 0; i < ACL_PRIVCOUNT; i++) {

         ln_stat  = ACLGetPrivName( a_impl->h, i, role_name );
         len      = strlen(                       role_name );

            /* zero out the right role/priv delimiter */
         if ( len > 0 ) { role_name[ len - 1 ] = '\0'; }

         if ( LN_IS_OK && len > 2 ) {
               /*avoid calls to ln_update_cache() by assuming privs*/
            (void) ln_role_store( a_impl, role_name+1, 0,1, i );
            continue;
         }
         if ( LN_IS_NOT_OK  && ln_stat == ERR_ACL_NOENTRY ) {
               /* no role name found, i.e. a free role slot           */
               /* do nothing, cause all has been initialzized to zero */
            ln_stat = LN_OK;
            continue;
         }
         if ( LN_IS_NOT_OK  && ln_stat != ERR_ACL_NOENTRY ) {
            Safefree(a_impl);             /* fatal role name error */
            LN_STAT( db    ) = ln_stat;
            XSRETURN_NOT_OK;
         }
      }  /* end for */

      ln_role_update_cache( a_impl );

      LN_PUSH_NEW_O( "Notes::Acl",        db );
      LN_SET_H(       ln_o )     = (long) a_impl;
      LN_SET_OK(      ln_o );
      XSRETURN(       1    );



MODULE =    Notes::Acl   PACKAGE = Notes::Acl

PROTOTYPES: DISABLE

void
DESTROY( a )
      LN_Acl *       a;
   PREINIT:
      d_LN_XSVARS;
      LN_Acl_Impl*   a_impl;
      HANDLE         a_h;
   PPCODE:
      a_impl   = (LN_Acl_Impl*) LN_H(a);
      a_h      = a_impl->h;
      OSMemFree( a_h    ); /* OSMemFree() _always_ returns NO_ERROR */
      Safefree(  a_impl );
      XSRETURN(  0      );



void
save( a )
      LN_Acl *       a;
   PREINIT:
      d_LN_XSVARS;
      LN_Acl_Impl*   a_impl;
      HANDLE         a_h;
   PPCODE:
      a_impl     = (LN_Acl_Impl*) LN_H(a);
      a_h        = a_impl->h;
      LN_STAT(a) = NSFDbStoreACL( (DBHANDLE)
                      LN_PARENT_H(a),
                      a_h,
                      0L, /* reserved: not yet used */
                      0L  /* store existing ACL     */
      );
      XSRETURN( 0 );






void
has_entryname( a, name )
      LN_Acl *           a;
      char *             name;
   PREINIT:
      d_LN_XSVARS;
      LN_Acl_Impl*       a_impl;
      HANDLE             a_h;
      LN_Acl_EnumEntry   ln_e;
   PPCODE:
      a_impl     = (LN_Acl_Impl*) LN_H(a);
      a_h        = a_impl->h;

      LN_STAT(a) =
         DNCanonicalize( 0L, NULL, name, ln_e.name, MAXUSERNAME, NULL );

      if ( LN_IS_NOT_OK ) { XSRETURN_NOT_OK; }

      ln_e.found = LN_NOT_OK;
      ln_e.stat  = LN_OK;

      LN_STAT(a) =
         ACLEnumEntries( a_h, &XS_Notes__Acl_enum_has_entryname,&ln_e );

      if ( LN_IS_NOT_OK ) { XSRETURN_NOT_OK; }

      LN_STAT(a) = ln_e.stat;
      ln_stat    = ln_e.found;

      if   ( LN_IS_OK )
           { XSRETURN_OK;     }
      else { XSRETURN_NOT_OK; }



void
all_entrynames( a )
      LN_Acl *           a;
   PREINIT:
      d_LN_XSVARS;
      LN_Acl_Impl*       a_impl;
      HANDLE             a_h;
      int                sp_i;
      LN_Acl_EnumEntry   ln_e;
   PPCODE:
      a_impl     = (LN_Acl_Impl*) LN_H(a);
      a_h        = a_impl->h;

      sp_i       = 0;
      ln_stat    = LN_OK;

      ln_e.sp    = SP;      /* we avoid using PUTBACK instead,    */
      ln_e.items = sp_i;    /* cause it adjusts _global_ stack ptr*/
      ln_e.stat  = ln_stat;
      ln_e.obj   = a;

      LN_STAT(a) = ACLEnumEntries(
                      a_h,
                     &XS_Notes__Acl_enum_xpush_all_entrynames,
                     &ln_e
      );
      if ( LN_IS_NOT_OK ) { XSRETURN_NOT_OK; }

      SP         = ln_e.sp;   /* we avoid using SPAGAIN instead,    */
      sp_i       = ln_e.items;/* cause it adjusts _global_ stack ptr*/
      ln_stat    = ln_e.stat;

      if ( LN_IS_NOT_OK ) { LN_STAT(a) = ln_stat; }

      XSRETURN( sp_i );






void
all_roles( a )
      LN_Acl * a;
   PREINIT:
      d_LN_XSVARS;
      LN_Acl_Impl*  a_impl;
      HANDLE        a_h;
      int           i        = 0;
      int           sp_i     = 0;
      LN_RoleName   role;
      int           min_role;
      int           max_role;
   ALIAS:
      all_roles     = 0
      all_privs     = 1
   PPCODE:
      a_impl        = (LN_Acl_Impl*) LN_H(a);
      a_h           = a_impl->h;

      switch ( ix ) {
         case   0:  min_role=a_impl->r1;max_role=a_impl->rn + 1;  break;
         case   1:  min_role=0;         max_role=ACL_BITPRIVCOUNT;break;
         default:   min_role=a_impl->r1;max_role=a_impl->rn + 1;  break;
      }
      for ( LN_SET_OK(a), i = min_role; i < max_role; i++ ) {

         if ( (a_impl->roles[i][0]) != '\0' ) {
            XPUSHs(sv_2mortal(newSVpv( a_impl->roles[i], 0 )));
            sp_i += 1;
         }
      }
      XSRETURN( sp_i );



void
has_role(          a, name )
      LN_Acl *        a;
      char *          name;
   PREINIT:
      d_LN_XSVARS;
      LN_Acl_Impl *   a_impl;
      HANDLE          a_h;
      int             i;
      int             len;
      LN_RoleName     role;
      int             is_role;
      int             is_priv;
      int             found;
      int             not_found;
   PPCODE:
      a_impl = (LN_Acl_Impl*) LN_H(a);
      a_h    = a_impl->h;
      len    = strlen( name );
      len    = ( len  < ACL_PRIVNAMEMAX ) ? len : ACL_PRIVNAMEMAX - 1;

      strncpy(  role, name, len );
      role[ len                 ] = '\0'; /* truncate to len */
      role[ ACL_PRIVNAMEMAX-1   ] = '\0'; /* safeguard       */

      i = ln_role_exists( a_impl, role, is_role, is_priv );

      if   ( i <= 0 ) { XSRETURN_NOT_OK; }
      else            { XSRETURN_OK;     }



void
has_all_roles(   a, ... )
      LN_Acl *   a;
   PREINIT:
      d_LN_XSVARS;
      LN_Acl_Impl*    a_impl;
      HANDLE          a_h;
      int             i;
      int             j;
      char *          name;
      int             len;
      LN_RoleName     role;
      int             is_role;
      int             is_priv;
      int             found;
      int             not_found;
   ALIAS:
      has_all_roles = 0
      has_any_roles = 1
      has_no_roles  = 2
      has_all_privs = 3
      has_any_privs = 4
      has_no_privs  = 5
   PPCODE:
      a_impl        = (LN_Acl_Impl*) LN_H(a);
      a_h           = a_impl->h;

      if ( items <= 1 ) { XSRETURN( 0 ); }

      for ( LN_SET_OK(a), j = 1; j < items; j++ ) {

         name = SvPV( ST( j ), a );
         len  = strlen(   name  );
         len  = (  len  < ACL_PRIVNAMEMAX ) ? len : ACL_PRIVNAMEMAX - 1;

         strncpy(  role, name, len );
         role[ len                 ] = '\0'; /* truncate to len */
         role[ ACL_PRIVNAMEMAX-1   ] = '\0'; /* safeguard       */

         switch ( ix ) {
            case 0: case 1: case 2: is_role = 1; is_priv = 0; break;
            case 3: case 4: case 5: is_role = 0; is_priv = 1; break;
            default:                is_role = 1; is_priv = 0; break;
         }

         i = ln_role_exists( a_impl, role, is_role, is_priv );

         switch( ix ) {
            case 0: case 3: {    if (i <= 0) {XSRETURN_NOT_OK;}; break;}
            case 2: case 5: {    if (i >  0) {XSRETURN_NOT_OK;}; break;}
            case 1: case 4: {    if (i >  0) {XSRETURN_OK;    }; break;}
            default:        {    if (i <= 0) {XSRETURN_NOT_OK;}; break;}
         }

         if ( i <= 0 ) { ++not_found; }
         if ( i >  0 ) { ++found;     }

      }  /* end for j < items */

      items -= 1;
      switch( ix ) {
         case 0: case 3: { if (    found==items) {XSRETURN_OK;}; break;}
         case 2: case 5: { if (not_found==items) {XSRETURN_OK;}; break;}
         default:        { if (    found==items) {XSRETURN_OK;}; break;}
      }
      XSRETURN_NOT_OK;



void
add_roles( a, ... )
      LN_Acl *     a;
   PREINIT:
      d_LN_XSVARS;
      LN_Acl_Impl*   a_impl;
      HANDLE         a_h;
      int            i;
      int            j;
      char *         name;
      int            len;
      LN_RoleName    role;
      int            is_role;
      int            is_priv;
   ALIAS:
      add_roles    = 0
      add_privs    = 1
      remove_roles = 2
      remove_privs = 3
   PPCODE:
      a_impl       = (LN_Acl_Impl*) LN_H(a);
      a_h          = a_impl->h;

      if ( items <= 1 ) { XSRETURN( 0 ); }

      for ( LN_SET_OK(a), j = 1; j < items; j++ ) {

         name = SvPV( ST( j ), na );
         len  = strlen(   name  );
         len  = (  len  < ACL_PRIVNAMEMAX ) ? len : ACL_PRIVNAMEMAX - 1;

         strncpy(  role, name, len );
         role[ len                 ] = '\0'; /* truncate to len */
         role[ ACL_PRIVNAMEMAX-1   ] = '\0'; /* safeguard       */

         switch ( ix ) {
            case 0: case 2: is_role=1; is_priv=0; break;
            case 1: case 3: is_role=0; is_priv=1; break;
            default:        is_role=1; is_priv=0; break;
         }

         i = ln_role_exists( a_impl, role, is_role, is_priv );

         switch ( ix ) {
            case  0: case  1: {
               if  (i  > 0) {    LN_STAT(a)=ERR_ACL_INLIST;  continue; }
               if  (i == 0) {    LN_STAT(a)=ERR_ACL_FULL;    continue; }
               i = -i  - 1;
               ln_stat = ACLSetPrivName( a_h, i, role );
               if (LN_IS_NOT_OK){LN_STAT(a)=ln_stat;         continue; }

               i = ln_role_store(        a_impl,role,is_role,is_priv,i);
               if  (i <= 0)  {   LN_SET_NOT_OK(a);           continue; }
               break;
            }
            case  2: case  3: {
               if  (i <= 0) {    LN_STAT(a)=ERR_ACL_NOENTRY; continue; }
               i =  i - 1;
               ln_stat = ACLSetPrivName( a_h, i, "" );
               if (LN_IS_NOT_OK){LN_STAT(a)=ln_stat;         continue; }

               i = ln_role_delete(       a_impl,role,is_role,is_priv,i);
               if  (i <= 0) {    LN_SET_NOT_OK(a);           continue; }
               break;
            }
            default: break;
         }
      }  /* end for j < items */

      XSRETURN( 0 );



void
rename_roles_by_name( a, ... )
      LN_Acl *        a;
   PREINIT:
      d_LN_XSVARS;
      LN_Acl_Impl*      a_impl;
      HANDLE            a_h;
      int               i;
      int               j;
      char *            name;
      int               len;
      LN_RoleName       old_role;
      LN_RoleName       new_role;
      int               is_role;
      int               is_priv;
   ALIAS:
      rename_roles    = 0
      rename_privs    = 1
   PPCODE:
      a_impl          = (LN_Acl_Impl*) LN_H(a);
      a_h             = a_impl->h;

      if ( items     <= 2 ) {         XSRETURN(0); }
      if ( items % 2 == 0 ) {         items -= 1;  } /*old/new pairs!*/

      for ( LN_SET_OK(a), j = 1; j < items; j += 2 ) {

         name = SvPV( ST( j + 1 ), na );
         len  = strlen(   name  );
         len  = (  len  < ACL_PRIVNAMEMAX ) ? len : ACL_PRIVNAMEMAX - 1;

         strncpy(  new_role, name, len );
         new_role[ len                 ] = '\0'; /* truncate to len */
         new_role[ ACL_PRIVNAMEMAX-1   ] = '\0'; /* safeguard       */

         name = SvPV( ST( j ), na );
         len  = strlen(   name  );
         len  = (  len  < ACL_PRIVNAMEMAX ) ? len : ACL_PRIVNAMEMAX - 1;

         strncpy(  old_role, name, len );
         old_role[ len                 ] = '\0'; /* truncate to len */
         old_role[ ACL_PRIVNAMEMAX-1   ] = '\0'; /* safeguard       */

         switch ( ix ) {
            case 0:  is_role = 1; is_priv = 0; break;
            case 1:  is_role = 0; is_priv = 1; break;
            default: is_role = 1; is_priv = 0; break;
         }

         i = ln_role_exists( a_impl, new_role, is_role, is_priv );
         if  (i  > 0) {    LN_STAT(a)=ERR_ACL_INLIST;  continue; }

         i = ln_role_exists( a_impl, old_role, is_role, is_priv );
         if  (i <= 0) {    LN_STAT(a)=ERR_ACL_NOENTRY; continue; }
         i =  i -  1;

         ln_stat = ACLSetPrivName( a_h, i, new_role );
         if (LN_IS_NOT_OK){LN_STAT(a)=ln_stat;         continue; }

         i = ln_role_store(        a_impl,new_role,is_role,is_priv,i);
         if  (i <= 0)  {   LN_STAT(a)=LN_NOT_OK;       continue; }

      }  /* end for j < items */

      XSRETURN( 0 );



void
dbg_all_privroles( a )
      LN_Acl * a;
   PREINIT:
      d_LN_XSVARS;
      LN_Acl_Impl*        a_impl;
      HANDLE              a_h;
      int                 i        = 0;
      int                 sp_i     = 0;
      LN_RoleName         role;
      int                 min_role;
      int                 max_role;
   ALIAS:
      dbg_all_privroles    = 0
      dbg_all_privrolebits = 1
      dbg_roles_r1         = 2
      dbg_roles_rn         = 3
      dbg_roles_r1_free    = 4
      dbg_roles_rn_free    = 5
   PPCODE:
      a_impl    = (LN_Acl_Impl*) LN_H(a);
      a_h       = a_impl->h;

      switch ( ix ) {
         case   5:  XSRETURN_IV( a_impl->rn_free ); break;
         case   4:  XSRETURN_IV( a_impl->r1_free ); break;
         case   3:  XSRETURN_IV( a_impl->rn      ); break;
         case   2:  XSRETURN_IV( a_impl->r1      ); break;
         case   1:  XPUSHs(sv_2mortal(newSVpv(
                        (char *)&(a_impl->rolebits),
                        sizeof(ACL_PRIVILEGES)
                    )));               XSRETURN(1); break;
         case   0:  {
            for ( i = 0; i < ACL_PRIVCOUNT; i++ ) {

               if ( (a_impl->roles[i][0]) != '\0' ) {
                    XPUSHs(sv_2mortal(newSVpv(a_impl->roles[i], 0)));
               }
               else {
                    XPUSHs(sv_2mortal( &PL_sv_undef ));
               }
               sp_i += 1;
            }
            XSRETURN( sp_i );
         }
         default:  XSRETURN_IV( a_impl->r1_free ); break;
      }
