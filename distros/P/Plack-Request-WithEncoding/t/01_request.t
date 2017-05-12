use strict;
use warnings;
use utf8;
use Encode qw/encode is_utf8 encode_utf8/;
use Hash::MultiValue;
use HTTP::Request;
use HTTP::Request::Common;

use Plack::Request::WithEncoding;

use Test::More;
use Plack::Test;

subtest 'isa' => sub {
    my $req = build_request();
    isa_ok $req, 'Plack::Request';
    isa_ok $req, 'Plack::Request::WithEncoding';
};

subtest 'default encoding (utf-8)' => sub {
    subtest 'GET' => sub {
        my $req = build_request();

        subtest 'get encoding information' => sub {
            is $req->encoding, 'utf-8';
        };

        subtest 'Decoded rightly' => sub {
            ok is_utf8($req->param('foo'));
            ok is_utf8($req->query_parameters->{'foo'});
        };

        is $req->param('foo'), 'ほげ', 'get query value of parameter';

        my $got = $req->param('bar');
        is $got, 'ふが2', 'get tail of value when context requires the scalar';
        is_deeply [$req->param('bar')], ['ふが1', 'ふが2'], 'get all value as array when context requires the array';
        is_deeply [sort {$a cmp $b} $req->param], ['bar', 'foo'], 'get keys of all params when it with no arguments';
    };

    subtest 'POST' => sub {
        my $app = sub {
            my $req = Plack::Request::WithEncoding->new(shift);
            ok is_utf8($req->body_parameters->{'foo'}), 'decoded rightly';
            is $req->body_parameters->{'foo'}, 'こんにちは世界', 'get body value of parameter';
            $req->new_response(200)->finalize;
        };
        test_psgi $app, sub {
            my $cb  = shift;
            my $res = $cb->(POST '/', { foo => 'こんにちは世界' });
            ok $res->is_success;
        };
    };
};

subtest 'custom encoding (cp932)' => sub {
    subtest 'GET' => sub {
        my $req = build_request('cp932');
        $req->env->{'plack.request.withencoding.encoding'} = 'cp932';

        subtest 'get encoding information' => sub {
            is $req->encoding, 'cp932';
        };

        subtest 'Decoded rightly' => sub {
            ok is_utf8($req->param('foo'));
            ok is_utf8($req->query_parameters->{'foo'});
        };

        is $req->param('foo'), 'ほげ', 'get query value of parameter';

        my $got = $req->param('bar');
        is $got, 'ふが2', 'get tail of value when context requires the scalar';
        is_deeply [$req->param('bar')], ['ふが1', 'ふが2'], 'get all value as array when context requires the array';
    };

    subtest 'POST' => sub {
        my $app = sub {
            my $req = Plack::Request::WithEncoding->new(shift);
            $req->env->{'plack.request.withencoding.encoding'} = 'cp932';

            ok is_utf8($req->body_parameters->{'foo'}), 'decoded rightly';
            is $req->body_parameters->{'foo'}, 'こんにちは世界', 'get body value of parameter';
            $req->new_response(200)->finalize;
        };
        test_psgi $app, sub {
            my $cb  = shift;
            my $req = HTTP::Request->new('POST', '/');
            $req->header(
                "content-length" => 44,
                "content-type" => "application/x-www-form-urlencoded"
            );
            $req->content('foo=%82%B1%82%F1%82%C9%82%BF%82%CD%90%A2%8AE'); # <= encoded by 'cp932'
            my $res = $cb->($req);
            ok $res->is_success;
        };
    };
};

subtest 'custom encoding (undef)' => sub {
    subtest 'GET' => sub {
        my $req = build_request();
        $req->env->{'plack.request.withencoding.encoding'} = undef;

        subtest 'get encoding information' => sub {
            is $req->encoding, undef;
        };

        subtest 'not decoded' => sub {
            ok !is_utf8($req->param('foo'));
            ok !is_utf8($req->query_parameters->{'foo'});
        };

        is $req->param('foo'), encode_utf8('ほげ'), 'get query value of parameter';

        my $got = $req->param('bar');
        is $got, encode_utf8('ふが2'), 'get tail of value when context requires the scalar';
        is_deeply [$req->param('bar')], [map {encode_utf8 $_} qw/ふが1 ふが2/], 'get all value as array when context requires the array';
    };

    subtest 'POST' => sub {
        my $app = sub {
            my $req = Plack::Request::WithEncoding->new(shift);
            $req->env->{'plack.request.withencoding.encoding'} = undef;

            ok !is_utf8($req->body_parameters->{'foo'}), 'not decoded';
            is $req->body_parameters->{'foo'}, encode_utf8('こんにちは世界'), 'get body value of parameter';
            $req->new_response(200)->finalize;
        };
        test_psgi $app, sub {
            my $cb  = shift;
            my $res = $cb->(POST '/', { foo => 'こんにちは世界' });
            ok $res->is_success;
        };
    };
};

subtest 'invalid encoding' => sub {
    my $req = build_request();
    $req->env->{'plack.request.withencoding.encoding'} = 'INVALID_ENCODING';

    eval{ $req->param };
    like $@, qr/Unknown encoding 'INVALID_ENCODING'\./, 'It must die.';
};

subtest 'accessor (not decoded)' => sub {
    my $req = build_request();

    subtest 'Should be not decoded' => sub {
        ok !is_utf8($req->raw_param('foo'));
        ok !is_utf8($req->raw_query_parameters->{'foo'});
    };

    is $req->raw_param('foo'), encode('utf-8', 'ほげ'), 'get query value of parameter';

    my $got = $req->raw_param('bar');
    is $got, encode('utf-8', 'ふが2'), 'get tail of value when context requires the scalar';
    is_deeply [$req->raw_param('bar')], [encode('utf-8', 'ふが1'), encode('utf-8', 'ふが2')], 'get all value as array when context requires the array';

    subtest 'POST' => sub {
        my $app = sub {
            my $req = Plack::Request::WithEncoding->new(shift);

            ok !is_utf8($req->raw_body_parameters->{'foo'}), 'not decoded';
            is $req->raw_body_parameters->{'foo'}, encode('utf-8', 'こんにちは世界'), 'get body value of parameter';
            $req->new_response(200)->finalize;
        };
        test_psgi $app, sub {
            my $cb  = shift;
            my $res = $cb->(POST '/', { foo => 'こんにちは世界' });
            ok $res->is_success;
        };
    };
};

done_testing;

sub build_request {
    my $encoding = shift || 'utf-8';

    # raw param: foo=ほげ&bar=ふが1&bar=ふが2
    my $query;
    if ($encoding eq 'utf-8') {
        $query = 'foo=%e3%81%bb%e3%81%92&bar=%e3%81%b5%e3%81%8c1&bar=%e3%81%b5%e3%81%8c2';
    }
    elsif ($encoding eq 'cp932') {
        $query = 'foo=%82%d9%82%b0&bar=%82%d3%82%aa1&bar=%82%d3%82%aa2';
    }
    else {
        die 'Specified encoding is unknown.';
    }

    my $host  = 'example.com';
    my $path  = '/hoge/fuga';

    my $req = Plack::Request::WithEncoding->new({
        QUERY_STRING   => $query,
        REQUEST_METHOD => 'GET',
        HTTP_HOST      => $host,
        PATH_INFO      => $path,
    });

    return $req;
}
