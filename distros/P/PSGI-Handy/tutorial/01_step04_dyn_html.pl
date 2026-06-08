#!/usr/bin/perl
use 5.00503;
use strict;
BEGIN { if ($] < 5.006 && !defined(&warnings::import)) { $INC{'warnings.pm'} = 'stub'; eval 'package warnings; sub import {}' } }
use warnings; local $^W = 1;

use PSGI::Handy;
use HTTP::Handy;

my $app = PSGI::Handy->new();

# Read the current time on each request and return it as structured HTML.
$app->get('/', sub {
    my $c = shift;
    my $time = scalar localtime();

    my $html = "<h1>Current Time</h1>\n";
    $html   .= "<p>The time is now: <strong>$time</strong></p>\n";

    return $c->html($html);
});

my $psgi_app = $app->to_app;
print "Starting server on http://127.0.0.1:8080/ (Step 4: Dynamic HTML)\n";
HTTP::Handy->run(app => $psgi_app, host => '127.0.0.1', port => 8080);
