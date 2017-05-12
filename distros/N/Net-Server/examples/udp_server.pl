#!/usr/bin/perl

=head1 NAME

udp_server.pl - Simple sample udp echo server

=head1 SERVER SYNOPSIS

    perl udp_server.pl --log_level 3
    # default is to not background

=head1 CLIENT SYNOPSIS

    # In another terminal

    perl udp_server.pl --client

=cut

package MyUDPD;
use strict;
use warnings;
use Data::Dumper;

my $port        = 20203;
my $host        = 'localhost';
my $recv_length = 8192; # packet size

### what type of server is this - we could
### use multi type when we add command line
### parsing to this http server to allow
### for different configurations
use base qw(Net::Server::PreFork);

if (grep {/\bclient\b/i} @ARGV) {
    handle_client();

} else {
    ### run the server
    MyUDPD->run( port => "$host:$port/udp",
                 # we could also do the following:
                 # port => '*:20203/udp',
                 # port => 'somehost:20203/udp',
                 # port => '20203/udp', port => '20204/udp',
                 # port => '20203/udp', port => '20203/tcp',
                 );
}
exit;

###----------------------------------------------------------------###
### overridden server hooks

### set up some server parameters
sub configure_hook {
  my $self = shift;

  ### change the packet len?
  $self->{server}->{udp_recv_len} = $recv_length; # default is 4096

}


### this is the main method to override
### this is where most of the work will occur
### A sample server is shown below.
sub process_request {
  my $self = shift;
  my $prop = $self->{'server'};

  ### if we were writing a server that did both tcp and udp,
  ### we would need to check $prop->{udp_true} to see
  ### if the current connection is udp or not
  #  if ($prop->{udp_true}) {
  #    # yup, this is udp
  #  }

  # all of the client data is already in 'udp_data'
  if ($prop->{'udp_data'} =~ /dump/) {
      local $Data::Dumper::Sortkeys = 1;
      $prop->{'client'}->send(Data::Dumper::Dumper($self), 0);
  } else {
      $prop->{'client'}->send("You said \"$prop->{udp_data}\"", 0);
  }
  return;

}


###----------------------------------------------------------------###
### dummy client terminal echo relay

sub handle_client {
    require IO::Socket;

    my $recv_flags  = 0;

    print "$0\nEcho server client relay\nType anything and hit enter\n";
    print "-------------------------------\n";
    while (defined(my $line = <STDIN>)) {
        chomp $line;

        my $sock = IO::Socket::INET->new(
                                         PeerAddr => $host,
                                         PeerPort => $port,
                                         Proto    => 'udp',
                                         )
            || die "Couldn't connect to $host:$port: $!";

        $sock->send($line, 0);

        my $data = '';
        $sock->recv($data, $recv_length, $recv_flags);

        print "From the server:\n$data\n-------------------------\n";
    }

}
