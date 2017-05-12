use Test::More;
use Test::TCP;
use strict;
use warnings;

BEGIN {
    use_ok 'Net::OTServ';
}

test_tcp(
    listen => 1,
    host => '127.0.0.1',
    port => 7171,

    server => sub {
        my $sock = shift;
        while (my $client = $sock->accept) {
            my $req;
            $client->recv($req, 9);
            if ($req eq "\x06\x00\xFF\xFF\x69\x6E\x66\x6F") {
                my $xml = qq{
<?xml version="1.0"?>
<tsqp version="1.0">
<serverinfo uptime="25221" ip="127.0.0.1" servername="Test::TCP" port="${\($client->sockport)}" location="$0" url="127.0.0.1" server="Test::TCP" version="7.4" client="7.4"/>
<owner name="a3f" email=""/>
<players online="400" max="2500" peak="2500"/>
<map name="map" author="a3f" width="10" height="10"/>
<motd>Welcome to TCP::Test</motd>
</tsqp>
                };
                $client->send($xml);
            }
            $client->close;
        }
    },
    client => sub {
        my $port = shift;
        my $status = Net::OTServ::status '127.0.0.1', $port;
        ok keys %{ $status } > 0;

        is $status->{owner}{name}, "a3f";
        is $status->{serverinfo}{servername}, "Test::TCP";
        is $status->{serverinfo}{server}, "Test::TCP";
        is $status->{serverinfo}{url}, "127.0.0.1";
        is $status->{players}{online}, 400;
        is $status->{motd}, "Welcome to TCP::Test";

        done_testing;
    }
);
