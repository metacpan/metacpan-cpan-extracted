##############################################################################
#
#  Net::Waiter concise INET socket server
#  (c) Vladi Belperchinov-Shabanski "Cade" 2015
#  http://cade.datamax.bg
#  <cade@bis.bg> <cade@biscom.net> <cade@datamax.bg> <cade@cpan.org>
#
#  GPL
#
##############################################################################
package Net::Waiter;
use strict;
use POSIX ":sys_wait_h";
use IO::Socket::INET;

our $VERSION = '1.02';

##############################################################################
            
sub new
{
  my $class = shift;
  $class = ref( $class ) || $class;
  
  my %opt = @_;
  
  my $self = { 
               PORT    => $opt{ 'PORT'    }, # which port to listen on
               PREFORK => $opt{ 'PREFORK' }, # how many preforked processes
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
             
  bless $self, $class;
  return $self;
}

##############################################################################

sub run
{
  my $self = shift;

  if( $self->ssl_in_use() )
    {
    eval { require IO::Socket::SSL; };
    die "SSL not available: $@" if $@;
    };

  $SIG{ 'INT'  } = sub { $self->break_main_loop(); };
  $SIG{ 'CHLD' } = sub { $self->__sig_child(); };
  $SIG{ 'USR1' } = sub { $self->__sig_usr1();  };
  $SIG{ 'USR2' } = sub { $self->__sig_usr2();  };


  my $server_socket;

  if( $self->ssl_in_use() )
    {
    my %ssl_opts = %{ $self->{ 'SSL_OPTS' } };
    $ssl_opts{ SSL_error_trap  } = sub { shift; $self->on_ssl_error( shift() ); },

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
    $self->{ 'SERVER_SOCKET' } = $server_socket;
    $self->on_listen_ok();
    }

  while(4)
    {
    last if $self->{ 'BREAK_MAIN_LOOP' };
    my $client_socket = $server_socket->accept();
    if( ! $client_socket )
      {
      $self->on_accept_error();
      next;
      }

    $self->{ 'CLIENT_SOCKET' } = $client_socket;

    my $peerhost = $client_socket->peerhost();
    my $peerport = $client_socket->peerport();
    my $sockhost = $client_socket->sockhost();
    my $sockport = $client_socket->sockport();

    $self->on_accept_ok( $client_socket );

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
        $self->on_fork_ok( $pid );
        $client_socket->close();
        next;
        }
      }
    # --------- child here ---------
    delete $self->{ 'SERVER_SOCKET' };

    # reinstall signal handlers in the kid
    $SIG{ 'INT'  } = 'DEFAULT';
    $SIG{ 'CHLD' } = 'DEFAULT';
    $SIG{ 'USR1' } = 'DEFAULT';
    $SIG{ 'USR2' } = 'DEFAULT';

    srand();

    $self->{ 'CHILD' } = 1;

    $client_socket->autoflush( 1 );
    $self->on_process( $client_socket );
    $self->on_close( $client_socket );
    $client_socket->close();
    
    if( ! $self->{ 'NOFORK' } )
      {
      return 0;
      }
    # ------- child ends here -------
    }

  $self->on_server_close( $server_socket );
  close( $server_socket );
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

sub on_process
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
   PREFORK => 0,    # how many preforked processes, TODO
   NOFORK  => 0,    # if 1 will not fork, only single client will be accepted
   SSL     => 1,    # use SSL

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

=head2 on_close( $client_socket )

Called right before client socket will be closed. And after on_process().

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
