use Test::More tests => 3;
use Test::Exception;
use Test::MockObject;
use Riak::Light;

subtest "should die with autodie enable" => sub {
    plan tests => 1;

    my $mock = Test::MockObject->new;

    my $client = Riak::Light->new(
        host   => 'host', port => 1234, autodie => 1,
        driver => $mock
    );
    $mock->set_true('perform_request');
    $mock->set_always( read_response => { error => "ops" } );
    throws_ok { $client->ping } qr/Error in 'ping' : ops/, "should die";
};

subtest "should not die with autodie disable" => sub {
    plan tests => 3;
    my $mock = Test::MockObject->new;

    my $client = Riak::Light->new(
        host   => 'host', port => 1234, autodie => 0,
        driver => $mock
    );
    $mock->set_true('perform_request');
    $mock->set_always( read_response => { error => "ops" } );

    lives_ok { $client->ping } "should not die";
    ok( !$client->ping, "should return undef" );
    like( $@, qr/Error in 'ping' : ops/, "should set \$\@ to the error" );
};

subtest "should clear \$\@ between calls" => sub {
    plan tests => 4;

    my $mock = Test::MockObject->new;

    my $client = Riak::Light->new(
        host   => 'host', port => 1234, autodie => 0,
        driver => $mock
    );
    $mock->set_true('perform_request');
    $mock->set_series(
        'read_response', { error => "ops" },
        { error => undef, code => 2, body => q() }
    );

    ok( !$client->ping, "should not die" );
    like( $@, qr/Error in 'ping' : ops/, "should set \$\@ to the error" );
    ok( $client->ping, "should return true" );
    ok( !$@,           " \$\@ should be clean" );
};
