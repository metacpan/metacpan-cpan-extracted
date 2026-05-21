#!/usr/bin/env perl
# Benchmark Router::Ragel against Router::XS, Router::R3, URI::Router,
# and Mojolicious::Routes. Routers that aren't installed are skipped.
use strict;
use warnings;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use Benchmark qw(:all);
use Router::Ragel;

my %have;
$have{XS}   = eval { require Router::XS; Router::XS->import(':all'); 1 };
$have{R3}   = eval { require Router::R3; 1 };
$have{UR}   = eval { require URI::Router; 1 };
$have{Mojo} = eval {
    require Mojolicious::Routes;
    require Mojolicious::Routes::Match;
    require Mojolicious::Controller;
    1;
};

my @routes = (
    '/qest/qwe',
    '/jest/route/other/:a',
    '/test/:id/:param/:aa/:bb/:aa/:bb/get',
    '/another/:route/add',
    '/prefix/:as/:as/check',
    '/asd/vsadf/:bb',
    '/asdvsdf/qwedqwed/:aa',
);

my @paths = (
    '/qest/qwe',
    '/jest/route/other/aa',
    '/test/dasd/param/aa/bb/aa/bb/get',
    '/another/route/:aaa',
    '/prefix/as/as',
    '/invalid/path',
);

my $ragel = Router::Ragel->new;
$ragel->add($_, +{}) for @routes;
$ragel->compile;

my %bench;
$bench{'Ragel(fun)'} = sub { my @r; @r = Router::Ragel::match($ragel, $_) for @paths };
$bench{'Ragel(method)'} = sub { my @r; @r = $ragel->match($_) for @paths };

if ($have{XS}) {
    Router::XS::add_route($_ =~ s/:\w+/*/gr, +{}) for @routes;
    $bench{'XS(fun)'} = sub { my @r; @r = Router::XS::check_route($_) for @paths };
}

if ($have{R3}) {
    my $r3 = Router::R3->new(map +(s/:(\w+)/{$1}/gr, +{}), @routes);
    $bench{'R3(method)'} = sub { my @r; @r = $r3->match($_) for @paths };
    $bench{'R3(fun)'} = sub { my @r; @r = Router::R3::match($r3, $_) for @paths };
}

if ($have{UR}) {
    my $ur = URI::Router->new(map +(s/:(\w+)/*/gr, +{}), @routes);
    $bench{'UR(method)'} = sub { my @r; @r = $ur->route($_) for @paths };
    $bench{'UR(fun)'} = sub { my @r; @r = URI::Router::route($ur, $_) for @paths };
}

if ($have{Mojo}) {
    my $mojo = Mojolicious::Routes->new;
    $mojo->any($_) for @routes;
    my $c = Mojolicious::Controller->new;
    $bench{'Mojo'} = sub {
        my @r;
        for my $p (@paths) {
            my $m = Mojolicious::Routes::Match->new(root => $mojo);
            $m->find($c, { method => 'GET', path => $p });
            @r = $m->stack ? @{$m->stack} : ();
        }
    };
}

# warmup
for (1..1000) { $_->() for values %bench }

print "available: ", join(', ', grep $have{$_}, sort keys %have), "\n";
print "Benchmarking..\n";
cmpthese(-2, \%bench);
