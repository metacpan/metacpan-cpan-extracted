package RPC::Simple::Server;

use strict;
use vars qw($VERSION @ISA @EXPORT %pidTab %deadChildren %fhTab $verbose
           @buddies);

# %fhTab is a hash of fileno of file descriptors opened for reading the 
# STDOUT of children. If contains the ref of the process objects controlling
# this child.

use Fcntl ;

use IO::Socket ;
use IO::Select ;

use RPC::Simple::ObjectHandler ;

require Exporter;

@ISA = qw(Exporter);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(mainLoop chilDeath goodGuy registerChild unregisterChild);

( $VERSION ) = '$Revision: 1.8 $ ' =~ /\$Revision:\s+([^\s]+)/;

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

@buddies = ('127.0.0.1') ; # I am a good guy 
our $verbose = 0;

sub childDeath
  {
    # not an object method
    # DO NOT call Tk code in signal handler or in called functions
    my $pid = wait ;
    if (defined $pidTab{$pid})
      {
        print "child pid $pid died ($?)\n";
        $deadChildren{$pid} = [$pidTab{$pid}, $?] ;
        delete $pidTab{$pid} ;
      }
    elsif (exists $pidTab{$pid})
      {
        print "old news: child died ($pid)\n" ;
      }
    else
      {
        print "Unknown child died ($pid)\n" ;
      }
    # may not be needed anymore according to Tom C TBD
  }

sub logmsg { print "$0 $$: @_ at ", scalar localtime, "\n" }

sub mainLoop
  {
    my $port = shift || 7810 ;
    $verbose = shift || 0 ; 

    my $clientOpen = 0 ;
    
    #create listening socket
    my $server = IO::Socket::INET -> new (Listen => 5,
                                          LocalAddr => 'localhost',
                                          LocalPort => $port,
                                          Proto => 'tcp'
                                         ) ;
    
    die "Can't create listening socket $!\n" unless defined $server ;

    my $serverNb = $server -> fileno ;

    logmsg "server started on port $port";
    
    # my $sclient = register_io_client
    #   ([],'rw', SERVER ,
    #    \&acceptSocket,\&acceptSocket,\&acceptSocket )
    #   || die "socket server not registered\n";
    
    # set_maximum_inactive_server_time(6000) ; # need a handler TBD
    
    # print "listening to socket registered\n";
    
    # register_interval_client([],5,sub{ print ".";}) ;
    # start_server() ;

    # create select object 
    my $s = IO::Select -> new() ;
    $s -> add ($server) ; # add listening socket 
    
    while (1)
      { 
        my ($toRead,$dummy,$shutThem) = IO::Select -> 
          select ($s ,undef, $s, 2) ;

        foreach my $fh (@$shutThem)
          {
            # close fh on errors (usually dead children, or closed client)
            if ($serverNb == $fh->fileno)
              {
                my $nb = $fh->fileno ;
                print "closing fno $nb (on error)\n" if $verbose ;
                my ($theObj,$theMeth) = @{$fhTab{$nb}} ;
                $theObj-> close(1) ;
                delete $fhTab{$nb} ;
              }
          }

        foreach my $fh (@$toRead)
          {
            if ($serverNb == $fh->fileno)
              {
                # reading server socket 
                my $ref = RPC::Simple::Server -> new($server,$s) ;
                next unless defined $ref ;
                my $nb = $ref->getFileno ;
                $fhTab{$nb} = [ $ref , 'readClient' ] ;
              }
            else
              {
                my $nb = $fh->fileno ;
                print "reading fno $nb\n" if $verbose ;
                my ($theObj,$theMeth) = @{$fhTab{$nb}} ;
                unless ($theObj-> $theMeth(1) )
                  {
                    print "closing fno $nb (error after reading)\n" 
                      if $verbose ;
                    my ($theObj,$theMeth) = @{$fhTab{$nb}} ;
                    $theObj-> close() ;
                    delete $fhTab{$nb} ;
                  } 
              }
	  }


        &checkDead ;
      }
  }

sub registerChild
  {
	my $object=shift ;
	my $pid = shift ;
	$pidTab{$pid}=$object;
  }

