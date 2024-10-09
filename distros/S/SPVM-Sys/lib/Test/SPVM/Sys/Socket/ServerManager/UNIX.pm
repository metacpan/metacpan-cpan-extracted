package Test::SPVM::Sys::Socket::ServerManager::UNIX;

use base 'Test::SPVM::Sys::Socket::ServerManager';

use strict;
use warnings;
use Carp ();

use IO::Socket::UNIX;
use File::Temp ();
use Time::HiRes ();

# Fields
sub tmpdir { shift->{tmpdir} }

sub path { shift->{path} }

# Instance Methods
sub init_fields {
  my ($self, %options) = @_;
  
  $self->SUPER::init_fields(%options);
  
  # path and tmpdir field
  my $path = $self->{path};
  unless (defined $path) {
    $self->{tmpdir} = File::Temp->newdir;
    $self->{path} = $self->{tmpdir} . "/test.sock";
  }
}

sub start {
  my ($self) = @_;
  
  my $path = $self->path;
  
  my $pid = fork();
  
  unless (defined $pid) {
    Carp::confess("fork() failed: $!");
  }
  
  # Child
  if ($pid == 0) {
    
    my $code = $self->{code};
    
    $code->($self);
    
    if (kill 0, $self->{my_pid}) {
      warn("[Test::SPVM::Sys::Socket::ServerManager::Socket::UNIX#start]Child process does not block(pid: $$, my_pid:$self->{my_pid}).");
    }
    
    exit 0;
  }
  # Parent
  else {
    $self->{pid} = $pid;
    $self->_wait_server_start;
    return;
  }
}

sub _wait_server_start {
  my ($self) = @_;
  
  my $path = $self->path;
  
  my $max_wait = $self->{max_wait};
  
  $max_wait ||= 10;
  
  my $waiter = &_make_waiter($max_wait);
  
  while ($waiter->()) {
    my $socket = IO::Socket::UNIX->new(
      Type => SOCK_STREAM,
      Peer => $path,
    );
    
    if ($socket) {
      return 1;
    }
  }
  
  return 0;
}

sub _make_waiter {
  my ($max_wait) = @_;
  
  my $waited = 0;
  
  my $sleep  = 0.001;
  
  my $waiter = sub {
    return 0 if $max_wait >= 0 && $waited > $max_wait;
    
    Time::HiRes::sleep($sleep);
    $waited += $sleep;
    $sleep  *= 2;
    
    return 1;
  };
  
  return $waiter;
}

1;

=head1 Name

Test::SPVM::Sys::Socket::ServerManager::UNIX - Server Manager for tests for UNIX Domain Sockets

=head1 Description

Test::SPVM::Sys::Socket::ServerManager::UNIX class is a server manager for tests for UNIX domain sockets.

=head1 Usage
  
  use Test::SPVM::Sys::Socket::ServerManager::UNIX;
  
  my $server_manager = Test::SPVM::Sys::Socket::ServerManager::UNIX->new(
    code => sub {
      my ($server_manager) = @_;
      
      my $path = $server_manager->path;
      
      my $server = Test::SPVM::Sys::Socket::Server->new_echo_server_unix_tcp(path => $path);
      
      $server->start;
    },
  );

=head1 Details

This class is originally a L<Test::UNIXSock> porting for tests for L<SPVM::Sys::Socket>.

=head1 Super Class

L<Test::SPVM::Sys::Socket::ServerManager>

=head1 Fields

=head2 path

  my $path = $self->path;

The path to which the server binds.

=head2 tmpdir

A temporary directory used by L</"path">.

=head1 Class Methods

=head2 new

  my $server = Test::SPVM::Sys::Socket::ServerManager::UNIX->new(%options);

Calls L<new|Test::SPVM::Sys::Socket::ServerManager/"new"> method in its super class and returns its return value.

Options:

The following options are available adding the options of L<new|Test::SPVM::Sys::Socket::ServerManager/"new"> method in its super class.

=over 2

=item * C<path>

Sets L</"path"> field to this value.

=back

=head1 Instance Methods

=head2 init_fields

  $server->init_fields(%options);

Calls L<init_fields|Test::SPVM::Sys::Socket::ServerManager/"init_fields"> method in its super class and sets fields of this calss.

L</"path"> field is set to the value of C<path> option.

If C<path> option is not defind, L<tmpdir> field is set to a temporary directory and L</"path"> is set to an available path.

This method is a protected method, so it should only be called in this class and its child classes.

=head2 start

  $server->start($code);

Starts a server process given an anon subroutine $code.

This method calls L<fork|https://perldoc.perl.org/functions/fork> function and starts the server specified by $code in the child process.

The L<Test::SPVM::Sys::Socket::ServerManager::UNIX> object is passed to the 1th argument of $code.

  $server->start(sub {
    my ($server_manager) = @_;
    
    my $path = $server_manager->path;
    
  });

The parent process waits until the server starts.
