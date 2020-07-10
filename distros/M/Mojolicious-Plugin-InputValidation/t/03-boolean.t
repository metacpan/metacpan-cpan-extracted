use strict;
use warnings;
use Test::More;
use Test::Mojo;
use lib 'lib';
use Mojolicious::Lite;

plugin 'InputValidation';
use Mojolicious::Plugin::InputValidation;

post '/' => sub {
    my $c = shift;
    $c->render(text => $c->validate_json_request({
        foo => iv_bool,
        bar => iv_bool(empty => 1),
        baz => iv_bool(nillable => 1),
    }));
};

my $web = Test::Mojo->new;

$web->post_ok('/' => { 'Content-Type' => 'application/json' } => '{ "foo": true, "bar": false, "baz": null }')
    ->content_is('');
$web->post_ok('/' => { 'Content-Type' => 'application/json' } => '{ "foo": true, "bar": "", "baz": null }')
    ->content_is('');
$web->post_ok('/' => { 'Content-Type' => 'application/json' } => '{ "foo": true, "bar": null, "baz": false }')
    ->content_is("Value '' is not a boolean at path /bar");
$web->post_ok('/' => { 'Content-Type' => 'application/json' } => '{ "foo": 42, "bar": false, "baz": null }')
    ->content_is("Value '42' is not a boolean at path /foo");

done_testing;
