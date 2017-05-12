use Test::More;
use Test::Fake::HTTPD;

use HTTP::Response;
use Spica;

{
    package Mock::BasicRow::Spec;
    use Spica::Spec::Declare;

    client {
        name 'mock_basic_row';
        endpoint 'default' => '/' => [];
        columns qw(
            id
            name
        );
    };

    client {
        name 'mock_basic_row_foo';
        endpoint 'default' => '/foo' => []; 
        columns qw(
            id
            name
        );
        row_class 'Mock::BasicRow::FooRow';
    };

    package Mock::BasicRow::FooRow;
    use parent 'Spica::Receiver::Row';

    package Mock::BasicRow::Row::MockBasicRow;
    use parent 'Spica::Receiver::Row';

    sub foo {
        'foo'
    }

    1;
}

my $api = run_http_server {
    my $req = shift;

    return HTTP::Response->new(
        '200',
        'OK',
        ['Content-Type' => 'application/json'],
        '{"id":1,"name":"perl"}',
    );
};

my $spica = Spica->new(
    host => '127.0.0.1',
    port => $api->port,
    spec => 'Mock::BasicRow::Spec',
);

subtest 'your row class' => sub {
    my $row = $spica->fetch('mock_basic_row' => +{id => 1})->next;
    isa_ok $row => 'Mock::BasicRow::Row::MockBasicRow';
    is $row->id => 1;
    is $row->name => 'perl';
    is $row->foo => 'foo';
};

subtest 'row_class specific Spec.pm' => sub {
    is +$spica->spec->get_row_class('mock_basic_row_foo') => 'Mock::BasicRow::FooRow';
};

subtest 'handle' => sub {
    my $row = $spica->fetch('mock_basic_row', +{id => 1})->next;
    isa_ok $row->handle => 'Spica';
    can_ok $row->handle => 'fetch';
};

done_testing();
