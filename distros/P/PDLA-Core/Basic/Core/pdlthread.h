
#ifndef __PDLATHREAD_H
#define __PDLATHREAD_H


typedef struct pdl_errorinfo {
	char *funcname;
	char **paramnames;
	int nparamnames;
} pdl_errorinfo;


/* comment out unless debugging
   Note that full recompile will be needed since this switch
   changes the pdl_thread struct
*/
#define PDLA_THREAD_DEBUG

#define PDLA_THREAD_MAGICKED 0x0001
#define PDLA_THREAD_MAGICK_BUSY 0x0002
#define PDLA_THREAD_INITIALIZED 0x0004

#ifdef PDLA_THREAD_DEBUG
#define PDLA_THR_MAGICNO 0x92314764
#define PDLA_THR_SETMAGIC(it) it->magicno = PDLA_THR_MAGICNO
#define PDLA_THR_CLRMAGIC(it) (it)->magicno = 0x99876134
#else
#define PDLA_THR_CLRMAGIC(it) (void)0
#endif

/* XXX To avoid mallocs, these should also have "default" values */
typedef struct pdl_thread {
	pdl_errorinfo *einfo;
#ifdef PDLA_THREAD_DEBUG
        int magicno;
#endif
	int gflags;	/* Flags about this struct */
	int ndims;	/* Number of dimensions threaded over */
	int nimpl;	/* Number of these that are implicit */
	int npdls;	/* Number of pdls involved */
	int nextra;
	PDLA_Indx *inds;	/* Indices for each of the dimensions */
	PDLA_Indx *dims;	/* Dimensions of each dimension */
	PDLA_Indx *offs;	/* Offsets for each of the pdls */
	PDLA_Indx *incs;	/* npdls * ndims array of increments. Fast because
	 		               of constant indices for first loops */
	PDLA_Indx *realdims;  /* realdims for each pdl (e.g., specified by PP signature) */
	pdl **pdls;
        char *flags;    /* per pdl flags */
        int mag_nth;    /* magicked thread dim */
        int mag_nthpdl; /* magicked piddle */
        int mag_nthr;   /* number of threads */
} pdl_thread;


/* Thread per pdl flags */
#define		PDLA_THREAD_VAFFINE_OK	0x01

#define PDLA_TVAFFOK(flag) (flag & PDLA_THREAD_VAFFINE_OK)
#define PDLA_TREPRINC(pdl,flag,which) (PDLA_TVAFFOK(flag) ? \
		pdl->vafftrans->incs[which] : pdl->dimincs[which])

#define PDLA_TREPROFFS(pdl,flag) (PDLA_TVAFFOK(flag) ? pdl->vafftrans->offs : 0)


/* No extra vars; not sure about the NULL arg, means no per pdl args */
#define PDLA_THREADINIT(thread,pdls,realdims,creating,npdls,info) \
	  PDLA->initthreadstruct(0,pdls,realdims,creating,npdls,info,&thread;\
				NULL)

#define PDLA_THREAD_DECLS(thread)

#define PDLA_THREADCREATEPAR(thread,ind,dims,temp) \
	  PDLA->thread_create_parameter(&thread,ind,dims,temp)
#define PDLA_THREADSTART(thread) PDLA->startthreadloop(&thread)

#define PDLA_THREADITER(thread,ptrs) PDLA->iterthreadloop(&thread,0,NULL)

#define PDLA_THREAD_INITP(thread,which,ptr) /* Nothing */
#define PDLA_THREAD_P(thread,which,ptr) ((ptr)+(thread).offs[ind])
#define PDLA_THREAD_UPDP(thread,which,ptr) /* Nothing */

/* __PDLATHREAD_H */
#endif
