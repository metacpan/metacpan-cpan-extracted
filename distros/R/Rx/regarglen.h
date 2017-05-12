
#define GET_ARG_1_OF_1(n) (((unsigned *)(n+1))[0])
#define GET_ARG_1_OF_2(n) (((unsigned short *)(n+1))[0])
#define GET_ARG_2_OF_2(n) (((unsigned short *)(n+1))[1])

void regargprint(int, char *);

int regtype_arglen[] = {
  0, 4, 4,
};

/* 
 * In this table, 
 * 0 denotes a node with no arguments,
 * 1 denotes a node with one 32b argument, and
 * 2 denotes a node with a pair of 16b arguments.
 */

static const U8 regtype_arg[] = {
	0,		/* END */
	0,		/* SUCCEED */
	0,		/* BOL */
	0,		/* MBOL */
	0,		/* SBOL */
	0,		/* EOS */
	0,		/* EOL */
	0,		/* MEOL */
	0,		/* SEOL */
	0,		/* BOUND */
	0,		/* BOUNDL */
	0,		/* NBOUND */
	0,		/* NBOUNDL */
	0,		/* GPOS */
	0,		/* REG_ANY */
	0,		/* SANY */
	0,		/* ANYOF */
	0,		/* ALNUM */
	0,		/* ALNUML */
	0,		/* NALNUM */
	0,		/* NALNUML */
	0,		/* SPACE */
	0,		/* SPACEL */
	0,		/* NSPACE */
	0,		/* NSPACEL */
	0,		/* DIGIT */
	0,		/* DIGITL */
	0,		/* NDIGIT */
	0,		/* NDIGITL */
	0,		/* CLUMP */
	0,		/* BRANCH */
	0,		/* BACK */
	0,		/* EXACT */
	0,		/* EXACTF */
	0,		/* EXACTFL */
	0,		/* NOTHING */
	0,		/* TAIL */
	0,		/* STAR */
	0,		/* PLUS */
        2,		/* CURLY */
        2,		/* CURLYN */
        2,		/* CURLYM */
        2,		/* CURLYX */
	0,		/* WHILEM */
        1,		/* OPEN */
        1,		/* CLOSE */
        1,		/* REF */
        1,		/* REFF */
        1,		/* REFFL */
        1,		/* IFMATCH */
        1,		/* UNLESSM */
        1,		/* SUSPEND */
        1,		/* IFTHEN */
        1,		/* GROUPP */
        1,		/* LONGJMP */
        1,		/* BRANCHJ */
        1,		/* EVAL */
	0,		/* MINMOD */
	0,		/* LOGICAL */
        1,		/* RENUM */
	0,		/* OPTIMIZED */
};

