use strict;
use warnings;

use Test::More tests => 3;

use Routes::Tiny;

my $r = Routes::Tiny->new;

$r->add_route('/(:foo)-bar', name => 'group');

my $m = $r->match('/hello-bar');
is_deeply($m->params, {foo => 'hello'});

$m = $r->match('/-bar');
ok(!$m);

is($r->build_path('group', foo => 'one'), '/one-bar');
