#/*-*- Mode: C++ -*- */

MODULE = Moot		PACKAGE = Moot::Ngrams

##=====================================================================
## Constructors etc.
##=====================================================================

##-- disable perl prototypes
PROTOTYPES: DISABLE

##--------------------------------------------------------------
## Constructor: new()
mootNgrams*
new(char *CLASS)
CODE:
 RETVAL=new mootNgrams();
OUTPUT:
 RETVAL

##--------------------------------------------------------------
## clear
void
clear(mootNgrams* ng)
CODE:
 ng->clear();

##--------------------------------------------------------------
## Destructor: DESTROY()
void
DESTROY(mootNgrams* ng)
CODE:
 if (ng) delete ng;

##=====================================================================
## Accessors
##=====================================================================

##--------------------------------------------------------------
size_t
n_unigrams(mootNgrams* ng)
CODE:
 RETVAL = ng->n_unigrams();
OUTPUT:
 RETVAL

##--------------------------------------------------------------
size_t
n_bigrams(mootNgrams* ng)
CODE:
 RETVAL = ng->n_bigrams();
OUTPUT:
 RETVAL

##--------------------------------------------------------------
size_t
n_trigrams(mootNgrams* ng)
CODE:
 RETVAL = ng->n_trigrams();
OUTPUT:
 RETVAL

##--------------------------------------------------------------
void
add_count(mootNgrams *ng, ...)
CODE:
 if (items<3) {
   Perl_croak(aTHX_ "Usage: Moot::Ngrams::add_count(ng, tag1 [,tag2 [,tag3]] count)");
 } else if (items==3) {
   char *tag1 = SvPV_nolen(ST(1));
   CountT count = (double)SvNV(ST(2));
   ng->add_counts(mootNgrams::Ngram(tag1),count);
 } else if (items==4) {
   char *tag1 = SvPV_nolen(ST(1));
   char *tag2 = SvPV_nolen(ST(2));
   CountT count = (double)SvNV(ST(3));
   ng->add_counts(mootNgrams::Ngram(tag1,tag2),count);
 } else if (items>=5) {
   char *tag1 = SvPV_nolen(ST(1));
   char *tag2 = SvPV_nolen(ST(2));
   char *tag3 = SvPV_nolen(ST(3));
   CountT count = (double)SvNV(ST(4));
   ng->add_counts(mootNgrams::Ngram(tag1,tag2,tag3),count);
 }

##--------------------------------------------------------------
CountT
lookup(mootNgrams *ng, ...)
CODE:
 if (items<2) {
   Perl_croak(aTHX_ "Usage: Moot::Ngrams::lookup(ng, tag1 [,tag2 [,tag3]])");
 } else if (items==2) {
   char *tag1 = SvPV_nolen(ST(1));
   RETVAL = ng->lookup(tag1);
 } else if (items==3) {
   char *tag1 = SvPV_nolen(ST(1));
   char *tag2 = SvPV_nolen(ST(2));
   RETVAL = ng->lookup(tag1,tag2);
 } else if (items>=4) {
   char *tag1 = SvPV_nolen(ST(1));
   char *tag2 = SvPV_nolen(ST(2));
   char *tag3 = SvPV_nolen(ST(3));
   RETVAL = ng->lookup(tag1,tag2,tag3);
 }
OUTPUT:
 RETVAL

##--------------------------------------------------------------
## ugtotal
CountT
ugtotal(mootNgrams *ng)
CODE:
 RETVAL = ng->ugtotal;
OUTPUT:
 RETVAL


##--------------------------------------------------------------
## I/O: File

bool
loadFile(mootNgrams *ng, char *filename)
CODE:
 RETVAL = ng->load(filename);
OUTPUT:
 RETVAL

bool
saveFile(mootNgrams *ng, char *filename, bool compact=false)
CODE:
 RETVAL = ng->save(filename,compact);
OUTPUT:
 RETVAL

##--------------------------------------------------------------
## I/O: FH

bool
loadFh(mootNgrams *ng, FILE *f, char *filename=NULL)
CODE:
 RETVAL = ng->load(f,filename);
OUTPUT:
 RETVAL

bool
saveFh(mootNgrams *ng, FILE *f, char *filename=NULL, bool compact=false)
CODE:
 RETVAL = ng->save(f,filename,compact);
OUTPUT:
 RETVAL
