package Net::Async::Github::RateLimit::Core;

use strict;
use warnings;

our $VERSION = '0.008'; # VERSION

=head1 NAME

Net::Async::Github::RateLimit::Core - represents the current user's rate limit

=head1 METHODS

=head2 new

Instantiates.

=cut

sub new { my $class = shift; bless { @_ }, $class }

=head2 limit

Current limit as a number of remaining requests.

=cut

sub limit { shift->{limit} }

=head2 remaining

Number of remaining requests.

=cut

sub remaining { shift->{remaining} }

=head2 reset

When we expect the rate limit to be reset, as a UNIX epoch.

=cut

sub reset : method { shift->{reset} }

=head2 seconds_left

Number of seconds left before reset.

=cut

sub seconds_left { shift->reset - time }

1;

