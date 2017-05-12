package Parallel::Pvm;

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
@EXPORT = qw
  (
   PVM_BYTE PVM_CPLX PVM_DCPLX PVM_DOUBLE PVM_FLOAT PVM_INT
   PVM_LONG PVM_SHORT PVM_STR PVM_UINT PVM_ULONG PVM_USHORT
   PvmAllowDirect PvmAlready PvmAutoErr PvmBadMsg PvmBadParam
   PvmBadVersion PvmCantStart PvmDSysErr PvmDataDefault
   PvmDataFoo PvmDataInPlace PvmDataRaw PvmDebugMask PvmDontRoute
   PvmDupEntry PvmDupGroup PvmDupHost PvmFragSize PvmHostAdd
   PvmHostCompl PvmHostDelete PvmHostFail PvmMismatch PvmMppFront
   PvmNoBuf PvmNoData PvmNoEntry PvmNoFile PvmNoGroup PvmNoHost
   PvmNoInst PvmNoMem PvmNoParent PvmNoSuchBuf PvmNoTask
   PvmNotImpl PvmNotInGroup PvmNullGroup PvmOk PvmOutOfRes
   PvmOutputCode PvmOutputTid PvmOverflow PvmPollConstant
   PvmPollSleep PvmPollTime PvmPollType PvmResvTids PvmRoute
   PvmRouteDirect PvmSelfOutputCode PvmSelfOutputTid
   PvmSelfTraceCode PvmSelfTraceTid PvmShowTids PvmSysErr
   PvmTaskArch PvmTaskChild PvmTaskDebug PvmTaskDefault
   PvmTaskExit PvmTaskHost PvmTaskSelf PvmTaskTrace PvmTraceCode
   PvmTraceTid PvmMboxDefault PvmMboxPersistent PvmMboxMultiInstance 
   PvmMboxOverWritable PvmMboxFirstAvail PvmMboxReadAndDelete
);

# Theese are the badd ones:
#     send pack unpack exit recv kill 
@EXPORT_OK = qw
  (

   spawn initsend psend mcast sendsig probe nrecv trecv precv parent
   mytid halt catchout tasks config addhosts delhosts bufinfo freebuf
   getrbuf getsbuf mkbuf setrbuf setsbuf mstat pstat tidtohost getopt
   setopt reg_hoster reg_tasker reg_rm perror notify recv_notify
   hostsync recvf recvf_old

   joingroup lvgroup bcast freezegroup barrier getinst gettid gsize

   siblings

   getcontext newcontext setcontext freecontext

   putinfo recvinfo delinfo getmboxinfo

   code2symbol code2text
  );

$VERSION = '1.4.0-pre1';

sub AUTOLOAD 
{
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.  If a constant is not found then control is passed
    # to the AUTOLOAD in AutoLoader.

    my $constname;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "& not defined" if $constname eq 'constant';
    my $val = constant($constname, @_ ? $_[0] : 0);
    if ($! != 0) 
    {
	if ($! =~ /Invalid/) 
        {
	    $AutoLoader::AUTOLOAD = $AUTOLOAD;
	    goto &AutoLoader::AUTOLOAD;
	}
	else 
        {
		croak "Your vendor has not defined Parallel::Pvm macro $constname";
	}
    }
    no strict 'refs';
    *$AUTOLOAD = sub { $val };
    goto &$AUTOLOAD;
}

bootstrap Parallel::Pvm $VERSION;

# Preloaded methods go here.


# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

Parallel::Pvm - Perl extension for the Parallel Virtual Machine (PVM) Message Passing System

=head1 SYNOPSIS

  use Parallel::Pvm;

=head1 DESCRIPTION

The B<PVM> message passing system 
enables a programmer to configure a group of 
(possibly heterogenous) computers connected by 
a network into a 
parallel virtual machine.  
The system was developed by 
the University of Tennessee, Oak Ridge National 
Laboratory and Emory University. 

Using PVM, applications can 
be developed which spawns parallel processes onto 
nodes in the virtual machine to perform specific tasks.  
These parallel tasks can also periodically exchange 
information using a set of message passing functions 
developed for the system.  

PVM applications have mostly been developed in the scientific 
and engineering fields.  However applications 
for real-time and client/server systems can also be developed.  
PVM simply provides a convenient way for managing 
parallel tasks and communications  
without need for B<rexec> or B<socket> level programming.

