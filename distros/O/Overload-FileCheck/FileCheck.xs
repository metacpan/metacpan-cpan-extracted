/*
*
* Copyright (c) 2018, cPanel, LLC.
* All rights reserved.
* http://cpanel.net
*
* This is free software; you can redistribute it and/or modify it under the
* same terms as Perl itself.
*
*/

#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>
#include <embed.h>

#include "FileCheck.h"

/*
*  Macro to make the moking process easier
*     for now keep them there, so we can hack them in the same file
*/

/* generic macro with args */
#define _CALL_REAL_PP(zOP) (* ( gl_overload_ft->op[zOP].real_pp ) )(aTHX)
#define _RETURN_CALL_REAL_PP_IF_UNMOCK(zOP) if (!gl_overload_ft->op[zOP].is_mocked) return _CALL_REAL_PP(zOP);

/* simplified versions for our custom usage */
#define CALL_REAL_OP()            _CALL_REAL_PP(PL_op->op_type)
#define RETURN_CALL_REAL_OP_IF_UNMOCK() _RETURN_CALL_REAL_PP_IF_UNMOCK(PL_op->op_type)

#define INIT_FILECHECK_MOCK(op_name, op_type, f) \
  newCONSTSUB(stash, op_name,    newSViv(op_type) ); \
  gl_overload_ft->op[op_type].real_pp = PL_ppaddr[op_type]; \
  PL_ppaddr[op_type] = f;

/* TODO: need to improve for Perl <= 5.014 */
#define RETURN_CALL_REAL_OP_IF_CALL_WITH_DEFGV() STMT_START { \
    if (gl_overload_ft->op[OP_STAT].is_mocked) { \
      SV *arg = *PL_stack_sp; GV *gv; \
      if ( SvTYPE(arg) == SVt_PVAV ) arg = arg + AvMAX( arg ); \
      /* GV *gv =  MAYBE_DEREF_GV(arg); */ \
      if ( PL_op->op_flags & OPf_REF ) \
        gv = cGVOP_gv; \
      else { \
        gv = MAYBE_DEREF_GV(arg); \
       } \
      /* printf ("### XXX ---> arg %d %p vs GV %p vs defgv %p \n", SvFLAGS(arg), *PL_stack_sp, gv, PL_defgv ); */ \
      /* get the GV from the arg if it s not a GV */ \
      if ( SvTYPE(arg) == SVt_NULL || gv == PL_defgv ) { \
        return CALL_REAL_OP(); \
      } \
    } \
  } STMT_END

/* a Stat_t struct has 13 elements */
#define STAT_T_MAX 13

/* ----------- start there --------------- */

OverloadFTOps  *gl_overload_ft = 0;

/*
* common helper to callback the pure perl function Overload::FileCheck::_check
*   and get the mocked value for the -X check
*
*  1 check is true  -> OP returns Yes
*  0 check is false -> OP returns No
*  TODO:            -> OP returns undef
* -1 fallback to the original OP
*/
int _overload_ft_ops() {
  SV *const arg = *PL_stack_sp;
  int optype = PL_op->op_type;  /* this is the current op_type we are mocking */
  int check_status = -1;        /* 1 -> YES ; 0 -> FALSE ; -1 -> delegate */
  int count;

  dSP;

  ENTER;
  SAVETMPS;

  PUSHMARK(SP);
  EXTEND(SP, 2);
  PUSHs(sv_2mortal(newSViv(optype)));
  PUSHs(arg);

  PUTBACK;

  count = call_pv("Overload::FileCheck::_check", G_SCALAR);

  SPAGAIN;

  if (count != 1)
    croak("No return value from Overload::FileCheck::_check for OP #%d\n", optype);

  check_status = POPi; /* TOOO pop on SV* for true / false & co */

  /* printf ("######## The result is %d /// OPTYPE is %d\n", check_status, optype); */

  PUTBACK;
  FREETMPS;
  LEAVE;

  return check_status;
}

