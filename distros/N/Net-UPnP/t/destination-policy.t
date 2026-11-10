use strict;
use warnings;
use Test::More;
use Socket;
use IO::Socket::INET;
use POSIX qw(_exit);
use Net::UPnP::ControlPoint;
use Net::UPnP::Device;

for my $host ('127.0.0.1', '127.1', '2130706433', '0x7f000001', 'localhost') {
    my $http = Net::UPnP::HTTP->new(allowed_addresses => ['192.0.2.1']);
    ok(!$http->post($host, 9, 'GET', '/', '', ''), "$host is rejected");
    like($http->geterror(), qr/destination not permitted/, 'resolved address is checked before connect');
}

{
    my $list = ['127.0.0.1'];
    my $http = Net::UPnP::HTTP->new(allowed_addresses => $list);
    $list->[0] = '127.0.0.2';
    ok(!$http->post('127.0.0.2', 9, 'GET', '/', '', ''), 'caller list is copied');
    like($http->geterror(), qr/not permitted/, 'list mutation cannot change policy');
    my $deny = Net::UPnP::HTTP->new(allowed_addresses => []);
    ok(!$deny->post('127.0.0.1', 9, 'GET', '/', '', ''), 'empty policy denies all');
}

sub http_server {
    my ($body) = @_;
    my $server = IO::Socket::INET->new(LocalAddr => '127.0.0.1', LocalPort => 0,
        Listen => 1, ReuseAddr => 1) or die $!;
    my $port = $server->sockport;
    my $pid = fork(); die $! unless defined $pid;
    if (!$pid) {
        alarm 3;
        my $client = $server->accept() or _exit(1);
        while (my $line = <$client>) { last if $line eq "\r\n"; }
        print $client "HTTP/1.0 200 OK\r\nContent-Length: " . length($body) . "\r\n\r\n$body";
        close $client;
        _exit(0);
    }
    close $server;
    return ($port, $pid);
}

sub cleanup { kill 'KILL', $_[0]; waitpid($_[0], 0); }

{
    my ($port, $pid) = http_server('ok');
    my $res = Net::UPnP::HTTP->new()->post('127.0.0.1', $port, 'GET', '/', '', '');
    ok($res && $res->getcontent() eq 'ok', 'trusted direct HTTP retains loopback support');
    cleanup($pid);
}

{
    no warnings 'redefine';
    my $resolutions = 0;
    local *Net::UPnP::HTTP::_resolve = sub {
        ++$resolutions;
        return pack('C4', 127, 0, 0, $resolutions == 1 ? 1 : 2);
    };
    my ($port, $pid) = http_server('pinned');
    my $http = Net::UPnP::HTTP->new(allowed_addresses => ['127.0.0.1']);
    my $res = $http->post('changing.invalid', $port, 'GET', '/', '', '');
    ok($res && $res->getcontent() eq 'pinned', 'checked packed address is used for connection');
    is($resolutions, 1, 'no second resolution between check and use');
    ok(!$http->post('changing.invalid', $port, 'GET', '/', '', ''), 'later DNS change is rejected');
    like($http->geterror(), qr/not permitted/, 'policy reevaluated on each request');
    cleanup($pid);
}

sub discover_local {
    my ($allow, $location) = @_;
    my $udp = IO::Socket::INET->new(LocalAddr => '127.0.0.1', LocalPort => 0,
        Proto => 'udp') or die $!;
    my $port = $udp->sockport;
    my $pid = fork(); die $! unless defined $pid;
    if (!$pid) {
        alarm 3;
        my $peer = recv($udp, my $request, 4096, 0);
        send($udp, "HTTP/1.1 200 OK\r\nLOCATION: $location\r\n\r\n", 0, $peer);
        _exit(0);
    }
    close $udp;
    local $Net::UPnP::SSDP_ADDR = '127.0.0.1';
    local $Net::UPnP::SSDP_PORT = $port;
    my $cp = Net::UPnP::ControlPoint->new();
    my @devices = $cp->search(mx => 0.1, allowed_addresses => $allow);
    cleanup($pid);
    return ($cp, @devices);
}

{
    my ($cp, @devices) = discover_local([], 'http://127.0.0.1:9/desc');
    is(scalar(@devices), 0, 'loopback LOCATION has no implicit discovery trust');
    like($cp->geterror(), qr/not permitted/, 'blocked discovery exposes diagnostic');
    ($cp, @devices) = discover_local(['127.0.0.1'], 'http://127.0.0.2:9/desc');
    is(scalar(@devices), 0, 'different host is not authorized by a trusted peer');
}

{
    my $description = '<root><URLBase>http://127.0.0.2/</URLBase><serviceList><service><serviceType>test</serviceType><controlURL>/control</controlURL></service></serviceList></root>';
    my ($port, $pid) = http_server($description);
    my ($cp, @devices) = discover_local(['127.0.0.1'], "http://127.0.0.1:$port/desc");
    cleanup($pid);
    is(scalar(@devices), 1, 'explicitly trusted local device is discoverable');
    if (@devices) {
        my ($service) = $devices[0]->getservicelist();
        is_deeply($devices[0]->getallowedaddresses(), ['127.0.0.1'], 'discovered policy retained on device');
        for my $control ('/control', 'http://127.0.0.2/control') {
            $service->setdevicedescription("<serviceType>test</serviceType><controlURL>$control</controlURL>");
            is($service->postaction('Test', {})->getstatuscode(), 0, 'action rejects URLBase/absolute cross-host target');
            is($service->postcontrol('Test', {})->getstatuscode(), 0, 'deprecated action alias retains policy');
            is($service->postquery('Test')->getstatuscode(), 0, 'query rejects URLBase/absolute cross-host target');
            is($service->postaction('Test', {}, {allowed_addresses => ['127.0.0.2']})->getstatuscode(),
                0, 'HTTP tuning cannot replace device policy');
        }
        my $copy = $devices[0]->getallowedaddresses();
        push @$copy, '127.0.0.2';
        is_deeply($devices[0]->getallowedaddresses(), ['127.0.0.1'], 'returned policy is a copy');
    }
}

{
    my ($port, $pid) = http_server('<Response><ok>yes</ok></Response>');
    my $dev = Net::UPnP::Device->new();
    $dev->setallowedaddresses(['127.0.0.1']);
    $dev->setssdp("LOCATION: http://127.0.0.1:$port/desc\r\n");
    $dev->setdescription('<serviceList><service><serviceType>test</serviceType><controlURL>/control</controlURL></service></serviceList>');
    my ($service) = $dev->getservicelist();
    is($service->postaction('Test', {})->getstatuscode(), 200, 'same-host SOAP with device policy remains valid');
    cleanup($pid);
}

for my $bad (undef, '127.0.0.1', ['localhost'], ['127.0.0.999']) {
    my $ok = eval { Net::UPnP::HTTP->new(allowed_addresses => $bad); 1; };
    ok(!$ok, 'invalid destination policy rejected explicitly');
}

done_testing;
