package Protocol::XMPP::User;

use strict;
use warnings;

our $VERSION = '0.007'; ## VERSION

=head1 NAME

Protocol::XMPP::User - user-related functionality

=cut

use Protocol::XMPP::Roster;

sub new {
  my $class = shift;
  my $self = bless { }, $class;
  return $self;
}

sub name {

}

sub roster {
  my $self = shift;
  return Protocol::XMPP::Roster->new($self);
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <tom@perlsite.co.uk>

=head1 LICENSE

Copyright Tom Molesworth 2010-2026. Licensed under the same terms as Perl itself.

