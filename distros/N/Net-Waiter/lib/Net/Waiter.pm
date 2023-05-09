##############################################################################
#
#  Net::Waiter concise INET socket server
#  (c) Vladi Belperchinov-Shabanski "Cade" 2015-2022
#  http://cade.noxrun.com
#        <cade@noxrun.com> <cade@bis.bg> <cade@cpan.org>
#
#  GPL
#
##############################################################################
package Net::Waiter;
use strict;
use POSIX ":sys_wait_h";
use IO::Socket::INET;
use Sys::SigAction qw( set_sig_handler );
use IPC::Shareable;
use Time::HiRes qw( sleep );

our $VERSION = '1.05';

##############################################################################
            
sub new
{
  my $class = shift;
  $class = ref( $class ) || $class;
  
  my %opt = @_;
  
  my $self = { 
               PORT    => $opt{ 'PORT'    }, # which port to listen on
               PREFORK => $opt{ 'PREFORK' }, # how many preforked processes
               MAXFORK => $opt{ 'MAXFORK' }, # max count of preforked processes
               NOFORK  => $opt{ 'NOFORK'  }, # foreground process
    
               SSL     => $opt{ 'SSL'     }, # use SSL
               OPT     => \%opt,
             };

  if( $opt{ 'SSL' } )
    {
    $self->{ 'SSL_OPTS' } = {};
    while( my ( $k, $v ) = each %opt )
      {
      next unless $k =~ /^SSL_/;
      $self->{ 'SSL_OPTS' }{ $k } = $v;
      }
    }

  my $pf = $self->{ 'PREFORK' };
  my $mf = $self->{ 'MAXFORK' };
  if( $pf < 0 )
    {
    # if PREFORK is negative, it will be absolute prefork and maxfork count
    $self->{ 'PREFORK' } = abs( $pf );
    $self->{ 'MAXFORK' } = abs( $pf ) unless $mf > 0;
    }
             
  bless $self, $class;
  return $self;
}

##############################################################################

sub run
{
  my $self = shift;

  $self->{ 'PARENT_PID' } = $$;

  if( $self->ssl_in_use() )
    {
    eval { require IO::Socket::SSL; };
    die "SSL not available: $@" if $@;
    };

  $SIG{ 'INT'   } = sub { $self->break_main_loop(); };
  $SIG{ 'CHLD'  } = sub { $self->__sig_child();     };
  $SIG{ 'USR1'  } = sub { $self->__sig_usr1();      };
  $SIG{ 'USR2'  } = sub { $self->__sig_usr2();      };
  $SIG{ 'RTMIN' } = sub { $self->__sig_kid_idle()   };
  $SIG{ 'RTMAX' } = sub { $self->__sig_kid_busy()   };

  my $server_socket;

  if( $self->ssl_in_use() )
    {
    my %ssl_opts = %{ $self->{ 'SSL_OPTS' } };
    $ssl_opts{ 'SSL_error_trap'  } = sub { shift; $self->on_ssl_error( shift() ); },

    $server_socket = IO::Socket::SSL->new(  
                                         Proto     => 'tcp',
                                         LocalPort => $self->{ 'PORT' },
                                         Listen    => 128,
                                         ReuseAddr => 1,

                                         %ssl_opts,
                                         );

    }
  else
    {
    $server_socket = IO::Socket::INET->new( 
                                         Proto     => 'tcp',
                                         LocalPort => $self->{ 'PORT' },
                                         Listen    => 128,
                                         ReuseAddr => 1,
                                         );
    }

  if( ! $server_socket )
    {
    # cannot open server port
    return 100;
    }
  else
    {
    binmode( $server_socket );
    $self->{ 'SERVER_SOCKET' } = $server_socket;
    $self->on_listen_ok();
    }

  tie my %SHA, 'IPC::Shareable', { size => 64*1024 };
  $self->{ 'SHA' } = \%SHA;

  while(4)
    {
    last if $self->{ 'BREAK_MAIN_LOOP' };
    my $bk = $self->get_busy_kids_count();
 
    if( $self->{ 'PREFORK' } > 0 )
      {
      $self->__run_prefork( $server_socket );
      }
    else
      {  
      $self->__run_forking( $server_socket );
      }
    }

  tied( %{ $self->{ 'SHA' } } )->remove();

  $self->on_server_close( $server_socket );
  close( $server_socket );

  print STDERR Dumper( $self->{ 'STATS' } );

  return 0;
}

