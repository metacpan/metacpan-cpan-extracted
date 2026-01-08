package Protocol::XMPP::Element::Register;

use strict;
use warnings;
use parent qw(Protocol::XMPP::ElementBase);

our $VERSION = '0.007'; ## VERSION

=head1 NAME

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=cut

use Data::Dumper;

sub new {
  my $class = shift;
  my $self = $class->SUPER::new(@_);
  $self->debug($self->{element}->{NamespaceURI});
  $self;
}

sub end_element {
  my $self = shift;
  $self->debug("Register request received, data was: " . $self->{data});
  $self;
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <tom@perlsite.co.uk>

=head1 LICENSE

Copyright Tom Molesworth 2010-2026. Licensed under the same terms as Perl itself.

