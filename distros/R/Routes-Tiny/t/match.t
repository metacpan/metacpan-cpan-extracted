use strict;
use warnings;

use Test::More tests => 6;

use Routes::Tiny;

my $r = Routes::Tiny->new;
$r->add_route('/foo', name => 'text');
$r->add_route('/:foo/:bar', name => 'route');

my $m = $r->match('/foo');
is_deeply($m->params, {});
is($r->build_path('text'), '/foo');
is $m->name => 'text';

$m = $r->match('/hello/there');
is_deeply($m->params, {foo => 'hello', bar => 'there'});
is($r->build_path('route', foo => 'hello', bar => 'there'), '/hello/there');
is $m->name => 'route';
