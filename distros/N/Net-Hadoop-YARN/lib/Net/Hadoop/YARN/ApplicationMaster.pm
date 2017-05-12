package Net::Hadoop::YARN::ApplicationMaster;
$Net::Hadoop::YARN::ApplicationMaster::VERSION = '0.202';
use strict;
use warnings;
use 5.10.0;
use Moo;

with 'Net::Hadoop::YARN::Roles::AppMasterHistoryServer';
with 'Net::Hadoop::YARN::Roles::Common';


#<<<
my $methods_urls = {
    jobs                => ['/proxy/{appid}/ws/v1/mapreduce/jobs',                                                      'job'                     ],
    job                 => ['/proxy/{appid}/ws/v1/mapreduce/jobs/{jobid}',                                              ''                        ],
    jobconf             => ['/proxy/{appid}/ws/v1/mapreduce/jobs/{jobid}/conf',                                         ''                        ],
    jobcounters         => ['/proxy/{appid}/ws/v1/mapreduce/jobs/{jobid}/counters',                                     'counterGroup'            ],
    jobattempts         => ['/proxy/{appid}/ws/v1/mapreduce/jobs/{jobid}/jobattempts',                                  'jobAttempt'              ],
    _get_tasks          => ['/proxy/{appid}/ws/v1/mapreduce/jobs/{jobid}/tasks',                                        'task'                    ],
    task                => ['/proxy/{appid}/ws/v1/mapreduce/jobs/{jobid}/tasks/{taskid}',                               ''                        ],
    taskcounters        => ['/proxy/{appid}/ws/v1/mapreduce/jobs/{jobid}/tasks/{taskid}/counters',                      'taskCounterGroup'        ],
    taskattempts        => ['/proxy/{appid}/ws/v1/mapreduce/jobs/{jobid}/tasks/{taskid}/attempts',                      'taskAttempt'             ],
    taskattempt         => ['/proxy/{appid}/ws/v1/mapreduce/jobs/{jobid}/tasks/{taskid}/attempts/{attemptid}',          ''                        ],
    taskattemptcounters => ['/proxy/{appid}/ws/v1/mapreduce/jobs/{jobid}/tasks/{taskid}/attempts/{attemptid}/counters', 'taskAttemptCounterGroup' ],
};
#>>>

# For each of the keys, at startup:
# - make a method, adding the path
# - pass the path and variables to a validation and substitution engine
# - execute the request
# - return the proper fragment of the JSON tree

_mk_subs($methods_urls);

has '+servers' => (
    default => sub {["localhost:8088"]},
);


sub info {
    my $self = shift;
    $self->mapreduce(@_);
}

sub mapreduce {
    my $self   = shift;
    my $app_id = shift;
    my $res    = $self->_get("{appid}/ws/v1/mapreduce/info");
    return $res->{info};
}


sub tasks {
    my $self = shift;
    $self->_get_tasks(@_);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Hadoop::YARN::ApplicationMaster

=head1 VERSION

version 0.202

=head1 NAME

Net::Hadoop::YARN::ApplicationMaster

Implementation of the REST API described in
L<http://hadoop.apache.org/docs/r2.5.1/hadoop-mapreduce-client/hadoop-mapreduce-client-core/MapredAppMasterRest.html>

=head1 METHODS

Most of the methods are described in
L<Net::Hadoop::YARN::Roles::AppMasterHistoryServer> as both the Application Master
and History Server implement them. Please refer to the role for a full list and
arguments.

=head2 mapreduce

=head2 info

Mapreduce Application Master Info API

http://<proxy http address:port>/proxy/{appid}/ws/v1/mapreduce/info

=head2 tasks

Tasks API

Takes application ID as a first argument, plus an optional options hashref:

=over 4

=item type

type of task, valid values are m or r.  m for map task or r for reduce task.

=back

=head1 AUTHOR

David Morel <david.morel@amakuru.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by David Morel & Booking.com.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
