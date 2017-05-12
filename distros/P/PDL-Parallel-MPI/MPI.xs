/* 
	This file used to generate backend for PDL::Parallel::MPI.

	Much of this code is copied from or based off of 
	the perl module Parallel::MPI-0.03 by Josh Wilmes
	and Chris Stevens.  Used with permission.

	This file also borrows heavily from perl::PDL::CallExt.xs.

	Everything else: 
		Darin McGill
		darin@uclink4.berkeley.edu
		4/21/2002
 */
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <mpi.h>

#define MPI_STRING ((MPI_Datatype)34)
/*#define  ARGV_DEBUG*/

#ifdef FLOAT_HACK
# undef MPI_FLOAT
# define MPI_FLOAT MPI_DOUBLE
#endif

#include "utils.c"

/* don't ask- mpicc hoses up these definitions */
#undef VERSION
#undef XS_VERSION
#define VERSION "0.01"
#define XS_VERSION "0.01"

#include "pdl.h"
#include "pdlcore.h"
#include <string.h>

static Core* PDL; /* Structure hold core C functions */
SV* CoreSV;       /* Get's pointer to perl var holding core structure */

MPI_Status global_status;

MPI_Op opmap(char * op) 
{

	if (! strcmp(op,"+"))	return MPI_SUM; 
	if (! strcmp(op,"*"))	return MPI_PROD;

	if (! strcmp(op,"max"))	return MPI_MAX;
	if (! strcmp(op,"min"))	return MPI_MIN;

	if (! strcmp(op,"&"))	return MPI_BAND; 
	if (! strcmp(op,"|"))	return MPI_BOR; 
	if (! strcmp(op,"^"))	return MPI_BXOR; 

	if (! strcmp(op,"and"))	return MPI_LAND; 
	if (! strcmp(op,"or"))	return MPI_LOR; 
	if (! strcmp(op,"xor"))	return MPI_LXOR; 
	else croak("\nPDL::Parallel::MPI - \nOperator to opmap not recognized!\n");
}

MPI_Datatype pdl_mpi_typemap(int pdl_datatype)
{
	/*enum pdl_datatypes { PDL_B, PDL_S, PDL_US, PDL_L, PDL_F, PDL_D };*/
	switch (pdl_datatype) 
	{
		case PDL_B: return MPI_BYTE;
		case PDL_S: return MPI_SHORT;
		case PDL_US: return MPI_UNSIGNED_SHORT;
		case PDL_L: return MPI_LONG;
		case PDL_F: return MPI_FLOAT;
		case PDL_D: return MPI_DOUBLE;
	}
	croak("pdl_mpi_typemap problem\n");
}

MODULE = PDL::Parallel::MPI		PACKAGE = PDL::Parallel::MPI
PROTOTYPES: DISABLE

BOOT:
   /* Get pointer to structure of core shared C routines */
   CoreSV = perl_get_sv("PDL::SHARE",FALSE);  /* SV* value */
   if (CoreSV==NULL)
     croak("This module requires use of PDL::Core first");
   PDL = (Core*) (void*) SvIV( CoreSV );  /* Core* value */

int
get_rank(MPI_Comm comm = MPI_COMM_WORLD)
      CODE:
        MPIpm_errhandler("MPI_Comm_rank", MPI_Comm_rank(comm,&RETVAL));
      OUTPUT:
        RETVAL

void
check_piddle(SV *sv)
	PREINIT:
		pdl * piddle;
		double * the_data;
		int i;
	CODE:
   		/* XXX this mostly for debugging */
		piddle = (pdl *) SvIV(sv);
		the_data = (double *) piddle->data;
		PDL_CHKMAGIC(piddle);
		for (i=0;i<piddle->nvals;i++)
			fprintf(stdout, "dim0 = %i piddle(%i) = %f\n",piddle->dims[0],i,the_data[i]);

void
send_test(double d, int dest)
	PREINIT:
		int retval;
		int tag = 0;
		int flag;
	CODE:
        MPIpm_errhandler("MPI_Initialized",  MPI_Initialized(&flag));
		if (! flag) { croak("send_test: MPI not initialized !\n"); }
		else { fprintf(stdout, "intalized ok from inside MPI.xs -- send_test\n"); }
		retval = MPI_Send(&d,1,MPI_DOUBLE,dest,tag,MPI_COMM_WORLD);
		MPIpm_errhandler("send_test",retval);

double
receive_test(int source)
	PREINIT:
		double d;
		int retval;
		int tag = 0;
		int flag;
	CODE:
        MPIpm_errhandler("MPI_Initialized",  MPI_Initialized(&flag));
		if (! flag) { croak("receive_test: MPI not initialized !\n"); }
		else { fprintf(stdout, "intalized ok from inside MPI.xs -- receive_test\n"); }
		retval = 
		MPI_Recv(&d,1, MPI_DOUBLE,source,tag,MPI_COMM_WORLD,&global_status);
		MPIpm_errhandler("receive_test",retval);
		RETVAL = d;
	OUTPUT:
		RETVAL

