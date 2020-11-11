package Net::Async::Github::RateLimit;

use strict;
use warnings;

use Net::Async::Github::RateLimit::Core;

our $VERSION = '0.007'; # VERSION

=head1 NAME

Net::Async::Github::RateLimit - represents the current user's rate limit

=head1 METHODS

=head2 new

Instantiates.

=cut

sub new {
    my ($class, %args) = @_;
    $args{core} = Net::Async::Github::RateLimit::Core->new(%{ delete $args{resources}{core} });
    bless \%args, $class
}

=head2 core

Returns a L<Net::Async::Github::RateLimit::Core> instance.

=cut

sub core { shift->{core} }

1;

