#!/usr/bin/perl
use 5.00503;
use strict;
BEGIN { if ($] < 5.006 && !defined(&warnings::import)) { $INC{'warnings.pm'} = 'stub'; eval 'package warnings; sub import {}' } }
use warnings; local $^W = 1;

use PSGI::Handy;
use HTTP::Handy;
use HP::Handy;

# Inject HP::Handy through a CODE renderer (see Step 8 for the reason).
my $hp = HP::Handy->new( template_dir => 'templates', auto_escape => 1 );
my $renderer = sub {
    my ($name, $vars) = @_;
    return $hp->render_file($name, $vars);
};

my $app = PSGI::Handy->new( renderer => $renderer );

$app->get('/', sub {
    my $c = shift;
    my $time = scalar localtime();

    # Pass variables to the template as a hash reference.
    return $c->render('step09.html', { current_time => $time });
});

my $psgi_app = $app->to_app;
print "Starting server on http://127.0.0.1:8080/ (Step 9: Dynamic Template)\n";
HTTP::Handy->run(app => $psgi_app, host => '127.0.0.1', port => 8080);
