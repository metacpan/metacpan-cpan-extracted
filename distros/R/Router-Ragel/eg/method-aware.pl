#!/usr/bin/env perl
# HTTP-method-aware routing on top of Router::Ragel.
# Encodes the method as a path prefix so a single Router::Ragel instance
# dispatches by method+path. Captures from the path are returned positionally.
use strict;
use warnings;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use Router::Ragel;

my $router = Router::Ragel->new
    ->add('/GET/users', 'list users')
    ->add('/POST/users', 'create user')
    ->add('/GET/users/:id<int>', 'show user')
    ->add('/PUT/users/:id<int>', 'update user')
    ->add('/DELETE/users/:id<int>', 'delete user')
    ->compile;

sub dispatch {
    my ($method, $path) = @_;
    Router::Ragel::match($router, "/$method$path");
}

for my $req (
    [GET => '/users'],
    [POST => '/users'],
    [GET => '/users/42'],
    [PUT => '/users/42'],
    [DELETE => '/users/42'],
    [PATCH => '/users/42'],
    [GET => '/widgets'],
) {
    my ($m, $p) = @$req;
    my @r = dispatch($m, $p);
    if (@r) {
        my $caps = @r > 1 ? ' [' . join(',', @r[1..$#r]) . ']' : '';
        print "$m $p -> $r[0]$caps\n";
    } else {
        print "$m $p -> (no match)\n";
    }
}