SV* _overload_ft_ops_sv() {
  SV *const arg = *PL_stack_sp;
  int optype = PL_op->op_type;  /* this is the current op_type we are mocking */
  SV *status;        /* 1 -> YES ; 0 -> FALSE ; -1 -> delegate */

  dSP;
  int count;

  ENTER;
  SAVETMPS;

  PUSHMARK(SP);
  EXTEND(SP, 2);
  PUSHs(sv_2mortal(newSViv(optype)));
  PUSHs(arg);

  PUTBACK;

  count = call_pv("Overload::FileCheck::_check", G_SCALAR);

  SPAGAIN;

  if (count != 1)
    croak("No return value from Overload::FileCheck::_check for OP #%d\n", optype);

  status = POPs;
  SvREFCNT_inc( status );

  /* printf ("######## The result is %d /// OPTYPE is %d\n", check_status, optype); */

  PUTBACK;
  FREETMPS;
  LEAVE;

  return status;
}

/*
*   view perldoc to call SVs, method, ...
*
*   https://perldoc.perl.org/perlcall.html
*
*   but also https://perldoc.perl.org/perlguts.html
*/

#define set_stat_from_aryix(st, ix) \
  rsv = ary[ix]; \
  if (SvROK(rsv)) croak("Overload::FileCheck - Item %d should not be one RV\n", ix); \
  if (SvIOK(rsv)) st = SvIV( rsv ); \
  else if (SvUOK(rsv)) st = SvUV( rsv ); \
  else if (SvNOK(rsv)) st = SvNV( rsv ); \
  else croak("Overload::FileCheck - Item %d is not numeric...\n", ix);


/*
*   similar to _overload_ft_ops but expect more args from _check
*   which returns values for a fake stat
*
*   Note: we could also call a dedicated function as _check_stat
*/
int _overload_ft_stat(Stat_t *stat, int *size) {
  SV *const arg = *PL_stack_sp;
  int optype = PL_op->op_type;  /* this is the current op_type we are mocking */
  int check_status = -1;        /* 1 -> YES ; 0 -> FALSE ; -1 -> delegate */

  dSP;
  int count;
  SV *sv;

  ENTER;
  SAVETMPS;

  PUSHMARK(SP);
  EXTEND(SP, 2);
  PUSHs(sv_2mortal(newSViv(optype)));
  PUSHs(arg);
  PUTBACK;

  count = call_pv("Overload::FileCheck::_check", G_ARRAY);

  SPAGAIN;

  if (count < 1)
    croak("Overload::FileCheck::_check for stat OP #%d should return at least one SV.\n", optype);
  if (count > 2)
    croak("Overload::FileCheck::_check for stat OP #%d should return no more than two SVs.\n", optype);

  /* popping the stack from last entry to first */
  if (count == 2) sv = POPs; /* RvAV */
  check_status = POPi; /* TOOO pop on SV* for true / false & co */

  *size = 0; /* by default it fails */

  if ( check_status == 1 ) {
    AV *stat_array;
    SV **ary;
    SV *rsv;
    int av_size;

    if (count != 2)
      croak("Overload::FileCheck::_check for stat OP #%d should return two SVs on success.\n", optype);

    if ( ! SvROK(sv) )
      croak( "Overload::FileCheck::_check need to return an array ref" );

    stat_array = MUTABLE_AV( SvRV( sv ) );
    if ( SvTYPE(stat_array) !=  SVt_PVAV )
      croak( "Overload::FileCheck::_check need to return an array ref" );

    av_size = AvFILL(stat_array);
    if ( av_size > 0 && av_size != ( STAT_T_MAX - 1 ) )
      croak( "Overload::FileCheck::_check: Array should contain 13 elements" );

    if ( av_size > 0 ) {
      *size = av_size; /* store the av_size */

      ary = AvARRAY(stat_array);

      /* fill the stat struct */
      set_stat_from_aryix( stat->st_dev, 0 );       /* IV */
      set_stat_from_aryix( stat->st_ino, 1 );       /* IV or UV : neg = PL_statcache.st_ino < 0 */
      set_stat_from_aryix( stat->st_mode, 2 );      /* UV */
      set_stat_from_aryix( stat->st_nlink, 3 );     /* UV */
      set_stat_from_aryix( stat->st_uid, 4 );       /* IV ? */
      set_stat_from_aryix( stat->st_gid, 5 );       /* IV ? */
      set_stat_from_aryix( stat->st_rdev, 6 );      /* IV or PV */
      set_stat_from_aryix( stat->st_size, 7 );      /* NV or IV */
      set_stat_from_aryix( stat->st_atime, 8 );     /* NV or IV */
      set_stat_from_aryix( stat->st_mtime, 9 );     /* NV or IV */
      set_stat_from_aryix( stat->st_ctime, 10 );    /* NV or IV */
      set_stat_from_aryix( stat->st_blksize, 11 );  /* UV or PV */
      set_stat_from_aryix( stat->st_blocks, 12 );   /* UV or PV */
    }

  }

  PUTBACK;
  FREETMPS;
  LEAVE;

  return check_status;
}


