#!perl
use strict;
use warnings;
use lib qw(lib);

use Test::More 0.88;
use Test::Warnings;
use Neo4j::Types::Relationship;

plan tests => 11 + 4 + 7 + 1;


my ($r, $p);

sub new_rel { bless shift, 'Neo4j::Types::Relationship' }

$r = new_rel {
	id => 55,
	type => 'TEST',
	start => 34,
	end => 89,
	properties => { foo => 144, bar => 233, '358' => [3, 5, 8] }
};
is $r->id, 55, 'id';
is $r->type, 'TEST', 'type';
is $r->start_id, 34, 'start id';
is $r->end_id, 89, 'end id';
is $r->get('foo'), 144, 'get foo';
is $r->get('bar'), 233, 'get bar';
is_deeply $r->get('358'), [3, 5, 8], 'get 358';
$p = $r->properties;
is ref($p), 'HASH', 'props ref';
is $p->{foo}, 144, 'props foo';
is $p->{bar}, 233, 'props bar';
is_deeply $p->{358}, [3, 5, 8], 'props 358';

$r = new_rel {
	id => 0,
	properties => { '0' => [] }
};
is $r->id(), 0, 'id 0';
is ref($r->get('0')), 'ARRAY', 'get 0 ref';
is scalar(@{$r->get('0')}), 0, 'get 0 empty';
$p = $r->properties;
is_deeply $p, {0=>[]}, 'props deeply';

$r = new_rel { };
ok ! defined($r->id), 'id gigo';
ok ! defined($r->type), 'no type';
ok ! defined($r->start_id), 'no start id';
ok ! defined($r->end_id), 'no end id';
ok ! defined($r->get('whatever')), 'prop undef';
$p = $r->properties;
is ref($p), 'HASH', 'empty props ref';
is scalar(keys %$p), 0, 'empty props empty';


done_testing;
