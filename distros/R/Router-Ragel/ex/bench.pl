use strict;
use warnings;
use Benchmark qw(:all);
use Router::Ragel;
use Router::XS qw(:all);  # Import functional interface
use Router::R3;
use URI::Router;

my @routes = (
    '/qest/qwe',
    '/jest/route/other/:a',
    '/test/:id/:param/:aa/:bb/:aa/:bb/get',
    '/another/:route/add',
    '/prefix/:as/:as/check',
    '/asd/vsadf/:bb',
    '/asdvsdf/qwedqwed/:aa'
);

my @paths = (
    '/qest/qwe',
    '/jest/route/other/aa',
    '/test/dasd/param/aa/bb/aa/bb/get',
    '/another/route/:aaa',
    '/prefix/as/as',
    '/invalid/path',
);

my $ragel_router = Router::Ragel->new;
for my $route (@routes) {
    $ragel_router->add($route, +{});
    add_route($route=~s/:\w+/*/gr, +{});
}
$ragel_router->compile;

my $r3 = Router::R3->new(map +(s/:(\w+)/{$1}/gr, +{}), @routes);

my $ur = URI::Router->new(map +(s/:(\w+)/*/gr, +{}), @routes);

for (1..100) { # warmup
    $ragel_router->match($_) for @paths;
    check_route($_) for @paths;
    $r3->match($_) for @paths
}

# Run the benchmark
print "Benchmarking..\n";
my @r;
cmpthese(-1, {
    'Ragel(fun)' => sub { @r = Router::Ragel::match($ragel_router, $_) for @paths },
    'Ragel(method)' => sub { @r = $ragel_router->match($_) for @paths  },
    'XS(fun)' => sub { @r = check_route($_) for @paths },
    'R3(method)' => sub { @r = $r3->match($_) for @paths },
    'R3(fun)' => sub { @r = Router::R3::match($r3, $_) for @paths },
    'UR(method)' => sub { @r = $ur->route($_) for @paths },
    'UR(fun)' => sub { @r = URI::Router::route($ur, $_) for @paths },
});
