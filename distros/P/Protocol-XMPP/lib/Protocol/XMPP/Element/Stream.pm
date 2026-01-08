package Protocol::XMPP::Element::Stream;

use strict;
use warnings;
use parent qw(Protocol::XMPP::ElementBase);

our $VERSION = '0.007'; ## VERSION

=head1 NAME

Protocol::XMPP::Element::Stream - handle the stream start/end tags

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=cut

sub new {
  my $class = shift;
  my $self = $class->SUPER::new(@_);
  $self->stream->remote_opened->done;
  $self
}

=head2 C<end_element>

=cut

sub end_element {
  my $self = shift;
  $self->stream->remote_closed->done;
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <tom@perlsite.co.uk>

=head1 LICENSE

Copyright Tom Molesworth 2010-2026. Licensed under the same terms as Perl itself.
