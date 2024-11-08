#include "perlbolt.h"
#include "ppport.h"

#define NVCLASS "Neo4j::Bolt::NeoValue"

struct neovalue {
  neo4j_value_t value;
};
typedef struct neovalue neovalue_t;

SV *_new_from_perl (const char* classname, SV *v) {
   SV *neosv, *neosv_ref;
   neovalue_t *obj;
   Newx(obj, 1, neovalue_t);
   obj->value = SV_to_neo4j_value(v);
   neosv = newSViv((IV) obj);
   neosv_ref = newRV_noinc(neosv);
   sv_bless(neosv_ref, gv_stashpv(classname, GV_ADD));
   SvREADONLY_on(neosv);
   return neosv_ref;
}

const char* _neotype (SV *obj) {
  neo4j_value_t v;
  v = C_PTR_OF(obj,neovalue_t)->value;
  return neo4j_typestr( neo4j_type( v ) );
}

SV* _as_perl (SV *obj) {
  SV *ret;
  ret = newSV(0);
  sv_setsv(ret,neo4j_value_to_SV( C_PTR_OF(obj, neovalue_t)->value ));
  return ret;
}

int _map_size (SV *obj) {
  return neo4j_map_size( C_PTR_OF(obj, neovalue_t)->value );
}

SV* is_bool (SV *sv) {
  SV *ref;
  if (! SvOK(sv)) {
    return &PL_sv_no;
  }
  SvGETMAGIC(sv);
  if (SvROK(sv)) {
    ref = SvRV(sv);
    if (SvTYPE(ref) < SVt_PVAV) { // scalar ref
      if (SvOBJECT(ref) && sv_isa(sv, "JSON::PP::Boolean")) {
        return &PL_sv_yes;
      }
      if (SvIOK(ref) && SvIV(ref) >> 1 == 0) { // literal \1 or \0
        return &PL_sv_yes;
      }
    }
  }
#if PERL_VERSION_GE(5,36,0)
  else if (SvIsBOOL(sv)) {
    return &PL_sv_yes;
  }
#endif
  return &PL_sv_no;
}

void DESTROY(SV *obj) {
  neo4j_value_t *val = C_PTR_OF(obj, neo4j_value_t);
  return;
}


MODULE = Neo4j::Bolt::NeoValue  PACKAGE = Neo4j::Bolt::NeoValue  

PROTOTYPES: DISABLE


SV *
_new_from_perl (classname, v)
	const char *	classname
	SV *	v

const char *
_neotype (obj)
	SV *	obj

SV *
_as_perl (obj)
	SV *	obj

int
_map_size (obj)
	SV *	obj

SV *
is_bool (obj)
	SV *	obj

void
DESTROY (obj)
	SV *	obj
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        DESTROY(obj);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

