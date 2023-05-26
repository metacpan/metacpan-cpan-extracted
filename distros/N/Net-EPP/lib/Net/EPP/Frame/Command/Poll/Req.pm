package Net::EPP::Frame::Command::Poll::Req;
use base qw(Net::EPP::Frame::Command::Poll);
use strict;

=pod

=head1 NAME

Net::EPP::Frame::Command::Poll::Req - an instance of L<Net::EPP::Frame::Command>
for the EPP C<E<lt>PollE<gt>> request command.

=head1 OBJECT HIERARCHY

    L<XML::LibXML::Node>
    +----L<XML::LibXML::Document>
        +----L<Net::EPP::Frame>
            +----L<Net::EPP::Frame::Command>
                +----L<Net::EPP::Frame::Command::Poll>

=cut

sub new {
	my $package = shift;
	my $self = bless($package->SUPER::new('poll'), $package);
	$self->getCommandNode->setAttribute('op' => 'req');
	return $self;
}

=head1 METHODS

This module does not define any methods in addition to those it inherits from
its ancestors.

=cut

1;
