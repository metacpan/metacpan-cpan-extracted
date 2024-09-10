##############################################################################
#
#  Net::Waiter concise INET socket server
#  (c) Vladi Belperchinov-Shabanski "Cade" 2015-2024
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
use Data::Dumper;
use Errno;

our $VERSION = '1.14';

$Data::Dumper::Terse = 1;
 
##############################################################################
            
sub new
{
  my $class = shift;
  $class = ref( $class ) || $class;
  
  my %opt = @_;
  
  my $self = { 
               PORT    => $opt{ 'PORT'    },         # which port to listen on
               PREFORK => $opt{ 'PREFORK' },         # how many preforked processes, 0 means forking server
               MAXFORK => $opt{ 'MAXFORK' } || 1024, # max count of forked processes
               NOFORK  => $opt{ 'NOFORK'  },         # foreground process
               TIMEOUT => $opt{ 'TIMEOUT' } || 4,    # timeout for accept(), default 4 seconds

               PX_IDLE => $opt{ 'PX_IDLE' } || 31,   # process exit idle, used in preforked processes
               
               PROP_SIGUSR => $opt{ 'PROP_SIGUSR' },

               DEBUG   => $opt{ 'DEBUG'   }, # debug level, true to enable or positive number for debug level
    
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

  # timeout cap
  $self->{ 'TIMEOUT' } =    1 if $self->{ 'TIMEOUT' } <    1; # avoid busyloop
  $self->{ 'TIMEOUT' } = 3600 if $self->{ 'TIMEOUT' } > 3600; # 1 hour max should be enough :)

  $self->{ 'PX_IDLE' } = 31 if $self->{ 'PX_IDLE' } < 1;
             
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
  $SIG{ 'TERM'  } = sub { $self->break_main_loop(); };
  $SIG{ 'CHLD'  } = sub { $self->__sig_child();     };
  $SIG{ 'HUP'   } = sub { $self->__sig_hup();       };
  $SIG{ 'USR1'  } = sub { $self->__sig_usr1();      };
  $SIG{ 'USR2'  } = sub { $self->__sig_usr2();      };
  $SIG{ 'RTMIN' } = sub { $self->__sig_kid_idle()   };
  $SIG{ 'RTMAX' } = sub { $self->__sig_kid_busy()   };

  my $server_socket;

  my $sock_pkg;
  my %sock_opts;
  if( $self->ssl_in_use() )
    {
    my %sock_opts = %{ $self->{ 'SSL_OPTS' } };
    $sock_opts{ 'SSL_error_trap'  } = sub { shift; $self->on_ssl_error( shift() ); },
    $sock_pkg = 'IO::Socket::SSL';
    }
  else
    {
    $sock_pkg = 'IO::Socket::INET';
    }

  $server_socket = $sock_pkg->new(  
                                       Proto     => 'tcp',
                                       LocalPort => $self->{ 'PORT' },
                                       Listen    => 128,
                                       ReuseAddr => 1,
                                       Blocking  => 0,

                                       %sock_opts,
                                       );

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


  my $tm = time();
  my $sha_key = $self->{ 'SHA_KEY' } = "$0.$$.$tm";
  $self->{ 'SHA' } = new IPC::Shareable key => $sha_key, size => 256*1024, mode => 0600, create => 1 or die "fatal: cannot create shared memory segment\n";

  while(4)
    {
    last if $self->{ 'BREAK_MAIN_LOOP' };
 
    if( $self->{ 'PREFORK' } > 0 )
      {
      $self->__run_prefork( $server_socket );
      sleep(4); # will be interrupted by busy/free signals
      }
    else
      {  
      $self->__run_forking( $server_socket );
      # no need for sleep since, select/accept will block for a while (4 sec)
      }

    $self->__sha_lock_ro( 'MASTER STATS UPDATE' );

    $self->{ 'KIDS_BUSY'   } = 0;
    for my $cpid ( keys %{ $self->{ 'SHA' }{ 'PIDS' } } )
      {
      next unless $cpid > 0;
      if( ! exists $self->{ 'KID_PIDS' }{ $cpid } )
        {
        delete $self->{ 'SHA' }{ 'PIDS' }{ $cpid };
        }
      else
        {
        my $v = $self->{ 'SHA' }{ 'PIDS' }{ $cpid };
        my ( $b, $c ) = split /:/, $v;
        $self->{ 'KIDS_BUSY'  }++ if $b eq '*';
        }  
      }
    $self->{ 'STAT' }{ 'BUSY_COUNT' } = $self->{ 'SHA' }{ 'STAT' }{ 'BUSY_COUNT' };

    $self->__sha_unlock( 'MASTER STATS UPDATE' );

    if( $self->{ 'DEBUG' } )
      {
      require Data::Dumper;  
      $Data::Dumper::Sortkeys++;
      my $tf = $self->{ 'FORKS' };
      my $kk = $self->{ 'KIDS'  };
      my $bk = $self->{ 'KIDS_BUSY' };
      }

    }

  $self->propagate_signal( 'TERM' );

  tied( %{ $self->{ 'SHA' } } )->remove();
  delete $self->{ 'SHA' };

  $self->on_server_close( $server_socket );
  close( $server_socket );

  return 0;
}

sub __run_forking
{
  my $self          = shift;
  my $server_socket = shift;

  if( ! socket_can_read( $server_socket, $self->{ 'TIMEOUT' } ) )
    {
    $self->on_forking_idle();
    return '0E0';
    }

  my $client_socket = $server_socket->accept() or return '0E0';
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
      $self->{ 'FORKS' }++;
      $self->{ 'KIDS'  }++;
      $self->{ 'KID_PIDS' }{ $pid } = 1;
      $self->on_fork_ok( $pid );
      $client_socket->close();
      next;
      }
    }
  # --------- kid here ---------
  $self->{ 'CHILD'  } = 1;
  delete $self->{ 'SERVER_SOCKET' };
  delete $self->{ 'KIDS' };
  delete $self->{ 'KID_PIDS' };

  # reinstall signal handlers in the kid
  $SIG{ 'INT'   } = sub { $self->break_main_loop(); };
  $SIG{ 'TERM'  } = sub { $self->break_main_loop(); };
  $SIG{ 'CHLD'  } = 'IGNORE';
  $SIG{ 'HUP'   } = sub { $self->__child_sig_hup();   };
  $SIG{ 'USR1'  } = sub { $self->__child_sig_usr1();  };
  $SIG{ 'USR2'  } = sub { $self->__child_sig_usr2();  };
  $SIG{ 'RTMIN' } = sub { $self->__sig_kid_idle()   };
  $SIG{ 'RTMAX' } = sub { $self->__sig_kid_busy()   };

  srand();

  my $sha_key = $self->{ 'SHA_KEY' };
  $self->{ 'SHA' } = new IPC::Shareable key => $sha_key or die "fatal: cannot attach shared memory segment\n";

  $client_socket->autoflush( 1 );
  $self->on_child_start();

  $self->im_busy();
  $self->on_process( $client_socket );
  $self->on_close( $client_socket );
  $client_socket->close();
  $self->im_idle();
  
  $self->on_child_exit();
  if( ! $self->{ 'NOFORK' } )
    {
    exit();
    }
  # ------- child exits here -------
}

