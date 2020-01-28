use Mojo::Base -strict;
use Test::More;
use Mojo::DB::Connector;

plan skip_all => q{TEST_MYSQL=mysql://root@/test}
    unless $ENV{TEST_MYSQL};

$ENV{MOJO_DB_CONNECTOR_URL} = $ENV{TEST_MYSQL};
my $connector = Mojo::DB::Connector->new;

$connector->strict_mode(1);
my $connection = $connector->new_connection;
ok $connection->{strict_mode}, 'strict mode set';

$connector->strict_mode(0);
$connection = $connector->new_connection;
ok !$connection->{strict_mode}, 'strict mode not set';

note 'Test override';
$connector->strict_mode(0);
$connection = $connector->new_connection(strict_mode => 1);
ok $connection->{strict_mode}, 'strict mode overridden';

$connector->strict_mode(1);
$connection = $connector->new_connection(strict_mode => 0);
ok !$connection->{strict_mode}, 'strict mode overridden';

done_testing;
