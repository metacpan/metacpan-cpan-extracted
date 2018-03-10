package Net::Hadoop::Oozie::SLA;
$Net::Hadoop::Oozie::SLA::VERSION = '0.113';
use 5.010;
use strict;
use warnings;

use Moo;

use Carp qw( confess );
use Date::Format;
use Date::Parse;
use Data::Dumper;

with 'Net::Hadoop::Oozie::Role::Common';

# appname is mandatory

has 'appname' => (
    is  => 'rw',
    isa => sub {
        confess "no valid appname provided"
            if !length $_[0] || $_[0] !~ m{ ^ [0-9a-z_/-]+ $ }xi
    },
    default => sub { undef },
    lazy    => 1,
);

# start and end are boundaries for search by nominal time; defaults are -24h and now
# they can be specified using unix timestamps or any date format Date::Parse accepts

has 'start' => (
    is     => 'rw',
    isa    => sub { confess "no valid start time or date provided" if !$_[0] },
    coerce => sub {
        if ( $_[0] =~ /^1[0-9]{9}$/ ) {    # unix timestamp
            return time2str( '%Y-%m-%dT%H:%MZ', $_[0], 'UTC' );
        }
        elsif ( my $time = str2time( $_[0] ) ) {    # date/time
            return time2str( '%Y-%m-%dT%H:%MZ', $time, 'UTC' );
        }
        return;
    },
    default => sub { time - 3600 * 24 },
    lazy    => 1,
);

# TODO Would be nice to add a check for end time later than start time; was
# thinking of doing it in isa() but the object isn't passed as an argument;
# builder() or default()?

has 'end' => (
    is     => 'rw',
    isa    => sub { confess "no valid end time or date provided" if !$_[0] },
    coerce => sub {
        if ( $_[0] =~ /^1[0-9]{9}$/ ) {    # unix timestamp
            return time2str( '%Y-%m-%dT%H:%MZ', $_[0], 'UTC' );
        }
        elsif ( my $time = str2time( $_[0] ) ) {    # date/time
            return time2str( '%Y-%m-%dT%H:%MZ', $time, 'UTC' );
        }
        return;
    },
    default => sub { 0 + time },
    lazy    => 1,
);

# regex for filtering by status (only retrieve the task in slaStatus matching the regex)
#
has 'sla_status' => (
    is      => 'rw',
    isa     => sub {1},
    coerce  => sub { return qr/$_[0]/ },
    default => '.*',
    lazy    => 1,
);

# regex for excluding by status (only retrieve the tasks in slaStatus that don't match the regex)
#
has 'sla_status_ignore' => (
    is      => 'rw',
    isa     => sub {1},
    coerce  => sub { return qr/$_[0]/ },
    default => 'some silly value',
    lazy    => 1,
);

# maximum number of items returned; this is applied *before* filtering by status
# NOTE the len parameter is undocumented in the oozie API, support may be removed
has 'limit' => (
    is      => 'rw',
    isa     => sub { confess "no valid limit provided" if $_[0] !~ /^[1-9][0-9]*$/ },
    default => 10_000,
    lazy    => 1,
);

