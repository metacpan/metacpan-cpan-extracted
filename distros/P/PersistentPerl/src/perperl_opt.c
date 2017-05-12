
/*
 * Copyright (C) 2003  Sam Horrocks
 * 
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 *
 */

#include "perperl.h"

#define PREFIX "PERPERL_"
#define PREFIX_LEN (sizeof(PREFIX)-1)
#define PREFIX_MATCH(s) (strncmp((s), "PERPERL_", PREFIX_LEN) == 0)

#ifdef PERPERL_EFENCE
#    define STRLIST_MALLOC		1
#else
#    define STRLIST_MALLOC		10
#endif

/*
 * StrList is a variable length array of char*'s
 */
typedef struct {
    char **ptrs;
    int  len;
    int  malloced;
} StrList;

/* Globals */
static StrList exec_argv, exec_envp, perl_argv;
static const char * const *orig_argv;
static int script_argv_loc;
static int got_shbang;
static OptRec *optdefs_save;	/* For save/restore */

/*
 * StrList Methods
 */

#define strlist_len(l)		((l)->len)
#define strlist_str(l, i)	((l)->ptrs[i])
#define strlist_concat(l, in)	\
		strlist_concat2((l), (const char * const *)strlist_export(in))
#define strlist_append(l, s)	strlist_append2(l, s, strlen(s))
#define strlist_append2(l, s, len)	\
		strlist_append3((l), perperl_util_strndup((s), (len)))

static void strlist_init(StrList *lst) {
    lst->malloced = 0;
    lst->ptrs = NULL;
    lst->len = 0;
}

static void strlist_alloc(StrList *lst, int min) {
    if (lst->malloced < min) {
	lst->malloced = min;
	perperl_renew(lst->ptrs, min, char*);
    }
}

static void strlist_setlen(StrList *lst, int newlen) {
    int malloced = lst->malloced;

    while (lst->len > newlen)
	perperl_free(lst->ptrs[--(lst->len)]);
    lst->len = newlen;
    if (malloced < lst->len) {
	if (malloced)
	    malloced *= PERPERL_REALLOC_MULT;
	else
	    malloced = STRLIST_MALLOC;
	if (malloced < lst->len)
	    malloced = lst->len;
	strlist_alloc(lst, malloced);
    }
}

static void strlist_append3(StrList *lst, char *str) {
    int len = lst->len;
    strlist_setlen(lst, len+1);
    lst->ptrs[len] = str;
}

static char **strlist_export(StrList *lst) {
    strlist_alloc(lst, lst->len+1);
    lst->ptrs[lst->len] = NULL;
    return lst->ptrs;
}

static void strlist_concat2(StrList *lst, const char * const *in) {
    for (; *in; ++in)
	strlist_append(lst, *in);
}

static void strlist_free(StrList *lst) {
    strlist_setlen(lst, 0);
    perperl_free(lst->ptrs);
}

static void strlist_replace(StrList *lst, int i, char *newstr) {
    perperl_free(lst->ptrs[i]);
    lst->ptrs[i] = newstr;
}

/* Split string on whitespace */
static void strlist_split(StrList *out, const char * const *in) {
    const char * const *p;
    const char *s, *beg;

    for (p = in; *p; ++p) {
	for (s = beg = *p; *s;) {
	    if (isspace((int)*s)) {
		if (beg < s)
		    strlist_append2(out, beg, s - beg);
		while (isspace((int)*s))
		    ++s;
		beg = s;
	    } else {
		++s;
	    }
	}
	if (beg < s) {
	    strlist_append2(out, beg, s - beg);
	}
    }
}

/*
 * End of StrList stuff
 */

/* Split into arg0, perl args, perperl options and script args */
static void cmdline_split(
    const char * const *in, char **arg0, StrList *perl_args,
    StrList *perperl_opts, StrList *script_args
)
{
    int doing_perperl_opts = 0;

    /* Arg-0 */
    if (arg0)
	*arg0 = perperl_util_strdup(*in);
    ++in;

    for (; *in; ++in) {
	char **p;
	StrList split;

	/* Split on spaces */
	{
	    const char *temp[2];

	    temp[0] = *in;
	    temp[1] = NULL;
	    strlist_init(&split);
	    strlist_split(&split, temp);
	    p = strlist_export(&split);
	}

	/*
	 * If there are no options in this arg, give the whole unsplit
	 * piece to the script_argv.
	 */
	if (!*p || **p != '-') {
	    strlist_free(&split);
	    break;
	}

	/* Perl args & Persistent options */
	for (; *p && **p == '-'; ++p) {
	    if (!doing_perperl_opts)
		if ((doing_perperl_opts = (p[0][1] == '-' && p[0][2] == '\0')))
		    continue;
	    strlist_append(doing_perperl_opts ? perperl_opts : perl_args, *p);
	}

	if (*p) {
	    ++in;
	    /* Give the remaining non-options in this arg to the script */
	    if (script_args)
		strlist_concat2(script_args, (const char * const *)p);
	    strlist_free(&split);
	    break;
	}
	strlist_free(&split);
    }

    /* Take the remaining args (without splits) and give to script_args */
    if (script_args)
	strlist_concat2(script_args, (const char * const *)in);
}


int perperl_opt_set(OptRec *optrec, const char *value) {
    if (optrec->type == OTYPE_STR) {
	if ((optrec->flags & PERPERL_OPTFL_MUST_FREE) && optrec->value)
	    perperl_free(optrec->value);
	if (optrec == &OPTREC_GROUP && *value == '\0') {
	    optrec->value = "default";
	    optrec->flags &= ~PERPERL_OPTFL_MUST_FREE;
	} else {
	    optrec->value = perperl_util_strdup(value);
	    optrec->flags |= PERPERL_OPTFL_MUST_FREE;
	}
    }
    else if (optrec->type == OTYPE_TOGGLE) {
	INT_OPTVAL(optrec) = !INT_OPTVAL(optrec);
    }
    else {
	int val = atoi(value);

	switch(optrec->type) {
	    case OTYPE_WHOLE:
		if (val < 0) return 0;
		break;
	    case OTYPE_NATURAL:
		if (val < 1) return 0;
		break;
	}
	INT_OPTVAL(optrec) = val;
    }
    optrec->flags |= PERPERL_OPTFL_CHANGED;
    return 1;
}

const char *perperl_opt_get(OptRec *optrec) {
    if (optrec->type == OTYPE_STR) {
	return STR_OPTVAL(optrec);
    } else {
	static char buf[20];
	sprintf(buf, "%u", INT_OPTVAL(optrec));
	return buf;
    }
}

static int ocmp(const void *a, const void *b) {
    return strcmp((const char *)a, ((const OptRec *)b)->name);
}

static int opt_set_byname(const char *optname, int len, const char *value) {
    OptRec *match;
    char *upper;
    int retval = 0;

    /* Copy the upper-case optname into "upper" */
    perperl_new(upper, len+1, char);
    upper[len] = '\0';
    while (len--)
	upper[len] = toupper(optname[len]);

    match =
	bsearch(upper, perperl_optdefs, PERPERL_NUMOPTS, sizeof(OptRec), &ocmp);
    if (match)
	retval = perperl_opt_set(match, value);
    perperl_free(upper);
    return retval;
}

static void process_perperl_opts(StrList *perperl_opts, int len) {
    int i, j;

    for (i = 0; i < len; ++i) {
	char *s = strlist_str(perperl_opts, i);
	char letter = s[1];

	OPTIDX_FROM_LETTER(j, letter)
	if (j >= 0)
	    perperl_opt_set(perperl_optdefs + j, s+2);
	else
	    DIE_QUIET("Unknown perperl option '-%c'", letter);
    }
}

void perperl_opt_init(const char * const *argv, const char * const *envp) {
    StrList perperl_opts, script_argv;
    int opts_len_before, i;
    const char * const *p;

    strlist_init(&exec_argv);
    strlist_init(&exec_envp);
    strlist_init(&script_argv);
    strlist_init(&perl_argv);
    strlist_init(&perperl_opts);

    orig_argv = argv;

    /* Make sure perl_argv has an arg0 */
    strlist_append(&perl_argv, "perl");

    /* Split up the command line */
    cmdline_split(argv, NULL, &perl_argv, &perperl_opts, &script_argv);

    /* Append the PerlArgs option to perl_argv */
    if (OPTREC_PERLARGS.flags & PERPERL_OPTFL_CHANGED) {
	StrList split;
	const char *tosplit[2];

	strlist_init(&split);
	tosplit[0] = OPTVAL_PERLARGS;
	tosplit[1] = NULL;
	strlist_split(&split, (const char * const *)tosplit);
	strlist_concat(&perl_argv, &split);
	strlist_free(&split);
    }

    /* Append to the perperl_opts any OptRec's changed before this call */
    opts_len_before = strlist_len(&perperl_opts);
    for (i = 0; i < PERPERL_NUMOPTS; ++i) {
	OptRec *rec = perperl_optdefs + i;

	if ((rec->flags & PERPERL_OPTFL_CHANGED) && rec->letter) {
	    const char *s = perperl_opt_get(rec);
	    char *t;
	    perperl_new(t, strlen(s)+3, char);
	    sprintf(t, "-%c%s", rec->letter, s);
	    strlist_append3(&perperl_opts, t);
	}
    }

    /* Set our OptRec values based on the perperl_opts that we got from argv */
    process_perperl_opts(&perperl_opts, opts_len_before);

    /*
     * Create exec args from perl args, perperl args and script args
     * Save the location of the script args
     */
    strlist_concat(&exec_argv, &perl_argv);
    if (strlist_len(&perperl_opts)) {
	strlist_append2(&exec_argv, "--", 2);
	strlist_concat(&exec_argv, &perperl_opts);
    }
    script_argv_loc = strlist_len(&exec_argv);
    strlist_concat(&exec_argv, &script_argv);
    got_shbang = 0;

    /* Copy the environment to exec_envp */
    strlist_concat2(&exec_envp, envp);

    /* Set our OptRec values based on the environment */
    for (p = envp; *p; ++p) {
	const char *s = *p;
	if (PREFIX_MATCH(s)) {
	    const char *optname = s + PREFIX_LEN;
	    const char *eqpos = strchr(optname, '=');
	    if (eqpos)
		(void) opt_set_byname(optname, eqpos - optname, eqpos+1);
	}
    }

    strlist_free(&perperl_opts);
    strlist_free(&script_argv);

#if defined(PERPERL_VERSION) && defined(PATCHLEVEL) && defined(SUBVERSION) && \
    defined(ARCHNAME)

    if (OPTVAL_VERSION) {
	char buf[200];

	sprintf(buf,
	    "PersistentPerl %s version %s built for perl version 5.%03d_%02d on %s\n",
	    PERPERL_PROGNAME, PERPERL_VERSION, PATCHLEVEL, SUBVERSION, ARCHNAME);
	write(2, buf, strlen(buf));
	perperl_util_exit(0,0);
    }
#endif
}

