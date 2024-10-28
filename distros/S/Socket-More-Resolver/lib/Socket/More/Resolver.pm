package Socket::More::Resolver;
use strict;
use warnings;

use feature qw<say state>;

no warnings "experimental";
our $VERSION="v0.1.3";

use constant::more DEBUG=>0;
use constant::more qw<CMD_GAI=0   CMD_GNI   CMD_SPAWN   CMD_KILL CMD_REAP>;
use constant::more qw<WORKER_ID=0 WORKER_READ   WORKER_WRITE  WORKER_CREAD WORKER_CWRITE WORKER_QUEUE  WORKER_BUSY>;
use constant::more qw<REQ_CMD=0   REQ_ID  REQ_DATA  REQ_CB  REQ_ERR REQ_WORKER>;

use Fcntl;

use Export::These qw<getaddrinfo getnameinfo close_pool>;
use Socket::More::Lookup ();

my $gai_data_pack="l> l> l> l> l>/a* l>/a*";

#REQID  and as above
#
my $gai_pack="($gai_data_pack)*";



sub _results_available;
sub process_results;
sub getaddrinfo;
sub shrink_pool;
sub monitor_workers;
my $i=0;    # Sequential ID of requests

my $in_flight=0;

#my @pool_free;      # pids (keys) of workers we can use
my $pool_max=4;
my $enable_shrink;


my @pairs;        # file handles for parent/child pipes
                  # preallocated with first import of this module

                  #my $template_pid;

our $Shared;

my %fd_worker_map;



# In the pre export, we start the workers if not already started.
# Also detect event system.
#
sub _preexport {
  shift; shift;


  my %options=map %$_, grep ref, @_;
  
  #my @imports=map %$_, grep !ref, @_;
  
   
  # Don't generate pairs if they already exist
  if(!@pairs){

    $pool_max=($options{max_workers}//4);
    $pool_max=4 if $pool_max <=0;
    $pool_max++;
    $enable_shrink=$options{enable_shrink};


    #pre allocate enough pipes for full pool
    for(1..$pool_max){
      pipe my $c_read, my $p_write;
      pipe my $p_read, my $c_write;
      fcntl $c_read, F_SETFD, 0;  #Make sure we clear CLOSEXEC
      fcntl $c_write, F_SETFD,0;

      push @pairs,[0, $p_read, $p_write, $c_read, $c_write, [], 0]; 
    }




    # Create the template process here. This is the first worker
    #Need to bootstrap/ create the first worker, which is used as a template
    DEBUG and say STDERR "Create worker: Bootrapping  first/template worker"; 
    spawn_template();

    # Prefork

    if($options{prefork}){ 
      for(1..($pool_max-1)){
        unshift $pairs[0][WORKER_QUEUE]->@*, [CMD_SPAWN, $i++, $_];
        $in_flight++;
      }
    }

    # Work with event systems 
    my $sub;

    my @search=qw<AE IO::Async Mojo::IOLoop>; # Built in drivers
    for($options{loop_driver}//()){
      if(ref eq "CODE"){
        $sub=$_;
      }
      if(ref eq "ARRAY"){
        unshift @search, @$_;
      }
      else {
        #Assume a string
        unshift @search, $_;
      }
    }

    if($options{no_loop}){
      # Prevent event loop integration
      $sub=undef;
    }
    else{
      # Use search list
      no strict "refs";
      for(@search){
        if(%{$_."::"}){
          $sub=eval "require Socket::More::Resolver::$_";
          die $@ if $@;
          last;
        }
      }
    }
    $sub->() if($sub);
    #grep !ref, @_; 
  }
  if($options{prefork}){
      getaddrinfo for(1..($pool_max-1));
  }
  @_;
}

sub _reexport {
  Socket::More::Lookup->import("gai_strerror"); 
}






#If used as a module, setup the process pool

#getaddrinfo Request
#REQID FLAGS FAMILY TYPE PROTOCOL HOST PORT 

#getaddrinfo response
#FLAG/ERROR FAMILY TYPE PROTOCOL ADDR CANONNNAME 
#

# Return undef when no worker available.
#   If under limit, a new worker is spawned for next run
# Return the worker struct to use otherwise
# 
sub _get_worker{

#_results_available unless $Shared;
    my $worker;
    my $fallback;
    my $unspawned;
    my $index;
    my $busy_count=0;
    state $robin=1;
    for(1..$#pairs){
      $index=$_;
      $worker=$pairs[$index];
      if($worker->[WORKER_BUSY]){
          if($worker->[WORKER_ID]){
            $busy_count++;
            # Fully spawned and working on a request
            DEBUG and say STDERR "GETTING WORKER: fully spawned $index";
          }
          else {
            # half spawned, this has at least 1 message
            # if all other workers are busy we use the first one of these we come accros
            $fallback//=$index if $worker->[WORKER_QUEUE]->@*;
            DEBUG and say STDERR "GETTING WORKER: half spawned fallback $index";
          }
      }
      else {
        # Not busy
        #
        if($worker->[WORKER_ID]){
          # THIS IS THE WORKER WE WANT
          DEBUG and say STDERR "GETTING WORKER: found unbusy $index";
          return $worker;
        }
        else{
          # Not spawned.  Use first one we come accross if we need to spawn
          $unspawned//=$index;
          DEBUG and say STDERR "GETTING WORKER: found unspawned $index";
        }
      }
    }

    #  Use the about to be spawned worker
    return $pairs[$fallback] if defined $fallback;

    # Here we actaully need to spawn a worker
    
    my $template_worker=spawn_template(); #ensure template exists
  
    if($busy_count < (@pairs-1)){
      DEBUG and say STDERR "Queue spawn command to template for inext $unspawned"; 
      push $template_worker->[WORKER_QUEUE]->@*, [CMD_SPAWN, $i++, $unspawned];
      $index=$unspawned;
      $in_flight++;
      $pairs[$unspawned][WORKER_BUSY]=1;
    }
    else{
      $index=$robin++;
      $robin=1 if $robin >=@pairs;
    }

    #$pairs[$index][WORKER_BUSY]=1;
    #$pairs[$index][WORKER_ID]=-1;
    $pairs[$index];

}


sub pool_next;
# Serialize messages to worker from queue
sub pool_next{
  my $w=shift;

  # handle returns first .. TODO: This is only if no event system is being used
  _results_available unless $Shared;
  my $redo;
  for($w?$w:@pairs){
    DEBUG and say STDERR "POOL next for ".$_->[WORKER_ID]." busy: $_->[WORKER_BUSY], queue; ".$_->[WORKER_QUEUE]->@*;
    my $ofd;
    # only process worker is initialized  not busy and  have something to process
    next unless $_->[WORKER_ID];
    next if $_->[WORKER_BUSY];
    next unless $_->[WORKER_QUEUE]->@*;

    $_->[WORKER_BUSY]=1;

    #my $req=shift $_->[WORKER_QUEUE]->@*;
    my $req=$_->[WORKER_QUEUE][0];
    $req->[REQ_WORKER]=$_->[WORKER_ID];
    
    #$reqs{$req->[REQ_ID]}=$req; #Add to outstanding


    # Header
    my $out=pack "l> l>", $req->[REQ_CMD], $req->[REQ_ID];

    # Body
    if($req->[REQ_CMD]==CMD_SPAWN){
        # Write to template process
        #DEBUG and 
        my $windex=$req->[2];
        DEBUG and say STDERR ">> SENDING CMD_SPWAN TO WORKER: $req->[REQ_WORKER], worker index $windex";
        my $cread=fileno $pairs[$windex][WORKER_CREAD];
        my $cwrite=fileno $pairs[$windex][WORKER_CWRITE];

        $out.=pack("l> l>", $cread, $cwrite);
        $ofd=$pairs[0][WORKER_WRITE];
        $redo=1;
    }
    elsif($req->[REQ_CMD]==CMD_GAI) {
      # getaddrinfo request
      DEBUG and say STDERR ">> SENDING CMD_GAI TO WORKER: $req->[REQ_WORKER]";
      if(ref $req->[REQ_DATA] eq "ARRAY"){
        $out.=pack $gai_pack, $req->[REQ_DATA]->@*;
      }
      else {
        # assume a hash
        for($req->[REQ_DATA]){
          #$out.=pack $gai_pack, $_->{flags}//0, $_->{family}//0, $_->{socktype}//0, $_->{protocol}//0, $_->{host}, $_->{port};
          $out.=pack $gai_pack, $_->{flags}//0, $_->{family}//0, $_->{socktype}//0, $_->{protocol}//0, $_->{address}, $_->{port};
        }
      }

      $ofd=$_->[WORKER_WRITE];
    }
    elsif($req->[REQ_CMD]==CMD_GNI){
      DEBUG and say STDERR ">> SENDING CMD_GNI TO WORKER: $req->[REQ_WORKER]";
      $out.=pack "l>/A* l>", $req->[REQ_DATA]->@*;
      $ofd=$_->[WORKER_WRITE];

    }
    elsif($req->[REQ_CMD]== CMD_KILL){
      DEBUG and say STDERR ">> Sending CMD_KILL to worker: $req->[REQ_WORKER]";
      $ofd=$_->[WORKER_WRITE];
      $redo=1;
    }
    elsif($req->[REQ_CMD]== CMD_REAP){
      DEBUG and say STDERR ">> Sending CMD_REAP to worker: $req->[REQ_WORKER]";
      $out.=pack("l>/l>*", $req->[REQ_DATA]->@*);
      $ofd=$pairs[0][WORKER_WRITE];
      $redo=1;
    }
    else {
      die "UNkown command in pool_next";
    }

    DEBUG and say STDERR ">> WRITING WITH FD $ofd";
    syswrite $ofd, unpack("H*", $out)."\n"; # bypass buffering

  }
   pool_next if $redo;
}


# Peforms a read on the pipe, parses response from worker
# and executes callbacks as needed
#
# This is the routine needing to be called from an event loop
# when the pipe is readable
#
sub process_results{
  my $fd_or_struct=shift;
  my $worker;
  if(ref $fd_or_struct){
    $worker=$fd_or_struct;
  }
  else{
    $worker=$fd_worker_map{$fd_or_struct};
  }
  #Check which worker is ready to read.
  # Read the result
  #For now we wait.
  my $r=$worker->[WORKER_READ];
  local $_=<$r>;
    chomp;
    my $bin=pack "H*", $_;

    my ($cmd, $id)=unpack "l> l>", $bin;
    $bin=substr $bin, 8;  #two lots of long

    # Remove from the outstanding table
    my $entry=shift $worker->[WORKER_QUEUE]->@*;
    $in_flight--;
    #my $entry=delete $reqs{$id};
    
    # Mark the returning worker as not busy
    #
    $worker->[WORKER_BUSY]=0;

    if($cmd==CMD_GAI){
      DEBUG and say STDERR "<< GAI return from worker $entry->[REQ_WORKER]";
      my @res=unpack $gai_pack, $bin;
      if($res[0] and $entry->[REQ_ERR]){
        $entry->[REQ_ERR]($res[0]);
      }
      elsif(!$res[0] and $entry->[REQ_CB]){
        my @list;
        while(@res>=6){
          my @r=splice @res,0, 6;
          $r[5]||=undef; #Set cannon name to undef if empty string
          if(ref($entry->[REQ_DATA]) eq "ARRAY"){
            push @list, \@r;#[$error, $family, $type, $protocol, $addr, $canonname]; 
          }
          else {
            push @list, {
              error=>$r[0],
              family=>$r[1],
              socktype=>$r[2],
              protocol=>$r[3],
              addr=>$r[4],
              cannonname=>$r[5]
            };

          }
      }
          #}
        $entry->[REQ_CB](@list);
      }
      else {
        # throw away results
      }


    }

    elsif($cmd==CMD_GNI){
      DEBUG and say STDERR "<< GNI return from worker $entry->[REQ_WORKER]";
      my ($error, $host, $port)=unpack "l> l>/A* l>/A*", $bin;
        DEBUG and say STDERR "error $error";
        DEBUG and say STDERR "host $host";
        DEBUG and say STDERR "service Service $port";
      if($error and $entry->[REQ_ERR]){
        $entry->[REQ_ERR]($error);
      }
      elsif(!$error and $entry->[REQ_CB]){
          DEBUG and say $entry->[REQ_CB];
          $entry->[REQ_CB]($host, $port);
      }
      else {
        # Should not get here
      }
    }
    elsif($cmd==CMD_SPAWN){
      # response from template fork. Add the worker to the pool
      # 
      my $pid=unpack "l>", $bin;
      my $index=$entry->[2];  #
      DEBUG and say STDERR "SPAWN RETURN: pid $pid  index $index";
      #unshift @pool_free, $index;
      my $worker=$pairs[$index];
      $worker->[WORKER_ID]=$pid;
      # turn on the worker by clearing the busy flag
      $worker->[WORKER_BUSY]=0;
      $fd_worker_map{fileno $worker->[WORKER_READ]}=$worker;

      DEBUG and say STDERR "<< SPAWN RETURN FROM TEMPLATE $entry->[REQ_WORKER]: new worker $pid";
    }
    elsif($cmd == CMD_KILL){
      my $id=$entry->[REQ_WORKER];
      DEBUG and say STDERR "<< KILL RETURN FROM WORKER: $id : $worker->[WORKER_ID]";
      $worker->[WORKER_ID]=0;
      #@pool_free=grep $pairs[$_]->[WORKER_ID] != $id, @pool_free;
    }
    elsif($cmd ==CMD_REAP){
      # Grandchild process  checking  via template process
      my @pids=unpack "l>/l>*", $bin;

      DEBUG and say STDERR "<< REAP RETURN FROM TEMPLATE $entry->[REQ_WORKER]";
      for(@pids){
        next unless $_ >0;

        my $index=-1; # ignore template
        #Locate the pid in the worker slots
        for my $windex (1..$#pairs){
          if($pairs[$windex][WORKER_ID]==$_){
            $index=$windex;
            last;
          }
        }

        if($index>0){
          $pairs[$index][WORKER_ID]=0;
          $pairs[$index][WORKER_BUSY]=0;
          #only restart if the worker has items in its queue
          if($pairs[$index][WORKER_QUEUE]->@*){
            unshift $pairs[0][WORKER_QUEUE]->@*, [CMD_SPAWN, $i++, $index];
            $in_flight++;
          }
        }
        else {
          # ignore
        }
      }
    }

    pool_next $worker if $Shared;
}

sub _results_available {
  my $timeout=shift//0;
  DEBUG and say STDERR "CHECKING IF RESULTS AVAILABLE";
  # Check if any workers are ready to talk 
  my $bits="";
  for(@pairs){
    vec($bits,  fileno($_->[WORKER_READ]),1)=1 if $_->[WORKER_ID];
  }

  my $count=select $bits, undef, undef, $timeout;

  if($count>0){
    for(@pairs){
      if($_->[WORKER_ID] and vec($bits, fileno($_->[WORKER_READ]), 1)){
        process_results $_;
      }
    }
  }
  $count;
}

sub getaddrinfo{
  if( @_ ){
    # If arguments present, then add to the request queue

    my ($host, $port, $hints, $on_result, $on_error)=@_;

    # Format the resuest into the same as the return structures.
    my $ref=[];
    if(ref($hints) eq "ARRAY"){
      push @$hints, $host, $port;
    }
    else {
      #$hints->{host}=$host;
      $hints->{address}=$host;
      $hints->{port}=$port;
    }


    # add the request to the queue and to outstanding table
    my $worker=_get_worker;
    my $req=[CMD_GAI, $i++, $hints, $on_result, $on_error, $worker->[WORKER_ID]];
    push $worker->[WORKER_QUEUE]->@*, $req;
    $in_flight++;
    #
    monitor_workers unless $Shared;
    shrink_pool if $enable_shrink;
  }

  pool_next;
  #return true if outstanding requests
  DEBUG and say STDERR "IN FLIGHT: $in_flight";
  $in_flight;
}

sub getnameinfo{
  if(@_){
    my ($addr, $flags, $on_result, $on_error)=@_;
    my $worker=_get_worker;
    my $req=[CMD_GNI, $i++, [$addr, $flags], $on_result, $on_error, $worker->[WORKER_ID]];
    push $worker->[WORKER_QUEUE]->@*, $req;
    $in_flight++;

    monitor_workers unless $Shared;
    shrink_pool if $enable_shrink;

  }
    pool_next;
    DEBUG and say STDERR "IN FLIGHT: $in_flight";
    $in_flight;
}

sub close_pool {

  my @indexes=1..$#pairs;
  push @indexes, 0;

  #generate messages to close
  for(@indexes){
    my $worker=$pairs[$_];
    next unless $worker->[WORKER_ID];

    my $req=[CMD_KILL, $i++, [], undef, undef, $_];
    push $worker->[WORKER_QUEUE]->@*, $req;
    $in_flight++;
    pool_next;
  }
}

# Send kill signal to all workers (not template)
# This forces respawning.
sub kill_pool {
  my @indexes=1..$#pairs;
  for(@indexes){
    my $worker=$pairs[$_];
    next unless $worker->[WORKER_ID];

    kill 'KILL', $worker->[WORKER_ID];
    $worker->[WORKER_ID]=0;
    $worker->[WORKER_BUSY]=0;
  }

}

# return the parent side reading filehandles. This is what is needed for event loops
sub to_watch {
    map $_->[WORKER_READ], @pairs;
}

sub monitor_workers {
  use POSIX qw<:sys_wait_h :errno_h>; 

  # check we have a template
  my $tpid=$pairs[0][WORKER_ID];
  my $res=waitpid $tpid, WNOHANG;
  if($res==$tpid){
    # This is the non event case
    $pairs[0][WORKER_ID]=0;
    #close_pool;
    kill_pool;
  }
  elsif($res == -1 and $! == ECHILD){
    # Event loops take over the child listening.... so work around
    #
    $pairs[0][WORKER_ID]=0;
    #close_pool;
    kill_pool;
  }
  else {
    # Template still active, use it as proxy
    my @pids= map {$_->[WORKER_ID]} @pairs;
    shift @pids; #remove template from the list

    push $pairs[0][WORKER_QUEUE]->@*, [CMD_REAP, $i++, [@pids], \&_monitor_callback, undef];
    $in_flight++;
  }

  pool_next;
  $in_flight;
}

sub _monitor_callback {
  
}


sub spawn_template {
  # This should only be called when modules is first loaded, or when an
  # external force has killed the template process
  my $worker=$pairs[0];
  return $worker if $worker->[WORKER_ID];

  my $pid=fork; 
  if($pid){
    # parent
    #
    $worker->[WORKER_ID]=$pid;
    $fd_worker_map{fileno $worker->[WORKER_READ]}=$worker;
    #push @pool_free, 0;
    $worker;

  }
  else {
    # child
    # exec an tell the process which fileno we want to communicate on
    close $worker->[WORKER_READ];
    close $worker->[WORKER_WRITE];
    my @ins=map {fileno $_->[WORKER_CREAD]} @pairs;  # Child read end
    my @outs=map {fileno $_->[WORKER_CWRITE]} @pairs; # Child write end
    DEBUG and say STDERR "Create worker: exec with ins: @ins";
    DEBUG and say STDERR "Create worker: exec with outs: @outs";
    my $file=__FILE__; 
    $file=~s|\.pm|/Worker.pm|;
    local $"=",";
    exec $^X, $file, "--in", "@ins", "--out", "@outs";
  }
}

sub shrink_pool {
  # work backwards and send a kill message to any non busy workers
  my $template_worker=spawn_template(); #ensure template exists
  for(reverse(@pairs)){
    next if $_== $template_worker;
    next if $_->[WORKER_QUEUE]->@*;
    next unless $_->[WORKER_ID];

    # send a kill message to any un needed workers
    my $req=[CMD_KILL, $i++, [], undef, undef, $_];
    push $_->[WORKER_QUEUE]->@*, $req;
    $in_flight++;
  }
}

sub cleanup {
#say STDERR "END HERE";
  #kill_pool;
  ################################
  # for(@pairs){                 #
  #   close $_->[WORKER_CREAD];  #
  #   close $_->[WORKER_CWRITE]; #
  # }                            #
  ################################
  # The template

  my $tpid=$pairs[0][WORKER_ID];
  #say STDERR "Template pid: ", $tpid;
  #say STDERR 
  kill 'KILL', $tpid;
  my $res=waitpid $tpid, 0;#, WNOHANG;
  if($res==$tpid){
    #say STDERR "TEMPLATE KILLED";
    # This is the non event case
    #$pairs[0][WORKER_ID]=0;
    #close_pool;
    kill_pool;
  }
  else {
    #say STDERR "RES: $res";
  }

}

1;
