use 5.010;
use strict;
use warnings;

package MongoDBx::Queue;

# ABSTRACT: A message queue implemented with MongoDB

our $VERSION = '2.001';

use Moose 2;
use MooseX::Types::Moose qw/:all/;
use MooseX::AttributeShortcuts;

use MongoDB 2 ();
use namespace::autoclean;

with (
    'MongoDBx::Queue::Role::_CommonOptions',
);

#--------------------------------------------------------------------------#
# Public attributes
#--------------------------------------------------------------------------#

#pod =attr database_name
#pod
#pod A MongoDB database name.  Unless a C<db_name> is provided in the
#pod C<client_options> attribute, this database will be the default for
#pod authentication.  Defaults to 'test'
#pod
#pod =attr client_options
#pod
#pod A hash reference of L<MongoDB::MongoClient> options that will be passed to its
#pod C<connect> method.
#pod
#pod =attr collection_name
#pod
#pod A collection name for the queue.  Defaults to 'queue'.  The collection must
#pod only be used by MongoDBx::Queue or unpredictable awful things will happen.
#pod
#pod =attr version
#pod
#pod The implementation version to use as a backend.  Defaults to '1', which is the
#pod legacy implementation for backwards compatibility.  Version '2' has better
#pod index coverage and will perform better for very large queues.
#pod
#pod B<WARNING> Versions are not compatible.  You MUST NOT have V1 and V2 clients
#pod using the same database+collection name.  See L</MIGRATION BETWEEN VERSIONS>
#pod for more.
#pod
#pod =cut

has version => (
    is      => 'ro',
    isa     => Int,
    default => 1,
);

#--------------------------------------------------------------------------#
# Private attributes and builders
#--------------------------------------------------------------------------#

has _implementation => (
    is => 'lazy',
    handles => [ qw(
        add_task
        reserve_task
        reschedule_task
        remove_task
        apply_timeout
        search
        peek
        size
        waiting
    )],
);

sub _build__implementation {
    my ($self) = @_;
    my $options = {
        client_options => $self->client_options,
        database_name => $self->database_name,
        collection_name => $self->collection_name,
    };
    if ($self->version == 1) {
        require MongoDBx::Queue::_V1;
        return MongoDBx::Queue::_V1->new($options);
    }
    elsif ($self->version == 2) {
        require MongoDBx::Queue::_V2;
        return MongoDBx::Queue::_V2->new($options);
    }
    else {
        die "Invalid MongoDBx::Queue 'version' (must be 1 or 2)"
    }
}

sub BUILD {
    my ($self) = @_;
    $self->_implementation->create_indexes;
}

#--------------------------------------------------------------------------#
# Public method documentation
#--------------------------------------------------------------------------#

#pod =method new
#pod
#pod    $queue = MongoDBx::Queue->new(
#pod         version => 2,
#pod         database_name   => "my_app",
#pod         client_options  => {
#pod             host => "mongodb://example.net:27017",
#pod             username => "willywonka",
#pod             password => "ilovechocolate",
#pod         },
#pod    );
#pod
#pod Creates and returns a new queue object.
#pod
#pod =method add_task
#pod
#pod   $queue->add_task( \%message, \%options );
#pod
#pod Adds a task to the queue.  The C<\%message> hash reference will be shallow
#pod copied into the task and not include objects except as described by
#pod L<MongoDB::DataTypes>.  Top-level keys must not start with underscores, which are
#pod reserved for MongoDBx::Queue.
#pod
#pod The C<\%options> hash reference is optional and may contain the following key:
#pod
#pod =for :list
#pod * C<priority>: sets the priority for the task. Defaults to C<time()>.
#pod
#pod Note that setting a "future" priority may cause a task to be invisible
#pod to C<reserve_task>.  See that method for more details.
#pod
#pod =method reserve_task
#pod
#pod   $task = $queue->reserve_task;
#pod   $task = $queue->reserve_task( \%options );
#pod
#pod Atomically marks and returns a task.  The task is marked in the queue as
#pod "reserved" (in-progress) so it can not be reserved again unless is is
#pod rescheduled or timed-out.  The task returned is a hash reference containing the
#pod data added in C<add_task>, including private keys for use by MongoDBx::Queue
#pod methods.
#pod
#pod Tasks are returned in priority order from lowest to highest.  If multiple tasks
#pod have identical, lowest priorities, their ordering is undefined.  If no tasks
#pod are available or visible, it will return C<undef>.
#pod
#pod The C<\%options> hash reference is optional and may contain the following key:
#pod
#pod =for :list
#pod * C<max_priority>: sets the maximum priority for the task. Defaults to C<time()>.
#pod
#pod The C<max_priority> option controls whether "future" tasks are visible.  If
#pod the lowest task priority is greater than the C<max_priority>, this method
#pod returns C<undef>.
#pod
#pod =method reschedule_task
#pod
#pod   $queue->reschedule_task( $task );
#pod   $queue->reschedule_task( $task, \%options );
#pod
#pod Releases the reservation on a task so it can be reserved again.
#pod
#pod The C<\%options> hash reference is optional and may contain the following key:
#pod
#pod =for :list
#pod * C<priority>: sets the priority for the task. Defaults to the task's original priority.
#pod
#pod Note that setting a "future" priority may cause a task to be invisible
#pod to C<reserve_task>.  See that method for more details.
#pod
#pod =method remove_task
#pod
#pod   $queue->remove_task( $task );
#pod
#pod Removes a task from the queue (i.e. indicating the task has been processed).
#pod
#pod =method apply_timeout
#pod
#pod   $queue->apply_timeout( $seconds );
#pod
#pod Removes reservations that occurred more than C<$seconds> ago.  If no
#pod argument is given, the timeout defaults to 120 seconds.  The timeout
#pod should be set longer than the expected task processing time, so that
#pod only dead/hung tasks are returned to the active queue.
#pod
#pod =method search
#pod
#pod   my @results = $queue->search( \%query, \%options );
#pod
#pod Returns a list of tasks in the queue based on search criteria.  The
#pod query should be expressed in the usual MongoDB fashion.  In addition
#pod to MongoDB options (e.g. C<limit>, C<skip> and C<sort>) as described
#pod in the MongoDB documentation for L<MongoDB::Collection/find>, this method
#pod supports a C<reserved> option.  If present, results will be limited to reserved
#pod tasks if true or unreserved tasks if false.
#pod
#pod =method peek
#pod
#pod   $task = $queue->peek( $task );
#pod
#pod Retrieves a full copy of the task from the queue.  This is useful to retrieve all
#pod fields from a projected result from C<search>.  It is equivalent to:
#pod
#pod   $self->search( { _id => $task->{_id} } );
#pod
#pod Returns undef if the task is not found.
#pod
#pod =method size
#pod
#pod   $queue->size;
#pod
#pod Returns the number of tasks in the queue, including in-progress ones.
#pod
#pod =method waiting
#pod
#pod   $queue->waiting;
#pod
#pod Returns the number of tasks in the queue that have not been reserved.
#pod
#pod =cut

__PACKAGE__->meta->make_immutable;

1;


# vim: ts=4 sts=4 sw=4 et:

__END__

=pod

=encoding UTF-8

=head1 NAME

MongoDBx::Queue - A message queue implemented with MongoDB

=head1 VERSION

version 2.001

=head1 SYNOPSIS

    use v5.10;
    use MongoDBx::Queue;

    my $queue = MongoDBx::Queue->new(
        version => 2,
        database_name => "queue_db",
        client_options => {
            host => "mongodb://example.net:27017",
            username => "willywonka",
            password => "ilovechocolate",
        }
    );

    $queue->add_task( { msg => "Hello World" } );
    $queue->add_task( { msg => "Goodbye World" } );

    while ( my $task = $queue->reserve_task ) {
        say $task->{msg};
        $queue->remove_task( $task );
    }

=head1 DESCRIPTION

MongoDBx::Queue implements a simple, prioritized message queue using MongoDB as
a backend.  By default, messages are prioritized by insertion time, creating a
FIFO queue.

On a single host with MongoDB, it provides a zero-configuration message service
across local applications.  Alternatively, it can use a MongoDB database
cluster that provides replication and fail-over for an even more durable,
multi-host message queue.

Features:

=over 4

=item *

messages as hash references, not objects

=item *

arbitrary message fields

=item *

arbitrary scheduling on insertion

=item *

atomic message reservation

=item *

stalled reservations can be timed-out

=item *

task rescheduling

=item *

automatically creates correct index

=item *

fork-safe

=back

Not yet implemented:

=over 4

=item *

parameter checking

=item *

error handling

=back

Warning: do not use with capped collections, as the queued messages will not
meet the constraints required by a capped collection.

=head1 ATTRIBUTES

=head2 database_name

A MongoDB database name.  Unless a C<db_name> is provided in the
C<client_options> attribute, this database will be the default for
authentication.  Defaults to 'test'

=head2 client_options

A hash reference of L<MongoDB::MongoClient> options that will be passed to its
C<connect> method.

=head2 collection_name

A collection name for the queue.  Defaults to 'queue'.  The collection must
only be used by MongoDBx::Queue or unpredictable awful things will happen.

