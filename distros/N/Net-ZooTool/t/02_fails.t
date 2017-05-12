use Test::More;
use Test::Exception;

use Net::ZooTool;

BEGIN { use_ok( Config::General, qw/ParseConfig/ ); }

dies_ok { Net::ZooTool->new() } 'dies without apikey';
dies_ok { Net::ZooTool->new({}) } 'dies without apikey';

my $config_file = 'auth.conf';

SKIP:
{
    skip("I cannot run tests without $config_file", 7) unless -f $config_file;

    my %config = ParseConfig($config_file);

    my $zoo = Net::ZooTool->new(
        {
            apikey   => $config{apikey},
        }
    );

    dies_ok { Net::ZooTool->new($config{apikey}, $config{user}) } 'dies with uncomplete params';
    dies_ok { Net::ZooTool->new( { apikey => $config{apikey}, user => $config{user} } ) } 'dies with uncomplete params';

    lives_ok { Net::ZooTool->new($config{apikey}) } 'lives with apikey';
    lives_ok { Net::ZooTool->new( { apikey => $config{apikey} } ) } 'lives with apikey';

    lives_ok { Net::ZooTool->new($config{apikey}, $config{user}, $config{password}) } 'lives with everything';
    lives_ok { Net::ZooTool->new( { apikey => $config{apikey}, user => $config{user}, password => $config{password} } ) } 'lives with everything';


    dies_ok { $zoo->user->validate({ 'login' => 'true', 'username' => $config{user} }) } 'Dies without login param';
}

done_testing();
