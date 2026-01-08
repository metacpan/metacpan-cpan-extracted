package Protocol::XMPP::Element::JID;

use strict;
use warnings;
use parent qw(Protocol::XMPP::TextElement);

our $VERSION = '0.007'; ## VERSION

=head1 NAME

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=cut

sub on_text_complete {
  my $self = shift;
  my $data = shift;
  $self->{jid} = $data;
  $self->stream->jid($data);
  $self->debug("Full JID was [$data]");
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <tom@perlsite.co.uk>

=head1 LICENSE

Copyright Tom Molesworth 2010-2026. Licensed under the same terms as Perl itself.

