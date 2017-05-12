  use strict;
  use lib qw(../blib/lib);
  use IO::Socket;
  use Parse::IRC;
  use Getopt::Long;

  my $parser = Parse::IRC->new();

  my %dispatch = ( 'ping' => \&irc_ping, '001' => \&irc_001, 'public' => \&irc_public );

  # The server to connect to and our details.
  my $server = "irc.perl.moo";
  my $port = 6667;
  my $nick = "parseirc$$";
  my $login = "simple_bot";

  # The channel which the bot will join.
  my $channel = "#IRC.pm";

  GetOptions( "server=s" 	=> \$server, 
	      "nick=s" 		=> \$nick, 
	      "login=s" 	=> \$login,
	      "port=i"		=> \$port,
	      "channel=s" 	=> \$channel );

  # Connect to the IRC server.
  my $sock = new IO::Socket::INET(PeerAddr => $server,
                                  PeerPort => $port,
                                  Proto => 'tcp') or
                                    die "Can't connect\n";

  # Log on to the server.
  print $sock "NICK $nick\r\n";
  print $sock "USER $login 8 * :Perl IRC Hacks Robot\r\n";

  # Keep reading lines from the server.
  while (my $input = <$sock>) {
    $input =~ s/\r\n//g;
    my $hashref = $parser->parse( $input );
    SWITCH: {
          my $type = lc $hashref->{command};
          $type = 'public' if $type eq 'privmsg' and $hashref->{params}->[0] =~ /^#/;
          my @args;
          push @args, $hashref->{prefix} if $hashref->{prefix};
          push @args, @{ $hashref->{params} };
          if ( defined $dispatch{$type} ) {
            $dispatch{$type}->(@args);
            last SWITCH;
          }
          print STDOUT join( ' ', "irc_$type:", @args ), "\n";
    }
  }

  sub irc_001 {
    print STDOUT "Connected to $_[0]\n";
    print $sock "JOIN $channel\r\n";
    return 1;
  }

  sub irc_ping {
    my $server = shift;
    print $sock "PONG :$server\r\n";
    return 1;
    print STDOUT "Connected to $_[0]\n";
    print $sock "JOIN $channel\r\n";
    return 1;
  }

  sub irc_public {
    my ($who,$where,$what) = @_;
    print "$who -> $where -> $what\n";
    return 1;
  }

