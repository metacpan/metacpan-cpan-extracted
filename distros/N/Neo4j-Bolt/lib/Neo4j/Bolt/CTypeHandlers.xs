#include "perlbolt.h"
#include "ppport.h"
#include "values.h"
#include <string.h>

extern neo4j_value_t neo4j_identity(long long);
extern neo4j_value_t neo4j_node(const neo4j_value_t*);
extern neo4j_value_t neo4j_relationship(const neo4j_value_t*);

/**
Types
NEO4J_BOOL
NEO4J_BYTES
NEO4J_FLOAT
NEO4J_IDENTITY
NEO4J_INT
NEO4J_LIST
NEO4J_MAP
NEO4J_NODE
NEO4J_NULL
NEO4J_PATH
NEO4J_RELATIONSHIP
NEO4J_STRING
**/

neo4j_value_t SViv_to_neo4j_bool (SV *sv);
neo4j_value_t SViv_to_neo4j_int (SV *sv);
neo4j_value_t SVnv_to_neo4j_float (SV *sv);
neo4j_value_t SVpv_to_neo4j_string (SV *sv);
neo4j_value_t AV_to_neo4j_list(AV *av);
neo4j_value_t HV_to_neo4j_map(HV *hv);
neo4j_value_t HV_to_neo4j_node(HV *hv);
neo4j_value_t HV_to_neo4j_relationship(HV *hv);
neo4j_value_t AV_to_neo4j_path(AV *av);
neo4j_value_t SV_to_neo4j_value(SV *sv);

neo4j_value_t object_to_neo4j_value(SV *sv);
neo4j_value_t object_to_neo4j_datetime(SV *sv);
neo4j_value_t object_to_neo4j_duration(SV *sv);
neo4j_value_t object_to_neo4j_point(SV *sv);
neo4j_value_t object_to_neo4j_bytes(SV *sv);

neo4j_value_t SVpv_to_neo4j_elementid(SV *sv);

#ifdef NEO4J_BOLT_TYPES_FAST
neo4j_value_t SViv_to_neo4j_date(SV *sv);
neo4j_value_t SViv_to_neo4j_localtime(SV *sv);

neo4j_value_t HV_to_neo4j_time(HV *hv);
neo4j_value_t HV_to_neo4j_localtime(HV *hv);
neo4j_value_t HV_to_neo4j_date(HV *hv);
neo4j_value_t HV_to_neo4j_datetime(HV *hv);
neo4j_value_t HV_to_neo4j_localdatetime(HV *hv);
neo4j_value_t HV_to_neo4j_duration(HV *hv);

neo4j_value_t HV_to_neo4j_point(HV *hv);
#endif /* NEO4J_BOLT_TYPES_FAST */

SV* neo4j_bool_to_SViv( neo4j_value_t value );
SV* neo4j_bytes_to_SVpv( neo4j_value_t value );
SV* neo4j_float_to_SVnv( neo4j_value_t value );
SV* neo4j_int_to_SViv( neo4j_value_t value );
SV* neo4j_string_to_SVpv( neo4j_value_t value );
HV* neo4j_node_to_HV( neo4j_value_t value );
HV* neo4j_relationship_to_HV( neo4j_value_t value );
AV* neo4j_path_to_AV( neo4j_value_t value);
AV* neo4j_list_to_AV( neo4j_value_t value );
HV* neo4j_map_to_HV( neo4j_value_t value );
SV* neo4j_value_to_SV( neo4j_value_t value );

SV* neo4j_elementid_to_SVpv( neo4j_value_t value);

HV* neo4j_date_to_HV( neo4j_value_t value);
HV* neo4j_time_to_HV( neo4j_value_t value);
HV* neo4j_localtime_to_HV( neo4j_value_t value);
HV* neo4j_datetime_to_HV(neo4j_value_t value);
HV* neo4j_localdatetime_to_HV(neo4j_value_t value);
HV* neo4j_duration_to_HV(neo4j_value_t value);
HV* neo4j_point_to_HV(neo4j_value_t value);

long long neo4j_identity_value(neo4j_value_t value);

neo4j_value_t SViv_to_neo4j_bool (SV *sv) {
  return neo4j_bool( (bool) SvIV(sv) );
}

neo4j_value_t SViv_to_neo4j_int (SV *sv) {
  return neo4j_int( (long long) SvIV(sv) );
}

neo4j_value_t SVnv_to_neo4j_float (SV *sv) {
  return neo4j_float( SvNV(sv) );
}

neo4j_value_t SVpv_to_neo4j_string (SV *sv) {
  STRLEN len;
  char *k0,*k;
  SV *sv2;
  k = SvPV(sv,len);
  // create duplicate to keep SvPVutf8 from changing the original SV
  sv2 = newSVpvn_flags(k, len, SvFLAGS(sv) & SVf_UTF8 | SVs_TEMP);
  k = SvPVutf8(sv2, len);
  Newx(k0,len+1,char);
  memcpy(k0,k,(size_t) len);
  *(k0+len) = 0;
  return neo4j_ustring(k0, len);
}

