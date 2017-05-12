#/*-*- Mode: C++ -*- */

MODULE = Moot		PACKAGE = Moot::HMM

##=====================================================================
## Constructors etc.
##=====================================================================

##-- disable perl prototypes
PROTOTYPES: DISABLE

##------------------------------------------------------
## Constructor: new()
mootHMM*
_new(char *CLASS)
CODE:
 RETVAL=new mootHMM();
OUTPUT:
 RETVAL

##------------------------------------------------------
## clear
void
clear(mootHMM* hmm, bool wipe_everything=true, bool unlogify=false)
CODE:
 hmm->clear(wipe_everything,unlogify);

##------------------------------------------------------
## Destructor: DESTROY()
void
DESTROY(mootHMM* hmm)
CODE:
 if (hmm) delete hmm;

##=====================================================================
## Accessors
##=====================================================================

##------------------------------------------------------
int
verbose(mootHMM *hmm, ...)
CODE:
 if (items>1) hmm->verbose=SvUV(ST(1));
 RETVAL = hmm->verbose;
OUTPUT:
 RETVAL

##------------------------------------------------------
size_t
ndots(mootHMM *hmm, ...)
CODE:
 if (items>1) hmm->ndots=SvUV(ST(1));
 RETVAL=hmm->ndots;
OUTPUT:
 RETVAL

##------------------------------------------------------
bool
save_ambiguities(mootHMM *hmm, ...)
CODE:
 if (items>1) hmm->save_ambiguities=SvTRUE(ST(1));
 RETVAL=hmm->save_ambiguities;
OUTPUT:
 RETVAL

##------------------------------------------------------
bool
save_flavors(mootHMM *hmm, ...)
CODE:
 if (items>1) hmm->save_flavors=SvTRUE(ST(1));
 RETVAL=hmm->save_flavors;
OUTPUT:
 RETVAL

##------------------------------------------------------
bool
save_mark_unknown(mootHMM *hmm, ...)
CODE:
 if (items>1) hmm->save_mark_unknown=SvTRUE(ST(1));
 RETVAL=hmm->save_mark_unknown;
OUTPUT:
 RETVAL

##------------------------------------------------------
bool
hash_ngrams(mootHMM *hmm, ...)
CODE:
 if (items>1) hmm->hash_ngrams=SvTRUE(ST(1));
 RETVAL = hmm->hash_ngrams;
OUTPUT:
 RETVAL
 
##------------------------------------------------------
bool
relax(mootHMM *hmm, ...)
CODE:
 if (items>1) hmm->relax=SvTRUE(ST(1));
 RETVAL = hmm->relax;
OUTPUT:
 RETVAL

##------------------------------------------------------
bool
use_lex_classes(mootHMM *hmm, ...)
CODE:
 if (items>1) hmm->use_lex_classes=SvTRUE(ST(1));
 RETVAL = hmm->use_lex_classes;
OUTPUT:
 RETVAL

##------------------------------------------------------
bool
use_flavors(mootHMM *hmm, ...)
CODE:
 if (items>1) hmm->use_flavors=SvTRUE(ST(1));
 RETVAL=hmm->use_flavors;
OUTPUT:
 RETVAL

##------------------------------------------------------
TagID
start_tagid(mootHMM *hmm, ...)
CODE:
 if (items>1) hmm->start_tagid=SvUV(ST(1));
 RETVAL = hmm->start_tagid;
OUTPUT:
 RETVAL

##------------------------------------------------------
ProbT
unknown_lex_threshhold(mootHMM *hmm, ...)
CODE:
 if (items>1) hmm->unknown_lex_threshhold=SvNV(ST(1));
 RETVAL = hmm->unknown_lex_threshhold;
OUTPUT:
 RETVAL

##------------------------------------------------------
ProbT
unknown_class_threshhold(mootHMM *hmm, ...)
CODE:
 if (items>1) hmm->unknown_class_threshhold=SvNV(ST(1));
 RETVAL = hmm->unknown_class_threshhold;
OUTPUT:
 RETVAL

##------------------------------------------------------
ProbT
nglambda1(mootHMM *hmm, ...)
CODE:
 if (items>1) hmm->nglambda1=SvNV(ST(1));
 RETVAL = hmm->nglambda1;