sub __run_forking
{
  my $self          = shift;
  my $server_socket = shift;

  my $client_socket = $server_socket->accept();
  if( ! $client_socket )
    {
    $self->on_accept_error();
    return;
    }

  binmode( $client_socket );
  $self->{ 'CLIENT_SOCKET' } = $client_socket;

  my $peerhost = $client_socket->peerhost();
  my $peerport = $client_socket->peerport();
  my $sockhost = $client_socket->sockhost();
  my $sockport = $client_socket->sockport();

  $self->on_accept_ok( $client_socket );
  
  my $mf = $self->{ 'MAXFORK' };
  if( $mf > 0 and $self->{ 'KIDS' } >= $mf )
    {
    $self->on_maxforked( $client_socket );
    $self->on_close( $client_socket );
    $client_socket->close();
    return;
    }

  my $pid;
  if( ! $self->{ 'NOFORK' } )
    {
    $pid = fork();
    if( ! defined $pid )
      {
      die "fatal: fork failed: $!";
      }
    if( $pid )
      {
      $self->{ 'KIDS' }++;
      $self->{ 'KID_PIDS' }{ $pid } = 1;
      $self->on_fork_ok( $pid );
      $client_socket->close();
      next;
      }
    }
  # --------- kid here ---------
  delete $self->{ 'SERVER_SOCKET' };

  # reinstall signal handlers in the kid
  $SIG{ 'INT'  } = 'DEFAULT';
  $SIG{ 'CHLD' } = 'DEFAULT';
  $SIG{ 'USR1' } = 'DEFAULT';
  $SIG{ 'USR2' } = 'DEFAULT';

  srand();

  $self->{ 'CHILD' } = 1;

  $client_socket->autoflush( 1 );
  $self->im_busy();
  $self->on_process( $client_socket );
  $self->on_close( $client_socket );
  $client_socket->close();
  $self->im_idle();
  
  if( ! $self->{ 'NOFORK' } )
    {
    exit();
    }
  # ------- child ends here -------
}

sub __run_prefork
{
  my $self          = shift;
  my $server_socket = shift;

  my $prefork_count = $self->{ 'PREFORK' };

  while(4)
    {
    last if $self->{ 'BREAK_MAIN_LOOP' };
 
    my $kk = $self->{ 'KIDS' }; # kids k'ount ;)
    my $bk = $self->get_busy_kids_count();
    my $ik = $kk - $bk; # idle kids count

    $self->{ 'STATS' }{ 'IDLE FREQ' }{ $ik }++ if $bk > 0;
   
    my $tk = $prefork_count;
    #$tk = $kk + $prefork_count / 2 if $kk > $prefork_count and $ik < ( 1 + $prefork_count / 10 );
    $tk = $kk + $prefork_count if $ik < ( 1 + $kk / 10 );

    my $mf = $self->{ 'MAXFORK' };
    $tk = $mf if $mf > 0 and $tk > $mf; # MAXFORK cap
    
    #while( $self->{ 'KIDS' } < $prefork_count || ( $ik < ( 1 + $prefork_count / 10 ) and $self->{ 'KIDS' } < $kk + $prefork_count / 2 ) )
    while( $self->{ 'KIDS' } < $tk )
      {
      last if $self->{ 'KIDS' } >= 1024;
      
      my $pid;
      $pid = fork();
      if( ! defined $pid )
        {
        die "fatal: fork failed: $!";
        }
      if( $pid )
        {
        $self->{ 'KIDS' }++;
        $self->{ 'KID_PIDS' }{ $pid } = 1;
        $self->on_fork_ok( $pid );
        $self->{ 'STATS' }{ 'SPAWNS' }++;
        }
      else
        {
        # --------- child here ---------
        $self->{ 'CHILD'  } = 1;
        $self->{ 'SPTIME' } = time();
        delete $self->{ 'SERVER_SOCKET' };
        $self->im_idle();

        while(4)
          {
          last if $self->{ 'BREAK_MAIN_LOOP' };
          exit unless $self->__run_preforked_child( $server_socket );
          my $kid_idle = $self->{ 'LPTIME' } > 0 ? time() - $self->{ 'LPTIME' } : - ( time() - $self->{ 'SPTIME' } );
          if( $self->{ 'LPTIME' } > 0 and $kid_idle > 110 )
            {
            exit;
            }
          }
        exit;  
        # ------- child ends here -------
        }  
#print STDERR "--ESTIMATE-- $tk = $kk + $prefork_count if $ik < ( 1 + $kk / 10 );\n";    
      }
    
#print STDERR "sleeping for 4 secs...........................$self->{ 'KIDS' } / $bk...........\n" . Dumper( $self->{ 'SHA' } );
    sleep(6);
    }
}

