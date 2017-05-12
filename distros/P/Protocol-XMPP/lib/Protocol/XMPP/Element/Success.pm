package Protocol::XMPP::Element::Success;
$Protocol::XMPP::Element::Success::VERSION = '0.006';
use strict;
use warnings;
use parent qw(Protocol::XMPP::ElementBase);

=head1 NAME

Protocol::XMPP::Success - indicate success for an operation

=head1 VERSION

Version 0.006

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=cut

sub end_element {
	my $self = shift;
	$self->debug("Successful response");
	# On successful authorisation, we need to start a new stream (without closing
	# the original one) so that we can go through stream header negotiation again:
	# authorisation may have enabled additional features that were not advertised
	# previously.
	$self->stream->reset;
	$self->write_text(@{$self->stream->preamble});
	$self->is_authorised(1);
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2010-2014. Licensed under the same terms as Perl itself.