/* a generic OP to overload the FT OPs returning yes or no */
/* FIXME also need to handle undef */
PP(pp_overload_ft_yes_no) {
  int check_status;

  assert( gl_overload_ft );

  /* not currently mocked */
  RETURN_CALL_REAL_OP_IF_UNMOCK();
  RETURN_CALL_REAL_OP_IF_CALL_WITH_DEFGV();

  check_status = _overload_ft_ops();

  {
    FT_SETUP_dSP_IF_NEEDED;

    if ( check_status == 1 ) FT_RETURNYES;
    if ( check_status == 0 ) FT_RETURNUNDEF;
    /* if ( check_status == -1 ) FT_RETURNUNDEF; */ /* TODO */
  }

  /* fallback */
  return CALL_REAL_OP();
}

PP(pp_overload_ft_int) {
  int check_status;

  assert( gl_overload_ft );

  /* not currently mocked */
  RETURN_CALL_REAL_OP_IF_UNMOCK();
  RETURN_CALL_REAL_OP_IF_CALL_WITH_DEFGV();

  check_status = _overload_ft_ops();

  /* SETERRNO(EEXIST,RMS_FEX); */ /* TODO */
  if ( check_status == -1 )
    return CALL_REAL_OP();

  {
    dTARGET;
    FT_SETUP_dSP_IF_NEEDED;

    /* TODO this is over simplistic some OPs can return one NV instead of IV */
    sv_setiv(TARG, (IV) check_status);
    FT_RETURN_TARG;
  }
}

PP(pp_overload_ft_nv) {
  SV *status;

  assert( gl_overload_ft );

  /* not currently mocked */
  RETURN_CALL_REAL_OP_IF_UNMOCK();
  RETURN_CALL_REAL_OP_IF_CALL_WITH_DEFGV();

  status = _overload_ft_ops_sv();

  if ( SvIOK(status) && SvIV(status) == -1 )
    return CALL_REAL_OP();

  if ( SvNOK(status) && SvNV(status) == -1 )
    return CALL_REAL_OP();

  {
    dTARGET;
    FT_SETUP_dSP_IF_NEEDED;

    if ( SvNOK(status) )
      sv_setnv(TARG, (NV) SvNV(status) );
    else if ( SvIOK(status) )
      sv_setiv(TARG, (IV) SvIV(status) );

    FT_RETURN_TARG;
  }
}

