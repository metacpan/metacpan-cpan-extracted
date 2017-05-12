#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Plack::Builder;
use Plack::Test;
use HTTP::Request::Common;

my $app = sub {['200', ['Content-Type' => 'text/plain'], ['Secret Agent Man']]};

my $test = Plack::Test->create(
    builder {
        enable 'Plack::Middleware::P3P';
        $app;
    }
);
my $headers = $test->request(GET '/')->headers;
is($headers->header('P3P'), 'CP="CAO PSA OUR"', 'Standard policies');

$test = Plack::Test->create(
    builder {
        enable 'Plack::Middleware::P3P', policies => 'CIA FBI NSA';
        $app;
    }
);
$headers = $test->request(GET '/')->headers;
is($headers->header('P3P'), 'CP="CIA FBI NSA"', 'String policies');

$test = Plack::Test->create(
    builder {
        enable 'Plack::Middleware::P3P', policies => ['CIA', 'FBI', 'NSA'];
        $app;
    }
);
$headers = $test->request(GET '/')->headers;
is($headers->header('P3P'), 'CP="CIA FBI NSA"', 'Array policies');

$app = sub {
    sub {
        my $respond = shift;
        my $writer = $respond->(['200', ['Content-Type' => 'text/plain']]);
        $writer->write('Secret');
        $writer->write('Agent');
        $writer->write('Man');
        $writer->close;
    }
};

$test = Plack::Test->create(
    builder {
        enable 'Plack::Middleware::P3P';
        $app;
    }
);
$headers = $test->request(GET '/')->headers;
is($headers->header('P3P'), 'CP="CAO PSA OUR"', 'Streaming standard policies');

$test = Plack::Test->create(
    builder {
        enable 'Plack::Middleware::P3P', policies => 'CIA FBI NSA';
        $app;
    }
);
$headers = $test->request(GET '/')->headers;
is($headers->header('P3P'), 'CP="CIA FBI NSA"', 'Streaming string policies');

$test = Plack::Test->create(
    builder {
        enable 'Plack::Middleware::P3P', policies => ['CIA', 'FBI', 'NSA'];
        $app;
    }
);
$headers = $test->request(GET '/')->headers;
is($headers->header('P3P'), 'CP="CIA FBI NSA"', 'Streaming array policies');

done_testing;
