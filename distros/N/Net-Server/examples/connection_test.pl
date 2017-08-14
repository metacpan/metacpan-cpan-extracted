#!/usr/bin/perl -w

=head1 NAME

connection_test.pl - Test UDP/TCP/UNIX/UNIX_DGRAM connections

=head1 SERVER SYNOPSIS

    # in a separate terminal window

    perl connection_test.pl

=head1 CLIENT SYNOPSIS

    perl connection_test.pl UDP

    # or

    perl connection_test.pl TCP

    # or

    perl connection_test.pl UNIX <UNIX socket directory>

    # or

    perl connection_test.pl UNIX_DGRAM <UNIX socket directory>

=cut

package MyPack;

use strict;
use warnings;
use base qw(Net::Server);
use IO::Socket ();
use File::Temp qw(tempdir);
use File::Spec::Functions qw(catdir);
use Socket qw(SOCK_DGRAM SOCK_STREAM);

sub post_bind_hook {
  my $self = shift;
  foreach my $sock ( @{ $self->{server}->{sock} } ){
    $self->log(2,$sock->show);
  }
}

my $socket_dir  = $ARGV[1] || tempdir(CLEANUP => 1);
my $socket_file = catdir($socket_dir, 'mysocket.file');
my $socket_file2 = catdir($socket_dir, 'mysocket.file2');
my $udp_port    = 20204;
my $tcp_port    = 20204;

print "\$Net::Server::VERSION = $Net::Server::VERSION\n";
print "UNIX socket directory = $socket_dir\n";

if( @ARGV ){
  if( uc($ARGV[0]) eq 'UDP' ){
      print "Testing UDP\n";
    my $sock = IO::Socket::INET->new(PeerAddr => 'localhost',
                                     PeerPort => $udp_port,
                                     Proto    => 'udp',
                                     ) || die "Can't connect [$!]";
    ### send a packet, get a packet
    $sock->send("Are you there?",0);
    my $data = undef;
    $sock->recv($data,4096,0);
    print $data,"\n";
    exit;
  }

  if( uc($ARGV[0]) eq 'TCP' ){
      print "Testing TCP\n";
    my $sock = IO::Socket::INET->new(PeerAddr => 'localhost',
                                     PeerPort => $tcp_port,
                                     Proto    => 'tcp',
                                     ) || die "Can't connect [$!]";
    print $sock "hi\n";
    my $line = $sock->getline();
    print $line;
    exit;
  }

  if( uc($ARGV[0]) eq 'UNIX' ){
      print "Testing UNIX (File socket with SOCK_STREAM)\n";
    my $sock = IO::Socket::UNIX->new(Peer => $socket_file) || die "Can't connect [$!]";

    print $sock "hi\n";
    my $line = $sock->getline();
    print $line;
    exit;
  }

  if( uc($ARGV[0]) eq 'UNIX_DGRAM' ){
      print "Testing UNIX_DGRAM\n";
    my $sock = IO::Socket::UNIX->new(Peer => $socket_file2,
                                     Type => SOCK_DGRAM,
                                     ) || die "Can't connect [$!]";

    ### send a packet, get a packet
    $sock->send("Are you there?",0);
    ### The server receives the data just fine
    ### however, the default arguments don't seem to work for
    ### sending it back.  If anybody knows why, let me know.
    my $data = undef;
    $sock->recv($data,4096,0);
    print $data,"\n";
    exit;
  }

  print "USAGE: $0 UDP|TCP|UNIX|UNIX_DGRAM
(If no arguments are passed, the server will start.
You should start the server in one window, and connect
in another window).
";
  exit;
}

### set up servers doing 
## SOCK_DGRAM  on INET (udp)
## SOCK_STREAM on INET (tcp)
## SOCK_DGRAM  on UNIX
## SOCK_STREAM on UNIX

MyPack->run(port => "$udp_port|udp",
            port => "$tcp_port|tcp",
            port => "$socket_file|unix", # default is SOCK_STREAM
            port => join("|",$socket_file2,SOCK_DGRAM,"unix"),
            log_level => 4,
            );
