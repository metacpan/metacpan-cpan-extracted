package OpenTracing::Tag;

use strict;
use warnings;

our $VERSION = '0.003'; # VERSION

use parent qw(OpenTracing::Common);

=encoding utf8

=head1 NAME

OpenTracing::Tag - wrapper object for tags

=head1 DESCRIPTION

Most of the time, tags are represented as simple key/value entries in a hashref.

Some tags have specific semantic meaning, so this class acts as a base for supporting
future operations on specific tags.

=cut

=head2 key

The tag key, a plain string.

=cut

sub key { shift->{key} }

=head2 value

The tag value, as a plain string.

=cut

sub value { shift->{value} }

1;

__END__

=head1 AUTHOR

Tom Molesworth <TEAM@cpan.org>

=head1 LICENSE

Copyright Tom Molesworth 2018-2019. Licensed under the same terms as Perl itself.

