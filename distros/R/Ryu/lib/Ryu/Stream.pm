package Ryu::Stream;

use strict;
use warnings;

use parent qw(Ryu::Node);

our $VERSION = '3.005'; # VERSION
our $AUTHORITY = 'cpan:TEAM'; # AUTHORITY

=head1 NAME

Ryu::Stream - combines a source and a sink

=head1 DESCRIPTION

See L<Ryu::Source> and L<Ryu::Sink> for details.

=cut

no indirect;

use Future;
use curry::weak;

use Ryu::Source;
use Ryu::Sink;

use Log::Any qw($log);

=head2 source

A L<Ryu::Source>.

=cut

sub source { shift->{source} }

=head2 source

A L<Ryu::Sink>.

=cut

sub sink { shift->{source} }

1;

__END__

=head1 AUTHOR

Tom Molesworth <TEAM@cpan.org>

=head1 LICENSE

Copyright Tom Molesworth 2011-2023. Licensed under the same terms as Perl itself.

