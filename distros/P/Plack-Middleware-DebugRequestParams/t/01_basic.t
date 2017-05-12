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
$app = Plack::Middleware::DebugRequestParams->wrap($app);

filters {
    method   => [qw(chomp)],
    params   => [qw(eval)],
    expected => [qw(chomp)],
};

test_psgi $app, sub {
    my $cb  = shift;
    for my $block (blocks) {
        my $stderr = capture_stderr {
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
/
--- method
GET
--- expected

===
--- path_info
/?foo=bar
--- method
GET
--- expected
.-------------------.
| Parameter | Value |
+-----------+-------+
| foo       | bar   |
'-----------+-------'

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
/
--- method
POST
--- params
+{ foo => 'bar' }
--- expected
.-------------------.
| Parameter | Value |
+-----------+-------+
| foo       | bar   |
'-----------+-------'

===
--- path_info
/?author=%E3%83%A9%E3%83%AA%E3%83%BC%E3%83%BB%E3%82%A6%E3%82%A9%E3%83%BC%E3%83%AB
--- method
GET
--- expected
.------------------------------.
| Parameter | Value            |
+-----------+------------------+
| author    | ラリー・ウォール |
'-----------+------------------'

