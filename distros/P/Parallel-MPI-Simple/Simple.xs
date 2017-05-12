#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/* The Inline::C source for this is available in the __DATA__ section
   of Simple.pm */

#include <mpi.h> 
#define GATHER_TAG 11001 /* used to be unlikely to upset other sends */

/*
  root process first broadcasts length of stored data then broadcasts
  the data.  Non-root processes receive length (via bcast), allocate
  space to take incomming data from root

  Both root and non-root processes then create and return a new scalar
  with contents identical to those root started with.
*/

SV* _Bcast (SV* data, int root, SV* comm) {
  int buf_len[1];
  int rank;
  SV* rval;
  MPI_Comm_rank((MPI_Comm)SvIVX(comm), &rank);
  if (rank == root) {
    buf_len[0] = sv_len(data);
    MPI_Bcast(buf_len, 1, MPI_INT, root, (MPI_Comm)SvIVX(comm));
    MPI_Bcast(SvPVX(data), buf_len[0], MPI_CHAR, root, (MPI_Comm)SvIVX(comm));
    rval = newSVpvn(SvPVX(data), buf_len[0]);
  }
  else {
    char *recv_buf;
    MPI_Bcast(buf_len, 1, MPI_INT, root, (MPI_Comm)SvIVX(comm));
    recv_buf = (char*)malloc((buf_len[0]+1)*sizeof(char));
    if (recv_buf == NULL) croak("Allocation error in _Bcast");
    MPI_Bcast(recv_buf, buf_len[0], MPI_CHAR, root, (MPI_Comm)SvIVX(comm));
    rval = newSVpvn(recv_buf, buf_len[0]);
    free(recv_buf);
  }
  return rval;
}

/*
  Finds length of data in stor_ref, sends this to receiver, then
  sends actual data, uses same tag for each message.
*/

int _Send(SV* stor_ref, int dest, int tag, SV*comm) {
  int str_len[1];
  str_len[0] = sv_len(stor_ref);
  MPI_Send(str_len, 1, MPI_INT, dest, tag, (MPI_Comm)SvIVX(comm));
  MPI_Send(SvPVX(stor_ref), sv_len(stor_ref),MPI_CHAR,
	   dest, tag, (MPI_Comm)SvIVX(comm));
  return 0;
}

/*
  Receives int for length of data it should then expect, allocates space
  then receives data into that space.  Creates a new SV and returns it.
*/

SV* _Recv (int source, int tag, SV*comm, SV*status) {
  MPI_Status tstatus;
  SV* rval;
  int len_buf[1];
  char *recv_buf;

  MPI_Recv(len_buf, 1, MPI_INT, source, tag, (MPI_Comm)SvIVX(comm), &tstatus);
  recv_buf = (char*)malloc((len_buf[0]+1)*sizeof(char));
  if (recv_buf == NULL) croak("Allocation error in _Recv");
  MPI_Recv(recv_buf, len_buf[0], MPI_CHAR, source, tag,
	    (MPI_Comm)SvIVX(comm), &tstatus);
  rval = newSVpvn(recv_buf, len_buf[0]);
  sv_setiv(status, tstatus.MPI_SOURCE);
  free(recv_buf);
  return rval;
}

/* Calls MPI_Init with dummy arguments, a bit dodgy but sort of ok */
int Init () {
  MPI_Init(&PL_origargc, &PL_origargv);
}

/* Returns rank of process within comm */
int _Comm_rank (SV* comm) {
  int trank;
  MPI_Comm_rank((MPI_Comm)SvIVX(comm),&trank);
  return trank;
}

/* returns total number of processes within comm */
int _Comm_size (SV* comm) {
  int tsize;
  MPI_Comm_size((MPI_Comm)SvIVX(comm), &tsize);
  return tsize;
}

/* returns SV whose IV slot is a cast pointer to the MPI_COMM_WORLD object */
SV* COMM_WORLD () {
  return newSViv((IV)MPI_COMM_WORLD);
}

/* returns SV whose IV slot is a cast pointer to the MPI_ANY_SOURCE value */
SV* ANY_SOURCE () {
  return newSViv((IV)MPI_ANY_SOURCE);
}

/* calls MPI_Barrier for comm */
int Barrier (SV*comm) {
  MPI_Barrier((MPI_Comm)SvIVX(comm));
}

/* ends MPI participation */
int Finalize () {
  MPI_Finalize();
}

/*
  If non-root:  participates in Gather so that root finds length of data
                to expect from this process.  Then send (using MPI_Send)
                data to root.

  If root: receives array of ints detailing length of scalars held by
   other processes, then receives from each in turn (using MPI_Recv)
   returns an array ref to root process only.
  
 */
SV* _Gather (SV* data, int root, SV* comm) {
  int rank, size, *buf_lens, i, max;
  char* recv_buf;
  int my_buf[1];
  AV* ret_arr;
  MPI_Status tstatus;

  /* find out how long data is */
  ret_arr = av_make(0,(SV**)NULL);
  my_buf[0] = sv_len(data);
  if (_Comm_rank(comm) == root) {
    MPI_Comm_size((MPI_Comm)SvIVX(comm), &size);
    buf_lens = malloc(size*sizeof(int));
    if (buf_lens == NULL) croak("Allocation error (lens) in _Gather");
    /* gather all scalar length data */
    MPI_Gather(my_buf, 1, MPI_INT, buf_lens, 1,
	       MPI_INT, root, (MPI_Comm)SvIVX(comm));
    max = 0; // keep buffer allocation calls to minimum
    for (i=0;i<size;i++) {
      max = max < buf_lens[i] ? buf_lens[i] : max;
    }
    recv_buf = malloc(max * sizeof(char));
    if (recv_buf == NULL) croak("Allocation error (recv) in _Gather");
    for (i=0;i<size;i++) {
      if (i == root) {
	av_push(ret_arr, data);
	continue; /* me, no point sending */
      }
      MPI_Recv(recv_buf, buf_lens[i], MPI_CHAR, i, GATHER_TAG,
	       (MPI_Comm)SvIVX(comm), &tstatus );
      av_push(ret_arr, sv_2mortal( newSVpvn(recv_buf, buf_lens[i]) ) );
    }
    free(recv_buf);
    free(buf_lens);
  }
  else {
    /* send out how long my scalar data is */ 
      MPI_Gather(my_buf, 1, MPI_INT, buf_lens, 1,
	       MPI_INT, root, (MPI_Comm)SvIVX(comm) );
    /* send out my scalar data as normal send with tag of ???? */
      MPI_Send(SvPVX(data), my_buf[0], MPI_CHAR,
	       root, GATHER_TAG,(MPI_Comm)SvIVX(comm));
  }

  return newRV_inc((SV*)ret_arr);
}

/* compares two communicators, translates MPI constants into something I
   can use as constants in the module interface */
int _Comm_compare(SV* comm1, SV* comm2) {
    int result = 0;
    MPI_Comm_compare((MPI_Comm)SvIVX(comm1), (MPI_Comm)SvIVX(comm2), &result);
    switch (result) {
	case MPI_IDENT:
	               return(1);
	case MPI_CONGRUENT:
	               return(2);
	case MPI_SIMILAR:
	               return(3);
	case MPI_UNEQUAL:
	               return(0);
        default:
	               return(0);
    }
}

/* frees a communicator, once all pending communication has taken place */
void _Comm_free (SV* comm) {
    MPI_Comm_free((MPI_Comm*)&SvIVX(comm));
    if ((MPI_Comm)SvIVX(comm) != MPI_COMM_NULL)
	croak("Communicator not freed properly\n");
}

SV* _Comm_dup (SV*comm) {
    MPI_Comm newcomm;
    MPI_Comm_dup((MPI_Comm)SvIVX(comm), &newcomm);
    return newSViv((IV)newcomm);
}

SV* _Comm_split (SV* comm, int colour, int key) {
    MPI_Comm newcomm;
    int realcolour;
    MPI_Comm_split((MPI_Comm)SvIVX(comm),
		    (colour < 0 ? MPI_UNDEFINED : colour),
		    key, &newcomm);
    return newSViv((IV)newcomm);
}




MODULE = Parallel::MPI::Simple	PACKAGE = Parallel::MPI::Simple	

PROTOTYPES: DISABLE

SV *
_Bcast (data, root, comm)
	SV *	data
	int	root
	SV *	comm

int
_Send (stor_ref, dest, tag, comm)
	SV *	stor_ref
	int	dest
	int	tag
	SV *	comm

SV *
_Recv (source, tag, comm, status)
	int	source
	int	tag
	SV *	comm
	SV *	status

int
Init ()

int
_Comm_rank (comm)
	SV *	comm

int
_Comm_size (comm)
	SV *	comm

SV *
COMM_WORLD ()

SV *
ANY_SOURCE ()

int
Barrier (comm)
	SV *	comm

int
Finalize ()

SV *
_Gather (data, root, comm)
	SV *	data
	int	root
	SV *	comm

int
_Comm_compare (comm1, comm2)
	SV *	comm1
	SV *	comm2

void
_Comm_free (comm)
	SV *	comm
	PREINIT:
	I32* temp;
	PPCODE:
	temp = PL_markstack_ptr++;
	_Comm_free(comm);
	if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
	  PL_markstack_ptr = temp;
	  XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
	return; /* assume stack size is correct */

SV *
_Comm_dup (comm)
	SV *	comm

SV *
_Comm_split (comm, colour, key)
	SV *	comm
	int	colour
	int	key