my $next_stat = time() + 4;
sub __run_prefork
{
  my $self          = shift;
  my $server_socket = shift;

  my $prefork_count = $self->{ 'PREFORK' };

  my $kk = $self->{ 'KIDS' };             # kids k'ount ;)
  my $bk = $self->get_busy_kids_count();  # busy count
  my $ik = $kk - $bk;                     # idle kids count

  my $tk = $prefork_count;
    #$tk = $kk + $prefork_count / 2 if $kk > $prefork_count and $ik < ( 1 + $prefork_count / 10 );
     $tk = $kk + $prefork_count if $ik <= ( 1 + $kk / 10 );

  my $mf = $self->{ 'MAXFORK' };
  $tk = $mf if $mf > 0 and $tk > $mf; # MAXFORK cap

  if( time() > $next_stat )
    {
    $self->__sha_lock_ro( 'MASTER SHARED STATE' );
    $self->log_debug( "debug: shared memory state:\n" . Dumper( $self->{ 'SHA' } ) );
    $self->__sha_unlock( 'MASTER SHARED STATE' );

    $self->log_debug( "debug: stats:\n" . Dumper( $self->{ 'STAT' } ) );
    $self->{ 'STAT' }{ 'IDLE_FREQ' }{ int( $ik / 5 ) * 5 }++ if $bk > 0;

    my $_c = 10;
    for my $k ( sort { $self->{ 'STAT' }{ 'IDLE_FREQ' }{ $b } <=> $self->{ 'STAT' }{ 'IDLE_FREQ' }{ $a } } keys %{ $self->{ 'STAT' }{ 'IDLE_FREQ' } } )
      {
      my $v = $self->{ 'STAT' }{ 'IDLE_FREQ' }{ $k };
      $self->log_debug( sprintf( "debug: %3d idle(s) => %3d time(s)", $k, $v ) );
      last unless $_c--;
      }

    $next_stat = time() + 4;
    }
  $self->log_debug( "debug: kids: $kk   busy: $bk   idle: $ik   to_fork: $tk   will_fork?: $kk < $tk" );

  while( $self->{ 'KIDS' } < $tk )
    {
    my $pid;
    $pid = fork();
    if( ! defined $pid )
      {
      die "fatal: fork failed: $!";
      }
    if( $pid )
      {
      $self->{ 'FORKS' }++;
      $self->{ 'KIDS'  }++;
      $self->{ 'KID_PIDS' }{ $pid } = 1;
      $self->on_fork_ok( $pid );
      $self->{ 'STAT' }{ 'SPAWNS' }++;
      }
    else
      {
      # --------- child here ---------
      $self->{ 'CHILD'  } = 1;
      $self->{ 'SPTIME' } = time();
      delete $self->{ 'SERVER_SOCKET' };
      delete $self->{ 'KIDS' };
      delete $self->{ 'KID_PIDS' };

      # reinstall signal handlers in the kid
      $SIG{ 'INT'   } = sub { $self->break_main_loop(); };
      $SIG{ 'TERM'  } = sub { $self->break_main_loop(); };
      $SIG{ 'CHLD'  } = 'IGNORE';
      $SIG{ 'HUP'   } = sub { $self->__child_sig_hup();   };
      $SIG{ 'USR1'  } = sub { $self->__child_sig_usr1();  };
      $SIG{ 'USR2'  } = sub { $self->__child_sig_usr2();  };
      $SIG{ 'RTMIN' } = sub { $self->__sig_kid_idle()   };
      $SIG{ 'RTMAX' } = sub { $self->__sig_kid_busy()   };
      
      $self->on_child_start();
      
      $self->im_idle();

      my $kid_idle;
      while(4)
        {
        last if $self->{ 'BREAK_MAIN_LOOP' };
        last unless $self->__run_preforked_child( $server_socket );
        $kid_idle = $self->{ 'LPTIME' } > 0 ? time() - $self->{ 'LPTIME' } : - ( time() - $self->{ 'SPTIME' } );
        last if $self->{ 'LPTIME' } > 0 and $kid_idle > $self->{ 'PX_IDLE' };

        my $tt = $0;
        $tt =~ s/ \[-?\d+\]//;
        $0 = $tt . " [$kid_idle]";
        }
      $self->on_child_exit();
      exit;  
      # ------- child exits here -------
      }  
    }
    
}

