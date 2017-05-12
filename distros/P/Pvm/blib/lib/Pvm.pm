package Pvm;

use strict;
use Carp;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $AUTOLOAD);

require Exporter;
require DynaLoader;
require AutoLoader;

@ISA = qw(Exporter DynaLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(
	PVM_BYTE
	PVM_CPLX
	PVM_DCPLX
	PVM_DOUBLE
	PVM_FLOAT
	PVM_INT
	PVM_LONG
	PVM_SHORT
	PVM_STR
	PVM_UINT
	PVM_ULONG
	PVM_USHORT
	PvmAllowDirect
	PvmAlready
	PvmAutoErr
	PvmBadMsg
	PvmBadParam
	PvmBadVersion
	PvmCantStart
	PvmDSysErr
	PvmDataDefault
	PvmDataFoo
	PvmDataInPlace
	PvmDataRaw
	PvmDebugMask
	PvmDontRoute
	PvmDupEntry
	PvmDupGroup
	PvmDupHost
	PvmFragSize
	PvmHostAdd
	PvmHostCompl
	PvmHostDelete
	PvmHostFail
	PvmMismatch
	PvmMppFront
	PvmNoBuf
	PvmNoData
	PvmNoEntry
	PvmNoFile
	PvmNoGroup
	PvmNoHost
	PvmNoInst
	PvmNoMem
	PvmNoParent
	PvmNoSuchBuf
	PvmNoTask
	PvmNotImpl
	PvmNotInGroup
	PvmNullGroup
	PvmOk
	PvmOutOfRes
	PvmOutputCode
	PvmOutputTid
	PvmOverflow
	PvmPollConstant
	PvmPollSleep
	PvmPollTime
	PvmPollType
	PvmResvTids
	PvmRoute
	PvmRouteDirect
	PvmSelfOutputCode
	PvmSelfOutputTid
	PvmSelfTraceCode
	PvmSelfTraceTid
	PvmShowTids
	PvmSysErr
	PvmTaskArch
	PvmTaskChild
	PvmTaskDebug
	PvmTaskDefault
	PvmTaskExit
	PvmTaskHost
	PvmTaskSelf
	PvmTaskTrace
	PvmTraceCode
	PvmTraceTid
);

$VERSION = '0.01';

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
		croak "Your vendor has not defined Pvm macro $constname";
	}
    }
    eval "sub $AUTOLOAD { $val }";
    goto &$AUTOLOAD;
}

bootstrap Pvm $VERSION;

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

Pvm - Perl extension for the Parallel Virtual Machine (PVM) Message Passing System

=head1 SYNOPSIS

  use Pvm;

=head1 DESCRIPTION

The C<PVM> message passing system 
enables a programmer to configure a group of 
(possibly heterogenous) computers connected via 
a network (including the internet) into a 
parallel virtual machine.  
The system was developed by 
the University of Tennessee, Oak Ridge National 
Laboratory and Emory University. 

Using C<PVM>, applications can 
be developed which spawns parallel processes onto 
nodes in this virtual machine to perform specific tasks.  
These parallel tasks can also periodically exchange 
information using a set of message passing functions 
developed for the system.  

C<PVM> applications have mostly been developed in the scientific 
and engineering fields.  However applications 
for real-time and client/server systems can also be developed.  
C<PVM> simply provides a convenient way for managing 
parallel tasks and communications  
without need for C<rexec> or C<socket> level programming.

As a utility, C<PVM> enables an organisation to leverage on the computers 
already available for parallel processing.  
Parallel applications can be started during non-peak 
hours to utilise idle CPU cycles.  
Or dedicated workstation clusters connected via 
a high performance network like C<ATM> can be used for high 
performance computing.  

It is recommended that you read the C<PVM> manual pages and the book
C<PVM: Parallel Virtual Machine, A users's guide and tutorial 
for networked parallel computing>.  Both the C<PVM> system and the 
book can be obtained by email from C<netlib@ornl.gov> 
or anonymous ftp from C<netlib2.cs.utk.edu>.  

