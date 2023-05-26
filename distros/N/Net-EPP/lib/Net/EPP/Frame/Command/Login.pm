package Net::EPP::Frame::Command::Login;
use base qw(Net::EPP::Frame::Command);
use strict;

=pod

=head1 NAME

Net::EPP::Frame::Command::Login - an instance of L<Net::EPP::Frame::Command>
for the EPP C<E<lt>loginE<gt>> command.

=head1 OBJECT HIERARCHY

    L<XML::LibXML::Node>
    +----L<XML::LibXML::Document>
        +----L<Net::EPP::Frame>
            +----L<Net::EPP::Frame::Command>
                +----L<Net::EPP::Frame::Command::Login>

=cut

sub _addCommandElements {
	my $self = shift;
	$self->getNode('login')->addChild($self->createElement('clID'));
	$self->getNode('login')->addChild($self->createElement('pw'));
	$self->getNode('login')->addChild($self->createElement('options'));

	$self->getNode('options')->addChild($self->createElement('version'));
	$self->getNode('options')->addChild($self->createElement('lang'));

	$self->getNode('login')->addChild($self->createElement('svcs'));
}

=pod

=head1 METHODS

	my $node = $frame->clID;

This method returns the L<XML::LibXML::Element> object corresponding to the
C<E<lt>clIDE<gt>> element.

	my $node = $frame->pw;

This method returns the L<XML::LibXML::Element> object corresponding to the
C<E<lt>pwE<gt>> element.

	my $node = $frame->newPW;

This method returns the L<XML::LibXML::Element> object corresponding to the
C<E<lt>newPWE<gt>> element.

	my $node = $frame->svcs;

This method returns the L<XML::LibXML::Element> object corresponding to the
C<E<lt>svcsE<gt>> element.

	my $node = $frame->options;

This method returns the L<XML::LibXML::Element> object corresponding to the
C<E<lt>optionsE<gt>> element.

	my $node = $frame->version;

This method returns the L<XML::LibXML::Element> object corresponding to the
C<E<lt>versionE<gt>> element.

	my $node = $frame->lang;

This method returns the L<XML::LibXML::Element> object corresponding to the
C<E<lt>langE<gt>> element.

=cut

sub clID { $_[0]->getNode('clID') }
sub pw { $_[0]->getNode('pw') }
sub newPW { $_[0]->getNode('newPW') }
sub svcs { $_[0]->getNode('svcs') }
sub options { $_[0]->getNode('options') }
sub version { $_[0]->getNode('version') }
sub lang { $_[0]->getNode('lang') }

1;
