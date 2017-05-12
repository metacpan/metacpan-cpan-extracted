use Test::More;
use Test::Fake::HTTPD;
use HTTP::Response;

use Spica;

{
    package Mock::Spec;
    use Spica::Spec::Declare;

    client {
        name 'before_request';
        endpoint 'default' => '/' => [];
        columns (
            'result',
            'message',
        );
        filter 'before_request' => sub {
            my ($spica, $builder) = @_;
            # XXX: override uri path SEE ALSO Spica::URIMaker
            $builder->uri->path('/test');
            return $builder;
        };
    };

    client {
        name 'after_request';
        endpoint 'default' => '/' => [];
        columns (
            'result',
            'message',
        );
        filter 'after_request' => sub {
            my ($spica, $response) = @_;
            if ($response->status == 404) {
                $response->{code}    = 200;
                $response->{content} = '[{"message": "after request hooks content"}]';
            }
            return $response;
        };
    };

    client {
        name 'before_receive';
        endpoint 'default' => '/before_receive' => [];
        columns (
            'result',
            'message',
        );
        filter 'before_receive' => sub {
            my ($spica, $data) = @_;
            return [$data];
        };
    };
}

my $api = run_http_server {
    my $req = shift;

    if ($req->uri->path eq '/test') {
        return HTTP::Response->new(
            '200',
            'OK',
            ['Content-Type' => 'application/json'],
            '{"result": "success"}',
        );
    }
    if ($req->uri->path eq '/before_receive') {
        return  HTTP::Response->new(
            '200',
            'OK',
            ['Content-Type' => 'application/json'],
            '{"message": "please format."}',
        );
    }
    return HTTP::Response->new(
        '404',
        'NOT FOUND',
        ['Content-Type' => 'application/json'],
        '{"id":1,"name":"perl"}',
    );
};

my $spica = Spica->new(
    host => '127.0.0.1',
    port => $api->port,
    spec => 'Mock::Spec',
);

subtest 'before_request' => sub {
    my $result = $spica->fetch('before_request', +{})->next;
    is $result->result => 'success';
};

subtest 'after_request' => sub {
    # exceptionが発生せず、何もコンテンツがない
    my $results = $spica->fetch('after_request' => +{});
    isa_ok $results->{data} => 'ARRAY';
    is $results->next->message => 'after request hooks content';
};

subtest 'before_receive' => sub {
    my $result = $spica->fetch('before_receive', +{})->next;
    is $result->message => 'please format.';
};

done_testing;