PP(pp_overload_stat) { /* stat & lstat */
  Stat_t mocked_stat = { 0 };  /* fake stats */
  int check_status = 0;
  int size;


  assert( gl_overload_ft );

  /* not currently mocked */
  RETURN_CALL_REAL_OP_IF_UNMOCK();
  RETURN_CALL_REAL_OP_IF_CALL_WITH_DEFGV();

  /* calling with our own tmp stat struct, instead of passing directly PL_statcache: more control */
  check_status = _overload_ft_stat(&mocked_stat, &size);

  /* explicit ask for fallback */
  if ( check_status == -1 )
    return CALL_REAL_OP();

  /*
  * The idea is too fool the stat function
  *   like if it was called by passing _ or *_
  *
  * We are setting these values as if stat was previously called
  *   - PL_laststype
  *   - PL_statcache
  *   - PL_laststatval
  *   - PL_statname
  *
  */

  {
      dSP;

      /* drop & replace our stack first element with *_ */
      /* Unexpected warning: Attempt to free unreferenced scalar: SV 0x119bd80. */
      //SV *previous_stack = sv_2mortal(POPs); /* what do we want to do with this ? */
      SV *previous_stack = POPs;

      /* copy the content of mocked_stat to PL_statcache */
      memcpy(&PL_statcache, &mocked_stat, sizeof(PL_statcache));

      /* Here, we cut early when stat() returned no values
       * In such a case, we set the statcache, but do not call
       * the real op (CALL_REAL_OP)
      */
      if ( !size )
        RETURN;

      PUSHs( MUTABLE_SV( PL_defgv ) ); /* add *_ to the stack */

      if ( size ) { /* yes it succeeds */
        PL_laststatval = 0;
      } else { /* the stat call fails */
        PL_laststatval = -1;
      }

      PL_laststype   = PL_op->op_type;  /* this was for our OP */

      /* probably not real necesseary, make warning messages nicer */
      if ( previous_stack && SvPOK(previous_stack) )
        sv_setpv(PL_statname, SvPV_nolen(previous_stack) );

    return CALL_REAL_OP();
  }

}

/*
*  extract from https://perldoc.perl.org/functions/-X.html
*
*  -r  File is readable by effective uid/gid.
*  -w  File is writable by effective uid/gid.
*  -x  File is executable by effective uid/gid.
*  -o  File is owned by effective uid.
*  -R  File is readable by real uid/gid.
*  -W  File is writable by real uid/gid.
*  -X  File is executable by real uid/gid.
*  -O  File is owned by real uid.
*  -e  File exists.
*  -z  File has zero size (is empty).
*  -s  File has nonzero size (returns size in bytes).
*  -f  File is a plain file.
*  -d  File is a directory.
*  -l  File is a symbolic link (false if symlinks aren't
*      supported by the file system).
*  -p  File is a named pipe (FIFO), or Filehandle is a pipe.
*  -S  File is a socket.
*  -b  File is a block special file.
*  -c  File is a character special file.
*  -t  Filehandle is opened to a tty.
*  -u  File has setuid bit set.
*  -g  File has setgid bit set.
*  -k  File has sticky bit set.
*  -T  File is an ASCII or UTF-8 text file (heuristic guess).
*  -B  File is a "binary" file (opposite of -T).
*  -M  Script start time minus file modification time, in days.
*  -A  Same for access time.
*  -C  Same for inode change time
*/

MODULE = Overload__FileCheck       PACKAGE = Overload::FileCheck

SV*
mock_op(optype)
     SV* optype;
 ALIAS:
      Overload::FileCheck::_xs_mock_op               = 1
      Overload::FileCheck::_xs_unmock_op             = 2
 CODE:
 {
     /* mylogger = INT2PTR(MyLogger*, SvIV(SvRV(self))); */
      int opid = 0;

      if ( ! SvIOK(optype) )
        croak("first argument to _xs_mock_op / _xs_unmock_op must be one integer");

      opid = SvIV( optype );
      if ( !opid || opid < 0 || opid >= OP_MAX )
          croak( "Invalid opid value %d", opid );

      switch (ix) {
         case 1: /* _xs_mock_op */
              gl_overload_ft->op[opid].is_mocked = 1;
          break;
         case 2: /* _xs_unmock_op */
              gl_overload_ft->op[opid].is_mocked = 0;
          break;
          default:
              croak("Unsupported function at index %d", ix);
              XSRETURN_EMPTY;
      }

      XSRETURN_EMPTY;
 }
 OUTPUT:
     RETVAL