void
xs_send(SV *sv,int dest,int tag=0,MPI_Comm comm=MPI_COMM_WORLD)
	PREINIT:
		pdl *piddle; 
		double * the_data;
		int retval;
	CODE:
		piddle = (pdl *) SvIV(sv);
		PDL_CHKMAGIC(piddle);
		the_data = (double *) piddle->data;
		retval = MPI_Send(the_data,piddle->nvals, pdl_mpi_typemap(piddle->datatype),dest,tag,comm);
		MPIpm_errhandler("&PDL::Parallel::MPI::send",retval);

void
xs_receive(SV *sv,int source,int tag=0,MPI_Comm comm=MPI_COMM_WORLD)
	PREINIT:
		pdl *piddle; 
		double * the_data;
		int retval;
	CODE:
		piddle = (pdl *) SvIV(sv);
		PDL_CHKMAGIC(piddle);
		the_data = (double *) piddle->data;
		retval = 
		MPI_Recv(the_data,piddle->nvals, pdl_mpi_typemap(piddle->datatype),
				source,tag,comm,&global_status);
		MPIpm_errhandler("&PDL::Parallel::MPI::receive",retval); 

void
get_status_list()
	PPCODE:
	    /* return the status as a 4 element array:
	     * (count,MPI_SOURCE,MPI_TAG,MPI_ERROR) */
	    XPUSHs(sv_2mortal(newSViv(global_status.count)));
	    XPUSHs(sv_2mortal(newSViv(global_status.MPI_SOURCE)));
	    XPUSHs(sv_2mortal(newSViv(global_status.MPI_TAG)));
	    XPUSHs(sv_2mortal(newSViv(global_status.MPI_ERROR)));

void
xs_broadcast(SV * sv,int root=0, MPI_Comm comm = MPI_COMM_WORLD)
	PREINIT:
		pdl *piddle; 
		double * the_data;
		int retval;
	CODE:
		piddle = (pdl *) SvIV(sv);
		PDL_CHKMAGIC(piddle);
		the_data = (double *) piddle->data;
		retval = 
		MPI_Bcast(the_data,piddle->nvals, pdl_mpi_typemap(piddle->datatype),root,comm);
		MPIpm_errhandler("&PDL::Parallel::MPI::broadcast",retval); 

void 
xs_scatter(SV * source_sv, SV * dest_sv, int root=0, MPI_Comm comm = MPI_COMM_WORLD)
	PREINIT:
		int rank;
		pdl * source_piddle; 
		pdl * dest_piddle;
		int err_code;
		void * source_data;
		MPI_Datatype sendtype;
	CODE:
        MPIpm_errhandler("MPI_Comm_rank", MPI_Comm_rank(comm,&rank));

		dest_piddle = (pdl *) SvIV(dest_sv);
		PDL_CHKMAGIC(dest_piddle);

		if (rank == root) {
			source_piddle=(pdl *) SvIV(source_sv);
			PDL_CHKMAGIC(source_piddle);
			source_data = source_piddle->data;
			sendtype=pdl_mpi_typemap(source_piddle->datatype);
		} else {
			/* MPI documentation says sendtype is signifigant only at
			 * root.  MPI documentation lies.  This is a silly hack
			 * to get around the problem.  email me if you know of a better
			 * work around.
			 */
			sendtype= pdl_mpi_typemap(dest_piddle->datatype);
		}

		err_code = MPI_Scatter(
			 source_data, dest_piddle->nvals, sendtype,
			 dest_piddle->data,   dest_piddle->nvals, pdl_mpi_typemap(dest_piddle->datatype),
				root, comm);
		MPIpm_errhandler("scatter-MPI_Scatter", err_code);

void 
xs_gather(SV * source_sv, SV * dest_sv, int root=0, MPI_Comm comm = MPI_COMM_WORLD)
	PREINIT:
		int rank;
		pdl * source_piddle; 
		pdl * dest_piddle;
		int err_code;
		void * dest_data;
		int dest_count;
		MPI_Datatype desttype;
	CODE:	
        MPIpm_errhandler("MPI_Comm_rank", MPI_Comm_rank(comm,&rank));

		source_piddle = (pdl *) SvIV(source_sv);
		PDL_CHKMAGIC(source_piddle);

		if (rank == root) {
			dest_piddle=(pdl *) SvIV(dest_sv);
			PDL_CHKMAGIC(dest_piddle);
			dest_data = dest_piddle->data;
			desttype=pdl_mpi_typemap(dest_piddle->datatype);
		} else {
			/* see comment in scatter */
			desttype=pdl_mpi_typemap(source_piddle->datatype);
		}

		err_code = MPI_Gather(
			 source_piddle->data, source_piddle->nvals, pdl_mpi_typemap(source_piddle->datatype),
			 dest_data,  source_piddle->nvals , desttype,
				root, comm);
		MPIpm_errhandler("gather-MPI_Gather", err_code);


