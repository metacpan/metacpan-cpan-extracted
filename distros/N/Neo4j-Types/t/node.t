#!perl
use strict;
use warnings;
use lib qw(lib);

use Test::More 0.88;
use Test::Exception;
use Test::Warnings;
use Neo4j::Types::Node;

plan tests => 12 + 4 + 6 + 1;


my ($n, @l, $p);

sub new_node { bless shift, 'Neo4j::Types::Node' }

$n = new_node {
	id => 42,
	labels => ['Foo', 'Bar'],
	properties => { foofoo => 11, barbar => 22, '123' => [1, 2, 3] }
};
is $n->id(), 42, 'id';
@l = $n->labels;
is scalar(@l), 2, 'label count';
is $l[0], 'Foo', 'label Foo';
is $l[1], 'Bar', 'label Bar';
throws_ok { my $l = $n->labels } qr/\bscalar context\b/i, 'scalar context';
is $n->get('foofoo'), 11, 'get foofoo';
is $n->get('barbar'), 22, 'get barbar';
is_deeply $n->get('123'), [1, 2, 3], 'get 123';
$p = $n->properties;
is ref($p), 'HASH', 'props ref';
is $p->{foofoo}, 11, 'props foofoo';
is $p->{barbar}, 22, 'props barbar';
is_deeply $p->{123}, [1, 2, 3], 'props 123';

$n = new_node {
	id => 0,
	properties => { '0' => [] }
};
is $n->id(), 0, 'id 0';
is ref($n->get('0')), 'ARRAY', 'get 0 ref';
is scalar(@{$n->get('0')}), 0, 'get 0 empty';
$p = $n->properties;
is_deeply $p, {0=>[]}, 'props deeply';

$n = new_node { };
ok ! defined($n->id), 'id gigo';
@l = $n->labels;
is scalar(@l), 0, 'no labels';
throws_ok { my $l = $n->labels } qr/\bscalar context\b/i, 'scalar context no labels';
ok ! defined($n->get('whatever')), 'prop undef';
$p = $n->properties;
is ref($p), 'HASH', 'empty props ref';
is scalar(keys %$p), 0, 'empty props empty';


done_testing;
