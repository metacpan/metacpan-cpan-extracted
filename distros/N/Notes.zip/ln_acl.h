        /* for easier ACL flag manipulation */

#include <acl.h>
#define LN_ACL_RESET_ANY_TYPE \
        ( ~ACL_FLAG_PERSON    \
        | ~ACL_FLAG_GROUP     \
        | ~ACL_FLAG_SERVER )

#define LN_ACL_DETAILS_SET_POSITIVES   \
        (  ACL_FLAG_CREATE_LOTUSSCRIPT |  ACL_FLAG_CREATE_FOLDER   \
        |  ACL_FLAG_CREATE_PRAGENT     |  ACL_FLAG_CREATE_PRFOLDER \
        |  ACL_FLAG_PUBLICWRITER       |  ACL_FLAG_PUBLICREADER )

#define LN_ACL_DETAILS_RESET_POSITIVES \
        ( ~ACL_FLAG_CREATE_LOTUSSCRIPT & ~ACL_FLAG_CREATE_FOLDER   \
        & ~ACL_FLAG_CREATE_PRAGENT     & ~ACL_FLAG_CREATE_PRFOLDER \
        & ~ACL_FLAG_PUBLICWRITER       & ~ACL_FLAG_PUBLICREADER )

#define LN_ACL_DETAILS_SET_NEGATIVES   \
        (  ACL_FLAG_NODELETE           |  ACL_FLAG_AUTHOR_NOCREATE )

#define LN_ACL_DETAILS_RESET_NEGATIVES \
        ( ~ACL_FLAG_NODELETE           & ~ACL_FLAG_AUTHOR_NOCREATE )



/*
 * the functions ln_role_* below form the interface to
 * a hash-like datastructure - though of finite size :-( -
 * in the array a_impl->roles[]
 *
 * the following is true for all functions:
 *
 * * char *name is the key to the "hash"
 *
 * * is_role and is_priv are boolean flags
 *   is_role = 1 ==> search rolename      area of a_impl->roles[i]
 *   is_priv = 1 ==> search privilegename area of a_impl->roles[i]
 *   is_role = 0 ==> don't search rolename       area
 *   is_priv = 0 ==> don't search privilegesname area
 *   assumption: is_role and is_priv never have the same value
 *
 * * i is the index into the array implementation of the "hash",
 *   where the slot i for "name" should be manipulated
 * 
 * * the Notes C API currently stores
 *   privilege names in slots 0 to ACL_BITPRIVCOUNT-1=4
 *   and
 *   role      names in slots ACL_BITPRIVCOUNT=5 to ACL_PRIVCOUNT-1=79
 *
 * * the cached values for the (eventually overlapping)
 *   stretch of indices containing filled slots and
 *   the stretch of indices containing free slots gets
 *   only updated when manipulating roles, i.e. for indices 5..79
 *
 * * free (empty) role _and_ privilege slots get filled with '\0'
 *
 * * the input values are only accidentally checked for correctness
 *
 */



/*
 * updates the "cache" members of the a_impl-struct
 * a_impl->r1        marks first filled role slot
 * a_impl->rn        marks last  filled role slot
 * a_impl->r1_free   marks first free   role slot
 * a_impl->rn_free   marks last  free   role slot
 *
 * Note 1:
 * * the stretches of filled and free role slots _can_ overlap
 * * assertion: ACL_BITPRIVCOUNT - 1 <= r1,rn,... <= ACL_PRIVCOUNT
 *
 * Note 2:
 * These cached values should speed up the linear
 * search in function ln_role_exists() considerably,
 * as for "normal" Notes ACLs, the following holds true:
 * (a) no privileges
 * (b) few, i.e. less than ten, filled role slots
 *     contiguosly stored at the beginning of the "roles" stretch
 * (c) the Notes C API implementation probably  
 *     guarantees, that the stretches of filled and free role slots
 *     mostly do not overlap after a call to $acl->save()
 *     and a reread with $acl=$db->acl;
 *     (we will check that :)
 *
 */
