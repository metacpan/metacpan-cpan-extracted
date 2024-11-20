## no critic (RequireUseStrict)
package Tapper::MCP::Scheduler::Controller;
our $AUTHORITY = 'cpan:TAPPER';
# ABSTRACT: Main class of the scheduler
$Tapper::MCP::Scheduler::Controller::VERSION = '5.0.9';
use 5.010;
use Moose;
use base "Tapper::Base";
use Tapper::Model 'model';
use aliased 'Tapper::MCP::Scheduler::Algorithm';
use aliased 'Tapper::MCP::Scheduler::PrioQueue';
use Tapper::MCP::Net;
use Tapper::MCP::Scheduler::ObjectBuilder;


has hostlist  => (is => 'rw', isa => 'ArrayRef');
has algorithm => (is => 'rw',
                  isa => 'Tapper::MCP::Scheduler::Algorithm',
                  default => sub {
                          Algorithm->new_with_traits
                            (
                             traits => ['Tapper::MCP::Scheduler::Algorithm::WFQ']
                            );
                  }
                 );


has testrun   => (is => 'rw');
has cfg       => (is => 'ro', default => sub {{}});

with "Tapper::MCP::Net::TAP";



sub free_hosts_with_features
{
        my $hosts =  model('TestrunDB')->resultset("Host")->search({active => 1, free => 1});
        $hosts->result_class('DBIx::Class::ResultClass::HashRefInflator');
        my $obj_builder = Tapper::MCP::Scheduler::ObjectBuilder->instance;

        my @hosts_with_features;
        while (my $host = $hosts->next) {
                my $features = Tapper::Model::get_hardware_overview($host->{id});
                $features->{hostname} = $host->{name};
                my $host_obj = $obj_builder->new_host(%$host);
                push @hosts_with_features, {host => $host_obj, features => $features};
        }
        return \@hosts_with_features;
}

sub available_resources
{
        my $resources = model('TestrunDB')->resultset("Resource")->search(
                {active => 1, used_by_scheduling_id => undef});
        my @_available_resources;
        while (my $resource = $resources->next) {
                push @_available_resources, $resource;
        }
        return \@_available_resources;
}


sub official_queuelist
{

        my $queue_rs = model('TestrunDB')->resultset('Queue')->search({active=> 1}
                                                                      ,{result_class => 'DBIx::Class::ResultClass::HashRefInflator'});
        my %queues;
        while (my $q = $queue_rs->next) {
                $queues{$q->{name}} = $q;
        }

        my %queue_objects;
        my $obj_builder = Tapper::MCP::Scheduler::ObjectBuilder->instance;
        foreach my $name (keys %queues) {
                $queue_objects{$name} = $obj_builder->new_queue(%{$queues{$name}});
        }
        return \%queue_objects;
}




sub toggle_bandwith_color {
        my ($self, $free_hosts, $queue) = @_;

        return 0 if @{$queue->jobs} == 0;
        foreach my $free_host ( map {$_->{host} } @$free_hosts) {
                if (@{$free_host->queues}) {
                QUEUE_CHECK:
                        {
                                foreach my $queuehost (@{$free_host->queues}) {
                                        return 0 if $queue->id == $queue->id;
                                }
                        }
                } else {
                        return 0;
                }
        }
        return 1;
}



sub get_next_job {
        my ($self, %args) = @_;

        my $obj_builder = Tapper::MCP::Scheduler::ObjectBuilder->instance;
        $obj_builder->clear();

        my ($queue, $job);

        do {{

                my $free_hosts = $self->free_hosts_with_features();
                return if not ($free_hosts and @$free_hosts);

                my $available_resources = $self->available_resources();

                my $queues = $self->official_queuelist();

                my $white_bandwith=1; # chosen queue was first choice

                # reset the list of associated jobs with this queue on every get_next_job
                my $prioqueue = PrioQueue->new();
                $job = $prioqueue->get_first_fitting($free_hosts, $available_resources);


        QUEUE:
                while (not $job) {

                        my $queue = $self->algorithm->lookup_next_queue($queues);
                        return () unless $queue;
                        if ($job = $queue->get_first_fitting($free_hosts, $available_resources)) {
                                if ($job->auto_rerun) {
                                        $job->testrun->rerun;
                                }
                                if ($job->testrun->scenario_element) {
                                ELEMENT:
                                        foreach my $element ($job->testrun->scenario_element->peer_elements) {
                                                my $peer_job = $element->testrun->testrun_scheduling;
                                                next ELEMENT if $peer_job->id == $job->id;
                                                $prioqueue->add($peer_job);
                                        }
                                }
                                $self->algorithm->update_queue($job->queue) if $white_bandwith;
                                last QUEUE;
                        } else {
                                delete $queues->{$queue->name};
                                $white_bandwith=0 if $self->toggle_bandwith_color($free_hosts, $queue);

                        }
                        last QUEUE if not %$queues;
                }

                if ($job and $job->testrun->scenario_element) {
                        $self->mark_job_as_running($job);
                        if ($job->testrun->scenario_element->peers_need_fitting > 0) {
                                # do not return this job already
                                $job = undef;
                                next;
                        } else {
                                return map{$_->testrun->testrun_scheduling} $job->testrun->scenario_element->peer_elements->all;
                        }
                }
        }
    } while (not $job and $args{try_until_found});

        return $job || () ;
}


sub mark_job_as_running {
        my ($self, $job) = @_;

        $job->testrun->starttime_testrun(model('TestrunDB')->storage->datetime_parser->format_datetime(DateTime->now));
        $job->testrun->update();
        $job->mark_as_running;
}

sub mark_job_as_finished {
        my ($self, $job) = @_;

        $job->testrun->endtime_test_program(model('TestrunDB')->storage->datetime_parser->format_datetime(DateTime->now));
        $job->testrun->update();
        $job->mark_as_finished;
}

1;                           # End of Tapper::MCP::Scheduler::Controller

__END__

=pod

=encoding UTF-8

=head1 NAME

Tapper::MCP::Scheduler::Controller - Main class of the scheduler

=head2 official_queuelist

Create a list of all active queues with their associated testruns.

=head2

Check whether we need to change from scheduling white bandwidth to black bandwidth.

@return black - 1
@return white - 0

=head2 get_next_job

Pick a testrequest and prepare it for execution. Returns 0 if not testrequest
fits any of the free hosts.

@param ArrayRef - array of host objects associated to hosts with no current test

@return success   - job object
@return no job    - 0

=head1 AUTHORS

=over 4

=item *

AMD OSRC Tapper Team <tapper@amd64.org>

=item *

Tapper Team <tapper-ops@amazon.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2024 by Advanced Micro Devices, Inc.

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut
