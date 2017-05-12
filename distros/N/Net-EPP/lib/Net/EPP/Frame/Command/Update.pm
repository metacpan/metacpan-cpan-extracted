# Copyright (c) 2016 CentralNic Ltd. All rights reserved. This program is
# free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.
# 
# $Id: Update.pm,v 1.5 2011/12/14 12:02:08 gavin Exp $
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