void 
xs_allgather(SV * source_sv, SV * dest_sv,  MPI_Comm comm = MPI_COMM_WORLD)
	PREINIT:
		pdl * source_piddle; 
		pdl * dest_piddle;
		int err_code;
	CODE:	
		source_piddle = (pdl *) SvIV(source_sv);
		dest_piddle   = (pdl *) SvIV(dest_sv);

		PDL_CHKMAGIC(dest_piddle);
		PDL_CHKMAGIC(source_piddle);


		err_code = MPI_Allgather(
			 source_piddle->data, source_piddle->nvals, pdl_mpi_typemap(source_piddle->datatype),
			 dest_piddle->data,   source_piddle->nvals, pdl_mpi_typemap(dest_piddle->datatype),
			 comm);
		MPIpm_errhandler("gather-MPI_Gather", err_code);

void 
xs_alltoall(SV * source_sv, SV * dest_sv,  MPI_Comm comm = MPI_COMM_WORLD)
	PREINIT:
		pdl * source_piddle; 
		pdl * dest_piddle; 
		int err_code;
		int comm_size;
		int send_count, recv_count;
	CODE:	
        MPIpm_errhandler("MPI_Comm_size",  MPI_Comm_size(comm,&comm_size));

		source_piddle = (pdl *) SvIV(source_sv);
		dest_piddle = (pdl *) SvIV(dest_sv);

		PDL_CHKMAGIC(source_piddle);
		PDL_CHKMAGIC(dest_piddle);


		send_count = ((double) source_piddle->nvals) / comm_size;
		recv_count = ((double) dest_piddle->nvals) / comm_size;

		err_code = MPI_Alltoall(
			 source_piddle->data, send_count, pdl_mpi_typemap(source_piddle->datatype),
			 dest_piddle->data,   recv_count, pdl_mpi_typemap(dest_piddle->datatype),
			 comm);
		MPIpm_errhandler("alltoall-MPI_Alltoall", err_code);


void 
xs_reduce(SV * source_sv, SV * dest_sv, char * op="+", int root=0,  MPI_Comm comm=MPI_COMM_WORLD)
	PREINIT:
		pdl * source_piddle; 
		pdl * dest_piddle; 
		int err_code;
		int rank;
		void * dest_data;
	CODE:	
        MPIpm_errhandler("MPI_Comm_rank", MPI_Comm_rank(comm,&rank));

		source_piddle = (pdl *) SvIV(source_sv);
		PDL_CHKMAGIC(source_piddle);

		if (rank == root) {
			dest_piddle = (pdl *) SvIV(dest_sv);
			PDL_CHKMAGIC(dest_piddle);
			dest_data = dest_piddle->data;
		}


		err_code = MPI_Reduce(
			 source_piddle->data, 
			 dest_data,   
			 source_piddle->nvals, 
			 pdl_mpi_typemap(source_piddle->datatype),
			 opmap(op), 
			 root, comm);
		MPIpm_errhandler("alltoall-MPI_Alltoall", err_code);


void 
xs_allreduce(SV * source_sv, SV * dest_sv, char * op="+",  MPI_Comm comm=MPI_COMM_WORLD)
	PREINIT:
		pdl * source_piddle; 
		pdl * dest_piddle; 
		int err_code;
	CODE:	
		source_piddle = (pdl *) SvIV(source_sv);
		dest_piddle = (pdl *) SvIV(dest_sv);

		PDL_CHKMAGIC(source_piddle);
		PDL_CHKMAGIC(dest_piddle);


		err_code = MPI_Allreduce(
			 source_piddle->data, 
			 dest_piddle->data,   
			 source_piddle->nvals, 
			 pdl_mpi_typemap(source_piddle->datatype),
			 opmap(op), 
			 comm);
		MPIpm_errhandler("alltoall-MPI_Alltoall", err_code);

void 
xs_scan(SV * source_sv, SV * dest_sv, char * op="+",  MPI_Comm comm=MPI_COMM_WORLD)
	PREINIT:
		pdl * source_piddle; 
		pdl * dest_piddle; 
		int err_code;
	CODE:	
		source_piddle = (pdl *) SvIV(source_sv);
		dest_piddle = (pdl *) SvIV(dest_sv);

		PDL_CHKMAGIC(source_piddle);
		PDL_CHKMAGIC(dest_piddle);


		err_code = MPI_Scan(
			 source_piddle->data, 
			 dest_piddle->data,   
			 source_piddle->nvals, 
			 pdl_mpi_typemap(source_piddle->datatype),
			 opmap(op), 
			 comm);
		MPIpm_errhandler("alltoall-MPI_Alltoall", err_code);

int 
xs_nvals(SV * sv)
	PREINIT:
		pdl * piddle;
	CODE:	
		piddle=(pdl *) SvIV(sv);
		PDL_CHKMAGIC(piddle);
		RETVAL=piddle->nvals;
	OUTPUT:
		RETVAL
		