sub __run_preforked_child
{
  my $self          = shift;
  my $server_socket = shift;

  if( ! socket_can_read( $server_socket, 4 ) )
    {
    #print STDERR "-----ERR------ ACCEPT $$ RES >>> $!\n\n\n";
    $self->on_prefork_child_idle();
    return '0E0';
    }

  my $client_socket = $server_socket->accept();
#print STDERR "-----OK------ ACCEPT $$ RES $client_socket >>> $!\n";

  binmode( $client_socket );
  $self->{ 'CLIENT_SOCKET' } = $client_socket;

  my $peerhost = $client_socket->peerhost();
  my $peerport = $client_socket->peerport();
  my $sockhost = $client_socket->sockhost();
  my $sockport = $client_socket->sockport();

  $self->on_accept_ok( $client_socket );

  # reinstall signal handlers in the kid
  $SIG{ 'INT'   } = 'DEFAULT';
  $SIG{ 'CHLD'  } = 'DEFAULT';
  $SIG{ 'USR1'  } = 'DEFAULT';
  $SIG{ 'USR2'  } = 'DEFAULT';
  $SIG{ 'RTMIN' } = 'DEFAULT';
  $SIG{ 'RTMAX' } = 'DEFAULT';

  srand();

  $self->{ 'BUSY_COUNT' }++;
  $self->im_busy();
  $client_socket->autoflush( 1 );
  my $res = $self->on_process( $client_socket );
  $self->on_close( $client_socket );
  $client_socket->close();
  $self->im_idle();

  $self->{ 'LPTIME' } = time(); # last processing time
  
#print STDERR "-----------------------running preforked kid [$$] res [$res]\n";
  return $res;
}

##############################################################################

sub get_server_socket
{
  my $self = shift;
  
  return exists $self->{ 'SERVER_SOCKET' } ? $self->{ 'SERVER_SOCKET' } : undef;
}

sub get_client_socket
{
  my $self = shift;
  
  return exists $self->{ 'CLIENT_SOCKET' } ? $self->{ 'CLIENT_SOCKET' } : undef;
}

sub get_busy_kids_count
{
  my $self = shift;
  
  return scalar( grep { substr( $_, 0, 1 ) eq  '*' } values %{ $self->{ 'SHA' } } ) || 0;
}

sub get_parent_pid
{
  my $self = shift;
  
  return $self->{ 'PARENT_PID' };
}

sub im_busy
{
  my $self = shift;
  
  return $self->__im_in_state( '*' );
}

sub im_idle
{
  my $self = shift;
  
  return $self->__im_in_state( '-' );
}

sub __im_in_state
{
  my $self  =    shift;
  my $state = uc shift;

  my $ppid = $self->get_parent_pid();
  return 0 if $ppid == $$; # states are available only for kids

  tied( %{ $self->{ 'SHA' } } )->lock();
  $self->{ 'SHA' }{ $$ } = $state . "/" . $self->{ 'BUSY_COUNT' };
  tied( %{ $self->{ 'SHA' } } )->unlock();
  
  return kill( 'RTMIN', $ppid ) if $state eq '-';
  return kill( 'RTMAX', $ppid ) if $state eq '*';
  return 0;
}

