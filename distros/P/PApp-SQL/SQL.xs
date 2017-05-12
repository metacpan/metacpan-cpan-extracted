#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/* import some stuff from DBIXS.h and DBI.xs */
#define DBIXS_VERSION 93
#define DBI_MAGIC '~'

#define DBISTATE_PERLNAME "DBI::_dbistate"
#define DBISTATE_ADDRSV   (perl_get_sv (DBISTATE_PERLNAME, 0x05))
#define DBIS_PUBLISHED_LVALUE (*(INT2PTR(dbistate_t**, &SvIVX(DBISTATE_ADDRSV))))

static SV *sql_varchar, *sql_integer, *sql_double;
static SV *tmp_iv;

struct dbistate_st {
#define DBISTATE_VERSION  94    /* Must change whenever dbistate_t does */
    /* this must be the first member in structure                       */
    void (*check_version) _((const char *name,
                int dbis_cv, int dbis_cs, int need_dbixs_cv,
                int drc_s, int dbc_s, int stc_s, int fdc_s));

    /* version and size are used to check for DBI/DBD version mis-match */
    U16 version;        /* version of this structure                    */
    U16 size;
    U16 xs_version;     /* version of the overall DBIXS / DBD interface */
    U16 spare_pad;
};
typedef struct dbistate_st dbistate_t;

#define DBIcf_ACTIVE      0x000004      /* needs finish/disconnect before clear */

typedef U32 imp_sth;

/* not strictly part of the API... */
static imp_sth *
sth_get_imp (SV *sth)
{
  MAGIC *mg = mg_find (SvRV (sth), PERL_MAGIC_tied);
  sth = mg->mg_obj;
  mg = mg_find (SvRV (sth), DBI_MAGIC);
  return (imp_sth *)SvPVX (mg->mg_obj);
}

#define DBI_STH_ACTIVE(imp) (*(imp) & DBIcf_ACTIVE)

/* end of import section */

#if (PERL_VERSION < 5) || ((PERL_VERSION == 5) && (PERL_SUBVERSION <= 6))
# define get_sv      perl_get_sv
# define call_method perl_call_method
# define call_sv     perl_call_sv
#endif

#if (PERL_VERSION > 5) || ((PERL_VERSION == 5) && (PERL_SUBVERSION >= 6))
# define CAN_UTF8 1
#endif

#define MAX_CACHED_STATEMENT_SIZE 2048

static SV *
sql_upgrade_utf8 (SV *sv)
{
#if CAN_UTF8
  if (SvPOKp (sv))
    sv_utf8_upgrade (sv);
#endif
  return sv;
}

static SV *
mortalcopy_and_maybe_force_utf8(int utf8, SV *sv)
{
  sv = sv_mortalcopy (sv);
#if CAN_UTF8
  if (utf8 && SvPOKp (sv))
    SvUTF8_on (sv);
#endif
  return sv;
}

#define maybe_upgrade_utf8(utf8,sv) ((utf8) ? sql_upgrade_utf8 (sv) : (sv))

#define is_dbh(sv) ((sv) && sv_isobject (sv) && sv_derived_from ((sv), "DBI::db"))

typedef struct mc_node
{
  struct mc_node *next;
  HV *stash;
  U32 gen;

  /* DBH */
  SV *prepare;

  /* STH */
  SV *execute;
  SV *bind_param;
  SV *bind_columns;
  SV *fetchrow_arrayref;
  SV *fetchall_arrayref;
  SV *finish;
} mc_node;

static mc_node *first;

static mc_node *
mc_find (HV *stash)
{
  mc_node *mc;
  U32 gen = PL_sub_generation;

#ifdef HvMROMETA
  gen += HvMROMETA (stash)->cache_gen;
#endif

  for (mc = first; mc; mc = mc->next)
    if (mc->stash == stash && mc->gen == gen)
      return mc;

  if (!mc)
    {
      Newz (0, mc, 1, mc_node);
      mc->stash = stash;

      mc->next = first;
      first = mc;
    }
  else
    {
      mc->execute           =
      mc->bind_param        =
      mc->bind_columns      =
      mc->fetchrow_arrayref =
      mc->fetchall_arrayref =
      mc->finish            = 0;
    }

  mc->gen = gen;

  return mc;
}

