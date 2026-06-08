#!/usr/bin/perl
use 5.00503;
use strict;
BEGIN { if ($] < 5.006 && !defined(&warnings::import)) { $INC{'warnings.pm'} = 'stub'; eval 'package warnings; sub import {}' } }
use warnings; local $^W = 1;

use PSGI::Handy;
use HTTP::Handy;

my $app = PSGI::Handy->new();

# Return "<a>." as HTML (text/html) for the root path.
$app->get('/', sub {
    my $c = shift;
    return $c->html('<a>.');
});

my $psgi_app = $app->to_app;
print "Starting server on http://127.0.0.1:8080/ (Step 2: HTML)\n";
HTTP::Handy->run(app => $psgi_app, host => '127.0.0.1', port => 8080);
