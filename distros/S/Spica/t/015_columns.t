use Test::More;
use Test::Fake::HTTPD;

my $api = run_http_server {
    my $req = shift;

    if ($req->uri->path eq '/accessor') {
        if ($req->uri->path_query eq '/accessor?userId=1') {
            return HTTP::Response->new(
                '200',
                'OK',
                ['Content-Type' => 'application/json'],
                '{"apiStatus": "success", "apiMessage": "hello world.\n"}',
            );
        } else {
            return HTTP::Response->new(401, 'INVALID ARGS', [], '')
        }
    } else {
        return HTTP::Response->new(
            '200',
            'OK',
            ['Content-Type' => 'application/json'],
            '{"apiStatus": "success", "apiMessage": "hello world.\n"}',
        );
    }
};

{
    package Mock::Spec;
    use Spica::Spec::Declare;

    client {
        name 'basic';
        endpoint default => '/' => [];
        columns (
            'apiStatus',
            'apiMessage'
        );
    };

    client {
        name 'convert';
        endpoint default => '/' => [];
        columns (
            'status'  => +{from => 'apiStatus'},
            'message' => +{from => 'apiMessage'},
        );
    };

    client {
        name 'no_row_accessor';
        endpoint default => '/accessor' => [];
        columns (
            'user_id' => +{from => 'userId', no_row_accessor => 1},
            'status'  => +{from => 'apiStatus'},
            'message' => +{from => 'apiMessage'},
        );
    };
}

use Spica;

my $spica = Spica->new(
    host => '127.0.0.1',
    port => $api->port,
    spec => 'Mock::Spec',
);

subtest 'basic' => sub {
    my $result = $spica->fetch('basic', +{})->next;
    can_ok $result => qw(apiStatus apiMessage);

    is $result->apiStatus  => 'success';
    is $result->apiMessage => "hello world.\n";
};

subtest 'convert' => sub {
    my $result = $spica->fetch('convert', +{})->next;
    can_ok $result => qw(status message);

    is $result->status  => 'success';
    is $result->message => "hello world.\n";
};

subtest 'no_row_accessor' => sub {
    my $result = $spica->fetch('no_row_accessor', +{user_id => 1})->next;

    can_ok $result => qw(status message);
    ok ! $result->can('user_id');

    is $result->status  => 'success';
    is $result->message => "hello world.\n";
};

done_testing;
