
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";
use Opsview::REST::TestUtils;

use Test::More tests => 4;

SKIP: {
    skip 'No $ENV{OPSVIEW_REST_TEST} defined', 4
        if (not defined $ENV{OPSVIEW_REST_TEST});

    my $ops = get_opsview();

    my $info = $ops->reload_info();
    is($info->{server_status}, 0, 'Server running');
    is($info->{configuration_status}, 'uptodate', 'Conf. up to date');

    $info = $ops->reload();
    is($info->{server_status}, 0, 'Server reloaded');
    is($info->{configuration_status}, 'uptodate', 'Conf. up to date');
};

