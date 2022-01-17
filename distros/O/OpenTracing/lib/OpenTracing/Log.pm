package OpenTracing::Log;

use strict;
use warnings;

our $VERSION = '1.006'; # VERSION
our $AUTHORITY = 'cpan:TEAM'; # AUTHORITY

use parent qw(OpenTracing::Common);

no indirect;
use utf8;

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

=head2 tag

Applies key/value tags to this log message.

The L<semantic conventions|https://github.com/opentracing/specification/blob/master/semantic_conventions.md>
may be of interest here.

Example usage:

 $log->tag(
  'error.kind' => 'Exception',
  'error.object' => $exception,
 );

=cut

sub tag : method {
    my ($self, %args) = @_;
    @{$self->{tags}}{keys %args} = values %args;
    return $self;
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <TEAM@cpan.org>

=head1 LICENSE

Copyright Tom Molesworth 2018-2021. Licensed under the same terms as Perl itself.

