package Net::EPP::Frame::Command::Info::Host;
use base qw(Net::EPP::Frame::Command::Info);
use Net::EPP::Frame::ObjectSpec;
use strict;

=pod

=head1 NAME

Net::EPP::Frame::Command::Info::Host - an instance of L<Net::EPP::Frame::Command::Info>
for host objects.

=head1 SYNOPSIS

	use Net::EPP::Frame::Command::Info::Host;
	use strict;

	my $info = Net::EPP::Frame::Command::Info::Host->new;
	$info->setHost('ns0.example.tld');

	print $info->toString(1);

This results in an XML document like this:

	<?xml version="1.0" encoding="UTF-8"?>
	<epp xmlns="urn:ietf:params:xml:ns:epp-1.0"
	  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
	  xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0
	  epp-1.0.xsd">
	    <command>
	      <info>
	        <host:info
	          xmlns:host="urn:ietf:params:xml:ns:host-1.0"
	          xsi:schemaLocation="urn:ietf:params:xml:ns:host-1.0
	          host-1.0.xsd">
	            <host:name>ns0.example-1.tldE<lt>/host:name>
	        </host:info>
	      </info>
	      <clTRID>0cf1b8f7e14547d26f03b7641660c641d9e79f45</clTRIDE<gt>
	    </command>
	</epp>

=head1 OBJECT HIERARCHY

    L<XML::LibXML::Node>
    +----L<XML::LibXML::Document>
        +----L<Net::EPP::Frame>
            +----L<Net::EPP::Frame::Command>
                +----L<Net::EPP::Frame::Command::Info>
                    +----L<Net::EPP::Frame::Command::Info::Host>

=cut

sub new {
	my $package = shift;
	my $self = bless($package->SUPER::new('info'), $package);

	my $host = $self->addObject(Net::EPP::Frame::ObjectSpec->spec('host'));

	return $self;
}

=pod

=head1 METHODS

	$frame->setHost($host_name);

This specifies the hostname for which information is being requested.

=cut

sub setHost {
	my ($self, $host) = @_;

	my $name = $self->createElement('host:name');
	$name->appendText($host);

	$self->getNode('info')->getChildNodes->shift->appendChild($name);

	return 1;
}

1;