sub sla {
    my $self   = shift;

    my $filter = {
        app_name      => $self->appname,
        nominal_start => $self->start,
        nominal_end   => $self->end,
    };

    my $uri = URI->new( $self->oozie_uri );
    $uri->query_form(
        len      => $self->limit,
        timezone => 'GMT',
        filter   => join ';',
        map {"$_=$filter->{$_}"} keys %$filter
    );

    $uri->path( sprintf "%s/%s", $uri->path, '/v2/sla' );

    my $res = $self->agent_request($uri);
    return if !$res->{slaSummaryList};

    my @res = @{ $res->{slaSummaryList} };

    # add meta info to the individual alerts and process the misses; these are
    # not individual SLA events, but a summary, so a job that had a duration
    # miss will still be in status MET when its end time is ok; the
    # documentation says there should be an eventStatus key, but it is likely
    # only present in the coordinator SLA, at least it is not there to be found
    # in the data that we extract
    for my $sla_row (@res) {
        for my $key (qw( lastModified expectedStart actualStart expectedEnd actualEnd)) {
            if ($sla_row->{$key}) {
                $sla_row->{$key . "Epoch"} = str2time $sla_row->{$key};
            }
        }

        # both of these can be undef (if not set by config) or -1 (if still
        # running); they're in ms too, so convert them
        $sla_row->{expectedDuration} = int($sla_row->{expectedDuration} / 1000)
            if (($sla_row->{expectedDuration} || 0) > 0);

        $sla_row->{actualDuration}   = int($sla_row->{actualDuration} / 1000)
            if (($sla_row->{actualDuration} || 0) > 0);

        if (($sla_row->{parentId} || '') =~ /\@[0-9]+$/) {
            ($sla_row->{coordId} = $sla_row->{parentId}) =~ s/\@.*//;
        }

        for (qw(Start End)) {
            if ($sla_row->{ 'expected' . $_ }
                && ( my $missed_by
                    = ( $sla_row->{ 'actual' . $_ . 'Epoch' }   || 0 )
                    - ( $sla_row->{ 'expected' . $_ . 'Epoch' } || 0 ) ) > 0
                )
            {
                push @{$sla_row->{slaMisses}}, [ uc $_ . "_MISS", $missed_by ];
            }
        }

        # actual duration is -1 when running, so we won't get a duration_miss
        # until the job is done; we need to figure it out sooner, by checking
        # the actual start and adding the expected duration
        if ( ( $sla_row->{expectedDuration} || 0 ) < ( $sla_row->{actualDuration} || 0 ) ) {
            push @{ $sla_row->{slaMisses} },
                [ 'DURATION_MISS', $sla_row->{actualDuration} - $sla_row->{expectedDuration} ];
        }
        elsif (
               ($sla_row->{expectedDuration} || 0) > 0
            && $sla_row->{actualDuration} == -1
            && $sla_row->{actualStartEpoch}
            && ( my $missed_by
                  = $sla_row->{lastModifiedEpoch}
                - $sla_row->{actualStartEpoch}
                - $sla_row->{expectedDuration} ) > 0
            )
        {
            push @{ $sla_row->{slaMisses} }, [ 'DURATION_MISS', $missed_by ];
        }

    }

    @res = grep { $_->{slaStatus} =~ $self->sla_status } @res;
    @res = grep { $_->{slaStatus} !~ $self->sla_status_ignore } @res;

    # splice @res, $self->limit;
    return @res;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Net::Hadoop::Oozie::Constants - Oozie SLA

=head1 VERSION

version 0.113

=head1 DESCRIPTION

Part of the Perl Oozie interface.

=head1 SYNOPSIS

    use Net::Hadoop::Oozie::SLA;
    # TODO

=head1 METHODS

=head2 sla

TODO.

=head1 SEE ALSO

L<Net::Hadoop::Oozie>.

=cut


sample SLA record:

{   'lastModifiedEpoch'  => 1442201595,
    'slaMisses'          => [ [ 'DURATION_MISS', 3772 ] ],
    'expectedStart'      => 'Sun, 13 Sep 2015 23:30:00 GMT',
    'actualEndEpoch'     => 1442201575,
    'expectedEndEpoch'   => 1442226600,
    'nominalTime'        => 'Sun, 13 Sep 2015 22:30:00 GMT',
    'actualStartEpoch'   => 1442183402,
    'appType'            => 'WORKFLOW_JOB',
    'user'               => 'mapred',
    'jobStatus'          => 'SUCCEEDED',
    'expectedStartEpoch' => 1442187000,
    'parentId'           => '0003236-150307132348543-oozie-oozi-C@192',
    'expectedEnd'        => 'Mon, 14 Sep 2015 10:30:00 GMT',
    'actualDuration'     => 18172,
    'lastModified'       => 'Mon, 14 Sep 2015 03:33:15 GMT',
    'actualStart'        => 'Sun, 13 Sep 2015 22:30:02 GMT',
    'appName'            => 'my-oozie-app',
    'id'                 => '0470604-150812124729073-oozie-oozi-W',
    'expectedDuration'   => 14400,
    'actualEnd'          => 'Mon, 14 Sep 2015 03:32:55 GMT',
    'coordId'            => '0003236-150307132348543-oozie-oozi-C',
    'slaStatus'          => 'MET'
}
