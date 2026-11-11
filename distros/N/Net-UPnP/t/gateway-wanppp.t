use strict;
use warnings;
use Test::More;
use Net::UPnP::Device;
use Net::UPnP::Service;
use Net::UPnP::HTTPResponse;
use Net::UPnP::ActionResponse;
use Net::UPnP::GW::Gateway;

# RT #60372: dial-up routers expose WANPPPConnection instead of WANIPConnection.

my $IP  = 'urn:schemas-upnp-org:service:WANIPConnection:1';
my $PPP = 'urn:schemas-upnp-org:service:WANPPPConnection:1';

sub device {
    my (@types) = @_;
    my $services = join '', map {
        "<service><serviceType>$_</serviceType><controlURL>/ctl/$_</controlURL></service>"
    } @types;
    my $dev = Net::UPnP::Device->new();
    $dev->setssdp("HTTP/1.1 200 OK\r\nLOCATION: http://192.168.1.1:5000/rootDesc.xml\r\n\r\n");
    $dev->setdescription("<root><device><serviceList>$services</serviceList></device></root>");
    return $dev;
}

# Record which service type and action each SOAP call goes to.
my @calls;
my %replies = (
    GetExternalIPAddress => '<NewExternalIPAddress>203.0.113.7</NewExternalIPAddress>',
    GetStatusInfo => '<NewConnectionStatus>Connected</NewConnectionStatus>'
        . '<NewLastConnectionError>ERROR_NONE</NewLastConnectionError><NewUptime>3600</NewUptime>',
    GetConnectionTypeInfo => '<NewConnectionType>IP_Routed</NewConnectionType>'
        . '<NewPossibleConnectionTypes>IP_Routed</NewPossibleConnectionTypes>',
    GetLinkLayerMaxBitRates => '<NewUpstreamMaxBitRate>1000000</NewUpstreamMaxBitRate>'
        . '<NewDownstreamMaxBitRate>8000000</NewDownstreamMaxBitRate>',
    AddPortMapping => '',
    DeletePortMapping => '',
);
{
    no warnings 'redefine';
    *Net::UPnP::Service::postaction = sub {
        my ($service, $name) = @_;
        push @calls, [$service->getservicetype(), $name];
        my $http = Net::UPnP::HTTPResponse->new();
        $http->setstatus(exists $replies{$name} ? "HTTP/1.1 200 OK\r\n" : "HTTP/1.1 500 Error\r\n");
        $http->setcontent("<s:Envelope><s:Body><u:${name}Response>"
            . ($replies{$name} || '') . "</u:${name}Response></s:Body></s:Envelope>");
        my $res = Net::UPnP::ActionResponse->new();
        $res->sethttpresponse($http);
        return $res;
    };
}

{
    my $gw = Net::UPnP::GW::Gateway->new();
    $gw->setdevice(device($PPP));
    ok($gw->getconnectionservice(), 'WANPPPConnection-only router has a connection service');
    is($gw->getconnectionservicetype(), $PPP, 'falls back to WANPPPConnection');

    @calls = ();
    is($gw->getexternalipaddress(), '203.0.113.7', 'external IP address via WANPPPConnection');
    ok($gw->addportmapping(NewExternalPort => 8080, NewProtocol => 'TCP'), 'add port mapping via WANPPPConnection');
    ok($gw->deleteportmapping(NewExternalPort => 8080, NewProtocol => 'TCP'), 'delete port mapping via WANPPPConnection');
    is_deeply([map { $_->[0] } @calls], [($PPP) x 3], 'all actions go to WANPPPConnection');

    is_deeply($gw->getstatusinfo(),
        {ConnectionStatus => 'Connected', LastConnectionError => 'ERROR_NONE', Uptime => 3600},
        'getstatusinfo');
    is($gw->getconnectiontypeinfo()->{ConnectionType}, 'IP_Routed', 'getconnectiontypeinfo');
    is_deeply($gw->getlinklayermaxbitrates(),
        {UpstreamMaxBitRate => 1000000, DownstreamMaxBitRate => 8000000},
        'getlinklayermaxbitrates on WANPPPConnection');
}

{
    my $gw = Net::UPnP::GW::Gateway->new();
    $gw->setdevice(device($PPP, $IP));
    is($gw->getconnectionservicetype(), $IP, 'WANIPConnection is preferred when both exist');
    @calls = ();
    $gw->getexternalipaddress();
    is($calls[0][0], $IP, 'default behaviour is unchanged for WANIPConnection routers');
    @calls = ();
    is($gw->getlinklayermaxbitrates(), undef, 'getlinklayermaxbitrates is undef on WANIPConnection');
    is(scalar(@calls), 0, 'no unsupported action is sent');

    $gw->setconnectionservicetype($PPP);
    is($gw->getconnectionservicetype(), $PPP, 'setconnectionservicetype selects WANPPPConnection');
    $gw->setconnectionservicetype(undef);
    is($gw->getconnectionservicetype(), $IP, 'undef restores the default order');

    my $only = Net::UPnP::GW::Gateway->new(connection_service_type => $PPP);
    $only->setdevice(device($IP));
    is($only->getconnectionservice(), undef, 'explicit type does not fall back');
    is($only->getexternalipaddress(), '', 'methods fail cleanly without the service');
    is($only->getstatusinfo(), undef, 'getstatusinfo is undef without the service');
}

{
    my $gw = Net::UPnP::GW::Gateway->new();
    $gw->setdevice(device('urn:schemas-upnp-org:service:Layer3Forwarding:1'));
    is($gw->getconnectionservice(), undef, 'no connection service');
    is($gw->getconnectionservicetype(), '', 'empty connection service type');
    is($gw->getportmappingnumberofentries(), 0, 'no port mappings without a connection service');
    is(Net::UPnP::GW::Gateway->new()->getconnectionservice(), undef, 'no device');
}

done_testing;