sub __run_preforked_child
{
  my $self          = shift;
  my $server_socket = shift;

  if( ! socket_can_read( $server_socket, $self->{ 'TIMEOUT' } ) )
    {
    $self->on_prefork_child_idle();
    return '0E0';
    }

  my $client_socket = $server_socket->accept() or return '0E0';

  binmode( $client_socket );
  $self->{ 'CLIENT_SOCKET' } = $client_socket;

  my $peerhost = $client_socket->peerhost();
  my $peerport = $client_socket->peerport();
  my $sockhost = $client_socket->sockhost();
  my $sockport = $client_socket->sockport();

  $self->on_accept_ok( $client_socket );

  srand();

  $self->{ 'BUSY_COUNT' }++;
  $self->im_busy();
  $client_socket->autoflush( 1 );
  my $res = $self->on_process( $client_socket );
  $self->on_close( $client_socket );
  $client_socket->close();
  $self->im_idle();

  $self->{ 'LPTIME' } = time(); # last processing time
  
  return $res;
}

##############################################################################

#use Data::Tools;
sub __sha_lock_ro
{
  my $self = shift;
  return $self->__sha_obtain_lock( IPC::Shareable::LOCK_SH, 'SH' );
}

sub __sha_lock_rw
{
  my $self = shift;
  return $self->__sha_obtain_lock( IPC::Shareable::LOCK_EX, 'EX' );
}

