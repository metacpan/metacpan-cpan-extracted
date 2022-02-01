#include "perlbolt.h"
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

long long neo4j_identity_value(neo4j_value_t value);
char *neo4j_string_to_alloc_str(neo4j_value_t value);

char *neo4j_string_to_alloc_str(neo4j_value_t value) {
  assert(neo4j_type(value) == NEO4J_STRING);
  char *s;
  int nlength;
  nlength = (int) neo4j_string_length(value);
  Newx(s,nlength+1,char);
  return neo4j_string_value(value,s,(size_t) nlength+1);
}

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
  int t;
  SV *thing;
  HV *hv;

  if (!SvOK(sv) ) {
    return neo4j_null;
  }
  if (SvROK(sv)) { // a ref
    thing = SvRV(sv);
    t = SvTYPE(thing);
    if ( t < SVt_PVAV) { // scalar ref
      if ((sv_isobject(sv) && sv_isa(sv, "JSON::PP::Boolean")) || (SvIOK(thing) && SvIV(thing) >> 1 == 0)) {
        // boolean (accepts JSON::PP, Types::Serialiser, literal \1 and \0)
        return SViv_to_neo4j_bool(thing);
      }
      else {
        return SV_to_neo4j_value(thing);
      }
    }
    else if (t == SVt_PVAV) { //array
      if (sv_isobject(sv)) {
        if (sv_isa(sv, PATH_CLASS)) { // path
          return AV_to_neo4j_path( (AV*) thing );
        }
        warn("Unknown blessed array reference type encountered");
      }
      return AV_to_neo4j_list( (AV*) thing );
    }
    else if (t == SVt_PVHV) { //hash
      // determine if is a map, node, or reln
      hv = (HV *)thing;
      if (sv_isobject(sv)) {
        if (sv_isa(sv, NODE_CLASS)) { // node
          return HV_to_neo4j_node(hv);
        }
        if (sv_isa(sv, RELATIONSHIP_CLASS)) { // reln
          return HV_to_neo4j_relationship(hv);
        }
        warn("Unknown blessed hash reference type encountered");
      }
      return HV_to_neo4j_map(hv); // map
    }
  }
  else {
   if (SvIOK(sv)) {
     return SViv_to_neo4j_int(sv);
   }
   else if (SvNOK(sv)) {
     return SVnv_to_neo4j_float(sv);
   } 
   else if (SvPOK(sv)) {
     return SVpv_to_neo4j_string(sv);
   }
   else {
     perror("Can't handle this scalar");
     return neo4j_null;
   }
  }
 return neo4j_null;
}

neo4j_value_t AV_to_neo4j_list(AV *av) {
  int i,n;
  neo4j_value_t *items;
  n = av_len(av);
  if (n < 0) {
    // empty list (av_len returns the top index)
    return neo4j_null;
  }
  Newx(items, n+1, neo4j_value_t);
  for (i=0;i<=n;i++) {
   items[i] = SV_to_neo4j_value( *(av_fetch(av,i,0)) );
  }
  return neo4j_list(items, n+1);
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

// neo4j_node(neo4j_value_t fields[3]) is not exposed in the API
// fields[0] is a NEO4J_IDENTITY
// fields[1] is a NEO4J_LIST of node labels (NEO4J_STRINGs)
//   (note REST::Neo4p::Node doesn't store a list of labels in the
//   simple rendering! Fix!)
// fields[2] is a NEO4J_MAP of properties
neo4j_value_t HV_to_neo4j_node(HV *hv) {
  SV **node_id_p, **lbls_ref_p, **props_ref_p;
  AV *lbls;
  HV *props;
  neo4j_value_t *fields;
  neo4j_map_entry_t null_ent;
  Newx(fields, 3, neo4j_value_t);

  node_id_p = hv_fetch(hv, "id", 2, 0);
  lbls_ref_p = hv_fetch(hv, "labels", 6, 0);
  if (lbls_ref_p && SvROK(*lbls_ref_p)) {
    lbls = (AV*) SvRV(*lbls_ref_p);
  } else {
    lbls = NULL;
  }
  if (lbls && SvTYPE((SV*)lbls) == SVt_PVAV && av_len(lbls) >= 0) {
    // non-empty list (av_len returns the top index)
    fields[1] = AV_to_neo4j_list(lbls);
  } else {
    fields[1] = neo4j_list( &neo4j_null, 0 );
  }
  fields[0] = neo4j_identity( node_id_p ? SvIV( *node_id_p ) : -1 );

  props_ref_p = hv_fetch(hv, "properties", 10, 0);
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


// neo4j_relationship( neo4j_value_t fields[5] ) is not exposed in API
// field[0] is NEO4J_IDENTITY (id of the relationship)
// field[1] is NEO4J_IDENTITY (id of the start node))
// field[2] is NEO4J_IDENTITY (id of the end node))
// field[3] is NEO4J_STRING (relationship type)
// field[4] is NEO4J_MAP (properties)

neo4j_value_t HV_to_neo4j_relationship(HV *hv) {
  SV **reln_id_p, **start_id_p, **end_id_p, **type_p, **props_ref_p;
  HV *props;
  neo4j_value_t *fields;
  neo4j_map_entry_t null_ent;

  Newx(fields, 5, neo4j_value_t);

  reln_id_p = hv_fetch(hv, "id", 2, 0);
  start_id_p = hv_fetch(hv, "start", 5, 0);
  end_id_p = hv_fetch(hv, "end", 3, 0);
  type_p = hv_fetch(hv, "type", 4, 0);

  fields[0] = neo4j_identity( reln_id_p ? SvIV( *reln_id_p ) : -1 );
  fields[1] = neo4j_identity( start_id_p ? SvIV( *start_id_p ) : -1 );
  fields[2] = neo4j_identity( end_id_p ? SvIV( *end_id_p ) : -1 );
  if (type_p && SvOK(*type_p)) {
    fields[3] = SVpv_to_neo4j_string( *type_p );
  } else {
    fields[3] = neo4j_string("");
  }

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

long long neo4j_identity_value(neo4j_value_t value)
{
  value._type = NEO4J_INT;
  return neo4j_int_value(value);
}


SV* neo4j_bool_to_SViv( neo4j_value_t value) {
  HV* boolean_stash = gv_stashpv("JSON::PP::Boolean", GV_ADD);
  SV* scalar = newSViv( (IV) neo4j_bool_value(value) );
  return sv_bless(newRV_noinc(scalar), boolean_stash);
}

SV* neo4j_bytes_to_SVpv( neo4j_value_t value ) {
  return newSVpvn( neo4j_bytes_value(value),
		   neo4j_bytes_length(value) );
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
  pv = newSVpvn(neo4j_string_to_alloc_str(value), len);
  sv_utf8_decode(pv);
  return pv;
}

SV* neo4j_value_to_SV( neo4j_value_t value ) {
  neo4j_type_t the_type;
  the_type = neo4j_type( value );
  if ( the_type ==  NEO4J_BOOL) {
    return neo4j_bool_to_SViv(value);
  } else if ( the_type ==  NEO4J_BYTES) {
    return neo4j_bytes_to_SVpv(value);
  } else if ( the_type ==  NEO4J_FLOAT) {
    return neo4j_float_to_SVnv(value);
  } else if ( the_type ==  NEO4J_INT) {
    return neo4j_int_to_SViv(value);
  } else if ( the_type ==  NEO4J_NODE) {
    return sv_bless( newRV_noinc((SV*)neo4j_node_to_HV( value )),
                     gv_stashpv(NODE_CLASS, GV_ADD) );
  } else if ( the_type ==  NEO4J_RELATIONSHIP) {
    return sv_bless( newRV_noinc((SV*)neo4j_relationship_to_HV( value )),
                     gv_stashpv(RELATIONSHIP_CLASS, GV_ADD) );
  } else if ( the_type ==  NEO4J_NULL) {
    return newSV(0);
  } else if ( the_type ==  NEO4J_LIST) {
    return newRV_noinc((SV*)neo4j_list_to_AV( value ));
  } else if ( the_type ==  NEO4J_MAP) {
    return newRV_noinc( (SV*)neo4j_map_to_HV( value ));
  } else if ( the_type == NEO4J_PATH ){
    return sv_bless( newRV_noinc((SV*)neo4j_path_to_AV( value )),
                     gv_stashpv(PATH_CLASS, GV_ADD) );

  } else if ( the_type ==  NEO4J_STRING) {
    return neo4j_string_to_SVpv(value);
  } else {
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
  char *ks;
  const neo4j_map_entry_t *entry;
  HV *hv;
  SV *sv;
  hv = newHV();
  n = (int) neo4j_map_size(value);
  for (i=0;i<n;i++) {
    entry = neo4j_map_getentry(value,i);
    ks = neo4j_string_to_alloc_str(entry->key);
    sv = neo4j_value_to_SV(entry->value);
    SvREFCNT_inc(sv);
    klen = neo4j_string_length(entry->key);
    if (! is_ascii_string((U8 *)ks, (STRLEN)klen)) {
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
  I32 retlen;
  long long id;
  neo4j_value_t labels,props;
  // const struct neo4j_struct *V;
  // V = (const struct neo4j_struct *)&value;
  // printf(neo4j_typestr(neo4j_type(V->fields[0])));

  hv = newHV();
  id = neo4j_identity_value(neo4j_node_identity(value));
  labels = neo4j_node_labels(value);
  props_hv = neo4j_map_to_HV(neo4j_node_properties(value));
  hv_stores(hv, "id", newSViv( (IV) id ));
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
  hv = newHV();
  reln_id = neo4j_identity_value(neo4j_relationship_identity(value));
  start_id = neo4j_identity_value(neo4j_relationship_start_node_identity(value));
  end_id = neo4j_identity_value(neo4j_relationship_end_node_identity(value));
  type = neo4j_string_to_SVpv(neo4j_relationship_type(value));
  props_hv = neo4j_map_to_HV(neo4j_relationship_properties(value));
  hv_stores(hv, "id", newSViv( (IV) reln_id ));
  hv_stores(hv, "start", newSViv( (IV) start_id ));
  hv_stores(hv, "end", newSViv( (IV) end_id ));
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
  neo4j_value_t node;
  av = newAV();
  n = neo4j_path_length(value);
  node = neo4j_path_get_node(value, 0);
  av_push(av, neo4j_value_to_SV( node ));
  last_node_id = neo4j_identity_value( neo4j_node_identity(node) );
  if (n==0) {
    return av;
  } else {
    for (i=1; i<=n; i++) {
      node = neo4j_path_get_node(value,i);
      node_id = neo4j_identity_value( neo4j_node_identity(node) );
      rel_sv = neo4j_value_to_SV(neo4j_path_get_relationship(value,i-1,&dir));
      hv_stores( (HV*) SvRV(rel_sv), "start", newSViv( (IV) (dir ? last_node_id : node_id)));
      hv_stores( (HV*) SvRV(rel_sv), "end", newSViv( (IV) (dir ? node_id : last_node_id)));
      av_push(av, rel_sv);
      av_push(av, neo4j_value_to_SV(node));
      last_node_id = node_id;
    }
    return av;
  }
}


MODULE = Neo4j::Bolt::CTypeHandlers  PACKAGE = Neo4j::Bolt::CTypeHandlers

PROTOTYPES: DISABLE


