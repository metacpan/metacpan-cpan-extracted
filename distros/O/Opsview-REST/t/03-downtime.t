
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";
use Opsview::REST::TestUtils;

use Test::More tests => 10;

BEGIN { use_ok 'Opsview::REST::Downtime'; }

my @tests = (
    {
        args => [],
        url  => '/downtime',
    },
    {
        args => [ page => 3, rows => 5 ],
        url  => '/downtime?page=3&rows=5',
    },
    {
        args => [
            starttime => '2012-01-08 12:49:13',
            duration  => '+2h',
            comment   => 'comment'
        ],
        url  => '/downtime?comment=comment&starttime=2012-01-08+12%3A49%3A13&duration=%2B2h',
    },
);

test_urls('Opsview::REST::Downtime', @tests);

SKIP: {
    skip 'No $ENV{OPSVIEW_REST_TEST} defined', 6
        if (not defined $ENV{OPSVIEW_REST_TEST});

    require DateTime;
    my $dt    = DateTime->now->add(hours => 1);
    my $start = $dt->ymd('-') . ' ' . $dt->hms(':');

    my $ops = get_opsview();

    # Create the downtime
    my $r = $ops->create_downtime(
        'starttime'     => $start,
        'endtime'       => '+2h',
        'comment'       => 'comment',
        'hst.hostname'  => 'opsview',
    );

    is($r->{summary}->{num_hosts}, 1, 'Submitted for one host');
    my @hostnames = map { $_->{hostname} } @{ $r->{list}->{hosts} };
    is($hostnames[0], 'opsview', 'Host is opsview itself');

    # Since downtimes are submitted asynchronously,
    # wait a little for it to take effect
    sleep 10;

    $r = '';
    $r = $ops->downtimes();
    is($r->{summary}->{num_hosts}, 1, 'Listed one host');
    @hostnames = map { $_->{hostname} } @{ $r->{list}->[0]->{objects}->{hosts} };
    is($hostnames[0], 'opsview', 'Host is opsview itself');

    # Wait a little bit more...
    sleep 10;

    # Delete the downtime
    $r = '';
    $r = $ops->delete_downtime('hst.hostname' => 'opsview');
    is($r->{summary}->{num_hosts}, 1, 'Deleted for one host');
    @hostnames = map { $_->{hostname} } @{ $r->{list}->{hosts} };
    is($hostnames[0], 'opsview', 'Host is opsview itself');
};

