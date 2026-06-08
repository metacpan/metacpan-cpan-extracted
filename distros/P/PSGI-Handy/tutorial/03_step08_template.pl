#!/usr/bin/perl
use 5.00503;
use strict;
BEGIN { if ($] < 5.006 && !defined(&warnings::import)) { $INC{'warnings.pm'} = 'stub'; eval 'package warnings; sub import {}' } }
use warnings; local $^W = 1;

use PSGI::Handy;
use HTTP::Handy;
use HP::Handy;

# View: HP::Handy reads templates from the 'templates' directory.
# HP::Handy exposes render_file()/render_string(), not the render() method
# that PSGI::Handy::Context->render() expects, so it is injected through a
# CODE renderer that maps a template name to render_file().
my $hp = HP::Handy->new( template_dir => 'templates', auto_escape => 1 );
my $renderer = sub {
    my ($name, $vars) = @_;
    return $hp->render_file($name, $vars);
};

my $app = PSGI::Handy->new( renderer => $renderer );

$app->get('/', sub {
    my $c = shift;
    # Render templates/step08.html (no variables passed).
    return $c->render('step08.html');
});

my $psgi_app = $app->to_app;
print "Starting server on http://127.0.0.1:8080/ (Step 8: Static Template)\n";
HTTP::Handy->run(app => $psgi_app, host => '127.0.0.1', port => 8080);
