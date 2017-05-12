#/*-*- Mode: C++ -*- */

MODULE = Moot		PACKAGE = Moot::HMM::Dyn

##=====================================================================
## Moot::HMM::Dyn ~ mootDynHMM

##-- disable perl prototypes
PROTOTYPES: DISABLE

##--------------------------------------------------------------
## Constructor: new()
mootDynHMM*
_new(char *CLASS)
CODE:
 RETVAL=new mootDynHMM();
OUTPUT:
 RETVAL

##--------------------------------------------------------------
void
DESTROY(mootDynHMM* hmm)
CODE:
 if (hmm) delete hmm;

##--------------------------------------------------------------
void
tag_sentence(mootDynHMM *hmm, AV* sentav, bool utf8=TRUE)
PREINIT:
  mootSentence *s;
CODE:
  s = av2sentence(sentav, NULL, utf8);
  hmm->tag_sentence(*s);
  sentence2tokdata(s, utf8);
  delete s;

##=====================================================================
## Moot::HMM::DynLex ~ mootDynLexHMM

MODULE = Moot		PACKAGE = Moot::HMM::DynLex

##-- disable perl prototypes
PROTOTYPES: DISABLE

##--------------------------------------------------------------
## Constructor: new()
mootDynLexHMM*
_new(char *CLASS)
CODE:
 RETVAL=new mootDynLexHMM();
OUTPUT:
 RETVAL

##--------------------------------------------------------------
void
DESTROY(mootDynLexHMM* hmm)
CODE:
 if (hmm) delete hmm;

##------------------------------------------------------
bool
invert_lexp(mootDynLexHMM *hmm, ...)
CODE:
 if (items>1) hmm->invert_lexp=SvTRUE(ST(1));
 RETVAL = hmm->invert_lexp;
OUTPUT:
 RETVAL

##------------------------------------------------------
TagStr
newtag_str(mootDynLexHMM *hmm, ...)
CODE:
 if (items>1) hmm->newtag_str=SvPV_nolen(ST(1));
 RETVAL = hmm->newtag_str;
OUTPUT:
 RETVAL

##------------------------------------------------------
TagID
newtag_id(mootDynLexHMM *hmm, ...)
CODE:
 if (items>1) hmm->newtag_id=SvUV(ST(1));
 RETVAL = hmm->newtag_id;
OUTPUT:
 RETVAL

##------------------------------------------------------
ProbT
newtag_f(mootDynLexHMM *hmm, ...)
CODE:
 if (items>1) hmm->newtag_f=SvNV(ST(1));
 RETVAL = hmm->newtag_f;
OUTPUT:
 RETVAL

##------------------------------------------------------
ProbT
Ftw_eps(mootDynLexHMM *hmm, ...)
CODE:
 if (items>1) hmm->Ftw_eps=SvNV(ST(1));
 RETVAL = hmm->Ftw_eps;
OUTPUT:
 RETVAL


##=====================================================================
## Moot::HMM::Boltzmann ~ mootDynLexHMM_Boltzmann

MODULE = Moot		PACKAGE = Moot::HMM::Boltzmann

##-- disable perl prototypes
PROTOTYPES: DISABLE

##--------------------------------------------------------------
## Constructor: new()
mootDynLexHMM_Boltzmann*
_new(char *CLASS)
CODE:
 RETVAL=new mootDynLexHMM_Boltzmann();
OUTPUT:
 RETVAL

##--------------------------------------------------------------
void
DESTROY(mootDynLexHMM_Boltzmann* hmm)
CODE:
 if (hmm) delete hmm;

##------------------------------------------------------
ProbT
dynlex_base(mootDynLexHMM_Boltzmann* hmm, ...)
CODE:
 if (items>1) hmm->dynlex_base=SvNV(ST(1));
 RETVAL = hmm->dynlex_base;
OUTPUT:
 RETVAL

##------------------------------------------------------
ProbT
dynlex_beta(mootDynLexHMM_Boltzmann* hmm, ...)
CODE:
 if (items>1) hmm->dynlex_beta=SvNV(ST(1));
 RETVAL = hmm->dynlex_beta;
OUTPUT:
 RETVAL
