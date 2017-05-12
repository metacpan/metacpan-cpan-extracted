use strict;
use warnings;

use Test::More tests => 2;

use Routes::Tiny;

my $r = Routes::Tiny->new;
$r->add_route('/:foo', name => 'route');

my $m = $r->match('0');
is_deeply($m->params, {foo => 0});

is($r->build_path('route', foo => 0), '/0');
