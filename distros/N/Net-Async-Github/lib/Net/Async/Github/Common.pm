package Net::Async::Github::Common;

use strict;
use warnings;

our $VERSION = '0.012'; # VERSION

=head1 NAME

Net::Async::Github::Common - common base class for entities

=head1 METHODS

=head2 new

Instantiates. This will expect the L</github> attribute to be passed.

=cut

sub new {
    my $self = bless { @_[1..$#_] }, $_[0];
    die "no ->github provided" unless $self->github;
    $self
}

=head2 github

Returns the top-level L<Net::Async::Github> instance.

=cut

sub github { shift->{github} }

1;

