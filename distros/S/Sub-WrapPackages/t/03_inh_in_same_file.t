#!perl

use strict;
use Test::More tests => 4;

use lib 't/lib';
use Banana;

my $post = '';
use Sub::WrapPackages (
    packages    => [qw(Banana)],
    post         => sub { $post .= $_[0]; },
    wrap_inherited => 1,
);

ok(Banana->peel() eq 'ready to eat', "got right response");
is($post, 'Banana::peel', 'post is good for non-inherited method');

$post = '';
ok(Banana->eat() eq 'yum yum', "got right response");
is($post, 'Banana::eat', 'post is good for inherited method');
