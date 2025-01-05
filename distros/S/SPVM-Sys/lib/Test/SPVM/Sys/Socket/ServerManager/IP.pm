package Test::SPVM::Sys::Socket::ServerManager::IP;

use base 'Test::SPVM::Sys::Socket::ServerManager';

use strict;
use warnings;
use Carp ();

use Test::SPVM::Sys::Socket::Util;

# Fields
sub port { shift->{port} }

# Instance Methods
sub init_fields {
  my ($self, %options) = @_;
  
  $self->SUPER::init_fields(%options);
  
  # port field
  my $port = Test::SPVM::Sys::Socket::Util::get_available_port;
  
  $self->{port} = $port;
}

sub start {
  my ($self) = @_;
  
  my $port = $self->{port};
  
  my $pid = fork;
  
  unless (defined $pid) {
    Carp::confess("fork() failed: $!");
  }
  
  # Child
  if ($pid == 0) {
    my $code = $self->{code};
    
    $code->($self);
    
    if (kill 0, $self->{my_pid}) {
      warn("[Test::SPVM::Sys::Socket::ServerManager::Socket::IP#start]Child process does not block(pid: $$, my_pid:$self->{my_pid}).");
    }
    
    exit 0;
  }
  # Parent
  else {
    $self->{pid} = $pid;
    
    $self->_wait_server_start;
  }
}

sub _wait_server_start {
  my ($self) = @_;
  
  my $host = $self->{host};
  
  my $port = $self->{port};
  
  my $max_wait = $self->{max_wait};
  
  $max_wait ||= 10;
  
  my $wait_time = 0.1;
  my $wait_total = 0;
  while (1) {
    if ($wait_total > $max_wait) {
      last;
    }
    
    sleep $wait_time;
    
    my $sock = IO::Socket::IP->new(
      Proto    => 'tcp',
      PeerAddr => $host,
      PeerPort => $port,
    );
    
    if ($sock) {
      last;
    }
    $wait_total += $wait_time;
    $wait_time *= 2;
  }
}

1;

=head1 Name

Test::SPVM::Sys::Socket::ServerManager::IP - Server Manager for tests for internet domain sockets

=head1 Description

Test::SPVM::Sys::Socket::ServerManager::IP class is a server manager for tests for internet domain sockets.

=head1 Usage

  my $server = Test::SPVM::Sys::Socket::ServerManager::IP->new(
    code => sub {
      my ($server_manager) = @_;
      
      my $port = $server_manager->port;
      
      my $server = Test::SPVM::Sys::Socket::Server->new_echo_server_ipv4_tcp(port => $port);
      
      $server->start;
    },
  );

=head1 Details

This class is originally a L<Test::TCP> porting for tests for L<SPVM::Sys::Socket>.

=head1 Super Class

L<Test::SPVM::Sys::Socket::ServerManager>

=head1 Class Methods

=head2 new

  my $server = Test::SPVM::Sys::Socket::ServerManager::IP->new(%options);

Calls L<new|Test::SPVM::Sys::Socket::ServerManager/"new"> method in its super class and returns its return value.

Options:

The following options are available adding the options of L<new|Test::SPVM::Sys::Socket::ServerManager/"new"> method in its super class.

=over 2

=item * C<port>

Sets L</"port"> field to this value.

=back

=head1 Fields

=head2 port

  my $port = $self->port;

The port number to which the server binds.

=head1 Instance Methods

=head2 init_fields

  $server->init_fields(%options);

Calls L<init_fields|Test::SPVM::Sys::Socket::ServerManager/"init_fields"> method in the super class and sets fields of this calss.

L</"port"> field is set to the value of C<port> option.

If C<port> option is not specified, the field is set to an available port.

This method is a protected method, so it should only be called in this class and its child classes.

=head2 start

  $server->start($code);

Starts a server process given an anon subroutine $code.

This method calls L<fork|https://perldoc.perl.org/functions/fork> function and starts the server specified by $code in the child process.

The L<Test::SPVM::Sys::Socket::ServerManager::IP> object is passed to the 1th argument of $code.

  $server->start(sub {
    my ($server_manager) = @_;
    
    my $port = $server_manager->port;
    
    
  });

The parent process waits until the server starts.