void 
xs_reduce_scatter(SV * source_sv, SV * dest_sv, SV * recv_count_sv, char * op="+",  MPI_Comm comm=MPI_COMM_WORLD)
	PREINIT:
		pdl * source_piddle; 
		pdl * dest_piddle; 
		pdl * recv_count_piddle;
		int err_code;
	CODE:	
		source_piddle = (pdl *) SvIV(source_sv);
		dest_piddle = (pdl *) SvIV(dest_sv);
		recv_count_piddle = (pdl *) SvIV(recv_count_sv);

		PDL_CHKMAGIC(source_piddle);
		PDL_CHKMAGIC(dest_piddle);
		PDL_CHKMAGIC(recv_count_piddle);


		if (recv_count_piddle->datatype != PDL_L) croak("recv_count must be of type PDL_L\n");

		err_code = MPI_Reduce_scatter(
			 source_piddle->data, 
			 dest_piddle->data,   
			 recv_count_piddle->data, 
			 pdl_mpi_typemap(source_piddle->datatype),
			 opmap(op), 
			 comm);
		MPIpm_errhandler("PDL::Parallel::MPI::reduce_scatter", err_code);



int
comm_size(MPI_Comm comm=MPI_COMM_WORLD)
      CODE:
        MPIpm_errhandler("MPI_Comm_size",  MPI_Comm_size(comm,&RETVAL));
      OUTPUT:
        RETVAL
	
		
void *
xs_send_nonblocking(SV *sv,int dest,int tag=0,MPI_Comm comm=MPI_COMM_WORLD)
	PREINIT:
		pdl *piddle; 
		int err_code;
		MPI_Request * request;
	CODE:
		piddle = (pdl *) SvIV(sv); 
		PDL_CHKMAGIC(piddle);

		request = malloc(sizeof (MPI_Request));
		err_code = MPI_Isend(
			piddle->data, piddle->nvals, pdl_mpi_typemap(piddle->datatype),
			dest, tag,comm,request);
		MPIpm_errhandler("send_nonblocking",err_code);
		RETVAL=request;
	OUTPUT:
		RETVAL

void *
xs_receive_nonblocking(SV *sv,int source,int tag=0,MPI_Comm comm=MPI_COMM_WORLD)
	PREINIT:
		pdl *piddle; 
		int retval;
		MPI_Request * request;
	CODE:
		piddle = (pdl *) SvIV(sv); 
		PDL_CHKMAGIC(piddle);

		request = malloc(sizeof (MPI_Request));
		retval = MPI_Irecv(
			piddle->data, piddle->nvals, pdl_mpi_typemap(piddle->datatype),
			source, tag,comm,request);
		MPIpm_errhandler("receive_nonblocking",retval);
		RETVAL=request;
	OUTPUT:
		RETVAL

void 
request_wait(void * request)
	CODE:
		MPIpm_errhandler("request_wait",
			MPI_Wait(  (MPI_Request *)  request,&global_status));

int 
request_test(void * request)
	CODE:
		MPIpm_errhandler("request_test",
			MPI_Test(  (MPI_Request *)  request,&RETVAL,&global_status));
	OUTPUT:
		RETVAL

 # XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX #
 # XXX end of my code   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX #
 # XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX #

double
constant(name,arg)
	char *		name
	int		arg


int
MPI_Comm_size(comm)
	MPI_Comm	comm
      PREINIT:
        int d;
      CODE:
        MPIpm_errhandler("MPI_Comm_size",  MPI_Comm_size(comm,&d));
	RETVAL = d;
      OUTPUT:
        RETVAL


int
MPI_Comm_rank(comm)
	MPI_Comm	comm
      PREINIT:
        int d;
      CODE:
        MPIpm_errhandler("MPI_Comm_rank", MPI_Comm_rank(comm,&d));
	RETVAL = d;
      OUTPUT:
        RETVAL

void
MPI_Init()
      PREINIT:
	AV *args_av;
	SV **sv_tmp;
	SV *sv_tmp2;
	SV *argv0;
        int argc;
	char **argv;
	int i;
      CODE:
        /* Get @ARGV */
        args_av = perl_get_av("main::ARGV", TRUE);
	if(args_av == NULL)
	    croak("Parallel::MPI: $ARGV not set. Oops");

        /* Get $0 */
        argv0 = perl_get_sv("main::0", FALSE);
	if(argv0 == NULL)
	    croak("Parallel::MPI: $0 not set. Oops");

        /* We can't run MPI from a -e or a - script. */
	if(!strncmp(SvPV(argv0, PL_na), "-", 1) ||
           !strncmp(SvPV(argv0, PL_na), "-e", 2))
	    croak("Parallel::MPI: Cannot use MPI with command line script");
 
	/* debug */
#ifdef ARGV_DEBUG
	printf("[%d] av_len=%d\n",getpid(),av_len(args_av));
 	for (i=0 ; i <= av_len(args_av) ; i++) {
	    sv_tmp = av_fetch(args_av,i,0);
	    printf("[%d] $ARGV[%d]=%s\n",getpid(),i,SvPV(*sv_tmp, PL_na));
	}
#endif
 
        /* argc = $#ARGV+1  +1 for argv[0] */
	argc = av_len(args_av)+2;
	if (argc == 1) {
	    croak("MPI_Init: no arguments found in the argv");
	} else {
            /* build up argv by setting argv[0] from $0
	       and the rest from @ARGV

               We add an extra NULL to prevent a coredump
               during global destruction
	    */
	    argv = (char**) malloc((argc+1) * sizeof(char*));
            argv[0] = strdup(SvPV(argv0, PL_na));
	    for(i=1; i<argc; i++) {
	        sv_tmp = av_fetch(args_av,i-1,0);
	        if (sv_tmp == NULL) {
		    argv[i] = NULL;
	        } else {
		    argv[i] = strdup(SvPV(*sv_tmp, PL_na));
	        }
            }
            argv[argc] = NULL; /* prevents coredumps */
	}

	/* debug */
#ifdef ARGV_DEBUG
	printf("[%d] argc=%d\n",getpid(),argc);
 	for (i=0;i<argc;i++)
	    printf("[%d] argv[%d]=%s\n",getpid(),i,argv[i]);
#endif
        
        /* Call the actual function */
	MPIpm_errhandler("MPI_Init",MPI_Init(&argc, &argv));

        /* Allow later MPI funcs to return to our error handler */
	MPI_Errhandler_set(MPI_COMM_WORLD, MPI_ERRORS_RETURN);

	/* debug */
#ifdef ARGV_DEBUG
	printf("[%d] argc=%d\n",getpid(),argc);
 	for (i=0;i<argc;i++)
	    printf("[%d] argv[%d]=%s\n",getpid(),i,argv[i]);
#endif

        /* Now copy argv back to @ARGV by clearing out @ARGV and pushing
	   each arg back onto @ARGV. */
        if(argc > 1) {
	    av_extend(args_av, argc-1);
            av_clear(args_av);
	    for(i=1;i<argc;i++) {
                sv_tmp2 = newSVpv(argv[i], 0);
                sv_tmp2 = SvREFCNT_inc(sv_tmp2);
		av_push(args_av, sv_tmp2);
	    }
	} else {
            /* No args; clear @ARGV */
            av_clear(args_av);
	}

	/* debug */
#ifdef ARGV_DEBUG
	printf("[%d] av_len=%d\n",getpid(),av_len(args_av));
 	for (i=0 ; i <= av_len(args_av) ; i++) {
	    sv_tmp = av_fetch(args_av,i,0);
	    if (sv_tmp == NULL)
		printf("[%d] $ARGV[%d]=undef\n",getpid(),i);
	    else {
		printf("[%d] $ARGV[%d]=%s\n",getpid(),i,SvPV(*sv_tmp, PL_na));
	    }
	}
#endif


void
MPI_Finalize()
    PREINIT:
	int rc;
    CODE:
	rc = MPI_Finalize();
        MPIpm_errhandler("MPI_Finalize",rc);


void
MPI_Send(ref, count, datatype, dest, tag, comm)
    SV* ref
    int count
    MPI_Datatype datatype
    int	dest
    int	tag
    MPI_Comm comm
  PREINIT:
    int len;
    void* buf;
    int ret;
  CODE:     
    if (! SvROK(ref)) 
	croak("MPI_Send: First argument is not a reference!");

    if (SvTYPE(SvRV(ref)) == SVt_PVHV) {
	croak("MPI_Send: Hashes are not supported yet");
    } else if (SvTYPE(SvRV(ref)) == SVt_PVAV) {
#ifdef SEND_DEBUG
	int i;
#endif /* SEND_DEBUG */
	AV *stuff = (AV*) SvRV(ref);
        if(count > (av_len(stuff)+1)) {
            printf("MPI_Send: count param is larger than given array.  Using "
                 "array length.\n");
            count = av_len(stuff)+1;
        }
#ifdef SEND_DEBUG
	printf("[%d] av_len=%d\n",getpid(),av_len(stuff));
 	for (i=0 ; i <= av_len(stuff) ; i++) {
	    SV **sv_tmp = av_fetch(stuff,i,0);
	    if (sv_tmp == NULL)
		printf("[%d] $stuff[%d]=undef\n",getpid(),i);
	    else {
		printf("[%d] $stuff[%d]=%s\n",getpid(),i,SvPV(*sv_tmp, PL_na));
	    }
	}
#endif /* SEND_DEBUG */
        len = MPIpm_packarray(&buf, stuff, datatype, count);
#ifdef SEND_DEBUG
        printf("[%d] len=%d\n[%d] ", getpid(), len, getpid());
	for(i=0;i<len;i++) {
	    printf("%02x ", (unsigned char)((char*)buf)[i]);
	    if((i!=0) && (i%16) == 0) printf("\n[%d] ", getpid());
	}
	printf("\n");
#endif /* SEND_DEBUG */
        if(datatype == MPI_STRING)
	    MPIpm_errhandler("MPI_Send",
		             MPI_Send(&len, 1, MPI_INT, dest, tag, comm));
	MPIpm_errhandler("MPI_Send",
	                 MPI_Send(buf, len, MPI_CHAR, dest, tag, comm));
    } else {
	count = 1;
        if (datatype == MPI_CHAR)
	    count = (SvCUR(SvRV(ref)) + 1) * sizeof(char);
	buf = (void*) malloc(MPIpm_bufsize(datatype,SvRV(ref),count));
	MPIpm_packscalar(buf,SvRV(ref),datatype);

	ret = MPI_Send(buf,count,datatype,dest,tag,comm);

	free(buf);
	MPIpm_errhandler("MPI_Send",ret);
    }