For the rest of 
this document we will provide a tutorial introduction to 
developing C<PVM> applications using perl.  The interface for some 
of the C<PVM> functions have been changed of course to give it a 
more perl-like feel.  

Remember think perl think parallel!  Good Luck!  

=head2 Environment Variables

After installing C<PVM> on your computer, there are two mandatory 
environment variables that have to be set in your .login or .cshrc
files; C<PVM_ROOT> and C<PVM_ARCH>.  
C<PVM_ROOT> points to the base of the C<PVM> 
installation directory, and C<PVM_ARCH> specifies the architecture 
of the computer on which C<PVM> is running.   An example of how this can 
be set for csh is shown below,

	setenv PVM_ROOT /usr/local/pvm3
	setenv PVM_ARCH `$PVM_ROOT/lib/pvmgetarch`

=head2 Setting up your rsh permission

In order for C<PVM> applications to run, C<rsh> permission 
has to be enabled.  This involves creating a C<.rhosts> 
file in your C<HOME> directory containing, for each line, the host and 
account name you wish to allow remote execution privillages.
An example C<.rhosts> file to allow a C<PVM> application to 
remotely execute on the host C<onyx> and C<prata> using the 
account C<edward> is shown below,

	onyx	edward
	prata	edward

=head2 Configuring your parallel virtual machine

Parallel process management and communications is handled by a set of 
distributed deamons running on each of the nodes of the 
virtual machine.  The daemon executable, C<pvmd>, is started 
when a computer is added to the virtual machine.  
A computer can be added to the virtual machine either statically 
in a console program or using a C<hostfile>, 
or dynamically within the application code itself.

The first method of configuring your virtual machine 
is to use the console program C<$PVM_ROOT/lib/pvm>.  
Run it from the command prompt.  The console program will first add the 
local host into the virtual machine and display the prompt 
	
	pvm>

To add a host, eg C<onyx>, as a node in your parallel virtual machine, simply
type

	pvm> add onyx

To display the current virtual machine configuration type

	pvm> conf

which will display node information pertaining to the host name, 
host id, host architecture, relative speed and data format.  
The console program has a number of other commands which can 
be viewed by typing C<help>.  

The second method of configuring your virtual machine is to use 
a C<hostfile>.   The C<hostfile> is simply an ASCII text file 
specifing the host names of the computers to be added into your 
virtual machine.  

Additional options may be also be defined 
for the nodes pertaining to the working directory, 
execution path, login name, alternative hostname etc. A simple
example of a C<hostfile> is shown below. 

	* wd=$HOME/work ep=$HOME/bin
	onyx
	prata.nsrc.nus.sg
	laksa ep=$HOME/perl5/bin

In the above example C<hostfile> we are adding the 
hosts C<onyx>, C<prata.nsrc.nus.sg> and C<laksa> into the 
virtual machine. We are also specifying the working 
directory, C<wd>, in which we want our application 
to run, and the execution path, C<ep>, in which we want C<PVM>
to look for executables. 

The C<*> in the first line 
defines a global option for all the hosts specified after it.
We can however provide an option locally to over-ride this
global option.  This is seen for the host C<laksa> where 
we have specified its execution path to be C<$HOME/perl5/bin> 
instead of the C<$HOME/bin>.  

The third method of configuring your virtual machine 
is to call the functions C<Pvm::addhosts> or C<Pvm::delhosts> 
within your application.  You must still start your master
C<pvmd> daemon first. This can be achieved by starting 
C<pvm> and typing C<quit> or simply typing  

	echo quit | pvm

The C<PVM> application can then be started where 
we can add the hosts C<prata.nsrc.nus.sg> and C<laksa> by calling

	Pvm::addhosts("prata.nsrc.nus.sg","laksa");

Or we can delete a host from our configuration by calling 

	Pvm::delhosts("laksa");

C<PVM> also provides a function, C<Pvm::conf>, to query the configuration 
of the parallel virtual machine. An example code to check the current 
configuration is shown below.

	($info,@conf) = Pvm::conf ;
	if ( $info == PvmOk ){
	   foreach $node (@conf){
	      print "host id = $node->{'hi_tid'}\n";
	      print "host name = $node->{'hi_name'}\n";
	      print "host architecture = $node->{'hi_arch'}\n";
	      print "host speed = $node->{'hi_speed'}\n";
           }
	}

=head2 Enrolling a task into PVM

A task has to expilictly enroll into C<PVM> 
in order for it to be known by other C<PVM> tasks.  
This can often be done by the call 
	
	$mytid = Pvm::mytid ;

where C<$mytid> is the task id, C<TID>, assigned by the 
C<PVM> system to the calling process.  Note however that 
calling any C<PVM> function in a program will also enroll it 
into the system.  

=head2 Spawning parallel tasks

A C<PVM> application can spawn parallel tasks in your parallel 
virtual machine.  Assuming there is exists an executable called 
C<client>, we can spawn four C<client> tasks in our virtual 
machine by calling 

	($ntask,@tids) = Pvm::spawn("client",4);

For each of the four spawned processes, the PVM system first 
allocates a host node and looks for the executable in the 
execuation path of that host.  If the executable is found it 
is started.  

The task which called the C<Pvm::spawn> is known as 
the C<parent> task.  
The number of C<children> tasks which are actually spawned by 
C<Pvm::spawn> is returned in the scalar C<$ntask>.  
The C<@tids> array returns the task id, C<TID>, of the spawned 
C<children> tasks which will be useful later for 
communicating with them.  A C<TID> < 0 indicates a task failure 
to spawn and can be used to determine the nature of 
the problem.  Eg.

	foreach $tid (@tids){
	   if ( $tid < 0 ){
	      if ( $tid == PvmNoMem )
		 warn "no memory ! \n";
	      }else if ( $tid == PvmSysErr ){
	         warn "pvmd not responding ! \n";
	      } ... 

	   }
	}

For more sophisticated users, C<Pvm::spawn> may be given additional 
argument parameters to control how/where you want a task to be spawned.
For example, you can specifically spawn C<client> in the internet 
host <onyx.nsrc.nus.sg> by calling

	Pvm::spawn("client",1,PvmTaskHost,"onyx.nsrc.nus.sg");

Or you can spawn C<client> on host nodes only of a particular architecture, 
say RS6K workstations, by calling

	Pvm::spawn("client",4,PvmTaskArch,"RS6K");

Note that tasks which have been spawned by using C<Pvm::spawn> 
do not need to be explicitly enrolled into the pvm system.  

=head2 Exchanging messages between tasks

Messages can be sent to a task enrolled into C<PVM> by specifying 
the example code sequence

	Pvm::initsend ;
	Pvm::pack(2.345,"hello dude");
	Pvm::pack(1234);
	Pvm::send($dtid,999);

In our example we first call C<Pvm::initsend> to initialize 
the internal C<PVM> send buffer.  
We then call C<Pvm::buffer> to fill this buffer with a double (2.345),
, a string ("hello dude"), and an integer (1234).  
Having filled the send buffer with the data that is to be sent, 
we call C<Pvm::send> to do the actual send to the task identifed by the C<TID> 
C<$dtid>.   We also label the sending message to disambiguate it with 
other messages with a tag.  This is done with the 999 argument in 
C<Pvm::send> function.  

For the destination task, we can receive the message sent by 
performing a blocking receive with the function C<Pvm::recv>.  
A code sequence for the above example on the recipent 
end will be 

	if ( Pvm::recv >= 0 ){
	   $int_t = Pvm::unpack ;
	   ($double_t,$str_t) = Pvm::unpack ;
	}

Note that we must unpack the message in the reverse order in which we packed 
our message.  
In our example C<Pvm::recv> will receive any message sent to it.  
In order to selectively receive a message, we could specify 
the C<TID> of the source task and the message C<tag>.  For
example, 

	$tag = 999;
	Pvm::recv($stid,$tag) ;

Other message passing functions that you may find useful are 
C<Pvm::psend>, C<Pvm::trecv>, C<Pvm::nrecv> and C<Pvm::precv>.  

=head2 Parallel I/O 

Note that the file descriptors in a parent task are not
inherented in the spawned C<children> tasks unlike C<fork>.  
By default any file I/O will be performed in the working 
directory specified in the C<hostfile> if no 
absolute path was provided for the opened file.  
If no working directory is specified, the default is the 
C<$HOME> directory.  For directories which are not NFS mounted, 
this would mean that each task performs its own separate 
I/O.  

In the case of C<tty> output, tasks which are not 
started from the command prompt will have their 
C<stdout> and C<stderr> directed to the file pvml.<uid>.  
This may be redirected to a C<parent> task by 
calling 

	Pvm::catchout;

for C<stdout> or 

	Pvm::catchout(stderr);

for C<stderr>.   You can direct the C<stdout> or C<stderr> output 
of a task to another C<TID> , other then its parent, by calling 

	Pvm::setopt(PvmOutTid,$tid);

=head2 Incorporating fault tolerance

The function C<Pvm::notify> can be used to incorporate some 
fault tolerance into your PVM application.  
You may use it to ask the C<PVM> 
to monitor the liveliness of a set of hosts or tasks
during the execution of a PVM application. 
For example you can instrument 
your application to monitor 3 tasks with C<TID> C<$task1>, 
C<$task2>, and C<$task3>, by using the code segments 

	@monitor = ($task1,$task2,$task3);
	Pvm::notify(PvmTaskExit,999,@monitor_task);
	...

	if ( Pvm::probe(-1,999) ){
	   $task = Pvm::recv_notify ;
	   print "Oops! task $task has failed ... \n" ; 
	}

If either C<$task1>, C<$task2> or C<$task3> 
fails,  the notification will take the form of 
a single message with the 
tag 999.  The message content will inform you of 
the C<TID> of the failed task.  

A similar scheme may be employed for the notification of host 
failures in your parallel virtual machine.  

=head2 Client/Server example

C<Client:>

	use Pvm;
	use File::Basename;
	...

	# Look for server tid and assume 
	# server name is 'service_provider'

	@task_list = Pvm::tasks ;
	foreach $task (@task_list){
	   $a_out = $task->{'ti_a_out'} ;
	   $base = basename $a_out ;
	   if ( $base eq 'service_provider' )
		$serv_tid = $task->{'ti_tid'} ;
	}

	# This is just one way (not necessarily the
	# best) of getting a server tid.
	# You could do the same thing by reading 
	# the server tid posted in a file. 

	...
	
	# send request for service
	Pvm::send($serv_tid,$REQUEST);

	# receive service from server
	Pvm::recv(-1,$RESPONSE);
	@service_packet = Pvm::unpack ;
	...

C<Server:>

	while(1){
	   ...

	   if ( Pvm::probe(-1,$REQUEST) ){

	      # a service request has arrived !
	      $bufid = Pvm::recv ;
	      ($info,$bytes,$tag,$stid) = Pvm::bufinfo($bufid) ;

	      if ( fork == 0 ){
	         # fork child process to handle service
	         ...
 
	         # provide service
	         Pvm::initsend ;
	         Pvm::pack(@service);
	         Pvm::send($stid,$RESPONSE);
	         
	         # exit child process
	         exit ;
	      }
	   }	   
	   ...
	
	}

=head2 PVM groups 

The PVM dynamic group functions have not been ported to perl yet.  
These functions provide facilities for collecting processes under 
a single C<group> label, and applying aggregate operations onto 
them.  Examples of these functions are C<Pvm::barrier>, C<Pvm::reduce>, 
C<Pvm::bcast> etc.  
One of our concerns is that these group functions may be 
changed or augmented in the future releases of PVM 3.4*. A decision 
for porting the group functions will be made after 
PVM 3.4 has been released.  

=head1 FUNCTIONS

=item C<Pvm::addhosts> 

Adds one or more host names to a parallel virtual machine. Eg.

	$info = Pvm::addhosts(@host_list) ;

=item C<Pvm::bufinfo>

Returns information about the requested message buffer. Eg.

	($info,$bytes,$tag,$tid) = Pvm::bufinfo($bufid);