sub unregisterChild
  {
	my $pid = shift ;
	print "Child $pid unregistered\n";
	undef $pidTab{$pid};
	delete $deadChildren{$pid} ;
  }


sub close
  { 
    my $self= shift ;

    print "closing connection\n";
    $self->{selector}->remove($self->{mySocket}) ;
    #$self->{mySocket}->close ;
    shutdown($self->{mySocket},2) ;
  }

sub readClient
  { 
    my $self= shift ;

    #	my ($obj,$key,$handle) = @_ ;
    print "readClient called\n" if $verbose ;

    return 0 if ($self->{mySocket}->eof) ;

    my @codeTab = () ;

    my $code = '' ;
    my $line ;
    my $codeEnd = 1 ;

    while ( $line = $self->{mySocket}->getline or not $codeEnd )
      {
        next unless defined $line ;
        
        print "-> ",$line  if $verbose ;
        $code .= $line ;
        if ($line =~ /#end$/
           )
          {
            push @codeTab, $code ;
            $code = '' ;
            $codeEnd = 1 ;
          }
        if ($line =~ /#begin$/
           )
          {
            $codeEnd = 0 ;
          }
      }

    foreach $code (@codeTab)
      {
        my ($args,$method,$reqId,$handle,$objectName) ;
        # untaint $code and place it in the safe

        if ($code =~ m/(.+)/s )
          {
            $code = $1 ;
            print "code is laundered\n" if $verbose ;
          } 

        eval($code) ;

        if ($@)
          {
            print "failed eval ($@) of :\n",$code,"end evaled code\n"  ; 
          }
        else
          {
            print "Call $method \n" if $verbose ;

            if ($method eq 'new')
              {
                # create new object, call-back always required
                $self->{handleTab}{$handle} = RPC::Simple::ObjectHandler
                  -> new ($self,$objectName, $handle, $args, $reqId) ;
              }
            elsif ($method eq 'destroy')
              {
                $self->{handleTab}{$handle}->destroy ;
                delete $self->{handleTab}{$handle} ;
              }
            else
              {
                $self->{handleTab}{$handle} -> 
                  remoteCall($reqId,$method,$args) ;
              }
          }
      }
    print "readClient finished\n" if $verbose ;
    return 1 ;
  }

sub dummy { print "Dummy function called\n"; }

sub writeSock
  {
    my $self=shift;

    my $handle = shift ;        # index of RpcClient
    my $method = shift ;
    my $reqId = shift ;
    my $param = shift  ;        # usually an array ref
    my $objectName = shift ;    # optionnal
    
    my $refs = [$param,$method,$reqId, $handle ] ;
    my $names = ['args','method','reqId','handle',] ;
    
    if (defined $objectName)
      {
        push @$refs, $objectName ;
        push @$names, 'objectName' ;
      }
    
    my $d = Data::Dumper->new ( $refs, $names ) ;
    my $paramStr = "#begin\n".$d->Dumpxs."#end\n" ; 
    #my $str = sprintf("%6d",length($paramStr)) . $paramStr ;
    my $str = $paramStr ;
    print "$paramStr\n" if $verbose ;
    no strict 'refs' ;
    my $val;
    eval
      {
        $val = $self->{mySocket}->send($str,0) ;
      };
    warn "send failed $!\n" unless defined $val ;
    print "$val bytes sent\n" if $verbose ;
  }

sub new
  {
    my $type = shift ;
    my $server = shift ;
    my $selector = shift ;
    # Optional parameters which can be used to tell server not
    # to accept the new connection but let the calling routine
    # do that for us.  If these parameters are used, you may
    # need to override the mainLoop subroutine.
    my $socket = shift || undef;
    my $manual_accept = shift || 0;
    my $self = {} ;

    $self->{'server'} = $server ;
    $self->{'selector'} = $selector ;

    bless $self, $type;

    if ($manual_accept && not defined $socket)
      {
        print "socket required for manual accept mode\n" ;
        undef $self ;
        return undef ;
      }


    my $iaddr;
    unless ($manual_accept)
      {
        print "Accepting connection\n" ;
        ($socket, $iaddr) = $server -> accept() ; # blocking call
      }

    unless (defined $socket)
      {
        print "accept failed $!\n" ;
        undef $self ;
        return undef ;
      }

    print "Connection accepted\n";

    my $name = gethostbyaddr($socket->peeraddr,AF_INET) ;
    my $ipadr = $socket -> peerhost ;
    my $ok = 0 ;
    foreach (@buddies)
      {
        print "Comparing $ipadr with $_\n";
        if ($ipadr eq $_)
          {
            $ok = 1 ;
            last;
          }
      }

    unless ($ok)
      {
        logmsg "connection from $name refused [ $ipadr ]";
        $socket->close ;
        undef $self ;
        return undef ;
      }

    $self->{mySocket} = $socket ;
    $selector->add($socket) unless($manual_accept) ;

    # put the socket in non-blocking mode
    fcntl($socket,F_SETFL, O_NDELAY)  || die "fcntl failed $!\n";

    logmsg "connection from $name [ $ipadr ] ";
    return $self ;
  }


