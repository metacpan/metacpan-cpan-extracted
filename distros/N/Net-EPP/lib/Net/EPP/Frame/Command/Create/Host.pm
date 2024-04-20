package Net::EPP::Frame::Command::Create::Host;
use List::Util qw(any);
use base       qw(Net::EPP::Frame::Command::Create);
use Net::EPP::Frame::ObjectSpec;
use strict;

=pod

=head1 NAME

Net::EPP::Frame::Command::Create::Host - an instance of L<Net::EPP::Frame::Command::Create>
for host objects.

=head1 SYNOPSIS

	use Net::EPP::Frame::Command::Create::Host;
	use strict;

	my $create = Net::EPP::Frame::Command::Create::Host->new;
	$create->setHost('ns1.example.uk.com);

	print $create->toString(1);

This results in an XML document like this:

	<?xml version="1.0" encoding="UTF-8"?>
	<epp xmlns="urn:ietf:params:xml:ns:epp-1.0"
	  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
	  xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0
	  epp-1.0.xsd">
	    <command>
	      <create>
	        <host:create
	          xmlns:contact="urn:ietf:params:xml:ns:host-1.0"
	          xsi:schemaLocation="urn:ietf:params:xml:ns:host-1.0
	          host-1.0.xsd">
	            <host:name>ns1.example.uk.com</host:name>
	        </domain:create>
	      </create>
	      <clTRID>0cf1b8f7e14547d26f03b7641660c641d9e79f45</clTRIDE>
	    </command>
	</epp>


=head1 OBJECT HIERARCHY

    L<XML::LibXML::Node>
    +----L<XML::LibXML::Document>
        +----L<Net::EPP::Frame>
            +----L<Net::EPP::Frame::Command>
                +----L<Net::EPP::Frame::Command::Create>
                    +----L<Net::EPP::Frame::Command::Create::Host>

=cut

sub new {
    my $package = shift;
    my $self    = bless($package->SUPER::new('create'), $package);

    $self->addObject(Net::EPP::Frame::ObjectSpec->spec('host'));

    return $self;
}

=pod

=head1 METHODS

	my $element = $frame->setHost($host_name);

This sets the name of the object to be created. Returns the
<E<lt>host:nameE<gt>> element.

=cut

sub setHost {
    my ($self, $host) = @_;

    my $name = $self->createElement('host:name');
    $name->appendText($host);

    $self->getNode('create')->getChildNodes->shift->appendChild($name);

    return 1;
}

=pod

	$frame->setAddr({ 'ip' => '10.0.0.1', 'version' => 'v4' });

This adds an IP address to the host object. EPP supports multiple 
addresses of different versions.

=cut

sub setAddr {
    my ($self, @addr) = @_;

    foreach my $ip (@addr) {
        my $hostAttr = $self->createElement('host:addr');
        $hostAttr->appendText($ip->{ip});
        $hostAttr->setAttribute('ip', $ip->{version});
        $self->getNode('create')->getChildNodes->shift->appendChild($hostAttr);
    }
    return 1;
}

=pod

=head2 TTL Extension

    $frame->setTTLs({
        A => 3600,
        AAAA => 900,
    });

Specify TTLs for glue records. The server must support the
TTL extension.

=cut

sub setTTLs {
    my ($self, $ttls) = @_;

    foreach my $type (keys(%{$ttls})) {
        my $ttl = $self->createExtensionElementFor(Net::EPP::Frame::ObjectSpec->xmlns('ttl'))->appendChild($self->createElement('ttl'));
        $ttl->appendText($ttls->{$type});
        if (any { $type eq $_ } qw(NS DS DNAME A AAAA)) {
            $ttl->setAttribute('for', $type);

        } else {
            $ttl->setAttribute('for',    'custom');
            $ttl->setAttribute('custom', $type);

        }
    }
}

1;
