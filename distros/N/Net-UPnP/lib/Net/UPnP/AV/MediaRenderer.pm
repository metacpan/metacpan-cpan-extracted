package Net::UPnP::AV::MediaRenderer;

#-----------------------------------------------------------------
# Net::UPnP::AV::Renderer
#-----------------------------------------------------------------

use strict;
use warnings;

use Net::UPnP::HTTP;
use Net::UPnP::Device;
use Net::UPnP::Service;
use Net::UPnP::AV::Container;
use Net::UPnP::AV::Item;

use vars qw($_DEVICE $DEVICE_TYPE $AVTRNSPORT_SERVICE_TYPE);

$_DEVICE = 'device';

$DEVICE_TYPE = 'urn:schemas-upnp-org:device:MediaRenderer:1';
$AVTRNSPORT_SERVICE_TYPE = 'urn:schemas-upnp-org:service:AVTransport:1';

#------------------------------
# new
#------------------------------

sub new {
	my($class) = shift;
	my($this) = {
		$Net::UPnP::AV::MediaRenderer::_DEVICE => undef,
	};
	bless $this, $class;
}

#------------------------------
# device
#------------------------------

sub setdevice() {
	my($this) = shift;
	if (@_) {
		$this->{$Net::UPnP::AV::MediaRenderer::_DEVICE} = $_[0];
	}
}

sub getdevice() {
	my($this) = shift;
	$this->{$Net::UPnP::AV::MediaRenderer::_DEVICE};
}

#------------------------------
# setAVTransportURI
#------------------------------

sub setAVTransportURI {
	my($this) = shift;
	my %args = (
		InstanceID => 0,	
		CurrentURI => '',
		CurrentURIMetaData => '',
		@_,
	);
	
	my (
		$dev,
		$avtrans_service,
		%req_arg,
	);
	
	$dev = $this->getdevice();
	$avtrans_service = $dev->getservicebyname($Net::UPnP::AV::MediaRenderer::AVTRNSPORT_SERVICE_TYPE);
	
	%req_arg = (
		'InstanceID' => $args{InstanceID},
		'CurrentURI' => $args{CurrentURI},
		'CurrentURIMetaData' => $args{CurrentURIMetaData},
	);
	
	$avtrans_service->postaction("SetAVTransportURI", \%req_arg);
}

#------------------------------
# setNextAVTransportURI
#------------------------------

sub setNextAVTransportURI {
	my($this) = shift;
	my %args = (
		InstanceID => 0,	
		NextURI => '',
		NextURIMetaData => '',
		@_,
	);
	
	my (
		$dev,
		$avtrans_service,
		%req_arg,
	);
	
	$dev = $this->getdevice();
	$avtrans_service = $dev->getservicebyname($Net::UPnP::AV::MediaRenderer::AVTRNSPORT_SERVICE_TYPE);
	
	%req_arg = (
			'InstanceID' => $args{InstanceID},
			'NextURI' => $args{NextURI},
			'NextURIMetaData' => $args{NextURIMetaData},
		);
	
	$avtrans_service->postaction("SetNextAVTransportURI", \%req_arg);
}

#------------------------------
# Play
#------------------------------

sub play {
	my($this) = shift;
	my %args = (
		InstanceID => 0,	
		Speed => 1,
		@_,
	);
	
	my (
		$dev,
		$avtrans_service,
		%req_arg,
	);
	
	$dev = $this->getdevice();
	$avtrans_service = $dev->getservicebyname($Net::UPnP::AV::MediaRenderer::AVTRNSPORT_SERVICE_TYPE);
	
	%req_arg = (
		'InstanceID' => $args{InstanceID},
		'Speed' => $args{Speed},
	);
	
	$avtrans_service->postaction("Play", \%req_arg);
}

#------------------------------
# Stop
#------------------------------

sub stop {
	my($this) = shift;
	my %args = (
		InstanceID => 0,	
		@_,
	);
	
	my (
		$dev,
		$avtrans_service,
		%req_arg,
	);
	
	$dev = $this->getdevice();
	$avtrans_service = $dev->getservicebyname($Net::UPnP::AV::MediaRenderer::AVTRNSPORT_SERVICE_TYPE);
	
	%req_arg = (
		'InstanceID' => $args{InstanceID},
	);
	
	$avtrans_service->postaction("Stop", \%req_arg);
}

1;

__END__

=head1 NAME

Net::UPnP::AV::MediaRenderer - Perl extension for UPnP.

=head1 SYNOPSIS

    use Net::UPnP::ControlPoint;
    use Net::UPnP::AV::MediaRenderer;
 
    my $obj = Net::UPnP::ControlPoint->new();
 
    @dev_list = ();
    while (@dev_list <= 0 || $retry_cnt > 5) {
        @dev_list = $obj->search(st =>'upnp:rootdevice', mx => 3);
        $retry_cnt++;
    } 
 
    $devNum= 0;
    foreach $dev (@dev_list) {
        my $device_type = $dev->getdevicetype();
        if  ($device_type ne 'urn:schemas-upnp-org:device:MediaRenderer:1') {
            next;
        }
        my $friendlyname = $dev->getfriendlyname(); 
        print "[$devNum] : " . $friendlyname . "\n";
        my $renderer = Net::UPnP::AV::MediaRenderer->new();
        $renderer->setdevice($dev);
        $renderer->stop();
        $renderer->setAVTransportURI(CurrentURI => 'http://xxx.xxx.xxx.xxx/xxxx.mpg');
        $renderer->play(); 
        $devNum++;
    }
 
=head1 DESCRIPTION

The package is a extention UPnP/AV media server.

=head1 METHODS

=over 4

=item B<new> - create new Net::UPnP::AV::MediaRenderer.

    $renderer = Net::UPnP::AV::MediaRenderer();

Creates a new object. Read `perldoc perlboot` if you don't understand that.

The new object is not associated with any UPnP devices. Please use setdevice() to set the device.

=item B<setdevice> - set a UPnP devices

    $renderer->setdevice($dev);

Set a device to the object.

=item B<setAVTransportURI> - set a current content.
	
    @action_response = $renderer->setAVTransportURI(
                                        InstanceID => $instanceID, # 0	
                                        CurrentURI => $url, # ''
                                        CurrentURIMetaData => $metaData, # "'
                                        );

Set a current content to play, L<Net::UPnP::ActionResponse>.

=item B<setNextAVTransportURI> - set a next content.
 
	@action_response = $renderer->setNextAVTransportURI(
										InstanceID => $instanceID, # 0	
                                        NextURI => $url, # ''
                                        NextURIMetaData => $metaData, # "'
										);
 
Set a next content to play, L<Net::UPnP::ActionResponse>.
 
=item B<play> - play.
	
    @action_response = $renderer->play(
										InstanceID => $instanceID, # 0	
										Speed => $url, # 1
 										);
 
Play the specified content.

=item B<stop> - stop.
 
    @action_response = $renderer->stop(
										InstanceID => $instanceID, # 0	
										);
 
Stop the playing content.
 
=back

=head1 SEE ALSO

L<Net::UPnP::AV::Content>

L<Net::UPnP::AV::Item>

L<Net::UPnP::AV::Container>

=head1 AUTHOR

Satoshi Konno
skonno@cybergarage.org

CyberGarage
http://www.cybergarage.org

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Satoshi Konno

It may be used, redistributed, and/or modified under the terms of BSD License.

=cut