void
MPI_Recv(ref, count, datatype, source, tag, comm)
	SV *	ref
	int     count
	MPI_Datatype	datatype
	int	source
	int	tag
	MPI_Comm comm
      PREINIT:
        void* buf;
        int ret;
	MPI_Status status;
#ifdef SEND_DEBUG
        int i;
#endif
      PPCODE:
	if (! SvROK(ref)) 
            croak("MPI_Recv: First argument is not a reference!");

	if (SvTYPE(SvRV(ref)) == SVt_PVHV) {
            croak("MPI_Recv: Hashes are not supported yet.");
	} else if (SvTYPE(SvRV(ref)) == SVt_PVAV) {
	    int len;
	    AV *stuff = (AV*) SvRV(ref);
            switch(datatype) {
	      case MPI_STRING:
	        MPI_Recv(&len, 1, MPI_INT, source, tag, comm, &status);
		break;
	      case MPI_INT:
                len = count * sizeof(int);
                break;
#ifndef FLOAT_HACK
	      case MPI_FLOAT:
                len = count * sizeof(float);
                break;
#endif
	      case MPI_DOUBLE:
                len = count * sizeof(double);
                break;
            }
#ifdef SEND_DEBUG
	    printf("[%d] len=%d\n", getpid(), len);
#endif
            buf = (char *) malloc(len);
            ret = MPI_Recv(buf, len, MPI_CHAR, source, tag, comm, &status);
#ifdef SEND_DEBUG
	    printf("[%d] len=%d\n[%d] ", getpid(), len, getpid());
	    for(i=0;i<len;i++) {
		printf("%02x ", (unsigned char)((char*)buf)[i]);
		if((i!=0) && (i%16) == 0) printf("\n[%d] ", getpid());
	    }
	    printf("\n");
#endif /* SEND_DEBUG */
            MPIpm_unpackarray(buf, &stuff, datatype, count);
	    MPIpm_errhandler("MPI_Recv",ret);
	    /* return the status as a 4 element array:
	     * (count,MPI_SOURCE,MPI_TAG,MPI_ERROR) */
	    XPUSHs(sv_2mortal(newSViv(status.count)));
	    XPUSHs(sv_2mortal(newSViv(status.MPI_SOURCE)));
	    XPUSHs(sv_2mortal(newSViv(status.MPI_TAG)));
	    XPUSHs(sv_2mortal(newSViv(status.MPI_ERROR)));
	} else {
	  buf = (void*) malloc(MPIpm_bufsize(datatype,NULL,count));

	  ret = MPI_Recv(buf,count,datatype,source,tag,comm,&status);

	  MPIpm_unpackscalar(buf,SvRV(ref),datatype);
	  free(buf);
	  MPIpm_errhandler("MPI_Recv",ret);

	  /* return the status as a 4 element array:
	   * (count,MPI_SOURCE,MPI_TAG,MPI_ERROR) */
	  XPUSHs(sv_2mortal(newSViv(status.count)));
	  XPUSHs(sv_2mortal(newSViv(status.MPI_SOURCE)));
	  XPUSHs(sv_2mortal(newSViv(status.MPI_TAG)));
	  XPUSHs(sv_2mortal(newSViv(status.MPI_ERROR)));
	}


int
MPI_Barrier(comm=MPI_COMM_WORLD)
	MPI_Comm	comm
     CODE:
        MPIpm_errhandler("MPI_Barrier",MPI_Barrier(comm));


int
MPI_Bcast(ref, count, datatype, root, comm=MPI_COMM_WORLD)
	SV *    ref
	int     count
        MPI_Datatype 	datatype
	int	root
	MPI_Comm	comm
      PREINIT:
        void* buf;
        int ret;
      CODE:     
	if (! SvROK(ref)) 
            croak("MPI_Bcast: First argument is not a reference!");

	if (SvTYPE(SvRV(ref)) == SVt_PVAV) {
	    AV* array = (AV*) SvRV(ref);
            int len;
            int rank;
	    MPI_Comm_rank(comm, &rank);
	    if(rank == root)
		MPIpm_packarray(&buf, array, datatype, count);
	    else
		buf = (void*) malloc(MPIpm_bufsize(datatype,SvRV(ref),count));

	    ret = MPI_Bcast(buf,count,datatype,root,comm);
	    if(rank != root)
		MPIpm_unpackarray(buf,&array,datatype, count);
	    MPIpm_errhandler("MPI_Bcast",ret);
#if 0
	    croak("MPI_Bcast: Arrays are not implemented yet.\n");
#endif
	} else {
	    buf = (void*) malloc(MPIpm_bufsize(datatype,SvRV(ref),count));
	    MPIpm_packscalar(buf,SvRV(ref),datatype);

	    ret = MPI_Bcast(buf,count,datatype,root,comm);

	    MPIpm_unpackscalar(buf,SvRV(ref),datatype);
	    free(buf);
	    MPIpm_errhandler("MPI_Bcast",ret);
	}


