package Net::EPP::Frame::Command::Update;
use Net::EPP::Frame::Command::Update::Contact;
use Net::EPP::Frame::Command::Update::Domain;
use Net::EPP::Frame::Command::Update::Host;
use base qw(Net::EPP::Frame::Command);
use strict;

=pod

=head1 NAME

Net::EPP::Frame::Command::Update - an instance of L<Net::EPP::Frame::Command>
for the EPP C<E<lt>updateE<gt>> command.

=head1 OBJECT HIERARCHY

    L<XML::LibXML::Node>
    +----L<XML::LibXML::Document>
        +----L<Net::EPP::Frame>
            +----L<Net::EPP::Frame::Command>
                +----L<Net::EPP::Frame::Command::Update>

=head1 METHODS

=cut

sub add {
	my $self = shift;
	foreach my $el ($self->getNode('update')->getChildNodes->shift->getChildNodes) {
		my (undef, $name) = split(/:/, $el->localName, 2);
		return $el if ($name eq 'add');
	}
}

sub rem {
	my $self = shift;
	foreach my $el ($self->getNode('update')->getChildNodes->shift->getChildNodes) {
		my (undef, $name) = split(/:/, $el->localName, 2);
		return $el if ($name eq 'rem');

	}
}

sub chg {
	my $self = shift;
	foreach my $el ($self->getNode('update')->getChildNodes->shift->getChildNodes) {
		my (undef, $name) = split(/:/, $el->localName, 2);
		return $el if ($name eq 'chg');
	}
}

=pod

	my $el = $frame->add;
	my $el = $frame->rem;
	my $el = $frame->chg;

These methods return the elements that should be used to contain the changes
to be made to the object (ie C<domain:add>, C<domain:rem>, C<domain:chg>).

=cut

1;
