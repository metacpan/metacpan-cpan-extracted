use lib "t/lib";
use Test::More tests=>5;

BEGIN{ use_ok( "Net::Jabber" ); }

my $Client;
my $connected = 0;

my $server = "obelisk.net";
my $port = 5222;
my $username = "test-netjabber";
my $password = "test";
my $resource = $$.time.qx(hostname);
chomp($resource);

###############################################################################
#
# Make sure you can ever connect to the server.  If we cannot then we should
# skip the rest of the tests because they will fail.
#
###############################################################################
SKIP:
{
    my $sock = IO::Socket::INET->new(PeerAddr=>"$server:$port");
    skip "Cannot open connection (maybe a firewall?)",4 unless defined($sock);
    $sock->close();
    
    $Client = new Net::Jabber::Client();

    $Client->SetCallBacks(onconnect => \&onConnect,
                          onauth    => \&onAuth,
                          message   => \&onMessage,
                         );

    $Client->Execute(username=>$username,
                     password=>$password,
                     resource=>$resource,
                     hostname=>$server,
                     port=>$port,
                     register=>1,
                     connectsleep=>0,
                     connectattempts=>1,
                   );

    #--------------------------------------------------------------------------
    # If all went well, we should never get here.
    #--------------------------------------------------------------------------
    ok(0,"Connected") unless $connected;
    ok(0,"Authenticated");
    ok(0,"Subject");
    ok(0,"Body");
}


###############################################################################
#
# onConnect - when we establish an initial connection to the server run the
#             following
#
###############################################################################
sub onConnect
{
    $connected = 1;
    ok(1, "Connected");
}


###############################################################################
#
# onAuth - when we have successfully authenticated with the server send a
#          test message to ourselves.
#
###############################################################################
sub onAuth
{
    $Client->MessageSend(to=>$username."@".$server."/".$resource,
                         subject=>"test",
                         body=>"This is a test.");

    ok(1, "Authenticated");
}


###############################################################################
#
# onMessage - when we get a message, check that the contents match what we sent
#             above.
#
###############################################################################
sub onMessage
{
    my $sid = shift;
    my $message = shift;

    is( $message->GetSubject(), "test", "Subject" );
    is( $message->GetBody(), "This is a test.", "Body" );

    $Client->Disconnect();

    exit(0);
}


