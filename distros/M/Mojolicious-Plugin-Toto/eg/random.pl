#!/usr/bin/env perl

use Mojolicious::Lite;
use Test::Mojo;
use List::Util qw/shuffle/;
use List::MoreUtils qw/pairwise/;

get '/hello' => { layout => 'default' } => sub { shift->render_text('hello') };

my @nouns = qw/
Archaeology
Baker
Bra
Jeans
Jellyfish
Octagon
Pendulum
Throne
Vase
Yellow
/;

my @verbs = qw/
Retract
Transform
Comparing
Browse
Favor
Fashion
Starve
/;

sub _random_splice {
    my $n = shift;
    my $list = shift;
    return splice @$list, 0, 2;
}

sub _random_nouns {
    my $count = shift;
    return @nouns[0..$count-1];
}

sub _random_verbs {
    my $n = shift;
    my @n = @verbs;
    return @n[0..($n-1)];
}

sub _random_pairs {
    my $n = shift;
    return pairwise { "$a/$b" } @{[ _random_nouns($n) ]} , @{[ _random_verbs($n) ]};
}

my @copy = @nouns;

plugin 'toto' => nav => [qw/this that theother/],
  sidebar     => {
    this     => [ _random_pairs(5), _random_splice(3,\@copy) ],
    that     => [ _random_pairs(5), _random_splice(3,\@copy) ],
    theother => [ _random_pairs(5), _random_splice(3,\@copy) ],
  },
  tabs => {
    $nouns[0] => [ _random_verbs(4) ],
    map { $nouns[$_] => [ _random_verbs(4) ] } (1..$#nouns)
  },
  ;

app->start;

1;

