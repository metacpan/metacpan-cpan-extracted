package Net::Hadoop::Oozie::SLA::Summary;
$Net::Hadoop::Oozie::SLA::Summary::VERSION = '0.115';
use 5.010;
use warnings;
use strict;

use Moo;

use Date::Parse 'str2time';
use Data::Dumper;
use Net::Hadoop::Oozie;
use CHI;
use Scalar::Util 'reftype';

my $CACHE_TTL = 300;

extends 'Net::Hadoop::Oozie::SLA';

has use_cache => (
    is      => 'rw',
    isa     => sub { die "use_cache should be 1/0" if $_[0] != 0 && $_[0] != 1 },
    default => sub { 0 },
    lazy    => 1,
);

has _cache => (
    is      => 'rw',
    isa     => sub { return if !$_[0]; die "not a cache object" if ref $_[0] !~ /^CHI/ },
    default => sub {
        my $self = shift;
        return $self->use_cache
            ? CHI->new(
                driver   => 'File',
                root_dir => $self->cache_root_dir,
            )
            : undef;
    },
    lazy => 1,
);

has cache_root_dir => (
    is      => 'rw',
    default => sub { '/tmp/oozie-sla-cache' },
    lazy    => 1,
);

has cache_id => (
    is => 'rw',
    default => sub { 'hadoopX' },
    lazy => 1,
);

has oozie_class => (
    is      => 'rw',
    default => sub { 'Net::Hadoop::Oozie' },
);

# filter by name: Net::Hadoop::Oozie::SLA->new->sla_miss_list(name => '^mysql.*')
# 
sub sla_miss_list {
    my $self = shift;
    my %options = (@_ == 1 && reftype $_[0] eq 'HASH') ? %{$_[0]} : @_;

    my $name_regex = $options{name};
    if ($name_regex) {
        eval {qr/$options{name}/} or die '"name" option doesn\'t contain a valid regex';
    }
    my $frozen_time = time;
    my @time_ranges = (
        [ $frozen_time - 86400,  $frozen_time,          'Last 24 hours' ],
        [ $frozen_time - 259200, $frozen_time - 86400,  '2 previous days' ],
        [ $frozen_time - 604800, $frozen_time - 259200, '4 more days' ],
    );
    $self->start( $frozen_time - 604800 );
    $self->end( $frozen_time );
    #$self->sla_status('MISS');

    my $coords = $self->oozie_class->new->jobs(
        jobtype => "coordinators",
        len     => 10_000,
        filter  => { status => [ "RUNNING", "SUSPENDED" ] }
    );
    $coords = [ map { $_->{coordJobName} } @{ $coords->{coordinatorjobs} || [] } ];

    # loop around the names, retrieving a series of SLA events for each
    # TODO cache or make parallel
    my ( @all_sla, $cache_hits, $cache_misses );
    my $start_fetch = time;
    for my $app_name ( @{ $coords || [] } ) {
        next if ($name_regex && $app_name !~ /$name_regex/);
        my ( @sla, $from_cache, $cache_key );
        if ( $self->use_cache ) {
            $cache_key = $self->cache_id . '#' . $app_name;
            my $sla = $self->_cache->get($cache_key);
            $from_cache = 1 if defined $sla;
            $cache_hits++   if $from_cache;
            $cache_misses++ if !$from_cache;
            @sla = @{ $sla || [] };
        }
        if ( !@sla ) {
            $self->appname($app_name);
            @sla = $self->sla();
        }
        #print Dumper \@sla;

        # cache even empty results
        if ( !$from_cache && $self->use_cache ) {
            $self->_cache->set( $cache_key, \@sla, $CACHE_TTL + int( rand(120) ) . " seconds" );
        }
        next if !@sla;
        push @all_sla, grep { $_->{slaMisses} } @sla;
    }
    $cache_hits   //= 0;
    $cache_misses //= 0;
    #warn "cache hits: $cache_hits misses: $cache_misses time: "
    #    . ( time - $start_fetch ) . " sec";
    #print Dumper @all_sla;

    @all_sla = sort { $b->{lastModifiedEpoch} <=> $a->{lastModifiedEpoch}} @all_sla;

    # check the actual job status and add it to the structure
    # my $oozie = Net::Hadoop::Oozie->new()

    # group the SLA events by time period (2 hours, 1 day, 1 week) ,
    # coordinator, and action ID (as a same action can have different workflow
    # IDs when it's launched several times; better see that by having 2 or more
    # rows grouped under 1 ID)
    my $grouped_sla;
    for my $time_range (@time_ranges) {
        my ($after, $before) = @$time_range;
        my (%alerts, $latest);
        for my $alert (@all_sla) {

            next if !$alert->{parentId}; # for now, ignore those that are not run from a coordinator

            # Not sure the lastModified field is a good indication of when
            # the SLA event happened, but that's all we have in the JSON;
            # let's try using that
            if (!( $alert->{lastModifiedEpoch} >= $after
                && $alert->{lastModifiedEpoch} < $before )) {
                next;
            }

            # they're already sorted, simply push them; since this will be used
            # by React, we really want arrays, not hashes (you can't easily
            # iterate on hash keys as you can here, since all hashes are
            # objects in JS, which add plenty of keys from the prototype);
            # we'll transform this multi-level hash in a series of nested
            # arrays later on
            push @{$alerts{$alert->{coordId}}{$alert->{parentId}}}, $alert;

            $latest->{coord}{ $alert->{coordId} } = $alert->{lastModifiedEpoch}
                if !$latest->{coord}{ $alert->{coordId} }
                || $latest->{coord}{ $alert->{coordId} } < $alert->{lastModifiedEpoch};
            $latest->{action}{ $alert->{parentId} } = $alert->{lastModifiedEpoch}
                if !$latest->{action}{ $alert->{parentId} }
                || $latest->{action}{ $alert->{parentId} } < $alert->{lastModifiedEpoch};
        }

        my @sorted_coord_ids
            = sort { $latest->{coord}{$b} <=> $latest->{coord}{$a} } keys %{ $latest->{coord} };
        my @sorted_action_ids = sort { $latest->{action}{$b} <=> $latest->{action}{$a} }
            keys %{ $latest->{action} };

        my $grouped_sla_part = {
            time_range => $time_range,
            coords     => [
                map {    # iterate coords
                    my $coord_id = $_;
                    {   id      => $coord_id,
                        actions => [
                            map {    # iterate actions
                                my $action_id = $_;
                                {   id     => $action_id,
                                    alerts => [ @{ $alerts{$coord_id}{$action_id} } ]
                                }    # populate alerts
                            } grep { $_ =~ /^$coord_id/ } @sorted_action_ids
                        ]
                    }
                } @sorted_coord_ids
            ]
        };

        push @$grouped_sla, $grouped_sla_part;
    }

    return $grouped_sla;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Net::Hadoop::Oozie::Constants - Oozie SLA Summary

=head1 VERSION

version 0.115

=head1 DESCRIPTION

Part of the Perl Oozie interface.

=head1 SYNOPSIS

    use Net::Hadoop::Oozie::SLA::Summary;
    # TODO

=head1 METHODS

=head2 sla_miss_list

TODO.

=head1 SEE ALSO

L<Net::Hadoop::Oozie>, L<Net::Hadoop::Oozie::SLA>.

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
