#/*-*- Mode: C++ -*- */

MODULE = Moot		PACKAGE = Moot::Lexfreqs

##=====================================================================
## Constructors etc.
##=====================================================================

##-- disable perl prototypes
PROTOTYPES: DISABLE

##--------------------------------------------------------------
## Constructor: new()
mootLexfreqs*
new(char *CLASS)
CODE:
 RETVAL=new mootLexfreqs();
OUTPUT:
 RETVAL

##--------------------------------------------------------------
## clear
void
clear(mootLexfreqs* lf)
CODE:
 lf->clear();

##--------------------------------------------------------------
## Destructor: DESTROY()
void
DESTROY(mootLexfreqs* lf)
CODE:
 if (lf) delete lf;


##=====================================================================
## Accessors
##=====================================================================

##--------------------------------------------------------------
## compute specials
void
compute_specials(mootLexfreqs *lf)
CODE:
   lf->compute_specials();

##--------------------------------------------------------------
## remove specials
void
remove_specials(mootLexfreqs *lf)
CODE:
   lf->remove_specials();

##--------------------------------------------------------------
## discount specials
void
discount_specials(mootLexfreqs *lf, CountT zf_special=1.0)
CODE:
 lf->discount_specials(zf_special);

##--------------------------------------------------------------
## n_pairs
size_t
n_pairs(mootLexfreqs *lf)
CODE:
 RETVAL = lf->n_pairs();
OUTPUT:
 RETVAL

##--------------------------------------------------------------
## n_tokens
size_t
n_tokens(mootLexfreqs *lf)
CODE:
 RETVAL = lf->n_tokens;
OUTPUT:
 RETVAL

##--------------------------------------------------------------
## add_count
void
add_count(mootLexfreqs *lf, char *word, char *tag, double count)
CODE:
 lf->add_count(word,tag,count);


##--------------------------------------------------------------
## lookup: f(tag)
CountT
f_tag(mootLexfreqs *lf, char *tag)
CODE:
 RETVAL = lf->f_tag(tag);
OUTPUT:
 RETVAL

##--------------------------------------------------------------
## lookup: f(word)
CountT
f_word(mootLexfreqs *lf, char *word)
CODE:
 RETVAL = lf->f_word(word);
OUTPUT:
 RETVAL

##--------------------------------------------------------------
## lookup: f(word,tag)
CountT
f_word_tag(mootLexfreqs *lf, char *word, char *tag)
CODE:
 RETVAL = lf->f_word_tag(word,tag);
OUTPUT:
 RETVAL


##--------------------------------------------------------------
## I/O: File

bool
loadFile(mootLexfreqs *lf, char *filename)
CODE:
 RETVAL = lf->load(filename);
OUTPUT:
 RETVAL

bool
saveFile(mootLexfreqs *lf, char *filename)
CODE:
 RETVAL = lf->save(filename);
OUTPUT:
 RETVAL

##--------------------------------------------------------------
## I/O: FH

bool
loadFh(mootLexfreqs *lf, FILE *f, char *filename=NULL)
CODE:
 RETVAL = lf->load(f,filename);
OUTPUT:
 RETVAL

bool
saveFh(mootLexfreqs *lf, FILE *f, char *filename=NULL)
CODE:
 RETVAL = lf->save(f,filename);
OUTPUT:
 RETVAL