double
MPI_Wtime()


double
MPI_Wtick()


int
MPI_Initialized()
      PREINIT:
        int flag;
      CODE:
        MPIpm_errhandler("MPI_Initialized",  MPI_Initialized(&flag));
	RETVAL = flag;
      OUTPUT:
        RETVAL


void
MPI_Abort(comm, errorcode)
	MPI_Comm	comm
	int	errorcode
      CODE:
	MPIpm_errhandler("MPI_Abort", MPI_Abort(comm,errorcode));


int
MPI_Reduce(sendref, recvref, count, datatype, op, root, comm)
	SV *	sendref
	SV *	recvref
	int	count
	MPI_Datatype	datatype
	MPI_Op	op
	int	root
	MPI_Comm	comm
      PREINIT:
        void* sendbuf, *recvbuf;
        int ret;
      CODE:     
	if (! SvROK(sendref) || ! SvROK(recvref))
            croak("MPI_Reduce: First two arguments must be references!");

	if (SvTYPE(SvRV(sendref)) == SVt_PVAV ||
            SvTYPE(SvRV(recvref)) == SVt_PVAV) {
	  croak("MPI_Reduce: Arrays are not yet implemented");
	} else {
	  sendbuf = (void*)malloc(MPIpm_bufsize(datatype,SvRV(sendref),count));
	  recvbuf = (void*)malloc(MPIpm_bufsize(datatype,SvRV(recvref),count));
	  MPIpm_packscalar(sendbuf,SvRV(sendref),datatype);

	  ret = MPI_Reduce(sendbuf,recvbuf,count,datatype,op,root,comm);

	  MPIpm_unpackscalar(recvbuf,SvRV(recvref),datatype);
	  free(sendbuf);
	  free(recvbuf);
	  MPIpm_errhandler("MPI_Reduce",ret);
	}


int
MPI_Allreduce(sendref, recvref, count, datatype, op, comm)
	SV *	sendref
	SV *	recvref
	int	count
	MPI_Datatype	datatype
	MPI_Op	op
	MPI_Comm	comm
      PREINIT:
        void* sendbuf, *recvbuf;
        int ret;
      CODE:     
	if (! SvROK(sendref) || ! SvROK(recvref))
            croak("MPI_Allreduce: First two arguments must be references!");

	if (SvTYPE(SvRV(sendref)) == SVt_PVAV ||
            SvTYPE(SvRV(recvref)) == SVt_PVAV) {
	  croak("MPI_Allreduce: Arrays are not yet implemented");
	} else {
	  sendbuf = (void*)malloc(MPIpm_bufsize(datatype,SvRV(sendref),count));
	  recvbuf = (void*)malloc(MPIpm_bufsize(datatype,SvRV(recvref),count));
	  MPIpm_packscalar(sendbuf,SvRV(sendref),datatype);

	  ret = MPI_Allreduce(sendbuf,recvbuf,count,datatype,op,comm);

	  MPIpm_unpackscalar(recvbuf,SvRV(recvref),datatype);
	  free(sendbuf);
	  free(recvbuf);
	  MPIpm_errhandler("MPI_Allreduce",ret);
	}


int
MPI_Scatter(sendref, sendcnt, sendtype, recvref, recvcnt, recvtype, root, comm)
	SV *    sendref
        int     sendcnt
        MPI_Datatype 	sendtype
	SV *    recvref
        int     recvcnt
        MPI_Datatype 	recvtype
	int	root
	MPI_Comm	comm
      PREINIT:
        void* sendbuf, *recvbuf;
        int ret;
      CODE:     
	if (! SvROK(sendref) || ! SvROK(recvref))
            croak("MPI_Scatter: First and Fourth arguments must be references!");

	if (SvTYPE(SvRV(sendref)) == SVt_PVAV)
        {
            int rank,len;
            MPI_Comm_rank(comm, &rank);
            if(rank == root)
		len = MPIpm_packarray(&sendbuf, (AV*)SvRV(sendref), sendtype,0);
	    recvbuf = (void*) malloc(MPIpm_bufsize(recvtype,(SV*)SvRV(sendref),recvcnt));
	    ret = MPI_Scatter(sendbuf,sendcnt,sendtype,recvbuf,recvcnt,recvtype,root,comm); 
	    if(SvTYPE(SvRV(recvref)) == SVt_PVAV) {
		AV *recv = (AV*) SvRV(recvref);
		MPIpm_unpackarray(recvbuf,&recv,recvtype,recvcnt);
            } else {
		SV *recv = (SV*) SvRV(recvref);
		MPIpm_unpackscalar(recvbuf,recv,recvtype);
            }
	    MPIpm_errhandler("MPI_Scatter",ret);
	} else {
	  sendbuf = (void*)calloc(MPIpm_bufsize(sendtype,SvRV(sendref),sendcnt)+1,1);
	  recvbuf = (void*)calloc(MPIpm_bufsize(recvtype,SvRV(recvref),recvcnt)+1,1);
	  MPIpm_packscalar(sendbuf,SvRV(sendref),sendtype);

	  ret = MPI_Scatter(sendbuf,sendcnt,sendtype,recvbuf,recvcnt,recvtype,root,comm); 
	  MPIpm_unpackscalar(recvbuf,SvRV(recvref),recvtype);
#ifdef WHY_DOES_THIS_MAKE_IT_SEGFAULT
	  free(sendbuf);
	  free(recvbuf);
#endif
	  MPIpm_errhandler("MPI_Scatter",ret);
	}