static void
mc_cache (mc_node *mc, SV **method, const char *name)
{
  *method = (SV *)gv_fetchmethod_autoload (mc->stash, name, 0);

  if (!method)
    croak ("%s: method not found in stash, pelase report.", name);
}

#define mc_cache(mc, method) mc_cache ((mc), &((mc)->method), # method)

typedef struct lru_node
{
  struct lru_node *next;
  struct lru_node *prev;

  U32 hash;
  SV *dbh;
  SV *sql;

  SV *sth;
  imp_sth *sth_imp;

  mc_node *mc;
} lru_node;

static lru_node lru_list;
static int lru_size;
static int lru_maxsize;

#define lru_init() lru_list.next = &lru_list; lru_list.prev = &lru_list /* other fields are zero */

/* this is primitive, yet effective */
/* the returned value must never be zero (or bad things will happen) */
static U32
lru_hash (SV *dbh, SV *sql)
{
  STRLEN i, l;
  char *b = SvPV (sql, l);
  U32 hash = 2166136261;

  hash = (hash ^ (U32)dbh) * 16777619U;
  hash = (hash ^        l) * 16777619U;

  for (i = 7; i < l; i += i >> 2)
    hash = (hash ^  b [i]) * 16777619U;

  return hash;
}

/* fetch and "use" */
static lru_node *
lru_fetch (SV *dbh, SV *sql)
{
  lru_node *n;
  U32 hash;

  dbh = SvRV (dbh);
  hash = lru_hash (dbh, sql);

  n = &lru_list;
  do {
    n = n->next;

    if (!n->hash)
      return 0;
  } while (n->hash != hash
           || DBI_STH_ACTIVE (n->sth_imp)
           || !sv_eq (n->sql, sql)
           || n->dbh != dbh);

  /* found, so return to the start of the list */
  n->prev->next = n->next;
  n->next->prev = n->prev;

  n->next = lru_list.next;
  n->prev = &lru_list;
  lru_list.next->prev = n;
  lru_list.next = n;

  return n;
}

static void
lru_trim (void)
{
  while (lru_size > lru_maxsize)
    {
      /* nuke at the end */
      lru_node *n = lru_list.prev;

      n = lru_list.prev;

      lru_list.prev = n->prev;
      n->prev->next = &lru_list;

      SvREFCNT_dec (n->dbh);
      SvREFCNT_dec (n->sql);
      SvREFCNT_dec (n->sth);
      Safefree (n);
      
      lru_size--;
    }
}

/* store a not-yet existing entry(!) */
static void
lru_store (SV *dbh, SV *sql, SV *sth, mc_node *mc)
{
  lru_node *n;
  U32 hash;

  if (!lru_maxsize)
    return;
  
  dbh = SvRV (dbh);
  hash = lru_hash (dbh, sql);

  lru_size++;
  lru_trim ();

  New (0, n, 1, lru_node);

  n->hash    = hash;
  n->dbh     = dbh; SvREFCNT_inc (dbh); /* note: this is the dbi hash itself, not the reference */
  n->sql     = newSVsv (sql);
  n->sth     = sth; SvREFCNT_inc (sth);
  n->sth_imp = sth_get_imp (sth);
  n->mc      = mc;

  n->next    = lru_list.next;
  n->prev    = &lru_list;
  lru_list.next->prev = n;
  lru_list.next = n;
}

static void
lru_cachesize (int size)
{
  if (size >= 0)
    {
      lru_maxsize = size;
      lru_trim ();
    }
}

static GV *sql_exec;
static GV *DBH;

#define newconstpv(str) newSVpvn ((str), sizeof (str))

MODULE = PApp::SQL		PACKAGE = PApp::SQL

PROTOTYPES: DISABLE

