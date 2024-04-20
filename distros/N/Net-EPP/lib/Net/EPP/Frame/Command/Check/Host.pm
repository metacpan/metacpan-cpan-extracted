package Net::EPP::Frame::Command::Check::Host;
use base qw(Net::EPP::Frame::Command::Check);
use Net::EPP::Frame::ObjectSpec;
use strict;

=pod

=head1 NAME

Net::EPP::Frame::Command::Check::Host - an instance of L<Net::EPP::Frame::Command::Check>
for host objects.

=head1 SYNOPSIS

	use Net::EPP::Frame::Command::Check::Host;
	use strict;

	my $check = Net::EPP::Frame::Command::Check::Host->new;
	$check->addHost('example-1.tld');
	$check->addHost('example-2.tld');
	$check->addHost('example-2.tld');

	print $check->toString(1);

This results in an XML document like this:

	<?xml version="1.0" encoding="UTF-8"?>
	<epp xmlns="urn:ietf:params:xml:ns:epp-1.0"
	  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
	  xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0
	  epp-1.0.xsd">
	    <command>
	      <check>
	        <host:check
	          xmlns:host="urn:ietf:params:xml:ns:host-1.0"
	          xsi:schemaLocation="urn:ietf:params:xml:ns:host-1.0
	          host-1.0.xsd">
	            <host:name>ns0.example-1.tldE<lt>/host:name>
	            <host:name>ns1.example-2.tldE<lt>/host:name>
	            <host:name>ns2.example-3.tldE<lt>/host:name>
	        </host:check>
	      </check>
	      <clTRID>0cf1b8f7e14547d26f03b7641660c641d9e79f45</clTRIDE<gt>
	    </command>
	</epp>

=head1 OBJECT HIERARCHY

    L<XML::LibXML::Node>
    +----L<XML::LibXML::Document>
        +----L<Net::EPP::Frame>
            +----L<Net::EPP::Frame::Command>
                +----L<Net::EPP::Frame::Command::Check>
                    +----L<Net::EPP::Frame::Command::Check::Host>

=cut

sub new {
    my $package = shift;
    my $self    = bless($package->SUPER::new('check'), $package);

    $self->addObject(Net::EPP::Frame::ObjectSpec->spec('host'));

    return $self;
}

=pod

=head1 METHODS

	$frame->addHost($host_name);

This adds a hostname to the list of hosts to be checked.

=cut

sub addHost {
    my ($self, $host) = @_;

    my $name = $self->createElement('host:name');
    $name->appendText($host);

    $self->getNode('check')->getChildNodes->shift->appendChild($name);

    return 1;
}

1;
