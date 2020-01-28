use Mojo::Base -strict;
use Test::More;
use Mojo::DB::Connector;
use Mojo::URL;
use Mojo::Util 'sha1_sum';

plan skip_all => q{TEST_MYSQL=mysql://root@/test or TEST_POSTGRESQL=postgresql://root@/test}
    unless $ENV{TEST_MYSQL} or $ENV{TEST_POSTGRESQL};

test_cache($ENV{TEST_MYSQL}) if $ENV{TEST_MYSQL};
test_cache($ENV{TEST_POSTGRESQL}) if $ENV{TEST_POSTGRESQL};

done_testing;

sub test_cache {
    my $connection_string = shift;

    $ENV{MOJO_DB_CONNECTOR_URL} = $connection_string;
    my $connector = Mojo::DB::Connector->new;

    my $new_one = $connector->new_connection;
    my $new_two = $connector->new_connection;

    isnt $new_two, $new_one, 'connections are not cached';

    $connector->with_roles('+Cache');
    my $cached_one = $connector->cached_connection;
    my $cached_two = $connector->cached_connection;

    is $cached_two, $cached_one, 'connection was cached';
    isnt $cached_one, $new_one, 'original connection not returned';
    isnt $cached_one, $new_two, 'second connection not returned';

    note 'Test that userinfo is cached with sha1_sum';
    my $url = Mojo::URL->new($connection_string);
    is $connector->cache->get($url->clone->userinfo(sha1_sum($url->userinfo))->to_unsafe_string), $cached_one, 'userinfo is cached with sha1_sum';
    is $connector->cache->get($url->to_unsafe_string), undef, 'userinfo is not cached in plaintext';

    my $new_three = $connector->new_connection;
    isnt $new_three, $cached_one, q{new connection isn't a cached connection};
    isnt $new_three, $new_one, q{new connection isn't an original new connection};
    isnt $new_three, $new_two, q{new connection isn't an original new connection};

    note 'Test options are used when caching';
    my $cached_options_one = $connector->cached_connection(options => [PrintError => 1, RaiseError => 0]);
    my $cached_options_two = $connector->cached_connection(options => [RaiseError => 0, PrintError => 1]);
    is $cached_options_two, $cached_options_one, q{connection with options was cached, and order doesn't matter};
    isnt $cached_options_one, $cached_one, 'options cached connection different from connection with no options';

    note 'Test options are sorted by key and then value';
    my $cached_options_three = $connector->cached_connection(options => [PrintError => 1, PrintError => 0, RaiseError => 0, RaiseError => 1]);
    my $cached_options_four = $connector->cached_connection(options => [PrintError => 0, RaiseError => 1, RaiseError => 0, PrintError => 1]);
    is $cached_options_four, $cached_options_three, 'options sorted by key then value when caching';
    isnt $cached_options_three, $cached_options_one, 'cached options with more options not equal to original cached options';
}
