#!/usr/bin/perl
use 5.00503;
use strict;
BEGIN { if ($] < 5.006 && !defined(&warnings::import)) { $INC{'warnings.pm'} = 'stub'; eval 'package warnings; sub import {}' } }
use warnings; local $^W = 1;

use PSGI::Handy;
use HTTP::Handy;

my $app = PSGI::Handy->new();

# Show the login form.
$app->get('/', sub {
    my $c = shift;
    my $html = <<'HTML';
<!DOCTYPE html>
<html>
<head><title>Step 7</title></head>
<body>
    <h1>Login Form</h1>
    <form action="/login" method="POST">
        Username: <input type="text" name="username" value=""><br><br>
        Password: <input type="password" name="password" value=""><br><br>
        <input type="submit" value="Login">
    </form>
</body>
</html>
HTML
    return $c->html($html);
});

# Branch on the credentials.
$app->post('/login', sub {
    my $c = shift;

    my $username = $c->param('username');
    my $password = $c->param('password');
    $username = defined $username ? $username : '';
    $password = defined $password ? $password : '';

    # Succeed only when username is "admin" and password is "secret".
    if ($username eq 'admin' && $password eq 'secret') {
        my $html = <<"HTML";
<!DOCTYPE html>
<html>
<head><title>Success</title></head>
<body>
    <h1>Page A: Login Success</h1>
    <p>Welcome, $username!</p>
    <a href="/">Back to Form</a>
</body>
</html>
HTML
        return $c->html($html);
    }
    else {
        my $html = <<'HTML';
<!DOCTYPE html>
<html>
<head><title>Failed</title></head>
<body>
    <h1>Page B: Login Failed</h1>
    <p>Invalid username or password.</p>
    <a href="/">Try Again</a>
</body>
</html>
HTML
        return $c->html($html);
    }
});

my $psgi_app = $app->to_app;
print "Starting server on http://127.0.0.1:8080/ (Step 7: Login Branch)\n";
HTTP::Handy->run(app => $psgi_app, host => '127.0.0.1', port => 8080);
