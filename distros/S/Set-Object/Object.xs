#ifdef __cplusplus
extern "C" {
#endif
#define PERL_POLLUTE
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

#include "ppport.h"

#if __GNUC__ >= 3   /* I guess. */
#define _warn(msg, e...) warn("# (" __FILE__ ":%d): " msg, __LINE__, ##e)
#else
#define _warn warn
#endif

#ifdef SET_DEBUG
/* for debugging object-related functions */
#define IF_DEBUG(e)
/* for debugging scalar-related functions */
#define IF_REMOVE_DEBUG(e) e
#define IF_INSERT_DEBUG(e)
/* for debugging weakref-related functions */
#define IF_SPELL_DEBUG(e) e
#else
#define IF_DEBUG(e)
#define IF_REMOVE_DEBUG(e)
#define IF_INSERT_DEBUG(e)
#define IF_SPELL_DEBUG(e)
#endif

#if (PERL_VERSION > 7) || ( (PERL_VERSION == 7)&&( PERL_SUBVERSION > 2))
#define SET_OBJECT_MAGIC_backref (int)((char)0x9f)
#else
#define SET_OBJECT_MAGIC_backref '~'
#endif

#define __PACKAGE__ "Set::Object"

typedef struct _BUCKET
{
	SV** sv;
	int n;
} BUCKET;

typedef struct _ISET
{
	BUCKET* bucket;
	I32 buckets, elems;
        SV* is_weak;
        HV* flat;
} ISET;

#ifdef USE_ITHREADS
# define MY_CXT_KEY __PACKAGE__ "::_guts" XS_VERSION
# ifndef MY_CXT_CLONE
#  define MY_CXT_CLONE \
    dMY_CXT_SV;                                                      \
    my_cxt_t *my_cxtp = (my_cxt_t*)SvPVX(newSV(sizeof(my_cxt_t)-1)); \
    Copy(INT2PTR(my_cxt_t*, SvUV(my_cxt_sv)), my_cxtp, 1, my_cxt_t); \
    sv_setuv(my_cxt_sv, PTR2UV(my_cxtp))
# endif

typedef struct {
  ISET *s;
} my_cxt_t;

STATIC perl_mutex iset_mutex;

START_MY_CXT
# define THR_LOCK   MUTEX_LOCK(&iset_mutex)
# define THR_UNLOCK MUTEX_UNLOCK(&iset_mutex)

#else
# define THR_LOCK
# define THR_UNLOCK
#endif

#define ISET_HASH(el) ((PTR2UV(el)) >> 4)

#define ISET_INSERT(s, item) \
	     ( SvROK(item) \
	       ? iset_insert_one(s, item) \
               : iset_insert_scalar(s, item) )

int iset_remove_one(ISET* s, SV* el, int spell_in_progress);


int insert_in_bucket(BUCKET* pb, SV* sv)
{
	if (!pb->sv)
	{
		New(0, pb->sv, 1, SV*);
		pb->sv[0] = sv;
		pb->n = 1;
		IF_DEBUG(_warn("inserting %p in bucket %p offset %d", sv, pb, 0));
	}
	else
	{
		SV **iter = pb->sv, **last = pb->sv + pb->n, **hole = 0;

		for (; iter != last; ++iter)
		{
			if (*iter)
			{
				if (*iter == sv)
					return 0;
			}
			else
				hole = iter;
		}

		if (!hole)
		{
			Renew(pb->sv, pb->n + 1, SV*);
			hole = pb->sv + pb->n;
			++pb->n;
		}

		*hole = sv;

		IF_DEBUG(_warn("inserting %p in bucket %p offset %ld", sv, pb, iter - pb->sv));
	}
	return 1;
}

int iset_insert_scalar(ISET* s, SV* sv)
{
  STRLEN len;
  char* key = 0;

  if (!s->flat) {
    IF_INSERT_DEBUG(_warn("iset_insert_scalar(%p): creating scalar hash", s));
    s->flat = newHV();
  }

  if (!SvOK(sv))
     return 0;

  key = SvPV(sv, len);
  IF_INSERT_DEBUG(_warn("iset_insert_scalar(%p): sv (%p, rc = %d, str= '%s')!", s, sv, SvREFCNT(sv), SvPV_nolen(sv)));

  THR_LOCK;
  if (!hv_exists(s->flat, key, len)) {
    if (!hv_store(s->flat, key, len, &PL_sv_undef, 0)) {
      THR_UNLOCK;
      _warn("hv store failed[?] set=%p", s);
    } else {
      THR_UNLOCK;
    }
    IF_INSERT_DEBUG(_warn("iset_insert_scalar(%p): inserted OK!", s));
    return 1;
  }
  else {
    THR_UNLOCK;
    IF_INSERT_DEBUG(_warn("iset_insert_scalar(%p): already there!", s));
    return 0;
  }
}

int iset_remove_scalar(ISET* s, SV* sv)
{
  STRLEN len;
  char* key = 0;

  if (!s->flat || !HvKEYS(s->flat)) {
    //IF_REMOVE_DEBUG(_warn("iset_remove_scalar(%p):'%s' (no hash)", s, SvPV_nolen(sv)));
    return 0;
  }

  IF_REMOVE_DEBUG(_warn("iset_remove_scalar(%p): sv (%p, rc=%d, str='%s')"
#ifdef USE_ITHREADS
			" interp=%p"
#endif
			, s, sv, SvREFCNT(sv), SvPV_nolen(sv)
#ifdef USE_ITHREADS
			, PERL_GET_CONTEXT
#endif
			));
  key = SvPV(sv, len);

  THR_LOCK;
  if ( hv_delete(s->flat, key, len, 0) ) {
    THR_UNLOCK;
    IF_REMOVE_DEBUG(_warn("iset_remove_scalar(%p): deleted key '%s'", s, key));
    return 1;

  } else {
    THR_UNLOCK;
    IF_REMOVE_DEBUG(_warn("iset_remove_scalar(%p): key '%s' not found", s, key));
    return 0;
  }
  
}

bool iset_includes_scalar(ISET* s, SV* sv)
{
  if (s->flat && HvKEYS(s->flat)) {
    STRLEN len;
    char* key = SvPV(sv, len);
    return hv_exists(s->flat, key, len);
  }
  else {
    return 0;
  }
}

void _cast_magic(ISET* s, SV* sv);

int iset_insert_one(ISET* s, SV* rv)
{
	I32 hash, index;
	SV* el;
	int ins = 0;

	if (!SvROK(rv))
	    Perl_croak(aTHX_ "Tried to insert a non-reference into a Set::Object");

	el = SvRV(rv);

	if (!s->buckets)
	{
		Newz(0, s->bucket, 8, BUCKET);
		s->buckets = 8;
	}

	hash = ISET_HASH(el);
	index = hash & (s->buckets - 1);

	if (insert_in_bucket(s->bucket + index, el))
	{
		++s->elems;
		++ins;
		if (s->is_weak) {
		    IF_DEBUG(_warn("rc of %p left as-is, casting magic", el));
		    _cast_magic(s, el);
		} else {
		    SvREFCNT_inc(el);
		    IF_DEBUG(_warn("rc of %p bumped to %d", el, SvREFCNT(el)));
		}
	}

	if (s->elems > s->buckets)
	{
		int oldn = s->buckets;
		int newn = oldn << 1;

		BUCKET *bucket_first, *bucket_iter, *bucket_last, *new_bucket;
		int i;

		IF_DEBUG(_warn("Reindexing, n = %d", s->elems));

		Renew(s->bucket, newn, BUCKET);
		Zero(s->bucket + oldn, oldn, BUCKET);
		s->buckets = newn;

		bucket_first = s->bucket;
		bucket_iter = bucket_first;
		bucket_last = bucket_iter + oldn;

		for (i = 0; bucket_iter != bucket_last; ++bucket_iter, ++i)
		{
			SV **el_iter, **el_last, **el_out_iter;
			I32 new_bucket_size;

			if (!bucket_iter->sv)
				continue;

			el_iter = bucket_iter->sv;
			el_last = el_iter + bucket_iter->n;
			el_out_iter = el_iter;

			for (; el_iter != el_last; ++el_iter)
			{
				SV* sv = *el_iter;
				I32 hash = ISET_HASH(sv);
				I32 index = hash & (newn - 1);

				if (index == i)
				{
					*el_out_iter++ = *el_iter;
					continue;
				}

				new_bucket = bucket_first + index;
				IF_DEBUG(_warn("%p moved from bucket %d:%p to %d:%p",
					       sv, i, bucket_iter, index, new_bucket));
				insert_in_bucket(new_bucket, sv);
			}
         
			new_bucket_size = el_out_iter - bucket_iter->sv;

			if (!new_bucket_size)
			{
				Safefree(bucket_iter->sv);
				bucket_iter->sv = 0;
				bucket_iter->n = 0;
			}

			else if (new_bucket_size < bucket_iter->n)
			{
				Renew(bucket_iter->sv, new_bucket_size, SV*);
				bucket_iter->n = new_bucket_size;
			}
		}
	}
	return ins;
}

void _dispel_magic(ISET* s, SV* sv);

void iset_clear(ISET* s)
{
	BUCKET* bucket_iter = s->bucket;
	BUCKET* bucket_last = bucket_iter + s->buckets;

	for (; bucket_iter != bucket_last; ++bucket_iter)
	{
		SV **el_iter, **el_last;

		if (!bucket_iter->sv)
		  continue;

		el_iter = bucket_iter->sv;
		el_last = el_iter + bucket_iter->n;

		for (; el_iter != el_last; ++el_iter)
		{
			if (*el_iter)
			{
				IF_DEBUG(_warn("freeing %p, rc = %d, bucket = %p(%ld)) pos = %ld",
					 *el_iter, SvREFCNT(*el_iter),
					 bucket_iter, bucket_iter - s->bucket,
					 el_iter - bucket_iter->sv));

				if (s->is_weak) {
				  IF_SPELL_DEBUG(_warn("dispelling magic"));
				  _dispel_magic(s,*el_iter);
				} else {
				  IF_SPELL_DEBUG(_warn("removing element"));
				  SvREFCNT_dec(*el_iter);
				}
				*el_iter = 0;
			}
		}

		Safefree(bucket_iter->sv);

		bucket_iter->sv = 0;
		bucket_iter->n = 0;
	}

	Safefree(s->bucket);
	s->bucket = 0;
	s->buckets = 0;
	s->elems = 0;
}


MAGIC*
_detect_magic(SV* sv) {
  if (SvMAGICAL(sv))
    return mg_find(sv, SET_OBJECT_MAGIC_backref);
  else
    return NULL;
}

void
_dispel_magic(ISET* s, SV* sv) {
    SV* self_svrv = s->is_weak;
    MAGIC* mg = _detect_magic(sv);
    IF_SPELL_DEBUG(_warn("dispelling magic from %p (self = %p, mg = %p)",
			 sv, self_svrv, mg));
    if (mg) {
       AV* wand = (void *)(mg->mg_obj);
       SV ** const svp = AvARRAY(wand);
       I32 i = AvFILLp(wand);
       int c = 0;

       assert( SvTYPE(wand) == SVt_PVAV );

       while (i >= 0) {
	 if (svp[i] && SvIOK(svp[i]) && SvIV(svp[i])) {
	   ISET* o = INT2PTR(ISET*, SvIV(svp[i]));
	   if (s == o) {
	     /*
	     SPELL_DEBUG("dropping RC of %p from %d to %d",
			 svp[i], SvREFCNT(svp[i]), SvREFCNT(svp[i])-1);
	     SvREFCNT_dec(svp[i]);
	     */
	     svp[i] = newSViv(0);
	   } else {
	     c++;
	   }
	 }
	 i--;
       }
       if (!c) {
         sv_unmagic(sv, SET_OBJECT_MAGIC_backref);
         SvREFCNT_dec(wand);
       }
    }
}

void
_fiddle_strength(ISET* s, const int strong) {

      BUCKET* bucket_iter = s->bucket;
      BUCKET* bucket_last = bucket_iter + s->buckets;

      THR_LOCK;
      for (; bucket_iter != bucket_last; ++bucket_iter)
      {
         SV **el_iter, **el_last;

         if (!bucket_iter->sv)
            continue;

         el_iter = bucket_iter->sv;
         el_last = el_iter + bucket_iter->n;

         for (; el_iter != el_last; ++el_iter)
            if (*el_iter) {
	      if (strong) {
		THR_UNLOCK;
		_dispel_magic(s, *el_iter);
		SvREFCNT_inc(*el_iter);
		IF_DEBUG(_warn("bumped RC of %p to %d", *el_iter,
			       SvREFCNT(*el_iter)));
		THR_LOCK;
	      }
	      else {
		THR_UNLOCK;
		if ( SvREFCNT(*el_iter) > 1 )
		  _cast_magic(s, *el_iter);
		SvREFCNT_dec(*el_iter);
		IF_DEBUG(_warn("reduced RC of %p to %d", *el_iter,
			       SvREFCNT(*el_iter)));
		THR_LOCK;
	      }
	    }
      }
      THR_UNLOCK;
}

int
_spell_effect(pTHX_ SV *sv, MAGIC *mg)
{
    AV * const av = (AV*)mg->mg_obj;
    SV ** const svp = AvARRAY(av);
    I32 i = AvFILLp(av);

    IF_SPELL_DEBUG(_warn("_spell_effect (SV=%p, av_len=%d)", sv,
			 av_len(av)));

    while (i >= 0) {
        IF_SPELL_DEBUG(_warn("_spell_effect %d", i));
	if (svp[i] && SvIOK(svp[i]) && SvIV(svp[i])) {
	  ISET* s = INT2PTR(ISET*, SvIV(svp[i]));
	  IF_SPELL_DEBUG(_warn("_spell_effect i = %d, SV = %p", i, svp[i]));
	  if (!s->is_weak)
	    Perl_croak(aTHX_ "panic: set_object_magic_killbackrefs (flags=%"UVxf")",
		       (UV)SvFLAGS(svp[i]));
	  /* SvREFCNT_dec(svp[i]); */
	  svp[i] = newSViv(0);
	  if (iset_remove_one(s, sv, 1) != 1) {
	    _warn("Set::Object magic backref hook called on non-existent item (%p, self = %p)", sv, s->is_weak);
	  };
	}
	i--;
    }
    return 0;
}

static MGVTBL SET_OBJECT_vtbl_backref =
 	  {0,	0, 0,	0, MEMBER_TO_FPTR(_spell_effect)};

void
_cast_magic(ISET* s, SV* sv) {
    SV* self_svrv = s->is_weak;
    AV* wand;
    MGVTBL *vtable = &SET_OBJECT_vtbl_backref;
    MAGIC* mg;
    SV ** svp;
    int how = SET_OBJECT_MAGIC_backref;
    I32 i,l,free;

    mg = _detect_magic(sv);
    if (mg) {
      IF_SPELL_DEBUG(_warn("sv_magicext reusing wand %p for %p", wand, sv));
      wand = (AV *)mg->mg_obj;
      assert( SvTYPE(wand) == SVt_PVAV );
    }
    else {
      wand=newAV();
      IF_SPELL_DEBUG(_warn("sv_magicext(%p, %p, %d, %p, NULL, 0)", sv, wand, how, vtable));
#if (PERL_VERSION > 7) || ( (PERL_VERSION == 7)&&( PERL_SUBVERSION > 2) )
      mg = sv_magicext(sv, (SV *)wand, how, vtable, NULL, 0);
#else
      sv_magic(sv, wand, how, NULL, 0);
      mg = mg_find(sv, SET_OBJECT_MAGIC_backref);
      mg->mg_virtual = &SET_OBJECT_vtbl_backref;
#endif
      mg->mg_flags |= MGf_REFCOUNTED;
      SvRMAGICAL_on(sv);
    }

    svp = AvARRAY(wand);
    i = AvFILLp(wand);
    free = -1;

    while (i >= 0) {
      if (svp[i] && SvIV(svp[i])) {
	ISET* o = INT2PTR(ISET*, SvIV(svp[i]));
	if (s == o)
	  return;
      } else {
	if ( svp[i] ) SvREFCNT_dec(svp[i]);
	svp[i] = NULL;
	free = i;
      }
      i = i - 1;
    }

    if (free == -1) {
      IF_SPELL_DEBUG(_warn("casting self %p with av_push to the end", self_svrv));
      av_push(wand, self_svrv);
    } else {
      IF_SPELL_DEBUG(_warn("casting self %p to slot %d", self_svrv, free));
      svp[free] = self_svrv;
    }

    /*
    SvREFCNT_inc(self_svrv);
    */
}

int
iset_remove_one(ISET* s, SV* el, int spell_in_progress)
{
  SV *referant;
  I32 hash, index;
  SV **el_iter, **el_last, **el_out_iter;
  BUCKET* bucket;

  IF_DEBUG(_warn("removing scalar %p from set %p", el, s));

  /* note an object being destroyed is not SvOK */
  if (!spell_in_progress && !SvOK(el))
    return 0;

  if (SvOK(el) && !SvROK(el)) {
    IF_DEBUG(_warn("scalar is not a ref (flags = 0x%x)", SvFLAGS(el)));
    if (s->flat && HvKEYS(s->flat)) {
      IF_DEBUG(_warn("calling remove_scalar for %p", el));
      if (iset_remove_scalar(s, el))
	return 1;
    }
    return 0;
  }

  referant = (spell_in_progress ? el : SvRV(el));
  hash = ISET_HASH(referant);
  index = hash & (s->buckets - 1);
  bucket = s->bucket + index;

  if (s->buckets == 0)
    return 0;

  if (!bucket->sv)
    return 0;

  el_iter = bucket->sv;
  el_out_iter = el_iter;
  el_last = el_iter + bucket->n;
  IF_DEBUG(_warn("remove: el_last = %p, el_iter = %p", el_last, el_iter));

  THR_LOCK;
  for (; el_iter != el_last; ++el_iter) {
    if (*el_iter == referant) {
      if (s->is_weak) {
	THR_UNLOCK;
	if (!spell_in_progress) {
	  IF_SPELL_DEBUG(_warn("Removing ST(%p) magic", referant));
	  _dispel_magic(s,referant);
	} else {
	  IF_SPELL_DEBUG(_warn("Not removing ST(%p) magic (spell in progress)", referant));
	}
	THR_LOCK;
      } else {
	THR_UNLOCK;
	IF_SPELL_DEBUG(_warn("Not removing ST(%p) magic from Muggle", referant));
	THR_LOCK;
	SvREFCNT_dec(referant);
      }
      *el_iter = 0;
      --s->elems;
      THR_UNLOCK;
      return 1;
    }
    else {
      THR_UNLOCK;
      IF_SPELL_DEBUG(_warn("ST(%p) != %p", referant, *el_iter));
      THR_LOCK;
    }
  }
  THR_UNLOCK;
  return 0;
}
  
MODULE = Set::Object		PACKAGE = Set::Object		

PROTOTYPES: DISABLE

void
new(pkg, ...)
   SV* pkg;

   PPCODE:

   {
     SV* self;
     ISET* s;
     I32 item;
     SV* isv;
	
     New(0, s, 1, ISET);
     s->elems = 0;
     s->buckets = 0;
     s->bucket = NULL;
     s->flat = Nullhv;
     s->is_weak = Nullsv;

     isv = newSViv( PTR2IV(s) );
     sv_2mortal(isv);

     self = newRV_inc(isv);
     sv_2mortal(self);

     sv_bless(self, gv_stashsv(pkg, FALSE));

     for (item = 1; item < items; ++item) {
       ISET_INSERT(s, ST(item));
     }

     IF_DEBUG(_warn("set!"));

     PUSHs(self);
     XSRETURN(1);
   }

void
insert(self, ...)
   SV* self;

   PPCODE:
      ISET* s = INT2PTR(ISET*, SvIV(SvRV(self)));
      I32 item;
      int inserted = 0;

      for (item = 1; item < items; ++item)
      {
	if ((SV*)s == ST(item)) {
	  _warn("INSERTING SET UP OWN ARSE");
	}
	if ISET_INSERT(s, ST(item))
	inserted++;
	IF_DEBUG(_warn("inserting %p %p size = %d", ST(item), SvRV(ST(item)), s->elems));
      }

      XSRETURN_IV(inserted);
  
void
remove(self, ...)
   SV* self;

   PPCODE:

      ISET* s = INT2PTR(ISET*, SvIV(SvRV(self)));
      I32 hash, index, item;
      SV **el_iter, **el_last, **el_out_iter;
      BUCKET* bucket;
      int removed = 0;

      for (item = 1; item < items; ++item)
      {
         SV* el = ST(item);
	 removed += iset_remove_one(s, el, 0);
      }
      XSRETURN_IV(removed);

int
is_null(self)
   SV* self;

   CODE:
   ISET* s = INT2PTR(ISET*, SvIV(SvRV(self)));
   if (s->elems)
     XSRETURN_UNDEF;
   if (s->flat) {
     if (HvKEYS(s->flat)) {
       XSRETURN_UNDEF;
     }
   }
   RETVAL = 1;

   OUTPUT: RETVAL

int
size(self)
   SV* self;

   CODE:
   ISET* s = INT2PTR(ISET*, SvIV(SvRV(self)));
   RETVAL = s->elems + (s->flat ? HvKEYS(s->flat) : 0);

   OUTPUT: RETVAL

int
rc(self)
   SV* self;

   CODE:
   RETVAL = SvREFCNT(self);

   OUTPUT: RETVAL

int
rvrc(self)
   SV* self;

   CODE:
   
   if (SvROK(self)) {
     RETVAL = SvREFCNT(SvRV(self));
   } else {
     XSRETURN_UNDEF;
   }

   OUTPUT: RETVAL

void
includes(self, ...)
   SV* self;

   PPCODE:

      ISET* s = INT2PTR(ISET*, SvIV(SvRV(self)));
      I32 hash, index, item;
      SV **el_iter, **el_last;
      BUCKET* bucket;

      for (item = 1; item < items; ++item)
      {
         SV* el = ST(item);
         SV* rv;

	 if (!SvOK(el))
	   XSRETURN_NO;

	 if (!SvROK(el)) {
	   IF_DEBUG(_warn("includes! el = %s", SvPV_nolen(el)));
	   if (!iset_includes_scalar(s, el))
	     XSRETURN_NO;
	   goto next;
	 }

	 rv = SvRV(el);

         if (!s->buckets)
            XSRETURN_NO;

         hash = ISET_HASH(rv);
         index = hash & (s->buckets - 1);
         bucket = s->bucket + index;

	 IF_DEBUG(_warn("includes: looking for %p in bucket %d:%p",
			rv, index, bucket));

         if (!bucket->sv)
            XSRETURN_NO;

         el_iter = bucket->sv;
         el_last = el_iter + bucket->n;

         for (; el_iter != el_last; ++el_iter)
            if (*el_iter == rv)
               goto next;
            
         XSRETURN_NO;

         next: ;
      }

      XSRETURN_YES;


void
members(self)
   SV* self
   
   PPCODE:

      ISET* s = INT2PTR(ISET*, SvIV(SvRV(self)));
      BUCKET* bucket_iter = s->bucket;
      BUCKET* bucket_last = bucket_iter + s->buckets;

      EXTEND(sp, s->elems + (s->flat ? HvKEYS(s->flat) : 0) );

      for (; bucket_iter != bucket_last; ++bucket_iter)
      {
         SV **el_iter, **el_last;

         if (!bucket_iter->sv)
            continue;

         el_iter = bucket_iter->sv;
         el_last = el_iter + bucket_iter->n;

         for (; el_iter != el_last; ++el_iter)
            if (*el_iter)
			{
				SV* el = newRV(*el_iter);
				if (SvOBJECT(*el_iter)) {
				  sv_bless(el, SvSTASH(*el_iter));
				}
				PUSHs(sv_2mortal(el));
			}
      }

      if (s->flat) {
        int i = 0, num = hv_iterinit(s->flat);

        while (i++ < num) {
	  HE* he = hv_iternext(s->flat);

	  PUSHs(HeSVKEY_force(he));
        }
      }

void
clear(self)
   SV* self

   CODE:
      ISET* s = INT2PTR(ISET*, SvIV(SvRV(self)));

      iset_clear(s);
      if (s->flat) {
	hv_clear(s->flat);
	IF_REMOVE_DEBUG(_warn("iset_clear(%p): cleared", s));
      }
      
void
DESTROY(self)
   SV* self

   CODE:
      ISET* s = INT2PTR(ISET*, SvIV(SvRV(self)));
      if ( s ) {
	sv_setiv(SvRV(self), 0);
	IF_DEBUG(_warn("aargh!"));
	iset_clear(s);
	if (s->flat) {
	  hv_undef(s->flat);
	  SvREFCNT_dec(s->flat);
	}
	Safefree(s);
      }
      
int
is_weak(self)
   SV* self

   CODE:
      ISET* s = INT2PTR(ISET*, SvIV(SvRV(self)));

      RETVAL = !!s->is_weak;

   OUTPUT: RETVAL

void
_weaken(self)
   SV* self

   CODE:
      ISET* s = INT2PTR(ISET*, SvIV(SvRV(self)));

      if (s->is_weak)
        XSRETURN_UNDEF;

      IF_DEBUG(_warn("weakening set (%p)", SvRV(self)));

      s->is_weak = SvRV(self);

      _fiddle_strength(s, 0);

void
_strengthen(self)
   SV* self

   CODE:
      ISET* s = INT2PTR(ISET*, SvIV(SvRV(self)));

      if (!s->is_weak)
        XSRETURN_UNDEF;

	IF_DEBUG(_warn("strengthening set (%p)", SvRV(self)));

      _fiddle_strength(s, 1);

      s->is_weak = 0;

   /* Here are some functions from Scalar::Util; they are so simple,
      that it isn't worth making a dependancy on that module. */

int
is_int(sv)
	SV *sv
PROTOTYPE: $
CODE:
  SvGETMAGIC(sv);
  if ( !SvIOKp(sv) )
     XSRETURN_UNDEF;

  RETVAL = 1;
OUTPUT:
  RETVAL

int
is_string(sv)
	SV *sv
PROTOTYPE: $
CODE:
  SvGETMAGIC(sv);
  if ( !SvPOKp(sv) )
     XSRETURN_UNDEF;

  RETVAL = 1;
OUTPUT:
  RETVAL

int
is_double(sv)
	SV *sv
PROTOTYPE: $
CODE:
  SvGETMAGIC(sv);
  if ( !SvNOKp(sv) )
     XSRETURN_UNDEF;

  RETVAL = 1;
OUTPUT:
  RETVAL

void
get_magic(sv)
	SV *sv
PROTOTYPE: $
CODE:
  MAGIC* mg;
  SV* magic;
  if (! SvROK(sv)) {
     _warn("tried to get magic from non-reference");
     XSRETURN_UNDEF;
  }

  if (! (mg = _detect_magic(SvRV(sv))) )
     XSRETURN_UNDEF;

  IF_SPELL_DEBUG(_warn("found magic on %p - %p", sv, mg));
  IF_SPELL_DEBUG(_warn("mg_obj = %p", mg->mg_obj));

     /*magic = newSV(0);
  SvRV(magic) = mg->mg_obj;
  SvROK_on(magic); */
  POPs;
  magic = newRV_inc(mg->mg_obj);
  PUSHs(magic);
  XSRETURN(1);

SV*
get_flat(sv)
     SV* sv
PROTOTYPE: $
CODE:
  ISET* s = INT2PTR(ISET*, SvIV(SvRV(sv)));
  if (s->flat) {
    RETVAL = newRV_inc((SV *)s->flat);
  } else {
    XSRETURN_UNDEF;
  }
OUTPUT:
  RETVAL

const char *
blessed(sv)
    SV * sv
PROTOTYPE: $
CODE:
{
    if (SvMAGICAL(sv))
	mg_get(sv);
    if(!sv_isobject(sv)) {
	XSRETURN_UNDEF;
    }
    RETVAL = sv_reftype(SvRV(sv),TRUE);
}
OUTPUT:
    RETVAL

const char *
reftype(sv)
    SV * sv
PROTOTYPE: $
CODE:
{
    if (SvMAGICAL(sv))
	mg_get(sv);
    if(!SvROK(sv)) {
	XSRETURN_UNDEF;
    }
    RETVAL = sv_reftype(SvRV(sv),FALSE);
}
OUTPUT:
    RETVAL

UV
refaddr(sv)
    SV * sv
PROTOTYPE: $
CODE:
{
    if(SvROK(sv)) {
	RETVAL = PTR2UV(SvRV(sv));
    } else {
      RETVAL = 0;
    }
}
OUTPUT:
    RETVAL


int
_ish_int(sv)
	SV *sv
PROTOTYPE: $
CODE:
  double dutch;
  int innit;
  STRLEN lp;
  SV * MH;
  /* This function returns the integer value of a passed scalar, as
     long as the scalar can reasonably considered to already be a
     representation of an integer.  This means if you want strings to
     be interpreted as integers, you're going to have to add 0 to
     them. */

  if (SvMAGICAL(sv)) {
    /* probably a tied scalar */
    Perl_croak(aTHX_ "Tied variables not supported");
  }

  if (SvAMAGIC(sv)) {
    /* an overloaded variable.  need to actually call a function to
       get its value. */
    Perl_croak(aTHX_ "Overloaded variables not supported");
  }

  if (SvNIOKp(sv)) {
    /* NOK - the scalar is a double */

    if (SvPOKp(sv)) {
      /* POK - the scalar is also a string. */

      /* we have to be careful; a scalar "2am" or, even worse, "2e6"
         may satisfy this condition if it has been evaluated in
         numeric context.  Remember, we are testing that the value
         could already be considered an _integer_, and AFAIC 2e6 and
         2.0 are floats, end of story. */

      /* So, we stringify the numeric part of the passed SV, turn off
         the NOK bit on the scalar, so as to perform a string
         comparison against the passed in value.  If it is not the
         same, then we almost certainly weren't given an integer. */

      if (SvIOKp(sv)) {
	MH = newSViv(SvIV(sv));
      } else if (SvNOKp(sv)) {
	MH = newSVnv(SvNV(sv));
      }
      sv_2pv(MH, &lp);
      SvPOK_only(MH);

      if (sv_cmp(MH, sv) != 0) {
	XSRETURN_UNDEF;
      }
    }

    if (SvNOKp(sv)) {
      /* How annoying - it's a double */
      dutch = SvNV(sv);
      if (SvIOKp(sv)) {
	innit = SvIV(sv);
      } else {
	innit = (int)dutch;
      }
      if (dutch - innit < (0.000000001)) {
	RETVAL = innit;
      } else {
	XSRETURN_UNDEF;
      }
    } else if (SvIOKp(sv)) {
      RETVAL = SvIV(sv);
    }
  } else {
    XSRETURN_UNDEF;
  }
OUTPUT:
  RETVAL

int
is_overloaded(sv)
	SV *sv
PROTOTYPE: $
CODE:
  SvGETMAGIC(sv);
  if ( !SvAMAGIC(sv) )
     XSRETURN_UNDEF;
  RETVAL = 1;
OUTPUT:
  RETVAL

int
is_object(sv)
	SV *sv
PROTOTYPE: $
CODE:
  SvGETMAGIC(sv);
  if ( !SvOBJECT(sv) )
     XSRETURN_UNDEF;
  RETVAL = 1;
OUTPUT:
  RETVAL

void
_STORABLE_thaw(obj, cloning, serialized, ...)
   SV* obj;

   PPCODE:

   {
	   ISET* s;
	   I32 item;
	   SV* isv;
	
	   New(0, s, 1, ISET);
	   s->elems = 0;
	   s->bucket = 0;
	   s->buckets = 0;
	   s->flat = NULL;
	   s->is_weak = 0;

	   if (!SvROK(obj)) {
	     Perl_croak(aTHX_ "Set::Object::STORABLE_thaw passed a non-reference");
	   }

	   /* FIXME - some random segfaults with 5.6.1, Storable 2.07,
		      freezing closures, and back-references to
		      overloaded objects.  One day I might even
		      understand why :-)

		      Bug in Storable... that's why.  old news.
	    */
	   isv = SvRV(obj);
	   SvIV_set(isv, PTR2IV(s) );
	   SvIOK_on(isv);

	   for (item = 3; item < items; ++item)
	   {
		  ISET_INSERT(s, ST(item));
	   }

      IF_DEBUG(_warn("set!"));

      PUSHs(obj);
      XSRETURN(1);
   }

BOOT:
{
#ifdef USE_ITHREADS
  MY_CXT_INIT;
  MY_CXT.s  = NULL;
  MUTEX_INIT(&iset_mutex);
#endif
}

#ifdef USE_ITHREADS

void
CLONE(...)
PROTOTYPE: DISABLE
PREINIT:
  ISET *old_s;
PPCODE:
 {
  dMY_CXT;
  old_s = MY_CXT.s;
 }
 {
  MY_CXT_CLONE;
  MY_CXT.s = old_s;
 }
 XSRETURN(0);

#endif