void
ln_role_update_cache( LN_Acl_Impl* a_impl ) {

   int    j;
   char   c;
   
   Zero( (char *)&(a_impl->rolebits), 1, ACL_PRIVILEGES );
   a_impl->r1      = ACL_PRIVCOUNT;
   a_impl->rn      = ACL_BITPRIVCOUNT - 1;
   a_impl->r1_free = ACL_PRIVCOUNT;
   a_impl->rn_free = ACL_BITPRIVCOUNT - 1;

   for ( j = 0; j < ACL_BITPRIVCOUNT; j++ ) {
      if ( a_impl->roles[j][0] != '\0' ) {
         ACLSetPriv( a_impl->rolebits, j );
      }
   }
   for ( j = ACL_BITPRIVCOUNT; j < ACL_PRIVCOUNT; j++ ) {

      if ( a_impl->roles[j][0] != '\0' ) {
         ACLSetPriv( a_impl->rolebits, j );
         if ( a_impl->rn < j  && j <  ACL_PRIVCOUNT    )
         {    a_impl->rn = j; }
         if ( a_impl->r1 > j  && j >= ACL_BITPRIVCOUNT )
         {    a_impl->r1 = j; }
      }
      else { 
         if ( a_impl->rn_free <  j  && j <  ACL_PRIVCOUNT    )
         {    a_impl->rn_free =  j; }
         if ( a_impl->r1_free >  j  && j >= ACL_BITPRIVCOUNT )
         {    a_impl->r1_free =  j; }
      }
   }  /* end for j < ACL_PRIVCOUNT */

   /* 
    * printf( "\n:rolebits\n" );
    * for ( j = 0; j < 10; j++ ) {
    *    c = (a_impl->rolebits).BitMask[j];
    *    printf( "%d |%0.2x|\n", j, (unsigned int)c );
    * }
    *
    */

}  /* end function ln_role_update_cache() */



/*
 * checks wether a given rolename
 * is present in the rolename-array a_impl->roles[i]
 * return values:
 * (1) negative values from -1 till -ACL_PRIVCOUNT
 *     indicate that name is _not_ present and
 *     that -result - 1 is the next free slot in a_impl->roles[]
 * (2) the value 0 indicates that name is _not_ present
 *     and a_impl->roles[] is _full_, i.e. no more free slots 
 * (3) positive values from 1 till ACL_PRIVCOUNT
 *     indicate that name is present in a_impl->roles[]
 *     and can be found at index result - 1 
 */
int
ln_role_exists(
   LN_Acl_Impl* a_impl, char* name, int is_role, int is_priv
) {

   int    min_role;
   int    max_role;
   int    result;
   int    free;
   int    j;

   if ( is_role ) { min_role = a_impl->r1;max_role = a_impl->rn + 1;   }
   else           { min_role = 0;         max_role = ACL_BITPRIVCOUNT; }

   for (result=-1, free=ACL_PRIVCOUNT, j=min_role; j<max_role; j++) {
      if (a_impl->roles[j][0] == '\0')
      {  free  = j; continue;  }
      if (a_impl->roles[j][0] == name[0]
          && strcmp(a_impl->roles[j],name) == 0)
      {  result= j; break;     }
   }
   if ( result != -1 )             { return   result + 1;  }

   result = (is_role ? a_impl->r1_free : free);
   if ( result !=  ACL_PRIVCOUNT ) { return -(result + 1); }
   if ( result ==  ACL_PRIVCOUNT ) { return   0;           }

}  /* end function ln_role_exists() */



/*
 * stores a given name at slot with index i;
 * doesn't check wether name is already present
 * return values:
 * (1) positive values i + 1 indicate success
 * (2) negative values and 0 indicate errors
 *
 */
int
ln_role_store(
   LN_Acl_Impl* a_impl, char* name, int is_role, int is_priv, int i
) {

   int j;
   
   if ( -1 < i && i < ACL_PRIVCOUNT ) { /* just to avoid coredumps */
      Zero(   a_impl->roles[i], 1, LN_RoleName );
      strcpy( a_impl->roles[i],    name );
      ACLSetPriv( a_impl->rolebits, i );
   }
   if ( is_role ) { ln_role_update_cache( a_impl ); }

   return i + 1;

}  /* end function ln_role_store() */



/*
 * deletes a name at given slot with index i;
 * doesn't check wether name is already present
 * and doesn't use name in the implementation
 * return values:
 * (1) positive values i + 1 indicate success
 * (2) negative values and 0 indicate errors
 *
 */
int
ln_role_delete( 
   LN_Acl_Impl* a_impl,  char* name, int is_role, int is_priv, int i
) {
   int j;
   
   if ( -1 < i && i < ACL_PRIVCOUNT ) {
      Zero(         a_impl->roles[i], 1, LN_RoleName );
      ACLClearPriv( a_impl->rolebits, i );
   }
   if ( is_role ) { ln_role_update_cache( a_impl ); }

   return i + 1;

}  /* end function ln_role_delete() */
