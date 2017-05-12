#ifdef __cplusplus
extern "C" {
#endif
#include <kstat.h>
#include <sys/utsname.h>
#include <sys/sysinfo.h>
#include <sys/flock.h>
#include <sys/dnlc.h>
#include <sys/vmmeter.h>
#undef SP
#include "Kstat.h"
#ifdef __cplusplus
}
#endif

/******************************************************************************/
/* For saving kstat info in the tied hashes */
typedef struct
   {
   char         read;
   char         valid;
   kstat_ctl_t  *kstat_ctl;
   kstat_t      *kstat;
   }
KstatInfo_t;

/* Hash of "module:name" to KSTAT_RAW read function */
static HV* raw_kstat_lookup;
typedef (*kstat_raw_reader_t)(HV*, kstat_t*);

/******************************************************************************/

static void save_flushmeter(HV *self, kstat_t *kp)
{
struct flushmeter *flushmeterp;

/* PERL_ASSERT(kp->ks_ndata == 1); */
PERL_ASSERT(kp->ks_data_size == sizeof(struct flushmeter));
flushmeterp = (struct flushmeter*)(kp->ks_data);

SAVE_UINT32(self, flushmeterp, f_ctx);
SAVE_UINT32(self, flushmeterp, f_segment);
SAVE_UINT32(self, flushmeterp, f_page);
SAVE_UINT32(self, flushmeterp, f_partial);
SAVE_UINT32(self, flushmeterp, f_usr);
SAVE_UINT32(self, flushmeterp, f_region);
}

/******************************************************************************/

static void save_ncstats(HV *self, kstat_t *kp)
{
struct ncstats *ncstatsp;

/* PERL_ASSERT(kp->ks_ndata == 1); */
PERL_ASSERT(kp->ks_data_size == sizeof(struct ncstats));
ncstatsp = (struct ncstats*)(kp->ks_data);

SAVE_INT32(self, ncstatsp, hits);
SAVE_INT32(self, ncstatsp, misses);
SAVE_INT32(self, ncstatsp, enters);
SAVE_INT32(self, ncstatsp, dbl_enters);
SAVE_INT32(self, ncstatsp, long_enter);
SAVE_INT32(self, ncstatsp, long_look);
SAVE_INT32(self, ncstatsp, move_to_front);
SAVE_INT32(self, ncstatsp, purges);
}

/******************************************************************************/

static void save_sysinfo(HV *self, kstat_t *kp)
{
sysinfo_t *sysinfop;

/* PERL_ASSERT(kp->ks_ndata == 1); */
PERL_ASSERT(kp->ks_data_size == sizeof(sysinfo_t));
sysinfop = (sysinfo_t*)(kp->ks_data);

SAVE_UINT32(self, sysinfop, updates);
SAVE_UINT32(self, sysinfop, runque);
SAVE_UINT32(self, sysinfop, runocc);
SAVE_UINT32(self, sysinfop, swpque);
SAVE_UINT32(self, sysinfop, swpocc);
SAVE_UINT32(self, sysinfop, waiting);
}

/******************************************************************************/

static void save_vminfo(HV *self, kstat_t *kp)
{
vminfo_t *vminfop;

/* PERL_ASSERT(kp->ks_ndata == 1); */
PERL_ASSERT(kp->ks_data_size == sizeof(vminfo_t));
vminfop = (vminfo_t*)(kp->ks_data);

SAVE_UINT64(self, vminfop, freemem);
SAVE_UINT64(self, vminfop, swap_resv);
SAVE_UINT64(self, vminfop, swap_alloc);
SAVE_UINT64(self, vminfop, swap_avail);
SAVE_UINT64(self, vminfop, swap_free);
}

/******************************************************************************/

static void save_nfs(HV *self, kstat_t *kp)
{
struct mntinfo_kstat *mntinfop;

/* PERL_ASSERT(kp->ks_ndata == 1); */
PERL_ASSERT(kp->ks_data_size == sizeof(struct mntinfo_kstat));
mntinfop = (struct mntinfo_kstat*)(kp->ks_data);

SAVE_STRING(self, mntinfop, mik_proto);
SAVE_UINT32(self, mntinfop, mik_vers);
SAVE_UINT32(self, mntinfop, mik_flags);
SAVE_UINT32(self, mntinfop, mik_secmod);
SAVE_UINT32(self, mntinfop, mik_curread);
SAVE_UINT32(self, mntinfop, mik_curwrite);
SAVE_INT32(self, mntinfop, mik_retrans);
hv_store(self, "lookup_srtt", 11, NEW_UIV(mntinfop->mik_timers[0].srtt), 0);
hv_store(self, "lookup_deviate", 14,
         NEW_UIV(mntinfop->mik_timers[0].deviate), 0);
hv_store(self, "lookup_rtxcur", 13, NEW_UIV(mntinfop->mik_timers[0].rtxcur), 0);
hv_store(self, "read_srtt", 9, NEW_UIV(mntinfop->mik_timers[1].srtt), 0);
hv_store(self, "read_deviate", 12, NEW_UIV(mntinfop->mik_timers[1].deviate), 0);
hv_store(self, "read_rtxcur", 11, NEW_UIV(mntinfop->mik_timers[1].rtxcur), 0);
hv_store(self, "write_srtt", 10, NEW_UIV(mntinfop->mik_timers[1].srtt), 0);
hv_store(self, "write_deviate", 13,
         NEW_UIV(mntinfop->mik_timers[1].deviate), 0);
hv_store(self, "write_rtxcur", 12, NEW_UIV(mntinfop->mik_timers[1].rtxcur), 0);
SAVE_UINT32(self, mntinfop, mik_noresponse);
SAVE_UINT32(self, mntinfop, mik_failover);
SAVE_UINT32(self, mntinfop, mik_remap);
SAVE_STRING(self, mntinfop, mik_curserver);
}

/******************************************************************************/

static void build_raw_kstat_lookup()
{
struct utsname     un;
kstat_raw_reader_t fnp;

extern void save_2_6_cpu_stat(HV *self, kstat_t *kp);
extern void save_2_6_var(HV *self, kstat_t *kp);
extern void save_2_7_cpu_stat(HV *self, kstat_t *kp);
extern void save_2_7_var(HV *self, kstat_t *kp);

uname(&un);
raw_kstat_lookup = newHV();

SAVE_FNP(raw_kstat_lookup, save_flushmeter, "unix:flushmeter");
SAVE_FNP(raw_kstat_lookup, save_ncstats, "unix:ncstats");
SAVE_FNP(raw_kstat_lookup, save_sysinfo, "unix:sysinfo");
SAVE_FNP(raw_kstat_lookup, save_vminfo, "unix:vminfo");
SAVE_FNP(raw_kstat_lookup, save_nfs, "nfs:mntinfo");
if (strcmp(un.release, "5.7") >= 0)
  {
  SAVE_FNP(raw_kstat_lookup, save_2_7_cpu_stat, "cpu_stat:cpu_stat");
  SAVE_FNP(raw_kstat_lookup, save_2_7_var, "unix:var");
  }
else
  {
  SAVE_FNP(raw_kstat_lookup, save_2_6_cpu_stat, "cpu_stat:cpu_stat");
  SAVE_FNP(raw_kstat_lookup, save_2_6_var, "unix:var");
  }
}

/******************************************************************************/

static kstat_raw_reader_t lookup_raw_kstat_fn(char *module, char *name)
{
char               key[128];
register char      *f, *t;
SV                 **entry;
kstat_raw_reader_t fnp;

/* Copy across module & name, removing any digits */
for (f = module, t = key; *f != '\0'; f++, t++)
   {
   while (*f != '\0' && isdigit(*f)) { f++; }
   *t = *f;
   }
*t++ = ':';
for (f = name; *f != '\0'; f++, t++)
   {
   while (*f != '\0' && isdigit(*f)) { f++; }
   *t = *f;
   }
*t = '\0';

if ((entry = hv_fetch(raw_kstat_lookup, key, strlen(key), FALSE)) == 0)
   { fnp = 0; }
else
   { fnp = (kstat_raw_reader_t)SvIV(*entry); }
return(fnp);
}

/******************************************************************************/
/******************************************************************************/
/**                                                                          **/
/** Code internal to Kstat                                                   **/
/**                                                                          **/
/******************************************************************************/
/******************************************************************************/

static HV *get_tie(SV *self, char *module, int instance, char *name,
                   int *is_new)
{
char str_inst[16];
char *key[3];
int  k;
int  new;
HV   *hash;
HV   *tie;

sprintf(str_inst, "%d", instance);
key[0] = module;
key[1] = str_inst;
key[2] = name;

hash = (HV*)SvRV(self);
for (k = 0; k < 3; k++)
   {
   SV **entry;

   SvREADONLY_off(hash);
   entry = hv_fetch(hash, key[k], strlen(key[k]), TRUE);
   if (! SvOK(*entry))
      {
      HV *newhash;

      newhash = newHV();
      sv_setsv(*entry, newRV_noinc((SV*)newhash));
      if (k < 2) { SvREADONLY_on(newhash); }
      SvREADONLY_on(*entry);
      SvREADONLY_on(hash);
      hash = newhash;
      new = 1;
      }
   else
      {
      SvREADONLY_on(hash);
      hash = (HV*)SvRV(*entry);
      new = 0;
      }
   }

/* Create and bless another hash for the tie, if necessary */
if (new)
   {
   SV *tieref;
   HV *stash;

   tie = newHV();
   tieref = newRV_noinc((SV*)tie);
   stash = gv_stashpv("Solaris::Kstat::Stat", TRUE);
   sv_bless(tieref, stash);

   /* Add TIEHASH magic */
   hv_magic(hash, (GV*)tieref, 'P');
   SvREADONLY_on(hash);
   }

/* Otherwise, just find the existing tied hash */
else
   {
   MAGIC *mg;

   mg = mg_find((SV*)hash, 'P');
   if (mg == 0) { croak("Lost P magic"); }
   tie = (HV*)SvRV(mg->mg_obj);
   }
if (is_new) { *is_new = new; }
return(tie);
}

/******************************************************************************/

static void apply_to_ties(SV* self, void (*fnp)(HV*, void*), void* arg)
{
HV *hash1;
HE *entry1;

long s;

hash1 = (HV*)SvRV(self);
hv_iterinit(hash1);
while (entry1 = hv_iternext(hash1))
   {
   HV *hash2;
   HE *entry2;
   
   hash2 = (HV*)SvRV(hv_iterval(hash1, entry1));
   hv_iterinit(hash2);
   while (entry2 = hv_iternext(hash2))
      {
      HV *hash3;
      HE *entry3;

      hash3 = (HV*)SvRV(hv_iterval(hash2, entry2));
      hv_iterinit(hash3);
      while (entry3 = hv_iternext(hash3))
         {
         HV    *hash4;
         MAGIC *mg;
         HV    *tie;

         hash4 = (HV*)SvRV(hv_iterval(hash3, entry3));
         mg = mg_find((SV*)hash4, 'P');
         if (mg == 0) { croak("Lost P magic"); }
         fnp((HV*)SvRV(mg->mg_obj), arg);
         }
      }
   }
}

/******************************************************************************/

static void set_valid(HV *self, void *arg)
{
MAGIC *mg;

mg = mg_find((SV*)self, '~');
if (mg == 0) { croak("Lost ~ magic"); }
((KstatInfo_t*)SvPVX(mg->mg_obj))->valid = (int)arg;
}

/******************************************************************************/

static void prune_invalid(SV* self)
{
HV     *hash1;
HE     *entry1;
STRLEN klen;

hash1 = (HV*)SvRV(self);
hv_iterinit(hash1);
while (entry1 = hv_iternext(hash1))
   {
   HV *hash2;
   HE *entry2;
   
   hash2 = (HV*)SvRV(hv_iterval(hash1, entry1));
   hv_iterinit(hash2);
   while (entry2 = hv_iternext(hash2))
      {
      HV *hash3;
      HE *entry3;

      hash3 = (HV*)SvRV(hv_iterval(hash2, entry2));
      hv_iterinit(hash3);
      while (entry3 = hv_iternext(hash3))
         {
         HV    *hash4;
         MAGIC *mg;
         HV    *tie;

         hash4 = (HV*)SvRV(hv_iterval(hash3, entry3));
         mg = mg_find((SV*)hash4, 'P');
         if (mg == 0) { croak("Lost P magic"); }
         tie = (HV*)SvRV(mg->mg_obj);
         mg = mg_find((SV*)tie, '~');
         if (mg == 0) { croak("Lost ~ magic"); }
         if (((KstatInfo_t*)SvPVX((SV*)mg->mg_obj))->valid == FALSE)
            {
            hv_delete(hash3, HePV(entry3, klen), klen, G_DISCARD);
            }
         }
      if (HvKEYS(hash3) == 0)
         {
         hv_delete(hash2, HePV(entry2, klen), klen, G_DISCARD);
         }
      }
   if (HvKEYS(hash2) == 0)
      {
      hv_delete(hash1, HePV(entry1, klen), klen, G_DISCARD);
      }
   }
}

/******************************************************************************/
/******************************************************************************/
/**                                                                          **/
/** Code internal to Solaris::Kstat::Stat                                    **/
/**                                                                          **/
/******************************************************************************/
/******************************************************************************/

static void save_named(HV *self, kstat_t *kp)
{
kstat_named_t *knp;
int           n;
SV*           value;

for (n = kp->ks_ndata, knp = KSTAT_NAMED_PTR(kp); n > 0; n--, knp++)
   {
   switch (knp->data_type)
      {
#ifdef __SunOS_5_5_1
      case KSTAT_DATA_CHAR:
         value = newSVpv(knp->value.c, 0);
         break;
      case KSTAT_DATA_LONG:
         value = newSViv(knp->value.l);
         break;
      case KSTAT_DATA_ULONG:
         value = NEW_UIV(knp->value.ul);
         break;
      case KSTAT_DATA_LONGLONG:
         value = NEW_UIV(knp->value.ll);
         break;
      case KSTAT_DATA_ULONGLONG:
         value = NEW_UIV(knp->value.ull);
         break;
      case KSTAT_DATA_FLOAT:
         value = newSVnv(knp->value.f);
         break;
      case KSTAT_DATA_DOUBLE:
         value = newSVnv(knp->value.d);
         break;
#else
      case KSTAT_DATA_CHAR:
         value = newSVpv(knp->value.c, 0);
         break;
      case KSTAT_DATA_INT32:
         value = newSViv(knp->value.i32);
         break;
      case KSTAT_DATA_UINT32:
         value = NEW_UIV(knp->value.ui32);
         break;
      case KSTAT_DATA_INT64:
         value = NEW_UIV(knp->value.i64);
         break;
      case KSTAT_DATA_UINT64:
         value = NEW_UIV(knp->value.ui64);
         break;
#endif
      default:
         croak("kstat_read: invalid data type %d for %s",
               knp->data_type, knp->name);
         break;
      }
   hv_store(self, knp->name, strlen(knp->name), value, 0);
   }
}

/******************************************************************************/

static void save_intr(HV *self, kstat_t *kp)
{
kstat_intr_t *kintrp;
int          i;
static char  *intr_names[] =
   { "hard", "soft", "watchdog", "spurious", "multiple service" };

PERL_ASSERT(kp->ks_ndata == 1);
PERL_ASSERT(kp->ks_data_size == sizeof(kstat_intr_t));
kintrp = KSTAT_INTR_PTR(kp);

for (i = 0; i < KSTAT_NUM_INTRS; i++)
   {
   hv_store(self, intr_names[i], strlen(intr_names[i]),
            NEW_UIV(kintrp->intrs[i]), 0);
   }
}

/******************************************************************************/

static void save_io(HV *self, kstat_t *kp)
{
kstat_io_t *kiop;

PERL_ASSERT(kp->ks_ndata == 1);
PERL_ASSERT(kp->ks_data_size == sizeof(kstat_io_t));
kiop = KSTAT_IO_PTR(kp);
SAVE_UINT64(self, kiop, nread);
SAVE_UINT64(self, kiop, nwritten);
SAVE_UINT32(self, kiop, reads);
SAVE_UINT32(self, kiop, writes);
SAVE_HRTIME(self, kiop, wtime);
SAVE_HRTIME(self, kiop, wlentime);
SAVE_HRTIME(self, kiop, wlastupdate);
SAVE_HRTIME(self, kiop, rtime);
SAVE_HRTIME(self, kiop, rlentime);
SAVE_HRTIME(self, kiop, rlastupdate);
SAVE_UINT32(self, kiop, wcnt);
SAVE_UINT32(self, kiop, rcnt);
}

/******************************************************************************/

static void save_timer(HV *self, kstat_t *kp)
{
kstat_timer_t *ktimerp;

PERL_ASSERT(kp->ks_ndata == 1);
PERL_ASSERT(kp->ks_data_size == sizeof(kstat_timer_t));
ktimerp = KSTAT_TIMER_PTR(kp);
SAVE_STRING(self, ktimerp, name);
SAVE_UINT64(self, ktimerp, num_events);
SAVE_HRTIME(self, ktimerp, elapsed_time);
SAVE_HRTIME(self, ktimerp, min_time);
SAVE_HRTIME(self, ktimerp, max_time);
SAVE_HRTIME(self, ktimerp, start_time);
SAVE_HRTIME(self, ktimerp, stop_time);
}

/******************************************************************************/

void read_kstats(HV *self, int refresh)
{
MAGIC              *mg;
KstatInfo_t        *kip;
kstat_raw_reader_t fnp;

mg = mg_find((SV*)self, '~');
if (mg == 0) { croak("Lost ~ magic"); }
kip = (KstatInfo_t*)SvPVX(mg->mg_obj);
if ((refresh && ! kip->read) || (! refresh && kip->read)) { return; }

if (! kstat_read(kip->kstat_ctl, kip->kstat, 0)) { croak("kstat_read"); }
hv_store(self, "snaptime", 8, NEW_HRTIME(kip->kstat->ks_snaptime), 0);

switch (kip->kstat->ks_type)
   {
   case KSTAT_TYPE_RAW:
      if ((fnp = lookup_raw_kstat_fn(kip->kstat->ks_module,
                                     kip->kstat->ks_name)) != 0)
         { fnp(self, kip->kstat); }
      break;
   case KSTAT_TYPE_NAMED:
      save_named(self, kip->kstat);
      break;
   case KSTAT_TYPE_INTR:
      save_intr(self, kip->kstat);
      break;
   case KSTAT_TYPE_IO:
      save_io(self, kip->kstat);
      break;
   case KSTAT_TYPE_TIMER:
      save_timer(self, kip->kstat);
      break;
   default:
      croak("kstat_read: illegal kstat type %d for %s.%d.%s",
            kip->kstat->ks_type, kip->kstat->ks_module,
            kip->kstat->ks_instance, kip->kstat->ks_name);
      break;
   }

kip->read = TRUE;
}

/******************************************************************************/
/******************************************************************************/
/**                                                                          **/
/** XS code begins here                                                      **/
/**                                                                          **/
/******************************************************************************/
/******************************************************************************/

MODULE = Solaris::Kstat PACKAGE = Solaris::Kstat
PROTOTYPES: ENABLE

BOOT:
   build_raw_kstat_lookup();

SV*
new(class)
   char *class;
PREINIT:
   HV          *stash;
   kstat_ctl_t *kc;
   SV          *kcsv;
   kstat_t     *kp;
   KstatInfo_t kstatinfo;
CODE:
   /* Create a blessed hash ref */
   RETVAL = (SV*)newRV_noinc((SV*)newHV());
   stash = gv_stashpv(class, TRUE);
   sv_bless(RETVAL, stash);

   /* Open the kstats handle & save as ~ magic */
   if ((kc = kstat_open()) == 0) { croak("kstat_open"); }
   
   kcsv = newSVpv((char*)&kc, sizeof(kc));
   sv_magic(SvRV(RETVAL), kcsv, '~', 0, 0);
   SvREFCNT_dec(kcsv);

   kstatinfo.read      = FALSE;
   kstatinfo.valid     = TRUE;
   kstatinfo.kstat_ctl = kc;
   for (kp = kc->kc_chain; kp != 0; kp = kp->ks_next)
      {
      HV *tie;
      SV *kstatsv;

      /* Don't bother storing the kstat headers */
      if (strncmp(kp->ks_name, "kstat_", 6) == 0)
         { continue; }

      /* Don't bother storing raw stats we don't understand */
      if (kp->ks_type == KSTAT_TYPE_RAW &&
          lookup_raw_kstat_fn(kp->ks_module, kp->ks_name) == 0)
         {
#ifdef REPORT_UNKNOWN
         printf("Unknown kstat type %s:%d:%s\n",
                kp->ks_module, kp->ks_instance, kp->ks_name);
#endif
         continue;
         }

      /* Create a 3-layer hash heirarchy - module.instance.name */
      tie = get_tie(RETVAL, kp->ks_module, kp->ks_instance, kp->ks_name, 0);

      /* Save the data necessary to read the kstat info on demand */
      hv_store(tie, "class", 5, newSVpv(kp->ks_class, 0), 0);
      hv_store(tie, "crtime", 6, NEW_HRTIME(kp->ks_crtime), 0);
      kstatinfo.kstat = kp;
      kstatsv = newSVpv((char*)&kstatinfo, sizeof(kstatinfo));
      sv_magic((SV*)tie, kstatsv, '~', 0, 0);
      SvREFCNT_dec(kstatsv);
      }
   SvREADONLY_on(SvRV(RETVAL));
   /* SvREADONLY_on(RETVAL); */
OUTPUT:
   RETVAL

################################################################################

int
update(self)
   SV* self;
PREINIT:
   MAGIC       *mg;
   kstat_ctl_t *kc;
   kstat_t     *kp;
   int         ret;
CODE:
   mg = mg_find(SvRV(self), '~');
   if (mg == 0) { croak("Lost ~ magic"); }
   kc = *(kstat_ctl_t**)SvPVX(mg->mg_obj);

   RETVAL = 0;
   while ((ret = kstat_chain_update(kc)) > 0) { RETVAL = 1; }
   if (ret == -1) { croak("kstat_chain_update"); }

   /* If the kstat chain hasn't changed we can just reread any stats
      that have already been read */
   if (RETVAL == 0)
      {
      apply_to_ties(self, (void(*)(HV*, void*))&read_kstats, (void*)TRUE);
      }

   /* Otherwise we have to update the Perl structure so that it is in-line with
      the new kstat chain.  We do this in such a way as to retain all the
      existing structures, just adding or deleting the bare minimum */
   else
      {
      KstatInfo_t kstatinfo;

      /* Step 1: set the 'invalid' flag on each entry */
      apply_to_ties(self, &set_valid, (void*)FALSE);

      /* Step 2: Set the 'valid' flag on all entries in the kstat list */
      kstatinfo.read      = FALSE;
      kstatinfo.valid     = TRUE;
      kstatinfo.kstat_ctl = kc;
      for (kp = kc->kc_chain; kp != 0; kp = kp->ks_next)
         {
         int new;
         HV  *tie;
         
         /* Don't bother storing the kstat headers or types */
         if (strncmp(kp->ks_name, "kstat_", 6) == 0)
            { continue; }

         /* Don't bother storing raw stats we don't understand */
         if (kp->ks_type == KSTAT_TYPE_RAW &&
             lookup_raw_kstat_fn(kp->ks_module, kp->ks_name) == 0)
            {
#ifdef REPORT_UNKNOWN
            printf("Unknown kstat type %s:%d:%s\n",
                   kp->ks_module, kp->ks_instance, kp->ks_name);
#endif
            continue;
            }

         /* Find the tied hash associated with the kstat entry */
         tie = get_tie(self, kp->ks_module, kp->ks_instance, kp->ks_name, &new);

         /* If newly created we need to store the associated kstat info */
         if (new)
            {
            SV *kstatsv;

            /* Save the data necessary to read the kstat info on demand */
            hv_store(tie, "class", 5, newSVpv(kp->ks_class, 0), 0);
            hv_store(tie, "crtime", 6, NEW_HRTIME(kp->ks_crtime), 0);
            kstatinfo.kstat = kp;
            kstatsv = newSVpv((char*)&kstatinfo, sizeof(kstatinfo));
            sv_magic((SV*)tie, kstatsv, '~', 0, 0);
            SvREFCNT_dec(kstatsv);
            }

         /* If the stats already exist, just update them */
         else
            {
            MAGIC *mg;

            /* Mark the tie as valid */
            mg = mg_find((SV*)tie, '~');
            if (mg == 0) { croak("Lost ~ magic"); }
            ((KstatInfo_t*)SvPVX(mg->mg_obj))->valid = TRUE;

            /* Reread the stats, if they were read previously */
            read_kstats(tie, TRUE);
            }
         }

      /* Step 3: Delete any entries that are still marked as 'invalid' */
      prune_invalid(self);
      }
OUTPUT:
   RETVAL

################################################################################

void
DESTROY(self)
   SV *self;
PREINIT:
   MAGIC       *mg;
   kstat_ctl_t *kc;
CODE:
   mg = mg_find(SvRV(self), '~');
   if (mg == 0) { croak("Lost ~ magic"); }
   kc = *(kstat_ctl_t**)SvPVX(mg->mg_obj);
   if (kstat_close(kc) != 0) { croak("kstat_close"); }

################################################################################

MODULE = Solaris::Kstat PACKAGE = Solaris::Kstat::Stat
PROTOTYPES: ENABLE

SV*
FETCH(self, key)
   SV* self;
   SV* key;
PREINIT:
   char   *k;
   STRLEN klen;
   SV     **value;
CODE:
   self = SvRV(self);
   k = SvPV(key, klen);
   if (strNE(k, "class") && strNE(k, "crtime"))
      { read_kstats((HV*)self, FALSE); }
   value = hv_fetch((HV*)self, k, klen, FALSE);
   if (value) { RETVAL = *value; SvREFCNT_inc(RETVAL); }
   else       { RETVAL = &PL_sv_undef; }
OUTPUT:
   RETVAL

################################################################################

SV*
STORE(self, key, value)
   SV* self;
   SV* key;
   SV* value;
PREINIT:
   char   *k;
   STRLEN klen;
CODE:
   self = SvRV(self);
   k = SvPV(key, klen);
   if (strNE(k, "class") && strNE(k, "crtime"))
      { read_kstats((HV*)self, FALSE); }
   SvREFCNT_inc(value);
   RETVAL = *(hv_store((HV*)self, k, klen, value, 0));
   SvREFCNT_inc(RETVAL);
OUTPUT:
   RETVAL

################################################################################

bool
EXISTS(self, key)
   SV* self;
   SV* key;
PREINIT:
   char *k;
CODE:
   self = SvRV(self);
   k = SvPV(key, PL_na);
   if (strNE(k, "class") && strNE(k, "crtime"))
      { read_kstats((HV*)self, FALSE); }
   RETVAL = hv_exists_ent((HV*)self, key, 0);
OUTPUT:
   RETVAL

################################################################################

SV*
FIRSTKEY(self)
   SV* self;
PREINIT:
   HE *he;
PPCODE:
   self = SvRV(self);
   read_kstats((HV*)self, FALSE);
   hv_iterinit((HV*)self);
   if (he = hv_iternext((HV*)self))
      {
      EXTEND(sp, 1);
      PUSHs(hv_iterkeysv(he));
      }

################################################################################

SV*
NEXTKEY(self, lastkey)
   SV* self;
   SV* lastkey;
PREINIT:
   HE *he;
PPCODE:
   self = SvRV(self);
   if (he = hv_iternext((HV*)self))
      {
      EXTEND(sp, 1);
      PUSHs(hv_iterkeysv(he));
      }

################################################################################

SV*
DELETE(self, key)
   SV *self;
   SV *key;
CODE:
   self = SvRV(self);
   RETVAL = hv_delete_ent((HV*)self, key, 0, 0);
   if (RETVAL) { SvREFCNT_inc(RETVAL); }
   else        { RETVAL = &PL_sv_undef; }
OUTPUT:
   RETVAL

################################################################################

void
CLEAR(self)
   SV* self;
PREINIT:
   MAGIC   *mg;
   KstatInfo_t *kip;
CODE:
   self = SvRV(self);
   hv_clear((HV*)self);
   mg = mg_find(self, '~');
   if (mg == 0) { croak("Lost ~ magic"); }
   kip = (KstatInfo_t*)SvPVX(mg->mg_obj);
   hv_store((HV*)self, "class", 5, newSVpv(kip->kstat->ks_class, 0), 0);
   hv_store((HV*)self, "crtime", 6, NEW_HRTIME(kip->kstat->ks_crtime), 0);

################################################################################
