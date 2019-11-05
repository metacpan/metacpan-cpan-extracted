package Tapper::Schema::TestrunDB::Result::Queue;
our $AUTHORITY = 'cpan:TAPPER';
$Tapper::Schema::TestrunDB::Result::Queue::VERSION = '5.0.11';
# ABSTRACT: Tapper - Containing queues of testruns

use strict;
use warnings;

use parent 'DBIx::Class';

__PACKAGE__->load_components(qw/InflateColumn::DateTime Core/);
__PACKAGE__->table("queue");
__PACKAGE__->add_columns
    (
     "id",         { data_type => "INT",       default_value => undef,                is_nullable => 0, size => 11,    is_auto_increment => 1, },
     "name",       { data_type => "VARCHAR",   default_value => "",                   is_nullable => 1, size => 255,                           },
     "priority",   { data_type => "INT",       default_value => 0,                    is_nullable => 0, size => 10,                            },
     "runcount",   { data_type => "INT",       default_value => 0,                    is_nullable => 0, size => 10,                            }, # aux for algorithm
     "active",     { data_type => "INT",       default_value => 0,                    is_nullable => 1, size => 1,                             },
     "is_deleted", { data_type => "TINYINT",   default_value => "0",                  is_nullable => 1,                                        }, # deleted queues need to be kept in db to show old testruns correctly
     "created_at", { data_type => "TIMESTAMP", default_value => \'CURRENT_TIMESTAMP', is_nullable => 1,                                        }, #' emacs highlight bug
     "updated_at", { data_type => "DATETIME",  default_value => undef,                is_nullable => 1,                                        },
    );

(my $basepkg = __PACKAGE__) =~ s/::\w+$//;

__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint( unique_queue_name => [ qw/name/ ], );
__PACKAGE__->has_many ( testrunschedulings => 'Tapper::Schema::TestrunDB::Result::TestrunScheduling', { 'foreign.queue_id' => 'self.id' });
__PACKAGE__->has_many ( queuehosts         => "${basepkg}::QueueHost",         { 'foreign.queue_id' => 'self.id' });
__PACKAGE__->has_many ( deniedhosts         => "${basepkg}::DeniedHost",       { 'foreign.queue_id' => 'self.id' });

# -------------------- methods on results --------------------


sub queued_testruns
{
        my ($self) = @_;

        $self->testrunschedulings->search({
                                           status => 'schedule'
                                          },
                                          {
                                           order_by => 'testrun_id'
                                          });
}


sub get_first_fitting
{
        my ($self, $free_hosts) = @_;
        my $jobs = $self->queued_testruns;
        foreach my $job ($jobs->all()) {
                if (my $host = $job->fits($free_hosts)) {
                        $job->host_id ($host->id);

                        if ($job->testrun->scenario_element) {
                                $job->testrun->scenario_element->is_fitted(1);
                                $job->testrun->scenario_element->update();
                        }
                        return $job;
                }
        }
        return;
}


sub to_string
{
        my ($self) = @_;

        my $format = join( $Tapper::Schema::TestrunDB::DELIM, qw/%s %s %s %s %s %s %s %s %s %s %s %s %s %s /, '');
        sprintf (
                 $format,
                 map {
                      defined $self->$_
                      ? $self->$_
                      : $Tapper::Schema::TestrunDB::NULL
                     } @{$self->result_source->{_ordered_columns} }
                );
}


sub is_member
{
        my ($head, @tail) = @_;
        grep { $head->id eq $_->id } @tail;
}


sub ordered_preconditions
{
        my ($self) = @_;

        my @done = ();
        my %seen = ();
        my @todo = ();

        @todo = $self->preconditions->search({}, {order_by => 'succession'})->all;

        while (my $head = shift @todo)
        {
                if ($seen{$head->id})
                {
                        push @done, $head unless is_member($head, @done);
                }
                else
                {
                        $seen{$head->id} = 1;
                        my @pre_todo = $head->child_preconditions->search({}, { order_by => 'succession' } )->all;
                        unshift @todo, @pre_todo, $head;
                }
        }
        return @done;
}


sub producer
{
        my ($self) = @_;

        my $producer_class = "Tapper::MCP::Scheduler::PreconditionProducer::".$self->producer;
        eval "use $producer_class"; ## no critic (ProhibitStringyEval)
        return $producer_class->new unless $@;
        return;
}


sub produce
{
        my ($self, $request) = @_;

        my $producer = $self->producer;

        if (not $producer) {
                warn "Queue ".$self->name." does not have an associated producer";
        } else {
                print STDERR "Queue.producer: ", Dumper($producer);
                return $producer->produce($request);
        }
}


sub update_content {
        my ($self, $args) =@_;

        require DateTime;
        $self->priority( $args->{priority} ) if exists($args->{priority});
        $self->active( $args->{active} ) if exists($args->{active});
        $self->updated_at( DateTime->now->strftime('%F %T') );
        $self->update;

        return $self->id;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Tapper::Schema::TestrunDB::Result::Queue - Tapper - Containing queues of testruns

=head2 queued_testruns

Return all scheduled testruns in current queue.

=head2 get_first_fitting

Return first fitting testrun according to the scheduling rules.

=head2 to_string

Return a readable repesentation of Queue.

=head2 is_member($head, @tail)

Checks if the first element is already in the list of the remaining
elements.

=head2 ordered_preconditions

Returns all preconditions in the order they need to be installed.

=head2 producer

Return instance of PreconditionProducer according to associated
producer.

=head2 produce

Return associated producer.

=head2 update_content

Update I<priority> and I<active> flags.

=head1 AUTHORS

=over 4

=item *

AMD OSRC Tapper Team <tapper@amd64.org>

=item *

Tapper Team <tapper-ops@amazon.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Advanced Micro Devices, Inc..

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut
