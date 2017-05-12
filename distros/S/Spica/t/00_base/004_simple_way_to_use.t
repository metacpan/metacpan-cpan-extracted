use Test::More;
use Test::Fake::HTTPD;
use HTTP::Response;

use Spica;

my $api = run_http_server {
    my $req = shift;

    return HTTP::Response->new(
        200,
        'OK',
        [],
        '[{"id":1,"name":"perl"},{"id":2,"name":"ruby"}]',
    );
};

my $spica = Spica->new(host => '127.0.0.1', port => $api->port);

my $results = $spica->fetch('/', +{});
isa_ok $results => 'Spica::Receiver::Iterator';

{
    my $result = $results->next;
    isa_ok $result => 'Spica::Receiver::Row';
    is $result->id => 1;
    is $result->name => 'perl';
}

{
    my $result = $results->next;
    isa_ok $result => 'Spica::Receiver::Row';
    is $result->id => 2;
    is $result->name => 'ruby';
}

done_testing;
