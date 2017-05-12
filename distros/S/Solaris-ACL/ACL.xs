/*
 *
 * $Id: ACL.xs,v 1.10 2000/04/07 22:48:30 ian Exp $
 *
 * Change Log:
 * $Log: ACL.xs,v $
 * Revision 1.10  2000/04/07 22:48:30  ian
 * Fixed bug where attempts to give extra groups ACL access resulted in
 * corresponding users getting access instead.
 *
 * Removed to useless declarations of acl_result variable.
 *
 * Revision 1.9  2000/02/07 01:26:54  iroberts
 * * Added Id and Log strings to all files
 * * Now EXPORTs instead of EXPORT_OKing setfacl and getfacl
 * * make clean now removes test-acl-file and test-acl-dir
 *
 */


#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <sys/acl.h>
#include <errno.h>
#ifdef __cplusplus
}
#endif

/* Key names and lengths for the acl hash */

#define USER_KEY "users"
#define USER_KEY_LENGTH 5
#define GROUP_KEY "groups"
#define GROUP_KEY_LENGTH 6
#define USER_OBJ_KEY "uperm"
#define USER_OBJ_KEY_LENGTH 5
#define GROUP_OBJ_KEY "gperm"
#define GROUP_OBJ_KEY_LENGTH 5
#define OTHER_OBJ_KEY "operm"
#define OTHER_OBJ_KEY_LENGTH 5
#define MASK_OBJ_KEY "mask"
#define MASK_OBJ_KEY_LENGTH 4

/* record_error(sys_err, pattern, ...) */

/* record_error sets Solaris::ACL::error to the value of pattern,
   where pattern (and option subsequent arguments) is a sprintf type
   string.  If sys_err is non_zero, then the error message
   corresponding to errno is appended to the end of the string. */

void record_error(int sys_err, const char *pattern, ...)
{
  SV *error; 
  va_list args;

  va_start(args, pattern);
  sv_vsetpvfn(error = perl_get_sv("Solaris::ACL::error",TRUE),
              pattern, strlen(pattern), &args, Null(SV**), 0, Null(bool*));
  va_end(args);
  if (sys_err)
    sv_catpv(error, strerror(errno));

}

/* hashref_count(hashref) */
 
/* hashref_count checks to see if the given SV is a hashref; if it is,
   it sets hash to point to the referenced hash, and returns the
   number of entries in the corresponding hash.  If not, it sets hash
   to NULL and returns -1.  */


int hashref_count (SV *hash_ref, HV **hash)
{
  if (! SvROK(hash_ref))
    return -1;
  
  if (SvTYPE((SV *)*hash = SvRV(hash_ref)) != SVt_PVHV)
  {
    *hash = NULL;
    return -1;
  }    

  return HvKEYS(*hash);
}

/* pretest_acl(acl, acl_hash, user_hash, group_hash) */
 
/* pretest_acl does some preliminary checks to see if the given SV is
   a hashref to a properly formed acl; if it is, it returns the number
   of entries in the acl.  If not, it calls record_error and returns
   0.  acl_hash is set to be the pointer to the actual hash refered to
   by acl.  If the acl has a user has entry, then user_hash is set to
   point to that, and otherwise is set to NULL. Likewise for
   group_hash.  If the acl has a mask, then mask is set to the SV
   pointer for that entry. */

int pretest_acl (SV *acl, HV **acl_hash, HV **user_hash, 
                 HV **group_hash, SV ***mask)
{
  SV **matched_val;
  int hash_count;
  int acl_count = 3; /* user, group, other */

  if (! SvROK(acl))
  {
    record_error(0, "Passed scalar is not a reference");
    return 0;
  }
  if (SvTYPE((SV *)*acl_hash = SvRV(acl)) != SVt_PVHV)
  {
    record_error(0, "Passed scalar is not a hash reference");
    return 0;
  }

  if(matched_val = hv_fetch(*acl_hash, USER_KEY, USER_KEY_LENGTH, 0))
  {
    if ((hash_count = hashref_count(*matched_val,user_hash)) == -1)
    {
      record_error(0, "the 'user' field of the hash is not a hash reference");
      return 0;
    }
     acl_count += hash_count;
  }
  else
  {
    *user_hash = NULL;
  }
  
  if(matched_val = hv_fetch( *acl_hash, GROUP_KEY, GROUP_KEY_LENGTH, 0))
  {
    if ((hash_count = hashref_count(*matched_val,group_hash)) == -1)
    {
      record_error(0, "the 'group' field of the hash is not a hash reference");
      return 0;
    }
    acl_count += hash_count;
  }
  else
  {
    *group_hash = NULL;
  }
  
  /* check to see if an acl_mask is set */
  if( (*mask) = hv_fetch(*acl_hash, MASK_OBJ_KEY, MASK_OBJ_KEY_LENGTH,0))
    acl_count++;
  
  return acl_count;
}

