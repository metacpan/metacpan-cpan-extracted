/* input.c: i/o routines for files and pseudo-files (strings) */

#include "rc.h"

/*
   NB: character unget is supported for up to two characters, but NOT
   in the case of EOF. Since EOF does not fit in a char, it is easiest
   to support only one unget of EOF.
*/

typedef struct Input {
	inputtype t;
	char *ibuf;
	int fd, index, read, lineno, last;
	bool saved, eofread;
} Input;

#define BUFSIZE ((size_t) 256)

char *prompt, *prompt2;

static int dead(void);
static int fdgchar(void);
static int stringgchar(void);
static void ugdead(int);
static void pushcommon(void);

static char *inbuf;
static size_t istacksize, chars_out, chars_in;
static bool eofread = FALSE, save_lineno = TRUE;
static Input *istack, *itop;

static int (*realgchar)(void);
static void (*realugchar)(int);

int last;

extern int gchar() {
	int c;

	if (eofread) {
		eofread = FALSE;
		return last = EOF;
	}

	while ((c = (*realgchar)()) == '\0')
		pr_error("warning: null character ignored");

	return c;
}

extern void ugchar(int c) {
	(*realugchar)(c);
}

static int dead() {
	return last = EOF;
}

static void ugdead(int c) {
	return;
}

static void ugalive(int c) {
	if (c == EOF)
		eofread = TRUE;
	else
		inbuf[--chars_out] = c;
}

/* get the next character from a string. */

static int stringgchar() {
	return last = (chars_out == chars_in ? EOF : inbuf[chars_out++]);
}

/* set up the input stack, and put a "dead" input at the bottom, so that yyparse will always read eof */

extern void initinput() {
	istack = itop = ealloc(istacksize = 256 * sizeof (Input));
	istack->t = iFd;
	istack->fd = -1;
	realugchar = ugalive;
}

/* push an input source onto the stack. set up a new input buffer, and set gchar() */

static void pushcommon() {
	size_t idiff;
	istack->index = chars_out;
	istack->read = chars_in;
	istack->ibuf = inbuf;
	istack->lineno = lineno;
	istack->saved = save_lineno;
	istack->last = last;
	istack->eofread = eofread;
	istack++;
	idiff = istack - itop;
	if (idiff >= istacksize / sizeof (Input)) {
		itop = erealloc(itop, istacksize *= 2);
		istack = itop + idiff;
	}
	realugchar = ugalive;
	chars_out = 2;
	chars_in = 0;
}

extern void pushstring(char *a, int len) {
	pushcommon();
	chars_in = len;
	chars_out = 0;
	save_lineno = TRUE;
	inbuf = a;
	realgchar = stringgchar;
	if (save_lineno)
		lineno = 1;
	else
		--lineno;
}

/* remove an input source from the stack. restore the right kind of getchar (string,fd) etc. */

extern void popinput() {
	if (istack->t == iFd)
		close(istack->fd);
	efree(inbuf);
	--istack;
	realgchar = stringgchar;
	if (istack->t == iFd && istack->fd == -1) { /* top of input stack */
		realgchar = dead;
		realugchar = ugdead;
	}
	last = istack->last;
	eofread = istack->eofread;
	inbuf = istack->ibuf;
	chars_out = istack->index;
	chars_in = istack->read;
	if (save_lineno)
		lineno = istack->lineno;
	else
		lineno++;
	save_lineno = istack->saved;
}

/* flush input characters upto newline. Used by scanerror() */

extern void flushu() {
	int c;
	if (last == '\n' || last == EOF)
		return;
	while ((c = gchar()) != '\n' && c != EOF)
		; /* skip to newline */
	if (c == EOF)
		ugchar(c);
}

/* the wrapper loop in rc: prompt for commands until EOF, calling yyparse and walk() */

extern Node *doit() {
	bool eof;
	for (eof = FALSE; !eof;) {
		Edata block;
	        block.b = newblock();
		inityy();
		if (yyparse() == 1)
		  return 0; /* should return errsv XXX */
		eof = (last == EOF);
		if (parsetree) {
		  walk(parsetree);
		}
		restoreblock(block.b); /*savefree XXX*/
	}
	popinput();
	return parsetree;
}

/* parse a function imported from the environment */

extern Node *parseline(char *extdef, int len) {
	Node *fun;
	pushstring(extdef, len);
	fun = doit();
	return fun;
}

