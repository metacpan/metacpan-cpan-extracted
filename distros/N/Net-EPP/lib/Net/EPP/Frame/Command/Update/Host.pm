# Copyright (c) 2016 CentralNic Ltd. All rights reserved. This program is
# free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.
# 
# $Id: Host.pm,v 1.3 2011/01/23 12:26:24 gavin Exp $
package Net::EPP::Frame::Command::Update::Host;
use base qw(Net::EPP::Frame::Command::Update);
use Net::EPP::Frame::ObjectSpec;
use strict;

=pod

=head1 NAME

Net::EPP::Frame::Command::Update::Host - an instance of L<Net::EPP::Frame::Command::Update>
for host objects.

=head1 SYNOPSIS

	use Net::EPP::Frame::Command::Update::Host;
	use strict;

	my $info = Net::EPP::Frame::Command::Update::Host->new;
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
	        <host:update
	          xmlns:host="urn:ietf:params:xml:ns:host-1.0"
	          xsi:schemaLocation="urn:ietf:params:xml:ns:host-1.0
	          host-1.0.xsd">
	            <host:name>example-1.tldE<lt>/host:name>
	        </host:update>
	      </info>
	      <clTRID>0cf1b8f7e14547d26f03b7641660c641d9e79f45</clTRIDE<gt>
	    </command>
	</epp>

=head1 OBJECT HIERARCHY

    L<XML::LibXML::Node>
    +----L<XML::LibXML::Document>
        +----L<Net::EPP::Frame>
            +----L<Net::EPP::Frame::Command>
                +----L<Net::EPP::Frame::Command::Update>
                    +----L<Net::EPP::Frame::Command::Update::Host>

=cut

sub new {
	my $package = shift;
	my $self = bless($package->SUPER::new('update'), $package);

	my $host = $self->addObject(Net::EPP::Frame::ObjectSpec->spec('host'));

	# 'chg' element's contents are not optional for hosts, so we'll add
	# this element only when we plan to use it (accessor is overriden)
	foreach my $grp (qw(add rem)) {
		my $el = $self->createElement(sprintf('host:%s', $grp));
		$self->getNode('update')->getChildNodes->shift->appendChild($el);
	}

	return $self;
}

=pod

=head1 METHODS

	$frame->setHost($host_name);

This specifies the host object to be updated.

=cut

sub setHost {
	my ($self, $host) = @_;

	my $name = $self->createElement('host:name');
	$name->appendText($host);

	my $n = $self->getNode('update')->getChildNodes->shift;
	$n->insertBefore($name, $n->firstChild);

	return 1;
}

=pod

	$frame->addStatus($type, $info);

Add a status of $type with the optional extra $info.

=cut

sub addStatus {
	my ($self, $type, $info) = @_;
	my $status = $self->createElement('host:status');
	$status->setAttribute('s', $type);
	$status->setAttribute('lang', 'en');
	if ($info) {
		$status->appendText($info);
	}
	$self->getElementsByLocalName('host:add')->shift->appendChild($status);
	return 1;
}

=pod

	$frame->remStatus($type);

Remove a status of $type.

=cut

sub remStatus {
	my ($self, $type) = @_;
	my $status = $self->createElement('host:status');
	$status->setAttribute('s', $type);
	$self->getElementsByLocalName('host:rem')->shift->appendChild($status);
	return 1;
}


=pod

	$frame->addAddr({ 'ip' => '10.0.0.1', 'version' => 'v4' });

Add a set of IP addresses to the host object. EPP supports multiple
addresses of different versions.

=cut

sub addAddr {
	my ($self, @addr) = @_;

	foreach my $ip (@addr) {
		my $el = $self->createElement('host:addr');
		$el->appendText($ip->{ip});
		$el->setAttribute('ip', $ip->{version});
		$self->getElementsByLocalName('host:add')->shift->appendChild($el);
	}
	return 1;
}

=pod

	$frame->remAddr({ 'ip' => '10.0.0.2', 'version' => 'v4' });

Remove a set of IP addresses from the host object. EPP supports multiple
addresses of different versions.

=cut

sub remAddr {
	my ($self, @addr) = @_;

	foreach my $ip (@addr) {
		my $el = $self->createElement('host:addr');
		$el->appendText($ip->{ip});
		$el->setAttribute('ip', $ip->{version});
		$self->getElementsByLocalName('host:rem')->shift->appendChild($el);
	}
	return 1;
}


=pod
	my $el = $frame->chg;

Lazy-building of 'host:chg'element.

=cut
sub chg {
	my $self = shift;

	my $chg = $self->getElementsByLocalName('host:chg')->shift;
	if ( $chg ) {
		return $chg;
	}
	else {
		my $el = $self->createElement('host:chg');
		$self->getNode('update')->getChildNodes->shift->appendChild($el);
		return $el;
	}
}

=pod
	$frame->chgName('ns2.example.com');

Change a name of host.

=cut
sub chgName {
	my ($self, $name) = @_;
	my $el = $self->createElement('host:name');
	$el->appendText($name);
	$self->chg->appendChild($el);
}


=pod

=head1 AUTHOR

CentralNic Ltd (http://www.centralnic.com/).

=head1 COPYRIGHT

This module is (c) 2016 CentralNic Ltd. This module is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

=over

=item * L<Net::EPP::Frame>

=back

=cut

1;
