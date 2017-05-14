package Net::Async::TravisCI::Config;
$Net::Async::TravisCI::Config::VERSION = '0.002';
use strict;
use warnings;

sub new { bless { @_[1..$#_] }, $_[0] }

=head2 pusher

=cut

sub pusher { shift->{pusher} }

=head2 shorten_host

=cut

sub shorten_host { shift->{shorten_host} }

=head2 github

=cut

sub github { shift->{github} }

=head2 host

=cut

sub host { shift->{host} }

=head2 notifications

=cut

sub notifications { shift->{notifications} }

=head2 assets

=cut

sub assets { shift->{assets} }


1;

