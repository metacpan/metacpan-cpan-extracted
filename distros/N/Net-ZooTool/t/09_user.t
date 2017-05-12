use Test::More;

use Net::ZooTool;

BEGIN { use_ok( Config::General, qw/ParseConfig/ ); }

my $config_file = 'auth.conf';

SKIP:
{
    skip("I cannot run tests without $config_file", 2) unless -f $config_file;

    my %config = ParseConfig($config_file);

    my $zoo = Net::ZooTool->new(
        {
            apikey   => $config{apikey},
            user     => $config{user},
            password => $config{password},
        }
    );

    my $user_info = $zoo->user->info({
        'username' => 'smashingmag',
    });

    my $validate = $zoo->user->validate({
        'username' => $config{user},
        'login' => 'true',
    });

    is($user_info->{tinyurl}, 'http://zoo.tl/u/smashingmag', "Tinyurl matches");
    is($validate->{username}, $config{user}, "User is validated");
}

done_testing();