##############################################################################

sub break_main_loop
{
  my $self = shift;
  
  $self->{ 'BREAK_MAIN_LOOP' } = 1;
}

sub ssl_in_use
{
  my $self = shift;
  
  return $self->{ 'SSL' };
}

sub is_child
{
  my $self = shift;
  
  return $self->{ 'CHILD' };
}

sub __sig_child
{
  my $self = shift;

  my $child_pid;
  while( ( $child_pid = waitpid( -1, WNOHANG ) ) > 0 )
    {
    tied( %{ $self->{ 'SHA' } } )->lock();
    delete $self->{ 'SHA' }{ $child_pid };
    tied( %{ $self->{ 'SHA' } } )->unlock();
    
    $self->{ 'KIDS' }--;
    delete $self->{ 'KID_PIDS' }{ $child_pid };
    $self->on_sig_child( $child_pid );
    }
  $SIG{ 'CHLD' } = sub { $self->__sig_child(); };
}

sub __sig_usr1
{
  my $self = shift;

  $self->on_sig_usr1();
  $SIG{ 'USR1' } = sub { $self->__sig_usr1();  };
}

sub __sig_usr2
{
  my $self = shift;

  $self->on_sig_usr2();
  $SIG{ 'USR2' } = sub { $self->__sig_usr2();  };
}

use Data::Dumper;

sub __sig_kid_idle
{
  my $self = shift;

  $self->on_sig_kid_idle();
}

sub __sig_kid_busy
{
  my $self = shift;

  $self->on_sig_kid_busy();
}

##############################################################################

sub on_listen_ok
{
}

sub on_accept_error
{
}

sub on_accept_ok
{
}

sub on_fork_ok
{
}

# called when connection is accepted and processing requested on socket data
sub on_process
{
}

# called on preforked childs, when accept timeouts
sub on_prefork_child_idle
{
}

sub on_maxforked
{
}

sub on_close
{
}

sub on_server_close
{
}

sub on_ssl_error
{
}

sub on_sig_child
{
}

sub on_sig_usr1
{
}

sub on_sig_usr2
{
}

sub on_sig_kid_idle
{
}

sub on_sig_kid_busy
{
}


##############################################################################

# backported from Data::Tools::Socket to reduce dependency
# https://metacpan.org/pod/Data::Tools
# https://github.com/cade-vs/perl-data-tools

sub socket_can_write
{
  my $sock    = shift;
  my $timeout = shift;

  my $win;
  vec( $win, fileno( $sock ), 1 ) = 1;
  return select( undef, $win, undef, $timeout ) > 0;
}

sub socket_can_read
{
  my $sock    = shift;
  my $timeout = shift;

  my $rin;
  vec( $rin, fileno( $sock ), 1 ) = 1;
  return select( $rin, undef, undef, $timeout ) > 0;
}

##############################################################################

=pod


=head1 NAME

  Net::Waiter compact INET socket server

=head1 SYNOPSIS

  package MyWaiter;
  use strict;
  use parent qw( Net::Waiter );

  sub on_accept_ok
  {
    my $self = shift;
    my $sock = shift;
    my $peerhost = $sock->peerhost();
    print "client connected from $peerhost\n";
  }

  sub on_process
  {
    my $self = shift;
    my $sock = shift;
    print $sock "hello world\n";
  }

  #--------------------------------------------------

  packgage main;
  use strict;
  use MyWaiter;

  my $server = MyWaiter->new( PORT => 9123 );
  my $res = $server->run();
  print "waiter result: $res\n"; # 0 is ok, >0 is error

=head1 DESCRIPTION

Net::Waiter is a base class which implements compact INET network socket server.  

=head1 METHODS/FUNCTIONS

=head2 new( OPTION => VALUE, ... )

Creates new Net::Waiter object and sets its options:

   PORT    => 9123, # which port to listen on
   PREFORK =>    8, # how many preforked processes
   MAXFORK =>   32, # max count of preforked processes
   NOFORK  =>    0, # if 1 will not fork, only single client will be accepted
   SSL     =>    1, # use SSL

