package Tapper::MCP::Scheduler::Queue;
our $AUTHORITY = 'cpan:TAPPER';
$Tapper::MCP::Scheduler::Queue::VERSION = '5.0.7';
use strict;
use warnings;

use Moose;
use MooseX::ClassAttribute;
use Tapper::Model 'model';
use Tapper::MCP::Scheduler::ObjectBuilder;
use Scalar::Util qw/weaken/;
use Perl6::Junction qw/any/;


has id                 => (is => 'ro');
has name               => (is => 'ro');
has priority           => (is => 'ro');
has runcount           => (is => 'rw');
has active             => (is => 'ro');
has is_deleted         => (is => 'ro');
has created_at         => (is => 'ro');
has updated_at         => (is => 'ro');
has testrunschedulings => (is => 'ro',
                           lazy => 1,
                           default => sub {
                                   my ($self) = shift;
                                   my @return_jobs;
                                   my $jobs = model('TestrunDB')->resultset('TestrunScheduling')->search({queue_id => $self->id, status => 'schedule'});
                                   $jobs->result_class('DBIx::Class::ResultClass::HashRefInflator');
                                   my $obj_builder = Tapper::MCP::Scheduler::ObjectBuilder->instance;

                                   while (my $this_job = $jobs->next) {
                                           $this_job->{queue} = $self;
                                           push @return_jobs, $obj_builder->new_job(%{$this_job});
                                           weaken $return_jobs[$#return_jobs];
                                   }
                                   return \@return_jobs;
                           });
has queuehosts         => (is => 'ro',
                           lazy => 1,
                           default => sub {
                                   my ($self) = shift;
                                   my @return_hosts;
                                   my $queue_hosts = model('TestrunDB')->resultset('QueueHost')->search({queue_id => $self->id});
                                   my $obj_builder = Tapper::MCP::Scheduler::ObjectBuilder->instance;


                                   while (my $this_qh = $queue_hosts->next) {
                                           my $hosts = model->resultset('Host')->search({id => $this_qh->host->id},{result_class => 'DBIx::Class::ResultClass::HashRefInflator'});
                                           push @return_hosts, $obj_builder->new_host(%{$hosts->search({}, {rows => 1})->first});
                                           weaken $return_hosts[$#return_hosts];

                                   }
                                   return \@return_hosts;
                           });
has deniedhosts  => (is => 'ro',
                         lazy => 1,
                         default => sub {
                                   my ($self) = shift;
                                   my @return_hosts;
                                   my $queue_hosts = model('TestrunDB')->resultset('DeniedHost')->search({queue_id => $self->id});
                                   my $obj_builder = Tapper::MCP::Scheduler::ObjectBuilder->instance;


                                   while (my $this_qh = $queue_hosts->next) {
                                           my $hosts = model->resultset('Host')->search({id => $this_qh->host->id},{result_class => 'DBIx::Class::ResultClass::HashRefInflator'});
                                           push @return_hosts, $obj_builder->new_host(%{$hosts->search({}, {rows => 1})->first});
                                           weaken $return_hosts[$#return_hosts];

                                   }
                                   return \@return_hosts;
                           },
                         );


sub jobs
{
        my $self = shift;
        return $self->testrunschedulings;
}

sub get_first_fitting
{
        my ($self, $free_hosts) = @_;

        my @forbidden_host_names;
        @forbidden_host_names = map {$_->name} @{$self->deniedhosts};

        # "x ne any(x,y)" is not the same as "not x eq any(x,y)". That migt be confusing, so please keep the "not eq".
        my @new_free_hosts = grep((not $_->{host}->name eq any(@forbidden_host_names)), @$free_hosts);
        $free_hosts = \@new_free_hosts;


        foreach my $job (@{$self->testrunschedulings}) {
                my $host = $job->fits($free_hosts);
                if ($host) {
                        my $db_job = model('TestrunDB')->resultset('TestrunScheduling')->find($job->{id});
                        $db_job->host_id ($host->id);

                        if ($db_job->testrun->scenario_element) {
                                $db_job->testrun->scenario_element->is_fitted(1);
                                $db_job->testrun->scenario_element->update();
                        }
                        $db_job->update;
                        return $db_job;
                }
        }
        return;
}

  __PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Tapper::MCP::Scheduler::Queue

=head1 SYNOPSIS

Abstraction for the database table.

=head1 NAME

Tapper::MCP::Scheduler::Queue - Queue object for Tapper scheduler

=head1 AUTHOR

AMD OSRC Tapper Team, C<< <tapper at amd64.org> >>

=head1 BUGS

None.

=head1 COPYRIGHT & LICENSE

Copyright 2008-2011 AMD OSRC Tapper Team, all rights reserved.

This program is released under the following license: freebsd

=head1 AUTHORS

=over 4

=item *

AMD OSRC Tapper Team <tapper@amd64.org>

=item *

Tapper Team <tapper-ops@amazon.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Advanced Micro Devices, Inc..

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut
