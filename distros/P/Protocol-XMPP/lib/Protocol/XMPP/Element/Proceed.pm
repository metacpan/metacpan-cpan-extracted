package Protocol::XMPP::Element::Proceed;

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
  $self->dispatch_event('starttls');
  $self;
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <tom@perlsite.co.uk>

=head1 LICENSE

Copyright Tom Molesworth 2010-2026. Licensed under the same terms as Perl itself.

