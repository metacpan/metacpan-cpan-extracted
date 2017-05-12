package Tapper::Cmd::Testrun;
our $AUTHORITY = 'cpan:TAPPER';
$Tapper::Cmd::Testrun::VERSION = '5.0.8';
use Moose;
use Tapper::Model 'model';
use DateTime;
use Perl6::Junction qw/any/;
use Hash::Merge::Simple qw/merge/;
use Try::Tiny;

use parent 'Tapper::Cmd';
use Tapper::Cmd::Requested;
use Tapper::Cmd::Precondition;
use Tapper::Cmd::Notification;



sub find_matching_hosts
{
        return;
}



sub create
{
        my ($self, $plan, $instance) = @_;

        if ( not ref($plan) ) {
                require YAML::Syck;
                $plan = YAML::Syck::Load($plan);
        }

        if ( not ref($plan) eq 'HASH' ) {
                die "'$plan' is not YAML containing a testrun description\n";
        }

        my @preconditions = Tapper::Cmd::Precondition
            ->new({ schema => $self->schema })
            ->add($plan->{preconditions})
        ;

        my %args          = map { lc($_) => $plan->{$_} } grep { lc($_) ne 'preconditions' and $_ !~ /^requested/i } keys %$plan;

        my @testruns;
        foreach my $host (@{$plan->{requested_hosts_all} || [] }) {
                my $merged_arguments = merge \%args, {precondition    => $plan->{preconditions},
                                                      requested_hosts => $host,
                                                      testplan_id     => $instance,
                                                     };
                my $testrun_id = $self->add($merged_arguments);
                $self->assign_preconditions($testrun_id, @preconditions);
                push @testruns, $testrun_id;
        }
        if ($plan->{requested_hosts_any}) {
                my $merged_arguments = merge \%args, {precondition    => $plan->{preconditions},
                                                      requested_hosts => $plan->{requested_hosts_any},
                                                      testplan_id     => $instance};
                my $testrun_id = $self->add($merged_arguments );
                $self->assign_preconditions($testrun_id, @preconditions);
                push @testruns, $testrun_id;
        }
        foreach my $host ($self->find_matching_hosts($plan->{requested_features_all})) {
                my $merged_arguments = merge \%args, {precondition    => $plan->{preconditions},
                                                      requested_hosts => $host,
                                                      testplan_id     => $instance};
                my $testrun_id = $self->add($merged_arguments );
                $self->assign_preconditions($testrun_id, @preconditions);
                push @testruns, $testrun_id;
        }
        if ($plan->{requested_features_any}) {
                my $merged_arguments = merge \%args, {precondition       => $plan->{preconditions},
                                                      requested_features => $plan->{requested_features_any},
                                                      testplan_id        => $instance};
                my $testrun_id = $self->add($merged_arguments );
                $self->assign_preconditions($testrun_id, @preconditions);
                push @testruns, $testrun_id;
        }
        if ( not grep { $_ =~ /^requested/i } keys %$plan) {
                my $merged_arguments = merge \%args, {precondition    => $plan->{preconditions},
                                                      testplan_id     => $instance,
                                                     };
                my $testrun_id = $self->add($merged_arguments);
                $self->assign_preconditions($testrun_id, @preconditions);
                push @testruns, $testrun_id;
        }

        return @testruns;

}