=head2 version

The implementation version to use as a backend.  Defaults to '1', which is the
legacy implementation for backwards compatibility.  Version '2' has better
index coverage and will perform better for very large queues.

B<WARNING> Versions are not compatible.  You MUST NOT have V1 and V2 clients
using the same database+collection name.  See L</MIGRATION BETWEEN VERSIONS>
for more.

=head1 METHODS

=head2 new

   $queue = MongoDBx::Queue->new(
        version => 2,
        database_name   => "my_app",
        client_options  => {
            host => "mongodb://example.net:27017",
            username => "willywonka",
            password => "ilovechocolate",
        },
   );

Creates and returns a new queue object.

=head2 add_task

  $queue->add_task( \%message, \%options );

Adds a task to the queue.  The C<\%message> hash reference will be shallow
copied into the task and not include objects except as described by
L<MongoDB::DataTypes>.  Top-level keys must not start with underscores, which are
reserved for MongoDBx::Queue.

The C<\%options> hash reference is optional and may contain the following key:

=over 4

=item *

C<priority>: sets the priority for the task. Defaults to C<time()>.

=back

Note that setting a "future" priority may cause a task to be invisible
to C<reserve_task>.  See that method for more details.

=head2 reserve_task

  $task = $queue->reserve_task;
  $task = $queue->reserve_task( \%options );

Atomically marks and returns a task.  The task is marked in the queue as
"reserved" (in-progress) so it can not be reserved again unless is is
rescheduled or timed-out.  The task returned is a hash reference containing the
data added in C<add_task>, including private keys for use by MongoDBx::Queue
methods.

Tasks are returned in priority order from lowest to highest.  If multiple tasks
have identical, lowest priorities, their ordering is undefined.  If no tasks
are available or visible, it will return C<undef>.

The C<\%options> hash reference is optional and may contain the following key:

=over 4

=item *

C<max_priority>: sets the maximum priority for the task. Defaults to C<time()>.

=back

The C<max_priority> option controls whether "future" tasks are visible.  If
the lowest task priority is greater than the C<max_priority>, this method
returns C<undef>.

=head2 reschedule_task

  $queue->reschedule_task( $task );
  $queue->reschedule_task( $task, \%options );

Releases the reservation on a task so it can be reserved again.

The C<\%options> hash reference is optional and may contain the following key:

=over 4

=item *

C<priority>: sets the priority for the task. Defaults to the task's original priority.

=back

Note that setting a "future" priority may cause a task to be invisible
to C<reserve_task>.  See that method for more details.

=head2 remove_task

  $queue->remove_task( $task );

Removes a task from the queue (i.e. indicating the task has been processed).

=head2 apply_timeout

  $queue->apply_timeout( $seconds );

Removes reservations that occurred more than C<$seconds> ago.  If no
argument is given, the timeout defaults to 120 seconds.  The timeout
should be set longer than the expected task processing time, so that
only dead/hung tasks are returned to the active queue.

=head2 search

  my @results = $queue->search( \%query, \%options );

Returns a list of tasks in the queue based on search criteria.  The
query should be expressed in the usual MongoDB fashion.  In addition
to MongoDB options (e.g. C<limit>, C<skip> and C<sort>) as described
in the MongoDB documentation for L<MongoDB::Collection/find>, this method
supports a C<reserved> option.  If present, results will be limited to reserved
tasks if true or unreserved tasks if false.

=head2 peek

  $task = $queue->peek( $task );

Retrieves a full copy of the task from the queue.  This is useful to retrieve all
fields from a projected result from C<search>.  It is equivalent to:

  $self->search( { _id => $task->{_id} } );

Returns undef if the task is not found.

=head2 size

  $queue->size;

Returns the number of tasks in the queue, including in-progress ones.

=head2 waiting

  $queue->waiting;

Returns the number of tasks in the queue that have not been reserved.

=for Pod::Coverage BUILD

=head1 MIGRATION BETWEEN VERSIONS

Implementation versions are not compatible.  Migration of active tasks from
version '1' to version '2' is an exercise left to end users.

One approach to migration could be to run a script with two C<MongoDBx::Queue>
clients, one using version '1' and one using version '2', using different
C<database_name> attributes.  Such a script could iteratively reserve a task
with the v1 client, add the task via the v2 client, then remove it via the v1
client.  Workers could be operating on one or both versions of the queue while
migration is going on, depending on your needs.

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/dagolden/MongoDBx-Queue/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/dagolden/MongoDBx-Queue>

  git clone https://github.com/dagolden/MongoDBx-Queue.git

=head1 AUTHOR

David Golden <dagolden@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by David Golden.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
