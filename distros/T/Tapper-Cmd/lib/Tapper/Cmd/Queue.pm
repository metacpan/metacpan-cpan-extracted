package Tapper::Cmd::Queue;
our $AUTHORITY = 'cpan:TAPPER';
$Tapper::Cmd::Queue::VERSION = '5.0.11';
use Moose;

use DateTime;

use Tapper::Model 'model';

extends 'Tapper::Cmd';





sub add {
        my ($self, $args) = @_;
        my %args = %{$args};    # copy

        $args{is_deleted} = 0;

        my $q = model('TestrunDB')->resultset('Queue')->update_or_create(\%args);
        $q->insert;
        my $all_queues = model('TestrunDB')->resultset('Queue');


        # the new queue now has a much lower runcount than all others
        # If we keep this situation the new queue would be scheduled
        # until it catches up with the other queues. To prevent this we
        # reset the runcount of all queues.
        foreach my $queue ($all_queues->all) {
                $queue->runcount($queue->priority);
                $queue->update;
        }
        return $q->id;
}



sub update {
        my ($self, $queue, $args) = @_;

        if (! (ref $queue && $queue->isa('Tapper::Schema::TestrunDB::Result::Queue')) ) {
                $queue = model('TestrunDB')->resultset('Queue')->find( $queue );
        }

        my $retval = $queue->update_content( $args );
        my $all_queues = model('TestrunDB')->resultset('Queue');

        if (defined($args->{priority})) {
                # The priority of the queue has changed. Without the following
                # changes the queue would be scheduled/not scheduled until its
                # runcount is in correct relation to all others. Therefore, we
                # reset the runcount to have scheduling working correctly immediatelly.
                foreach my $queue ($all_queues->all) {
                        $queue->runcount($queue->priority);
                        $queue->update;
                }
        }

        require DateTime;
        foreach my $queue ( model('TestrunDB')->resultset('Queue')->all ) {
                if ( $queue->runcount ne $queue->priority ) {
                        $queue->runcount( $queue->priority );
                        $queue->updated_at( DateTime->now->strftime('%F %T') );
                        $queue->update;
                }
        }

        return $retval;
}


sub del {

    my ( $self, $queue, $force ) = @_;

    # queue is not a result object
    if (! ref $queue ) {
        $queue = model('TestrunDB')->resultset('Queue')->find( $queue );
    }

    # empty queues can be deleted, because it does not break anything
    if ( $force || $queue->testrunschedulings->count == 0 ) {
        $queue->delete;
    }
    else {

        require DateTime;
        $queue->is_deleted( 1 );
        $queue->active( 0 );
        $queue->updated_at( DateTime->now->strftime('%F %T') );
        $queue->update;

        if ( my $or_attached_jobs = $queue->testrunschedulings->search({ status => 'schedule' }) ) {
            $or_attached_jobs->update({ status => 'finished' });
        }
    }

    return 0;

}

1; # End of Tapper::Cmd::Testrun

__END__

=pod

=encoding UTF-8

=head1 NAME

Tapper::Cmd::Queue

=head1 SYNOPSIS

This project offers backend functions for all projects that manipulate
queues in the database. This module handles the testrun part.

    use Tapper::Cmd::Queue;

    my $bar = Tapper::Cmd::Queue->new();
    $bar->add($testrun);
    ...

=head1 NAME

Tapper::Cmd::Queue - Backend functions for manipluation of queues in the database

=head1 FUNCTIONS

=head2 add

Add a new queue to database.

=head2 add

Add a new queue.
-- required --
* name - string
* priority - int

@param hash ref - options for new queue

@return success - queue id
@return error   - undef

=head2 update

Changes values of an existing queue.

@param int or object ref    - queue id or queue object
@param hash ref             - overwrite these options

@return success             - queue id
@return error               - undef

=head2 del

Delete a queue with given id. Its named del instead of delete to prevent
confusion with the buildin delete function. If the queue is not empty
and force is not given, we keep the queue and only set it to deleted to
not break showing old testruns and their results.

@param      - queue result || queue id
@param bool - force deleted

@return success - 0
@return error   - error string

=head1 AUTHORS

=over 4

=item *

AMD OSRC Tapper Team <tapper@amd64.org>

=item *

Tapper Team <tapper-ops@amazon.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Advanced Micro Devices, Inc..

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut
