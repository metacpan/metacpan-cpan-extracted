#!/usr/bin/env perl

use lib 'lib';
use Mojolicious::Lite;

use Mojolicious::Static;

my $static = Mojolicious::Static->new;
# push @{$static->paths}, './static';
push @{$static->paths}, '/Users/sklukin/Develop/perl/gallery/static';

app->plugin(Config => { file => 'main.conf' });

app->plugin('Gallery');

get '/' => sub {
  my $c = shift;

  $c->render(text => '<a href="/photos">Gallery</a>');
};

app->start;
