use strict;
use warnings;
use Test::More;
use IO::Socket::INET;
use Time::HiRes qw(time sleep);
use Socket;
use POSIX qw(_exit);
use Net::UPnP::ControlPoint;
use Net::UPnP::GW::Gateway;
use Net::UPnP::ActionResponse;
use Net::UPnP::QueryResponse;

sub discover {
    my ($sender, $options) = @_;
    my $udp = IO::Socket::INET->new(LocalAddr => '127.0.0.1',
        LocalPort => 0, Proto => 'udp') or die $!;
    my $port = $udp->sockport;
    my $pid = fork();
    die $! unless defined $pid;
    if (!$pid) {
        alarm 3;
        my $peer = recv($udp, my $request, 4096, 0);
        $sender->($udp, $peer);
        _exit(0);
    }
    close $udp;
    local $Net::UPnP::SSDP_ADDR = '127.0.0.1';
    local $Net::UPnP::SSDP_PORT = $port;
    my $control = Net::UPnP::ControlPoint->new();
    my $start = time();
    my @devices = $control->search(mx => 0.05,
        allowed_addresses => ['127.0.0.1'], %{$options || {}});
    my $elapsed = time() - $start;
    kill 'KILL', $pid;
    waitpid($pid, 0);
    return (\@devices, $control->geterror(), $elapsed);
}

{
    my ($devices, $error, $elapsed) = discover(sub {
        my ($udp, $peer) = @_;
        for (1 .. 100) { send($udp, "invalid\r\n", 0, $peer); sleep 0.01; }
    });
    is(scalar(@$devices), 0, 'invalid flood creates no devices');
    cmp_ok($elapsed, '<', 0.6, 'invalid flood cannot reset discovery deadline');
}

{
    my ($devices, $error) = discover(sub {
        my ($udp, $peer) = @_;
        for (1 .. 20) { send($udp, "invalid\r\n", 0, $peer); }
    }, {max_packets => 4});
    like($error, qr/packet limit/, 'invalid packets consume bounded packet budget');
}

{
    no warnings 'redefine';
    my $gets = 0;
    local *Net::UPnP::HTTP::post = sub {
        ++$gets;
        my $res = Net::UPnP::HTTPResponse->new();
        $res->setstatus("HTTP/1.0 200 OK\r\n");
        $res->setcontent('<root><friendlyName>test</friendlyName></root>');
        return $res;
    };
    my ($devices, $error) = discover(sub {
        my ($udp, $peer) = @_;
        for (1 .. 20) {
            send($udp, "HTTP/1.1 200 OK\r\nUSN: $_\r\nLOCATION: http://127.0.0.1/desc\r\n\r\n", 0, $peer);
        }
    });
    is($gets, 1, 'same LOCATION with changing USN fetched once');
    is(scalar(@$devices), 1, 'duplicate replies produce one device');
    is($devices->[0]->getfriendlyname(), 'test', 'normal description preserved');
    $gets = 0;
    ($devices, $error) = discover(sub {
        my ($udp, $peer) = @_;
        for (1 .. 20) {
            send($udp, "LOCATION: http://127.0.0.1/$_\r\n", 0, $peer);
        }
    }, {max_devices => 2});
    is(scalar(@$devices), 2, 'device cap returns bounded partial results');
    is($gets, 2, 'device cap also stops fetches');
    like($error, qr/device limit/, 'partial result has explicit diagnostic');
}

{
    no warnings 'redefine';
    my $gets = 0;
    local *Net::UPnP::HTTP::post = sub { ++$gets; return ''; };
    my ($devices) = discover(sub {
        my ($udp, $peer) = @_;
        for (1 .. 20) { send($udp, "LOCATION: http://127.0.0.1/failed\r\n", 0, $peer); }
    });
    is(scalar(@$devices), 0, 'failed HTTP remains safe for discovery');
    is($gets, 1, 'failed LOCATION cannot be retried without bound');
}

