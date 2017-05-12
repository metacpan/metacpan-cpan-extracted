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
        }
    );

    isa_ok($zoo, 'Net::ZooTool', "Net::ZooTool created");
    isa_ok($zoo->auth, 'Net::ZooTool::Auth', 'Valid field');
}

done_testing();
