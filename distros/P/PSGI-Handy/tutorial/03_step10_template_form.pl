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

# Show the form.
$app->get('/', sub {
    my $c = shift;
    return $c->render('step10_form.html');
});

# Receive the submitted data and show the result.
$app->post('/echo', sub {
    my $c = shift;

    my $message = $c->param('message');
    $message = defined $message ? $message : '';

    return $c->render('step10_result.html', { message => $message });
});

my $psgi_app = $app->to_app;
print "Starting server on http://127.0.0.1:8080/ (Step 10: Template Form)\n";
HTTP::Handy->run(app => $psgi_app, host => '127.0.0.1', port => 8080);