OUTPUT:
 RETVAL

##------------------------------------------------------
ProbT
nglambda2(mootHMM *hmm, ...)
CODE:
 if (items>1) hmm->nglambda2=SvNV(ST(1));
 RETVAL = hmm->nglambda2;
OUTPUT:
 RETVAL

##------------------------------------------------------
ProbT
nglambda3(mootHMM *hmm, ...)
CODE:
 if (items>1) hmm->nglambda3=SvNV(ST(1));
 RETVAL = hmm->nglambda3;
OUTPUT:
 RETVAL


##------------------------------------------------------
ProbT
wlambda0(mootHMM *hmm, ...)
CODE:
 if (items>1) hmm->wlambda0=SvNV(ST(1));
 RETVAL = hmm->wlambda0;
OUTPUT:
 RETVAL

##------------------------------------------------------
ProbT
wlambda1(mootHMM *hmm, ...)
CODE:
 if (items>1) hmm->wlambda1=SvNV(ST(1));
 RETVAL = hmm->wlambda1;
OUTPUT:
 RETVAL


##------------------------------------------------------
ProbT
clambda0(mootHMM *hmm, ...)
CODE:
 if (items>1) hmm->clambda0=SvNV(ST(1));
 RETVAL = hmm->clambda0;
OUTPUT:
 RETVAL

##------------------------------------------------------
ProbT
clambda1(mootHMM *hmm, ...)
CODE:
 if (items>1) hmm->clambda1=SvNV(ST(1));
 RETVAL = hmm->clambda1;
OUTPUT:
 RETVAL


##------------------------------------------------------
ProbT
beamwd(mootHMM *hmm, ...)
CODE:
 if (items>1) hmm->beamwd=SvNV(ST(1));
 RETVAL = hmm->beamwd;
OUTPUT:
 RETVAL

##------------------------------------------------------
size_t n_tags(mootHMM *hmm, ...)
CODE:
 if (items>1) hmm->n_tags=SvUV(ST(1));
 RETVAL = hmm->n_tags;
OUTPUT:
 RETVAL

##------------------------------------------------------
size_t n_toks(mootHMM *hmm, ...)
CODE:
 if (items>1) hmm->n_toks=SvUV(ST(1));
 RETVAL = hmm->n_toks;
OUTPUT:
 RETVAL

##------------------------------------------------------
size_t n_classes(mootHMM *hmm, ...)
CODE:
 if (items>1) hmm->n_classes=SvUV(ST(1));
 RETVAL = hmm->n_classes;
OUTPUT:
 RETVAL

##------------------------------------------------------
size_t
nsents(mootHMM *hmm, ...)
CODE:
 if (items>1) hmm->nsents=SvUV(ST(1));
 RETVAL = hmm->nsents;
OUTPUT:
 RETVAL

##------------------------------------------------------
size_t
ntokens(mootHMM *hmm, ...)
CODE:
 if (items>1) hmm->ntokens=SvUV(ST(1));
RETVAL = hmm->ntokens;
OUTPUT:
 RETVAL

##------------------------------------------------------
size_t
nnewtokens(mootHMM *hmm, ...)
CODE:
 if (items>1) hmm->nnewtokens=SvUV(ST(1));
 RETVAL = hmm->nnewtokens;
OUTPUT:
 RETVAL

##------------------------------------------------------
size_t
nunclassed(mootHMM *hmm, ...)
CODE:
 if (items>1) hmm->nunclassed=SvUV(ST(1));
 RETVAL = hmm->nunclassed;
OUTPUT:
 RETVAL

##------------------------------------------------------
size_t
nnewclasses(mootHMM *hmm, ...)
CODE:
 if (items>1) hmm->nnewclasses=SvUV(ST(1));
 RETVAL = hmm->nnewclasses;
OUTPUT:
 RETVAL

##------------------------------------------------------
size_t
nunknown(mootHMM *hmm, ...)
CODE:
 if (items>1) hmm->nunknown=SvUV(ST(1));
 RETVAL = hmm->nunknown;
OUTPUT:
 RETVAL