sub add {

        my ($self, $received_args) = @_;

        my %args = %{$received_args || {}}; # copy

        $args{notes}                 ||= '';
        $args{shortname}             ||= '';

        my ( $testrun_id, $exception );
        my $or_schema = $self->schema;

        try {
                $or_schema->txn_do(sub {

                        $args{topic_name}              = $args{topic} || 'Misc';
                        my $topic = $or_schema->resultset('Topic')->find_or_create({name => $args{topic_name}});
                
                        $args{earliest}              ||= DateTime->now;
                        $args{owner}                 ||= $ENV{USER} || 'nobody';
                        $args{owner_id}              ||= Tapper::Model::get_or_create_owner( $args{owner} );
                
                        if ($args{requested_hosts} and not $args{requested_host_ids}) {
                                foreach my $host (@{ref $args{requested_hosts} eq 'ARRAY' ? $args{requested_hosts} : [ $args{requested_hosts} ]}) {
                                        my $host_result = $or_schema->resultset('Host')->search({name => $host}, {rows => 1})->first;
                                        die "Can not request host '$host'. This host is not known to tapper\n" if not $host_result;
                                        push @{$args{requested_host_ids}}, $host_result->id if $host_result;
                                }
                        }
                
                        if ( not $args{queue_id} ) {
                                $args{queue}   ||= 'AdHoc';
                                my $queue_result = $or_schema->resultset('Queue')->search({name => $args{queue}});
                                die qq{Queue "$args{queue}" does not exists\n} if not $queue_result->count;
                                $args{queue_id}  = $queue_result->search({}, {rows => 1})->first->id;
                        }

                        $testrun_id = $or_schema->resultset('Testrun')->add(\%args);

                        if ( $args{requested_features} ) {
                                foreach my $feature (
                                        @{
                                                ref $args{requested_features} eq 'ARRAY'
                                                        ? $args{requested_features}
                                                        : [ $args{requested_features} ]
                                        }
                                ) {
                                        $or_schema
                                            ->resultset('TestrunRequestedFeature')
                                            ->new({testrun_id => $testrun_id, feature => $feature})
                                            ->insert()
                                        ;
                                }
                        }

                        if ( exists $args{notify} ) {
                                my $s_notify = $args{notify} // q##;
                                my $notify   = Tapper::Cmd::Notification->new();
                                my $filter   = "testrun('id') == $testrun_id";
                                if (lc $args{notify} eq any('pass', 'ok','success')) {
                                        $filter .= " and testrun('success_word') eq 'pass'";
                                } elsif (lc $args{notify} eq any('fail', 'not_ok','error')) {
                                        $filter .= " and testrun('success_word') eq 'fail'";
                                }
                                try {
                                        $notify->add({filter   => $filter,
                                                      owner_id => $args{owner_id},
                                                      event    => "testrun_finished",
                                                     });
                                } catch {
                                        $exception = "Successfully created your testrun with id $testrun_id but failed to add a notification request\n$_";
                                }
                        }
                });
        }
        catch {
                $exception = $_;
        };

        if ( wantarray ) {
            return ( $testrun_id, $exception );
        }
        else {
            if ( $exception ) {
                die $exception;
            }
            return $testrun_id;
        }

}



sub update {
        my ($self, $id, $args) = @_;
        my %args = %{$args};    # copy

        my $testrun = $self->schema->resultset('Testrun')->find($id);

        $args{owner_id} = $args{owner_id} || Tapper::Model::get_or_create_owner( $args{owner} ) if $args{owner};

        return $testrun->update_content(\%args);
}


sub del {
        my ($self, $id) = @_;
        my $testrun = $self->schema->resultset('Testrun')->find($id);
        if ($testrun->testrun_scheduling) {
                return "Running testruns can not be deleted. Try freehost or wait till the testrun is finished."
                  if $testrun->testrun_scheduling->status eq 'running';
                if ($testrun->testrun_scheduling->requested_hosts->count) {
                        foreach my $host ($testrun->testrun_scheduling->requested_hosts->all) {
                                $host->delete();
                        }
                }
                if ($testrun->testrun_scheduling->requested_features->count) {
                        foreach my $feat ($testrun->testrun_scheduling->requested_features->all) {
                                $feat->delete();
                        }
                }
        }

        $testrun->delete();
        return 0;
}


sub rerun {
        my ($self, $id, $args) = @_;
        my %args = %{$args || {}}; # copy
        my $testrun = $self->schema->resultset('Testrun')->find( $id );
        return $testrun->rerun(\%args)->id;
}


sub pause {
        my ($self, $id) = @_;
        my $testrun = $self->schema->resultset('TestrunScheduling')->search
            ({
                testrun_id => $id,
                status => 'schedule',
             })->first;
        if ($testrun and $testrun->testrun_id) {
            return $testrun->update_content({status => 'prepare'});
        }
        return;
}


sub continue {
        my ($self, $id) = @_;
        my $testrun = $self->schema->resultset('TestrunScheduling')->search
            ({
                testrun_id => $id,
                status => 'prepare',
             })->first;
        if ($testrun and $testrun->testrun_id) {
            return $testrun->update_content({status => 'schedule'});
        }
        return;
}


sub cancel
{
        my ($self, $testrun_id, $comment) = @_;
        my $msg = { 'state' => 'quit', };
        if ( $comment ) {
                $msg->{error} = $comment;
        }
        my $testrun_result = $self->schema->resultset('Testrun')->find( $testrun_id ) or die "No such testrun '$testrun_id'\n";
        if ($testrun_result->testrun_scheduling->status eq 'schedule' or
            $testrun_result->testrun_scheduling->status eq 'prepare'
           ) {
                $testrun_result->testrun_scheduling->status('finished');
                $testrun_result->testrun_scheduling->update;
        } elsif ( $testrun_result->testrun_scheduling->status eq 'running') {
                $self->schema->resultset('Message')->new({
                                                  testrun_id => $testrun_id,
                                                  message    => $msg,
                                                 }
                                                )->insert;
        }
        return 0;
}



