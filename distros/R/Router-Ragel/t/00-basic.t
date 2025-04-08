#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 7;
use FindBin qw($Bin);
use lib "$Bin/../lib";

require_ok('Router::Ragel');
my $router = Router::Ragel->new;
my $data1 = { page => 'test_page', content => 'Hello, World!' };
my $data2 = [ 'dynamic_route', 42 ];
$router->add('/test', $data1);
$router->add('/test/:id/:param/get', $data2);
$router->add('/test/:id/:param/get/:bet', $data2);
ok($router->compile, 'Routes compiled successfully');
my ($assoc_data1, @placeholder_values1) = $router->match('/test');
is_deeply($assoc_data1, $data1, 'Matched data for /test');
is(scalar @placeholder_values1, 0, 'No placeholder values for /test');
my ($assoc_data2, @placeholder_values2) = $router->match('/test/4/rest/get');
is_deeply($assoc_data2, $data2, 'Matched data for /test/4/rest/get');
is_deeply(\@placeholder_values2, [ '4', 'rest' ], 'Placeholder values for /test/4/rest/get');
my @no_match = $router->match('/invalid/path');
is(scalar @no_match, 0, 'No match for /invalid/path');
done_testing;
