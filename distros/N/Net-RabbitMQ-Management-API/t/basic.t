use FindBin;
use lib "$FindBin::Bin/lib";
use Net::RabbitMQ::Test;
use Net::RabbitMQ::Test::UA;
use Test::Most;

BEGIN {
    use_ok('Net::RabbitMQ::Management::API');
    use_ok('Net::RabbitMQ::Management::API::Result');
}

{
    my $p = Net::RabbitMQ::Test->create('Net::RabbitMQ::Management::API');

    isa_ok $p, 'Net::RabbitMQ::Management::API';

    throws_ok { $p->request } qr{Missing mandatory key in parameters: method}, 'Not given any parameters';
    throws_ok { $p->request( method => 'GET' ) } qr{Missing mandatory key in parameters: path}, 'Parameter path missing';
    throws_ok { $p->request( method => 'xxx', path => '/bar' ) } qr{Invalid method: xxx}, 'Not a valid HTTP method';

    lives_ok { $p->request( method => 'GET', path => 'bar' ) } 'Correct parameters do not throw an exception';
    lives_ok { $p->request( method => 'GET', path => 'bar', options => {} ) } 'Empty options hashref';

    my $result = $p->request( method => 'GET', path => '/bar' );
    my $response = $result->response;

    isa_ok $result,   'Net::RabbitMQ::Management::API::Result';
    isa_ok $response, 'HTTP::Response';
}

{
    my $p = Net::RabbitMQ::Test->create('Net::RabbitMQ::Management::API');
    my $request = $p->request( method => 'POST', path => '/foo', data => { some => 'data' } )->request;

    is $request->content, '{"some":"data"}', 'The JSON content was set in the request object';
    is $request->header('Authorization'), 'Basic Z3Vlc3Q6Z3Vlc3Q=', 'Authorization header was set in the HTTP::Request object';
}

{
    my $p = Net::RabbitMQ::Test->create('Net::RabbitMQ::Management::API');
    my $result = $p->request( method => 'GET', path => '/error/notfound' );

    is $result->success,     '', 'Unsuccessful response';
    is $result->raw_content, '', 'Has raw JSON content';

    is ref( $result->content ), 'HASH', 'Has decoded JSON hashref';
}

done_testing;
