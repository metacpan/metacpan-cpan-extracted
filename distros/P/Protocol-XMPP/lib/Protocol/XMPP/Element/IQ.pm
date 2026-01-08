package Protocol::XMPP::Element::IQ;

use strict;
use warnings;
use parent qw(Protocol::XMPP::ElementBase);

our $VERSION = '0.007'; ## VERSION

=head1 NAME

Protocol::XMPP::Bind - register ability to deal with a specific feature

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=cut

=head2 end_element

=cut

sub end_element {
  my $self = shift;
  $self->debug("IQ data");
  my $id = $self->attributes->{id};
  $self->stream->iq_complete($id => $self);
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <tom@perlsite.co.uk>

=head1 LICENSE

Copyright Tom Molesworth 2010-2026. Licensed under the same terms as Perl itself.

