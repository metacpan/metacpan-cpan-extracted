use strict;
use warnings;
use utf8;
use Puncheur::Request;
use Encode;
use Test::More;

my $query = 'foo=%E3%81%BB%E3%81%92&bar=%E3%81%B5%E3%81%8C1&bar=%E3%81%B5%E3%81%8C2';
my $host  = 'example.com';
my $path  = '/hoge/fuga';

my $req = Puncheur::Request->new({
    QUERY_STRING   => $query,
    REQUEST_METHOD => 'GET',
    HTTP_HOST      => $host,
    PATH_INFO      => $path,
});

subtest 'isa' => sub {
    isa_ok $req, 'Puncheur::Request';
    isa_ok $req, 'Plack::Request';
};

subtest 'normal' => sub {
    ok Encode::is_utf8($req->param('foo')), 'decoded';
    ok Encode::is_utf8($req->query_parameters->{'foo'}), 'decoded';
    is $req->param('foo'), 'ほげ';
    is_deeply [$req->param('bar')], ['ふが1', 'ふが2'];
};

subtest 'accessor' => sub {
    ok !Encode::is_utf8($req->param_raw('foo')), 'not decoded';
    ok !Encode::is_utf8($req->parameters_raw->{'foo'}), 'not decoded';
};

subtest 'uri' => sub {
    my $uri = $req->uri;
    isa_ok $uri, 'URI';
    is $uri.'', "http://$host$path?$query";

    my $base = $req->base;
    isa_ok $base, 'URI';
    is $base.'', "http://$host/";
};

subtest capture_params => sub {
    my %params = $req->capture_params(qw/foo bar/);

    is_deeply \%params, {
        foo => 'ほげ',
        bar => 'ふが2',
    };
};

done_testing;
