#!/usr/bin/env perl
# Minimal Plack/PSGI app dispatching via Router::Ragel.
# Run: plackup eg/plack.pl
use strict;
use warnings;
use Plack::Request;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use Router::Ragel;

sub _txt { [200, ['Content-Type', 'text/plain'], [shift]] }

my $router = Router::Ragel->new
    ->add('/', sub { _txt('home') })
    ->add('/users', sub { _txt('user list') })
    ->add('/users/:id<int>', sub { my (undef, $id) = @_; _txt("user $id") })
    ->add('/blog/:year<int>/:slug', sub { my (undef, $y, $s) = @_; _txt("$y / $s") })
    ->compile;

my $app = sub {
    my $req = Plack::Request->new(shift);
    my ($handler, @captures) = Router::Ragel::match($router, $req->path_info);
    return [404, ['Content-Type', 'text/plain'], ['not found']] unless $handler;
    return $handler->($req, @captures);
};