sub status
{
        my ($self, $id) = @_;
        my $result;
        my $testrun = $self->schema->resultset('Testrun')->find($id);
        die "No testrun with id '$id'\n" if not $testrun;

        $result->{status}       .= $testrun->testrun_scheduling->status; # the dot (.=) stringifies the enum object that the status actually contains
        $result->{success_ratio} = undef;

        my $reportgroup = $self->schema->resultset('ReportgroupTestrun')->search({testrun_id => $id});
        if ($reportgroup->count > 0) {
                $result->{reports} = [];
                foreach my $group_element ($reportgroup->all) {
                        push @{$result->{reports}}, $group_element->report_id;
                        $result->{primaryreport} = $group_element->report_id if $group_element->primaryreport;
                }
        }

        if ($result->{status} eq 'finished') {
                my $stats = $self->schema->resultset('ReportgroupTestrunStats')->search({testrun_id => $id})->first;
                return $result if not defined($stats);

                $result->{success_ratio} = $stats->success_ratio;
                if ($stats->success_ratio < 100) {
                        $result->{status} = 'fail';
                } else {
                        $result->{status} = 'pass';
                }
        }
        return $result;
}



1; # End of Tapper::Cmd::Testrun

__END__

=pod

=encoding UTF-8

=head1 NAME

Tapper::Cmd::Testrun

=head1 SYNOPSIS

This project offers backend functions for all projects that manipulate
testruns or preconditions in the database. This module handles the testrun part.

    use Tapper::Cmd::Testrun;

    my $bar = Tapper::Cmd::Testrun->new();
    $bar->add($testrun);
    ...

=head1 NAME

Tapper::Cmd::Testrun - Backend functions for manipluation of testruns in the database

=head1 FUNCTIONS

=head2 find_matching_hosts

=head2 create

Create new testruns from a data structure that contains all information
including requested hosts and features. If the new testruns belong to a
test plan instance the function expects the id of this instance as
second parameter.

@param hash ref - testrun description OR
       string   - YAML
@optparam instance - test plan instance id

@return array   - testrun ids

@throws die()

=head2 add

Add a new testrun. Owner/owner_id and requested_hosts/requested_host_ids
allow to specify the associated value as id or string which will be converted
to the associated id. If both values are given the id is used and the string
is ignored. The function expects a hash reference with the following options:
-- optional --
* requested_host_ids - array of int
or
* requested_hosts    - array of string

* notes - string
* shortname - string
* topic - string
* date - DateTime
* instance - int

* owner_id - int
or
* owner - string

@param hash ref - options for new testrun

@return success - testrun id)
@return error   - exception

@throws exception without class

=head2 update

Changes values of an existing testrun. The function expects a hash reference with
the following options (at least one should be given):

* hostname  - string
* notes     - string
* shortname - string
* topic     - string
* date      - DateTime
* owner_id - int
or
* owner     - string

@param int      - testrun id
@param hash ref - options for new testrun

@return success - testrun id
@return error   - undef

=head2 del

Delete a testrun with given id. Its named del instead of delete to
prevent confusion with the buildin delete function.

@param int - testrun id

@return success - 0
@return error   - error string

=head2 rerun

Insert a new testrun into the database. All values not given are taken from
the existing testrun given as first argument.

@param int      - id of original testrun
@param hash ref - different values for new testrun

@return success - testrun id
@return error   - exception

@throws exception without class

=head2 pause

Pause an existing testrun by setting its state to 'prepare'.

@param int      - id of original testrun

@return success - testrun id
@return error   - exception

@throws exception without class

=head2 continue

Continue a paused testrun (status 'prepare') by setting its state back
to 'schedule'.

@param int      - id of original testrun

@return success - testrun id
@return error   - exception

@throws exception without class

=head2 cancel

Stop a running testrun by sending the appropriate message to MCP. As
convenience to the user the function will also work on testruns that are
not running. In that case the return value contains a warning that the
caller should present to the user.

@param int - testrun id
@optparam string - comment

@return success - success string
@return error   - error string

@throws die()

=head2 status

Get information of one testrun.

@param int - testrun id

@return - hash ref -
* status - one of 'prepare', 'schedule', 'running', 'pass', 'fail'
* success_ratio - percentage of success

@throws - die

=head1 AUTHOR

AMD OSRC Tapper Team, C<< <tapper at amd64.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2012 AMD OSRC Tapper Team, all rights reserved.

This program is released under the following license: freebsd

=head1 AUTHORS

=over 4

=item *

AMD OSRC Tapper Team <tapper@amd64.org>

=item *

Tapper Team <tapper-ops@amazon.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Advanced Micro Devices, Inc..

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut
