use Test::More;

use Net::ZooTool;

BEGIN { use_ok( Config::General, qw/ParseConfig/ ); }

my $config_file = 'auth.conf';

SKIP:
{
    skip("I cannot run tests without $config_file", 1) unless -f $config_file;

    my %config = ParseConfig($config_file);

    my $zoo = Net::ZooTool->new(
        {
            apikey   => $config{apikey},
            user     => $config{user},
            password => $config{password},
        }
    );

    my $items = $zoo->user->items({
        'username' => 'smashingmag',
        'limit' => 5,
        'offset' => 1
    });

    is(scalar @$items, 5, 'Found 5 items');
}

done_testing();
