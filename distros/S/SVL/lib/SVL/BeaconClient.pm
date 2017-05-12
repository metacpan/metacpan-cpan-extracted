package SVL::BeaconClient;
use strict;
use warnings;
$| = 1;
use POE qw(Component::Client::TCP Filter::Reference Filter::Stream);

POE::Component::Client::TCP->new(
  RemoteAddress => "www.astray.com",
#  RemoteAddress => "localhost",
  RemotePort    => 5678,
  ServerInput   => \&handle_server_input,
  Filter        => 'POE::Filter::Reference',
  Connected     => \&handle_connected,			      
);

my $global_uuid = shift;

my %svnserve;

sub handle_connected {
    $_[HEAP]->{server}->put({ type => 'register', uuid => $global_uuid } );
}

sub handle_server_input {
  my $data = $_[ARG0];

  my $heap = $_[HEAP];

  if ($data->{type} eq 'listen') {
    print "Remote listening enabled $data->{address}:$data->{port}/$data->{uuid}/\n";
  } elsif ($data->{type} eq 'connect') {
    # we need to connect here
    my $stream_id = $data->{stream};
    POE::Component::Client::TCP->new(
      RemoteAddress => '127.0.0.1',
      RemotePort    => '48513',
      Connected     => sub {
        #print "Connected to svnserve\n";
        $svnserve{$stream_id} = $_[HEAP]->{server};
      },
      ServerInput => sub {
        #print "Sending data back for stream $stream_id\n";
#        warn $_[ARG0] . "\n";
        $heap->{server}
          ->put({ type => 'data', stream => $stream_id, data => $_[ARG0] });
      },
      Filter => 'POE::Filter::Stream'
    );
    print "Connection from $data->{address} stream $data->{stream}\n";
  } elsif ($data->{type} eq 'data') {
    #print "Got data for stream $data->{stream}\n";
    $svnserve{ $data->{stream} }->put($data->{data});
  } elsif ($data->{type} eq 'disconnect') {
    #print "Disconnected client for stream $data->{stream}\n";
  } else {
    die "Unknown type";
  }
}

$poe_kernel->run();

1;

