use Test::More tests => 6;
use Test::Exception;
use Riak::Light;

dies_ok { Riak::Light->new } "should ask for port and host";
dies_ok { Riak::Light->new( host => '127.0.0.1' ) } "should ask for port";
dies_ok { Riak::Light->new( port => 8087 ) } "should ask for host";

subtest "new and default attrs values" => sub {
    my $client = new_ok(
        'Riak::Light' => [
            host    => '127.0.0.1',
            port    => 9087,
            autodie => 0,
            driver  => undef
        ],
        "a new client"
    );
    is( $client->timeout, 0.5, "default timeout should be 0.5" );
    is( $client->r,       2,   "default r  should be 2" );
    is( $client->w,       2,   "default w  should be 2" );
    is( $client->dw,      2,   "default dw should be 2" );
    ok( !$client->autodie,         "default autodie shoudl be false" );
    ok( $client->timeout_provider, 'Riak::Light::Timeout::Select' );

    ok( !$client->has_rw, "should have no rw" );
    ok( !$client->has_pr, "should have no pr" );
    ok( !$client->has_pw, "should have no pw" );
};

subtest "new and other attrs values" => sub {
    my $client = new_ok(
        'Riak::Light' => [
            host             => '127.0.0.1',
            port             => 9087,
            timeout          => 0.2,
            autodie          => 1,
            r                => 1,
            w                => 1,
            dw               => 1,
            driver           => undef,
            in_timeout       => 2,
            out_timeout      => 4,
            rw               => 1,
            pr               => 2,
            pw               => 3,
            timeout_provider => 'Riak::Light::Timeout::TimeOut'
        ],
        "a new client"
    );
    is( $client->timeout, 0.2, "timeout should be 0.2" );
    is( $client->r,       1,   "r  should be 1" );
    is( $client->w,       1,   "w  should be 1" );
    is( $client->dw,      1,   "dw should be 1" );
    is( $client->rw,      1,   "rw should be 1" );
    is( $client->pr,      2,   "pr should be 2" );
    is( $client->pw,      3,   "pw should be 3" );
    ok( $client->autodie,          "autodie should be true" );
    ok( $client->timeout_provider, 'Riak::Light::Timeout::TimeOut' );
    is( $client->in_timeout,  2, "in timeout should be 2" );
    is( $client->out_timeout, 4, "out timeout should be 4" );
};

subtest "should be a riak::light instance" => sub {
    isa_ok(
        Riak::Light->new( host => 'host', port => 9999, driver => undef ),
        'Riak::Light'
    );
  }
