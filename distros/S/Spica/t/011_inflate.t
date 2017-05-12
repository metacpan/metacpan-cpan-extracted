use Test::More;
use Test::Requires
    'Test::Fake::HTTPD',
    'HTTP::Request';

use Spica;

my $api = run_http_server {
    my $req = shift;

    return HTTP::Response->new(
        '200',
        'OK',
        ['Content-Type' => 'application/json'],
        '{"result": "success", "message": "hello world.\n"}',
    );
};

{
    package Mock::Inflate::Result;

    sub new {
        my ($class, %args) = @_;
        bless \%args => $class;
    }

    sub result {
        shift->{result};
    }

    1;
}

{
    package Mock::Inflate::Spec;
    use Spica::Spec::Declare;

    client {
        name 'mock_basic';
        endpoint 'default' => '/' => [];
        columns qw(
            result
            message
        );
        inflate 'result' => sub {
            my ($col_value) = @_;
            return Mock::Inflate::Result->new(result => $col_value);
        };
    };

    1;

}

subtest 'fetch' => sub {
    my $spica = Spica->new(
        host => '127.0.0.1',
        port => $api->port,
        spec => 'Mock::Inflate::Spec',
    );

    my $row = $spica->fetch('mock_basic', +{})->next;

    isa_ok $row => 'Spica::Receiver::Row';
    isa_ok $row->result => 'Mock::Inflate::Result';
    is $row->result->result => 'success';
};

done_testing();