As a utility, PVM enables an organisation to leverage on the computers 
already available for parallel processing.  
Parallel applications can be started during non-peak 
hours to utilise idle CPU cycles.  
Or dedicated workstation clusters connected via 
a high performance network like B<ATM> can be used for high 
performance computing.  

It is recommended that you read the PVM manual pages and the book
"PVM: Parallel Virtual Machine, A users's guide and tutorial 
for networked parallel computing".  Both the PVM system and the 
book can be obtained from the HTTP address http://www.epm.ornl.gov/pvm.

For the rest of 
this document we will provide a tutorial introduction to 
developing PVM applications using perl.  The interface for some 
of the PVM functions have been changed of course to give it a 
more perl-like feel.  

Remember think perl think parallel!  Good Luck!  

=head2 Environment Variables

After installing PVM on your computer, there are two mandatory 
environment variables that have to be set in your .login or .cshrc
files; B<PVM_ROOT> and B<PVM_ARCH>.  
B<PVM_ROOT> points to the base of the B<PVM> 
installation directory, and B<PVM_ARCH> specifies the architecture 
of the computer on which B<PVM> is running.   An example of how this can 
be set for csh is shown below,

	setenv PVM_ROOT /usr/local/pvm3
	setenv PVM_ARCH `$PVM_ROOT/lib/pvmgetarch`

=head2 Setting up your rsh permission

In order for PVM applications to run, B<rsh> permission 
has to be enabled.  This involves creating a B<.rhosts> 
file in your B<HOME> directory containing, for each line, the host and 
account name you wish to allow remote execution privillages.
An example B<.rhosts> file to allow a PVM application to 
remotely execute on the host B<onyx> and B<prata> using the 
account B<edward> is shown below,

	onyx	edward
	prata	edward

=head2 Configuring your parallel virtual machine

Parallel process management and communications is handled by a set of 
distributed deamons running on each of the nodes of the 
virtual machine.  The daemon executable, B<pvmd>, is started 
when a computer is added to the virtual machine.  
A computer can be added to the virtual machine either statically 
in a console program or using a B<hostfile>, 
or dynamically within the application code itself.

The first method of configuring your virtual machine 
is to use the console program B<$PVM_ROOT/lib/pvm>.  
Run it from the command prompt.  The console program will first add the 
local host into the virtual machine and display the prompt 
	
	pvm>

To add a host, eg B<onyx>, as a node in your parallel virtual machine, simply
type

	pvm> add onyx

To display the current virtual machine configuration type

	pvm> conf

which will display node information pertaining to the host name, 
host id, host architecture, relative speed and data format.  
The console program has a number of other commands which can 
be viewed by typing B<help>.  

The second method of configuring your virtual machine is to use 
a B<hostfile>.   The B<hostfile> is simply an ASCII text file 
specifing the host names of the computers to be added into your 
virtual machine.  

Additional options may be also be defined 
for the nodes pertaining to the working directory, 
execution path, login name, alternative hostname etc. A simple
example of a B<hostfile> is shown below. 

	* wd=$HOME/work ep=$HOME/bin
	onyx
	prata.nsrc.nus.sg
	laksa ep=$HOME/perl5/bin

In the above example B<hostfile> we are adding the 
hosts B<onyx>, B<prata.nsrc.nus.sg> and B<laksa> into the 
virtual machine. We are also specifying the working 
directory, B<wd>, in which we want our application 
to run, and the execution path, B<ep>, in which we want PVM
to look for executables. 

The B<*> in the first line 
defines a global option for all the hosts specified after it.
We can however provide an option locally to over-ride this
global option.  This is seen for the host B<laksa> where 
we have specified its execution path to be B<$HOME/perl5/bin> 
instead of the B<$HOME/bin>.  

The third method of configuring your virtual machine 
is to call the functions B<Parallel::Pvm::addhosts> or B<Parallel::Pvm::delhosts> 
within your application.  You must still start your master
B<pvmd> daemon first. This can be achieved by starting 
B<pvm> and typing B<quit> or simply typing  

	echo quit | pvm

The PVM application can then be started where 
we can add the hosts B<prata> and B<laksa> by calling

	Parallel::Pvm::addhosts("prata","laksa");

Or we can delete a host from our configuration by calling 

	Parallel::Pvm::delhosts("laksa");

PVM also provides a function, B<Parallel::Pvm::conf>, to query the configuration 
of the parallel virtual machine. An example code to check the current 
configuration is shown below.

	($info,@conf) = Parallel::Pvm::conf ;
	if ( $info == PvmOk ){
	  foreach $node (@conf){
	   print "host id = $node->{'hi_tid'}\n";
	   print "host name = $node->{'hi_name'}\n";
	   print "host architecture = $node->{'hi_arch'}\n";
	   print "host speed = $node->{'hi_speed'}\n";
	  }
	}

=head2 Enrolling a task into PVM

A task has to expilictly enroll into PVM 
in order for it to be known by other PVM tasks.  
This can often be done by the call 
	
	$mytid = Parallel::Pvm::mytid ;

where B<$mytid> is the task id, B<TID>, assigned by the 
PVM system to the calling process.  Note however that 
calling any PVM function in a program will also enroll it 
into the system.  

=head2 Spawning parallel tasks

A PVM application can spawn parallel tasks in your parallel 
virtual machine.  Assuming there is exists an executable called 
B<client>, we can spawn four B<client> tasks in our virtual 
machine by calling 

	($ntask,@tids) = Parallel::Pvm::spawn("client",4);

For each of the four spawned processes, the PVM system first 
allocates a host node and looks for the executable in the 
execuation path of that host.  If the executable is found it 
is started.  

The task which called the B<Parallel::Pvm::spawn> is known as 
the B<parent> task.  
The number of B<children> tasks which are actually spawned by 
B<Parallel::Pvm::spawn> is returned in the scalar B<$ntask>.  
The B<@tids> array returns the task id, B<TID>, of the spawned 
B<children> tasks which will be useful later for 
communicating with them.  A B<TID> < 0 indicates a task failure 
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

For more sophisticated users, B<Parallel::Pvm::spawn> may be given additional 
argument parameters to control how/where you want a task to be spawned.
For example, you can specifically spawn B<client> in the internet 
host B<onyx.nsrc.nus.sg> by calling

	Parallel::Pvm::spawn("client",1,PvmTaskHost,"onyx.nsrc.nus.sg");

Or you can spawn B<client> on host nodes only of a particular architecture, 
say RS6K workstations, by calling

	Parallel::Pvm::spawn("client",4,PvmTaskArch,"RS6K");

Also, if the spawned remote executable requires an argument B<argv>, 
you can supply this by calling

	Parallel::Pvm::spawn("client",4,PvmTaskArch,"RS6K",argv);

Note that tasks which have been spawned by using B<Parallel::Pvm::spawn> 
do not need to be explicitly enrolled into the pvm system.  

=head2 Exchanging messages between tasks

Messages can be sent to a task enrolled into PVM by specifying 
the example code sequence

	Parallel::Pvm::initsend ;
	Parallel::Pvm::pack(2.345,"hello dude");
	Parallel::Pvm::pack(1234);
	Parallel::Pvm::send($dtid,999);

In our example we first call B<Parallel::Pvm::initsend> to initialize
the internal PVM send buffer.  We then call B<Parallel::Pvm::buffer>
to fill this buffer with a double (2.345), a string ("hello dude"),
and an integer (1234) <b>Actually, currently all arguments are
converted to strings</b>.  Having filled the send buffer with the data
that is to be sent, we call B<Parallel::Pvm::send> to do the actual
send to the task identifed by the B<TID> B<$dtid>.  We also label the
sending message to disambiguate it with other messages with a tag.
This is done with the 999 argument in B<Parallel::Pvm::send> function.

For the destination task, we can receive the message sent by 
performing a blocking receive with the function B<Parallel::Pvm::recv>.  
A code sequence for the above example on the recipent 
end will be 

	if ( Parallel::Pvm::recv >= 0 ){
	   $int_t = Parallel::Pvm::unpack ;
	   ($double_t,$str_t) = Parallel::Pvm::unpack ;
	}

Note that we must unpack the message in the reverse order in which we packed 
our message.  
In our example B<Parallel::Pvm::recv> will receive any message sent to it.  
In order to selectively receive a message, we could specify 
the B<TID> of the source task and the message B<tag>.  For
example, 

	$tag = 999;
	Parallel::Pvm::recv($stid,$tag) ;

I<Caveats>: Messages may not contain the vertical tab character
C<"\v">. If you pass messages to programs written in other languages,
you need to know that C<Parallel::Pvm::pack> packs everything as
strings (with C<pvm_packstr>).

Other message passing functions that you may find useful are 
B<Parallel::Pvm::psend>, B<Parallel::Pvm::trecv>, B<Parallel::Pvm::nrecv> and B<Parallel::Pvm::precv>.  

=head2 Parallel I/O 

Note that the file descriptors in a parent task are not
inherented in the spawned B<children> tasks unlike B<fork>.  
By default any file I/O will be performed in the working 
directory specified in the B<hostfile> if no 
absolute path was provided for the opened file.  
If no working directory is specified, the default is the 
B<$HOME> directory.  For directories which are not NFS mounted, 
this would mean that each task performs its own separate 
I/O.  

In the case of B<tty> output, tasks which are not 
started from the command prompt will have their 
B<stdout> and B<stderr> directed to the file pvml.<uid>.  
This may be redirected to a B<parent> task by 
calling 

	Parallel::Pvm::catchout;

for B<stdout> or 

	Parallel::Pvm::catchout(stderr);

for B<stderr>.   You can direct the B<stdout> or B<stderr> output 
of a task to another B<TID> , other then its parent, by calling 

	Parallel::Pvm::setopt(PvmOutTid,$tid);

=head2 Incorporating fault tolerance

The function B<Parallel::Pvm::notify> can be used to incorporate some 
fault tolerance into your PVM application.  
You may use it to ask the PVM 
to monitor the liveliness of a set of hosts or tasks
during the execution of a PVM application. 
For example you can instrument 
your application to monitor 3 tasks with B<TID> B<$task1>, 
B<$task2>, and B<$task3>, by using the code segments 

	@monitor = ($task1,$task2,$task3);
	Parallel::Pvm::notify(PvmTaskExit,999,@monitor_task);
	...

	if ( Parallel::Pvm::probe(-1,999) ){
	   $task = Parallel::Pvm::recv_notify ;
	   print "Oops! task $task has failed ... \n" ; 
	}

If either B<$task1>, B<$task2> or B<$task3> 
fails,  the notification will take the form of 
a single message with the 
tag 999.  The message content will inform you of 
the B<TID> of the failed task.  

A similar scheme may be employed for the notification of host 
failures in your parallel virtual machine.  

=head2 Client/Server example

B<Client:>

	use Pvm;
	use File::Basename;
	...

	# Look for server tid and assume 
	# server name is 'service_provider'

	@task_list = Parallel::Pvm::tasks ;
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
	Parallel::Pvm::send($serv_tid,$REQUEST);

	# receive service from server
	Parallel::Pvm::recv(-1,$RESPONSE);
	@service_packet = Parallel::Pvm::unpack ;
	...

B<Server:>

	while(1){
	   ...

	   if ( Parallel::Pvm::probe(-1,$REQUEST) ){

	      # a service request has arrived !
	      $bufid = Parallel::Pvm::recv ;
	      ($info,$bytes,$tag,$stid) = Parallel::Pvm::bufinfo($bufid) ;

	      if ( fork == 0 ){
	         # fork child process to handle service
	         ...
 
	         # provide service
	         Parallel::Pvm::initsend ;
	         Parallel::Pvm::pack(@service);
	         Parallel::Pvm::send($stid,$RESPONSE);
	         
	         # exit child process
	         exit ;
	      }
	   }	   
	   ...
	
	}

=head2 PVM groups 

The PVM dynamic group functions have not completely been ported to
Perl yet.  We do not support B<pvm_scatter>, B<pvm_gather>, and
B<pvm_reduce> currently.  This is connected to the limited datatype
support in the rest of the Perl interface.

The group functions provide facilities for collecting processes under
a single B<group> label, and applying aggregate operations onto them.
Examples of these functions are B<Parallel::Pvm::barrier>,
B<Parallel::Pvm::reduce>, B<Parallel::Pvm::bcast> etc.  One of our
concerns is that these group functions may be changed or augmented in
the future releases of PVM 3.4*.

=head1 FUNCTIONS

=over 4

=item B<Parallel::Pvm::start_pvmd>

Starts pvmd if it's not already running.

	$info = Parallel::Pvm::start_pvmd($block, @args) ;

=item B<Parallel::Pvm::addhosts> 

