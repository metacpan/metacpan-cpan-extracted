use Test::More;
use IO::Pipe;
use IO::Select;

use RPC::Lite;

my @serializerTypes = qw( XML JSON );


my $server_control_pipe = IO::Pipe->new();
my $client_control_pipe = IO::Pipe->new();

if ( my $pid = fork() ) # parent - client
{

  $client_control_pipe->reader;
  $server_control_pipe->writer;
  $server_control_pipe->autoflush;

  # wait for the server to tell us it's listening
  $response = <$client_control_pipe>; # block until we get a response

  if ( $response =~ /listening/ )
  {
    my $numTests = 6 * @serializerTypes;
    plan tests => $numTests;
  }
  elsif ( $response =~ /no threading/ )
  {
    plan skip_all => 'could not enable threading';
  }
  else
  {
    plan tests => 1;
    fail('unexpected response from child process: ' . $response );
  }

  foreach my $serializerType ( @serializerTypes )
  {

    $client = RPC::Lite::Client->new(
      {
        Transport  => 'TCP:Host=localhost,Port=10000,Timeout=0.1',
        Serializer => $serializerType,
      }
    );

    ok( defined( $client ), "$serializerType client construction" );

    my ($gotSlow, $gotFast);
    $client->AsyncRequest(sub {
                            $gotSlow = 1;
                            is( $_[0], 'slow', 'slow call returned correct value' );
                            ok( $gotFast, 'slow returned after fast' );
                          },
                          'slow');
    $client->AsyncRequest(sub {
                            $gotFast = 1;
                            is( $_[0], 'fast', 'fast call returned correct value' );
                            ok( !$gotSlow, 'fast returned before slow' );
                          },
                          'fast');

    my $start = time;
    $client->HandleResponse until ($gotFast and $gotSlow) or (time > $start + 20);
    ok ( $gotFast && $gotSlow, 'got responses from both calls');

  }

  # tell the server we're done
  $server_control_pipe->print("done\n");

}
elsif ( defined( $pid ) ) # child - server
{

  $server_control_pipe->reader;
  $client_control_pipe->writer;
  $client_control_pipe->autoflush;

  if ( ! RPC::Lite::Server->IsThreadingSupported )
  {
    $client_control_pipe->print("no threading\n");
    exit;
  }

  my $server = TestServer->new(
    {
      Transports  => [ 'TCP:Port=10000,Timeout=0.1' ],
      Threaded    => 1,
    }
  );

  # tell the client we're listening
  $client_control_pipe->print("listening\n");

  # run the server loop until the client tells us it's done
  my $select = IO::Select->new([$server_control_pipe]);
  until ( $select->can_read(0) )
  {
    $server->HandleRequests;
    $server->HandleResponses;
  }

}
else
{
  plan tests => 1;
  fail('failed to spawn server process');
}

###########################


package TestServer;

use base qw(RPC::Lite::Server);

sub slow
{
  sleep(10);
  return 'slow';
}

sub fast
{
  return 'fast';
}
