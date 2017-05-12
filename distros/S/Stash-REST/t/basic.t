use strict;
use Test::More;

use JSON;
use HTTP::Response;
use Test::Fake::HTTPD;
use LWP::UserAgent;
use URL::Encode qw/url_params_mixed/;

use File::Temp qw/ tempfile/;
use URI::QueryParam;

my $httpd = Test::Fake::HTTPD->new( timeout => 5, );

my $fakedatabase = {};
my $seq          = 0;
$httpd->run(
    sub {
        my $req = shift;

        my @pp = split q{/}, $req->uri->path;
        shift @pp;
        $seq++;

        my $data = $req->content;

        $data = url_params_mixed($data) if $req->headers->header('Content-type') eq 'application/x-www-form-urlencoded';
        $data = decode_json($data)      if $req->headers->header('Content-type') eq 'application/json';

        if ( $req->method eq 'POST' ) {

            if ( $req->uri->path eq '/post-with-params' ) {

                return [
                    200,
                    [ 'Content-Type', 'application/json' ],
                    [
                        encode_json(
                            {
                                ilove  => $data,
                                params => { map { $_ => [ ( $req->uri->query_param($_) ) ] } $req->uri->query_param }
                            }
                        )
                    ]
                ];

            }
            elsif ( $req->uri->path eq '/test-content-json' ) {

                return [ 200, [ 'Content-Type', 'application/json' ], [ encode_json( { ilove => $data } ) ] ];

            }
            elsif ( $req->uri->path eq '/test-file-upload' ) {

                # we don't need really parse the Content-Disposition... but HTTP::Body should be good for you.
                my $ok1 = $data =~ /Content-Disposition: form-data; name="file1";/;
                my $ok2 = $data =~ /Content-Disposition: form-data; name="file2";/;

                return [ 200, [ 'Content-Type', 'application/json' ], [ encode_json( { oks => $ok1 + $ok2 } ) ] ];

            }
            elsif ( @pp == 1 ) {

                $fakedatabase->{ $pp[0] }{$seq} = my $obj = { id => $seq, %$data };
                return [
                    201,
                    [ 'Content-Type', 'application/json', 'Location', join( '/', @pp, $seq ) ],
                    [ encode_json($obj) ]
                ];
            }

        }
        elsif ( $req->method eq 'GET' ) {

            if ( $req->uri->path eq '/get-params' ) {

                return [
                    200,
                    [ 'Content-Type', 'application/json' ],
                    [
                        encode_json(
                            { params => { map { $_ => [ ( $req->uri->query_param($_) ) ] } $req->uri->query_param } }
                        )
                    ]
                ];

            }
            elsif ( @pp == 1 ) {
                return [
                    200,
                    [ 'Content-Type', 'application/json' ],
                    [
                        encode_json(
                            { $pp[0], [ map { $fakedatabase->{ $pp[0] }{$_} } keys %{ $fakedatabase->{ $pp[0] } } ] }
                        )
                    ]
                ];
            }
            else {
                return [ 404, [], ['{"error":"not found"}'] ] unless exists $fakedatabase->{ $pp[0] }{ $pp[1] };
                return [
                    200,
                    [ 'Content-Type', 'application/json' ],
                    [ encode_json( $fakedatabase->{ $pp[0] }{ $pp[1] } ) ]
                ];
            }

        }
        elsif ( $req->method eq 'DELETE' ) {

            if ( @pp == 2 ) {
                delete $fakedatabase->{ $pp[0] }{ $pp[1] };
                return [ 204, [], [''] ];
            }

        }
        elsif ( $req->method eq 'PUT' ) {

            if ( @pp == 2 ) {

                $fakedatabase->{ $pp[0] }{ $pp[1] }{$_} = $data->{$_} for keys %$data;
                return [
                    202,
                    [ 'Content-Type', 'application/json' ],
                    [ encode_json( { id => $fakedatabase->{ $pp[0] }{ $pp[1] }{id} } ) ]
                ];
            }

        }
        elsif ( $req->method eq 'HEAD' ) {
            return [ 200, [ Foo => 1 ], [] ];
        }

        [ 500, [ 'Content-Type', 'application/json' ], ['{"error":"fatal"}'] ];
    }
);

BEGIN { use_ok 'Stash::REST' }
my $obj = Stash::REST->new(
    do_request => sub {
        my $req = shift;
        $req->uri( $req->uri->abs( $httpd->endpoint ) );

        LWP::UserAgent->new->request($req);
    },
    decode_response => sub {
        my $res = shift;
        return decode_json( $res->content );
    },
);
is( ref $obj, 'Stash::REST', 'obj is Stash::REST' );

is( $obj->stash('foo'), undef, 'foo is undef' );

is( $obj->stash->{'foo'} = 3, '3', 'foo is 3' );

$obj->stash->{'bar'} = 1;

$obj->stash( 'bar2' => 2, 'bar3' => 3 );

is( $obj->stash->{'bar'},  '1', 'bar is 1' );
is( $obj->stash->{'bar2'}, '2', 'bar2 is 2' );
is( $obj->stash->{'bar3'}, '3', 'bar3 is 3' );

my $run = 0;
$obj->rest_post(
    '/zuzus',
    name            => 'add zuzu',
    list            => 1,
    stash           => 'easyname',
    prepare_request => sub {
        is( ref $_[0], 'HTTP::Request', 'HTTP::Request recived on prepare_request' );
        $run++;
    },
    [ name => 'foo', ]
);
is( $run, '2', '2 executions of prepare_request' );

is( ref $obj->stash->{'easyname'},      'HASH',    'stash easyname is hash' );
is( ref $obj->stash->{'easyname.get'},  'HASH',    'stash easyname.get is hash' );
is( ref $obj->stash->{'easyname.id'},   '',        'stash easyname.id is scalar' );
is( $obj->stash->{'easyname.url'},      'zuzus/1', 'stash easyname.url is /zuzus/1' );
is( $obj->stash->{'easyname.list-url'}, '/zuzus',  'stash easyname.list-url is /zuzus' );
is( ref $obj->stash->{'easyname.list'}, 'HASH',    'stash easyname.list is HASH' );

$obj->stash_ctx(
    'easyname.get',
    sub {
        my ($me) = @_;

        is( $me->{id}, $obj->stash('easyname.id'), 'get has the same id!' );
        is( $me->{name}, 'foo', 'name ok!' );

    }
);

$obj->stash_ctx(
    'easyname.list',
    sub {
        my ($me) = @_;

        ok( $me = delete $me->{zuzus}, 'zuzu list exists' );

        is( @$me, 1, '1 zuzu' );

        is( $me->[0]{name}, 'foo', 'listing ok' );
    }
);

$obj->rest_put(
    $obj->stash('easyname.url'),
    name => 'update zuzu',
    [ name => 'AAAAAAAAA', ]
);

do {
    my $res = $obj->rest_head( $obj->stash('easyname.url'), );
    is( $res->headers->header('foo'), '1', 'header is present' );
};

$obj->rest_reload('easyname');

$obj->stash_ctx(
    'easyname.get',
    sub {
        my ($me) = @_;

        is( $me->{name}, 'AAAAAAAAA', 'name updated!' );
    }
);

$obj->rest_delete( $obj->stash('easyname.url') );

$obj->rest_reload( 'easyname', code => 404 );

$obj->rest_reload_list('easyname');

$obj->stash_ctx(
    'easyname.list',
    sub {
        my ($me) = @_;

        ok( $me = delete $me->{zuzus}, 'zuzus list exists' );

        is( @$me, 0, '0 zuzu' );

    }
);

do {
    my $run = 0;
    $obj->rest_post(
        '/abos',
        name            => 'create without list',
        stash           => 'easyname2',
        is_fail         => 0,                       # default is 0
        prepare_request => sub {
            is( ref $_[0], 'HTTP::Request', 'HTTP::Request recived on prepare_request' );
            $run++;
        },
        [ name => 'foo', ]
    );
    is( $run, '1', '1 execution of prepare_request' );
};

$obj->rest_get(
    [ 'abox', '1' ],                                # same as /abox/1
    name    => 'get with 404',
    is_fail => 1,
    code    => 404,
    stash   => 'easyname3',
    [ query_param => 1, query_param2 => 2 ]
);