Adds one or more host names to a parallel virtual machine. Eg.

	$info = Parallel::Pvm::addhosts(@host_list) ;

=item B<Parallel::Pvm::bufinfo>

Returns information about the requested message buffer. Eg.

	($info,$bytes,$tag,$tid) = Parallel::Pvm::bufinfo($bufid);

=item B<Parallel::Pvm::catchout>

Catches output from children tasks.  Eg.

	# Parallel::Pvm::catchout(stdout);
	$bufid = Parallel::Pvm::catchout; 

=item B<Parallel::Pvm::config>

Returns information about the present virtual machine configuration. Eg.

	($info,@host_ref_list) = Parallel::Pvm::config ;

=item B<Parallel::Pvm::delhosts>

Deletes one or more hosts from the virtual machine. Eg.

	$info = Parallel::Pvm::delhosts(@host_list);

=item B<Parallel::Pvm::exit>

Tells the local PVM daemon that the process is leaving.  Eg.

	$info = Parallel::Pvm::exit ;

=item B<Parallel::Pvm::freebuf>

Disposes of a message buffer. Eg.

	$info = Parallel::Pvm::freebuf($bufid);

=item B<Parallel::Pvm::getopt>

Shows various libpvm options.  Eg.

	$val = Parallel::Pvm::getopt(PvmOutputTid);
	$val = Parallel::Pvm::getopt(PvmFragSize);

=item B<Parallel::Pvm::getrbuf>

Returns the message buffer identifier for the active receive buffer. Eg.

	$bufid = Parallel::Pvm::getrbuf ;


=item B<Parallel::Pvm::getsbuf>

Returns the message buffer identifier for the active send buffer.  Eg. 

	$bufid = Parallel::Pvm::getsbuf ;

=item B<Parallel::Pvm::halt>

Shuts down the entire PVM system. Eg. 

	$info = Parallel::Pvm::halt ;

=item B<Parallel::Pvm::hostsync>

Gets time-of-day clock from PVM host. Eg.

	($info,$remote_clk,$delta) = Parallel::Pvm::hostsync($host) ;

where B<delta> is the time-of-day equivalent to B<local_clk - remote_clk>. 

=item B<Parallel::Pvm::initsend>

Clears default send buffer and specifies message encoding. Eg.

	# Parallel::Pvm::initsend(PvmDataDefault) ;
	$bufid = Parallel::Pvm::initsend

=item B<Parallel::Pvm::kill>

Terminates a specified PVM process.

	$info = Parallel::Pvm::kill($tid);

=item B<Parallel::Pvm::mcast>

Multicast the data in the active message buffer to a set of tasks.  Eg.

	$info = Parallel::Pvm::mcast(@tid_list,$tag);

=item B<Parallel::Pvm::mkbuf>

Creates a new message buffer. Eg.

	# Parallel::Pvm::mkbuf(PvmDataDefault);
	$bufid = Parallel::Pvm::mkbuf ;

	$bufid = Parallel::Pvm::mkbuf(PvmDataRaw);

=item B<Parallel::Pvm::mstat>

Returns the status of a host in the virtual machine.  Eg. 

	$status = Parallel::Pvm::mstat($host);

=item B<Parallel::Pvm::mytid>

Returns the tid of the calling process.

	$mytid = Parallel::Pvm::mytid ;

=item B<Parallel::Pvm::notify>

Requests notification of PVM events. Eg.

	$info = Parallel::Pvm::notify(PvmHostDelete,999,$host_list);

	# turns on notification for new host
	$info = Parallel::Pvm::notify(PvmHostAdd);

        # turns off notification for new host
	$info = Parallel::Pvm::notify(PvmHostAdd,0);

=item B<Parallel::Pvm::nrecv>

Nonblocking receive.  Eg.

	# Parallel::Pvm::nrecv(-1,-1);
	$bufid = Parallel::Pvm::nrecv ;

	# Parallel::Pvm::nrecv($tid,-1);
	$bufid = Parallel::Pvm::nrecv($tid) ;

	$bufid = Parallel::Pvm::nrecv($tid,$tag) ;

=item B<Parallel::Pvm::pack>

Packs active message buffer with data. Eg.

	$info = Parallel::Pvm::pack(@data_list);

=item B<Parallel::Pvm::parent>

Returns the tid of the process that spawned the calling process.  Eg.

	$tid = Parallel::Pvm::parent ;