neo4j_value_t SV_to_neo4j_value(SV *sv) {
  SV *ref;
  svtype reftype;
#ifdef NEO4J_BOLT_TYPES_FAST
  bool is_zoned;
#endif /* NEO4J_BOLT_TYPES_FAST */
  
  if ( !SvOK(sv) ) {
    return neo4j_null;
  }
  SvGETMAGIC(sv);
  if (SvROK(sv)) {
    ref = SvRV(sv);
    reftype = SvTYPE(ref);
    
    if (SvOBJECT(ref)) {
      if (reftype < SVt_PVAV) { // blessed scalar ref
        if (sv_isa(sv, "JSON::PP::Boolean")) {
          return SViv_to_neo4j_bool(ref);
        }
      }
      if (reftype == SVt_PVAV) { // blessed array ref
        if (sv_isa(sv, PATH_CLASS)) {
          return AV_to_neo4j_path( (AV*) ref );  // unimplemented
        }
      }
      if (reftype == SVt_PVHV) { // blessed hash ref
        if (sv_isa(sv, NODE_CLASS)) {
          return HV_to_neo4j_node( (HV*) ref );
        }
        if (sv_isa(sv, RELATIONSHIP_CLASS)) {
          return HV_to_neo4j_relationship( (HV*) ref );
        }
#ifdef NEO4J_BOLT_TYPES_FAST
       // special case if it's a Neo4j::Bolt object
       if (sv_isa(sv, DATETIME_CLASS)) {
          // determine type by "signature"
          if (hv_fetchs((HV*) ref, "epoch_days", 0) != NULL) {
            return HV_to_neo4j_date( (HV*) ref );
          }
          is_zoned = hv_fetchs((HV*) ref, "offset_secs", 0) != NULL
                  || hv_fetchs((HV*) ref, "tz_name", 0) != NULL;
          if (hv_fetchs((HV*) ref, "epoch_secs", 0) != NULL) {
            return is_zoned
                   ? HV_to_neo4j_datetime( (HV*) ref )
                   : HV_to_neo4j_localdatetime( (HV*) ref );
          }
          else {
            return is_zoned
                   ? HV_to_neo4j_time( (HV*) ref )
                   : HV_to_neo4j_localtime( (HV*) ref );
          }
        }
        if (sv_isa(sv, DURATION_CLASS)) {
          return HV_to_neo4j_duration( (HV*) ref );
        }
        if (sv_isa(sv, POINT_CLASS)) {
          return HV_to_neo4j_point( (HV*) ref );
        }
#endif /* NEO4J_BOLT_TYPES_FAST */
      }
      return object_to_neo4j_value(sv);
    }
    
    if (reftype < SVt_PVAV) { // unblessed scalar ref
      if (SvIOK(ref) && SvIV(ref) >> 1 == 0) { // literal \1 or \0
        return SViv_to_neo4j_bool(ref);
      }
      return SV_to_neo4j_value(ref);
    }
    if (reftype == SVt_PVAV) { // unblessed array ref
      return AV_to_neo4j_list( (AV*) ref );
    }
    if (reftype == SVt_PVHV) { // unblessed hash ref
      return HV_to_neo4j_map( (HV*) ref );
    }
    warn("Unknown reference type (%i) encountered", reftype);
    return neo4j_null;
    
  }
  else { // scalar
#if PERL_VERSION_GE(5,36,0)
    if (SvIsBOOL(sv)) {
      return neo4j_bool( SvTRUE(sv) );
    }
#endif
    if (SvNIOK(sv) && ! SvPOK(sv)) { // created_as_number
      if (SvIOK(sv)) {
        return SViv_to_neo4j_int(sv);
      }
      else {
        return SVnv_to_neo4j_float(sv);
      }
    }
    if (SvPOK(sv)) {
      return SVpv_to_neo4j_string(sv);
    }
  }
  perror("Can't handle this scalar");
  return neo4j_null;
}

neo4j_value_t object_to_neo4j_value(SV *sv) {
  // try to get a neo4j_value_t by using the Neo4j::Types API
  dSP;
  I32 count;
  SV *ref;
  svtype reftype;
  
  ENTER;
  SAVETMPS;
  
  enum {
    DateTime, Duration, Point, Bytes
  } type;
  for ( type = 0; type < 3; ++type ) {
    PUSHMARK(SP);
    EXTEND(SP, 2);
    PUSHs(sv);
    switch (type) {
      case DateTime: mPUSHs(newSVpvs("Neo4j::Types::DateTime"));  break;
      case Duration: mPUSHs(newSVpvs("Neo4j::Types::Duration"));  break;
      case Point:    mPUSHs(newSVpvs("Neo4j::Types::Point"));     break;
      case Bytes:    mPUSHs(newSVpvs("Neo4j::Types::ByteArray")); break;
    }
    PUTBACK;
    count = call_method("isa", G_SCALAR);
    if (count != 1) {
      croak("isa returned %i values, 1 was expected", (int)count);
    }
    SPAGAIN;
    if (POPi) {
      break;
    }
  }
  
  PUTBACK;
  FREETMPS;
  LEAVE;
  
  switch (type) {
    case DateTime:
      return object_to_neo4j_datetime( sv );
    case Duration:
      return object_to_neo4j_duration( sv );
    case Point:
      return object_to_neo4j_point( sv );
    case Bytes:
      return object_to_neo4j_bytes( sv );
  }
  
  ref = SvRV(sv);
  reftype = SvTYPE(ref);
  warn("Class %s is not a Neo4j::Types implementation", sv_reftype(ref, 1));
  switch (reftype) {
    case SVt_PVAV:
      return AV_to_neo4j_list( (AV*) ref );
    case SVt_PVHV:
      return HV_to_neo4j_map( (HV*) ref );
    default:
      return neo4j_null;
  }
}