/* Read the script file for options on the #! line at top. */
void perperl_opt_read_shbang(void) {
    char *argv[3], *arg0;
    StrList perperl_opts;
    PersistentMapInfo *mi;
    const char *maddr;

    if (got_shbang)
	return;
    
    got_shbang = 1;

    mi = perperl_script_mmap(1024);
    if (!mi)
	perperl_util_die("script read failed");

    maddr = (const char *)mi->addr;
    if (mi->maplen > 2 && maddr[0] == '#' && maddr[1] == '!') {
	const char *s = maddr + 2, *t;
	int l = mi->maplen - 2;
	    
	/* Find the whitespace after the interpreter command */
	while (l && !isspace((int)*s)) {
	    --l; ++s;
	}

	/* Find the newline at the end of the line. */
	for (t = s; l && *t != '\n'; l--, t++)
	    ;

	argv[0] = "";
	argv[1] = perperl_util_strndup(s, t-s);
	argv[2] = NULL;

	/* Split up the command line */
	strlist_init(&perperl_opts);
	cmdline_split(
	    (const char * const *)argv, &arg0,
	    &perl_argv, &perperl_opts, NULL
	);

	/* Put arg0 into perl_argv[0] */
	strlist_replace(&perl_argv, 0, arg0);

	/* Set our OptRec values based on the perperl opts */
	process_perperl_opts(&perperl_opts, strlist_len(&perperl_opts));
	strlist_free(&perperl_opts);
	perperl_free(argv[1]);
    }
    perperl_script_munmap();
}

void perperl_opt_set_script_argv(const char * const *argv) {
    /* Replace the existing script_argv with this one */
    strlist_setlen(&exec_argv, script_argv_loc);
    strlist_concat2(&exec_argv, argv);
    got_shbang = 0;
}

const char * const *perperl_opt_script_argv(void) {
    return (const char * const *)(strlist_export(&exec_argv) + script_argv_loc);
}

PERPERL_INLINE const char *perperl_opt_script_fname(void) {
    return strlist_export(&exec_argv)[script_argv_loc];
}

#ifdef PERPERL_BACKEND
char **perperl_opt_perl_argv(const char *script_name) {
    static StrList *full_perl_argv, argv_storage;

    if (full_perl_argv)
	strlist_free(full_perl_argv);
    else
	full_perl_argv = &argv_storage;

    /* Append the script argv to the end of perl_argv */
    strlist_init(full_perl_argv);
    strlist_concat(full_perl_argv, &perl_argv);
    if (script_name)
	strlist_append(full_perl_argv, script_name);
    strlist_concat2(full_perl_argv,
	perperl_opt_script_argv() + (script_name ? 1 : 0));

    return strlist_export(full_perl_argv);
}
#endif

const char * const *perperl_opt_orig_argv(void) {
    return orig_argv;
}

const char * const *perperl_opt_exec_envp(void) {
    return (const char * const *)strlist_export(&exec_envp);
}

#ifdef PERPERL_FRONTEND
const char * const *perperl_opt_exec_argv(void) {
    exec_argv.ptrs[0] = OPTVAL_BACKENDPROG;
    return (const char * const *)strlist_export(&exec_argv);
}
#endif

static void copy_optdefs(OptRec *dest, OptRec *src) {
    int i;

    perperl_memcpy(dest, src, PERPERL_NUMOPTS * sizeof(OptRec));
    for (i = 0; i < PERPERL_NUMOPTS; ++i)
	perperl_optdefs[i].flags &= ~PERPERL_OPTFL_MUST_FREE;
}

void perperl_opt_save(void) {
    perperl_new(optdefs_save, PERPERL_NUMOPTS, OptRec);
    copy_optdefs(optdefs_save, perperl_optdefs);
}

void perperl_opt_restore(void) {
    int i;

    for (i = 0; i < PERPERL_NUMOPTS; ++i) {
	OptRec *op = perperl_optdefs + i;
	if ((op->flags & PERPERL_OPTFL_MUST_FREE) && op->value)
	    perperl_free(op->value);
    }
    copy_optdefs(perperl_optdefs, optdefs_save);
}
