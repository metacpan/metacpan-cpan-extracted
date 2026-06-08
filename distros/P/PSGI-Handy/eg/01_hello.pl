######################################################################
#
# 01_hello.pl - the smallest PSGI::Handy application
#
# Run: perl -Ilib eg/01_hello.pl
# Then open http://127.0.0.1:8080/ and /hello/world.
#
# Demonstrates:
#   PSGI::Handy new/get/to_app, Context html/text, path parameter :name
#
######################################################################
use strict;
BEGIN { if ($] < 5.006 && !defined(&warnings::import)) { $INC{'warnings.pm'} = 'stub'; eval 'package warnings; sub import {}' } }
use warnings; local $^W = 1;
BEGIN { pop @INC if $INC[-1] eq '.' }
use FindBin ();
use lib "$FindBin::Bin/../lib";

use PSGI::Handy;
use HTTP::Handy;   # delivery layer (any PSGI server works)

my $app = PSGI::Handy->new;

$app->get('/', sub {
    my $c = shift;
    return $c->html("<!DOCTYPE html>\n<title>PSGI::Handy</title>\n"
                  . "<h1>Hello from PSGI::Handy</h1>\n"
                  . "<p>Try <a href=\"/hello/world\">/hello/world</a>.</p>\n");
});

$app->get('/hello/:name', sub {
    my $c = shift;
    my $name = $c->param('name');
    $name = '' unless defined $name;
    $name =~ s/[<>&]//g;                 # crude escaping for the demo
    return $c->html("<h1>Hello, $name!</h1>\n");
});

$app->get('/health', sub {
    my $c = shift;
    return $c->text("ok\n");
});

my $psgi = $app->to_app;
HTTP::Handy->run(app => $psgi, host => '127.0.0.1', port => 8080);
