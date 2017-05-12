
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";
use Opsview::REST::TestUtils;

use Test::More;
use Test::Exception;

use Data::Dumper;

BEGIN { use_ok 'Opsview::REST::Config'; };

my @tests = (
    {
        args => [],
        die  => 'No arguments die',
    },
    {
        args => ['hostgroup', 1],
        path  => '/config/hostgroup/1',
    },
    {
        args => ['contact', 5],
        path  => '/config/contact/5',
    },
    {
        args => ['contact', 'xx'],
        die  => 'id must be numeric',
    },
    {
        args => ['xxxx', 'xx'],
        die  => 'object type must be accepted',
    },
);

test_urls('Opsview::REST::Config', @tests);

SKIP: {
    skip 'No $ENV{OPSVIEW_REST_TEST} defined', 7
        if (not defined $ENV{OPSVIEW_REST_TEST});

    my $ops  = get_opsview();
    my $name = get_random_name();
    my $ip   = get_random_ip();

    my $res = $ops->create_host(
        ip                      => $ip,
        name                    => $name,
        hostgroup               => { name => 'Monitoring Servers' },
        notification_interval   => 16,
        notification_period     => { name => '24x7' },
    );

    is($res->{object}->{name}, $name, 'Host created');

    my $id = $res->{object}->{id};
    $res = $ops->get_host($id);
    is($res->{object}->{name}, $name, 'Host can be retrieved');

    my $notif_int = 27;
    $res = $ops->update_host(
        $id,
        notification_interval => $notif_int,
    );
    is($res->{object}->{notification_interval}, $notif_int, 'Host can be updated');

    my $ip2   = get_random_ip();
    my $name2 = get_random_name();
    $res = $ops->clone_host(
        $id,
        ip   => $ip2,
        name => $name2,
    );
    is($res->{object}->{ip},   $ip2,   'Host can be cloned');
    is($res->{object}->{name}, $name2, 'Name is correct for cloned host');
    is($res->{object}->{notification_interval}, $notif_int, 'Params merged properly');
    
    $res = $ops->delete_host($id);
    ok($res->{success}, 'Host can be deleted');

}

done_testing;