/* add_acl_ent(type, id, perms, acl_buf, entry_number, total_ents) */

/* add_acl_ent adds the entry specified by type, user and perms to
   position entry_number of acl_buf, and then increments entry_number.
   If entry_number >= total_ents, then record_error is called, and -1
   is returned.  Otherwise, 0 is returned. */

int add_acl_ent(int type, uid_t id, o_mode_t perm, 
                aclent_t *acl_buf, int *entry_number, int total_ents)
{
  if(*entry_number >= total_ents)
  {
    record_error(0, "number of acl entries larger than expected");
    return -1;
  }
  
  acl_buf[*entry_number].a_type = type;
  acl_buf[*entry_number].a_id = id;
  acl_buf[(*entry_number)++].a_perm = perm;
  return 0;
}

/* add_acl_list(acl_hash, type, acl_buf, entry_number, total_ents) */

/* add_acl_list iterates through the given hash, adding an entry to
   acl_buf of acl type type, id given by the key and perm given by
   acl_hash{id}.  entry_number and total_ents are handled as in
   add_acl_ent. 0 returned on success, -1 on error. */

int add_acl_list(HV *acl_hash, int type, aclent_t *acl_buf, 
                 int *entry_number, int total_ents)
{
  HE *hash_entry;

  hv_iterinit(acl_hash);
  
  while(hash_entry = hv_iternext(acl_hash))
  {
    if (add_acl_ent(type, SvIV(hv_iterkeysv(hash_entry)), 
                    SvIV(hv_iterval(acl_hash, hash_entry)),
                    acl_buf, entry_number, total_ents))
      return -1;
  }
  return 0;
}    

/* populate_acl(acl_ents, def, acl_hash, user_hash, group_hash,
                mask, num_ents, uid, gid) */

/* populate_acl puts acl entries into the array pointed to by
   acl_ents.  def should either be 0 or ACL_DEFAULT.  acl_hash
   should point to the acl hash, while user_hash and group_hash should
   point to the user and group entries (if they exist), or be null
   otherwise.  mask should be a pointer to the SV pointer for mask, or
   null.  num_ents is the expected number of entries.  uid and gid are
   the user and group owners of the file.  If the actual number of
   entries is different (either less or more) than num_ents, then
   record_error is called, and -1 is returned.  If any required acl
   entries are missing, then record_error is called, and -1 returned.
   Otherwise (i.e., on success), 0 is returned.  */

int populate_acl(aclent_t *acl_ents, int def, HV *acl_hash, HV *user_hash, 
                 HV *group_hash, SV **mask, int num_acl_ents,
                 uid_t uid, gid_t gid)
{
  SV **matched_val;
  int i=0;

  if(matched_val = hv_fetch(acl_hash, USER_OBJ_KEY, USER_OBJ_KEY_LENGTH, 0))
  {
    if(add_acl_ent(USER_OBJ | def, uid, SvIV(*matched_val), 
                   acl_ents, &i, num_acl_ents)) 
      return -1;
  }
  else
  {
    record_error(0, "no user_obj key in hash");
    return -1;
  }
  
  if(matched_val = hv_fetch(acl_hash, GROUP_OBJ_KEY, GROUP_OBJ_KEY_LENGTH, 0))
  {
    if(add_acl_ent(GROUP_OBJ | def, gid, SvIV(*matched_val), 
                   acl_ents, &i, num_acl_ents)) 
      return -1;
  }
  else
  {
    record_error(0, "no group_obj key in hash");
    return -1;
  }

  if(matched_val = hv_fetch(acl_hash, OTHER_OBJ_KEY, OTHER_OBJ_KEY_LENGTH, 0))
  {
    if(add_acl_ent(OTHER_OBJ | def, 0, SvIV(*matched_val), 
                   acl_ents, &i, num_acl_ents)) 
      return -1;
  }
  else
  {
    record_error(0, "no other_obj key in hash");
    return -1;
  }
  
  if(mask)
  {
    if(add_acl_ent(CLASS_OBJ | def, 0, SvIV(*mask), 
                   acl_ents, &i, num_acl_ents)) 
      return -1;
  }
  
  if(user_hash)
    if(add_acl_list(user_hash,  USER | def, acl_ents, &i, num_acl_ents))
      return -1;

  if(group_hash)
    if(add_acl_list(group_hash, GROUP | def, acl_ents, &i, num_acl_ents))
      return -1;

  return 0; /* all's well that ends well... */
}

