package Protocol::XMPP::Element::StartTLS;
$Protocol::XMPP::Element::StartTLS::VERSION = '0.006';
use strict;
use warnings;
use parent qw(Protocol::XMPP::ElementBase);

=head1 NAME

=head1 SYNOPSIS

=head1 VERSION

Version 0.006

=head1 DESCRIPTION

=head1 METHODS

=cut

sub end_element {
	my $self = shift;
	$self->debug('TLS available');
	$self->stream->{features}->{tls} = 1;
	$self->stream->{tls_pending} = 1;

# screw this, let's go straight into TLS mode
	$self->write_xml(['starttls', _ns => 'xmpp-tls']);
	$self;
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2010-2014. Licensed under the same terms as Perl itself.
