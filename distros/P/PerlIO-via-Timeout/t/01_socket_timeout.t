use strict;
use warnings;

use Test::More;
use PerlIO::via::Timeout qw(:all);

use Test::TCP;
use Errno qw(ETIMEDOUT);

sub create_server {
    my $delay = shift;
    Test::TCP->new(
        code => sub {
            my $port   = shift;
            my $socket = IO::Socket::INET->new(
                Listen    => 5,
                Reuse     => 1,
                Blocking  => 1,
                LocalPort => $port
            ) or die "ops $!";
    
            my $buffer;
            while (1) {
               # First, establish connection
                my $client = $socket->accept();
                $client or next;
    
                # Then get data (with delay)
                if ( defined (my $message = <$client>) ) {
                    my $response = "S" . $message;
                    sleep($delay);
                    print $client $response;
                }
                $client->close();
            }
        },
    );
    
}


subtest 'socket without timeout' => sub {
    my $server = create_server(1);
    my $client = IO::Socket::INET->new(
        PeerHost        => '127.0.0.1',
        PeerPort        => $server->port,
    );
    
    binmode($client, ':via(Timeout)');
    is read_timeout($client), 0, 'layer has default 0 read timeout';
    is write_timeout($client), 0, 'layer has default 0 write timeout';
    

    $client->print("OK\n");
    my $response = $client->getline;
    is $response, "SOK\n", "got proper response";

};

subtest 'socket with timeout' => sub {
    my $server = create_server(2);
    my $client = IO::Socket::INET->new(
        PeerHost        => '127.0.0.1',
        PeerPort        => $server->port,
    );
    
    binmode($client, ':via(Timeout)');
    read_timeout($client, 0.5);

    is timeout_enabled($client), 1, 'layer has timeout enabled';
    is read_timeout($client), 0.5, 'layer has proper read timeout';
    is write_timeout($client), 0, 'layer has default 0 write timeout';

    print $client ("OK\n");
    my $response = <$client>;
    is $response, undef, "got undef response";
    is(0+$!, ETIMEDOUT, "error is timeout");
};

subtest 'socket with disabled timeout' => sub {
    my $server = create_server(2);
    my $client = IO::Socket::INET->new(
        PeerHost        => '127.0.0.1',
        PeerPort        => $server->port,
    );
    
    binmode($client, ':via(Timeout)');
    read_timeout($client, 0.5);
    disable_timeout($client, 0);
    is read_timeout($client), 0.5, 'layer has 0.5 read timeout';
    is write_timeout($client), 0, 'layer has default 0 write timeout';
    
    $client->print("OK\n");
    my $response = $client->getline;
    is $response, "SOK\n", "got proper response";

};

done_testing;
