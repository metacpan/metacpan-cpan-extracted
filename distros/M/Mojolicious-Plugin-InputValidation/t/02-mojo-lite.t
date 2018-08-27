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
        foo => {
            bar  => iv_int,
            baz  => iv_word,
            quux => iv_float(optional => 1),
        }
    }));
};

my $web = Test::Mojo->new;

$web->post_ok('/' => json => { foo => { bar => 42, baz => 'hello' } })
    ->content_is('');
$web->post_ok('/' => json => { foo => { bar => 42, baz => 'hell-' } })
    ->content_is("Value 'hell-' does not match word characters only at path /foo/baz");
$web->post_ok('/' => json => { foo => { bar => 42, baz => 'hello', quux => '' } })
    ->content_is("Value '' is not a float at path /foo/quux");
$web->post_ok('/' => json => { foo => { bar => 42, baz => 'hello', quux => '3.14' } })
    ->content_is('');

done_testing;
