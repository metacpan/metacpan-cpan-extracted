# sirc.pl
# A simple IRC robot.
# Usage: perl sirc.pl

use strict;
use warnings;

# We will use a raw socket to connect to the IRC server.
use IO::Socket;
use IO::Select;
use Parse::IRC;

$|=1;

my $filter = Parse::IRC->new( public => 1 );

# Add your IRC event handling sub routines here.
# You will get $socket, followed by irc args as parameters.
my %dispatch = ( 'ping' => \&irc_ping, '001' => \&irc_001 );

# The server to connect to and our details.
my $server = "irc.perl.org";
my $nick = "simplebot$$";
my $login = "simple_bot";

# The channel which the bot will join.
my $channel = "#IRC.pm";

my $readable_handles = IO::Select->new();

# Connect to the IRC server.
my $sock = new IO::Socket::INET(PeerAddr => $server,
                                PeerPort => 6667,
                                Proto => 'tcp') or
                                    die "Can't connect\n";

$sock->autoflush(1);

# Log on to the server.
print $sock "NICK $nick\r\n";
print $sock "USER $login 8 * :Perl IRC Hacks Robot\r\n";

$readable_handles->add($sock);

# Keep reading lines from the server.
LOOP: while(1) {
  my ($readable) = IO::Select->select($readable_handles,
                                         undef, undef, 0);
  foreach my $socket (@$readable) {
    my $input = <$socket>;
    $input =~ s/\r\n//g;
    my $hashref = $filter->parse($input);
    next LOOP unless $hashref;
    my $type = lc $hashref->{command};
    my @args;
    push @args, $hashref->{prefix} if $hashref->{prefix};
    push @args, @{ $hashref->{params} };
    if ( defined $dispatch{$type} ) {
	$dispatch{$type}->($socket,@args);
	next LOOP;
    }
    print STDOUT join( ' ', "irc_$type:", @args ), "\n";
  }
}

sub irc_ping {
  my ($socket,$server) = @_;
  print $socket "PONG :$server\r\n";
  return 1;
}

sub irc_001 {
  my ($socket,$server) = @_;
  print STDOUT "Connected to $server\n";
  print $socket "JOIN $channel\r\n";
  return 1;
}