neo4j_value_t object_to_neo4j_datetime(SV *sv) {
  dSP;
  I32 count;
  int i;
  U32 ok[4], tz_name_ok;
  IV iv[4];
  SV *iv_sv, *tz_name_sv;
  neo4j_value_t tz_name, *fields;
  
  ENTER;
  SAVETMPS;
  
  enum {
    days, seconds, nanos, tz_offset
  };
  static const char * const methods[4] = {
    "days", "seconds", "nanoseconds", "tz_offset"
  };
  for (i = 0; i < 4; ++i) {
    PUSHMARK(SP);
    XPUSHs(sv);
    PUTBACK;
    count = call_method(methods[i], G_SCALAR);
    if (count != 1) {
      croak("Neo4j::Types::DateTime::%s returned %i values, 1 was expected", methods[i], (int)count);
    }
    SPAGAIN;
    iv_sv = POPs;
    ok[i] = SvOK(iv_sv);
    iv[i] = ok[i] ? SvIV(iv_sv) : 0;
  }
  
  PUSHMARK(SP);
  XPUSHs(sv);
  PUTBACK;
  count = call_method("tz_name", G_SCALAR);
  if (count != 1) {
    croak("Neo4j::Types::DateTime::tz_name returned %i values, 1 was expected", (int)count);
  }
  SPAGAIN;
  tz_name_sv = POPs;
  tz_name_ok = SvOK(tz_name_sv);
  if (tz_name_ok) {
    tz_name = SVpv_to_neo4j_string(tz_name_sv);
  }
  
  PUTBACK;
  FREETMPS;
  LEAVE;
  
  if (ok[seconds] || ok[nanos]) {
    if (ok[days]) {
      if (ok[tz_offset] || tz_name_ok) { // ZONED DATETIME
        Newx(fields, 3, neo4j_value_t);
        fields[0] = neo4j_int( (long long) iv[days] * 86400LL + iv[seconds] );
        fields[1] = neo4j_int( (long long) iv[nanos] );
        if (tz_name_ok) {
          //fields[2] = tz_name;
          //return neo4j_datetimezoneid(fields);
          if (! ok[tz_offset]) {
            warn("Named timezones unsupported by Neo4j::Bolt");
            return neo4j_null;
          }
        }
        //else {
          fields[2] = neo4j_int( (long long) iv[tz_offset] );
          return neo4j_datetime(fields);
        //}
      }
      else { // LOCAL DATETIME
        Newx(fields, 2, neo4j_value_t);
        fields[0] = neo4j_int( (long long) iv[days] * 86400LL + iv[seconds] );
        fields[1] = neo4j_int( (long long) iv[nanos] );
        return neo4j_localdatetime(fields);
      }
    }
    else {
      if (ok[tz_offset]) { // ZONED TIME
        Newx(fields, 2, neo4j_value_t);
        fields[0] = neo4j_int( (long long) iv[seconds] * 1000000000LL + iv[nanos] );
        fields[1] = neo4j_int( (long long) iv[tz_offset] );
        return neo4j_time(fields);
      }
      else { // LOCAL TIME
        Newx(fields, 1, neo4j_value_t);
        fields[0] = neo4j_int( (long long) iv[seconds] * 1000000000LL + iv[nanos] );
        return neo4j_localtime(fields);
      }
    }
  }
  else { // DATE
    Newx(fields, 1, neo4j_value_t);
    fields[0] = neo4j_int( (long long) iv[days] );
    return neo4j_date(fields);
  }
}

neo4j_value_t object_to_neo4j_duration(SV *sv) {
  dSP;
  I32 count;
  int i;
  neo4j_value_t *fields;
  Newx(fields, 4, neo4j_value_t);
  
  ENTER;
  SAVETMPS;
  
  static const char * const methods[4] = {
    "months", "days", "seconds", "nanoseconds"
  };
  for (i = 0; i < 4; ++i) {
    PUSHMARK(SP);
    XPUSHs(sv);
    PUTBACK;
    count = call_method(methods[i], G_SCALAR);
    if (count != 1) {
      croak("Neo4j::Types::Duration::%s returned %i values, 1 was expected", methods[i], (int)count);
    }
    SPAGAIN;
    fields[i] = neo4j_int( POPi );
  }
  
  PUTBACK;
  FREETMPS;
  LEAVE;

  return neo4j_duration(fields);
}

neo4j_value_t object_to_neo4j_point(SV *sv) {
  dSP;
  I32 count;
  neo4j_value_t *fields;
  Newx(fields, 4, neo4j_value_t);
  
  ENTER;
  SAVETMPS;
  
  PUSHMARK(SP);
  XPUSHs(sv);
  PUTBACK;
  count = call_method("srid", G_SCALAR);
  if (count != 1) {
    croak("Neo4j::Types::Point::srid returned %i values, 1 was expected", (int)count);
  }
  SPAGAIN;
  fields[0] = neo4j_int( POPi );
  
  PUSHMARK(SP);
  XPUSHs(sv);
  PUTBACK;
  count = call_method("coordinates", G_LIST);
  SPAGAIN;
  for ( ; count > 3 ; --count ) { POPs; }
  fields[3] = neo4j_float( count >= 3 ? POPn : 0.0 ); // z
  fields[2] = neo4j_float( count >= 2 ? POPn : 0.0 ); // y
  fields[1] = neo4j_float( count >= 1 ? POPn : 0.0 ); // x
  
  PUTBACK;
  FREETMPS;
  LEAVE;
  
  if (count == 3) {
    return neo4j_point3d(fields);
  }
  else {
    return neo4j_point2d(fields);
  }
}

neo4j_value_t object_to_neo4j_bytes(SV *sv) {
  dSP;
  I32 count;
  STRLEN len;
  char *pv, *bytes;
  ENTER;
  SAVETMPS;
  PUSHMARK(SP);
  XPUSHs(sv);
  PUTBACK;
  count = call_method("as_string", G_SCALAR);
  if (count != 1) {
    croak("Neo4j::Types::ByteArray::as_string returned %i values, 1 was expected", (int)count);
  }
  SPAGAIN;
  pv = SvPVbytex(POPs, len);
  Newx(bytes, len, char);
  Copy(pv, bytes, len, char);
  PUTBACK;
  FREETMPS;
  LEAVE;
  return neo4j_bytes(bytes, len);
}

