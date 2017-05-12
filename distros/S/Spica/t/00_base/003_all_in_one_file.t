use Test::More;
use Test::Fake::HTTPD;
use HTTP::Request;

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
    package Mock::BasicALLINONE::Spec;
    use Spica::Spec::Declare;

    client {
        name 'mock_basic';
        endpoint 'default' => '/' => [];
        columns qw(
            result
            message
        );
    };

    1;

}

{
    package Mock::BasicALLINONE::Row::MockBasic;
    use parent 'Spica::Receiver::Row';

    1;
}

my $spica = Spica->new(
    host => '127.0.0.1',
    port => $api->port,
    spec => 'Mock::BasicALLINONE::Spec',
);

my $iter = $spica->fetch('mock_basic', +{});
isa_ok $iter => 'Spica::Receiver::Iterator';

my $row = $iter->next;
isa_ok $row => 'Mock::BasicALLINONE::Row::MockBasic';
is $row->result => 'success';
is $row->message => "hello world.\n";

done_testing();
