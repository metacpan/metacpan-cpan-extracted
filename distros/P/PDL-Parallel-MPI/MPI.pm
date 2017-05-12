package PDL::Parallel::MPI;

=head1 NAME

PDL::Parallel::MPI 

Routines to allow PDL objects to be moved around on
parallel systems using the MPI library.

=head1 SYNOPSIS

	use PDL;
	use PDL::Parallel::MPI;
	mpirun(2);

	MPI_Init();
	$rank = get_rank();
	$a=$rank * ones(2);
	print "my rank is $rank and \$a is $a\n";
	$a->move( 1 => 0);
	print "my rank is $rank and \$a is $a\n";
	MPI_Finalize();

=head1 MPI STANDARD CALLS

Most of the functions from the MPI standard may be used
from this module on regular perl data.  
This is functionallity inherited from the Parallel::MPI module.
Read the documentation for Parallel::MPI to see how to use.

One may mix mpi calls on perl built-in-datatypes
and mpi calls on piddles.

	use PDL;
	use PDL::Parallel::MPI;
	mpirun(2);

	MPI_Init();
	$rank = get_rank();
	$pi = 3.1;
	if ($rank == 0) {
		MPI_Send(\$pi,1,MPI_DOUBLE,1,0,MPI_COMM_WORLD);
	} else {
		$message = zeroes(1);
		$message->receive(0);
		print "pi is $message\n";
	}
	MPI_Finalize();


=head1 MPI GENERIC CALLS

=head2 MPI_Init

Call this before you pass around any piddles or make any mpi calls.

	# usage:
	MPI_Init();

=head2 MPI_Finalize

Call this before your mpi program exits or you may get zombies.

	# usage:
	MPI_Finalize();

=head2 get_rank

=for ref

Returns an integer specifying who this process is.
Starts at 0.  Optional communicator argument.

=for usage

	# usage
	get_rank($comm);  # comm is optional and defaults to MPI_COMM_WORLD


=head2 comm_size

=for ref

Returns an integer specifying how many processes there are.
Optional communicator argument.

=for usage

	# usage
	comm_size($comm);  # comm is optional and defaults to MPI_COMM_WORLD


=cut

require AutoLoader;
require Exporter;
require DynaLoader;
@ISA = qw(Exporter DynaLoader);
use strict;
use Carp;
use vars qw($VERSION @ISA %EXPORT_TAGS @EXPORT_OK $AUTOLOAD 
	    $errno $errstr $exceptions @EXPORT);
	

=head2 mpirun

=for ref

Typically one would invoke a mpi program using mpirun, 
which comes with your mpi compiler.  
This function simply a dirty hack which makes
a script to invoke itself using that program.

=for usage

	mpirun($number_of_processes);

=cut

sub mpirun {
	my $nprocs = shift;
	if (not @ARGV) {
		my $ret = system("mpirun -np $nprocs $0");
		print STDERR "mpirun error\n" if $ret;
		exit;
	}
}

$VERSION = 0.02;
bootstrap PDL::Parallel::MPI;

$exceptions = 1;

# these will be set (regardless of the above setting) if an error occurs in
# an MPI function.
$errno = 0;
$errstr = undef;

=head1 PDL SPECIFIC MPI CALLS

=head2 move

=for ref

C<move> is a piddle method.  It copies a piddle from one processes onto 
another processes.  The first arguement is the rank of the source
processes, and the second argument is the rank of the receiving processes.
The piddle should be the allocated to be same size and datatype on both machines 
(this is not checked).  The method does nothing if executed on a process which
is neither the source or the destination.  => may be used in place of "," for readability.

=for usage

	# usage
	$piddle->move($source_processor , $dest_processor);

=for example

	# example
	$a = $rank * ones(4);
	$a->move( 0 => 1);

=cut

sub PDL::move 
{
	# $piddle->move( 0 => 1 );
	@_ == 3 or die "must call move method with two arguments\n";
	my ($piddle,$source,$dest) = @_;
	return if $source == $dest;
	my $rank = get_rank();
	#use tag 42
	xs_send($$piddle,$dest,42) 	if $rank == $source;
	xs_receive($$piddle,$source,42) 	if $rank == $dest;
}

=head2 send / receive

=for ref

You can use send and receive to move piddles around by yourself, although
I really recommend using C<move> instead.

=for usage

	$piddle->send($dest,$tag,$comm);   # $tag and $comm are optional
	$piddle->receive($source,$tag,$comm);  # dido

=cut

sub PDL::send
{
	my ($piddle,$dest) = @_;
	my $tag = $_[2] || 0;
	xs_send($$piddle,$dest,$tag,$_[3]) if $_[3];
	xs_send($$piddle,$dest,$tag)  if not  $_[3];
}

sub PDL::receive
{
	my ($piddle,$source) = @_;
	my $tag = $_[2] || 0;
	xs_receive($$piddle,$source,$tag,$_[3]) if $_[3];
	xs_receive($$piddle,$source,$tag)  if not  $_[3];
}


=head2 broadcast

=for ref

Piddle method which copies the value at the root process to all of the
other processes in the communicator.  The root defaults to 0 if not 
specified and the communicator to MPI_COMM_WORLD.  Piddles should
be pre-allocated to be the same size and datatype on all processes.

=for usage

	# usage
	$piddle->broadcast($root,$comm);  # $root and $comm optional

=for example
	
	# example
	$a=$rank * ones(4);
	$a->broadcast(3);

=cut

sub PDL::broadcast
{
	my $piddle=shift;
	xs_broadcast($$piddle,@_);
}

=head2 send_nonblocking / receive_nonblocking

=for ref

These piddle methods initiate communication and return before that
communication is completed.  They return a request object which can
be checked for completion or waited on.  Data at source and dest 
should be pre-allocated to have the same size and datatype.

=for usage

	# $tag and $comm are optional arguments.
	$request = $piddle->send_nonblocking($dest_proc,$tag,$comm);
	$request = $piddle->receive_nonblocking($dest_proc,$tag,$comm);
	...
	$request->wait();  # blocks until the communication is completed.
		or
	$request->test();  # returns true if the communication is completed.
	# $request is deallocated after a wait or test returns true.

=for example

	# this example is similar to how mpi_rotate is implemented.
	$r_send 	= $source->send_nonblocking(($rank+1) 	% $population);
	$r_receive  = $dest->receive_nonblocking(($rank-1)  % $population);
	$r_receive->wait();  
	$r_send->wait();

=cut
sub PDL::send_nonblocking
{
	my $piddle=shift;
	my $request = xs_send_nonblocking($$piddle,@_);
	return bless \$request, "PDL::Parallel::MPI::request";
}

sub PDL::receive_nonblocking
{
	my $piddle=shift;
	my $request = xs_receive_nonblocking($$piddle,@_);
	return bless \$request, "PDL::Parallel::MPI::request";
}

sub PDL::Parallel::MPI::request::wait
{
	my $self=shift;
	PDL::Parallel::MPI::request_wait($$self);
}

sub PDL::Parallel::MPI::request::test
{
	my $self=shift;
	return PDL::Parallel::MPI::request_test($$self);
}

=head2 get_status / print_status

=for ref

get_status returns a hashref which contains the status of the last
receive.  The fields are C<count>, C<source>, C<tag>, and C<error>.  
print_status simply prints out the status nicely.  Note that if there
is an error in a receive and exception will be thrown.

=for usage

	print_status();
	print ${get_status()}{count};

=cut

sub print_status {
	my @list = get_status_list();
	print "\tcount => $list[0]
	source => $list[1]
	tag => $list[2]
	error => $list[3]\n";
}

sub get_status {
	my @list = get_status_list();
	return {
		count => $list[0],
		source => $list[1],
		tag => $list[2],
		error => $list[3],
	}
}

=head2 mpi_rotate 

=for ref

C<mpi_rotate> is a piddle method which should be executed at the same time
on all processors.  For each process, it moves the entire piddle to the next 
process.  This movement is (inefficently) done in place by default, or you can
specify a destination.

=for usage

	$piddle->mpi_rotate(
		dest => $dest_piddle,	# optional
		offset => $offset,	# optional, defaults to +1
	);

=for example

=cut

sub PDL::mpi_rotate # the method 'rotate' was taken
{
	my ($piddle,$source,$dest,$rank,$population,$r_send,$r_receive,%args,$offset);

	$piddle=shift;
	%args = @_;
	$offset = $args{'offset'} || 1;

	if (ref $args{'dest'} eq 'PDL') {
		$source = $piddle;
		$dest   = $args{'dest'};
	} else {
		$source = $piddle->copy();
		$dest   = $piddle;
	}
	$rank       = get_rank();
	$population = comm_size();
	$r_send 	= $source->send_nonblocking(($rank+$offset)	 % $population);
	$r_receive  = $dest->receive_nonblocking(($rank-$offset) % $population);

	$r_receive->wait();  
	$r_send->wait();
}

=head2 scatter

=for ref

Takes a piddle and splits its data onto all of the processors.
This would take an n-dimensional piddle on the root and turn 
it into an n-1 dimensional piddle on all processors.  
It may be called as a piddle method, which is equivilant to
simply specifing the 'source' argument.
On the root, one must specify the source.  On all other procs,
one may also pass a 'source' argument to allow scatter to grok
the size of the destination piddle to allocate.  Alternatively 
on the non-root procs one may specify the dest piddle explicitly,
or simply specify the dimensions of the destionation piddle.


=for usage

	# usage (all arguments are optional, but see above).
	# may be used as a piddle method, which simply sets the
	# source argument.
	
	$dest_piddle = scatter(
		source => $src_piddle,
		dest   => $dest_piddle,  
		dims   => $array_ref,
		root   => $root_proc,      # root defaults to 0.
		comm   => $comm,           # defaults to MPI_COMM_WORLD
	);

=for example

	# with 4 processes
	$a = sequence(4,4);
	$b = $a->scatter;

=cut

sub scatter 
{
	my ($source, $root_proc, $dest,	@dims);
	my %args = @_;
	$root_proc = $args{'root'} || 0;
	$source = (ref $args{'source'} eq 'PDL' ? $args{'source'} : \0);

	if (ref $args{'dest'} eq 'PDL') {$dest=$args{'dest'};}
	else
	{
		@dims =	$args{'dims'} ? (@{$args{'dims'}},0) : $source->dims;
		pop @dims;
		$dest=main::zeroes(@dims);
	}

	if ($args{'comm'}) 	{xs_scatter($$source,$$dest,$root_proc,$args{'comm'})}
	else 				{xs_scatter($$source,$$dest,$root_proc)}
	return $dest;
}

=head2 gather

=for ref

C<gather> is the opposite of C<scatter>.  Using it as a piddle method
simply specifies the source.  If called on an n dimensional piddle on 
all procs, the root will contain an n+1 dimensional piddle on
completion.


                  memory =>
                +------------+                    +-------------+
          ^     |a0          |      ----->        | a0 a1 a2 a3 |
   procs  |     |a1          |     gather         |             |
          |     |a2          |                    |             |
                |a3          |    <-----          |             |
                +------------+    scatter         +-------------+

=for usage

	# usage
	gather(
		source => $src_piddle,
		dest   => $dest_piddle,  # only used at root, extrapolated from source if not specified.
		root   => $root_proc,    # defaults to 0
		comm   => $comm,         # defaults to MPI_COMM_WORLD
	);

=for example

	# example.  assume nprocs == 4.
	$a = ones(4);
	$b = $a->gather;
	# $b->dims now is (4,4) on proc 0.

=cut

sub gather 
{
	my ($source, $root_proc, $dest,	$rank);
	my %args = @_;
	$rank = get_rank();
	$root_proc = $args{'root'} || 0;
	$source = $args{'source'};

	if (ref $args{'dest'} eq 'PDL') { $dest =$args{'dest'}; } 
	else {
		if ($rank == $root_proc) 
		{
			$dest = main::zeroes($source->dims,comm_size());
		} else {
			$dest = \0;
		}
	}

	if ($args{'comm'}) 	{xs_gather($$source,$$dest,$root_proc,$args{'comm'})}
	else 				{xs_gather($$source,$$dest,$root_proc)}
	return $dest;
}

=head2 allgather

C<allgather> does the same thing as C<gather> except that the result is placed
on all processors rather than just the root.

                  memory =>
                +------------+                    +-------------+
          ^     |a0          |                    | a0 a1 a2 a3 |
   procs  |     |a1          |     ----->         | a0 a1 a2 a3 |
          |     |a2          |     allgather      | a0 a1 a2 a3 |
                |a3          |                    | a0 a1 a2 a3 |
                +------------+                    +-------------+

=for ref

=for usage

=for example

=cut

sub allgather 
{
	my ($source, $dest);
	my %args = @_;
	$source = (ref $args{'source'} eq 'PDL') ? $args{'source'} : croak;

	if (ref $args{'dest'} eq 'PDL') { $dest =$args{'dest'}; } 
	else { $dest = main::zeroes($source->dims,comm_size()); }

	if ($args{'comm'}) 	{xs_allgather($$source,$$dest,$args{'comm'})}
	else 				{xs_allgather($$source,$$dest)}
	return $dest;
}

=head2 alltoall

=for ref

                  memory =>
                +-------------+                    +-------------+
          ^     | a0 a1 a2 a3 |                    | a0 b0 c0 d0 |
   procs  |     | b0 b1 b2 b3 |     ----->         | a1 b1 c1 d1 |
          |     | c0 c1 c2 c3 |     alltoall       | a2 b2 c2 d2 |
                | d0 d1 d2 d3 |                    | a3 b3 c3 d3 |
                +-------------+                    +-------------+

=for usage

	# usage
	# calling as piddle method simply sets the source argument.
	$dest_piddle = alltoall(
		source => $src_piddle,
		dest   => $dest_piddle,  # created for you if not passed.
		comm   => $comm,         # defaults to MPI_COMM_WORLD.
	);

=for example


	# example: assume comm_size is 4.
	$a = $rank * sequence(4);
	$b = $a->alltoall;

=cut

sub alltoall 
{
	my ($source, $dest);
	my %args = @_;
	$source = (ref $args{'source'} eq 'PDL') ? $args{'source'} : croak;

	if (ref $args{'dest'} eq 'PDL') { $dest =$args{'dest'}; } 
	else { $dest = main::zeroes($source->dims); }

	if ($args{'comm'}) 	{xs_alltoall($$source,$$dest,$args{'comm'})}
	else 				{xs_alltoall($$source,$$dest)}
	return $dest;
}

=head2 reduce

=for ref

 +-------------+             +----------------------------------+
 | a0 a1 a2 a3 |    reduce   | a0+b0+c0+d0 , a1+b1+c1+d1, ....  |
 | b0 b1 b2 b3 |    ----->   |                                  |
 | c0 c1 c2 c3 |             |                                  |
 | d0 d1 d2 d3 |             |                                  |
 +-------------+             +----------------------------------+

Allowed operations are: 
C<+ * max min & | ^ and or xor>.


=for usage

	# usage  (also as piddle method; source is set)
	$dest_piddle = reduce(
		source => $src_piddle,
		dest   => $dest_piddle,  # signifigant only at root & created for you if not specified
		root   => $root,         # defaults to 0
		op     => $op,           # defaults to '+'
		comm   => $comm,         # defaults to MPI_COMM_WORLD
	);

=for example

	# example
	$a=$rank * (sequence(4)+1);
	$b=$a->reduce; 

=cut

sub reduce
{
	# XXX : add documentation about what ops are possible.
	my ($op,%args,$source,$dest,$comm,$root);
	%args=@_;

	$op = $args{'op'} || '+';
	$root = $args{'root'} || 0;

	$source = ref $args{'source'} ? $args{'source'} : croak;

	if (get_rank() == $root) {
		if (ref $args{'dest'} eq 'PDL') { $dest =$args{'dest'}; } 
		else { $dest = main::zeroes($source->dims); }
	} else {
		$dest = \0;
	}

	if ($args{'comm'}) 	{ xs_reduce($$source,$$dest,$op,$root,$args{'comm'});}
	else				{ xs_reduce($$source,$$dest,$op,$root);}
	return $dest;
}

=head2 allreduce

=for ref

Just like reduce except that the result is put on all the processes.

=for usage

	# usage  (also as piddle method; source is set)
	$dest_piddle = allreduce(
		source => $src_piddle,
		dest   => $dest_piddle,  # created for you if not specified
		root   => $root,         # defaults to 0
		op     => $op,           # defaults to '+'
		comm   => $comm,         # defaults to MPI_COMM_WORLD
	);

=for example

	# example
	$a=$rank * (sequence(4)+1);
	$b=$a->allreduce; 

=cut

sub allreduce
{
	# XXX : add documentation about what ops are possible.
	my ($op,%args,$source,$dest,$comm,$root);
	%args=@_;

	$op = $args{'op'} || '+';

	$source = ref $args{'source'} ? $args{'source'} : croak;

	if (ref $args{'dest'} eq 'PDL') { $dest =$args{'dest'}; } 
	else { $dest = main::zeroes($source->dims); }

	if ($args{'comm'}) 	{ xs_allreduce($$source,$$dest,$op,$args{'comm'});}
	else				{ xs_allreduce($$source,$$dest,$op);}
	return $dest;
}

=head2 scan

=for ref

 +-------------+             +----------------------------------+
 | a0 a1 a2 a3 |    scan     | a0 ,  a1 , a2 , a3               |
 | b0 b1 b2 b3 |    ----->   | a0+b0 , a1+b1 , a2+b2, a3+b3     |
 | c0 c1 c2 c3 |             |                                  |
 | d0 d1 d2 d3 |             |    ...                           |
 +-------------+             +----------------------------------+

Allowed operations are: 
C<+ * max min & | ^ and or xor>.


=for usage

	# usage  (also as piddle method; source is set)
	$dest_piddle = scan(
		source => $src_piddle,
		dest   => $dest_piddle,  # created for you if not specified
		root   => $root,         # defaults to 0
		op     => $op,           # defaults to '+'
		comm   => $comm,         # defaults to MPI_COMM_WORLD
	);

=for example

	# example
	$a=$rank * (sequence(4)+1);
	$b=$a->scan; 

=cut

sub scan
{
	# XXX : add documentation about what ops are possible.
	my ($op,%args,$source,$dest,$comm,$root);
	%args=@_;

	$op = $args{'op'} || '+';

	$source = ref $args{'source'} ? $args{'source'} : croak;

	if (ref $args{'dest'} eq 'PDL') { $dest =$args{'dest'}; } 
	else { $dest = main::zeroes($source->dims); }

	if ($args{'comm'}) 	{ xs_scan($$source,$$dest,$op,$args{'comm'});}
	else				{ xs_scan($$source,$$dest,$op);}
	return $dest;
}

=head2 reduce_and_scatter

=for ref

Does a reduce followed by a scatter.  A regular scatter distributes the data
evenly over all processes, but with reduce_and_scatter you get to specify the
distribution (if you want; defaults to uniform).

=for usage

	# usage  (also as piddle method; source is set)
	$dest_piddle = reduce_and_scatter(
		source => $src_piddle,
		dest   => $dest_piddle,             # created for you if not specified.
		recv_count => $recv_count_piddle    # 1D int piddle.  put $r[$i] elements on proc $i.
		op     => $op,                      # defaults to '+'
		comm   => $comm,                    # defaults to MPI_COMM_WORLD
	);


=for example

	# example, taken from t/20_reduce_and_scatter.t
	mpirun(4); MPI_Init(); $rank = get_rank();
	$a=$rank * (sequence(4)+1);
	$b=$a->reduce_and_scatter; 
	print "rank = $rank, b=$b\n" ;

=cut

sub reduce_and_scatter
{
	# XXX : add documentation about what ops are possible.
	my ($op,%args,$source,$dest,$comm_size,$recv_count);
	%args=@_;
	$op = $args{'op'} || '+';
	$source = ref $args{'source'} ? $args{'source'} : croak;
	$comm_size= $args{'comm'} ? comm_size($args{'comm'}) : comm_size();

	$recv_count = (ref $args{'recv_count'} eq 'PDL') ? $args{'recv_count'} :
		main::ones($comm_size) * (xs_nvals($$source) / $comm_size);
	
	# mpi requires an int[]
	# on my machine int is the pdl long.
	# if that's not the case on your machine, things will break.
	$recv_count = main::long($recv_count);  

	if (ref $args{'dest'} eq 'PDL') { $dest =$args{'dest'}; } 
	else 
	{ 
		$dest=
			main::zeroes(
				$recv_count->at(get_rank()) 
			);
	}

	if (get_rank() == 1) {
		print "source=$source\ndest=$dest\nrecv_count=$recv_count\nop=$op\n";
	}
	if ($args{'comm'}) 	{ xs_reduce_scatter($$source,$$dest,$$recv_count,$op,$args{'comm'});}
	else				{ xs_reduce_scatter($$source,$$dest,$$recv_count,$op);}
	return $dest;
}