BOOT:
{
   struct dbistate_st *dbis = DBIS_PUBLISHED_LVALUE;

   /* this is actually wrong, we should call the check member, apparently */
   assert (dbis->version == DBISTATE_VERSION);
   assert (dbis->xs_version == DBIXS_VERSION);

   tmp_iv = newSViv (0);

   sql_exec = gv_fetchpv ("PApp::SQL::sql_exec", TRUE, SVt_PV);
   DBH      = gv_fetchpv ("PApp::SQL::DBH"     , TRUE, SVt_PV);

   /* apache might BOOT: twice :( */
   if (lru_size)
     lru_cachesize (0);

   lru_init ();
   lru_cachesize (100);
}

void
boot2 (SV *t_str, SV *t_int, SV *t_dbl)
	CODE:
        sql_varchar = newSVsv (t_str);
        sql_integer = newSVsv (t_int);
        sql_double  = newSVsv (t_dbl);

int
cachesize(size = -1)
	int	size
	CODE:
        RETVAL = lru_maxsize;
        lru_cachesize (size);
        OUTPUT:
        RETVAL

void
sql_exec(...)
	ALIAS:
                sql_uexec     = 1
        	sql_fetch     = 2
                sql_ufetch    = 3
                sql_fetchall  = 4
                sql_ufetchall = 5
                sql_exists    = 6
                sql_uexists   = 7
	PPCODE:
{
	if (items == 0)
          croak ("Usage: sql_exec [database-handle,] [bind-var-refs,... ] \"sql-statement\", [arguments, ...]");
        else
          {
            int i;
            int arg = 0;
            int first_execution = 0;
            int bind_first, bind_last;
            int count;
            lru_node *lru;
            SV *dbh = ST(0);
            SV *sth;
            SV *sql;
            SV *execute;
            mc_node *mc;
            STRLEN dc, dd; /* dummy */
            I32 orig_stack = SP - PL_stack_base;

            /* save our arguments against destruction through function calls */
            SP += items;
            
            /* first check wether we should use an explicit db handle */
            if (!is_dbh (dbh))
              {
                /* the next line doesn't work - check why later maybe */
                /* dbh = get_sv ("DBH", FALSE);
                if (!is_dbh (dbh))
                  {*/
                    dbh = GvSV (DBH);
                    if (!is_dbh (dbh))
                      croak ("sql_exec: no $DBH argument and no fallback in $PApp::SQL::DBH");
                      /*croak ("sql_exec: no $DBH found in current package or in PApp::SQL::");
                  }*/
              }
            else
              arg++; /* we consumed one argument */

            /* be more Coro-friendly by keeping a copy, so different threads */
            /* can replace their global handles */
            dbh = sv_2mortal (newSVsv (dbh));

            /* count the remaining references (for bind_columns) */
            bind_first = arg;
            while (items > arg && SvROK (ST(arg)))
              arg++;

            bind_last = arg;

            /* consume the sql-statement itself */
            if (items <= arg)
              croak ("sql_exec: required argument \"sql-statement\" missing");

            if (!SvPOK (ST(arg)))
              croak ("sql_exec: sql-statement must be a string");

            sql = ST(arg); arg++;

            if ((ix & ~1) == 6)
              {
                SV *neu = sv_2mortal (newSVpv ("select count(*) > 0 from ", 0));
                sv_catsv (neu, sql);
                sv_catpv (neu, " limit 1");
                sql = neu;
                ix -= 4; /* sql_fetch */
              }

            /* now prepare all parameters, by unmagicalising them and upgrading them */
            for (i = arg; i < items; ++i)
              {
                SV *sv = ST (i);

                /* we sv_mortalcopy magical values since DBI seems to have a memory
                 * leak when magical values are passed into execute().
                 */
                if (SvMAGICAL (sv))
                  ST (i) = sv = sv_mortalcopy (sv);

                if ((ix & 1) && SvPOKp (sv) && !SvUTF8 (sv))
                  {
                    ST (i) = sv = sv_mortalcopy (sv);
                    sv_utf8_upgrade (sv);
                  }
              }

            /* check cache for existing statement handle */
            lru = SvCUR (sql) <= MAX_CACHED_STATEMENT_SIZE
                  ? lru_fetch (dbh, sql)
                  : 0;
            if (!lru)
              {
                mc = mc_find (SvSTASH (SvRV (dbh)));

                if (!mc->prepare)
                  mc_cache (mc, prepare);

                PUSHMARK (SP);
                EXTEND (SP, 2);
                PUSHs (dbh);
                PUSHs (sql);
                PUTBACK;
                count = call_sv (mc->prepare, G_SCALAR);
                SPAGAIN;

                if (count != 1)
                  croak ("sql_exec: unable to prepare() statement '%s': %s",
                         SvPV (sql, dc),
                         SvPV (get_sv ("DBI::errstr", TRUE), dd));

                sth = POPs;

                if (!SvROK (sth))
                  croak ("sql_exec: buggy DBD driver, prepare returned non-reference for '%s': %s",
                         SvPV (sql, dc),
                         SvPV (get_sv ("DBI::errstr", TRUE), dd));

                mc = mc_find (SvSTASH (SvRV (sth)));

                if (!mc->bind_param)
                  {
                    mc_cache (mc, bind_param);
                    mc_cache (mc, execute);
                    mc_cache (mc, finish);
                  }

                if (SvCUR (sql) <= MAX_CACHED_STATEMENT_SIZE)
                  lru_store (dbh, sql, sth, mc);

                /* on first execution we unfortunately need to use bind_param
                 * to mark any numeric parameters as such.
                 */
                SvIV_set (tmp_iv, 0);

                while (items > arg)
                  {
                    SV *sv = ST (arg);
                    /* we sv_mortalcopy magical values since DBI seems to have a memory
                     * leak when magical values are passed into execute().
                     */

                    PUSHMARK (SP);
                    EXTEND (SP, 4);
                    PUSHs (sth);
                    SvIVX (tmp_iv)++;
                    PUSHs (tmp_iv);
                    PUSHs (sv);

                    PUSHs (
                       SvPOKp (sv) ? sql_varchar
                     : SvNOKp (sv) ? sql_double
                     : SvIOKp (sv) ? sql_integer
                     :               sql_varchar
                    );

                    PUTBACK;
                    call_sv (mc->bind_param, G_VOID);
                    SPAGAIN;

                    arg++;
                  }

                /* now use execute without any arguments */
                PUSHMARK (SP);
                EXTEND (SP, 1);
                PUSHs (sth);
              }
            else
              {
                sth = sv_2mortal (SvREFCNT_inc (lru->sth));
                mc  = lru->mc;

                /* we have previously executed this statement, so we
                 * use the cached types and use execute with arguments.
                 */

                PUSHMARK (SP);
                EXTEND (SP, items - arg + 1);
                PUSHs (sth);
                while (items > arg)
                  {
                    SV *sv = ST (arg);
                    PUSHs (ST (arg));
                    arg++;
                  }
              }

            PUTBACK;
            /* { static GV *execute;
              if (!execute) execute = gv_fetchmethod_autoload(SvSTASH(SvRV(sth)), "execute", 0);
              count = call_sv(GvCV(execute), G_SCALAR);
             }*/
            count = call_sv (mc->execute, G_SCALAR);
            SPAGAIN;

            if (count != 1)
              croak ("sql_exec: execute() didn't return any value ('%s'): %s",
                     SvPV (sql, dc),
                     SvPV (get_sv ("DBI::errstr", TRUE), dd));

            execute = POPs;

            if (!SvTRUE (execute))
              croak ("sql_exec: unable to execute statement '%s' (%s)",
                     SvPV (sql, dc),
                     SvPV (get_sv ("DBI::errstr", TRUE), dd));

            sv_setsv (GvSV (sql_exec), execute);

            if (bind_first != bind_last)
              {
                PUSHMARK (SP);
                EXTEND (SP, bind_last - bind_first + 2);
                PUSHs (sth);
                do {
#if CAN_UTF8
                  if (ix & 1)
                     SvUTF8_on (SvRV(ST(bind_first)));
#endif
                  PUSHs (ST(bind_first));
                  bind_first++;
                } while (bind_first != bind_last);

                PUTBACK;

                if (!mc->bind_columns)
                  mc_cache (mc, bind_columns);

                count = call_sv (mc->bind_columns, G_SCALAR);

                SPAGAIN;

                if (count != 1)
                  croak ("sql_exec: bind_columns() didn't return any value ('%s'): %s",
                         SvPV (sql, dc),
                         SvPV (get_sv ("DBI::errstr", TRUE), dd));

                if (!SvOK (TOPs))
                  croak ("sql_exec: bind_columns() didn't return a true ('%s'): %s",
                         SvPV (sql, dc),
                         SvPV (get_sv ("DBI::errstr", TRUE), dd));

                POPs;
              }

            if ((ix & ~1) == 2)
              { /* sql_fetch */
                SV *row;

                PUSHMARK (SP);
                XPUSHs (sth);
                PUTBACK;

                if (!mc->fetchrow_arrayref)
                  mc_cache (mc, fetchrow_arrayref);

                count = call_sv (mc->fetchrow_arrayref, G_SCALAR);
                SPAGAIN;

                if (count != 1)
                  abort ();

                row = POPs;

                SP = PL_stack_base + orig_stack;

                if (SvROK (row))
                  {
                    AV *av;

                    switch (GIMME_V)
                      {
                        case G_VOID:
                          /* no thing */
                          break;
                        case G_SCALAR:
                          /* the first element */
                          XPUSHs (mortalcopy_and_maybe_force_utf8 (ix & 1, *av_fetch ((AV *)SvRV (row), 0, 1)));
                          count = 1;
                          break;
                        case G_ARRAY:
                          av = (AV *)SvRV (row);
                          count = AvFILL (av) + 1;
                          EXTEND (SP, count);
                          for (arg = 0; arg < count; arg++)
                            PUSHs (mortalcopy_and_maybe_force_utf8 (ix & 1, AvARRAY (av)[arg]));

                          break;
                        default:
                          abort ();
                      }
                 }
              }
            else if ((ix & ~1) == 4)
              { /* sql_fetchall */
                SV *rows;

                PUSHMARK (SP);
                XPUSHs (sth);
                PUTBACK;

                if (!mc->fetchall_arrayref)
                  mc_cache (mc, fetchall_arrayref);

                count = call_sv (mc->fetchall_arrayref, G_SCALAR);
                SPAGAIN;

                if (count != 1)
                  abort ();

                rows = POPs;

                SP = PL_stack_base + orig_stack;

                if (SvROK (rows))
                  {
                    AV *av = (AV *)SvRV (rows);
                    count = AvFILL (av) + 1;

                    if (count)
                      {
                        int columns = AvFILL ((AV *) SvRV (AvARRAY (av)[0])) + 1; /* columns? */

                        EXTEND (SP, count);
                        if (columns == 1)
                          for (arg = 0; arg < count; arg++)
                            PUSHs (mortalcopy_and_maybe_force_utf8 (ix & 1, AvARRAY ((AV *)SvRV (AvARRAY (av)[arg]))[0]));
                        else
                          for (arg = 0; arg < count; arg++)
                            PUSHs (mortalcopy_and_maybe_force_utf8 (ix & 1, AvARRAY (av)[arg]));
                      }
                 }
              }
            else
              {
                SP = PL_stack_base + orig_stack;
                XPUSHs (sth);
              }

            if (ix > 1 || GIMME_V == G_VOID)
              {
                orig_stack = SP - PL_stack_base;

                PUSHMARK (SP);
                XPUSHs (sth);
                PUTBACK;

                if (!mc->finish)
                  mc_cache (mc, finish);

                call_sv (mc->finish, G_DISCARD);
                SPAGAIN;

                SP = PL_stack_base + orig_stack;
              }
          }
}