SV*
get_basetime()
CODE:
  RETVAL = newSViv(PL_basetime);
OUTPUT:
  RETVAL


BOOT:
    if (!gl_overload_ft) {
         HV *stash;
         SV *sv;
         int ix = 0;

         Newxz( gl_overload_ft, 1, OverloadFTOps);

         stash = gv_stashpvn("Overload::FileCheck", 19, TRUE);

         newCONSTSUB(stash, "_loaded", newSViv(1) );

         /* provide constants to standardize return values from mocked functions */
         newCONSTSUB(stash, "CHECK_IS_TRUE",         &PL_sv_yes );   /* could use newSViv(1) or &PL_sv_yes */
         newCONSTSUB(stash, "CHECK_IS_FALSE",        &PL_sv_no );    /* could use newSViv(0) or &PL_sv_no  */
         newCONSTSUB(stash, "CHECK_IS_NULL",         &PL_sv_undef ); /* FIXME: need to handle this as a valid answer */
         newCONSTSUB(stash, "FALLBACK_TO_REAL_OP",  newSVnv(-1) );

         /* provide constants to add entry in a fake stat array */

         newCONSTSUB(stash, "ST_DEV",                newSViv(ix++) );
         newCONSTSUB(stash, "ST_INO",                newSViv(ix++) );
         newCONSTSUB(stash, "ST_MODE",               newSViv(ix++) );
         newCONSTSUB(stash, "ST_NLINK",              newSViv(ix++) );
         newCONSTSUB(stash, "ST_UID",                newSViv(ix++) );
         newCONSTSUB(stash, "ST_GID",                newSViv(ix++) );
         newCONSTSUB(stash, "ST_RDEV",               newSViv(ix++) );
         newCONSTSUB(stash, "ST_SIZE",               newSViv(ix++) );
         newCONSTSUB(stash, "ST_ATIME",              newSViv(ix++) );
         newCONSTSUB(stash, "ST_MTIME",              newSViv(ix++) );
         newCONSTSUB(stash, "ST_CTIME",              newSViv(ix++) );
         newCONSTSUB(stash, "ST_BLKSIZE",            newSViv(ix++) );
         newCONSTSUB(stash, "ST_BLOCKS",             newSViv(ix++) );
         assert(STAT_T_MAX == ix);
         newCONSTSUB(stash, "STAT_T_MAX",            newSViv(STAT_T_MAX) );

         /* copy the original OP then plug our own custom OP function */
         /* view pp_sys.c for complete list */

         /* PP(pp_ftrread) - yes/no/undef */
         INIT_FILECHECK_MOCK( "OP_FTRREAD",   OP_FTRREAD,   &Perl_pp_overload_ft_yes_no);   /* -R */
         INIT_FILECHECK_MOCK( "OP_FTRWRITE",  OP_FTRWRITE,  &Perl_pp_overload_ft_yes_no);   /* -W */
         INIT_FILECHECK_MOCK( "OP_FTREXEC",   OP_FTREXEC,   &Perl_pp_overload_ft_yes_no);   /* -X */
         INIT_FILECHECK_MOCK( "OP_FTEREAD",   OP_FTEREAD,   &Perl_pp_overload_ft_yes_no);   /* -r */
         INIT_FILECHECK_MOCK( "OP_FTEWRITE",  OP_FTEWRITE,  &Perl_pp_overload_ft_yes_no);   /* -w */
         INIT_FILECHECK_MOCK( "OP_FTEEXEC",   OP_FTEEXEC,   &Perl_pp_overload_ft_yes_no);   /* -x */

         /* PP(pp_ftis) - yes/undef/true/false */
         INIT_FILECHECK_MOCK( "OP_FTIS",      OP_FTIS,      &Perl_pp_overload_ft_yes_no);   /* -e */
         INIT_FILECHECK_MOCK( "OP_FTSIZE",    OP_FTSIZE,    &Perl_pp_overload_ft_int);   /* -s */
         INIT_FILECHECK_MOCK( "OP_FTMTIME",   OP_FTMTIME,   &Perl_pp_overload_ft_nv);   /* -M */
         INIT_FILECHECK_MOCK( "OP_FTCTIME",   OP_FTCTIME,   &Perl_pp_overload_ft_nv);   /* -C */
         INIT_FILECHECK_MOCK( "OP_FTATIME",   OP_FTATIME,   &Perl_pp_overload_ft_nv);   /* -A */

         /* PP(pp_ftrowned) yes/no/undef */
         INIT_FILECHECK_MOCK( "OP_FTROWNED",  OP_FTROWNED,  &Perl_pp_overload_ft_yes_no);   /* -O */
         INIT_FILECHECK_MOCK( "OP_FTEOWNED",  OP_FTEOWNED,  &Perl_pp_overload_ft_yes_no);   /* -o */
         INIT_FILECHECK_MOCK( "OP_FTZERO",    OP_FTZERO,    &Perl_pp_overload_ft_yes_no);   /* -z */
         INIT_FILECHECK_MOCK( "OP_FTSOCK",    OP_FTSOCK,    &Perl_pp_overload_ft_yes_no);   /* -S */
         INIT_FILECHECK_MOCK( "OP_FTCHR",     OP_FTCHR,     &Perl_pp_overload_ft_yes_no);   /* -c */
         INIT_FILECHECK_MOCK( "OP_FTBLK",     OP_FTBLK,     &Perl_pp_overload_ft_yes_no);   /* -b */
         INIT_FILECHECK_MOCK( "OP_FTFILE",    OP_FTFILE,    &Perl_pp_overload_ft_yes_no);   /* -f */
         INIT_FILECHECK_MOCK( "OP_FTDIR",     OP_FTDIR,     &Perl_pp_overload_ft_yes_no);   /* -d */
         INIT_FILECHECK_MOCK( "OP_FTPIPE",    OP_FTPIPE,    &Perl_pp_overload_ft_yes_no);   /* -p */
         INIT_FILECHECK_MOCK( "OP_FTSUID",    OP_FTSUID,    &Perl_pp_overload_ft_yes_no);   /* -u */
         INIT_FILECHECK_MOCK( "OP_FTSGID",    OP_FTSGID,    &Perl_pp_overload_ft_yes_no);   /* -g */
         INIT_FILECHECK_MOCK( "OP_FTSVTX",    OP_FTSVTX,    &Perl_pp_overload_ft_yes_no);   /* -k */

         /* PP(pp_ftlink) - yes/no/undef */
         INIT_FILECHECK_MOCK( "OP_FTLINK",    OP_FTLINK,    &Perl_pp_overload_ft_yes_no);   /* -l */

         /* PP(pp_fttty) - yes/no/undef */
         INIT_FILECHECK_MOCK( "OP_FTTTY",     OP_FTTTY,     &Perl_pp_overload_ft_yes_no);   /* -t */

        /* PP(pp_fttext) - yes/no/undef */
         INIT_FILECHECK_MOCK( "OP_FTTEXT",    OP_FTTEXT,    &Perl_pp_overload_ft_yes_no);   /* -T */
         INIT_FILECHECK_MOCK( "OP_FTBINARY",  OP_FTBINARY,  &Perl_pp_overload_ft_yes_no);   /* -B */

         /* PP(pp_stat) also used for: pp_lstat() */
         INIT_FILECHECK_MOCK( "OP_STAT",      OP_STAT,      &Perl_pp_overload_stat);        /* stat */
         INIT_FILECHECK_MOCK( "OP_LSTAT",     OP_LSTAT,     &Perl_pp_overload_stat);        /* lstat */

    }


