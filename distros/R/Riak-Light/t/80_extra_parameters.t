use Test::More tests => 3;
use Test::Exception;
use Test::MockObject;
use Riak::Light;
use Riak::Light::PBC;
use POSIX qw(ETIMEDOUT strerror);
use JSON;

subtest "fetch" => sub {
    plan tests => 2;

    subtest "fetch simple value " => sub {
        plan tests => 5;
        my $mock = Test::MockObject->new;

        my $hash = { lol => 123 };

        my $mock_response = {
            error => undef,
            code  => 10,
            body  => RpbGetResp->encode(
                {   content => {
                        value        => encode_json($hash),
                        content_type => 'application/json'
                    }
                }
            )
        };

        $mock->set_true('perform_request');
        $mock->set_always( read_response => $mock_response );

        my $client = Riak::Light->new(
            host   => 'host', port => 1234, autodie => 1,
            driver => $mock
        );

        $client->get( foo => "bar" );

        my ( $name, $args ) = $mock->next_call;

        my %params;

        ( undef, %params ) = @$args;
        my $request = RpbGetReq->decode( $params{body} );

        is $name, "perform_request", 'should call perform_request';
        is $request->r, 2, 'should create the request with r = 2';
        is $request->bucket, "foo",
          'should create the request with bucket = foo';
        is $request->key, "bar", 'should create the request with key = bar';
        ok !$request->pr, 'pr should not be used';
    };

    subtest "fetch simple value with extra parameters" => sub {
        plan tests => 5;
        my $mock = Test::MockObject->new;

        my $hash = { lol => 123 };

        my $mock_response = {
            error => undef,
            code  => 10,
            body  => RpbGetResp->encode(
                {   content => {
                        value        => encode_json($hash),
                        content_type => 'application/json'
                    }
                }
            )
        };

        $mock->set_true('perform_request');
        $mock->set_always( read_response => $mock_response );

        my $client = Riak::Light->new(
            host   => 'host', port => 1234, autodie => 1, pr => 3,
            driver => $mock
        );

        $client->get( foo => "bar" );

        my ( $name, $args ) = $mock->next_call;

        my %params;

        ( undef, %params ) = @$args;
        my $request = RpbGetReq->decode( $params{body} );

        is $name, "perform_request", 'should call perform_request';
        is $request->r, 2, 'should create the request with r = 2';
        is $request->bucket, "foo",
          'should create the request with bucket = foo';
        is $request->key, "bar", 'should create the request with key = bar';
        is $request->pr,  3,     'should create the request with pr = 3';
    };
};

subtest "store" => sub {
    plan tests => 2;

    subtest "store simple data " => sub {
        plan tests => 8;
        my $mock = Test::MockObject->new;

        my $mock_response = {
            error => undef,
            code  => 12,
            body  => q()
        };

        $mock->set_true('perform_request');
        $mock->set_always( read_response => $mock_response );

        my $client = Riak::Light->new(
            host   => 'host', port => 1234, autodie => 1,
            driver => $mock
        );

        $client->put_raw( foo => "bar", "1" );

        my ( $name, $args ) = $mock->next_call;

        my %params;

        ( undef, %params ) = @$args;
        my $request = RpbPutReq->decode( $params{body} );

        is $name, "perform_request", 'should call perform_request';
        is $request->w, 2, 'should create the request with w = 2';
        is $request->bucket, "foo",
          'should create the request with bucket = foo';
        is $request->key, "bar", 'should create the request with key = bar';
        is $request->dw,  2,     'should create the request with dw = 2';
        ok !$request->pw, 'should has no pw';
        is $request->content->content_type, "plain/text",
          "content_type should be plain/text";
        is $request->content->value, "1", "value should be 1";
    };


    subtest "store simple data with extra parameters" => sub {
        plan tests => 8;
        my $mock = Test::MockObject->new;

        my $mock_response = {
            error => undef,
            code  => 12,
            body  => q()
        };

        $mock->set_true('perform_request');
        $mock->set_always( read_response => $mock_response );

        my $client = Riak::Light->new(
            host   => 'host', port => 1234, autodie => 1, pw => 1,
            driver => $mock
        );

        $client->put_raw( foo => "bar", "1" );

        my ( $name, $args ) = $mock->next_call;

        my %params;

        ( undef, %params ) = @$args;
        my $request = RpbPutReq->decode( $params{body} );

        is $name, "perform_request", 'should call perform_request';
        is $request->w, 2, 'should create the request with w = 2';
        is $request->bucket, "foo",
          'should create the request with bucket = foo';
        is $request->key, "bar", 'should create the request with key = bar';
        is $request->dw,  2,     'should create the request with dw = 2';
        is $request->pw,  1,     'should create the request with pw = 1';
        is $request->content->content_type, "plain/text",
          "content_type should be plain/text";
        is $request->content->value, "1", "value should be 1";
    };
};

subtest "delete" => sub {
    plan tests => 2;

    subtest "del simple data " => sub {
        plan tests => 9;
        my $mock = Test::MockObject->new;

        my $mock_response = {
            error => undef,
            code  => 14,
            body  => q()
        };

        $mock->set_true('perform_request');
        $mock->set_always( read_response => $mock_response );

        my $client = Riak::Light->new(
            host   => 'host', port => 1234, autodie => 1,
            driver => $mock
        );

        $client->del( foo => "bar" );

        my ( $name, $args ) = $mock->next_call;

        my %params;

        ( undef, %params ) = @$args;
        my $request = RpbDelReq->decode( $params{body} );

        is $name, "perform_request", 'should call perform_request';
        is $request->w,  2, 'should create the request with w = 2';
        is $request->r,  2, 'should create the request with r = 2';
        is $request->dw, 2, 'should create the request with dw = 2';

        is $request->bucket, "foo",
          'should create the request with bucket = foo';
        is $request->key, "bar", 'should create the request with key = bar';

        ok !$request->rw, 'should has no rw';
        ok !$request->pr, 'should has no pr';
        ok !$request->pw, 'should has no pw';
    };

    subtest "del simple data with extra parameters" => sub {
        plan tests => 9;
        my $mock = Test::MockObject->new;

        my $mock_response = {
            error => undef,
            code  => 14,
            body  => q()
        };

        $mock->set_true('perform_request');
        $mock->set_always( read_response => $mock_response );

        my $client = Riak::Light->new(
            host   => 'host', port => 1234, autodie => 1,
            rw     => 1,      pr   => 2,    pw      => 3,
            driver => $mock
        );

        $client->del( foo => "bar" );

        my ( $name, $args ) = $mock->next_call;

        my %params;

        ( undef, %params ) = @$args;
        my $request = RpbDelReq->decode( $params{body} );

        is $name, "perform_request", 'should call perform_request';
        is $request->w,  2, 'should create the request with w = 2';
        is $request->r,  2, 'should create the request with r = 2';
        is $request->dw, 2, 'should create the request with dw = 2';

        is $request->bucket, "foo",
          'should create the request with bucket = foo';
        is $request->key, "bar", 'should create the request with key = bar';

        is $request->rw, 1, 'should create the request with rw = 1';
        is $request->pr, 2, 'should create the request with pr = 2';
        is $request->pw, 3, 'should create the request with pw = 3';
    };

};
