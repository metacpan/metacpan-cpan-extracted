package Ryu::Node;

use strict;
use warnings;

our $VERSION = '0.015'; # VERSION

=head1 NAME

Ryu::Node - generic node

=head1 DESCRIPTION

This is a common base class for all sources, sinks and other related things.
It does very little.

=cut

=head1 METHODS

Not really. There's a constructor, but that's not particularly exciting.

=cut

sub new { bless { @_[1..$#_] }, $_[0] }

1;

__END__

=head1 AUTHOR

Tom Molesworth <TEAM@cpan.org>

=head1 LICENSE

Copyright Tom Molesworth 2011-2017. Licensed under the same terms as Perl itself.

