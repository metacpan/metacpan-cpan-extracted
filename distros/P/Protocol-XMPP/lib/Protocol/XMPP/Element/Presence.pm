package Protocol::XMPP::Element::Presence;

use strict;
use warnings;
use parent qw(Protocol::XMPP::ElementBase);

our $VERSION = '0.007'; ## VERSION

use Protocol::XMPP::Contact;

=head1 NAME

Protocol::XMPP::Success - indicate success for an operation

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=cut

sub end_element {
  my $self = shift;
  $self->debug("Had presence information");
  my $attr = $self->attributes;
  my $contact = Protocol::XMPP::Contact->new(
    stream  => $self->stream,
    jid => $attr->{from},
  );
  $self->dispatch_event('presence', $contact);
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <tom@perlsite.co.uk>

=head1 LICENSE

Copyright Tom Molesworth 2010-2026. Licensed under the same terms as Perl itself.

