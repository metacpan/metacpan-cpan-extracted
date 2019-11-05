package Ryu::Async::Server;

use strict;
use warnings;

our $VERSION = '0.016'; # VERSION

sub new { bless { @_[1..$#_] }, $_[0] }

sub port { shift->{port} }
sub incoming { shift->{incoming} }
sub outgoing { shift->{outgoing} }

1;

=head1 AUTHOR

Tom Molesworth <TEAM@cpan.org>

=head1 LICENSE

Copyright Tom Molesworth 2011-2019. Licensed under the same terms as Perl itself.

