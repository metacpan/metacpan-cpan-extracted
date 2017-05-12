package OpenMosix::HA;
use strict;
use warnings;
use Cluster::Init;
# use Event qw(one_event loop unloop);
use Time::HiRes qw(time);
use Data::Dump qw(dump);
use Sys::Syslog;

BEGIN {
  use Exporter ();
  use vars qw (
    $VERSION 
    @ISA
    @EXPORT
    @EXPORT_OK
    %EXPORT_TAGS
    $LOGOPEN
    $PROGRAM
  );
  $VERSION     = 0.555;
  @ISA         = qw (Exporter);
  @EXPORT      = qw ();
  @EXPORT_OK   = qw ();
  %EXPORT_TAGS = ();
  $LOGOPEN     = 0;
  $PROGRAM=$0; $PROGRAM =~ s/.*\///;
}

# COMMON

sub debug
{
  my $debug = $ENV{DEBUG} || 0;
  return unless $debug;
  my ($package, $filename, $line, $subroutine, $hasargs, $wantarray, $evaltext, $is_require, $hints, $bitmask) = caller(1);
  my $subline = (caller(0))[2];
  my $msg = join(' ',@_);
  $msg.="\n" unless $msg =~ /\n$/;
  warn time()." $$ $subroutine,$subline: $msg" if $debug;
  if ($debug > 1)
  {
    warn _stacktrace();
  }
  if ($debug > 2)
  {
    Event::Stats::collect(1);
    warn sprintf("%d\n%-35s %3s %10s %4s %4s %4s %4s %7s\n", time,
    "DESC", "PRI", "CBTIME", "PEND", "CARS", "RAN", "DIED", "ELAPSED");
    for my $w (reverse all_watchers())
    {
      my @pending = $w->pending();
      my $pending = @pending;
      my $cars=sprintf("%01d%01d%01d%01d",
      $w->is_cancelled,$w->is_active,$w->is_running,$w->is_suspended);
      my ($ran,$died,$elapsed) = $w->stats(60);
      warn sprintf("%-35s %3d %10d %4d %4s %4d %4d %7.3f\n",
      $w->desc,
      $w->prio,
      $w->cbtime,
      $pending,
      $cars,
      $ran,
      $died,
      $elapsed);
    }
  }
}

sub logger
{
  my $level=shift;
  my $msg = join(' ',@_);
  openlog($PROGRAM,,"daemon") unless $LOGOPEN;
  $LOGOPEN=1;
  debug $msg;
  syslog($level,$msg);
}

sub logcrit
{
  my $msg = join(' ',@_);
  logger "crit", $msg;
}

sub logalert
{
  my $msg = join(' ',@_);
  logger "alert", $msg;
}

sub loginfo
{
  my $msg = join(' ',@_);
  logger "info", $msg;
}

sub logdebug
{
  my $msg = join(' ',@_);
  logger "debug", $msg;
}

sub _stacktrace
{
  my $out="";
  for (my $i=1;;$i++)
  {
    my @frame = caller($i);
    last unless @frame;
    $out .= "$frame[3] $frame[1] line $frame[2]\n";
  }
  return $out;
}

=head1 NAME

OpenMosix::HA -- High Availability (HA) layer for an openMosix cluster

=head1 SYNOPSIS

  use OpenMosix::HA;

  my $ha = new OpenMosix::HA;

  # start the monitor daemon 
  $ha->monitor;

=head1 DESCRIPTION

This module provides the basic functionality needed to manage resource 
startup and restart across a cluster of openMosix machines.  

This gives you a high-availability cluster with low hardware overhead.
In contrast to traditional HA clusters, we use the openMosix cluster
membership facility, rather than hardware serial cables or extra
ethernet ports, to provide heartbeat and to detect network partitions.

All you need to do is build a relatively conventional openMosix
cluster, install this module on each node, and configure it to start
and manage your HA processes.  You do not need the relatively
high-end server machines which traditional HA requires.  There is no
need for chained SCSI buses (though you can use them) -- you can
instead share disks among many nodes via any number of other current
technologies, including SAN, NAS, GFS, or Firewire (IEEE-1394).

