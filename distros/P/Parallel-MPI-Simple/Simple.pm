package Parallel::MPI::Simple;

use strict;
require DynaLoader;
use vars qw(@ISA $VERSION);
use Storable qw(nfreeze thaw);

@ISA = qw(DynaLoader);
$VERSION = '0.10';

bootstrap Parallel::MPI::Simple;

# evil, but makes everything MPI_*, which is sort of expected
sub import {
    my $call = (caller())[0];
    no strict 'refs';
    # subs (MPI_ function calls)
    foreach (qw(Init Finalize COMM_WORLD ANY_SOURCE Comm_rank Comm_size
		Recv Send Barrier Bcast Gather
		Scatter Allgather Alltoall Reduce
		Comm_compare Comm_dup Comm_free Comm_split
	       )) {
	*{$call.'::MPI_'.$_} = \&$_;
    }
    # flags (variables)
    *{$call.'::MPI_'.$_} = \&$_
	foreach (qw(IDENT CONGRUENT SIMILAR UNEQUAL UNDEFINED));
}

=head1 NAME

 Parallel::MPI::Simple

=head1 SYNOPSIS

 mpirun -np 2 perl script.pl

 #!perl
 use Parallel::MPI::Simple;
 MPI_Init();
 my $rank = MPI_Comm_rank(MPI_COMM_WORLD);
 if ($rank == 1) {
   my $msg = "Hello, I'm $rank";
   MPI_Send($msg, 0, 123, MPI_COMM_WORLD);
 }
 else {
   my $msg = MPI_Recv(1, 123, MPI_COMM_WORLD);
   print "$rank received: '$msg'\n";
 }
 MPI_Finalise();

=head1 COMPILING AND RUNNING

Please view the README file in the module tarball if you are having
trouble compiling or running this module.

=head1 INTRODUCTION

Perl is not a strongly typed language, Perl does not enforce data
structures of a fixed size or dimensionality, Perl makes things easy.
Parallel processing solves problems faster and is commonly programmed
using a message passing paradigm.  Traditional message passing systems
are designed for strongly typed languages like C or Fortran, there
exist implementations of these for Perl but they concentrate on
perfectly mimicing the standards forcing the poor Perl programmer to
use strongly typed data despite all his best instincts.

This module provides a non-compliant wrapper around the widely
implemented MPI libraries, allowing messages to consist of arbitarily
nested Perl data structures whose size is limited by available memory.
This hybrid approach should allow you to quickly write programs which
run anywhere which supports MPI (both Beowulf and traditional MPP
machines).

=head1 Message Passing and Multiprocessing

The message passing paradigm is simple and easy to use.  Multiple
versions of the same program are run on multiple processors (or
nodes).  Each running copy should call C<MPI_Init> to announce that it
is running.  It can then find out who it is by calling
C<MPI_Comm_rank> and who else it can talk to by calling
C<MPI_Comm_size>.  Using this information to decide what part it is to
play in the ensuing computation, it the  exchanges messages, or
parcels of data, with other nodes allowing all to cooperate.

Once the computation is finished, the node calls C<MPI_Finalize> and
exits cleanly, ready to run another day.

These processes are all copies of the I<same> perl script and are invoked
using: C<mpirun -np [number of nodes] perl script.pl> .

Remember you may need to start a daemon before mpirun will work, for
C<mpich> this is often as easy as running: C<mpd &>.

=head1 Starting and Stopping a process

A process must formally enter and leave the MPI pool by calling these
functions.

=head2 MPI_Init

  MPI_Init()

Initialises the message passing layer.  This should be the first C<MPI_*>
call made by the program and ideally one of the first things the
program does.  After completing this call, all processes will be
synchronised and will become members of the C<MPI_COMM_WORLD>
communicator.  It is an error for programs invoked with C<mpirun> to
fail to call C<MPI_Init> (not to mention being a little silly).

=head2 MPI_Finalize

  MPI_Finalize()

Shuts down the message passing layer.  This should be called by every
participating process before exiting.  No more C<MPI_*> calls may be made
after this function has been called.  It is an error for a program to
exit I<without> calling this function.

=head1 Communicators

All processes are members of one or more I<communicators>.  These are
like channels over which messages are broadcast.  Any operation
involving more than one process will take place in a communicator,
operations involving one communicator will not interfere with those in
another.

On calling C<MPI_Init> all nodes automatically join the
C<MPI_COMM_WORLD> communicator.  A communicator can be split into
smaller subgroups using the C<MPI_Comm_split> function.

=head2 MPI_COMM_WORLD

 $global_comm = MPI_COMM_WORLD;

Returns the global communicator shared by all processes launched at
the same time.  Can be used as a "constant" where a communicator is
required.  Most MPI applications can get by using only this
communicator.

=head2 MPI_Comm_rank

  $rank = MPI_Comm_rank($comm);

Returns the rank of the process within the communicator given by
$comm.  Processes have ranks from 0..(size-1).

=cut

sub Comm_rank {
  _Comm_rank($_[0]);
}


=head2 MPI_Comm_size

  $size = MPI_Comm_size($comm);

Returns the number of processes in communicator $comm.

=cut

sub Comm_size {
  _Comm_size($_[0]);
}

=head2 MPI_Comm_compare

    $result = MPI_Comm_compare($comm1, $comm2);

Compares the two communicators $comm1 and $comm2.  $result will be equal
to:

  MPI_IDENT    : communicators are identical
  MPI_CONGRUENT: membership is same, ranks are equal
  MPI_SIMILAR  : membership is same, ranks not equal
  MPI_UNEQUAL  : at least one member of one is not in the other

=cut

sub IDENT     () { 1 }
sub CONGRUENT () { 2 }
sub SIMILAR   () { 3 }
sub UNEQUAL   () { 0 }

sub Comm_compare {
    my ($c1, $c2) = (@_);
    _Comm_compare($c1, $c2);
}

=head2 MPI_Comm_dup

    $newcomm = MPI_Comm_dup($comm);

Duplicates $comm but creates a new context for messages.

=cut

sub Comm_dup {
    my ($comm) = @_;
    _Comm_dup($comm);
}

=head2 MPI_Comm_split

    $newcomm = MPI_Comm_split($comm, $colour, $key);

Every process in $comm calls C<MPI_Comm_split> at the same time.  A
new set of communicators is produced, one for each distinct value of
$colour.  All those processes which specified the same value of
$colour end up in the same comminicator and are ranked on the values
of $key, with their original ranks in $comm being used to settle ties.

If $colour is negative (or C<MPI_UNDEFINED>), the process will not be
allocated to any of the new communicators and C<undef> will be
returned.

=cut

sub UNDEFINED () { -1 }
sub Comm_split {
    my ($comm, $colour, $key) = @_;
    my $rt = _Comm_split($comm, $colour, $key);
    if ($colour < 0) {
	return undef;
    }
    else {
	return $rt;
    }
}

=head2 MPI_Comm_free

    MPI_Comm_free($comm, [$comm2, ...] );

Frees the underlying object in communicator $comm, do not attempt to
do this to MPI_COMM_WORLD, wise to do this for any other comminicators
that you have created.  If given a list of comminicators, will free
all of them, make sure there are no duplicates...

=cut

sub Comm_free {
    _Comm_free($_) foreach @_;
}

=head1 Communications operations

=head2 MPI_Barrier

  MPI_Barrier($comm);

Waits for every process in $comm to call MPI_Barrier, once done, all
continue to execute.  This causes synchronisation of processes.  Be
sure that every process does call this, else your computation will
hang.

=head2 MPI_Send

  MPI_Send($scalar, $dest, $msg_tag, $comm);

This takes a scalar (which can be an anonymous reference to a more
complicated data structure) and sends it to process with rank $dest in
communicator $comm.  The message also carries $msg_tag as an
identfier, allowing nodes to receive and send out of order.
Completion of this call does not imply anything about the progress of
the receiving node.

=cut

sub Send {
  # my ($ref,$dest,$tag,$comm) = @_;
  my $stor = nfreeze(\$_[0]);
  _Send($stor, $_[1], $_[2], $_[3]);
}

=head2 MPI_Recv

 $scalar = MPI_Recv($source, $msg_tag, $comm);

Receives a scalar from another process.  $source and $msg_tag must both
match a message sent via MPI_Send (or one which will be sent in future)
to the same communicator given by $comm.

 if ($rank == 0) {
   MPI_Send([qw(This is a message)], 1, 0, MPI_COMM_WORLD); 
 }
 elsif ($rank == 1) {
   my $msg = MPI_Recv(1,0,MPI_COMM_WORLD);
   print join(' ', @{ $msg } );
 }

Will output "This is a message".  Messages with the same source,
destination, tag and comminicator will be delivered in the order in
which they were sent.  No other guarantees of timeliness or ordering
can be given.  If needed, use C<MPI_Barrier>.

C<$source> can be C<MPI_ANY_SOURCE> which will do what it says.

=cut

sub Recv {
  my $out;
  my ($source, $tag, $comm, $status) = @_;
  $out = _Recv($source, $tag, $comm, $status);
  return ${thaw($out)};
}

=head2 MPI_Bcast

 $data = MPI_Bcast($scalar, $root, $comm);

This sends $scalar in process $root from the root process to every
other process in $comm, returning this scalar in every process.  All
non-root processes should provide a dummy message (such as C<undef>),
this is a bit ugly, but maintains a consistant interface between the
other communication operations.  The scalar can be a complicated data
structure.

  if ($rank == 0) { # send from 0
    my $msg = [1,2,3, {3=>1, 5=>6}  ];
    MPI_Bcast( $msg, 0, MPI_COMM_WORLD);
  }
  else { # everything else receives, note dummy message
    my $msg = MPI_Bcast(undef, 0, MPI_COMM_WORLD);
  }

=cut

sub Bcast {
  my $out;
  # my ($data, $from, $comm) = @_;
  my $data = nfreeze(\$_[0]);
  $out = _Bcast($data, $_[1], $_[2]);
  return ${thaw($out)};
}

=head2 MPI_Gather

 # if root:
 @list = MPI_Gather($scalar, $root, $comm);
 #otherwise
 (nothing) = MPI_Gather($scalar, $root, $comm);

Sends $scalar from every process in $comm (each $scalar can be
different, root's data is also sent) to the root process which
collects them as a list of scalars, sorted by process rank order in
$comm.

=cut
#'
sub Gather {
  # my ($ref, $root, $comm) = @_;
  my @rt;
  my $data = nfreeze(\$_[0]);
  foreach (@{ _Gather($data, $_[1], $_[2]) }) {
     push @rt, ${thaw($_)};
  }
  return @rt;
}

=head2 MPI_Scatter

 $data = MPI_Scatter([N items of data], $root, $comm);

Sends list of scalars (anon array as 1st arg) from $root to all
processes in $comm, with process of rank N-1 receiving the Nth item in
the array.  Very bad things might happen if number of elements in
array != N.  This does not call the C function at any time, so do not
expect any implicit synchronisation.

=cut

sub Scatter {
  my ($aref, $root, $comm) = @_;
  if (Comm_rank($comm) == $root) {
    for my $i (0..@$aref-1) {
      next if $i == $root;
      Send($aref->[$i], $i, 11002, $comm);
    }
    $aref->[$root];
  }
  else {
    Recv($root, 11002, $comm);
  }
}

=head2 MPI_Allgather

 @list = MPI_Allgather($scalar, $comm);

Every process receives an ordered list containing an element from every
other process.  Again, this is implemented without a call to the C function.

=cut

sub Allgather {
  # my ($data, $comm) = @_;
  my @rt;
  my $frozen = nfreeze(\$_[0]);
  for my $i (0..Comm_size($_[1])-1) {
    push @rt, ${ thaw(_Bcast($frozen, $i, $_[1])) };
  }
  return @rt;
}

=head2 MPI_Alltoall

 @list = MPI_Alltoall([ list of scalars ], $comm);

Simillar to Allgather, each process (with rank I<rank>) ends up with a
list such that element I<i> contains the data which started in element
I<rank> of process I<i>s data.

=cut

sub Alltoall {
  my ($data, $comm) = @_;
  my ($rank, $size) = (Comm_rank($comm), Comm_size($comm));

  my @rt;
  foreach (0..$size-1) {
    next if $_ eq $rank;
    Send($data->[$_], $_, 1, $comm);
  }
  foreach (0..$size-1) {
    if ($_ eq $rank) {
      push @rt, $data->[$_]; next;
    }
    push @rt, Recv($_, 1, $comm);
  }
  return @rt;
}

=head2 MPI_Reduce

 $value = MPI_Reduce($input, \&operation, $comm);

Every process receives in $value the result of performing &operation
between every processes $input.  If there are three processes in
$comm, then C<$value = $input_0 op $input_1 op $input_2>.

Operation should be a sub which takes two scalar values (the $input
above) and returns a single value.  The operation it performs should
be commutative and associative, otherwise the result will be undefined.

For instance, to return the sum of some number held by each process, perform:

 $sum = MPI_Reduce($number, sub {$_[0] + $_[1]}, $comm);

To find which process holds the greatest value of some number:

 ($max, $mrank) = @{ MPI_Reduce([$number, $rank],
		       sub { $_[0]->[0] > $_[1]->[0] ? $_[0] : $_[1]}
			 , $comm) };

=cut

# This version is deprecated, but may be faster
sub Reduce2 {
  my ($ref, $code, $comm) = @_;
  my ($rank, $size) = (Comm_rank($comm), Comm_size($comm));
  my $rt;
  Barrier($comm); # safety first
  if ($rank != 0) {
    Send($ref, 0, 1, $comm);
    $rt = Recv(0,1,$comm);
  }
  else {
    $rt = $ref;
    for (1..$size-1) {
      $rt = &$code($rt, Recv($_,1,$comm));
    }
    for (1..$size-1) {
      Send($rt, $_,1,$comm);
    }
  }
  return $rt;
}

# This should be O(log(P)) in calc and comm
# This version first causes odds to send to evens which reduce, then etc.
sub Reduce {
  my ($val, $code, $comm) = @_;
  my ($rank, $size) = (Comm_rank($comm), Comm_size($comm));
  my $rt = $val;
  my @nodes = (0..$size-1);
  while (@nodes>1) {
    $#nodes += @nodes % 2;
    my %from = @nodes;
    my %to = reverse %from;
    if ($from{$rank}) { # I'm receiving something
      $rt = &$code($rt, Recv($from{$rank}, 1, $comm));
    }
    elsif (defined($to{$rank})) {# I'm sending something
      Send($rt, $to{$rank}, 1, $comm);
    }
    @nodes = sort {$a <=> $b} keys %from;
  }
  # node 0 only to distribute via Broadcast
  Bcast($rt, 0, $comm);
}

1; # I am the ANTI-POD!

=head1 PHILOSOPHY

I have decided to loosely follow the MPI calling and naming
conventions but do not want to stick strictly to them in all cases.
In the interests of being simple, I have decided that all errors
should result in the death of the MPI process rather than huge amounts
of error checking being foisted onto the module's user.

Many of the MPI functions have not been implemented, some of this is
because I feel they would complicate the module (I chose to have a
single version of the Send command, for instance) but some of this is
due to my not having finished yet.  I certainly do not expect to
provide process topologies or inter-communicators, I also do not
expect to provide anything in MPI-2 for some time.

=head1 ISSUES

This module has been tested on a variety of platforms.  I have not
been able to get it running with the mpich MPI implementation in
a clustered environment.

In general, I expect that most programs using this module will make
use of little other than C<MPI_Init>, C<MPI_Send>, C<MPI_Recv>,
C<MPI_COMM_WORLD>, C<MPI_Barrier>, C<MPI_Comm_size>, C<MPI_Comm_rank>
and C<MPI_Finalize>.

Please send bugs to github: L<https://github.com/quidity/p5-parallel-mpi-simple/issues>

=head1 AUTHOR

  Alex Gough (alex@earth.li)

=head1 COPYRIGHT

  This module is copyright (c) Alex Gough, 2001,2011.

  You may use and redistribute this software under the Artistic License as
  supplied with Perl.

=cut

__DATA__
__C__
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
  MPI_Init((int) NULL, (char ***)NULL);
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

__END__


