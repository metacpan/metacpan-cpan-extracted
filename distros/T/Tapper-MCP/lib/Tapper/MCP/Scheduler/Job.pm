package Tapper::MCP::Scheduler::Job;
our $AUTHORITY = 'cpan:TAPPER';
$Tapper::MCP::Scheduler::Job::VERSION = '5.0.7';
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
        no if $] >= 5.017011, warnings => 'experimental::smartmatch';
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
                                    return \$given ~~ \$_->{features}->{$entry};
                            } else {
                                    return \$_->{features}->{$entry} };
                    }";
                eval $eval_string; ## no critic
        }
        if ( not grep {$_ ~~ /hostname/} @functions ) {
                eval '
                sub hostname (;$) ## no critic (ProhibitSubroutinePrototypes)
                              {
                                      my ($given) = @_;

                                      if ($given) {
                                              # available
                                              return $given ~~ $_->{features}->{hostname};
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

This software is Copyright (c) 2018 by Advanced Micro Devices, Inc..

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut
