use strict;
use warnings;
use Test::More;
use IO::Socket::INET;
use POSIX qw(_exit);
use Net::UPnP::HTTP;
use Net::UPnP::Device;
use Net::UPnP::Service;
use Net::UPnP::ControlPoint;
use Net::UPnP::AV::MediaServer;
use Net::UPnP::GW::Gateway;

my $ssdp = "HTTP/1.1 200 OK\r\nLOCATION: http://10.0.0.1:5000/desc.xml\r\n\r\n";

# RT #75747: a device without <serviceList> must not croak.
{
    my $dev = Net::UPnP::Device->new();
    my @list = eval { $dev->getservicelist() };
    is($@, '', 'getservicelist on a new device does not croak');
    is(scalar(@list), 0, 'new device has an empty service list');

    $dev->setdescription('<root><device><deviceType>x</deviceType></device></root>');
    @list = eval { $dev->getservicelist() };
    is($@, '', 'getservicelist without <serviceList> does not croak');
    is(scalar(@list), 0, 'service list is empty');
    is($dev->getservicebyname('urn:x'), undef, 'getservicebyname returns undef');

    $dev->setdescription('<root><serviceList><service><serviceType>urn:a</serviceType></service></serviceList></root>');
    is(scalar($dev->getservicelist()), 1, 'service list is parsed');
    $dev->setdescription('<root></root>');
    is(scalar($dev->getservicelist()), 0, 'a later description without services resets the list');
}

# RT #21076: getposturl must honour the URL passed by the caller.
{
    my $dev = Net::UPnP::Device->new();
    $dev->setssdp($ssdp);
    $dev->setdescription('<root><serviceList><service><controlURL>/ctl/a</controlURL></service></serviceList></root>');
    my ($service) = $dev->getservicelist();
    is($service->getposturl('/other/b'), 'http://10.0.0.1:5000/other/b', 'supplied relative URL is used');
    is($service->getposturl('http://10.0.0.1:6000/x'), 'http://10.0.0.1:6000/x', 'supplied absolute URL is used');
    is($service->getposturl(), 'http://10.0.0.1:5000/ctl/a', 'controlURL is the default');
    is($service->getposturl(''), 'http://10.0.0.1:5000/ctl/a', 'empty argument falls back to controlURL');
}

# RT #21076: exactly one "/" between the host part and a relative controlURL.
{
    my $dev = Net::UPnP::Device->new();
    $dev->setdescription('<root><serviceList><service><controlURL>ctl/a</controlURL></service></serviceList></root>');
    my ($service) = $dev->getservicelist();
    $dev->setssdp("HTTP/1.1 200 OK\r\nLOCATION: http://10.0.0.1:5000/desc.xml\r\n\r\n");
    is($service->getposturl(), 'http://10.0.0.1:5000/ctl/a', 'slash added when LOCATION has a path');
    $dev->setssdp("HTTP/1.1 200 OK\r\nLOCATION: http://10.0.0.1:5000/\r\n\r\n");
    is($service->getposturl(), 'http://10.0.0.1:5000/ctl/a', 'slash added when LOCATION is the root');
    $dev->setssdp("HTTP/1.1 200 OK\r\nLOCATION: http://10.0.0.1\r\n\r\n");
    is($service->getposturl(), 'http://10.0.0.1:80/ctl/a', 'default port and slash when LOCATION has no path');
    is($service->getposturl('/ctl/b'), 'http://10.0.0.1:80/ctl/b', 'no double slash for an absolute path');

    $dev->setdescription('<root><URLBase>http://10.0.0.2:6000/base/</URLBase><serviceList><service><controlURL>/ctl/a</controlURL></service></serviceList></root>');
    ($service) = $dev->getservicelist();
    is($service->getposturl(), 'http://10.0.0.2:6000/base/ctl/a', 'URLBase with trailing slash and absolute path');
    $dev->setdescription('<root><URLBase>http://10.0.0.2:6000</URLBase><serviceList><service><controlURL>ctl/a</controlURL></service></serviceList></root>');
    ($service) = $dev->getservicelist();
    is($service->getposturl(), 'http://10.0.0.2:6000/ctl/a', 'URLBase without trailing slash and relative path');
}

# RT #88755: requests are sent as HTTP/1.1 with Host and Connection: close.
{
    my $listener = IO::Socket::INET->new(LocalAddr => '127.0.0.1', LocalPort => 0,
        Listen => 1, ReuseAddr => 1) or die "listen: $!";
    my $port = $listener->sockport;
    pipe(my $reader, my $writer) or die "pipe: $!";
    my $pid = fork();
    die "fork: $!" unless defined $pid;
    if (!$pid) {
        close $reader;
        alarm 4;
        my $client = $listener->accept() or _exit(1);
        my $head = '';
        while (my $line = <$client>) { $head .= $line; last if $line eq "\r\n"; }
        print $writer $head;
        close $writer;
        print $client "HTTP/1.1 200 OK\r\nTransfer-Encoding: chunked\r\n\r\n2\r\nok\r\n0\r\n\r\n";
        close $client;
        _exit(0);
    }
    close $writer;
    close $listener;
    my $http = Net::UPnP::HTTP->new(timeout => 2);
    my $res = $http->post('127.0.0.1', $port, 'GET', '/desc.xml', '', '');
    my $head = do { local $/; <$reader> };
    waitpid($pid, 0);
    like($head, qr{\AGET /desc\.xml HTTP/1\.1\r\n}, 'request line uses HTTP/1.1');
    like($head, qr{^Host: 127\.0\.0\.1:$port\r$}m, 'Host header is sent');
    like($head, qr{^Connection: close\r$}m, 'Connection: close is sent');
    ok($res && $res->getcontent() eq 'ok', 'chunked HTTP/1.1 response is read');
}

# RT #182943: POSIX::isfinite only exists from perl 5.22, so the limit checks
# must not depend on it. RT #182942: they must also hold on long double perls.
{
    my $inf = 9**9**9;
    ok(Net::UPnP::HTTP::_isfinite(0), 'zero is finite');
    ok(Net::UPnP::HTTP::_isfinite('1.5'), 'decimal string is finite');
    ok(Net::UPnP::HTTP::_isfinite(-1e300), 'large negative number is finite');
    ok(!Net::UPnP::HTTP::_isfinite($inf), 'infinity is not finite');
    ok(!Net::UPnP::HTTP::_isfinite(-$inf), 'negative infinity is not finite');
    ok(!Net::UPnP::HTTP::_isfinite($inf - $inf), 'NaN is not finite');
    ok(!Net::UPnP::HTTP::_isfinite('9' x 5000), 'overflowing digit string is not finite');
    ok(!eval { Net::UPnP::HTTP->new(timeout => '9' x 5000); 1; }, 'overflowing timeout is rejected');

    my @offenders;
    foreach my $module (sort grep { m{\ANet/UPnP} } keys %INC) {
        open(my $fh, '<', $INC{$module}) or next;
        my $source = do { local $/; <$fh> };
        close $fh;
        push @offenders, $module if $source =~ /^\s*use\s+POSIX\b[^;]*\bisfinite\b|POSIX::isfinite\s*\(/m;
    }
    is("@offenders", '', 'no module relies on POSIX::isfinite');
}

done_testing;