int
MPI_Gather(sendref, sendcnt, sendtype, recvref, recvcnt, recvtype, root, comm)
	SV *    sendref
        int     sendcnt
        MPI_Datatype 	sendtype
	SV *    recvref
        int     recvcnt
        MPI_Datatype 	recvtype
	int	root
	MPI_Comm	comm
      PREINIT:
        void* sendbuf, *recvbuf;
        int ret;
      CODE:     
	if (! SvROK(sendref) || ! SvROK(recvref))
            croak("MPI_Gather: First and Fourth arguments must be references!");

	if (SvTYPE(SvRV(sendref)) == SVt_PVAV ||
            SvTYPE(SvRV(recvref)) == SVt_PVAV)
	{
	    croak("MPI_Gather: Arrays are not implemented yet.");
	} else {
	  sendbuf = (void*)malloc(MPIpm_bufsize(sendtype,SvRV(sendref),sendcnt));
	  recvbuf = (void*)malloc(MPIpm_bufsize(recvtype,SvRV(recvref),recvcnt));
	  MPIpm_packscalar(sendbuf,SvRV(sendref),sendtype);

	  ret = MPI_Gather(sendbuf,sendcnt,sendtype,recvbuf,recvcnt,recvtype,root,comm);

	  MPIpm_unpackscalar(recvbuf,SvRV(recvref),recvtype);
	  free(sendbuf);
	  free(recvbuf);
	  MPIpm_errhandler("MPI_Gather",ret);
	}

int
MPI_Sendrecv(sendref, sendcount, sendtype, dest, sendtag, recvref, recvcount, recvtype, source, recvtag, comm)
	SV *	sendref
	int	sendcount
	MPI_Datatype	sendtype
	int	dest
	int	sendtag
	SV *	recvref
	int	recvcount
	MPI_Datatype	recvtype
	int	source
	int	recvtag
	MPI_Comm	comm
      PREINIT:
        void* sendbuf, *recvbuf;
        int ret;
	MPI_Status status;
      PPCODE:     
	if (! SvROK(sendref) || ! SvROK(recvref))
            croak("MPI_Sendrecv: First and Fourth arguments must be references!");

	if (SvTYPE(SvRV(sendref)) == SVt_PVAV &&
            SvTYPE(SvRV(recvref)) == SVt_PVAV)
	{
            AV* array = (AV*) SvRV(recvref);
	    int len;
	    recvbuf = malloc(MPIpm_bufsize(recvtype, SvRV(recvref), recvcount));
	    len = MPIpm_packarray(&sendbuf, (AV*)SvRV(sendref), sendtype, sendcount);
	    ret = MPI_Sendrecv(sendbuf, sendcount, sendtype, dest, sendtag,
                               recvbuf, recvcount, recvtype, source, recvtag,
                               comm, &status);

	    MPIpm_unpackarray(recvbuf,&array,recvtype,recvcount);
	    MPIpm_errhandler("MPI_Sendrecv",ret);
	} else {
	  sendbuf = (void*)malloc(MPIpm_bufsize(sendtype,SvRV(sendref),sendcount));
	  recvbuf = (void*)malloc(MPIpm_bufsize(recvtype,SvRV(recvref),recvcount));
	  MPIpm_packscalar(sendbuf,SvRV(sendref),sendtype);
          MPIpm_packscalar(recvbuf,SvRV(recvref),recvtype);
	  
	  ret = MPI_Sendrecv(sendbuf, sendcount, sendtype, dest,
                             sendtag, recvbuf, recvcount, recvtype,
			     source, recvtag, comm, &status);

	  MPIpm_unpackscalar(recvbuf,SvRV(recvref),recvtype);
	  free(sendbuf);
	  free(recvbuf);
	  MPIpm_errhandler("MPI_Sendrecv",ret);
	}

	/* return the status as a 4 element array:
	 * (count,MPI_SOURCE,MPI_TAG,MPI_ERROR) */
	XPUSHs(sv_2mortal(newSViv(status.count)));
	XPUSHs(sv_2mortal(newSViv(status.MPI_SOURCE)));
	XPUSHs(sv_2mortal(newSViv(status.MPI_TAG)));
	XPUSHs(sv_2mortal(newSViv(status.MPI_ERROR)));