sub PDL::reduce_and_scatter
{
	my $piddle=shift;
	reduce_and_scatter(source=>$piddle,@_);
}

sub PDL::scan
{
	my $piddle=shift;
	scan(source=>$piddle,@_);
}	

sub PDL::allreduce
{
	my $piddle=shift;
	allreduce(source=>$piddle,@_);
}

sub PDL::reduce 
{
	my $piddle=shift;
	reduce(source=>$piddle,@_);
}

sub PDL::alltoall
{
	my $piddle=shift;
	alltoall(source=>$piddle, @_);
}

sub PDL::allgather
{
	my $piddle=shift;
	allgather(source=>$piddle, @_);
}


sub PDL::scatter
{
	my $piddle=shift;
	scatter(source => $piddle, @_);
}

sub PDL::gather
{
	my $piddle=shift;
	gather(source => $piddle, @_);
}
	
my %constants = qw(MPI_2COMPLEX            MPI_Datatype
		   MPI_2DOUBLE_COMPLEX     MPI_Datatype
		   MPI_2DOUBLE_PRECISION   MPI_Datatype
		   MPI_2INT                MPI_Datatype
		   MPI_2INTEGER            MPI_Datatype
		   MPI_2REAL               MPI_Datatype
		   MPI_COMPLEX             MPI_Datatype
		   MPI_DATATYPE_NULL       MPI_Datatype
		   MPI_DOUBLE              MPI_Datatype
		   MPI_DOUBLE_COMPLEX      MPI_Datatype
		   MPI_DOUBLE_INT          MPI_Datatype
		   MPI_DOUBLE_PRECISION    MPI_Datatype
		   MPI_FLOAT               MPI_Datatype
		   MPI_FLOAT_INT           MPI_Datatype
		   MPI_INT                 MPI_Datatype
		   MPI_INTEGER             MPI_Datatype
		   MPI_BYTE                MPI_Datatype
		   MPI_CHAR                MPI_Datatype
		   MPI_CHARACTER           MPI_Datatype
		   MPI_LOGICAL             MPI_Datatype
		   MPI_LONG                MPI_Datatype
		   MPI_LONG_DOUBLE         MPI_Datatype
		   MPI_LONG_DOUBLE_INT     MPI_Datatype
		   MPI_LONG_INT            MPI_Datatype
		   MPI_LONG_LONG_INT       MPI_Datatype
		   MPI_REAL                MPI_Datatype
		   MPI_SHORT               MPI_Datatype
		   MPI_SHORT_INT           MPI_Datatype
           MPI_STRING              MPI_Datatype
		   MPI_UNSIGNED            MPI_Datatype
		   MPI_UNSIGNED_CHAR       MPI_Datatype
		   MPI_UNSIGNED_LONG       MPI_Datatype
		   MPI_UNSIGNED_SHORT      MPI_Datatype
		   MPI_ANY_SOURCE          MPI_Status
		   MPI_ANY_TAG             MPI_Status
		   MPI_BAND                MPI_Op
		   MPI_BOR                 MPI_Op
		   MPI_BXOR                MPI_Op
		   MPI_LAND                MPI_Op
		   MPI_LOR                 MPI_Op
		   MPI_LXOR                MPI_Op
		   MPI_MAX                 MPI_Op
		   MPI_MAXLOC              MPI_Op
		   MPI_MIN                 MPI_Op
		   MPI_MINLOC              MPI_Op
		   MPI_OP_NULL             MPI_Op
		   MPI_PROD                MPI_Op
		   MPI_SUM                 MPI_Op
		   MPI_COMM_NULL           MPI_Comm
		   MPI_COMM_SELF           MPI_Comm
		   MPI_COMM_WORLD          MPI_Comm
		   MPI_CONGRUENT           undef
		   MPI_IDENT               undef
		   MPI_SIMILAR             undef
		   MPI_UNEQUAL             undef
		   MPI_VERSION             undef);

my @funcs =     qw(&MPI_Send &MPI_Recv &MPI_Barrier &MPI_Bcast &MPI_Comm_size
		   &MPI_Comm_rank &MPI_Wtime &MPI_Wtick &MPI_Init &MPI_Finalize &MPI_Initialized
		   &MPI_Abort &MPI_Reduce &MPI_Allreduce &MPI_Scatter &MPI_Gather &MPI_Sendrecv);

@EXPORT = ( 
	keys %constants, 
	@funcs,
	qw/ 
	reduce
	send_test 
	receive_test 
	send 
	receive 
	get_status 
	get_status_list
	get_rank
	comm_size
	print_status
	scatter
	gather
	allgather
	mpirun
	alltoall
	allreduce
	reduce_and_scatter
	scan
	/);


sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.  If a constant is not found then control is passed
    # to the AUTOLOAD in AutoLoader.

    my $constname;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    my $val = constant($constname, @_ ? $_[0] : 0);

    if ($! != 0) {
	if ($! =~ /Invalid/) {
	    $AutoLoader::AUTOLOAD = $AUTOLOAD;
	    goto &AutoLoader::AUTOLOAD;
	}
	else {
	    croak "Your vendor has not defined MPI constant $constname";
	}
    }

    # some constants need to be blessed references to allow type checking.
    if ($constants{$constname} ne "undef") {
	eval "sub $constname {  my \$v = $val; my \$v2 = \\\$v; bless \$v2, \"$constants{$constname}\"; }";	
    } else {
	eval "sub $AUTOLOAD { $val }";
    }
    goto &$AUTOLOAD;
}


# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__



=head1 WARNINGS

This module is still under development.
Signifigant changes are expected.
As things are *expected* to break somehow or another, 
there is no waranty, and the author does not take
responsibility for the damage/distruction of your data/computer/sanity.

=head1 PLANS

=head2 indexing

Currently there is no support for any sort of indexing/dataflow/child piddles.
Ideally one would like to say:

	$piddle->diagonal(0,1)->move(0 => 1);

But currently one must say:

	$tmp = $piddle->diagonal(0,1)->copy;
	$tmp->move( 0 => 1);
	$piddle->diagonal(0,1) .= $tmp;

I believe the former behavior to be possible to implement.
I plan to do so once I reach a sufficent degree of enlightenment.

=head2 distributed data

One might wish to use their own personal massively parallel supercomputer interactively
with the pdl shell (perldl).  This would require master/slave interactions and
a distributed data model.  Such a project won't be started until after I finish 
PDL::Parallel::OpenMP.


=head1 AUTHOR

Darin McGill
darin@ocf.berkeley.edu

If you find this module useful, please let me know.
I very much appreciate bug reports, suggestions and other feedback.

=head1 ACKNOWLEDGEMENTS

This module is an extension of Parallel::MPI written by Josh Wilmes and Chris Stevens.
Signifigant portions of code has been copied from Parallel::MPI verbatim.
Used with permission.  Josh and Chris did most of the work to make perl's built in
datatypes (scalars, arrays) work with MPI.  I rely heavily on their work for 
MPI intitialization and error handling.

The diagrams in this document were inspired by and are
similar to diagrams found in MPI-The Complete Reference.

Sections of code from the main PDL distribution (such as header files, 
and code from PDL::CallExt.xs) were used extensively in development.
Many thanks to the PDL developers for their help, and of course, for
creating the PDL system in the first place.

=head1 SEE ALSO

The PDL::Parallel homepage:
http://www.ocf.berkeley.edu/~darin/projects/superperl

The PDL home page:
http://pdl.perl.org

The Perl module Parallel::MPI.

The Message Passing Interface: 
http://www.mpi-forum.org/

PDL::Parallel::OpenMP (under development).

=head1 COPYING

This module is free software.  
It may be modified and/or redistributed under the same terms as perl itself.

=cut
