#
#  Copyright 2009 10gen, Inc.
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

package MongoDB::Async::Timestamp;
{
  $MongoDB::Async::Timestamp::VERSION = '0.702.3';
}


# ABSTRACT: Replication timestamp


use Moose;


has sec => (
    is       => 'ro',
    isa      => 'Int',
    required => 1,
);


has inc => (
    is       => 'ro',
    isa      => 'Int',
    required => 1,
);

1;

__END__

=pod

=head1 NAME

MongoDB::Async::Timestamp - Replication timestamp

=head1 VERSION

version 0.702.3

=head1 SYNOPSIS

This is an internal type used for replication.  It is not for storing dates,
times, or timestamps in the traditional sense.  Unless you are looking to mess
with MongoDB's replication internals, the class you are probably looking for is
L<DateTime>.  See <MongoDB::Async::DataTypes> for more information.

=head1 NAME

MongoDB::Async::Timestamp - Timestamp used for replication

=head1 ATTRIBUTES

=head2 sec

Seconds since epoch.

=head2 inc

Incrementing field.

=head1 AUTHORS

=over 4

=item *

Florian Ragwitz <rafl@debian.org>

=item *

Kristina Chodorow <kristina@mongodb.org>

=item *

Mike Friedman <mike.friedman@10gen.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by 10gen, Inc..

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
