package Net::Hadoop::YARN::ApplicationMaster;
$Net::Hadoop::YARN::ApplicationMaster::VERSION = '0.203';
use strict;
use warnings;
use 5.10.0;

use constant {
    RE_ARCHIVED_ERROR => qr{
        Application .+?
        \Qcould not be found, please try the history server\E
    }xms,
};

use Constant::FromGlobal DEBUG => { int => 1, default => 0, env => 1 };

use Carp         ();
use Clone        ();
use HTML::PullParser;
use Moo;
use Ref::Util    ();
use Scalar::Util ();

use Net::Hadoop::YARN::HistoryServer;

with 'Net::Hadoop::YARN::Roles::AppMasterHistoryServer';
with 'Net::Hadoop::YARN::Roles::Common';

has '+servers' => (
    default => sub {["localhost:8088"]},
);

has history_object => (
    is  => 'rw',
    isa => sub {
        my $o = shift || return; # this is optional
        if (   ! Scalar::Util::blessed $o
            || ! $o->isa('Net::Hadoop::YARN::HistoryServer')
        ) {
            Carp::confess "$o is not a Net::Hadoop::YARN::HistoryServer";
        }
    },
    lazy    => 1,
    default => sub { },
);

my $PREFIX = '_' x 4;

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

_mk_subs($methods_urls, { prefix => $PREFIX } );

my %app_to_hist = (
    jobs => [ job => qr{ \A job_[0-9]+ }xms ],
);

foreach my $name ( keys %{ $methods_urls } ) {
    my $base = $PREFIX . $name;
    no strict qw( refs );
    *{ $name } = sub {
        my $self = shift;
        my $args = Clone::clone( \@_ );
        my @rv;

        eval {
            @rv = $self->$base( @_ );
            1;
        } or do {
            my $eval_error = $@ || 'Zombie error';
            if ( $eval_error =~ RE_ARCHIVED_ERROR && $self->history_object ) {
                @rv = $self->_collect_from_history(
                            $args,
                            $name,
                            $eval_error,
                        );
            }
            else {
                Carp::confess $eval_error;
            }
        };

        return wantarray ? @rv : $rv[0];
    };
}

sub _collect_from_history {
    my $self  = shift;
    my $args  = shift;
    my $name  = shift;
    my $error = shift || Carp::confess "No error message specified!";

    my $hist_method = $app_to_hist{ $name } || [ $name ];
    my($hmethod, $hregex) = @{ $hist_method };

    if ( DEBUG ) {
        print STDERR "Received HTML from the API. ",
                      "I will now attempt to collect the information from the history server\n";
        printf STDERR "The error was: %s\n", $error
            if DEBUG > 1;
    }

    my @hist_param;
    if ( $error =~ RE_ARCHIVED_ERROR && ( $name eq 'jobs' || $name eq 'job' ) ) {
        print STDERR "Job was archived\n" if DEBUG;
        @hist_param = (
            map {
                (my $c = $_) =~ s{ \bapplication_ }{job_}xms;
                $c;
            } @{ $args }
        );
    }
    else {
        print STDERR "Job was not available from he RM\n" if DEBUG;
        @hist_param = (
            $hregex
                ? grep { $_ =~ $hregex }
                    $self->_extract_ids_from_error_html( $error )
                : ()
        );
    }

    my @rv;
    eval {
        @rv = $self->history_object->$hmethod( @hist_param );
        1;
    } or do {
        my $eval_error_hist = $@ || 'Zombie error';
        Carp::confess "Received HTML from the API and attempting to map that to a historical job failed: $error\n$eval_error_hist\n";
    };

    foreach my $thing ( @rv ) {
        next if ! Ref::Util::is_hashref $thing;
        $thing->{__from_history} = 1;
    }

    return @rv;
}

sub _extract_ids_from_error_html {
    my $self  = shift;
    my $error = shift || Carp::confess "No error message specified!";
    my(undef, $html) = split m{\Q<!DOCTYPE\E}xms, $error, 2;
    $html = '<!DOCTYPE' . $html;
    my $parser = HTML::PullParser->new(
                    doc         => \$html,
                    start       => 'event, tagname, @attr',
                    report_tags => [qw( a )],
                ) || Carp::confess "Can't parse HTML received from the API: $!";
    my %link;
    while ( my $token = $parser->get_token ) {
        next if $token->[0] ne 'start';
        my($type, $tag, %attr) = @{ $token };
        my $link = $attr{href} || next;
        $link{ $link }++;
    }
    my %id;
    for my $link ( keys %link ) {
        $id{ $_ }++ for $self->_extract_valid_params( $link );
    }
    return keys %id;
}

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

version 0.203

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

=head2 job

=head2 jobattempts

=head2 jobconf

=head2 jobcounters

=head2 jobs

=head2 task

=head2 taskattempt

=head2 taskattemptcounters

=head2 taskattempts

=head2 taskcounters

=head1 AUTHOR

David Morel <david.morel@amakuru.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by David Morel & Booking.com.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
