#!perl

package Test::ParseRequest;

our %SPEC;
$SPEC{add2} = {
    v=>1.1,
    args=>{
        a=>{req=>1, pos=>0, schema=>'num'},
        b=>{req=>1, pos=>1, schema=>'num'},
    },
};
sub add2 { my %args = @_; [200, "OK", $args{a} + $args{b}] }

# to test deconfuse_php_clients
$SPEC{f1} = {
    v=>1.1,
    args=>{
        a=>{schema=>'array'},
        b=>{},
        h=>{schema=>'hash'},
    },
};
sub f1 { [200] }

package main;

use 5.010;
use strict;
use warnings;

use Plack::Builder;
use Plack::Test;
use Test::More;

test_ParseRequest_middleware(
    name => "default",
    args => {match_uri=>qr!^/api(?<uri>/[^?]*)!},
    requests => [
        {
            name      => 'default Riap request keys (for function)',
            args      => [GET => '/api/foo'],
            rreq      => {v=>1.1, action=>'call', uri=>'/foo', fmt=>'json'},
        },
        {
            name      => 'default Riap request keys (for package)',
            args      => [GET => '/api/'],
            rreq      => {v=>1.1, action=>'list', detail=>1, uri=>'/', fmt=>'json'},
        },
        {
            name      => 'default fmt = text, errpage in text',
            args      => [GET => '/x', ['Accept'=>'text/html',
                                        'User-Agent'=>'curl/0.0']],
            rreq      => undef,
            ct        => 'text/plain',
            content   => qr/match match_uri/,
        },

        {
            name      => 'request keys from X-Riap-* header',
            args      => [GET => '/api/foo', ['X-Riap-Foo' => 42,
                                              'X-Riap-Bar-Baz-j-'=>'[2]']],
            rreq      => {v=>1.1, action=>'call', uri=>'/foo', fmt=>'json',
                          foo=>42, bar_baz=>[2]},
        },
        {
            name      => 'invalid json in from X-Riap-* header',
            args      => [GET => '/api/', ['X-Riap-Foo-j-' => '[a']],
            rreq      => undef,
            ct        => 'application/json',
            content   => qr/invalid json/i,
        },

        {
            name      => 'parse args from body',
            args      => [POST => '/api/Foo/bar',
                          ['Content-Type'=>'application/json'],
                          '{"a":1,"b":[2,3]}'],
            rreq      => {v=>1.1, action=>'call', uri=>'/Foo/bar',
                          fmt=>'json', args=>{a=>1, b=>[2,3]}},
        },
        {
            name      => 'invalid json in body',
            args      => [POST => '/api/Foo/bar',
                          ['Content-Type'=>'application/json'],
                          '{"a":1,"b":[2,3]'],
            rreq      => undef,
            ct        => 'application/json',
            content   => qr/invalid json/i,
        },
        {
            name      => 'sanity check for args',
            args      => [POST => '/api/Foo/bar',
                          ['Content-Type'=>'application/json'],
                          '[]'],
            ct        => 'application/json',
            content   => qr/args.+must be hash/i,
        },
        {
            name      => 'args from body does not override X-Riap-Args header',
            args      => [POST => '/api/Foo/bar',
                          ['X-Riap-Args-j-'=>'{}',
                           'Content-Type'=>'application/json'],
                          '{"a":1,"b":[2,3]}'],
            rreq      => {v=>1.1, action=>'call', uri=>'/Foo/bar',
                          fmt=>'json', args=>{}},
        },
        {
            name      => 'args from form does not override args from body',
            args      => [POST => '/api/Foo/bar?a=10&b=20&c=30&d=40',
                          ['Content-Type'=>'application/json'],
                          '{"a":1,"b":2,"c":null}'],
            rreq      => {v=>1.1, action=>'call', uri=>'/Foo/bar',
                          fmt=>'json', args=>{a=>1, b=>2, c=>undef, d=>40}},
        },
        {
            name      => 'match_uri',
            args      => [GET => '/x'],
            rreq      => undef,
            ct        => 'application/json',
            content   => qr/match match_uri/,
        },
        {
            name      => 'match_uri does not override X-Riap-URI header',
            args      => [GET => '/api/F1',
                          ['X-Riap-URI'=>'/F0']],
            rreq      => {v=>1.1, action=>'call', uri=>'/F0',
                          fmt=>'json'},
        },
        {
            name      => 'parse args from body (yaml, default off)',
            args      => [POST => '/api/Foo/bar',
                          ['Content-Type'=>'text/yaml'],
                          '{a: 1, b: [2, 3]}'],
            ct        => 'application/json',
            content   => qr/unsupported/i,
        },
        {
            name      => 'parse args from body (unknown type)',
            args      => [POST => '/api/Foo/bar',
                          ['Content-Type'=>'text/unknown'],
                          '123'],
            ct        => 'application/json',
            content   => qr/unsupported/i,
        },

        # XXX test parse from multipart body (not yet supported)

        {
            name      => 'parse args + request keys from form (get)',
            args      => [GET => '/api/Foo/bar?a=1&b:j=[2,3]&-riap-foo=bar'],
            rreq      => {v=>1.1, action=>'call', uri=>'/Foo/bar',
                          fmt=>'json', foo=>'bar', args=>{a=>1, b=>[2,3]}},
        },
        {
            name      => 'invalid json in web form',
            args      => [GET => '/api/Foo/bar?a=1&b:j=['],
            rreq      => undef,
            ct        => 'application/json',
            content   => qr/invalid json/i,
        },
        {
            name      => 'request/args keys from form does not override '.
                'X-Riap-* header & body',
            args      => [GET => '/api/Foo/bar?a=2&b:j=[2,3]&-riap-foo=bar&'.
                      '-riap-fmt=text&-riap-baz=qux',
                          ['X-Riap-Args-j-'=>'{"a":1}', 'X-Riap-Baz'=>1]],
            rreq      => {v=>1.1, action=>'call', uri=>'/Foo/bar',
                          fmt=>'text', foo=>'bar', baz=>1,
                          args=>{a=>1, b=>[2,3]}},
        },

    ],
);

test_ParseRequest_middleware(
    name => "match_uri as 2-element array",
    args => {match_uri=>[
        qr!^/ga/(?<mod>[^?/]+)(?:
               /?(?:
                   (?<func>[^?/]+)?
               )
           )!x,
        sub {
            my ($env, $m) = @_;
            $m->{mod} =~ s!::!/!g;
            $m->{func} //= "";
            $env->{'riap.request'}{uri} = "/My/$m->{mod}/$m->{func}";
        },
    ]},
    requests => [
        {
            name      => 'mod',
            args      => [GET => '/ga/Foo::Bar'],
            rreq      => {v=>1.1, action=>'list', detail=>1, fmt=>'json',
                          uri=>'/My/Foo/Bar/'},
        },
        {
            name      => 'mod + func',
            args      => [GET => '/ga/Foo::Bar/baz'],
            rreq      => {v=>1.1, action=>'call', fmt=>'json',
                          uri=>'/My/Foo/Bar/baz'},
        },
    ],
);

test_ParseRequest_middleware(
    name => "accept_yaml=1",
    args => {match_uri=>qr!^/api(?<uri>/[^?]*)!, accept_yaml=>1},
    requests => [
        {
            name      => 'parse args from body (yaml turned on)',
            args      => [GET => '/api/Foo/bar',
                          ['Content-Type'=>'text/yaml'],
                          '{a: 1, b: [2, 3]}'],
            rreq      => {v=>1.1, action=>'call', uri=>'/Foo/bar',
                          fmt=>'json', args=>{a=>1, b=>[2,3]}},
        },
    ],
);

test_ParseRequest_middleware(
    name => "parse_form=0",
    args => {match_uri=>qr!^/api(?<uri>/[^?]*)!, parse_form=>0},
    requests => [
        {
            name      => 'request/args keys from form (turned off)',
            args      => [GET => '/api/Foo/bar?a=1'],
            rreq      => {v=>1.1, action=>'call', uri=>'/Foo/bar',
                          fmt=>'json'},
        },
    ],
);

test_ParseRequest_middleware(
    name => "parse_path_info=1",
    args => {parse_path_info=>1,
             match_uri=>[
                 qr!^/ga/(?<mod>[^?/]+)(?:
                        /?(?:
                            (?<func>[^?/]+)?
                            (?<pi>/?[^?]*)
                        )
                    )!x,
                 sub {
                     my ($env, $m) = @_;
                     $m->{mod} =~ s!::!/!g;
                     $m->{func} //= "";
                     $env->{'riap.request'}{uri} = "/$m->{mod}/$m->{func}";
                     $env->{PATH_INFO} = $m->{pi};
                 },
             ]},
    requests => [
        {
            name      => 'parse args from PATH_INFO (turned on)',
            args      => [GET => '/ga/Test::ParseRequest/add2/10%2E5/20%2E5'],
            rreq      => {v=>1.1, action=>'call', fmt=>'json',
                          uri=>'/Test/ParseRequest/add2',
                          args=>{a=>10.5, b=>20.5},
                      },
        },
    ],
);

# XXX test parse args + request keys from path info? (turned off by default)

subtest "deconfuse_php_clients & php_clients_ua_re" => sub {
    my $uri = "/Test/ParseRequest/f1";
    my %cr = (v=>1.1, action=>'call', fmt=>'json', ua=>'Phinci',
              uri=>$uri); # common request keys
    test_ParseRequest_middleware(
        name => "disabled",
        args => {deconfuse_php_clients=>0},
        requests => [
            {
                args      => [GET => $uri, [
                    "x-riap-ua" => "Phinci",
                    "x-riap-args-j-" => '[]',
                ]],
                rreq      => undef,
                ct        => 'application/json',
                content   => qr/args.+must.+hash/i,
            },
        ],
    );
    test_ParseRequest_middleware(
        name => "php_clients_ua_re doesn't match",
        args => {deconfuse_php_clients=>1, php_clients_ua_re=>'foo'},
        requests => [
            {
                args      => [GET => $uri, [
                    "x-riap-ua" => "Phinci",
                    "x-riap-args-j-" => '[]',
                ]],
                rreq      => undef,
                ct        => 'application/json',
                content   => qr/args.+must.+hash/i,
            },
        ],
    );
    test_ParseRequest_middleware(
        name => "enabled",
        args => {},
        requests => [
            {
                name      => 'args [] converted to {}',
                args      => [GET => $uri, [
                    "x-riap-ua" => "Phinci",
                    "x-riap-args-j-" => '[]',
                ]],
                rreq      => {%cr, args=>{}},
            },
            {
                name      => 'args [1] not converted to {}',
                args      => [GET => $uri, [
                    "x-riap-ua" => "Phinci",
                    "x-riap-args-j-" => '[1]',
                ]],
                rreq      => undef,
                ct        => 'application/json',
                content   => qr/args.+must.+hash/i,
            },

            {
                name      => 'arg a {} converted to []',
                args      => [GET => $uri, [
                    "x-riap-ua" => "Phinci",
                    "x-riap-args-j-" => '{"a":{}}',
                ]],
                rreq      => {%cr, args=>{a=>[]}},
            },
            {
                name      => 'arg a 1 not converted to []',
                args      => [GET => $uri, [
                    "x-riap-ua" => "Phinci",
                    "x-riap-args-j-" => '{"a":1}',
                ]],
                rreq      => {%cr, args=>{a=>1}},
            },

            {
                name      => 'arg h [] converted to {}',
                args      => [GET => $uri, [
                    "x-riap-ua" => "Phinci",
                    "x-riap-args-j-" => '{"h":[]}',
                ]],
                rreq      => {%cr, args=>{h=>{}}},
            },
            {
                name      => 'arg h 1 not converted to {}',
                args      => [GET => $uri, [
                    "x-riap-ua" => "Phinci",
                    "x-riap-args-j-" => '{"h":1}',
                ]],
                rreq      => {%cr, args=>{h=>1}},
            },

            {
                name      => 'arg b [] not converted to {}',
                args      => [GET => $uri, [
                    "x-riap-ua" => "Phinci",
                    "x-riap-args-j-" => '{"b":[]}',
                ]],
                rreq      => {%cr, args=>{b=>[]}},
            },
            {
                name      => 'arg b {} not converted to []',
                args      => [GET => $uri, [
                    "x-riap-ua" => "Phinci",
                    "x-riap-args-j-" => '{"b":{}}',
                ]],
                rreq      => {%cr, args=>{b=>{}}},
            },
            {
                name      => 'arg b 1 not converted to {}',
                args      => [GET => $uri, [
                    "x-riap-ua" => "Phinci",
                    "x-riap-args-j-" => '{"b":1}',
                ]],
                rreq      => {%cr, args=>{b=>1}},
            },
        ],
    );
};

done_testing;

sub test_ParseRequest_middleware {
    my %args = @_;
    my $rreq;

    # if $rr is undef it means ParseRequest dies/bails and we do not get to the
    # app

    my $app = builder {
        enable sub {
            my $app = shift;
            sub { my $env = shift; $rreq = undef; $app->($env) },
        };

        enable "PeriAHS::ParseRequest", %{$args{args}};

        sub {
            my $env = shift;
            $rreq = $env->{"riap.request"};
            return [
                200,
                ['Content-Type' => 'text/plain'],
                ['Success']
            ];
        };
    };

    test_psgi app => $app, client => sub {
        my $cb = shift;

        subtest $args{name} => sub {
            for my $test (@{$args{requests}}) {
                subtest $test->{name} => sub {
                    my $res = $cb->(HTTP::Request->new(@{$test->{args}}));
                    #diag $res->as_string;

                    is($res->code, $test->{status} // 200, "status")
                        or diag $res->as_string;

                    if (exists $test->{rreq}) {
                        if ($rreq) {
                            $rreq->{uri} = "$rreq->{uri}"; # to ease comparison
                        }
                        is_deeply($rreq, $test->{rreq}, "rreq")
                            or diag explain $rreq;
                    }

                    is($res->header('Content-Type'),
                       $test->{ct} // 'text/plain', "ct");

                    if ($test->{content}) {
                        if (ref($test->{content}) eq 'Regexp') {
                            like($res->content, $test->{content},
                                 "content (re)") or diag $res->content;
                        } else {
                            is($res->content, $>{content}, "content");
                        }
                    } else {
                        is($res->content, "Success", "default content (app)");
                    }

                    done_testing;
                };
            }
            done_testing;
        };

    };
}
