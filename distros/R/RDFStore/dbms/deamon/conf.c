/*
 *     Copyright (c) 2000-2006 Alberto Reggiori <areggiori@webweaving.org>
 *                        Dirk-Willem van Gulik <dirkx@webweaving.org>
 *
 * NOTICE
 *
 * This product is distributed under a BSD/ASF like license as described in the 'LICENSE'
 * file you should have received together with this source code. If you did not get a
 * a copy of such a license agreement you can pick up one at:
 *
 *     http://rdfstore.sourceforge.net/LICENSE
 *
 *
 * $Id: conf.c,v 1.16 2006/06/19 10:10:22 areggiori Exp $
 */

#include "dbms.h"
#include "dbmsd.h"
#include "dbms_compat.h"
#include "deamon.h"
#include "dbms_comms.h"

#include "conf.h"

typedef struct xscf {
	tops op;
	u_long ip, mask;
	struct xscf * nxt;
} txscf;

typedef enum ordertypes { 
	T_UNSET, T_ALLOW, T_DENY
} torder;

typedef struct xsctrl {
	char * dbase;
	torder first;
	struct xscf * recdeny, * recallow;
	struct xsctrl * nxt;
} txsctrl;

txsctrl * xscontrols  = NULL;    

const char  *
op2string(tops p) {
	const char * op;

	switch(p) {
	case T_NONE:	op="none";break;
	case T_RDONLY:	op="rdonly";break;
	case T_RDWR:	op="rdwr";break;
	case T_CREAT:	op="creat";break;
	case T_DROP:	op="drop";break;
	case T_ALL:	op="all";break;
	default:	op = "undefined";break;
	};

	return op;
}