#define PACKAGE_NAME "Solaris::ACL"

MODULE = Solaris::ACL		PACKAGE = Solaris::ACL		

 # getfacl(filename)

 # getfacl returns the acls of a file, Barring error, the return is
 # ($acl[, $default_acl]), where $acl and $default_acl are each
 # hashrefs to hashes with entries for:

 #  user - a hash ref to a hash of the form { uid => file perm mode ...}
 #  group - ditto for gids
 #  uperm - perms for the file owner
 #  gperm - perms for the file group
 #  operm - perms for other
 #  mask - the mask

 # If there are no default acl entries, then no default_acl hash is returned.

 # If there is an error, then the null list is returned, and $! is set
 # to indicate the error.  A more informative error message can be found 
 # in $Solaris::ACL::error.

void
getfacl(file_name)
     SV * file_name;
     PPCODE:
{
  char *file_string;        /* c-string version of file_name */
  int file_string_length;   /* need to pass a variable to SvPV */
  HV *acl_hash, *default_acl_hash, *current_acl_hash;
  HV *user_hash, *default_user_hash, **current_user_hash;
  HV *group_hash, *default_group_hash, **current_group_hash;
  SV **acl_list_hash;
  
  int num_acl_ents;
  aclent_t *acl_ents;
  int i;

  file_string = SvPV(file_name,file_string_length);
  if( (num_acl_ents=acl(file_string, GETACLCNT, 0, NULL)) == -1 )
  {
    record_error(1, "acl(%s, GETACLCNT) failed: ", file_string);
    XSRETURN(0);
  }
  
  if (New(0,acl_ents,num_acl_ents,aclent_t) == NULL)
  {
    record_error(1, "New(%, %d) failed: ", 
                    num_acl_ents, sizeof(aclent_t));
    XSRETURN(0);
  }

  if(acl(file_string, GETACL, num_acl_ents, acl_ents) == -1)
  {
    record_error(1, "acl(%s, GETACL) failed: ", file_string);
    XSRETURN(0);
  }
  
  /* We have the acl.  Now, convert it into our perl structure */
  
  acl_hash = newHV();
  default_acl_hash = NULL;  /* until we see a default acl,
                               assume there is none */
  user_hash = NULL;  /* Until we see user acls, assume none */
  group_hash = NULL; /* ditto */
  default_user_hash = NULL; /* ditto */
  default_group_hash = NULL; /* ditto */
  
  for(i = 0; i < num_acl_ents; i++)
  {
    if (acl_ents[i].a_type & ACL_DEFAULT)
    {
      if(default_acl_hash == NULL)
        default_acl_hash = newHV();
      current_acl_hash = default_acl_hash;
      current_user_hash = &default_user_hash;
      current_group_hash = &default_group_hash;
    }
    else
    {
      current_acl_hash = acl_hash;
      current_user_hash = &user_hash;
      current_group_hash = &group_hash;
    }


    switch ((acl_ents[i].a_type | ACL_DEFAULT) ^ ACL_DEFAULT)
    {
    case USER_OBJ:  /* file's user owner */
      hv_store(current_acl_hash, USER_OBJ_KEY, USER_OBJ_KEY_LENGTH,
               newSViv(acl_ents[i].a_perm), 0);
      break;
      
    case GROUP_OBJ:  /* file's group owner */
      hv_store(current_acl_hash, GROUP_OBJ_KEY, GROUP_OBJ_KEY_LENGTH,
               newSViv(acl_ents[i].a_perm), 0);
      break;
      
    case OTHER_OBJ:  /* "other" */
      hv_store(current_acl_hash, OTHER_OBJ_KEY, OTHER_OBJ_KEY_LENGTH,
               newSViv(acl_ents[i].a_perm), 0);
      break;
      
    case CLASS_OBJ:  /* acl mask */
      hv_store(current_acl_hash, MASK_OBJ_KEY, MASK_OBJ_KEY_LENGTH,
               newSViv(acl_ents[i].a_perm), 0);
      break;
      
    case USER:      /* additional users */
      if (*current_user_hash == NULL) /* is this our first user acl? */
      {
        *current_user_hash = newHV();
        hv_store(current_acl_hash, USER_KEY, USER_KEY_LENGTH, 
                 newRV_noinc((SV*)(*current_user_hash)), 0);
      }
      hv_store_ent(*current_user_hash, sv_2mortal(newSViv(acl_ents[i].a_id)), 
                   newSViv(acl_ents[i].a_perm), 0);
      break;
      
    case GROUP:      /* additional groups */
      if (*current_group_hash == NULL) /* is this our first group acl? */
      {
        *current_group_hash = newHV();
        hv_store(current_acl_hash, GROUP_KEY, GROUP_KEY_LENGTH, 
                 newRV_noinc((SV*)(*current_group_hash)), 0);
      }
      hv_store_ent(*current_group_hash, sv_2mortal(newSViv(acl_ents[i].a_id)), 
                   newSViv(acl_ents[i].a_perm), 0);
      break;
    }
  }

  Safefree(acl_ents);

  XPUSHs(sv_2mortal(sv_bless(newRV_noinc((SV*)acl_hash), 
                             gv_stashpv(PACKAGE_NAME,0))));
  if(default_acl_hash == NULL) /* were there default acls? */
    XSRETURN(1); 
  else
  {
    XPUSHs(sv_2mortal(sv_bless(newRV_noinc((SV*)default_acl_hash), 
                               gv_stashpv(PACKAGE_NAME,0))));
    XSRETURN(2);
  }
}

 # setfacl(filename, acl_hashref [, default_acl_hashref])

 # setfacl sets the acl (and optionally the default acl) for filename.
 # acl (and optionally default_acl) should be a reference to a hash with
 # the same structure as in getfacl.  The return is TRUE on sucess and FALSE
 # on failure.  If a failure is indicated, the caller should check the
 # string $Solaris::ACL::error for more information.  If the error is a
 # system error, the error will also be in $!.

