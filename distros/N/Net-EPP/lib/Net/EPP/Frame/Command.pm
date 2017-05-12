# Copyright (c) 2016 CentralNic Ltd. All rights reserved. This program is
# free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.
# 
# $Id: Command.pm,v 1.4 2011/12/03 11:44:51 gavin Exp $
package Net::EPP::Frame::Command;
use Net::EPP::Frame::Command::Check;
use Net::EPP::Frame::Command::Create;
use Net::EPP::Frame::Command::Delete;
use Net::EPP::Frame::Command::Info;
use Net::EPP::Frame::Command::Login;
use Net::EPP::Frame::Command::Logout;
use Net::EPP::Frame::Command::Poll;
use Net::EPP::Frame::Command::Renew;
use Net::EPP::Frame::Command::Transfer;
use Net::EPP::Frame::Command::Update;
use base qw(Net::EPP::Frame);
use strict;

=pod

=head1 NAME

Net::EPP::Frame::Command - an instance of L<Net::EPP::Frame> for client commands

=head1 DESCRIPTION

This module is a base class for the Net::EPP::Frame::* subclasses, you should
never need to access it directly.

=head1 OBJECT HIERARCHY

    L<XML::LibXML::Node>
    +----L<XML::LibXML::Document>
        +----L<Net::EPP::Frame>
            +----L<Net::EPP::Frame::Command>


=cut

sub new {
	my $package = shift;
	my $self = $package->SUPER::new('command');
	return bless($self, $package);
}

sub addObject() {
	my ($self, $object, $ns, $schema) = @_;

	my $obj = $self->createElement($self->getCommandType);
	$obj->setNamespace($ns, $object);
	$self->getNode($self->getCommandType)->addChild($obj);

	return $obj;
}

sub _addExtraElements {
	my $self = shift;

	$self->command->addChild($self->createElement($self->getCommandType)) if ($self->getCommandType ne '');
	$self->command->addChild($self->createElement('clTRID'));

	$self->_addCommandElements;
	return 1;
}

sub _addCommandElements {
}

=pod

=head1 METHODS

	my $object = $frame->addObject(@spec);

This method creates and returns a new element corresponding to the data in
C<@spec>, and appends it to the "command" element (as returned by the
C<getCommandType()> method below).

The L<Net::EPP::Frame::ObjectSpec> module can be used to quickly retrieve EPP
object specifications.

	my $type = $frame->getCommandType;

This method returns a scalar containing the command type (eg L<'create'>).

	my $type = $frame->getCommandNode;

This method returns the L<XML::LibXML::Element> object corresponding to the
command in question, eg the C<E<lt>createE<gt>> element (for a
L<Net::EPP::Frame::Command::Create> object). It is within this element that
EPP objects are placed.

	my $node = $frame->command;

This method returns the L<XML::LibXML::Element> object corresponding to the
C<E<lt>commandE<gt>> element.

	my $node = $frame->clTRID;

This method returns the L<XML::LibXML::Element> object corresponding to the
C<E<lt>clTRIDE<gt>> element.

=cut

sub getCommandType {
	my $self = shift;
	my $type = ref($self);
	my $me = __PACKAGE__;
	$type =~ s/^$me\:+//;
	$type =~ s/\:{2}.+//;
	return lc($type);
}

sub getCommandNode {
	my $self = shift;
	return $self->getNode($self->getCommandType);
}

sub command { $_[0]->getNode('command') }
sub clTRID { $_[0]->getNode('clTRID') }

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