static u_long 
getip(char * word) {
	struct in_addr ip;

#ifdef RDFSTORE_PLATFORM_SOLARIS
	ip.s_addr = inet_addr(word);
	if (ip.s_addr ==INADDR_NONE) {
#else
	if (inet_aton(word,&ip) != 1) {
#endif
                 struct hostent * hp;
                 if((hp = gethostbyname(word))==NULL) 
			return INADDR_NONE; /* rely on errno */
		ip.s_addr = *(u_long *) hp->h_addr;
	};

	errno = 0;
	return ip.s_addr;
}

static tops
decode_ops(char * p) {
	if (!strcmp(p,"none")) {
		return T_NONE;
	} else
	if (!strcmp(p,"rdonly")) {
		return T_RDONLY;
	} else
	if (!strcmp(p,"rdwr")) {
		return T_RDWR;
	} else
	if (!strcmp(p,"creat")) {
		return T_CREAT;
	}
	if (!strcmp(p,"drop")) {
		return T_DROP;
	}
	if (!strcmp(p,"all")) {
		return T_ALL;
	}
	return T_ERR;
}

static char *
getnextword(char ** p) {
	char *q;
	while(**p && isspace((int)(**p))) 
		(*p)++;	/* Skip any space */
 	q = *p;
	while(**p && (!(
		isspace((int)(**p)) || (**p == ',') || (**p == '>')
	       ))) (*p)++;	/* Run until we see space */
	if (**p) {
		**p = '\0';
		(*p)++;
	}
	return q;
}

/* Expect things like 
 *	single hostname
 * 	IP/bits
 * 	IP netmask
s*/
static int
decode_mask(struct xscf *cnf, char * p) {
	char * s;
	cnf->ip = 0;
	cnf->mask = INADDR_NONE;	/* Mask as exact as possible */
	if (!strcmp(p,"all")) {
		cnf->mask = INADDR_ANY; /* 0.0.0.0 */
		cnf->ip= INADDR_NONE; /* 255.255.255.255 */
	} else {
		if ((s = index(p,'/'))) {
			long len = strtol(s+1,NULL,10);
			if ((len == 0) && (errno = EINVAL))
				return -1;
			if ((len <0) || (len >32))
				return -1;
			*s = '\0';
			s++;
			cnf->mask = htonl(~((1<<(32-len))-1));
		} else
		if ((s = index(p,' '))) {
			char * q = getnextword(&p);
			if (!strcmp("netmask",q))
				q = getnextword(&p);
			if (((cnf->mask = getip(q))==INADDR_NONE) && (errno))
				return -1;
			*s = '\0';
			s++;
		}

		if (((cnf->ip = getip(p))==INADDR_NONE) && (errno))
			return -1;
	};
	/* Any bits in the IP which are masked/hidden */
	cnf->ip &= (cnf->mask);
	return 0;
}

static void 
free_config(txsctrl * cf) {
        txscf * cnf;
	for(;cf;) {
		txsctrl * p = cf; cf=cf->nxt;

		if (p->dbase) 
			free(p->dbase);

		for(cnf =  p->recallow; cnf;) {
			txscf * q = cnf; cnf=cnf->nxt;
			free(q);
		};

		for(cnf =  p->recdeny; cnf;) {
			txscf * q = cnf; cnf=cnf->nxt;
			free(q);
		};

		free(p);			
	}
}

const char *
parse_config(char * configfile) {
	static char errbuff[ 1024 ];
	char str[1024];
	char *p, * erm = NULL;
	int line = 0;
	int e = 1;
	char * nested = NULL;
	FILE * fin = stdin;
	txsctrl * nw_xscontrols = NULL;

	if (strcmp(configfile,"-")) 
		fin = fopen(configfile,"r");

	if (fin== NULL) {
		snprintf(errbuff,sizeof(errbuff),"Cannot open %s: %s",configfile,strerror(errno));
		return errbuff;
	}

	#define	doerr(x) { erm = x; goto xt; };

 	while((p = fgets(str,sizeof(str),fin))) {
		char * q;
		line ++;
		/* Strip any white space.. */
		while (*p && isspace((int)(*p))) 
			p++;

		if (!*p) 
			continue; /* ignore empty lines */

		if (*p == '#') 
			continue; /* ignore comments */

		if ((*p == '<') && (p[1] == '/')) {
			p= p+2;
			q = getnextword(&p);
			if (!nested) 
				doerr("Nesting close but no start");
			if (strcmp(q,nested))
				doerr("Nesting mismatch");
			free(nested);
			nested = NULL;
		} else
		if (*p == '<') {
			txsctrl * cnf =  malloc(sizeof(txsctrl));
			if (nested)  
				doerr("Nested too deeply");
			p++;
			nested = strdup(getnextword(&p));
			if (strcmp(nested,"dbase")) 
				doerr("Expected dbase");

			cnf->nxt = nw_xscontrols; 
			nw_xscontrols = cnf;

			cnf->dbase = strdup(getnextword(&p));
			cnf->recallow = NULL;
			cnf->recdeny = NULL;
			cnf->first = T_UNSET;
		} else
		if ((q = getnextword(&p))) {
			char * r;
			tops op;
			if (!nested) 
				doerr("Not a valid directive");

			/* <order> [by] <deny|allow>,<allow,deny> 
			 * <allow|deny> [operation] <ops> [from] <spec> 
                         */
			do {
	 			r = getnextword(&p);
			} while ((!strcmp(r,"operation")) || (!strcmp(r,"by")));

			if (!strcmp(q,"order")) {
				// char * r;
 				// r = getnextword(&p);
				if (!strcmp(r,"allow")) 
					nw_xscontrols->first = T_ALLOW;
				else
				if (!strcmp(r,"deny")) 
					nw_xscontrols->first = T_DENY;
				else
					doerr("deny or allow expected after order.");

				r = getnextword(&p);
				if ((nw_xscontrols->first == T_DENY) && (strcmp(r,"allow")))
					doerr("expected allow after order deny");
				if ((nw_xscontrols->first == T_ALLOW) && (strcmp(r,"deny")))
					doerr("expected deny after order allow");
				r = getnextword(&p);
				if (r && *r)
					doerr("trailing info after ordere line");
				continue;
			};

			/* <allow|deny> [operation] <ops> [from] <spec> 
			 */
			if ((op = decode_ops(r))==T_ERR)
				doerr("ops spec not recognized");

			/* [from] <spec> 
			 */
	 		do { 
				r = getnextword(&p);
			} while (!strcmp(r,"from"));

			/* <spec> 
			 */
			if (!r || !*r)
				doerr("expected an argument\n");

			if (!strcmp(q,"allow")) {
				txscf * s = malloc(sizeof(txscf));
				if (decode_mask(s, r))
					doerr("syntax error in allow specification");
				s->op = op;
				s->nxt = nw_xscontrols->recallow;
				nw_xscontrols->recallow = s;
			} else
			if (!strcmp(q,"deny")) {
				txscf * s = malloc(sizeof(txscf));
				if (decode_mask(s, r))
					doerr("syntax error in deny specification");
				s->op = op;
				s->nxt = nw_xscontrols->recdeny;
				nw_xscontrols->recdeny = s;
			} else
				doerr("Unknown directive (deny from, allow from or order expected");
		} else {
			doerr("Line terminated early");
		}
	}

	if (ferror(stdin)) {
		snprintf(errbuff,sizeof(errbuff),"Error reading config file: %s",strerror(errno));
		goto xt;
	};

	e = 0;

	/* Plase any baseline spec's at the start of the sequence.. */
{
	txsctrl * p, * * q, * h;
	for(p=nw_xscontrols;(p) && (p->nxt);p=p->nxt) {
		if (!strcmp(p->nxt->dbase,"_")) {
			txsctrl * cnf = nw_xscontrols;
			nw_xscontrols = p->nxt;
			p->nxt = p->nxt->nxt;
			nw_xscontrols->nxt = cnf;
		};
	}
	/* Place any fall through *'s at the end of the sequence */
	h = NULL;
	for(q = &nw_xscontrols; *q;) {
		txsctrl ** r = q; 
		q = &((*q)->nxt);
		if (!strcmp((*r)->dbase,"*")) {
			txsctrl * i = h;
			h = *r;
			(*r) = (*r)->nxt;
			h->nxt = i;
		};
	};
	for(q = &nw_xscontrols; *q; q=&( (*q)->nxt )) {};
	(*q) = h;
}
	 
xt:
	fclose(stdin);
	if (erm) 
		snprintf(errbuff,sizeof(errbuff),"Error parsing config file at line %d: %s",line,erm);

	/* If the parse is success full; clean up the old config struct, if
	 * any; and swap in the new one. Otherwise clean up the new partially
	 * created conf; and keep the old one in place.
	 */
	if (e) {
		free_config(nw_xscontrols);
	} else {
		free_config(xscontrols);
		xscontrols=nw_xscontrols;
	}
	return e ? errbuff : NULL;
}

/* String compare; which allows a '*' at
 * the end of a name.
 */
static int 
_dbcmp(char * name, char *conf) {
	int l = strlen(conf);
	if (conf[l-1] == '*')
		return strncmp(conf,name,l-1);
	return strcmp(conf,name);
}

tops  _allowed(txscf *p, u_long ip) {
	tops l = T_ERR;
	for(;p;p=p->nxt) {
		/* Should we also check on how exact the match is - and 
		 * do the bigger masks first ? Or do them in order ?
		 */
		if ((ip & p->mask) == p->ip)
			l = MAX(l,p->op);
			/* if (mask > last_mask) { l = p->op; last_mask = p->mask; }; */
	}
	return l;
}

static tops 
_deny( tops x) {
	if (x == T_ALL) 		/* deny all */
		return T_NONE;
	if (x == T_DROP)		/* dropping no - but create fine */
		return T_CREAT;
	if (x == T_CREAT) 		/* deny create - i.e. up to rdw*/
		return T_RDWR;
	if (x == T_RDWR)		/* deny rdwr - i.e. up to rdonly */
		return T_RDONLY;
	if (x == T_RDONLY)		
		return T_NONE;
	if (x == T_NONE)		/* deny none - i.e. all allowed */
		return T_CREAT;
	return T_ERR;
}

static tops 
_allow( tops x) {
	if (x == T_ALL) 		/* allow all */
		return T_DROP;
	return x;
}

tops _allowed_ops_cnf(txsctrl * cnf, u_long ip) {
	tops a = _allow(_allowed(cnf->recallow, ip));
	tops d = _deny(_allowed(cnf->recdeny, ip));
	if (a==T_ERR)
		return d;
	if (d==T_ERR)
		return a;
	if (cnf->first == T_DENY) {
		return MAX(a,d);
	} else {
		return MIN(a,d);
	}
}

/* Return the OPS level allowed to this
 * IP; regardless of database.
 */
tops allowed_ops(u_long ip) {
	txsctrl * p = xscontrols;
	tops min = T_NONE;

	for(;p;p=p->nxt) 
		min = MAX(min,_allowed_ops_cnf(p,ip));

	/* Return the baseline, if any.. */
	return min;
}

/* Return the OPS level allowed to this
 * IP and database
 */
tops allowed_ops_on_dbase(u_long ip, char *dbase) {
	txsctrl * p = xscontrols;
	tops min = T_NONE;

	for(;p;p=p->nxt) {
		/* Apply baseline specification.. 
		 */
		if ((p->dbase) && (!strcmp("_",p->dbase)))
			min = _allowed_ops_cnf(p,ip);

		/* Any specifics.. or the tailing default will
		 * override the baseline.
		 */
		if ((p->dbase) && ((!_dbcmp(dbase,p->dbase)) || (!strcmp("*",p->dbase)))) {
			tops s = _allowed_ops_cnf(p,ip);
			if (s != T_ERR)
				return s;
			min = MAX(min,s);
		}
	}

	/* Return the baseline, if any.. */
	return min;
}
		
#if __TESTING__CONF__


void dump_config( txsctrl * p) {
	if (!p) 
		printf("No configurations.\n");
	for(;p;p=p->nxt) {
		int i;
		printf("<dbase %s>\n",p->dbase);
		for(i=0;i<2;i++) {
			txscf * q = NULL;
			char * what;
			if (p->first == T_ALLOW) 
				q = i ? p->recdeny : p->recallow;
			else
			if (p->first == T_DENY) 
				q = i ? p->recallow : p->recdeny;
			else
				printf("Error!\n");

			if (!i)
				printf("\torder %s\n", (p->first == T_ALLOW) ? "allow, deny" : "deny, allow");
			if (q)
				printf("	# %s check\n",i ? "Then" : "First");

			what = (q == p->recallow) ? "allow" : "deny";

			for(;q; q=q->nxt) {
				struct in_addr in;
				const char * op = op2string(q->op);
				printf("	%s %s from",what,op);
				in.s_addr = q->ip;
				printf(" ip %s",inet_ntoa(in));
				in.s_addr = q->mask;
				printf(" netmask %s",inet_ntoa(in));
				printf("\n");
			};
		};
		printf("</dbase>\n\n");
	};
}

int main(int argc, char ** argv) {
	int i; const char * e;
	if (argc < 2)  {
		fprintf(stderr,"Specify file name and perhaps some IPs/Hosts\n");
		exit(1);
	}

	if ((e=parse_config(argv[1]))) {
		fprintf(stderr,"Failed: %s\n",e);
		exit(2);
	};

	dump_config(xscontrols);

	if (argc == 2)
		exit(0);
	
	if (argc % 2) {
		fprintf(stderr,"Need dbase and host pairs\n");
		exit(3);	
	}
			
	for(i = 2; i<argc;i+=2) {
		u_long ip = getip(argv[i+1]);
		tops p;
		struct in_addr in; 
		in.s_addr = ip; 
		if ((argv[i][0] == '\0') || (argv[i][0] == '*'))
			p = allowed_ops(ip);
		else
			p = allowed_ops_on_dbase(ip,argv[i]);
		printf("DBASE '%s': From Host:%s (%s) --> %s\n",argv[i],argv[i+1],inet_ntoa(in),op2string(p));
	}
	exit(0);
}
#endif
