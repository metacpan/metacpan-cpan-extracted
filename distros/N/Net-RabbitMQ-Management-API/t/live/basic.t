use FindBin;
use lib "$FindBin::Bin/../lib";
use Test::Most;
use Data::Dumper;

BEGIN {
    use_ok('Net::RabbitMQ::Management::API');
    use_ok('Net::RabbitMQ::Management::API::Result');
}

my $a = Net::RabbitMQ::Management::API->new( url => $ENV{TEST_URI} || 'http://localhost:55672/api' );

SKIP: {
    skip 'Set TEST_LIVE to true to run these tests', 1 unless $ENV{TEST_LIVE};

    my $result = $a->request(
        method => 'GET',
        path   => '/foo'
    );

    is $result->code,    404, 'HTTP status is 404';
    is $result->success, '',  'Not Successful';

    like $result->raw_content, qr{^<HTML><HEAD><TITLE>404 Not Found</TITLE></HEAD><BODY>}, '404 Not Found';
}

SKIP: {
    skip 'Set TEST_LIVE to true to run these tests', 1 unless $ENV{TEST_LIVE};

    my $result = $a->request(
        method => 'GET',
        path   => '/overview'
    );

    is $result->code,    200, 'HTTP status is 200';
    is $result->success, 1,   'Successful';

}

done_testing;
