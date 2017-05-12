#define MIN_PERL_DEFINE 1
 
#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

#include "rc.h"

int interactive=0;

extern void pr_error(char *s) {
	if (s != NULL) {
		warn("line %d: %s\n", lineno - 1, s);
	}
}

/* need to replace with perl-ish version XXX */
extern void writeall(int fd, char *buf, size_t remain) {
	int i;
	for (i = 0; remain > 0; buf += i, remain -= i) {
		if ((i = write(fd, buf, remain)) <= 0)
			break; /* abort silently on errors in write() */
	}
}

static char *node_typename(Node *THIS)
{
	switch (THIS->type) {
  case nAndalso: return "Andalso";
  case nArgs: return "Args";
  case nAssign: return "Assign";
  case nBackq: return "Backq";
  case nBang: return "Bang";
  case nBody: return "Body";
  case nBrace: return "Brace";
  case nCase: return "Case";
  case nCbody: return "Cbody";
  case nConcat: return "Concat";
  case nCount: return "Count";
  case nDup: return "Dup";
  case nElse: return "Else";
  case nEpilog: return "Epilog";
  case nFlat: return "Flat";
  case nForin: return "Forin";
  case nIf: return "If";
  case nLappend: return "Lappend";
  case nMatch: return "Match";
  case nNewfn: return "Newfn";
  case nNmpipe: return "Nmpipe";
  case nNowait: return "Nowait";
  case nOrelse: return "Orelse";
  case nPipe: return "Pipe";
  case nPre: return "Pre";
  case nQword: return "Qword";
  case nRedir: return "Redir";
  case nRmfn: return "Rmfn";
  case nSubshell: return "Subshell";
  case nSwitch: return "Switch";
  case nVar: return "Var";
  case nVarsub: return "Varsub";
  case nWhile: return "While";
  case nWord: return "Word";
	default: croak("type %d unknown", THIS->type);
	}
  return 0;
}

static char *node_class(Node *nd)  /*optimize XXX */
{ return SvPV(sv_2mortal(newSVpvf("Rc::%s", node_typename(nd))), PL_na); }

static SV *node_2sv(Node *var)
{
  if (!var) {
	/* need to fake up something to avoid sv_undef */
    SV *ret = newSV(0);
    sv_setiv(newSVrv(ret,"Rc::Undef"), 0);
    return ret;
  }
  else {
    return sv_setref_pv(newSV(0), node_class(var), (void*)var);
  }
}

static char *CB;
extern void walk(Node *nd)
{
  dSP;
  ENTER;
  SAVETMPS;
  PUSHMARK(SP);
  XPUSHs(node_2sv(nd));
  PUTBACK;
  perl_call_method(CB, G_DISCARD);
  FREETMPS;
  LEAVE;
}

MODULE = Rc          PACKAGE = Rc
 
PROTOTYPES: DISABLE

BOOT:
  initparse();
  initinput();
  initprint();

void
_walk(sv, method)
	SV *sv
	char *method
	PREINIT:
	STRLEN len;
	char *str = SvPV(sv, len);
	CODE:
	CB = method;
	parseline(str, len);

MODULE = Rc	PACKAGE = Rc::Node

char *
Node::type()
	CODE:
	RETVAL = node_typename(THIS);
	OUTPUT:
	RETVAL

MODULE = Rc	PACKAGE = Rc::WordX

char *
Node::string()
	CODE:
	RETVAL = THIS->u[0].s;
	OUTPUT:
	RETVAL

MODULE = Rc	PACKAGE = Rc::UnaryCmd

void
Node::kids()
	PPCODE:
	XPUSHs(node_2sv(THIS->u[0].p));

Node *
Node::kid(xx)
	int xx;
	CODE:
	assert(xx==0);
	RETVAL = THIS->u[xx].p;
	OUTPUT:
	RETVAL

MODULE = Rc	PACKAGE = Rc::BinCmd

void
Node::kids()
	PPCODE:
	XPUSHs(node_2sv(THIS->u[0].p));
	XPUSHs(node_2sv(THIS->u[1].p));

Node *
Node::kid(xx)
	int xx;
	CODE:
	assert(xx==0 || xx==1);
	RETVAL = THIS->u[xx].p;
	OUTPUT:
	RETVAL

MODULE = Rc	PACKAGE = Rc::Forin

void
Node::kids()
	PPCODE:
	XPUSHs(node_2sv(THIS->u[0].p));
	XPUSHs(node_2sv(THIS->u[1].p));
	XPUSHs(node_2sv(THIS->u[2].p));

Node *
Node::kid(xx)
	int xx;
	CODE:
	assert(xx==0 || xx==1 || xx==2);
	RETVAL = THIS->u[xx].p;
	OUTPUT:
	RETVAL

MODULE = Rc	PACKAGE = Rc::RedirX

char *
Node::redir()
	PREINIT:
	char *str;
	PPCODE:
	switch(THIS->u[0].i) {
	case rFrom: str="<"; break;
	case rCreate: str=">"; break;
	case rAppend: str=">>"; break;
	case rHeredoc: str="<<"; break;
	case rHerestring: str="<<<"; break;
	default: croak("unknown redir %d", THIS->u[0].i);
	}
	XPUSHs(sv_2mortal(newSVpv(str,0)));

MODULE = Rc	PACKAGE = Rc::Dup

int
Node::left()
	PPCODE:
	XPUSHs(sv_2mortal(newSViv(THIS->u[1].i)));

int
Node::right()
	PPCODE:
	XPUSHs(sv_2mortal(newSViv(THIS->u[2].i)));

MODULE = Rc	PACKAGE = Rc::Redir

int
Node::fd()
	PPCODE:
	XPUSHs(sv_2mortal(newSViv(THIS->u[1].i)));

Node *
Node::targ()
	CODE:
	RETVAL = THIS->u[2].p;
	OUTPUT:
	RETVAL

MODULE = Rc	PACKAGE = Rc::Pipe

void
Node::fds()
	PPCODE:
	XPUSHs(sv_2mortal(newSViv(THIS->u[0].i)));
	XPUSHs(sv_2mortal(newSViv(THIS->u[1].i)));

void
Node::kids()
	PPCODE:
	XPUSHs(node_2sv(THIS->u[2].p));
	XPUSHs(node_2sv(THIS->u[3].p));

Node *
Node::kid(xx)
	int xx;
	CODE:
	assert(xx==0 || xx==1);
	RETVAL = xx==0? THIS->u[2].p : THIS->u[3].p;
	OUTPUT:
	RETVAL