sub __sha_unlock
{
  my $self = shift;
  return $self->__sha_obtain_lock( IPC::Shareable::LOCK_UN, 'UN' );
}


sub __sha_obtain_lock
{
  my $self = shift;
  my $op   = shift;
  my $str  = shift;
  
  my $rc;
  while( ! $rc )
    {
    $rc = tied( %{ $self->{ 'SHA' } } )->lock( $op );
    return $rc if $rc;
    next if $!{EINTR} or $!{EAGAIN};
    $self->log( "error: cannot obtain $str lock for SHA! [$rc] $! retry in 1 second" );  
    sleep(1);
    }
  $self->log( "error: cannot obtain $str lock for SHA! $!" );  
  return undef;  
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
  
  return wantarray ? ( $self->{ 'KIDS_BUSY'  }, $self->{ 'KIDS'  } ) : $self->{ 'KIDS_BUSY'  };
}

sub get_kids_count
{
  my $self = shift;
  
  return $self->{ 'KIDS' };
}

sub get_parent_pid
{
  my $self = shift;
  
  return $self->{ 'PARENT_PID' };
}

sub get_kid_pids
{
  my $self = shift;

  return () if $self->is_child();
  
  return keys %{ $self->{ 'KID_PIDS' } || {} };
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

  $self->__sha_lock_rw( 'KID STATE' );
  $self->{ 'SHA' }{ 'PIDS' }{ $$ } = $state . ":" . $self->{ 'BUSY_COUNT' };
  $self->{ 'SHA' }{ 'STAT' }{ 'BUSY_COUNT' }++ if $state eq '*';
  $self->__sha_unlock( 'KID STATE' );

  my $tt = $0;
  $tt =~ s/ \| .+//;
  $0 = $tt . ' | ' . $self->{ 'SHA' }{ 'PIDS' }{ $$ };
  
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

sub propagate_signal
{
  my $self = shift;
  my $sig  = shift;
  
  for my $kpid ( $self->get_kid_pids() )
    {
    kill( $sig, $kpid );
    }
}

sub __sig_child
{
  my $self = shift;

  while( ( my $cpid = waitpid( -1, WNOHANG ) ) > 0 )
    {
    $self->{ 'KIDS' }--;
    delete $self->{ 'KID_PIDS' }{ $cpid };
    $self->on_sig_child( $cpid );
    }
  $SIG{ 'CHLD' } = sub { $self->__sig_child(); };
}

sub __sig_hup
{
  my $self = shift;

  $self->on_sig_hup();
  $SIG{ 'HUP ' } = sub { $self->__sig_hup();   };
}

sub __sig_usr1
{
  my $self = shift;

  $self->on_sig_usr1();
  $self->propagate_signal( 'USR1' ) if $self->{ 'PROP_SIGUSR' };
  $SIG{ 'USR1' } = sub { $self->__sig_usr1();  };
}

sub __sig_usr2
{
  my $self = shift;

  $self->on_sig_usr2();
  $self->propagate_signal( 'USR2' ) if $self->{ 'PROP_SIGUSR' };
  $SIG{ 'USR2' } = sub { $self->__sig_usr2();  };
}

sub __child_sig_hup
{
  my $self = shift;

  $self->on_child_sig_hup();
  $SIG{ 'HUP' } = sub { $self->__child_sig_hup();  };
}

sub __child_sig_usr1
{
  my $self = shift;

  $self->on_child_sig_usr1();
  $SIG{ 'USR1' } = sub { $self->__child_sig_usr1();  };
}

sub __child_sig_usr2
{
  my $self = shift;

  $self->on_child_sig_usr2();
  $SIG{ 'USR2' } = sub { $self->__child_sig_usr2();  };
}


# used only for waking up preforked servers main loop sleep
sub __sig_kid_idle
{
  my $self = shift;

  $SIG{ 'RTMIN' } = sub { $self->__sig_kid_idle()   };
}

# used only for waking up preforked servers main loop sleep
sub __sig_kid_busy
{
  my $self = shift;

  $SIG{ 'RTMAX' } = sub { $self->__sig_kid_busy()   };
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

# called on forking mode parent side, when noone connects in 'TIMEOUT' secods.
sub on_forking_idle
{
}

sub on_maxforked
{
}

# called right after fork, in the forked child, after initial setup but just before processing start
sub on_child_start
{
}

# called just before forked or preforked child exits
sub on_child_exit
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

sub on_sig_hup
{
}

sub on_sig_usr1
{
}

sub on_sig_usr2
{
}

sub on_child_sig_hup
{
}

sub on_child_sig_usr1
{
}

sub on_child_sig_usr2
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

# this function is used to log messages including debug. should be reimplemented
sub log
{
  my $self = shift;
  # should be reimplemented
  print STDERR "$_\n" for @_;
}

# used for debug log messages when DEBUG is enabled
sub log_debug
{
  my $self = shift;
  return unless $self->{ 'DEBUG' };
  return $self->log( @_ );
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
   TIMEOUT =>    4, # timeout for accepting connections, defaults to 4 seconds
   SSL     =>    1, # use SSL

   PX_IDLE =>   31, # prefork exit idle time, defaults to 31

   PROP_SIGUSR => 1, # if true, will propagate USR1/USR2 signals to childs
   
   DEBUG   =>    1, # enable debug mode, prints debug messages

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

Returns connected client socket.

=head2 get_busy_kids_count()

Returns the count of all forked busy processes (which are already accepted connection).
In array contect returns two integers: busy process count and all forked processes count.
This method is accessible from parent and all forked processes and reflect all processes.

Returns client (connected) socket object. Valid in kids only, otherwise returns undef.

=head2 get_kid_pids()

Returns list of forked child pids. Available only in parent processes.

=head2 propagate_signal( 'SIGNAME' )

Sends signal 'SIGNAME' to all child processes.

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

=head2 on_prefork_child_idle

Called on preforked childs, when accept timeouts (see 'TIMEOUT' option).

=head2 on_forking_idle

Called on forking mode parent, when accept timeouts (see 'TIMEOUT' option).

=head2 on_maxforked( $client_socket )

Called if client socket is accepted but MAXFORK count reached. This can be
used to advise the situation over the socket and will be called right before
client socket close.

note: this handler is only used for FORKING server. preforked servers will
not accept the socket at all if MAXFORK has been reached. the reason is that
forking server may release child process during the accept() call.

=head2 on_child_start()

Called right after fork, in the forked child, after initial setup but just before processing start.

=head2 on_child_exit()

Called inside a child, just before forked or preforked child exits.

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

Called when server process receives USR1 signal.

=head2 on_sig_usr2()

Called when server process receives USR2 signal.
                                                                                        
=head2 on_child_sig_usr1()

Called when forked (child) process receives USR1 signal.

=head2 on_child_sig_usr2()

Called when forked (child) process receives USR2 signal.

=head2 log() and log_debug()

Called when Waiter prints (debug) messages. Should be reimplemented to use
specific log facility. By default it prints messages to STDERR. Can be
reimplemented empty to supress any messages.
                                                                                        
=head1 NOTES

SIG_CHLD handler defaults to IGNORE in child processes. 
whoever forks further here, should reinstall signal handler if needed. 

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
