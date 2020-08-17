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
package MongoDB::InsertOneResult;

# ABSTRACT: MongoDB single insert result object

use version;
our $VERSION = 'v2.2.2';

use Moo;
use namespace::clean;

with $_ for qw(
  MongoDB::Role::_PrivateConstructor
  MongoDB::Role::_WriteResult
);

#pod =attr inserted_id
#pod
#pod The identifier of the inserted document.
#pod
#pod =cut

has inserted_id => (
    is  => 'ro',
    required => 1,
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MongoDB::InsertOneResult - MongoDB single insert result object

=head1 VERSION

version v2.2.2

=head1 SYNOPSIS

    my $result = $coll->insert( $document );

    if ( $result->acknowledged ) {
        ...
    }

=head1 DESCRIPTION

This class encapsulates the result from the insertion of a single document.

=head1 ATTRIBUTES

=head2 inserted_id

The identifier of the inserted document.

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
