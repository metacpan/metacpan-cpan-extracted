use Mojo::Base -strict;
use Mojolicious::Lite;

use Test::More;
use Test::Mojo;

use TestHelper;

plugin 'FormFields';

post '/single_filter' => sub {
    my $c = shift;
    $c->field('name')->filter('uc');
    $c->valid;			# trigger filter
    $c->render(text => $c->param('name'));
};

post '/scoped_single_filter' => sub {
    my $c = shift;
    my $user = $c->fields('user');
    $user->filter(name => 'uc');
    $c->valid;
    $c->render(text => $c->param('user.name'));
};

post '/multiple_filters' => sub {
    my $c = shift;
    $c->field('name')->filter('uc', 'strip')->filter('trim');
    $c->valid;
    $c->render(text => $c->param('name'));
};

post '/scoped_multiple_filters' => sub {
    my $c = shift;
    my $user = $c->fields('user');
    $user->filter('name', 'uc', 'strip')->filter('trim');
    $c->valid;
    $c->render(text => $c->param('user.name'));
};

post '/custom_filter' => sub {
    my $c = shift;
    $c->field('name')->filter(sub { chop $_[0]; $_[0] });
    $c->valid;
    $c->render(text => $c->param('name'));
};

post '/scoped_custom_filter' => sub {
    my $c = shift;
    my $user = $c->fields('user');
    $user->filter(name => sub { chop $_[0]; $_[0] });
    $user->valid;
    $c->render(text => $c->param('user.name'));
};

my $t = Test::Mojo->new;
$t->post_ok('/single_filter',
            form => { 'name' => 'fofinha' })->status_is(200)->content_is('FOFINHA');

$t->post_ok('/scoped_single_filter',
            form => { 'user.name' => 'fofinha' })->status_is(200)->content_is('FOFINHA');

$t->post_ok('/multiple_filters',
            form => { 'name' => ' a   b     c   ' })->status_is(200)->content_is('A B C');

$t->post_ok('/scoped_multiple_filters',
            form => { 'user.name' => ' a   b     c   ' })->status_is(200)->content_is('A B C');

$t->post_ok('/custom_filter',
            form => { 'name' => 'foo!' })->status_is(200)->content_is('foo');

$t->post_ok('/scoped_custom_filter',
            form => { 'user.name' => 'foo!' })->status_is(200)->content_is('foo');

done_testing();
