#
#  Copyright 2009-2013 MongoDB, Inc.
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
#

use strict;
use warnings;
package MongoDB::Timestamp;
# ABSTRACT: Replication timestamp

use version;
our $VERSION = 'v1.8.1';

use Moo;
use Types::Standard qw(
    Int
);
use namespace::clean -except => 'meta';

#pod =attr sec
#pod
#pod Seconds since epoch.
#pod
#pod =cut

has sec => (
    is       => 'ro',
    isa      => Int,
    required => 1,
);

#pod =attr inc
#pod
#pod Incrementing field.
#pod
#pod =cut

has inc => (
    is       => 'ro',
    isa      => Int,
    required => 1,
);


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MongoDB::Timestamp - Replication timestamp

=head1 VERSION

version v1.8.1

=head1 DESCRIPTION

This is an internal type used for replication.  It is not for storing dates,
times, or timestamps in the traditional sense.  Unless you are looking to mess
with MongoDB's replication internals, the class you are probably looking for is
L<DateTime>.  See L<MongoDB::DataTypes> for more information.

=head1 ATTRIBUTES

=head2 sec

Seconds since epoch.

=head2 inc

Incrementing field.

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

This software is Copyright (c) 2018 by MongoDB, Inc.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
