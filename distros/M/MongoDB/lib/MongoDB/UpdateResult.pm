#  Copyright 2014 - present MongoDB, Inc.
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.

use strict;
use warnings;
package MongoDB::UpdateResult;

# ABSTRACT: MongoDB update result object

use version;
our $VERSION = 'v2.2.2';

use Moo;
use MongoDB::_Constants;
use MongoDB::_Types qw(
    Numish
);
use Types::Standard qw(
    Undef
);
use namespace::clean;

with $_ for qw(
  MongoDB::Role::_PrivateConstructor
  MongoDB::Role::_WriteResult
);

#pod =attr matched_count
#pod
#pod The number of documents that matched the filter.
#pod
#pod =cut

has matched_count => (
    is       => 'ro',
    required => 1,
    isa      => Numish,
);

#pod =attr modified_count
#pod
#pod The number of documents that were modified.  Note: this is only available
#pod from MongoDB version 2.6 or later.  It will return C<undef> from earlier
#pod servers.
#pod
#pod You can call C<has_modified_count> to find out if this attribute is
#pod defined or not.
#pod
#pod =cut

has modified_count => (
    is       => 'ro',
    required => 1,
    isa      => (Numish|Undef),
);

sub has_modified_count {
    my ($self) = @_;
    return defined( $self->modified_count );
}

#pod =attr upserted_id
#pod
#pod The identifier of the inserted document if an upsert took place.  If
#pod no upsert took place, it returns C<undef>.
#pod
#pod =cut

has upserted_id => (
    is  => 'ro',
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MongoDB::UpdateResult - MongoDB update result object

=head1 VERSION

version v2.2.2

=head1 SYNOPSIS

    my $result = $coll->update( @parameters );

    if ( $result->acknowledged ) {
        ...
    }

=head1 DESCRIPTION

This class encapsulates the results from an update or replace operations.

=head1 ATTRIBUTES

=head2 matched_count

The number of documents that matched the filter.

=head2 modified_count

The number of documents that were modified.  Note: this is only available
from MongoDB version 2.6 or later.  It will return C<undef> from earlier
servers.

You can call C<has_modified_count> to find out if this attribute is
defined or not.

=head2 upserted_id

The identifier of the inserted document if an upsert took place.  If
no upsert took place, it returns C<undef>.

=head1 METHODS

=head2 acknowledged

Indicates whether this write result was acknowledged.  Always
true for this class.

=head2 assert

Throws an error if write errors or write concern errors occurred.
Otherwise, returns the invocant.

=head2 assert_no_write_error

Throws a MongoDB::WriteError if write errors occurred.
Otherwise, returns the invocant.

=head2 assert_no_write_concern_error

Throws a MongoDB::WriteConcernError if write concern errors occurred.
Otherwise, returns the invocant.

=head1 AUTHORS

=over 4

=item *

David Golden <david@mongodb.com>

=item *

Rassi <rassi@mongodb.com>

=item *

Mike Friedman <friedo@friedo.com>

=item *

Kristina Chodorow <k.chodorow@gmail.com>

=item *

Florian Ragwitz <rafl@debian.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by MongoDB, Inc.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
