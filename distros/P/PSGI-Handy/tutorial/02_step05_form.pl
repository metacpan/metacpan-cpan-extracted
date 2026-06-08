#!/usr/bin/perl
use 5.00503;
use strict;
BEGIN { if ($] < 5.006 && !defined(&warnings::import)) { $INC{'warnings.pm'} = 'stub'; eval 'package warnings; sub import {}' } }
use warnings; local $^W = 1;

use PSGI::Handy;
use HTTP::Handy;

my $app = PSGI::Handy->new();

# Show an input form on the root path.
$app->get('/', sub {
    my $c = shift;
    my $html = <<'HTML';
<!DOCTYPE html>
<html>
<head><title>Step 5</title></head>
<body>
    <h1>Simple Form</h1>
    <form action="/echo" method="POST">
        <input type="text" name="message" value="">
        <input type="submit" value="Send">
    </form>
</body>
</html>
HTML
    return $c->html($html);
});

my $psgi_app = $app->to_app;
print "Starting server on http://127.0.0.1:8080/ (Step 5: Form Display)\n";
HTTP::Handy->run(app => $psgi_app, host => '127.0.0.1', port => 8080);