=item B<Parallel::Pvm::perror>

Prints the error status of the las PVM call.

	$info = Parallel::Pvm::perror($msg);

=item B<Parallel::Pvm::precv>

Receives a message directly into a buffer.  

	# Parallel::Pvm::precv(-1,-1);
	@recv_buffer = Parallel::Pvm::precv ;

	# Parallel::Pvm::precv($tid,-1);
	@recv_buffer = Parallel::Pvm::precv($tid);

	@recv_buffer = Parallel::Pvm::precv($tid,$tag);

Note that the current limit for the receive buffer is 100 KBytes
unless you specify a third argument overwriting this limit.

=item B<Parallel::Pvm::probe>

Checks whether a message has arrived.  Eg.

	# Parallel::Pvm::probe(-1,-1);
	$bufid = Parallel::Pvm::probe ;

	# Parallel::Pvm::probe($tid,-1);
	$bufid = Parallel::Pvm::probe($tid);

	$bufid = Parallel::Pvm::probe($tid,$tag);

=item B<Parallel::Pvm::psend>

Packs and sends data in one call.  Eg.

	$info = Parallel::Pvm::psend($tid,$tag,@send_buffer);

=item B<Parallel::Pvm::pstat>

Returns the status of the specified PVM process.  Eg.

	$status = Parallel::Pvm::pstat($tid);

=item B<Parallel::Pvm::recv>

Receives a message.  Eg.

	# Parallel::Pvm::recv(-1,-1);
	$bufid = Parallel::Pvm::recv ;

	# Parallel::Pvm::recv($tid,-1);
	$bufid = Parallel::Pvm::recv($tid) ;

	$bufid = Parallel::Pvm::recv($tid,$tag);

=item B<Parallel::Pvm::recvf>

Redefines the comparison function used to accept messages.  Eg.

	Parallel::Pvm::recvf(\&new_foo);

=item B<Parallel::Pvm::recv_notify>

Receives the notification message initiated by B<Parallel::Pvm::notify>.  This 
should be preceded by a B<Parallel::Pvm::probe>.  Eg.

	# for PvmTaskExit and PvmHostDelete notification
	if ( Parallel::Pvm::probe(-1,$notify_tag) ){
		$message = Parallel::Pvm::recv_notify(PvmTaskExit) ;
	}

	# for PvmHostAdd notification
	@htid_list = Parallel::Pvm::recv_notify(PvmHostAdd);

=item B<Parallel::Pvm::recvf_old>

Resets the comparison function for accepting messages to the 
previous method before a call to B<Parallel::Pvm::recf>.  

=item B<Parallel::Pvm::reg_hoster>

Registers this task as responsible for adding new PVM hosts.  Eg.

	$info = Parallel::Pvm::reg_hoster ;

=item B<Parallel::Pvm::reg_rm>

Registers this task as a PVM resource manager.  Eg.

	$info = Parallel::Pvm::reg_rm ;

=item B<Parallel::Pvm::reg_tasker>

Registers this task as responsible for starting new PVM tasks.  Eg.

	$info = Parallel::Pvm::reg_tasker ;

=item B<Parallel::Pvm::send>

Send the data in the active message buffer.  Eg.  

	# Parallel::Pvm::send(-1,-1);
	$info = Parallel::Pvm::send ;

	# Parallel::Pvm::send($tid,-1);
	$info = Parallel::Pvm::send($tid);

	$info = Parallel::Pvm::send($tid,$tag);

=item B<Parallel::Pvm::sendsig>

Sends a signal to another PVM process.  Eg.

	use POSIX qw(:signal_h);
	...

	$info = Parallel::Pvm::sendsig($tid,SIGKILL);

=item B<Parallel::Pvm::setopt>

Sets various libpvm options.  Eg.

	$oldval=Parallel::Pvm::setopt(PvmOutputTid,$val);

	$oldval=Parallel::Pvm::setopt(PvmRoute,PvmRouteDirect);

=item B<Parallel::Pvm::setrbuf> 

Switches the active receive buffer and saves the previous buffer.  Eg.

	$oldbuf = Parallel::Pvm::setrbuf($bufid);

=item B<Parallel::Pvm::setsbuf>

Switches the active send buffer.  Eg.

	$oldbuf = Parallel::Pvm::setsbuf($bufid);

=item B<Parallel::Pvm::spawn>

Starts new PVM processes.  Eg.

	# Parallel::Pvm::spawn("compute.pl",4,PvmTaskDefault,"");
	($ntask,@tid_list) = Parallel::Pvm::spawn("compute.pl",4);

	($ntask,@tid_list) = Parallel::Pvm::spawn("compute.pl",4,PvmTaskHost,"onyx");

	($ntask,@tid_list) = Parallel::Pvm::spawn("compute.pl",4,PvmTaskHost,"onyx",argv);

=item B<Parallel::Pvm::tasks>

Returns information about the tasks running on the virtual machine. Eg.

	# Parallel::Pvm::tasks(0); Returns all tasks
	($info,@task_list) = Parallel::Pvm::tasks ;

	# Returns only for task $tid 
	($info,@task_list) = Parallel::Pvm::tasks($tid) ;
	

=item B<Parallel::Pvm::tidtohost>

Returns the host ID on which the specified task is running.  Eg.

	$dtid = Parallel::Pvm::tidtohost($tid);

=item B<Parallel::Pvm::trecv>

Receive with timeout.  Eg.

	# Parallel::Pvm::trecv(-1,-1,1,0); time out after 1 sec
	$bufid = Parallel::Pvm::trecv ;

	# time out after 2*1000000 + 5000 usec 	
	$bufid = Parallel::Pvm::trecv($tid,$tag,2,5000);


=item B<Parallel::Pvm::unpack>

Unpacks the active receive message buffer.  Eg.

	@recv_buffer = Parallel::Pvm::unpack ;

An optional integer argument gives the maximum message size to unpack.
Default is 100_000 bytes.

=back

=head1 AUTHORS

Edward Walker, edward@nsrc.nus.sg,
National Supercomputing Research Centre, Singapore

Denis Leconte, denis_leconte@geocities.com 

Ulrich Pfeifer, pfeifer@wait.de

=head1 SEE ALSO

perl(1), pvm_intro(1PVM)

=cut

sub code2symbol ($ ) {
  my %n2s = (
             0    => 'Ok',
             -2   => 'BadParam',
             -3   => 'Mismatch',
             -4   => 'Overflow',
             -5   => 'NoData',
             -6   => 'NoHost',
             -7   => 'NoFile',
             -8   => 'Denied',
             -10  => 'NoMem',
             -12  => 'BadMsg',
             -14  => 'SysErr',
             -15  => 'NoBuf',
             -16  => 'NoSuchBuf',
             -17  => 'NullGroup',
             -18  => 'DupGroup',
             -19  => 'NoGroup',
             -20  => 'NotInGroup',
             -21  => 'NoInst',
             -22  => 'HostFail',
             -23  => 'NoParent',
             -24  => 'NotImpl',
             -25  => 'DSysErr',
             -26  => 'BadVersion',
             -27  => 'OutOfRes',
             -28  => 'DupHost',
             -29  => 'CantStart',
             -30  => 'Already',
             -31  => 'NoTask',
             -32  => 'NotFound',
             -33  => 'Exists',
             -34  => 'HostrNMstr',
             -35  => 'ParentNotSet',
            );
  $n2s{$_[0]}
}

sub code2text ($ ) {
  my %n2t = (
             0   => "Success",
             -2  => "Bad parameter",
             -3  => "Parameter mismatch",
             -4  => "Value too large",
             -5  => "End of buffer",
             -6  => "No such host",
             -7  => "No such file",
             -8  => "Permission denied",
             -10 => "Malloc failed",
             -12 => "Can't decode message",
             -14 => "Can't contact local daemon",
             -15 => "No current buffer",
             -16 => "No such buffer",
             -17 => "Null group name",
             -18 => "Already in group",
             -19 => "No such group",
             -20 => "Not in group",
             -21 => "No such instance",
             -22 => "Host failed",
             -23 => "No parent task",
             -24 => "Not implemented",
             -25 => "Pvmd system error",
             -26 => "Version mismatch",
             -27 => "Out of resources",
             -28 => "Duplicate host",
             -29 => "Can't start pvmd",
             -30 => "Already in progress",
             -31 => "No such task",
             -32 => "Not Found",
             -33 => "Already exists",
             -34 => "Hoster run on non-master host",
             -35 => "Spawning parent set PvmNoSpawnParent",
            );
  $n2t{$_[0]}
}