eval {
    $obj->rest_get(
        '/things/deep/url/not/planed',
        stash => 'zu',
        data  => [ you => 'can' => 'pass' => 'data with %conf too' ]
    );
};
like( $@, qr/response expected success and it is failed/, 'response expected success and it is failed' );

eval { $obj->rest_get( '/things', stash => 'zu', is_fail => 1 ); };
like( $@, qr/response expected fail and it is successed/, 'response expected fail and it is successed' );

eval { $obj->rest_get( '/things', stash => 'zu', code => 230 ); };
like( $@, qr|response code \[200\] diverge expected \[230\]|, 'response code [200] diverge expected [230] ' );

eval { $obj->rest_get( { '/an' => { 'invalid/' => 'uri' } } ); };
like( $@, qr|invalid uri param|, 'rest_post invalid uri param' );

eval { $obj->rest_get(); };
like( $@, qr|invalid number of params|, 'rest_post invalid number of params' );

eval {
    $obj->rest_post(
        '/zuzus',
        name            => 'add zuzu',
        list            => 1,
        stash           => 'easyname',
        prepare_request => 1,
        [ name => 'foo', ]
    );
};
like( $@, qr|prepare_request must be a coderef|, 'prepare_request must be a coderef' );

$obj->fixed_headers( [ a_header => 12 ] );
$obj->rest_post(
    '/abob',
    name            => 'add abob',
    list            => 1,
    stash           => 'easyname',
    prepare_request => sub {
        is( $_[0]->headers->header('a_header'), '12', 'the fixed headers are sent' );
    },
    [ name => 'foo', ]
);

$obj->rest_post(
    '/test-content-json',
    name    => 'add abob',
    code    => 200,
    stash   => 'testjson',
    headers => [
        'Content-Type' => 'application/json',
    ],
    data => encode_json( { who => [ 'are', { you => 1.5 } ] } ),
);

$obj->stash_ctx(
    'testjson',
    sub {
        my ($me) = @_;
        is_deeply( $me->{ilove}, { who => [ 'are', { you => 1.5 } ] }, 'server recived the json data and decoded it.' );
    }
);

my ( $fh, $filename ) = tempfile();
$obj->rest_post(
    '/test-file-upload',
    name  => 'add abob',
    code  => 200,
    stash => 'testupload',
    files => {
        'file1' => $filename,
        'file2' => $filename,
    },
    data => [
        'foo' => 123
    ],
);

$obj->stash_ctx(
    'testupload',
    sub {
        my ($me) = @_;
        is( $me->{oks}, 2, 'two files was uploaded' );
    }
);
unlink($filename);

eval { $obj->rest_get( '/obs', params => [ name => 'bar' ], data => [ name => 'foo', ] ); };
like( $@, qr|Please, use only \{params\} instead|, 'Please, use only {params} instead' );

$obj->rest_get(
    '/get-params',
    stash  => 'testparams',
    params => [ name => 'bar' ]
);

$obj->stash_ctx(
    'testparams',
    sub {
        my ($me) = @_;

        is_deeply( $me->{params}, { name => ['bar'] }, 'params is encoded to url' );
    }
);

$obj->rest_get(
    '/get-params',
    stash => 'testparams',
    data  => [ name => 'fo' ]
);

$obj->stash_ctx(
    'testparams',
    sub {
        my ($me) = @_;

        is_deeply( $me->{params}, { name => ['fo'] }, 'data is converted to params if method is not POST or PUT' );
    }
);

$obj->rest_get(
    '/get-params?name=foo',
    stash  => 'testparams',
    params => [ name => 'zum' ]
);

$obj->stash_ctx(
    'testparams',
    sub {
        my ($me) = @_;
        is_deeply( $me->{params}, { name => [ 'foo', 'zum' ] }, 'mixed params' );
    }
);

$obj->rest_post(
    '/post-with-params?api_key=1',
    stash   => 'testparams',
    params  => [ another_key => 2 ],
    headers => [
        'Content-Type' => 'application/json',
    ],
    code => 200,
    data => encode_json( { hello => 'json' } ),
);

$obj->stash_ctx(
    'testparams',
    sub {
        my ($me) = @_;
        is_deeply(
            $me,
            {
                ilove  => { hello => 'json' },
                params => {
                    another_key => [2],
                    api_key     => [1],
                },
            },
            'params with json body'
        );
    }
);

done_testing;
