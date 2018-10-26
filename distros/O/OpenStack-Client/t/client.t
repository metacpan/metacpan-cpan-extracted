#! /usr/bin/perl
#
# Copyright (c) 2018 cPanel, L.L.C.
# All rights reserved.
# http://cpanel.net/
#
# Distributed under the terms of the MIT license.  See the LICENSE file for
# further details.
#

use strict;
use warnings;

use OpenStack::Client ();

use JSON ();

use lib 't/lib';
use Test::OpenStack::Client ();

use Test::More qw(no_plan);
use Test::Exception;

{
    throws_ok {
        OpenStack::Client->new
    } qr/No API endpoint provided/, "OpenStack::Client->new() dies when no API endpoint URI is provided";

    lives_ok {
        OpenStack::Client->new('http://foo.bar/')
    } "OpenStack::Client->new() doesn't die when API endpoint is provided";
}

{
    my $endpoint = 'http://foo.bar/';
    my $token    = {
        'foo' => 'bar'
    };

    my %tests = (
        'foobar'     => "${endpoint}foobar",
        '/foobar'    => "${endpoint}foobar",
        'foobar/baz' => "${endpoint}foobar/baz"
    );

    my $client = OpenStack::Client->new($endpoint,
        'token' => $token
    );

    foreach my $input (sort keys %tests) {
        my $expected = $tests{$input};

        is($client->uri($input) => $expected, "\$client->uri() yields '$expected' for '$input'");
    }

    is($client->endpoint => $endpoint, "\$client->endpoint() returns original HTTP endpoint URI");
    is($client->token    => $token,    "\$client->token() returns original token object");
}

