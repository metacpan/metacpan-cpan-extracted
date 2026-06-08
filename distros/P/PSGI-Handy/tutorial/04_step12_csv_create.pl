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
    return $c->render('step12_form.html');
});

$app->post('/add', sub {
    my $c = shift;
    my $id   = $c->param('id');
    my $name = $c->param('name');
    my $age  = $c->param('age');
    $id   = defined $id   ? $id   : '';
    $name = defined $name ? $name : '';
    $age  = defined $age  ? $age  : '';

    # Open in append mode.
    if (open(OUT, ">> data.csv")) {
        print OUT "$id,$name,$age\n";
        close(OUT);
    }

    # Re-render via a template so the value is auto-escaped.
    return $c->render('step12_result.html', { name => $name });
});

my $psgi_app = $app->to_app;
print "Starting server on http://127.0.0.1:8080/ (Step 12: Create)\n";
HTTP::Handy->run(app => $psgi_app, host => '127.0.0.1', port => 8080);
