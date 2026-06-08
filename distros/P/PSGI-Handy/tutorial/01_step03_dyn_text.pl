#!/usr/bin/perl
use 5.00503;
use strict;
BEGIN { if ($] < 5.006 && !defined(&warnings::import)) { $INC{'warnings.pm'} = 'stub'; eval 'package warnings; sub import {}' } }
use warnings; local $^W = 1;

use PSGI::Handy;
use HTTP::Handy;

my $app = PSGI::Handy->new();

# Read the current time on each request and return it as plain text.
$app->get('/', sub {
    my $c = shift;
    my $time = scalar localtime();
    return $c->text("Current Time: $time");
});

my $psgi_app = $app->to_app;
print "Starting server on http://127.0.0.1:8080/ (Step 3: Dynamic Text)\n";
HTTP::Handy->run(app => $psgi_app, host => '127.0.0.1', port => 8080);
