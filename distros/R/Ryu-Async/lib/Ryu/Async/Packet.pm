package Ryu::Async::Packet;

use strict;
use warnings;

our $VERSION = '0.020'; # VERSION
our $AUTHORITY = 'cpan:TEAM'; # AUTHORITY

sub new { bless { @_[1..$#_] }, $_[0] }

sub payload { $_[0]->{payload} }
sub from { $_[0]->{from} }

1;

=head1 AUTHOR

Tom Molesworth <TEAM@cpan.org>

=head1 LICENSE

Copyright Tom Molesworth 2011-2021. Licensed under the same terms as Perl itself.

