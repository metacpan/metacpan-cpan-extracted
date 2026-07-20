use v5.42;
use lib 'lib';
use feature 'class';

# Mock Acme::UPnP before anything else loads it
BEGIN {

    package Acme::UPnP;
    our $MOCKED_DISCOVER_DEVICE_CALLED = 0;
    our $MOCKED_DEVICE_FOUND           = 0;

    sub new {
        my $class = shift;
        return bless { on => {} }, $class;
    }
    sub is_available {1}

    sub on {
        my ( $self, $event, $cb ) = @_;
        push @{ $self->{on}{$event} }, $cb;
    }

    sub _emit {
        my ( $self, $event, @args ) = @_;
        for my $cb ( @{ $self->{on}{$event} // [] } ) {
            $cb->(@args);
        }
    }

    sub discover_device {
        my ($self) = @_;
        $MOCKED_DISCOVER_DEVICE_CALLED = 1;
        if ($MOCKED_DEVICE_FOUND) {
            $self->_emit( 'device_found', { name => 'Mock Router' } );
            return 1;
        }
        $self->_emit('device_not_found');
        return 0;
    }

    sub upnp_device {
        return $MOCKED_DEVICE_FOUND ? bless( {}, 'Net::UPnP::Device' ) : undef;
    }

    sub get_external_ip {
        return $MOCKED_DEVICE_FOUND ? '1.2.3.4' : undef;
    }
    sub map_port   {1}
    sub unmap_port {1}
    $INC{'Acme/UPnP.pm'} = 1;
}
use Test2::V1 -ipP;
no warnings;
use Net::BitTorrent;
subtest 'UPnP Disabled by Default' => sub {
    my $client = Net::BitTorrent->new();
    ok !$client->port_mapper, 'PortMapper is not initialized when UPnP is disabled by default';
};
subtest 'UPnP Disabled Explicitly' => sub {
    my $client = Net::BitTorrent->new( upnp_enabled => 0 );
    ok !$client->port_mapper, 'PortMapper is not initialized when UPnP is explicitly disabled';
};
subtest 'UPnP Enabled without Device' => sub {
    $Acme::UPnP::MOCKED_DEVICE_FOUND           = 0;
    $Acme::UPnP::MOCKED_DISCOVER_DEVICE_CALLED = 0;
    my $client = Net::BitTorrent->new( upnp_enabled => 1 );
    ok $client->port_mapper, 'PortMapper is initialized when UPnP is enabled';
    is $Acme::UPnP::MOCKED_DISCOVER_DEVICE_CALLED, 1,     'discover_device was called';
    is $client->port_mapper->upnp_device,          undef, 'No UPnP device found internally';
    is $client->port_mapper->get_external_ip(),    undef, 'get_external_ip returns undef when no device';
};
subtest 'UPnP Enabled with Device' => sub {
    $Acme::UPnP::MOCKED_DEVICE_FOUND           = 1;
    $Acme::UPnP::MOCKED_DISCOVER_DEVICE_CALLED = 0;
    my $client = Net::BitTorrent->new( upnp_enabled => 1 );
    ok $client->port_mapper,              'PortMapper is initialized when UPnP is enabled';
    ok $client->port_mapper->upnp_device, 'UPnP device found internally';
    is $Acme::UPnP::MOCKED_DISCOVER_DEVICE_CALLED, 1,         'discover_device was called';
    is $client->port_mapper->get_external_ip(),    '1.2.3.4', 'get_external_ip returns mocked IP';

    # Test unmapping during shutdown
    $client->shutdown();
};
done_testing;
