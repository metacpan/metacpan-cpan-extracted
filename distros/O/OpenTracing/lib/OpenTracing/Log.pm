package OpenTracing::Log;

use strict;
use warnings;

our $VERSION = '0.003'; # VERSION

use parent qw(OpenTracing::Common);

=encoding utf8

=head1 NAME

OpenTracing::Log - represents a single log message

=head1 DESCRIPTION

Each instance represents one log message.

=cut

=head1 METHODS

=head2 timestamp

When this message was logged.

=cut

sub timestamp { shift->{timestamp} }

=head2 tags

Arrayref of tags relating to the log entry.

=cut

sub tags { shift->{tags} }

=head2 tag_list

List of tags relating to the log entry.

=cut

sub tag_list { (shift->{tags} //= [])->@* }

1;

__END__

=head1 AUTHOR

Tom Molesworth <TEAM@cpan.org>

=head1 LICENSE

Copyright Tom Molesworth 2018-2019. Licensed under the same terms as Perl itself.

