package t::BoltFile;
use v5.12;
use warnings;

use Neo4j::Client 0.56;
use File::Spec;
BEGIN {
  use lib 'lib';
}
use Inline with => 'Neo4j::Client';

use Inline C => <<'END_BOLTFILE_C';

#include <neo4j-client.h>
#include <memory.h>
#include <iostream.h>
#include <posix_iostream.h>
#include <serialization.h>
#include <deserialization.h>
#include <stdio.h>
#define NEO4J_DEFAULT_MPOOL_BLOCK_SIZE 128
#define BFCLASS "t::BoltFile"
#define NVCLASS "Neo4j::Bolt::NeoValue"
#define C_PTR_OF(perl_obj,c_type) ((c_type *)SvIV(SvRV(perl_obj)))

struct bolt_file {
  char * fn;
  neo4j_iostream_t *fs;
  struct neo4j_mpool mpool;
};
typedef struct bolt_file bolt_file_t;

struct neovalue {
  neo4j_value_t value;
};
typedef struct neovalue neovalue_t;

SV* open_bf(const char *classname, const char *fn, int flags) {
  bolt_file_t *bf;
  struct neo4j_mpool bt_mpool;
  SV *bsv, *bsv_ref;
  int fd;
  Newx(bf,1,bolt_file_t);
  bf->fn = savepv(fn);
  bf->mpool = neo4j_mpool(&neo4j_std_memory_allocator,NEO4J_DEFAULT_MPOOL_BLOCK_SIZE);
  fd = open(fn, flags,0644);
  if (fd < 0) {
    fprintf(stderr, "can't open bolt file %s : %s\n",bf->fn,strerror(errno));
    return &PL_sv_undef;
  }
  //printf ("Hey dude\n");
  bf->fs = neo4j_posix_iostream(fd);
  if ( bf->fs == NULL ) {
    fprintf(stderr, "can't create neo4j_iostream (%s) : %s\n",bf->fn,strerror(errno));
    return &PL_sv_undef;
  }
  bsv = newSViv((IV) bf);
  bsv_ref = newRV_noinc(bsv);
  sv_bless(bsv_ref, gv_stashpv(BFCLASS, GV_ADD));
  SvREADONLY_on(bsv);
  return bsv_ref;
}

void close_bf (SV* obj) {
  bolt_file_t* bf = C_PTR_OF(obj,bolt_file_t);
  bf->fs->close(bf->fs);
  return;
}
const char *get_fn (SV* obj) {
  return C_PTR_OF(obj,bolt_file_t)->fn;
}

SV *_create_neovalue (SV *obj, neo4j_value_t *v) {
   SV *neosv, *neosv_ref;
   neovalue_t *o;
   Newx(o,1,neovalue_t);
   o->value = *v;
   neosv = newSViv((IV) o);
   neosv_ref = newRV_noinc(neosv);
   sv_bless(neosv_ref, gv_stashpv(NVCLASS, GV_ADD));
   SvREADONLY_on(neosv);
   return neosv_ref;
}

SV *_read_value (SV *obj) {
  bolt_file_t *bf;
  neo4j_value_t *value;
  bf = C_PTR_OF(obj,bolt_file_t);
  Newx(value,1,neo4j_value_t);
  if (!neo4j_deserialize(bf->fs, &(bf->mpool),value)) {
    return _create_neovalue(obj, value);
  }
  else {
    neo4j_perror(stderr,errno,"");
    return &PL_sv_undef;
  }
}

int _write_neovalue (SV*obj,SV*neov) {
  return 1+neo4j_serialize(C_PTR_OF(neov,neovalue_t)->value, C_PTR_OF(obj,bolt_file_t)->fs);
}

void DESTROY(SV* obj) {
  bolt_file_t* bf = C_PTR_OF(obj,bolt_file_t);
  // bf->fs->close(bf->fs);
  Safefree(bf->fn);
  Safefree(bf);
}

END_BOLTFILE_C

sub write_values {
  my ($self,@vals) = @_;
  for my $v (@vals) {
    next unless defined $v;
    $self->_write_neovalue($v) or die "Barfed on write $!";
  }
  return 1;
}
1;