Commercial support is available for B<OpenMosix::HA> as well as for
openMosix clusters and related products and services: see L</SUPPORT>.

=head1 QUICK START

See L<http://www.Infrastructures.Org> for cluster management
techniques, including clean ways to install, replicate, and update
nodes.

To use B<OpenMosix::HA> to provide high availability for  
processes hosted on an B<openMosix> cluster:

=over 4

=item *

Install B<Cluster::Init> and B<OpenMosix::HA> on each node.  

=item *

Create L<"/var/mosix-ha/cltab"> on any node.

=item * 

Create L<"/var/mosix-ha/hactl"> on any node.

=item * 

Run 'C<mosha>' on each node.  Putting this in F</etc/inittab> as a
"respawn" process would be a good idea.

=item * 

Check current status in L<"/var/run/mosix-ha/hastat"> on any node.  

=back

=head1 INSTALLATION

Use Perl's normal sequence:

  perl Makefile.PL
  make
  make test
  make install

You'll need to install this module on each node in the cluster.  

This module includes a script, L</mosha>, which will be installed when
you run 'make install'.  See the output of C<perl -V:installscript> to
find out which directory the script is installed in.

=head1 CONCEPTS

See L<Cluster::Init/"CONCEPTS"> for more discussion of basic concepts
used here, such as I<resource group>, I<high availability cluster>,
and I<high throughput cluster>.

Normally, a high-throughput cluster computing technology is orthogonal
to the intent of high availability, particularly if the cluster
supports process migration, as in openMosix.  When ordinary openMosix
nodes die, any processes migrated to or spawned from those nodes will
also die.  The higher the node count, the more frequently these
failures are likely to occur.

If the goal is high availability, then node failure in an openMosix
cluster presents two problems: (1) All processes which had migrated to
a failed node will die; their stubs on the home node will receive a
SIGCHLD.  (2)  All processes which had the failed node as their home
node will die; their stubs will no longer exist, and the migrated
processes will receive SIGKILL.

Dealing with (1) by itself might be easy; just use the native UNIX
init's "respawn" to start the process on the home node.  Dealing with
(2) is harder; you need to detect death of the home node, then figure
out which processes were spawned from there, and restart them on a
secondary node, again with a "respawn".  If you also lose the
secondary node, then you need to restart on a tertiary node, and so
on.  And managing /etc/inittab on all of the nodes would be an issue;
it would likely need to be both dynamically generated and different on
each node.

What's really needed is something like "init", but that acts
cluster-wide, using one replicated configuration file, providing both
respawn for individual dead processes and migration of entire resource
groups from dead home nodes.  That's what OpenMosix::HA does.

If processes are started via OpenMosix::HA, any processes and resource
groups which fail due to node failure will automatically restart on
other nodes.  OpenMosix::HA detects node failure, selects a new node
out of those currently available, and deconflicts the selection so
that two nodes don't restart the same process or resource group.  

There is no "head" or "supervisor" node in an OpenMosix::HA cluster --
there is no single point of failure.  Each node makes its own
observations and decisions about the start or restart of processes and
resource groups.  

You can build OpenMosix::HA clusters of dissimilar machines -- any
given node only needs to provide the hardware and/or software to
support a subset of all resource groups.  OpenMosix::HA is able to
test a node for eligibility before attempting to start a resource
group there -- resource groups will "seek" the nodes which can support
them.

IO fencing (the art of making sure that a partially-dead node doesn't
continue to access shared disk or other resources) can be handled as
it is in conventional HA clusters, by a combination of exclusive
device logins when using Firewire, or distributed locks when using GFS
or SAN.  

In the Linux HA community, simpler, more brute-force methods for IO
fencing are also used, involving network-controlled powerstrips or X10
controllers.  These methods are usually termed STOMITH or STONITH --
"shoot the other machine|node in the head".  OpenMosix::HA provides a
callback hook which can be used to trigger these external STOMITH
actions.

=head2 RESOURCE GROUP LIFECYCLE

Each OpenMosix::HA node acts independently, while watching the
activity of others.  If any node sees that a resource group is not
running anywhere in the cluster, it attempts to start the resource
group locally by following the procedure described here.  The
following discussion is from the perspective of that local node.

The node watches all other nodes in the cluster by consolidating
F</mfs/*/var/mosix-ha/clstat> into the local
L</"/var/mosix-ha/hastat">.  It then ensures that each resource group
configured in L</"/var/mosix-ha/cltab"> is running somewhere in the
cluster, at the runlevel specified in L</"/var/mosix-ha/hactl">.  

If a resource group is found to be not running anywhere in the
cluster, then the local OpenMosix::HA will attempt to transition the
resource group through each of the following runlevels on the local
node, in this order:

  plan
  test
  start (or whatever is named in hactl)
  stop  (later, at shutdown)

The following is a detailed discussion of each of these runlevels.

=head3 plan

Under normal circumstances, you should not create a 'plan' runlevel
entry in L</"/var/mosix-ha/cltab"> for any resource group.  This is
because 'plan' is used as a collision detection phase, a NOOP;
anything you run at the 'plan' runlevel will be run on multiple nodes
simultaneously.  

When starting a resource group on the local node, OpenMosix::HA will
first attempt to run the resource group at the 'plan' runlevel.  If
there is a 'plan' runlevel in L</"/var/mosix-ha/cltab"> for this
resource group, then OpenMosix::HA will execute it; otherwise, it will
just set the runlevel to 'plan' in its own copy of
L</"/var/mosix-ha/clstat">.

After several seconds in 'plan' mode, OpenMosix::HA will check other
nodes, to see if they have also started 'plan' or other activity for
the same resource group.  

If any other node shows 'plan' or other activity for the same resource
group during that time, then OpenMosix::HA will conclude that there
has been a collision, L</stop> the resource group on the local node,
and pause for several seconds.

The "several seconds" described here is dependent on the number of
nodes in the cluster and a collision-avoidance random backoff
calculation.  

=head3 test

You should specify at least one 'test' runlevel, with runmode also set
to 'test', for each resource group in L</"/var/mosix-ha/cltab">.  This
entry should test for prerequisites for the resource group, and its
command should exit with a non-zero return code if the test fails.  

For example, if F</usr/bin/foo> requires the 'modbar' kernel module,
then the following entries in L</"/var/mosix-ha/cltab"> will do the
job:

  foogrp:foo1:test:test:/sbin/modprobe modbar
  foogrp:foo2:start:respawn:/usr/bin/foo

...in this example, C<modprobe> will exit with an error if 'modbar'
can't be loaded on this node.

If a 'test' entry fails, then OpenMosix::HA will conclude that the
node is unusable for this resource group.  It will discontinue
startup, and will cleanup by executing the L</stop> entry for the
resource group.  

After a 'test' has failed and the resource group stopped, another node
will typically detect the stopped resource group within several
seconds, and execute L</plan> and L</test> again there.  This
algorithm continues, repeating as needed, until a node is found that
is eligible to run the resource group.  (For large clusters with small
groups of eligible nodes, this could take a while.  I'm considering
adding a "preferred node" list in hactl to shorten the search time.)

=head3 start

After the 'test' runlevel passes, and if there are still no collisions
detected, then OpenMosix::HA will start the resource group, using the
runlevel specified in L</"/var/mosix-ha/hactl">.

This runlevel is normally called 'start', but could conceivably be any
string matching C</[\w\d]+/>; you could use a numerical runlevel, a
product or project name, or whatever fits your needs.  The only other
requirement is that the string you use must be the same as whatever
you used in L</"/var/mosix-ha/cltab">.

=head3 stop

If you issue a L</shutdown>, then OpenMosix::HA will transition all
resource groups to the 'stop' runlevel.  If there is a 'stop' entry
for the resource group in L</"/var/mosix-ha/cltab">, then it will be
executed.

You do not need to specify a 'stop' entry in
L</"/var/mosix-ha/cltab">; you B<can> specify one if you'd like to do
any final cleanup, unmount filesystems, etc.

=head1 METHODS

=head2 new()

Loads Cluster::Init, but does not start any resource groups.

Accepts an optional parameter hash which you can use to override
module defaults.  Defaults are set for a typical openMosix cluster
installation.  Parameters you can override include:

=over 4

=item mfsbase

MFS mount point.  Defaults to C</mfs>.

=item mynode

Mosix node number of local machine.  You should only override this for
testing purposes.

=item varpath

The local path under C</> where the module should look for the
C<hactl> and C<cltab> files, and where it should put clstat
and clinit.s; this is also the subpath where it should look for
these things on other machines, under C</mfsbase/NODE>.  Defaults to
C<var/mosix-ha>.

=item timeout

The maximum age (in seconds) of any node's C<clstat> file, after which
the module considers that node to be stale, and calls for a STOMITH.
Defaults to 60 seconds.

=item mwhois

The command to execute to get the local node number.  Defaults to
"mosctl whois".  This command must print some sort of string on
STDOUT; a C</(\d+)/> pattern will be used to extract the node number
from the string.

=item stomith

The *CODE callback to execute when a machine needs to be STOMITHed.
The node number will be passed as the first argument.  Defaults to an
internal function which just prints "STOMITH node N" on STDERR.

=back

=cut

sub new
{
  my $class=shift;
  my $self={@_};
  bless $self, $class;
  $self->{mfsbase}   ||="/mfs";
  $self->{hpcbase}   ||="/proc/hpc";
  $self->{mwhois}    ||= "mosctl whois";
  $self->{mynode}    ||= $self->mosnode();
  $self->{varpath}   ||= "var/mosix-ha";
  $self->{clinit_s}  ||= "/".$self->{varpath}."/clinit.s";
  $self->{timeout}   ||= 60;
  $self->{cycletime} ||= 1;
  $self->{balance}   ||= 1.5;
  $self->{stomith}   ||= sub{$self->stomith(@_)};
  $self->{mybase}      = $self->nodebase($self->{mynode});
  $self->{hactl}       = $self->{mybase}."/hactl";
  $self->{cltab}       = $self->{mybase}."/cltab";
  $self->{clstat}      = $self->{mybase}."/clstat";
  $self->{hastat}      = $self->{mybase}."/hastat";
  unless (-d $self->{mybase})
  {
    mkdir $self->{mybase} || die $!;
  }
  return $self;
}

sub clinit
{
  my $self=shift;
  my %parms = (
    'clstat' => $self->{clstat},
    'cltab' => $self->{cltab},
    'socket' => $self->{clinit_s}
  );
  # start Cluster::Init daemon
  unless (fork())
  {
    $0.=" [Cluster::Init->daemon]";
    $self->cleanup;
    $self->getcltab($self->nodes);
    require Event;
    import Event;
    # noop; only -9 should be able to kill; we do orderly shutdown
    # in monitor
    Event->signal(signal=>"HUP" ,cb=>sub{1});
    Event->signal(signal=>"INT" ,cb=>sub{1});
    Event->signal(signal=>"QUIT",cb=>sub{1});
    Event->signal(signal=>"TERM",cb=>sub{1});
    my $clinit = Cluster::Init->daemon(%parms);
    debug "daemon exiting";
    exit;
  }
  sleep(1);
  # initialize client
  $self->{clinit} = Cluster::Init->client(%parms);
  return $self->{clinit};
}

### MONITOR

sub cleanexit
{
  my $self=shift;
  loginfo "calling haltwait";
  $self->haltwait;
  loginfo "calling shutdown";
  $self->{clinit}->shutdown();
  loginfo "calling cleanup";
  $self->cleanup;
  loginfo "exiting";
  exit 0;
}

sub cleanup
{
  my $self=shift;
  # unlink $self->{hastat};
  unlink $self->{clstat};
}

sub backoff
{
  my $self=shift;
  $self->{cycletime}+=rand(10);
}

sub cycle_faster
{
  my $self=shift;
  $self->{cycletime}/=rand(.5)+.5;
  # $self->{cycletime}=15 if $self->{cycletime} < 15;
}

sub cycle_slower
{
  my $self=shift;
  $self->{cycletime}*=rand()+1;
}

sub cycletime
{
  my $self=shift;
  my $time=shift;
  if ($time)
  {
    my $ct = $self->{cycletime};
    $ct = ($ct+$time)/2;
    $self->{cycletime}=$ct;
  }
  return $self->{cycletime};
}

sub compile_metrics
{
  my $self=shift;
  my $hastat=shift;
  my $hactl=shift;
  my $group=shift;
  my $mynode=$self->{mynode};
  my %metric;
  # is group active somewhere?
  if ($hastat->{$group})
  {
    $metric{isactive}=1;
    # is group active on my node?
    $metric{islocal}=1 if $hastat->{$group}{$mynode};
    for my $node (keys %{$hastat->{$group}})
    {
      # is group active in multiple places?
      $metric{instances}++;
    }
  }
  if ($metric{islocal})
  {
    # run levels which must be defined in cltab: plan test stop 
    # ("start" or equivalent is defined in hactl)
    my $level=$hastat->{$group}{$mynode}{level};
    my $state=$hastat->{$group}{$mynode}{state};
    debug "$group $level $state";
    # is our local instance of group contested?
    $metric{inconflict}=1 if $metric{instances} > 1;
    # has group been planned here?
    $metric{planned}=1 if $level eq "plan" && $state eq "DONE";
    # did group pass or fail a test here?
    $metric{passed}=1 if $level eq "test" && $state eq "PASSED";
    $metric{failed}=1 if $level eq "test" && $state eq "FAILED";
    # allow group to have no defined "test" runlevel -- default to pass
    $metric{passed}=1 if $level eq "test" && $state eq "DONE";
    # is group in transition?
    $metric{intransition}=1 unless $state =~ /^(DONE|PASSED|FAILED)$/;
    # is group in hactl?
    if ($hactl->{$group})
    {
      # does group runlevel match what's in hactl?
      $metric{chlevel}=1 if $level ne $hactl->{$group};
      # do we want to plan to test and start group on this node?
      unless ($hactl->{$group} eq "stop" || $metric{instances})
      {
	$metric{needplan}=1;
      }
    }
    else
    {
      $metric{deleted}=1;
    }
  }
  if ($hactl->{$group})
  {
    # do we want to plan to test and start group on this node?
    unless ($hactl->{$group} eq "stop" || $metric{instances})
    {
      $metric{needplan}=1;
    }
  }
  return %metric;
}

# get latest hactl file
sub gethactl
{
  my $self=shift;
  my @node=@_;
  $self->getlatest("hactl",@node);
  # return the contents
  my $hactl;
  open(CONTROL,"<".$self->{hactl}) || die $!;
  while(<CONTROL>)
  {
    next if /^\s*#/;
    next if /^\s*$/;
    chomp;
    my ($group,$level)=split;
    $hactl->{$group}=$level;
  }
  return $hactl;
}

# get latest cltab file
sub getcltab
{
  my $self=shift;
  my @node=@_;
  if ($self->getlatest("cltab",@node))
  {
    # reread cltab if it changed
    # if $self->{clinit}
    # XXX $self->tell("::ALL::","::REREAD::");
  }
  # return the contents
  my $cltab;
  open(CLTAB,"<".$self->{cltab}) || die $!;
  while(<CLTAB>)
  {
    next if /^\s*#/;
    next if /^\s*$/;
    chomp;
    my ($group,$tag,$level,$mode)=split(':');
    next unless $group;
    $cltab->{$group}=1;
  }
  return $cltab;
}

# get the latest version of a file
sub getlatest
{
  my $self=shift;
  my $file=shift;
  my @node=@_;
  my $newfile;
  # first we have to find it...
  my $myfile;
  for my $node (@node)
  {
    my $base=$self->nodebase($node);
    my $ckfile="$base/$file";
    $myfile=$ckfile if $node == $self->{mynode};
    next unless -f $ckfile;
    $newfile||=$ckfile;
    if (-M $newfile > -M $ckfile)
    {
      debug "$ckfile is newer than $newfile";
      $newfile=$ckfile;
    }
  }
  # ...then get it...
  if ($newfile && $myfile && $newfile ne $myfile)
  {
    if (-f $myfile && -M $myfile <= -M $newfile)
    {
      return 0;
    }
    sh("cp -p $newfile $myfile") || die $!; 
    return 1;
  }
  return 0;
}

# halt all local resource groups
sub haltall
{
  my $self=shift;
  my ($hastat)=$self->hastat($self->{mynode});
  debug dump $hastat;
  for my $group (keys %$hastat)
  {
    debug "halting $group";
    $self->tell($group,"stop");
  }
}

# halt all local resource groups and wait for them to complete
sub haltwait
{
  my $self=shift;
  my $hastat;
  loginfo "shutting down resource groups";
  my @group;
  do
  {
    $self->haltall;
    sleep(1);
    ($hastat)=$self->hastat($self->{mynode});
    @group=keys %$hastat;
    loginfo "still active: @group";
    for my $group (@group)
    {
      my $level=$hastat->{$group}{$self->{mynode}}{level};
      my $state=$hastat->{$group}{$self->{mynode}}{state};
      loginfo "$group: level=$level, state=$state";
    }
  } while (@group);
}

# build consolidated clstat and STOMITH stale nodes
sub hastat
{
  my $self=shift;
  my @node=@_;
  my $hastat;
  my @stomlist;
  for my $node (@node)
  {
    my $base=$self->nodebase($node);
    my $file="$base/clstat";
    next unless -f $file;
    # STOMITH stale nodes
    my $mtime = (stat($file))[9];
    debug "$node age $mtime\n";
    my $mintime = time - $self->{timeout};
    debug "$file mtime $mtime mintime $mintime\n";
    if ($mtime < $mintime)
    {
      debug "$node is old\n";
      unless($node == $self->{mynode})
      {
	push @stomlist, $node;
      }
    }
    open(CLSTAT,"<$file") || next;
    while(<CLSTAT>)
    {
      chomp;
      my ($class,$group,$level,$state) = split;
      next unless $class eq "Cluster::Init::Group";
      # ignore inactive groups
      next if $state eq "CONFIGURED";
      next if $level eq "stop" && $state eq "DONE";
      $hastat->{$group}{$node}{level}=$level;
      $hastat->{$group}{$node}{state}=$state;
    }
  }
  # note that this file is not always populated with the entire node
  # set -- depends on how hastat() was called!
  open(HASTAT,">".$self->{hastat}."tmp") || die $!;
  print HASTAT (dump $hastat);
  close HASTAT;
  rename($self->{hastat}."tmp", $self->{hastat}) || die $!;
  return ($hastat,\@stomlist);
}

=head2 monitor()

Starts the monitor daemon.  Does not return.  

The monitor does the real work for this module; it ensures the
resource groups in L</"/var/mosix-ha/cltab"> are each running
somewhere in the cluster, at the runlevels specified in
L</"/var/mosix-ha/hactl">.  Any resource groups found not running are
candidates for a restart on the local node.  

Before restarting a resource group, the local monitor announces its
intentions in the local C<clstat> file, and observes C<clstat> on
other nodes.  If the monitor on any other node also intends to start
the same resource group, then the local monitor will detect this and
cancel its own restart.  The checks and restarts are staggered by
random times on various nodes to prevent oscillation.

See L</CONCEPTS>.

=cut

sub monitor
{
  my $self=shift;
  my $runtime=shift || 999999999;
  my $start=time();
  my $stop=$start + $runtime;
  # Event->signal(signal=>"HUP" ,cb=>[$self,"cleanexit"]);
  # Event->signal(signal=>"INT" ,cb=>[$self,"cleanexit"]);
  # Event->signal(signal=>"QUIT",cb=>[$self,"cleanexit"]);
  # Event->signal(signal=>"TERM",cb=>[$self,"cleanexit"]);
  $SIG{HUP}=sub{$self->cleanexit};
  $SIG{INT}=sub{$self->cleanexit};
  $SIG{QUIT}=sub{$self->cleanexit};
  $SIG{TERM}=sub{$self->cleanexit};
  while(time < $stop)
  {
    my @node = $self->nodes();
    unless($self->quorum(@node))
    {
      my $node = $self->{mynode};
      logcrit "node $node: quorum lost: can only see nodes @node\n";
      $self->haltwait;
      sleep(30);
      next;
    }
    # build consolidated clstat 
    my ($hastat,$stomlist)=$self->hastat(@node);
    # STOMITH stale nodes
    $self->stomscan($stomlist) if time > $start + 120;
    # get and read latest hactl and cltab
    my $hactl=$self->gethactl(@node);
    my $cltab=$self->getcltab(@node);
    $self->scangroups($hastat,$hactl,@node);
    logdebug "node $self->{mynode} cycletime $self->{cycletime}\n";
    sleep($self->cycletime) if $self->cycletime + time < $stop;
  }
  return 1;
}

sub mosnode
{
  my $self=shift;
  my $whois=`$self->{mwhois}`; 
  # "This is MOSIX #32"
  $whois =~ /(\d+)/;
  my $node=$1;
  die "can't figure out my openMosix node number" unless $node;
  return $node;
}

sub nodebase
{
  my $self=shift;
  my $node=shift;
  my $base = join
  (
    "/",
    $self->{mfsbase},
    $node,
    $self->{varpath}
  );
  return $base;
}

# build list of nodes by looking in /proc/hpc/nodes
sub nodes
{
  my $self=shift;
  opendir(NODES,$self->{hpcbase}."/nodes") || die $!;
  my @node = grep /^\d/, readdir(NODES);
  closedir NODES;
  my @upnode;
  # check availability 
  for my $node (@node)
  {
    open(STATUS,$self->{hpcbase}."/nodes/$node/status") || next;
    chomp(my $status=<STATUS>);
    # XXX status bits mean what?
    next unless $status & 2;
    push @upnode, $node;
  }
  return @upnode;
}

# detect if we've lost quorum
sub quorum
{
  my ($self,@node)=@_;
  $self->{quorum}||=0;
  logdebug "quorum count: ".$self->{quorum}."\n";
  if (@node < $self->{quorum} * .6)
  {
    return 0;
  }
  $self->{quorum}=@node;
  return 1;
}

sub runXXX
{
  my $seconds=shift;
  Event->timer(at=>time() + $seconds,cb=>sub{unloop()});
  loop();
}

# scan through all known groups, stopping or starting them according 
# to directives in hactl and status of all nodes; the goal here is to
# make each group be at the runlevel shown in hactl
sub scangroups
{
  my $self=shift;
  my $hastat=shift;
  my $hactl=shift;
  my @node=@_;
  my $clinit=$self->{clinit};
  # for each group in hastat or hactl
  for my $group (uniq(keys %$hastat, keys %$hactl))
  {
    my %metric = $self->compile_metrics($hastat,$hactl,$group);
    debug "$group ", dump %metric;
    # stop groups which have been deleted from hactl
    if ($metric{deleted})
    {
      $self->tell($group,"stop");
      $self->cycletime(5);
      next;
    }
    # stop contested groups
    if ($metric{inconflict})
    {
      $self->tell($group,"stop");
      $self->backoff();
      next;
    }
    # start groups which previously passed tests
    if ($metric{passed})
    {
      $self->tell($group,$hactl->{$group});
      $self->cycletime(5);
      next;
    }
    # stop failed groups
    if ($metric{failed})
    {
      $self->tell($group,"stop");
      $self->cycletime(5);
      next;
    }
    # start tests for all uncontested groups we planned
    if ($metric{planned})
    {
      $self->tell($group,"test");
      $self->cycletime(5);
      next;
    }
    # notify world of groups we plan to test
    if ($metric{needplan})
    {
      $self->cycletime(10);
      # balance startup across all nodes
      next if rand(scalar @node) > $self->{balance};
      # start planning
      $self->tell($group,"plan");
      next;
    }
    # in transition -- don't do anything yet
    if ($metric{intransition})
    {
      $self->cycletime(5);
      next;
    }
    # whups -- level changed in hactl
    if ($metric{chlevel})
    {
      $self->tell($group,$hactl->{$group});
      $self->cycletime(5);
      next;
    }
    # normal cycletime is such that one node in the cluster should 
    # wake up each second
    # XXX this won't work with larger clusters -- too long to detect
    # shutdown in hactl -- maybe need to go with event loop here?
    $self->cycletime(scalar @node);
  }
}

sub sh
{
  my @cmd=@_;
  my $cmd=join(' ',@cmd);
  debug "> $cmd\n";
  my $res=`$cmd`;
  my $rc= $? >> 8;
  $!=$rc;
  return ($rc,$res) if wantarray;
  return undef if $rc;
  return 1;
}

sub stomith
{
  my ($self,$node)=@_;
  logalert "STOMITH node $node\n";
}

sub stomscan
{
  my $self=shift;
  my $stomlist=shift;
  for my $node (@$stomlist)
  {
    # warn "STOMITH $node\n";
    &{$self->{stomith}}($node);
  }
}

sub tell
{
  my $self=shift;
  my $group=shift;
  my $level=shift;
  debug "tell $group $level";
  $self->{clinit}->tell($group,$level);
}

sub uniq
{
  my @in=@_;
  my @out;
  for my $in (@in)
  {
    push @out, $in unless grep /^$in$/, @out;
  }
  return @out;
}

=head1 UTILITIES

=head2 mosha

OpenMosix::HA includes B<mosha>, a script which is intended to be
started as a "respawn" entry in each node's F</etc/inittab>.  It
requires no arguments.  

This is a simple script; all it does is create an OpenMosix::HA object
and call the L</monitor> method on that object.

=head1 FILES

=head2 /var/mosix-ha/cltab

The main configuration file; describes the processes and resource
groups you want to run in the cluster.  

See L<Cluster::Init/"/etc/cltab"> for the format of this file -- it's
the same file; OpenMosix::HA tells Cluster::Init to place cltab under
F</var/mosix-ha> instead of F</etc>.  For a configured example, see
F<t/master/mfs1/1/var/mosix-ha/cltab> in the OpenMosix::HA
distribution.

See L</"RESOURCE GROUP LIFECYCLE"> for runmodes and entries you should
specify in this file; specifically, you should set up at least one
'test' entry and one 'start' entry for each resource group.

You do B<not> need to replicate this file to any other node --
B<OpenMosix::HA> will do it for you.

=head2 /var/mosix-ha/hactl

The HA control file; describes the resource groups you want to run,
and the runlevels you want them to execute at.  See the L</CONCEPTS>
paragraph about the L</start> runlevel.  See
F<t/master/mfs1/1/var/mosix-ha/hactl> for an example.  

You do B<not> need to replicate this file to any other node --
B<OpenMosix::HA> will do it for you.

Format is one resource group per line, whitespace delimited, '#' means
comment:

  # resource_group  runlevel
  mygroup start
  foogroup start
  bargroup 3
  bazgroup 2
  # missing or commented means 'stop' -- the following two 
  #    lines are equivalent:
  redgrp stop
  # redgrp start

=head2 /var/mosix-ha/hastat

The cluster status file.  Rebuilt periodically on each node by
consolidating F</mfs/*/var/mosix-ha/clstat>.  Each node's version of
this file normally matches the others.  Interesting to read; can be
eval'd by other Perl processes for building automated monitoring
tools.

=head2 /var/mosix-ha/clstat

The per-node status file; see
L<Cluster::Init/"/var/run/clinit/cltab">.  Not very interesting unless
you're troubleshooting OpenMosix::HA itself -- see
F</var/mosix-ha/hastat> instead.

=head1 BUGS

The underlying module, Cluster::Init, has a Perl 5.8 compatibility
problem, documented there; fix targeted for next point release.

Quorum counting accidentally counts nodes that are up but not running
OpenMosix::HA; easy fix, to be done in next point release.

This version currently spits out debug messages every few seconds.

No test cases for monitor() yet.

Right now we don't detect or act on errors in cltab.

At this time, B<mosha> is a very minimal script which just gets the
job done, and probably will need some more work once we figure out
what else it might need to do.

=head1 SUPPORT

Commercial support for B<OpenMosix:::HA> is available at
L<http://clusters.TerraLuna.Org>.  On that web site, you'll also find
pointers to the latest version, a community mailing list, and other
cluster management software.

You can also find help for general infrastructure (and cluster)
administration at L<http://www.Infrastructures.Org>.

=head1 AUTHOR

	Steve Traugott
	CPAN ID: STEVEGT
	stevegt@TerraLuna.Org
	http://www.stevegt.com

=head1 COPYRIGHT

Copyright (c) 2003 Steve Traugott. All rights reserved.
This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 SEE ALSO

Cluster::Init, openMosix.Org, qlusters.com, Infrastructures.Org

=cut

1; 


