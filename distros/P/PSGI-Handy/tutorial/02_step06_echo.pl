#!/usr/bin/perl
use 5.00503;
use strict;
BEGIN { if ($] < 5.006 && !defined(&warnings::import)) { $INC{'warnings.pm'} = 'stub'; eval 'package warnings; sub import {}' } }
use warnings; local $^W = 1;

use PSGI::Handy;
use HTTP::Handy;

my $app = PSGI::Handy->new();

# Show the form (GET request).
$app->get('/', sub {
    my $c = shift;
    my $html = <<'HTML';
<!DOCTYPE html>
<html>
<head><title>Step 6</title></head>
<body>
    <h1>Echo Form</h1>
    <form action="/echo" method="POST">
        <input type="text" name="message" value="">
        <input type="submit" value="Send">
    </form>
</body>
</html>
HTML
    return $c->html($html);
});

# Receive the form data and echo it back (POST request).
$app->post('/echo', sub {
    my $c = shift;

    # Read the value of the field name="message".
    my $message = $c->param('message');
    $message = defined $message ? $message : '';

    # Embed the received string into the HTML response.
    my $html = <<"HTML";
<!DOCTYPE html>
<html>
<head><title>Echo Result</title></head>
<body>
    <h1>Echo Result</h1>
    <p>You typed: <strong>$message</strong></p>
    <p><a href="/">Back</a></p>
</body>
</html>
HTML
    return $c->html($html);
});

my $psgi_app = $app->to_app;
print "Starting server on http://127.0.0.1:8080/ (Step 6: Echo)\n";
HTTP::Handy->run(app => $psgi_app, host => '127.0.0.1', port => 8080);
