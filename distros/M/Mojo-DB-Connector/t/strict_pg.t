use Mojo::Base -strict;
use Test::More;
use Test::Exception;
use Mojo::DB::Connector;

plan skip_all => q{TEST_POSTGRESQL=postgresql://root@/test}
    unless $ENV{TEST_POSTGRESQL};

$ENV{MOJO_DB_CONNECTOR_URL} = $ENV{TEST_POSTGRESQL};
my $connector = Mojo::DB::Connector->new;

lives_and { ok $connector->strict_mode(1)->new_connection } 'strict pg lives';
lives_and { ok $connector->strict_mode(0)->new_connection } 'non-strict pg lives';

done_testing;