package Tak::ConnectorService;

use IPC::Open2;
use IO::Socket::UNIX;
use IO::Socket::INET; # Sucks to be v6, see comment where used
use IO::All;
use Tak::Router;
use Tak::Client;
use Tak::ConnectionService;
use Net::OpenSSH;
use Tak::STDIONode;
use Moo;

with 'Tak::Role::Service';

has connections => (is => 'ro', default => sub { Tak::Router->new });

has ssh => (is => 'ro', default => sub { {} });

sub handle_create {
  my ($self, $on, %args) = @_;
  die [ mistake => "No target supplied to create" ] unless $on;
  my $log_level = $args{log_level}||'info';
  my ($kid_in, $kid_out, $kid_pid) = $self->_open($on, $log_level);
  if ($kid_pid) {
    $kid_in->print($Tak::STDIONode::DATA, "__END__\n") unless $on eq '-';
    # Need to get a handshake to indicate STDIOSetup has finished
    # messing around with file descriptors, otherwise we can severely
    # confuse things by sending before the dup.
    my $up = <$kid_out>;
    die [ failure => "Garbled response from child: $up" ]
      unless $up eq "Shere\n";
  }
  my $connection = Tak::ConnectionService->new(
    read_fh => $kid_out, write_fh => $kid_in,
    listening_service => Tak::Router->new
  );
  my $client = Tak::Client->new(service => $connection);
  # actually, we should register with a monotonic id and
  # stash the pid elsewhere. but meh for now.
  my $pid = $client->do(meta => 'pid');
  my $name = $on.':'.$pid;
  my $conn_router = Tak::Router->new;
  $conn_router->register(local => $connection->receiver->service);
  $conn_router->register(remote => $connection);
  $self->connections->register($name, $conn_router);
  return ($name);
}

sub _open {
  my ($self, $on, @args) = @_;
  if ($on eq '-') {
    my $kid_pid = IPC::Open2::open2(my $kid_out, my $kid_in, 'tak-stdio-node', '-', @args)
      or die "Couldn't open2 child: $!";
    return ($kid_in, $kid_out, $kid_pid);
  } elsif ($on =~ /^\.?\//) { # ./foo or /foo
    my $sock = IO::Socket::UNIX->new($on)
      or die "Couldn't open unix domain socket ${on}: $!";
    return ($sock, $sock, undef);
  } elsif ($on =~ /:/) { # foo:80 we hope
    # IO::Socket::IP is a better answer. But can pull in XS deps.
    # Well, more strictly it pulls in Socket::GetAddrInfo, which can
    # actually work without its XS implementation (just doesn't handle v6)
    # and I've not properly pondered how to make things like fatpacking
    # Just Fucking Work in such a circumstance. First person to need IPv6
    # and be reading this comment, please start a conversation about it.
    my $sock = IO::Socket::INET->new(PeerAddr => $on)
      or die "Couldn't open TCP socket ${on}: $!";
    return ($sock, $sock, undef);
  }
  my $ssh = $self->ssh->{$on} ||= Net::OpenSSH->new($on);
  $ssh->error and
    die "Couldn't establish ssh connection: ".$ssh->error;
  return $ssh->open2('perl','-', $on, @args);
}

sub start_connection_request {
  my ($self, $req, @payload) = @_;;
  $self->connections->start_request($req, @payload);
}

sub receive_connection {
  my ($self, @payload) = @_;
  $self->connections->receive(@payload);
}

1;
