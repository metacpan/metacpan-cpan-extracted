#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Base::Less;
use Test::Differences qw(eq_or_diff);
use HTTP::Request::Common qw(GET POST);
use Plack::Test qw(test_psgi);
use Capture::Tiny qw(capture_stderr);
use Plack::Middleware::DebugRequestParams;

my $app = sub { [ 200, ["Content-Type" => "text/plain"], ['200 OK'] ] };
$app = Plack::Middleware::DebugRequestParams->wrap($app,
    ignore_path => qr{^/static/},
);

filters {
    method   => [qw(chomp)],
    params   => [qw(eval)],
    expected => [qw(chomp)],
};

test_psgi $app, sub {
    my $cb  = shift;
    for my $block (blocks) {
        my $stderr = capture_stderr {
            my $stderr;
            if ($block->method eq 'POST') {
                $cb->(POST $block->path_info, [%{$block->params}]);
            } else {
                $cb->(GET $block->path_info);
            }
        };
        eq_or_diff $stderr, $block->expected;
    }
};

done_testing;

__DATA__

===
--- path_info
/?foo=bar&foo=foobar
--- method
GET
--- expected
.--------------------.
| Parameter | Value  |
+-----------+--------+
| foo       | bar    |
| foo       | foobar |
'-----------+--------'

===
--- path_info
/static/img/example.jpg?foo=bar&foo=foobar
--- method
GET
--- expected