=item C<Pvm::catchout>

Catches output from children tasks.  Eg.

	# Pvm::catchout(stdout);
	$bufid = Pvm::catchout; 

=item C<Pvm::config>

Returns information about the present virtual machine configuration. Eg.

	($info,@host_ref_list) = Pvm::config ;

=item C<Pvm::delhosts>

Deletes one or more hosts from the virtual machine. Eg.

	$info = Pvm::delhosts(@host_list);

=item C<Pvm::exit>

Tells the local PVM daemon that the process is leaving.  Eg.

	$info = Pvm::exit ;

=item C<Pvm::freebuf>

Disposes of a message buffer. Eg.

	$info = Pvm::freebuf($bufid);

=item C<Pvm::getopt>

Shows various libpvm options.  Eg.

	$val = Pvm::getopt(PvmOutputTid);
	$val = Pvm::getopt(PvmFragSize);

=item C<Pvm::getrbuf>

Returns the message buffer identifier for the active receive buffer. Eg.

	$bufid = Pvm::getrbuf ;


=item C<Pvm::getsbuf>

Returns the message buffer identifier for the active send buffer.  Eg. 

	$bufid = Pvm::getsbuf ;

=item C<Pvm::halt>

Shuts down the entire PVM system. Eg. 

	$info = Pvm::halt ;

=item C<Pvm::hostsync>

Gets time-of-day clock from PVM host. Eg.

	($info,$remote_clk,$delta) = Pvm::hostsync($host) ;

where C<delta> is the time-of-day equivalent to C<local_clk - remote_clk>. 

=item C<Pvm::initsend>

Clears default send buffer and specifies message encoding. Eg.

	# Pvm::initsend(PvmDataDefault) ;
	$bufid = Pvm::initsend

=item C<Pvm::kill>

Terminates a specified PVM process.

	$info = Pvm::kill($tid);

=item C<Pvm::mcast>

Multicast the data in the active message buffer to a set of tasks.  Eg.

	$info = Pvm::mcast(@tid_list,$tag);

=item C<Pvm::mkbuf>

Creates a new message buffer. Eg.

	# Pvm::mkbuf(PvmDataDefault);
	$bufid = Pvm::mkbuf ;

	$bufid = Pvm::mkbuf(PvmDataRaw);

=item C<Pvm::mstat>

Returns the status of a host in the virtual machine.  Eg. 

	$status = Pvm::mstat($host);

=item C<Pvm::mytid>

Returns the tid of the calling process.

	$mytid = Pvm::mytid ;

=item C<Pvm::notify>

Requests notification of PVM events. Eg.

	$info = Pvm::notify(PvmHostDelete,999,$host_list);

=item C<Pvm::nrecv>

Nonblocking receive.  Eg.

	# Pvm::nrecv(-1,-1);
	$bufid = Pvm::nrecv ;

	# Pvm::nrecv($tid,-1);
	$bufid = Pvm::nrecv($tid) ;

	$bufid = Pvm::nrecv($tid,$tag) ;

=item C<Pvm::pack>

Packs active message buffer with data. Eg.

	$info = Pvm::pack(@data_list);

=item C<Pvm::parent>

Returns the tid of the process that spawned the calling process.  Eg.

	$tid = Pvm::parent ;

=item C<Pvm::perror>

Prints the error status of the las PVM call.

	$info = Pvm::perror($msg);

=item C<Pvm::precv>

Receives a message directly into a buffer.  

	# Pvm::precv(-1,-1);
	@recv_buffer = Pvm::precv ;

	# Pvm::precv($tid,-1);
	@recv_buffer = Pvm::precv($tid);

	@recv_buffer = Pvm::precv($tid,$tag);

Note that the current limit for the receive buffer is 100 KBytes.  

=item C<Pvm::probe>

Checks whether a message has arrived.  Eg.

	# Pvm::probe(-1,-1);
	$bufid = Pvm::probe ;

	# Pvm::probe($tid,-1);
	$bufid = Pvm::probe($tid);

	$bufid = Pvm::probe($tid,$tag);

=item C<Pvm::psend>

Packs and sends data in one call.  Eg.

	$info = Pvm::psend($tid,$tag,@send_buffer);

=item C<Pvm::pstat>

Returns the status of the specified PVM process.  Eg.

	$status = Pvm::pstat($tid);

=item C<Pvm::recv>

Receives a message.  Eg.

	# Pvm::recv(-1,-1);
	$bufid = Pvm::recv ;

	# Pvm::recv($tid,-1);
	$bufid = Pvm::recv($tid) ;

	$bufid = Pvm::recv($tid,$tag);

=item C<Pvm::recvf>

Redefines the comparison function used to accept messages.  Eg.

	Pvm::recvf(\&new_foo);

=item C<Pvm::recv_notify>

Receives the notification message initiated by C<Pvm::notify>.  This 
should be preceded by a C<Pvm::probe>.  Eg.

	if ( Pvm::probe(-1,$notify_tag) ){
		$message = Pvm::recv_notify ;
	}

=item C<Pvm::recvf_old>

Resets the comparison function for accepting messages to the 
previous method before a call to C<Pvm::recf>.  

=item C<Pvm::reg_hoster>

Registers this task as responsible for adding new PVM hosts.  Eg.

	$info = Pvm::reg_hoster ;

=item C<Pvm::reg_rm>

Registers this task as a PVM resource manager.  Eg.

	$info = Pvm::reg_rm ;

=item C<Pvm::reg_tasker>

Registers this task as responsible for starting new PVM tasks.  Eg.

	$info = Pvm::reg_tasker ;

=item C<Pvm::send>

Send the data in the active message buffer.  Eg.  

	# Pvm::send(-1,-1);
	$info = Pvm::send ;

	# Pvm::send($tid,-1);
	$info = Pvm::send($tid);

	$info = Pvm::send($tid,$tag);

=item C<Pvm::sendsig>

Sends a signal to another PVM process.  Eg.

	use POSIX qw(:signal_h);
	...

	$info = Pvm::sendsig($tid,SIGKILL);

=item C<Pvm::setopt>

Sets various libpvm options.  Eg.

	$oldval=Pvm::setopt(PvmOutputTid,$val);

	$oldval=Pvm::setopt(PvmRoute,PvmRouteDirect);

=item C<Pvm::setrbuf> 

Switches the active receive buffer and saves the previous buffer.  Eg.

	$oldbuf = Pvm::setrbuf($bufid);

=item C<Pvm::setsbuf>

Switches the active send buffer.  Eg.

	$oldbuf = Pvm::setsbuf($bufid);

=item C<Pvm::spawn>

Starts new PVM processes.  Eg.

	# Pvm::spawn("compute.pl",4,PvmTaskDefault,"");
	($ntask,@tid_list) = Pvm::spawn("compute.pl",4);

	($ntask,@tid_list) = Pvm::spawn("compute.pl",4,PvmTaskHost,"onyx");

=item C<Pvm::tasks>

Returns information about the tasks running on the virtual machine. Eg.

	# Pvm::tasks(0); Returns all tasks
	($info,@task_list) = Pvm::tasks ;

	# Returns only for task $tid 
	($info,@task_list) = Pvm::tasks($tid) ;
	

=item C<Pvm::tidtohost>

Returns the host ID on which the specified task is running.  Eg.

	$dtid = Pvm::tidtohost($tid);

=item C<Pvm::trecv>

Receive with timeout.  Eg.

	# Pvm::trecv(-1,-1,1,0); time out after 1 sec
	$bufid = Pvm::trecv ;

	# time out after 2*1000000 + 5000 usec 	
	$bufid = Pvm::trecv($tid,$tag,2,5000);


=item C<Pvm::unpack>

Unpacks the active receive message buffer.  Eg.

	@recv_buffer = Pvm::unpack ;

=head1 AUTHOR

Edward Walker, edward@nsrc.nus.sg,
National Supercomputing Research Centre

=head1 SEE ALSO

perl(1), pvm_intro(1PVM)

=cut
