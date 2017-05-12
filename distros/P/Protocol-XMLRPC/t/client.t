#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 10;

use Protocol::XMLRPC::Client;

Protocol::XMLRPC::Client->new(
    http_req_cb        => sub       { $_[-1]->($_[0], 500, {}, '') })->call(
    'http://empty.com' => 'foo.bar' => sub {
    },
    sub {
        my $self = shift;

        ok($self);
    }
    );

Protocol::XMLRPC::Client->new(
    http_req_cb        => sub       { $_[-1]->($_[0], 500, {}, '') })->call(
    'http://empty.com' => 'foo.bar' => sub {
        is(scalar @_, 1);
    }
    );

Protocol::XMLRPC::Client->new(
    http_req_cb => sub {
        my ($self, $url, $method, $headers, $body, $cb) = @_;

        is($body,
            '<?xml version="1.0"?><methodCall><methodName>foo.bar</methodName><params></params></methodCall>'
        );
        is($headers->{'Host'}, 'empty.com');

        $cb->(
            $self, 200, {},
            '<?xml version="1.0"?><methodResponse><params><param><value>FooBar</value></param></params></methodResponse>'
        );
    }
  )->call(
    'http://empty.com/foo/bar' => 'foo.bar' => sub {
        my ($self, $method_response) = @_;

        ok($method_response);
    }
  );

Protocol::XMLRPC::Client->new(
    http_req_cb => sub {
        my ($self, $url, $method, $headers, $body, $cb) = @_;

        $cb->($self, 400, {}, '');
    }
  )->call(
    '' => 'foo.bar' => sub {
    },
    sub {
        ok($_[0]);
    }
  );

Protocol::XMLRPC::Client->new(
    http_req_cb => sub {
        is($_[4],
            '<?xml version="1.0"?><methodCall><methodName>foo.bar</methodName><params><param><value><i4>1</i4></value></param></params></methodCall>'
        );
    }
)->call('' => 'foo.bar' => [1] => sub { });

Protocol::XMLRPC::Client->new(
    http_req_cb => sub {
        is($_[4],
            '<?xml version="1.0"?><methodCall><methodName>foo.bar</methodName><params><param><value><string>1</string></value></param></params></methodCall>'
        );
    }
  )
  ->call(
    '' => 'foo.bar' => [Protocol::XMLRPC::Value::String->new(1)] => sub { });

Protocol::XMLRPC::Client->new(
    http_req_cb => sub {
        is($_[4],
            '<?xml version="1.0"?><methodCall><methodName>foo.bar</methodName><params><param><value><array><data><value><string>1</string></value></data></array></value></param></params></methodCall>'
        );
    }
  )
  ->call(
    '' => 'foo.bar' => [[Protocol::XMLRPC::Value::String->new(1)]] => sub { }
  );

Protocol::XMLRPC::Client->new(
    http_req_cb => sub {
        is($_[4],
            '<?xml version="1.0"?><methodCall><methodName>foo.bar</methodName><params><param><value><struct><member><name>foo</name><value><string>bar</string></value></member></struct></value></param></params></methodCall>'
        );
    }
)->call('' => 'foo.bar' => [{foo => 'bar'}] => sub { });
