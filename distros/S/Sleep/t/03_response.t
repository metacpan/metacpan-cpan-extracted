use Test::More tests => 3;
use Test::Exception;

use Sleep::Response;

my $resp = Sleep::Response->new({ data => { test => 1} });

is_deeply({test => 1}, $resp->data());
is($resp->encode('application/json'), '{"test":1}');

dies_ok {
    $resp->encode('unknown/mimetype');
};

