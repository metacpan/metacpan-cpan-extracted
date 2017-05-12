package Pod::Webserver::Daemon;

use strict;
use warnings;

use Pod::Webserver::Connection;

our $VERSION = '3.11';

use Socket qw(PF_INET SOCK_STREAM SOMAXCONN inet_aton sockaddr_in);

# ------------------------------------------------

sub accept {
  my $self = shift;
  my $sock = $self->{__sock};

  my $rin = '';
  vec($rin, fileno($sock), 1) = 1;

  # Sadly getting a valid returned time from select is not portable

  my $end = $self->{Timeout} + time;

  do {
    if (select ($rin, undef, undef, $self->{Timeout})) {
      # Ready for reading;

      my $got = do {local *GOT; \*GOT};
      #$! = "";
      accept $got, $sock or die "Error: accept failed: $!\n";
      return Pod::Webserver::Connection->new($got);
    }
  } while (time < $end);

  return undef;

} # End of accept.

# ------------------------------------------------

sub new {
  my $class = shift;
  my $self = {@_};
  $self->{LocalHost} ||= 'localhost';

  # Anonymous file handles the 5.004 way:
  my $sock = do {local *SOCK; \*SOCK};

  my $proto = getprotobyname('tcp') or die "Error in getprotobyname: $!\n";
  socket($sock, PF_INET, SOCK_STREAM, $proto) or die "Can't create socket: $!\n";
  my $host = inet_aton($self->{LocalHost})
    or die "Can't resolve hostname '$self->{LocalHost}'\n";
  my $sin = sockaddr_in($self->{LocalPort}, $host);
  bind $sock, $sin
    or die "Couldn't bind to $self->{LocalHost}:$self->{LocalPort}: $!\n";
  listen $sock, SOMAXCONN or die "Couldn't listen on socket: $!\n";

  $self->{__sock} = $sock;

  return bless $self, $class;

} # End of accept.

# ------------------------------------------------

sub url {
  my $self = shift;

  return "http://$self->{LocalHost}:$self->{LocalPort}/";

} # End of url.

# ------------------------------------------------

1;
