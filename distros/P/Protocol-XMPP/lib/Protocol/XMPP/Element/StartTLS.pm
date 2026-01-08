package Protocol::XMPP::Element::StartTLS;

use strict;
use warnings;
use parent qw(Protocol::XMPP::ElementBase);

our $VERSION = '0.007'; ## VERSION

=head1 NAME

=head1 SYNOPSIS

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

Tom Molesworth <tom@perlsite.co.uk>

=head1 LICENSE

Copyright Tom Molesworth 2010-2026. Licensed under the same terms as Perl itself.