{
    my $tcp = IO::Socket::INET->new(LocalAddr => '127.0.0.1', LocalPort => 0,
        Listen => 1, ReuseAddr => 1) or die $!;
    my $port = $tcp->sockport;
    my $pid = fork(); die $! unless defined $pid;
    if (!$pid) {
        alarm 3;
        my $client = $tcp->accept();
        sleep 2;
        _exit(0);
    }
    close $tcp;
    my ($devices, $error, $elapsed) = discover(sub {
        send($_[0], "LOCATION: http://127.0.0.1:$port/desc\r\n", 0, $_[1]);
        sleep 1;
    });
    kill 'KILL', $pid; waitpid($pid, 0);
    is(scalar(@$devices), 0, 'stalled final description returns no invalid device');
    cmp_ok($elapsed, '<', 0.6, 'description GET uses remaining discovery deadline');
}

{
    package Local::Service;
    sub new { bless { calls => 0, @_ > 1 ? @_[1 .. $#_] : () }, $_[0] }
    sub postaction {
        my ($self, $name, $args, $options) = @_;
        ++$self->{calls};
        $self->{deadline} = $options->{deadline};
        Time::HiRes::sleep($self->{delay}) if $self->{delay};
        my $http = Net::UPnP::HTTPResponse->new();
        $http->setstatus($self->{stop} && $self->{calls} > $self->{stop}
            ? "HTTP/1.0 500 Finished\r\n" : "HTTP/1.0 200 OK\r\n");
        $http->setcontent('<Response><NewInternalPort>80</NewInternalPort></Response>');
        my $res = Net::UPnP::ActionResponse->new();
        $res->sethttpresponse($http);
        return $res;
    }
    sub postquery {
        my $http = Net::UPnP::HTTPResponse->new();
        $http->setstatus("HTTP/1.0 200 OK\r\n");
        $http->setcontent('<return>not-a-count</return>');
        my $res = Net::UPnP::QueryResponse->new();
        $res->sethttpresponse($http);
        return $res;
    }
    package Local::Device;
    sub getservicebyname { $_[0]->{service} }
}

sub gateway {
    my (%options) = @_;
    my $service = Local::Service->new(%options);
    my $device = bless {service => $service}, 'Local::Device';
    my $gateway = Net::UPnP::GW::Gateway->new();
    $gateway->setdevice($device);
    return ($gateway, $service);
}

{
    my ($gateway, $service) = gateway();
    my @entries = $gateway->getportmappingentries(max_entries => 3);
    is(scalar(@entries), 3, 'endless success has bounded entries');
    is($service->{calls}, 3, 'entry cap bounds requests');
    like($gateway->geterror(), qr/entry limit/, 'truncation diagnostic visible');
    cmp_ok($service->{deadline}, '>', Net::UPnP::HTTP::_now(), 'overall deadline reaches SOAP transport');
    @entries = $gateway->getportmappingentry(max_entries => 2);
    is(scalar(@entries), 2, 'deprecated enumeration alias retains cap');
}

{
    my ($gateway, $service) = gateway(stop => 2);
    my @entries = $gateway->getportmappingentries();
    is(scalar(@entries), 2, 'normal terminating gateway retains all mappings');
    is($gateway->geterror(), '', 'normal termination is not truncation');
    ($gateway, $service) = gateway();
    is($gateway->getportmappingnumberofentries(), 1024, 'invalid-count fallback uses bounded enumeration');
    like($gateway->geterror(), qr/entry limit/, 'fallback exposes truncation');
}

{
    my ($gateway, $service) = gateway(delay => 0.03);
    my @entries = $gateway->getportmappingentries(timeout => 0.05);
    cmp_ok($service->{calls}, '<=', 2, 'overall deadline stops fast successful exchanges');
    like($gateway->geterror(), qr/deadline/, 'overall enumeration deadline diagnostic');
}

for my $options ({mx => '9' x 400}, {max_packets => '9' x 400}) {
    my $ok = eval { Net::UPnP::ControlPoint->new()->search(%$options); 1; };
    ok(!$ok, 'nonfinite discovery limit rejected before socket setup');
}
for my $options ({timeout => '9' x 400}, {max_entries => '9' x 400}) {
    my ($gateway) = gateway();
    my $ok = eval { $gateway->getportmappingentries(%$options); 1; };
    ok(!$ok, 'nonfinite gateway limit rejected');
}

done_testing;
