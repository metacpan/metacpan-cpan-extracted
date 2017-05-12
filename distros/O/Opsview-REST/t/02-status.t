
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";
use Opsview::REST::TestUtils;

use Test::More tests => 6;
use Test::Exception;

use Data::Dumper;

BEGIN { use_ok 'Opsview::REST::Status'; };

my @tests = (
    {
        args => [],
        die  => 'No arguments die',
    },
    {
        args => ['hostgroup', hostgroupid => 1],
        url  => '/status/hostgroup?hostgroupid=1',
    },
    {
        args => ['hostgroup', hostgroupid => [1, 2]],
        url  => '/status/hostgroup?hostgroupid=1&hostgroupid=2',
    },
    {
        args => ['host', host => 'opsview', state => [0, 1, 2]],
        url  => '/status/host?state=0&state=1&state=2&host=opsview',
    },
    {
        args => ['host', filter => 'handled', state_type => 'hard', host_state => [1, 2]],
        url  => '/status/host?host_state=1&host_state=2&filter=handled&state_type=hard',
    },
);

test_urls('Opsview::REST::Status', @tests);

