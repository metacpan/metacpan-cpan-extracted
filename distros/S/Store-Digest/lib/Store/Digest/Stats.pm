package Store::Digest::Stats;

use 5.010;
use strict;
use warnings FATAL => 'all';

use Moose;
use namespace::autoclean;

use Store::Digest::Types qw(DateTimeType NonNegativeInt);

=head1 NAME

Store::Digest::Stats - Statistical report about data usage in the store

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    my $store = Store::Digest->new;

    my $stats = $store->stats;

=head1 METHODS

=head2 bytes

Returns the total number of bytes of I<payload> stored.

=cut

has bytes => (
    is  => 'ro',
    isa => NonNegativeInt,
);

=head2 objects

Returns the total number of I<digests> in the database, including
those for which the payloads have been removed.

=cut

has objects => (
    is  => 'ro',
    isa => NonNegativeInt,
);

=head2 deleted

Returns the number of digests which have had their payloads removed.

=cut

has deleted => (
    is  => 'ro',
    isa => NonNegativeInt,
);

=head2 created

Returns the L<DateTime> the database was created.

=cut

has created => (
    is => 'ro',
    isa => DateTimeType,
);

=head2 modified

Returns the L<DateTime> the database was last modified.

=cut

has modified => (
    is  => 'ro',
    isa => DateTimeType,
);

=head2 as_string

Returns the stats as a string.

=cut

sub as_string {
    my $self = shift;
my $str = <<EOT;
Digest store stats:
  Created on:      %-20s
  Last Modified:   %-20s
  Bytes stored:    %-20d
  Objects stored:  %-20d
  Objects deleted: %-20d
EOT

    return sprintf $str,
        map { $self->$_ } qw(created modified bytes objects deleted);
}

=head1 AUTHOR

Dorian Taylor, C<< <dorian at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Dorian Taylor.

Licensed under the Apache License, Version 2.0 (the "License"); you
may not use this file except in compliance with the License. You may
obtain a copy of the License at
L<http://www.apache.org/licenses/LICENSE-2.0>.

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
implied.  See the License for the specific language governing
permissions and limitations under the License.


=cut

__PACKAGE__->meta->make_immutable;

1; # End of Store::Digest::Stats
