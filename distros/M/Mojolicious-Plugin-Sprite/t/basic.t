
use lib 'lib';
use Mojo::Base -strict;
use Test::More tests => 9;

use Mojolicious::Lite;
use Test::Mojo;

plugin 'Sprite' => {
    config => {
        'icons/img1.gif' => '.spr-icons-img1',
        'icons/img2.gif' => '.spr-icons-img2',
    },
    css_url => '/css/sprite.css',
};

get '/' => sub {
    my $self = shift;
    $self->render('index');
};

my $t = Test::Mojo->new;

$t->get_ok('/')->status_is(200)->content_like(qr|<link rel="stylesheet" href="/css/sprite.css">|);

$t->get_ok('/')->status_is(200)->content_like(qr|<span class="spr spr-icons-img1"> </span>|);

$t->get_ok('/')->status_is(200)->content_like(qr|<img src="icons/img3.gif" alt="">|);

__DATA__
@@index.html.ep
<html>
    <head><title></title></head>
    <body>
        <p>Test</p>
        <img src="icons/img1.gif" alt="">
        <img src="icons/img3.gif" alt="">
    </body>
</html>