void
setfacl(file_name, acl_hashref, ...)
     SV *file_name;
     SV *acl_hashref;
     PPCODE:
{
  char *file_string;        /* c-string version of file_name */
  int file_string_length;   /* need to pass a variable to SvPV */

  HV *acl_hash, *def_acl_hash;
  HV *user_hash, *group_hash, *def_user_hash, *def_group_hash;
  SV **mask, **def_mask;

  aclent_t *acl_ents;
  int num_acl_ents;
  struct stat stat_buf;

  int num_def_acl_ents  = 0;

  if (items > 3)
    croak("Usage: Solaris::ACL::setfacl(file_name, acl [, default_acl])");

  /* are we over dereferencing in this next line ??? */
 
  if(!(num_acl_ents = 
       pretest_acl(acl_hashref, &acl_hash, &user_hash, &group_hash, &mask)))
    XSRETURN_NO;
    
  if (items == 3)
  {
    if(!(num_def_acl_ents = 
         pretest_acl(ST(2), &def_acl_hash, &def_user_hash, 
                     &def_group_hash, &def_mask)))
      XSRETURN_NO;
  }
    
  file_string = SvPV(file_name,file_string_length);

  /* Although it is not documented as mattering, the a_id field of
     user_obj and group_obj entries in an acl is set to be the actual
     user or group id of the file, at least when the acl is modified
     by setfacl(1) or chmod(1).  In case something actually depends on
     this, we are grabbing the user and group ids of the file via
     stat.  */

  if(stat(file_string, &stat_buf))
  {
    record_error(1, "stat(%s) failed: ", file_string);
    XSRETURN_NO;
  }
  
  if (New(0,acl_ents, num_acl_ents + num_def_acl_ents, aclent_t) == NULL)
  {
    record_error(1, "New(%d, %d) failed: ", 
                 num_acl_ents + num_def_acl_ents, sizeof(aclent_t));
    XSRETURN_NO;
  }
  
  if (populate_acl(acl_ents, 0, acl_hash, user_hash, 
                   group_hash, mask, num_acl_ents,
                   stat_buf.st_uid, stat_buf.st_gid))
    XSRETURN_NO;

  if (items == 3)
    if (populate_acl(&acl_ents[num_acl_ents], ACL_DEFAULT, def_acl_hash, 
                     def_user_hash, def_group_hash, def_mask, 
                     num_def_acl_ents, stat_buf.st_uid, stat_buf.st_gid))
    XSRETURN_NO;

  if(acl(file_string, SETACL, num_acl_ents + num_def_acl_ents, acl_ents) == -1)
  {
    record_error(1, "acl(%s, SETFACL) failed: ", file_string);
    XSRETURN_NO;
  }

  Safefree(acl_ents);

  /* woohoo!  everything worked! */
  XSRETURN_YES;
}