# register an object/method to call 
sub setMask
  {
    my $obj = shift ;
    my $method = shift ;
    my $nb = shift ;
    $fhTab{$nb} = [ $obj , $method ] ;
  }

sub resetMask
  {
    my $nb = shift ;
    delete $fhTab{$nb} ;
  }

sub checkDead
  {
    if (scalar  %deadChildren )
      {
        my $pid ;
        foreach $pid (keys %deadChildren)
          {
            my ($ref,$out) = @{$deadChildren{$pid}};
            $ref->processOver($out) ;
            delete $deadChildren{$pid} ;
          }
      }
  }

sub getFileno
  {
    my $self = shift ;
    return $self->{mySocket}->fileno ;
  }

sub goodGuy
  {
    my $good = shift ;

    if ($good =~ /^[\d\.]+$/)
      {
        push @buddies , $good ;
      }
    else
      {
        my (@addrs) = (gethostbyname($good))[4] ;
        my $addr = join(".", unpack('C4', $addrs[0])) ;
        push @buddies, $addr ;
      }
  }

1;
__END__

# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

RPC::Simple::Server - Perl class to use in the RPC server script.

=head1 SYNOPSIS

  use RPC::Simple::Server;

 my $server_pid = &spawn ;

=head1 DESCRIPTION

Generic server class. The mainLoop function will instantiate one server object
for each connection request.

Server also provides functions (childDeath) to monitor children processes.

=head1 Exported static functions

=head2 mainLoop 

To be called at the end of the main program.
This function will perform the select loop, and call relevant server objects.

=head2 goodGuy([ipaddress|host_name])

Declare the IP address or the host name as a buddy. Connection from 
buddies will be accepted. localhost is always considered as a good guy.

=head2 registerChild($object_ref, $pid)

Register process $pid as a process to be monitored by server.
$object_ref is the process manager of this child.
$object_ref::process_over will be called back when (or shortly after) 
the child dies.

=head2 unregisterChild($pid)

unregister process $pid. Does not call-back the process manager.

=head2 childDeath

Static function called when a child dies. $SIG{CHLD} must be set to 
\&childDeath by the user. 

=head1 CONSTRUCTOR

Called by mainloop. Construct a server. Currently only one server is 
supported.

=head1 METHODS

=head2 acceptSocket

called by new. By default, accepts only connection from localhost (127.0.0.1).

=head2 writeSock(index_of_agent, method, reqId, param, [objectName ])

Called by Object handler to send data back to Agent.

param: array_ref of parameters passed to the call-back function.

=head2 readClient

Read the client's socket. Execute the code passed through the socket and
call the relevant object handlers.

returns 0 if the socket is closed.

=head2 close

Close the connection.

=head2 setMask(object,method, file_number)

Function used by any object controlling a child process. Register the object
and the method to call back when reading from the passed file descriptor.

file_number is as given by fileno

=head2 resetMask

To be called when the child process is dead.

=head2 getFileno

Returns the fileno of the client's socket.

=head1 CAVEATS

Some function are provided to handle remote processes. These functions are
not yet tested. They may not stay in this class either.

=head1 AUTHORS

    Current Maintainer
    Clint Edwards <cedwards@mcclatchyinteractive.com>

    Original
    Dominique Dumont, <Dominique_Dumont@grenoble.hp.com>

=head1 SEE ALSO

perl(1).

=cut