##------------------------------------------------------
size_t
nfallbacks(mootHMM *hmm, ...)
CODE:
 if (items>1) hmm->nfallbacks=SvUV(ST(1));
 RETVAL = hmm->nfallbacks;
OUTPUT:
 RETVAL

##=====================================================================
## Lookup
##=====================================================================

##------------------------------------------------------
ProbT
wordp(mootHMM *hmm, char *tokstr, char *tagstr)
CODE:
   RETVAL = hmm->wordp(tokstr, tagstr);
OUTPUT:
 RETVAL

##------------------------------------------------------
ProbT
classp(mootHMM *hmm, AV *tagsetav, char *tagstr, U32 utf8=TRUE)
PREINIT:
  mootTagSet *tagset;
  mootHMM::LexClass *lclass;
CODE:
  tagset = av2tagset(tagsetav, NULL, utf8);
  lclass = hmm->tagset2lexclass(*tagset, NULL, false);
  RETVAL = hmm->classp(*lclass, tagstr);
  delete lclass;
  delete tagset;
OUTPUT:
 RETVAL

##------------------------------------------------------
ProbT
tagp(mootHMM *hmm, ...)
PREINIT:
  mootHMM::Trigram tg;
CODE:
 if (items < 2) {
   Perl_croak(aTHX_ "Usage: Moot::HMM::tagp(hmm, tag1 [,tag2 [,tag3]])");
 } else if (items==2) {
   char *tag1 = SvPV_nolen(ST(1));
   tg.tag3 = hmm->tagids.name2id(tag1);
 } else if (items==3) {
   char *tag1 = SvPV_nolen(ST(1));
   char *tag2 = SvPV_nolen(ST(2));
   tg.tag2 = hmm->tagids.name2id(tag1);
   tg.tag3 = hmm->tagids.name2id(tag2);
 } else if (items==4) {
   char *tag1 = SvPV_nolen(ST(1));
   char *tag2 = SvPV_nolen(ST(2));
   char *tag3 = SvPV_nolen(ST(3));
   tg.tag1 = hmm->tagids.name2id(tag1);
   tg.tag2 = hmm->tagids.name2id(tag2);
   tg.tag3 = hmm->tagids.name2id(tag3);
 }
 RETVAL = hmm->tagp(tg);
OUTPUT:
 RETVAL

##=====================================================================
## Tagging
##=====================================================================

##------------------------------------------------------
void
tag_sentence(mootHMM *hmm, AV* sentav, bool utf8=TRUE, bool trace=FALSE)
PREINIT:
  mootSentence *s;
CODE:
  s = av2sentence(sentav, NULL, utf8);
  hmm->tag_sentence(*s);
  if (trace) hmm->tag_dump_trace(*s);
  sentence2tokdata(s, utf8);
  delete s;

##------------------------------------------------------
void
tag_io(mootHMM *hmm, TokenReader *reader, TokenWriter *writer)
CODE:
  hmm->tag_io(reader,writer);

##------------------------------------------------------
void
tag_stream(mootHMM *hmm, TokenReader *reader, TokenWriter *writer)
CODE:
  hmm->tag_stream(reader,writer);


##=====================================================================
## I/O
##=====================================================================

##------------------------------------------------------
## I/O: Text Model

bool
_load_model(mootHMM *hmm, char *modelname, char *start_tag_str=NULL)
CODE:
   RETVAL = hmm->load_model(modelname, (start_tag_str ? start_tag_str : "__$"));
OUTPUT:
 RETVAL

##------------------------------------------------------
## I/O: Binary

bool
_load(mootHMM *hmm, char *filename)
CODE:
 RETVAL = hmm->load(filename);
OUTPUT:
 RETVAL

bool
_save(mootHMM *hmm, char *filename, int compression_level=-1)
CODE:
 RETVAL = hmm->save(filename,compression_level);
OUTPUT:
 RETVAL

##------------------------------------------------------
## I/O: dump

void
txtdump(mootHMM *hmm, char *filename=NULL)
CODE:
 FILE *f=stdout;
 if (filename && strcmp(filename,"-") != 0) f = fopen(filename,"wb");
 if (f == NULL) croak("HMM::txtdump(): open failed for file '%s'", filename);
 hmm->txtdump(f);
 if (f != stdout) fclose(f);


