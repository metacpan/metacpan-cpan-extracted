#!/usr/bin/env perl

use v5.38;
use Test::More;
use experimental 'class';

use PAGI::FastAPI::Response::HTML;
use Future;
use Future::AsyncAwait;

class MockPagiWriter {
    field $buffer = '';

    async method write ($chunk) {
        $buffer .= $chunk;
    }

    method get_buffer () { return $buffer }
}

class MockContext {
    field $status_code = 200;
    field $headers     = {};

    method status ($code = undef) {
        $status_code = $code if defined $code;
        return $status_code;
    }

    method set_header ($k, $v) {
        $headers->{$k} = $v;
    }

    method get_headers () { return $headers }
}

subtest 'HTML Response Class Formatting' => sub {
    my $c      = MockContext->new();
    my $writer = MockPagiWriter->new();

    my $html = PAGI::FastAPI::Response::HTML->new(
        body    => '<html><body><h1>Test</h1></body></html>',
        status  => 201,
        headers => [ ['x-custom-meta' => 'value123'] ],
    );

    $html->send($c, $writer)->get;

    my $headers = $c->get_headers();

    is($c->status(), 201, 'Status code set correctly');
    is($headers->{'content-type'}, 'text/html; charset=utf-8', 'Content-Type set to HTML UTF-8');
    is($headers->{'x-custom-meta'}, 'value123', 'Custom headers passed');
    is($writer->get_buffer(), '<html><body><h1>Test</h1></body></html>', 'HTML body written to transport');
};

done_testing();
