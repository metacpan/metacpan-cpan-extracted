use strictures 2;

use Test::More;

use Net::Blossom::_URL;

subtest 'validates HTTP base URLs' => sub {
    ok(Net::Blossom::_URL::http_base_url('https://cdn.example.com'), 'https URL');
    ok(Net::Blossom::_URL::http_base_url('http://127.0.0.1:8080/prefix'), 'http URL with path prefix');
    ok(Net::Blossom::_URL::http_base_url('http://[::1]:8080/prefix'), 'IPv6 URL with path prefix');
    ok(Net::Blossom::_URL::http_base_url('https://cdn.example.com/path/prefix'), 'path prefix');

    ok(!Net::Blossom::_URL::http_base_url('cdn.example.com'), 'scheme required');
    ok(!Net::Blossom::_URL::http_base_url('ftp://cdn.example.com'), 'non-http scheme rejected');
    ok(!Net::Blossom::_URL::http_base_url('https://'), 'host required');
    ok(!Net::Blossom::_URL::http_base_url('https://cdn.example.com:bad'), 'bad port rejected');
    ok(!Net::Blossom::_URL::http_base_url('https://cdn.example.com:'), 'empty port rejected');
    ok(!Net::Blossom::_URL::http_base_url('https://cdn.example.com:0'), 'zero port rejected');
    ok(!Net::Blossom::_URL::http_base_url('https://cdn.example.com:65536'), 'out of range port rejected');
    ok(!Net::Blossom::_URL::http_base_url('https://user@cdn.example.com'), 'userinfo rejected');
    ok(!Net::Blossom::_URL::http_base_url('https://cdn.example.com?bad=1'), 'query rejected');
    ok(!Net::Blossom::_URL::http_base_url('https://cdn.example.com#bad'), 'fragment rejected');
    ok(!Net::Blossom::_URL::http_base_url([]), 'reference rejected');
};

subtest 'validates HTTP root URLs' => sub {
    ok(Net::Blossom::_URL::http_root_url('https://cdn.example.com'), 'root URL');
    ok(Net::Blossom::_URL::http_root_url('https://cdn.example.com/'), 'slash root URL');

    ok(!Net::Blossom::_URL::http_root_url('https://cdn.example.com/path'), 'path rejected');
    ok(!Net::Blossom::_URL::http_root_url('https://cdn.example.com?bad=1'), 'query rejected');
};

done_testing;
