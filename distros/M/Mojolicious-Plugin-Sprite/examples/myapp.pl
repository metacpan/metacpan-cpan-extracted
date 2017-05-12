#!/usr/bin/env perl

use FindBin;
use lib "$FindBin::Bin/../lib";
use Mojolicious::Lite;

plugin 'Sprite' => {
    config  => "$FindBin::Bin/sprite.xml",
    css_url => "/css/sprite.css"
};

get '/' => sub {
    my $self = shift;
    $self->render('index');
};

app->start;
