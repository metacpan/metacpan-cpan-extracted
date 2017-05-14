package Net::Async::Trello::Common;
$Net::Async::Trello::Common::VERSION = '0.001';
use strict;
use warnings;

=head2 new

Instantiates.

=cut

sub new {
	my $self = bless { @_[1..$#_] }, $_[0];
	die "no ->trello provided" unless $self->trello;
	$self
}

sub trello { shift->{trello} }

1;