Test::OpenStack::Client->run_client_tests({
    'responses' => [{
        'content' => JSON::encode_json({
            'foo' => 'bar'
        })
    }],

    'test' => sub {
        my ($client) = @_;

        my $content;

        lives_ok {
            $content = $client->call('GET' => '/foo');
        } "\$client->call() doesn't die on a well-instantiated client";

        is($content->{'foo'} => 'bar', "Response contains expected result");
    }
}, {
    'test' => sub {
        is(shift->call('GET' => '/foo') => '', "Empty response contains expected empty result");
    }
}, {
    'responses' => [{
        'code'    =>  420,
        'content' => '420 Baked',
        'headers' => {
            'content-type' => 'text/plain'
        }
    }],

    'test' => sub {
        my ($client) = @_;

        throws_ok {
            $client->call('GET' => '/foo')
        } qr/420 Baked/, "\$client->call() dies when 400 error is returned by service";
    }
}, {
    'test' => sub {
        my ($client, $ua) = @_;

        my $content = {
            'bar' => 'baz'
        };

        $client->call('GET' => '/foo', $content);

        my $got      = $ua->{'requests'}->[0]->content;
        my $expected = JSON::encode_json($content);

        is_deeply($got => $expected, "\$client decodes JSON response bodies");
    }
}, {
    'responses' => [{
        'code'    => 520,
        'content' => 'Temporarily out of fucks to give',
        'headers' => {
            'Content-Type' => 'text/plain'
        }
    }],

    'test' => sub {
        my ($client) = @_;

        throws_ok {
            $client->call('GET' => '/foo');
        } qr/Temporarily out of fucks to give/, "\$client->call() dies with response body when 400 or 500 status is raised";
    }
}, {
    'responses' => [{
        'code'    => 320,
        'content' => 'Do whatever you want',
        'headers' => {
            'Content-Type' => 'text/plain'
        }
    }],

    'test' => sub {
        my ($client) = @_;

        my $got      = $client->call('GET' => '/foo');
        my $expected = 'Do whatever you want';

        is($got => $expected, "\$client->call() returns message body for plain text, non-error responses");
    }
}, {
    'responses' => [{
        'code'    => 504,
        'content' => undef
    }],

    'test' => sub {
        my ($client) = @_;

        throws_ok {
            $client->call('GET' => '/foo');
        } qr/504 Unknown error/, "\$client->call() dies with an unknown error when no response body is provided";
    }
}, {
    'test' => sub {
        my ($client, $ua) = @_;

        my @tests = (
            ['/foo' => { }, "no parameters"],

            ['/foo?bar=baz' => {
                'bar' => 'baz'
            }, "a single parameter"],

            ['/foo?bar=baz&meow=cats' => {
                'bar'  => 'baz',
                'meow' => 'cats'
            }, "multiple parameters"],

            ['/foo?bar=baz&tiny%20kittens=are%20awesome' => {
                'bar'          => 'baz',
                'tiny kittens' => 'are awesome'
            }, "parameters needing URI encoding"]
        );

        my $i = 0;
        my $prefix = 'http://foo.bar';

        foreach my $test (@tests) {
            my ($expected_suffix, $input, $message) = @{$test};

            my $expected = "${prefix}${expected_suffix}";

            $client->get('/foo', %{$input});

            my $got = $ua->{'requests'}->[$i++]->{'path'};

            is($got => $expected, "\$client->get() encodes with $message");
        }
    }
}, {
    'test' => sub {
        my ($client, $ua) = @_;

        $client->get('/foo?bar=baz',
            'meow' => 'cats'
        );

        my $prefix   = 'http://foo.bar';
        my $got      = $ua->{'requests'}->[0]->{'path'};
        my $expected = "${prefix}/foo?bar=baz&meow=cats";

        is($got => $expected, "\$client->get() handles request paths with arguments already present");
    }
}, {
    'responses' => [{
        'content' => JSON::encode_json({
            'payload' => ['foo', 'bar', 'baz']
        })
    }],

    'test' => sub {
        my ($client) = @_;

        my $got      = [];
        my $expected = ['foo', 'bar', 'baz'];

        $client->each('/foo', sub {
            my ($result) = @_;

            push @{$got}, @{$result->{'payload'}};
        });

        is_deeply($got => $expected, "\$client->each() calls a callback for each paginated result");

        throws_ok {
            $client->each();
        } qr/Invalid number of arguments/, "\$client->each() dies when too few arguments are passed";

        throws_ok {
            $client->each('/foo', {}, sub {}, 'foo');
        } qr/Invalid number of arguments/, "\$client->each() dies when too many arguments are passed";
    }
}, {
    'responses' => [{
        'content' => JSON::encode_json({})
    }],

    'test' => sub {
        my ($client, $ua) = @_;

        lives_ok {
            $client->each('/foo', {
                'bar' => 'baz'
            }, sub {});
        } "\$client->each() succeeds when passed GET parameters";

        my $got      = $ua->{'requests'}->[0]->{'path'};
        my $expected = "http://foo.bar/foo?bar=baz";

        is($got => $expected, "\$client->each() handles GET parameters properly");
    }
}, {
    'responses' => [{
        'content' => JSON::encode_json({
            'items' => [{
                'foo'  => 'bar'
            }],

            'next' => '/foo/1'
        })
    }, {
        'content' => JSON::encode_json({
            'items' => [{
                'baz' => 'boo'
            }],

            'next' => '/foo/2'
        })
    }, {
        'content' => JSON::encode_json({
            'items' => [{
                'meow' => 'cats'
            }]
        })
    }],

    'test' => sub {
        my ($client) = @_;

        my @responses;

        $client->every('/foo', 'items', sub {
            my ($item) = @_;

            push @responses, $item;
        });

        is(scalar @responses => 3, "\$client->every() callback is called once per item across paginations");

        my @expected = (
            {'foo'  => 'bar'},
            {'baz'  => 'boo'},
            {'meow' => 'cats'}
        );

        is_deeply(\@responses => \@expected, "\$client->every() decodes response bodies as expected");
    }
}, {
    'responses' => [{
        'content' => JSON::encode_json({
            'items' => ['foo', 'bar', 'baz']
        })
    }],

    'test' => sub {
        my ($client, $ua) = @_;

        lives_ok {
            $client->every('/foo', 'items', {
                'meow' => 'cats'
            }, sub {});
        } "\$client->every() won't die if passed GET parameters";

        my $got      = $ua->{'requests'}->[0]->{'path'};
        my $expected = "http://foo.bar/foo?meow=cats";

        is($got => $expected, "\$client->every() passes along GET parameters fine");
    }
}, {
    'responses' => [{
        'content' => '{}'
    }],

    'test' => sub {
        my ($client) = @_;

        throws_ok {
            $client->every('/foo', 'items', sub {})
        } qr/Response from \/foo does not contain attribute/, "\$client->every() dies when responses lack attribute corresponding to result set";

        throws_ok {
            $client->every('/foo', 'items', sub {}, {}, 'bleh');
        } qr/Invalid number of arguments/, "\$client->every() will complain if argument count is too much";

        throws_ok {
            $client->every('/foo', 'items');
        } qr/Invalid number of arguments/, "\$client->every() will complain if argument count is too little";
    }
}, {
    'responses' => [{
        'content' => JSON::encode_json({
            'items' => ['foo', 'bar', 'baz'],
            'next'  => '/foo/2'
        })
    }, {
        'content' => JSON::encode_json({
            'items' => ['eins', 'zwei', 'drei']
        })
    }],

    'test' => sub {
        my ($client) = @_;

        my @got;
        my @expected = qw(foo bar baz eins zwei drei);

        lives_ok {
            @got = $client->all('/foo', 'items');
        } "\$client->all() doesn't die in ordinary circumstances";

        is_deeply(\@got => \@expected, "\$client->all() handles result sets in the appropriate manner");
    }
}, {
    'responses' => [{
        'content' => JSON::encode_json({})
    }],

    'test' => sub {
        my ($client, $ua) = @_;

        my $sub = sub {};

        lives_ok {
            $client->call('PUT', {}, '/foo', $sub);
        } "\$client->call() doesn't die when passed a CODE ref request body";

        is $ua->{'requests'}->[0]->{'content'} => $sub, "\$client->call() passes CODE ref request body appropriately";
    }
}, {
    'responses' => [{
        'content' => JSON::encode_json({})
    }],

    'test' => sub {
        my ($client, $ua) = @_;

        my $called = 0;

        lives_ok {
            $client->call({
                'method' => 'PUT',
                'path'   => '/foo',
                'handler' => sub {
                    $called = 1;
                }
            });
        } "\$client->call() doesn't die when passed a CODE ref response handler";
    }
}, {
    'responses' => [{
        'content' => JSON::encode_json({
            'items' => []
        })
    }],

    'test' => sub {
        my ($client, $ua) = @_;

        lives_ok {
            $client->all('/foo', 'items', {
                'meow' => 'cats'
            });
        } "\$client->all() doesn't die when provided GET parameters";

        my $got      = $ua->{'requests'}->[0]->{'path'};
        my $expected = "http://foo.bar/foo?meow=cats";

        is($got => $expected, "\$client->all() passes GET parameters on expectedly");
    }
}, {
    'responses' => [{
        'content' => JSON::encode_json({
            'bar' => 'baz'
        })
    }, {
        'content' => JSON::encode_json({
            'meow' => 'cats'
        })
    }],

    'test' => sub {
        my ($client, $ua) = @_;

        my @tests = (
            ['put',  'PUT'  => {'bar'  => 'baz'}],
            ['post', 'POST' => {'meow' => 'cats'}]
        );

        my @got_responses;

        lives_ok {
            push @got_responses, $client->put('/foo', {'bar' => 'baz'});
        } "\$client->put() doesn't die when called normally";

        lives_ok {
            push @got_responses, $client->post('/foo', {'meow' => 'cats'});
        } "\$client->post() doesn't die when called normally";

        lives_ok {
            $client->delete('/foo/1');
        } "\$client->delete() doesn't die when called normally";

        my $i = 0;

        foreach my $test (@tests) {
            my ($name, $expected_method, $expected_response) = @{$test};

            my $got_method   = $ua->{'requests'}->[$i]->method;
            my $got_response = $got_responses[$i];

            is(       $got_method   => $expected_method,   "\$client->$name() issues call with appropriate HTTP method");
            is_deeply($got_response => $expected_response, "\$client->$name() decodes response body appropriately");

            $i++;
        }
    }
}, {
    'test' => sub {
        my ($client, $ua) = @_;

        no warnings qw/redefine/;
        my $orig_request = \&Test::OpenStack::Client::UserAgent::request;

        my $req_headers;

        local *Test::OpenStack::Client::UserAgent::request = sub {
          my ($self, $request) = @_;
          # save headers for easy comparing 
          $req_headers = $request->{'headers'};
          return $orig_request->($self, $request);
        };

        my @got_responses = ();
        my $headers = {
            'content-type'    => 'foobar', 'x-grumpy-cat' => '0 ftg',
        };

        my $response;
        lives_ok {
            $response = $client->call('PATCH', $headers, '/foo', {'bar' => 'baz'});
        } "\$client->call() doesn't die when called normally with 4 arguments (including \$headers)";
        
        # expected/defaults for comparing 
        $headers->{'accept-encoding'} = 'identity, gzip, deflate, compress';
        $headers->{'content-length'} = 0;
        $headers->{'accept'} = 'application/json, text/plain';

        is_deeply $req_headers => $headers, "4 argument form of \$client->call() sets headers as expected.";

        delete $headers->{'content-length'};
        delete $headers->{'x-grumpy-cat'};

        # change defaults for comparing 
        $headers->{'accept-encoding'} = 'I have no idea what I am doing.';
        $headers->{'accept'} = 'The honeybadger accepts it all!';
        $headers->{'content-type'} = 'application/openstack-images-v2.1-json-patch'; 
        $headers->{'x-ftg'} = 0;

        $req_headers = {};
        lives_ok {
            $response = $client->call('PATCH', $headers, '/foo', {'bar' => 'baz'});
        } "\$client->call() doesn't die when called normally with 4 arguments (including \$headers)";

        # add this expected header for comparing
        $headers->{'content-length'} = 0;

        is_deeply $req_headers => $headers, "4 argument form of \$client->call() sets headers as expected.";
    }
});