neo4j_value_t AV_to_neo4j_list(AV *av) {
  int i,n;
  neo4j_value_t *items;
  n = av_count(av);
  if (n == 0) {
    return neo4j_null;
  }
  Newx(items, n, neo4j_value_t);
  for (i=0;i<n;i++) {
   items[i] = SV_to_neo4j_value( *(av_fetch(av,i,0)) );
  }
  return neo4j_list(items, n);
}

neo4j_value_t HV_to_neo4j_map (HV *hv) {
  HE *ent;
  char *k,*k0;
  SV *v,*ksv;
  int n;
  STRLEN retlen;
  neo4j_map_entry_t *map_ents;
  if (!HvTOTALKEYS(hv)) {
    return neo4j_null;
  }
  Newx(map_ents,HvTOTALKEYS(hv),neo4j_map_entry_t);
  hv_iterinit(hv);
  n=0;
  while ((ent = hv_iternext(hv))) {
    ksv = hv_iterkeysv(ent);
    k = SvPVutf8(ksv, retlen);
    Newx(k0,retlen+1,char);
    memcpy(k0,k,retlen);
    *(k0+retlen)=0;
    map_ents[n] = neo4j_map_entry( k0, SV_to_neo4j_value(hv_iterval(hv,ent)));
    n++;
  }
  return neo4j_map( map_ents, HvTOTALKEYS(hv) );
}

// neo4j_node(neo4j_value_t fields[4]) is not exposed in the API
// fields[0] is a NEO4J_IDENTITY
// fields[1] is a NEO4J_LIST of node labels (NEO4J_STRINGs)
//   (note REST::Neo4p::Node doesn't store a list of labels in the
//   simple rendering! Fix!)
// fields[2] is a NEO4J_MAP of properties
// fields[3] is a NEO4J_ELEMENTID

neo4j_value_t HV_to_neo4j_node(HV *hv) {
  SV **node_id_p, **lbls_ref_p, **props_ref_p, **elt_id_p;
  AV *lbls;
  HV *props;
  neo4j_value_t *fields;
  neo4j_map_entry_t null_ent;
  Newx(fields, 4, neo4j_value_t);

  node_id_p = hv_fetchs(hv, "id", 0);
  lbls_ref_p = hv_fetchs(hv, "labels", 0);
  elt_id_p = hv_fetchs(hv, "element_id", 0);
  if (lbls_ref_p && SvROK(*lbls_ref_p)) {
    lbls = (AV*) SvRV(*lbls_ref_p);
  } else {
    lbls = NULL;
  }
  if (lbls && SvTYPE((SV*)lbls) == SVt_PVAV && av_count(lbls) > 0) {
    fields[1] = AV_to_neo4j_list(lbls);
  } else {
    fields[1] = neo4j_list( &neo4j_null, 0 );
  }
  fields[0] = neo4j_identity( node_id_p ? SvIV( *node_id_p ) : -1 );
  fields[3] = elt_id_p ? SVpv_to_neo4j_elementid( (SV*) *elt_id_p ) :
      neo4j_null;
  props_ref_p = hv_fetchs(hv, "properties", 0);
  if (props_ref_p && SvROK(*props_ref_p)) {
    props = (HV*) SvRV(*props_ref_p);
  } else {
    props = NULL;
  }
  if (props && SvTYPE((SV*)props) == SVt_PVHV && HvTOTALKEYS(props)) {
    fields[2] = HV_to_neo4j_map(props);
  } else {
    null_ent = neo4j_map_entry( "", neo4j_null );
    fields[2] = neo4j_map( &null_ent, 0 );
  }
  return neo4j_node(fields);
}


// neo4j_relationship( neo4j_value_t fields[8] ) is not exposed in API
// field[0] is NEO4J_IDENTITY (id of the relationship)
// field[1] is NEO4J_IDENTITY (id of the start node))
// field[2] is NEO4J_IDENTITY (id of the end node))
// field[3] is NEO4J_STRING (relationship type)
// field[4] is NEO4J_MAP (properties)
// field[5] is NEO4J_ELEMENTID (elt id of the relationship)
// field[6] is NEO4J_ELEMENTID (elt id of the start node))
// field[7] is NEO4J_ELEMENTID (elt id of the end node))

neo4j_value_t HV_to_neo4j_relationship(HV *hv) {
  SV **reln_id_p, **start_id_p, **end_id_p, **type_p, **props_ref_p;
  SV **reln_eid_p, **start_eid_p, **end_eid_p;
  HV *props;
  neo4j_value_t *fields;
  neo4j_map_entry_t null_ent;

  Newx(fields, 8, neo4j_value_t);

  reln_id_p = hv_fetchs(hv, "id", 0);
  start_id_p = hv_fetchs(hv, "start", 0);
  end_id_p = hv_fetchs(hv, "end", 0);
  type_p = hv_fetchs(hv, "type", 0);
  reln_eid_p = hv_fetchs(hv, "element_id", 0);
  start_eid_p = hv_fetchs(hv, "start_element_id", 0);
  end_eid_p = hv_fetchs(hv, "end_element_id", 0);

  fields[0] = neo4j_identity( reln_id_p ? SvIV( *reln_id_p ) : -1 );
  fields[1] = neo4j_identity( start_id_p ? SvIV( *start_id_p ) : -1 );
  fields[2] = neo4j_identity( end_id_p ? SvIV( *end_id_p ) : -1 );
  if (type_p && SvOK(*type_p)) {
    fields[3] = SVpv_to_neo4j_string( *type_p );
  } else {
    fields[3] = neo4j_string("");
  }
  fields[5] = reln_eid_p ? SVpv_to_neo4j_elementid( (SV*) *reln_eid_p ) :
      neo4j_null;
  fields[6] = start_eid_p ? SVpv_to_neo4j_elementid( (SV*) *start_eid_p ) :
      neo4j_null;
  fields[7] = end_eid_p ? SVpv_to_neo4j_elementid( (SV*) *end_eid_p ) :
      neo4j_null;

  props_ref_p = hv_fetch(hv, "properties", 10, 0);
  if (props_ref_p && SvROK(*props_ref_p)) {
    props = (HV*) SvRV(*props_ref_p);
  } else {
    props = NULL;
  }
  if (props && SvTYPE((SV*)props) == SVt_PVHV && HvTOTALKEYS(props)) {
    fields[4] = HV_to_neo4j_map(props);
  } else {
    null_ent = neo4j_map_entry( "", neo4j_null );
    fields[4] = neo4j_map( &null_ent, 0 );
  }
  return neo4j_relationship(fields);
}