if PREFORK is negative, the absolute value will be used both for PREFORK and
MAXFORK counts.

if SSL is enabled then additional IO::Socket::SSL options can be added:

   SSL_cert_file => 'cert.pem',
   SSL_key_file  => 'key.pem', 
   SSL_ca_file   => 'ca.pem',

for further details, check IO::Socket::SSL docs.   
   
=head2 run()

This executes server main loop. It will create new server socket, set
options (listen port, ssl options, etc.) then fork and call handlers along
the way.

Run returns exit code:

    0 -- ok
  100 -- cannot create server listen socket

=head2 break_main_loop()

Breaks main server loop. Calling break_main_loop() is possible from parent 
server process handler functions (see HANDLER FUNCTIONS below) but it will 
not break the main loop immediately. It will just rise flag which will stop 
when control is returned to the next server loop.

=head2 ssl_in_use()

Returns true (1) if current setup uses SSL (useful mostly inside handlers).

=head2 is_child()

Returns true (1) if this process is client/child process (useful mostly inside handlers).

=head2 get_server_socket()

Returns server (listening) socket object. Valid in parent only, otherwise returns undef.

=head2 get_client_socket()

Returns client (connected) socket object. Valid in kids only, otherwise returns undef.

=head1 HANDLER FUNCTIONS

All of the following methods are empty in the base implementation and are
expected to be reimplemented. The list order below is chronological but the
most important function which must be reimplemented is on_process().

=head2 on_listen_ok()

Called when listen socket is ready but no connection is accepted yet.

=head2 on_accept_error()

Called if there is an error with accepting connections.

=head2 on_accept_ok( $client_socket )

Called when new connection is accepted without error.

=head2 on_fork_ok( $child_pid )

Called when new process is forked. This will be executed inside the server
(parent) process and will have forked (child) process pid as 1st argument.

=head2 on_process( $client_socket )

Called when socket is ready to be used. This is the place where the actual
work must be done.

=head2 on_maxforked( $client_socket )

Called if client socket is accepted but MAXFORK count reached. This can be
used to advise the situation over the socket and will be called right before
client socket close.

note: this handler is only used for FORKING server. preforked servers will
not accept the socket at all if MAXFORK has been reached. the reason is that
forking server may release child process during the accept() call.

=head2 on_close( $client_socket )

Called right before client socket will be closed. And after on_process().
Will be called and when MAXFORK has been reached also.

=head2 on_server_close()

Called right before server (listen) socket is closed (i.e. when main loop 
is interrupted). This is the last handler to be called on each run().

=head2 on_ssl_error( $ssl_handshake_error )

Called when SSL handshake or other error encountered. Gets error message as 1st argument.

=head2 on_sig_child( $child_pid )

Called when child/client process finishes. It executes only inside the parent/server
process and gets child pid as 1st argument.

=head2 on_sig_usr1()

Called when server or forked (child) process receives USR1 signal.
(is_child() can be used here)

=head2 on_sig_usr2()

Called when server or forked (child) process receives USR2 signal.
(is_child() can be used here)
                                                                                        
=head1 TODO

  (more docs)

=head1 REQUIRED MODULES

Net::Waiter is designed to be compact and self sufficient. 
However it uses some 3rd party modules:

  * IO::Socket::INET

=head1 DEMO

For demo server check 'demo' directory in the source tar package or at the
GITHUB repository:

  https://github.com/cade-vs/perl-net-waiter/tree/master/demo  

=head1 GITHUB REPOSITORY

  https://github.com/cade-vs/perl-net-waiter

  git@github.com:cade-vs/perl-net-waiter.git

  git clone git://github.com/cade-vs/perl-net-waiter.git
  
=head1 AUTHOR

  Vladi Belperchinov-Shabanski "Cade"

  <cade@biscom.net> <cade@cpan.org> <cade@datamax.bg>

  http://cade.datamax.bg

=cut

##############################################################################
1;
