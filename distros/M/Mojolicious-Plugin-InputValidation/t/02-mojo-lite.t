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
            bar => iv_int,
            baz => iv_word,
        }
    }));
};

my $web = Test::Mojo->new;

$web->post_ok('/' => json => { foo => { bar => 42, baz => 'hello' } })
    ->content_is('');
$web->post_ok('/' => json => { foo => { bar => 42, baz => 'hell-' } })
    ->content_is("Value 'hell-' does not match word characters only at path /foo/baz");

done_testing;
