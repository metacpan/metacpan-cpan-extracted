package Protocol::XMPP::Element::Challenge;
$Protocol::XMPP::Element::Challenge::VERSION = '0.006';
use strict;
use warnings;
use parent qw(Protocol::XMPP::ElementBase);

=head1 NAME

Protocol::XMPP::Challenge - deal with the XMPP challenge

=head1 VERSION

Version 0.006

=head1 SYNOPSIS

=head1 DESCRIPTION

Generate a response to an XMPP challenge using the L<Auth::SASL> object we set up earlier.

=head1 METHODS

=cut

use MIME::Base64;

=head1 C<end_element>

On completion of the element, queue a write for the answering token as provided by L<Authen::SASL>. Token
value is opaque binary data, and must be Base64 encoded (using L<MIME::Base64>).

=cut

sub end_element {
	my $self = shift;
	$self->debug("Data was: " . $self->{data});
	my $data = MIME::Base64::decode_base64($self->{data});

	my ($token) = $self->stream->{features}->{sasl_client}->client_step($data);
	$self->debug("Token was [" . ($token || 'undefined') . "]");

# Return either base64 token value, or '=' (which decodes to empty value but we need to be explicit about
# this for some recipients) if we didn't have one.
	my $response = MIME::Base64::encode_base64(defined $token ? $token : '', '');
	$token = '=' unless defined $response && length $response;

	$self->write_xml([
		'response',
		_ns => 'xmpp-sasl',
		_content => $response
	]);
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2010-2014. Licensed under the same terms as Perl itself.
