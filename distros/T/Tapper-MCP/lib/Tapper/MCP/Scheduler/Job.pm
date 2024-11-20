package Tapper::MCP::Scheduler::Job;
our $AUTHORITY = 'cpan:TAPPER';
$Tapper::MCP::Scheduler::Job::VERSION = '5.0.9';
use strict;
use warnings;

use Moose;
use Safe;
use Tapper::Model;
use Tapper::MCP::Scheduler::ObjectBuilder;


has id            => (is => 'ro');
has testrun_id    => (is => 'ro');
has queue_id      => (is => 'ro');
has host_id       => (is => 'rw');  # needs to be rw because we set the host we actually use
has prioqueue_seq => (is => 'ro');
has status        => (is => 'ro');
has auto_rerun    => (is => 'ro');
has created_at    => (is => 'ro');
has updated_at    => (is => 'ro');

has testrun       => (is => 'ro',
                      lazy => 1,
                      default => sub {
                              my $self = shift;
                              return Tapper::Model::model('TestrunDB')->resultset('Testrun')->search({id => $self->testrun_id}, {rows => 1})->first;
                      });

has requested_features => (is => "ro",
                           lazy => 1,
                           default => sub {
                                   my ($self) = shift;
                                   my @return_feat;
                                   my $feats = Tapper::Model::model('TestrunDB')->resultset('TestrunRequestedFeature')->search({testrun_id => $self->testrun_id});
                                   $feats->result_class('DBIx::Class::ResultClass::HashRefInflator');
                                   while (my $this_feat = $feats->next) {
                                           push @return_feat, $this_feat;
                                   }
                                   return \@return_feat;
                           });
has requested_hosts => (is => "ro",
                        lazy => 1,
                        default => sub {
                                my ($self) = shift;
                                my @return_hosts;
                                my $hosts = Tapper::Model::model('TestrunDB')->resultset('TestrunRequestedHost')->search({testrun_id => $self->testrun_id});
                                my $obj_builder = Tapper::MCP::Scheduler::ObjectBuilder->instance;
                                while (my $this_host = $hosts->next) {
                                        my $host_rs =  Tapper::Model::model->resultset('Host')->search({id => $this_host->host->id},{result_class => 'DBIx::Class::ResultClass::HashRefInflator'});
                                        push @return_hosts, $obj_builder->new_host(%{$host_rs->search({}, {rows => 1})->first});
                                }
                                return \@return_hosts;
                        });
has requested_resources => (is => "ro",
                            lazy => 1,
                            default => sub {
                                my ($self) = shift;
                                my $resource_reqs = Tapper::Model::model('TestrunDB')->resultset('TestrunRequestedResource')->search(
                                        {testrun_id => $self->testrun_id},{ prefetch => 'alternatives' });

                                my @requested_resources;
                                while (my $resource_req = $resource_reqs->next) {
                                        push @requested_resources, $resource_req;
                                }

                                return \@requested_resources;
                        });
has queue         => (is => 'ro',
                      lazy => 1,
                      default => sub {
                              my ($self) = shift;
                              my @return_obj;
                              my $queue_host = Tapper::Model::model('TestrunDB')->resultset('QueueHost')->search({queue_id => $self->id});
                              my $queue = Tapper::Model::model->resultset('Queue')->search({id => $queue_host->queue->id},{result_class => 'DBIx::Class::ResultClass::HashRefInflator'});
                              my $obj_builder = Tapper::MCP::Scheduler::ObjectBuilder->instance;
                              return $obj_builder->new_queue(%{$queue->search({}, {rows => 1})->first});
                       });

# ----- scheduler related methods -----

sub match_host {
        my ($self, $free_hosts) = @_;

        foreach my $req_host (@{$self->requested_hosts})
        {
                no strict 'refs'; ## no critic (ProhibitNoStrict)
        FREE_HOST:
                foreach my $free_host( map {$_->{host} } @$free_hosts) {
                        if (@{$free_host->queues}){
                                QUEUE_CHECK:
                                {
                                        foreach my $queue(@{$free_host->queues}) {
                                                last QUEUE_CHECK if $queue->id == $self->queue_id;
                                        }
                                        next FREE_HOST;
                                }
                        }
                        return $free_host if $free_host->name eq $req_host->name;
                }
        }
        return;
}