neo4j_value_t AV_to_neo4j_path(AV *av) {
  fprintf(stderr, "Not yet implemented");
  return neo4j_null;
}

neo4j_value_t SVpv_to_neo4j_elementid(SV *sv) {
  STRLEN len;
  char *k0,*k;
  SV *sv2;
  k = SvPV(sv,len);
  // create duplicate to keep SvPVutf8 from changing the original SV
  sv2 = newSVpvn_flags(k, len, SvFLAGS(sv) & SVf_UTF8 | SVs_TEMP);
  k = SvPVutf8(sv2, len);
  Newx(k0,len+1,char);
  memcpy(k0,k,(size_t) len);
  *(k0+len) = 0;
  return neo4j_elementid((const char *)k0);
}

#ifdef NEO4J_BOLT_TYPES_FAST
neo4j_value_t SViv_to_neo4j_date(SV *sv) {
    neo4j_value_t *fields;
    Newx(fields, 1, neo4j_value_t);
    fields[0] = SViv_to_neo4j_int(sv);
    return neo4j_date(fields);
}

neo4j_value_t SViv_to_neo4j_localtime(SV *sv) {
    neo4j_value_t *fields;
    Newx(fields, 1, neo4j_value_t);
    fields[0] = SViv_to_neo4j_int(sv);
    return neo4j_localtime(fields);
}

neo4j_value_t HV_to_neo4j_time(HV *hv) {
  neo4j_value_t *fields;
  SV **nsecs_p, **offset_secs_p;
  Newx(fields, 2, neo4j_value_t);
  nsecs_p = hv_fetchs(hv, "nsecs", 0);
  offset_secs_p = hv_fetchs(hv, "offset_secs", 0);
  
  fields[0] = neo4j_int( nsecs_p ? SvIV( *nsecs_p ) : -1 );
  fields[1] = neo4j_int( offset_secs_p ? SvIV( *offset_secs_p ) : 0);
  return neo4j_time(fields);
}

neo4j_value_t HV_to_neo4j_date(HV *hv) {
    SV **svp;
    svp = hv_fetchs(hv, "epoch_days", 0);
    if (svp == NULL) {
	warn("Can't create neo4j_date: no epoch_days value in hash");
	return neo4j_null;
    } else {
	return SViv_to_neo4j_date(*svp);
    }
}

neo4j_value_t HV_to_neo4j_localtime(HV *hv) {
    SV **svp;
    svp = hv_fetchs(hv, "nsecs", 0);
    if (svp == NULL) {
	warn("Can't create neo4j_date: no nsecs value in hash");
	return neo4j_null;
    } else {
	return SViv_to_neo4j_localtime(*svp);
    }
}

neo4j_value_t HV_to_neo4j_datetime(HV *hv) {
  SV **secs_p, **nsecs_p, **offset_p;
  neo4j_value_t *fields;
  Newx(fields, 3, neo4j_value_t);

  secs_p = hv_fetchs(hv, "epoch_secs", 0);
  nsecs_p = hv_fetchs(hv, "nsecs", 0);
  offset_p = hv_fetchs(hv, "offset_secs", 0);

  fields[0] = neo4j_int( secs_p ? SvIV( *secs_p ) : -1 );
  fields[1] = neo4j_int( nsecs_p ? SvIV( *nsecs_p ) : -1 );
  fields[2] = neo4j_int( offset_p ? SvIV( *offset_p ) : -1 );

  return neo4j_datetime(fields);
}

neo4j_value_t HV_to_neo4j_localdatetime(HV *hv) {
  SV **secs_p, **nsecs_p;
  neo4j_value_t *fields;
  Newx(fields, 2, neo4j_value_t);

  secs_p = hv_fetchs(hv, "epoch_secs", 0);
  nsecs_p = hv_fetchs(hv, "nsecs", 0);

  fields[0] = neo4j_int( secs_p ? SvIV( *secs_p ) : -1 );
  fields[1] = neo4j_int( nsecs_p ? SvIV( *nsecs_p ) : -1 );

  return neo4j_localdatetime(fields);
}


neo4j_value_t HV_to_neo4j_duration(HV *hv) {
    SV **months_p, **days_p, **secs_p, **nsecs_p;
  neo4j_value_t *fields;
  Newx(fields, 4, neo4j_value_t);

  months_p = hv_fetchs(hv, "months", 0);
  days_p = hv_fetchs(hv, "days", 0);
  secs_p = hv_fetchs(hv, "secs", 0);
  nsecs_p = hv_fetchs(hv, "nsecs", 0);

  fields[0] = neo4j_int( months_p ? SvIV( *months_p ) : -1 );
  fields[1] = neo4j_int( days_p ? SvIV( *days_p ) : -1 );
  fields[2] = neo4j_int( secs_p ? SvIV( *secs_p ) : -1 );
  fields[3] = neo4j_int( nsecs_p ? SvIV( *nsecs_p ) : -1 );

  return neo4j_duration(fields);
}

neo4j_value_t HV_to_neo4j_point(HV *hv) {
  SV **srid_p, **x_p, **y_p, **z_p;
  neo4j_value_t *fields;
  Newx(fields, 4, neo4j_value_t);

  x_p = hv_fetchs(hv, "x", 0);
  y_p = hv_fetchs(hv, "y", 0);
  z_p = hv_fetchs(hv, "z", 0);
  srid_p = hv_fetchs(hv, "srid", 0);  

  fields[0] = neo4j_int( srid_p ? SvIV( *srid_p ) : -1 );
  fields[1] = neo4j_float( x_p ? SvNV( *x_p ) : 0.0 );
  fields[2] = neo4j_float( y_p ? SvNV( *y_p ) : 0.0 );
  fields[3] = neo4j_float( z_p ? SvNV( *z_p ) : 0.0 );

  if (z_p) {
      return neo4j_point3d(fields);
  }
  else {
      return neo4j_point2d(fields);
  }
}
#endif /* NEO4J_BOLT_TYPES_FAST */

long long neo4j_identity_value(neo4j_value_t value)
{
  value._type = NEO4J_INT;
  return neo4j_int_value(value);
}


SV* neo4j_bool_to_SViv( neo4j_value_t value) {
#if defined(NEO4J_CORE_BOOLS) && PERL_VERSION_GE(5,36,0)
  return newSVsv(neo4j_bool_value(value) ? &PL_sv_yes : &PL_sv_no);
#else
  HV* boolean_stash = gv_stashpv("JSON::PP::Boolean", GV_ADD);
  SV* scalar = newSViv( (IV) neo4j_bool_value(value) );
  return sv_bless(newRV_noinc(scalar), boolean_stash);
#endif /* NEO4J_CORE_BOOLS */
}

SV* neo4j_bytes_to_SVpv( neo4j_value_t value ) {
  HV* bytes_stash = gv_stashpv("Neo4j::Bolt::Bytes", GV_ADD);
  SV* scalar = newSVpvn( neo4j_bytes_value(value),
                         neo4j_bytes_length(value) );
  return sv_bless(newRV_noinc(scalar), bytes_stash);
}

SV* neo4j_float_to_SVnv( neo4j_value_t value ) {
  return newSVnv( neo4j_float_value( value ) );
}

SV* neo4j_int_to_SViv( neo4j_value_t value ) {
  return newSViv( (IV) neo4j_int_value( value ) );
}

SV* neo4j_string_to_SVpv( neo4j_value_t value ) {
  STRLEN len;
  SV* pv;
  len = neo4j_string_length(value);
  pv = len ? newSVpvn(neo4j_ustring_value(value), len) : newSVpvs("");
  sv_utf8_decode(pv);
  return pv;
}

SV* neo4j_elementid_to_SVpv( neo4j_value_t value ) {
  if (neo4j_type(value) == NEO4J_NULL) {
    return newSV(0);
    /* Undefined element IDs exist for nodes in unbound relationships.
     * neo4j_relationship_to_HV() first needs to insert placeholders, before
     * neo4j_path_to_AV() can store the correct node element IDs in the HV.
     */
  }
  return neo4j_string_to_SVpv(value);
}

SV* neo4j_value_to_SV( neo4j_value_t value ) {
  neo4j_type_t the_type;
  the_type = neo4j_type( value );
  if (the_type == NEO4J_BOOL) {
    return neo4j_bool_to_SViv(value);
  }
  else if (the_type == NEO4J_BYTES) {
    return neo4j_bytes_to_SVpv(value);
  }
  else if (the_type == NEO4J_FLOAT) {
    return neo4j_float_to_SVnv(value);
  }
  else if (the_type == NEO4J_INT) {
    return neo4j_int_to_SViv(value);
  }
  else if (the_type == NEO4J_NODE) {
      return value_to_blessed_sv(value,neo4j_node_to_HV,NODE_CLASS);
  }
  else if (the_type == NEO4J_RELATIONSHIP) {
      return value_to_blessed_sv(value,neo4j_relationship_to_HV,RELATIONSHIP_CLASS);
  }
  else if (the_type == NEO4J_NULL) {
    return newSV(0);
  }
  else if (the_type == NEO4J_LIST) {
    return newRV_noinc((SV*)neo4j_list_to_AV( value ));
  }
  else if (the_type == NEO4J_MAP) {
    return newRV_noinc( (SV*)neo4j_map_to_HV( value ));
  }
  else if (the_type == NEO4J_PATH) {
      return value_to_blessed_sv(value,neo4j_path_to_AV,PATH_CLASS);
//    return sv_bless( newRV_noinc((SV*)neo4j_path_to_AV( value )),
//                     gv_stashpv(PATH_CLASS, GV_ADD) );
  }
  else if (the_type == NEO4J_STRING) {
    return neo4j_string_to_SVpv(value);
  }
  else if (the_type == NEO4J_ELEMENTID) {
    return neo4j_elementid_to_SVpv(value);
  }
  else if (the_type == NEO4J_DATE) {
      return value_to_blessed_sv(value,neo4j_date_to_HV,DATETIME_CLASS);
  }
  else if (the_type == NEO4J_TIME) {
      return value_to_blessed_sv(value,neo4j_time_to_HV,DATETIME_CLASS);
  }
  else if (the_type == NEO4J_LOCALTIME) {
      return value_to_blessed_sv(value,neo4j_localtime_to_HV,DATETIME_CLASS);
  }
  else if (the_type == NEO4J_DATETIME) {
      return value_to_blessed_sv(value,neo4j_datetime_to_HV,DATETIME_CLASS);
//    return sv_bless( newRV_noinc((SV*)neo4j_datetime_to_HV( value )),
//                     gv_stashpv(DATETIME_CLASS, GV_ADD) );
  }
  else if (the_type == NEO4J_LOCALDATETIME) {
      return value_to_blessed_sv(value,neo4j_localdatetime_to_HV,DATETIME_CLASS);
  }
  else if (the_type == NEO4J_DURATION) {
      return value_to_blessed_sv(value,neo4j_duration_to_HV,DURATION_CLASS);
  }
  else if (the_type == NEO4J_POINT2D || the_type == NEO4J_POINT3D) {
      return value_to_blessed_sv(value,neo4j_point_to_HV,POINT_CLASS);
  }
  else {
    warn("Unknown neo4j_value type encountered");
    return newSV(0);
  }
}

AV* neo4j_list_to_AV( neo4j_value_t value ) {
  int i,n;
  AV* av;
  neo4j_value_t entry;
  n = neo4j_list_length( value );
  av = newAV();
  for (i=0;i<n;i++) {
    entry = neo4j_list_get(value, i);
    av_push(av, neo4j_value_to_SV( entry ));
  }
  return av;
}

HV* neo4j_map_to_HV( neo4j_value_t value ) {
  int i,n;
  I32 klen;
  const char *ks;
  const neo4j_map_entry_t *entry;
  HV *hv;
  SV *sv;
  hv = newHV();
  n = (int) neo4j_map_size(value);
  for (i=0;i<n;i++) {
    entry = neo4j_map_getentry(value,i);
    klen = neo4j_string_length(entry->key);
    ks = klen ? neo4j_ustring_value(entry->key) : "";
    sv = neo4j_value_to_SV(entry->value);
    if (! is_utf8_invariant_string((U8 *)ks, (STRLEN)klen)) {
      // treat key as utf8 (as opposed to single-byte)
      klen = -klen;
    }
    if (hv_store(hv, ks, klen, sv, 0) == NULL) {
      SvREFCNT_dec(sv);
      fprintf(stderr, "Failed to create hash entry for key '%s'\n",ks);
    }
  }
  return hv;
}

HV* neo4j_node_to_HV( neo4j_value_t value ) {
  HV *hv, *props_hv;
  char *k;
  SV *v;
  neo4j_value_t elt_id;
  I32 retlen;
  long long id;
  neo4j_value_t labels,props;

  hv = newHV();
  id = neo4j_identity_value(neo4j_node_identity(value));
  elt_id = neo4j_node_elementid(value);
  labels = neo4j_node_labels(value);
  props_hv = neo4j_map_to_HV(neo4j_node_properties(value));
  hv_stores(hv, "id", newSViv( (IV) id ));
  hv_stores(hv, "element_id", neo4j_elementid_to_SVpv(elt_id));
  if (neo4j_list_length(labels)) {
    hv_stores(hv, "labels", neo4j_value_to_SV(labels));
  }
  if (HvTOTALKEYS(props_hv)) {
    hv_stores(hv, "properties", newRV_noinc( (SV*) props_hv ));
  }
  return hv;
}

HV* neo4j_relationship_to_HV( neo4j_value_t value ) {
  HV *hv, *props_hv;
  char *k;
  SV *type,*v;
  STRLEN len;
  I32 retlen;
  long long reln_id,start_id,end_id;
  neo4j_value_t elt_id, start_elt_id, end_elt_id;
  hv = newHV();
  reln_id = neo4j_identity_value(neo4j_relationship_identity(value));
  elt_id = neo4j_relationship_elementid(value);
  start_id = neo4j_identity_value(neo4j_relationship_start_node_identity(value));
  start_elt_id = neo4j_relationship_start_node_elementid(value);
  end_id = neo4j_identity_value(neo4j_relationship_end_node_identity(value));
  end_elt_id = neo4j_relationship_end_node_elementid(value);  
  type = neo4j_string_to_SVpv(neo4j_relationship_type(value));
  props_hv = neo4j_map_to_HV(neo4j_relationship_properties(value));
  hv_stores(hv, "id", newSViv( (IV) reln_id ));
  hv_stores(hv, "element_id", neo4j_elementid_to_SVpv( elt_id ));  
  hv_stores(hv, "start", newSViv( (IV) start_id ));
  hv_stores(hv, "start_element_id", neo4j_elementid_to_SVpv( start_elt_id ));  
  hv_stores(hv, "end", newSViv( (IV) end_id ));
  hv_stores(hv, "end_element_id", neo4j_elementid_to_SVpv( end_elt_id ));    
  SvPV(type,len);
  retlen = (I32) len;
  if (retlen) {
    hv_stores(hv, "type", type);
  }
  if (HvTOTALKEYS(props_hv)) {
    hv_stores(hv, "properties", newRV_noinc( (SV*) props_hv ));
  }
  return hv;
}

AV* neo4j_path_to_AV( neo4j_value_t value) {
  int i,n,last_node_id,node_id;
  
  AV* av;
  struct neo4j_struct *v;
  _Bool dir;
  SV* rel_sv;
  neo4j_value_t node, node_elt_id, last_node_elt_id;
  av = newAV();
  n = neo4j_path_length(value);
  node = neo4j_path_get_node(value, 0);
  av_push(av, neo4j_value_to_SV( node ));
  last_node_id = neo4j_identity_value( neo4j_node_identity(node) );
  last_node_elt_id = neo4j_node_elementid(node);
  if (n==0) {
    return av;
  } else {
    for (i=1; i<=n; i++) {
      node = neo4j_path_get_node(value,i);
      node_id = neo4j_identity_value( neo4j_node_identity(node) );
      node_elt_id = neo4j_node_elementid(node);
      rel_sv = neo4j_value_to_SV(neo4j_path_get_relationship(value,i-1,&dir));
      hv_stores( (HV*) SvRV(rel_sv), "start", newSViv( (IV) (dir ? last_node_id : node_id)));
      hv_stores(
	  (HV*) SvRV(rel_sv), "start_element_id",
	  neo4j_elementid_to_SVpv( dir ? last_node_elt_id : node_elt_id )
	  );      
      hv_stores( (HV*) SvRV(rel_sv), "end", newSViv( (IV) (dir ? node_id : last_node_id)));
      hv_stores(
	  (HV*) SvRV(rel_sv), "end_element_id",
	  neo4j_elementid_to_SVpv( dir ? node_elt_id : last_node_elt_id )
	  );
      av_push(av, rel_sv);
      av_push(av, neo4j_value_to_SV(node));
      last_node_id = node_id;
      last_node_elt_id = node_elt_id;
    }
    return av;
  }
}

HV* neo4j_date_to_HV( neo4j_value_t value) {
  HV *hv;
  long long days;
  hv = newHV();
  days = neo4j_date_days(value);
  hv_stores(hv, "neo4j_type", neo4j_type_svpv(value));
  hv_stores(hv, "epoch_days", newSViv( (IV) days ));
  return hv;
}


HV* neo4j_time_to_HV( neo4j_value_t value) {
    HV *hv;
    long long nsecs, offset_secs;
    hv = newHV();
    nsecs = neo4j_time_nsecs(value);
    offset_secs = neo4j_time_secs_offset(value);
    hv_stores(hv, "neo4j_type", neo4j_type_svpv(value));
    hv_stores(hv, "nsecs", newSViv( (IV) nsecs ));
    hv_stores(hv, "offset_secs", newSViv( (IV) offset_secs ));
    return hv;
}

HV* neo4j_localtime_to_HV( neo4j_value_t value) {
    HV *hv;
    long long nsecs;
    hv = newHV();
    nsecs = neo4j_localtime_nsecs(value);
    hv_stores(hv, "neo4j_type", neo4j_type_svpv(value));
    hv_stores(hv, "nsecs", newSViv( (IV) nsecs ));
    return hv;
}

HV* neo4j_datetime_to_HV(neo4j_value_t value) {
    HV *hv;
    long long secs, nsecs, offset_secs;
    hv = newHV();
    secs = neo4j_datetime_secs(value);
    nsecs = neo4j_datetime_nsecs(value);
    offset_secs = neo4j_datetime_secs_offset(value);
    hv_stores(hv, "neo4j_type", neo4j_type_svpv(value));
    hv_stores(hv, "epoch_secs", newSViv( (IV) secs ));
    hv_stores(hv, "nsecs", newSViv( (IV) nsecs ));
    hv_stores(hv, "offset_secs", newSViv( (IV) offset_secs ));
    return hv;
}

HV* neo4j_localdatetime_to_HV(neo4j_value_t value) {
    HV *hv;
    long long epoch_secs, nsecs;
    hv = newHV();
    epoch_secs = neo4j_localdatetime_secs(value);
    nsecs = neo4j_localdatetime_nsecs(value);
    hv_stores(hv, "neo4j_type", neo4j_type_svpv(value));
    hv_stores(hv, "epoch_secs", newSViv( (IV) epoch_secs ));
    hv_stores(hv, "nsecs", newSViv( (IV) nsecs ));
    return hv;
}

HV* neo4j_duration_to_HV(neo4j_value_t value) {
    HV *hv;
    long long months, days, secs, nsecs;
    hv = newHV();
    months = neo4j_duration_months(value);
    days = neo4j_duration_days(value);
    secs = neo4j_duration_secs(value);
    nsecs = neo4j_duration_nsecs(value);
    hv_stores(hv, "months", newSViv( (IV) months ));
    hv_stores(hv, "days", newSViv( (IV) days ));    
    hv_stores(hv, "secs", newSViv( (IV) secs ));
    hv_stores(hv, "nsecs", newSViv( (IV) nsecs ));
    return hv;
}

HV* neo4j_point_to_HV(neo4j_value_t value) {
    HV *hv;
    long long srid;
    double x, y, z;
    hv = newHV();
    if (neo4j_type(value) == NEO4J_POINT2D) {
	srid = neo4j_point2d_srid(value);
	x = neo4j_point2d_x(value);
	y = neo4j_point2d_y(value);
    }
    else if (neo4j_type(value) == NEO4J_POINT3D) {
	srid = neo4j_point3d_srid(value);
	x = neo4j_point3d_x(value);
	y = neo4j_point3d_y(value);
	z = neo4j_point3d_z(value);	
    }
    else {
        warn("Arg is not a neo4j point type");	
	return hv;
    }
    hv_stores(hv, "srid", newSViv( (IV) srid ));
    hv_stores(hv, "x", newSVnv( (NV) x ));
    hv_stores(hv, "y", newSVnv( (NV) y ));
    if (neo4j_type(value) == NEO4J_POINT3D) {
	hv_stores(hv, "z", newSVnv( (NV) z ));
    }
    return hv;
}


MODULE = Neo4j::Bolt::CTypeHandlers  PACKAGE = Neo4j::Bolt::CTypeHandlers

PROTOTYPES: DISABLE