our @functions;
BEGIN {
        my $features = Tapper::Model::model->resultset('HostFeature')->search(
                                                                              {
                                                                              },
                                                                              {
                                                                               columns => [ qw/entry/ ],
                                                                               distinct => 1,
                                                                              });

        while ( my $feature = $features->next ) {
                my $entry = $feature->entry;
                push @functions, "&".$entry;
                my $eval_string = "sub $entry (;\$)";
                $eval_string   .= "{
                            my (\$given) = \@_;

                            if (\$given) {
                                    # available
                                    return \$given eq \$_->{features}->{$entry};
                            } else {
                                    return \$_->{features}->{$entry} };
                    }";
                eval $eval_string; ## no critic
        }
        if ( not grep {$_ =~ /hostname/} @functions ) {
                eval '
                sub hostname (;$) ## no critic (ProhibitSubroutinePrototypes)
                              {
                                      my ($given) = @_;

                                      if ($given) {
                                              # available
                                              return $given eq $_->{features}->{hostname};
                                      } else {
                                              return $_->{features}->{hostname};
                                      }
                              }';
                push @functions, "&hostname";
        }
}

sub match_feature {
        my ($self, $free_hosts) = @_;
 HOST:
        foreach my $host( @$free_hosts )
        {
                # filter out queuebound hosts
                if (@{$host->{host}->queues}){
                QUEUE_CHECK:
                        {
                                foreach my $queuehost(@{$host->{host}->queues}) {
                                        last QUEUE_CHECK if $queuehost->queue->id == $self->queue->id;
                                }
                                next HOST;
                        }
                }

                $_ = $host;
                my $compartment = Safe->new();
                $compartment->permit(qw(:base_core));
                $compartment->share(@functions);

                foreach my $this_feature( @{$self->requested_features} )
                {
                        my $success = $compartment->reval($this_feature->{feature});
                        print STDERR "Error in TestRequest.fits: ", $@ if $@;
                        next HOST if not $success;
                }
                return $host->{host};
        }
        return;
}

# Tries to acquire resources for job
# Returns 2 values
# - If all requested resources are available
# - Which resources were acquired (array ref) or undef if not possible
sub claim_resources {
        my ($self, $free_resources) = @_;

        my %res_lookup;
        $res_lookup{$_->id} = $_ foreach (@$free_resources);

        my @acquire_resources;

        # Transaction, rollback unless commit is called on this
        my $guard = Tapper::Model->model('TestrunDB')->txn_scope_guard;

        foreach my $res_request (@{$self->requested_resources})
        {
                my $best_alternative;
                foreach my $res_alternative ($res_request->alternatives)
                {
                        if (my $resource = $res_lookup{$res_alternative->resource_id})
                        {
                                $best_alternative = $resource;
                                last;
                        }
                }

                return (0,undef) unless defined $best_alternative;

                # Remove from lookup so it won't be chose twice.
                delete $res_lookup{$best_alternative->id};

                # Remember choice for frontends
                $res_request->selected_resource($best_alternative);
                $res_request->update;

                # Mark as in use
                $best_alternative->used_by_scheduling_id($self->{id});
                $best_alternative->update;

                push @acquire_resources, $best_alternative;
        }

        $guard->commit;

        return (1, \@acquire_resources);
}

# Checks whether all testruns that our job depends on have finished.
sub dependencies_finished {
        my ($self) = @_;
        my $unfinished_dependency = Tapper::Model::model('TestrunDB')->resultset('TestrunDependency')->search({
                'depender_testrun_id' => $self->testrun_id,
                'testrun_scheduling.status' => { '!=', 'finished' },
        },{
                'join' => { dependee => 'testrun_scheduling' },
        })->first;

        return !defined($unfinished_dependency);
}

# Checks a TestrunScheduling against a list of available hosts
# returns the matching host
sub fits {
        my ($self, $free_hosts) = @_;

        if (not $free_hosts)
        {
                return;
        }
        elsif (@{$self->requested_hosts})
        {
                my $host = $self->match_host($free_hosts);
                if ($host)
                {
                        return $host;
                }
                elsif (@{$self->requested_features})
                {
                        $host = $self->match_feature($free_hosts);
                        return $host if $host;
                }
        }
        elsif (@{$self->requested_features}) # but no wanted hostnames
        {
                my $host = $self->match_feature($free_hosts);
                return $host if $host;
        }
        else # free_hosts but no wanted hostnames and no requested_features
        {
                foreach my $host (map {$_->{host} } @$free_hosts) {
                        if (@{$host->queues}){
                                foreach my $queue(@{$host->queues}) {
                                        return $host if $queue->id == $self->queue_id;
                                }
                        } else {
                                return $host;
                        }

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

Tapper::MCP::Scheduler::Job

=head1 SYNOPSIS

Abstraction for the database table testrun_scheduling.

=head1 NAME

Tapper::MCP::Scheduler::Job - Job object for Tapper scheduler

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

This software is Copyright (c) 2024 by Advanced Micro Devices, Inc.

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut
