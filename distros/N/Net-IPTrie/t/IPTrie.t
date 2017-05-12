use strict;
use Test::More qw(no_plan);
use lib "lib";

BEGIN { use_ok('Net::IPTrie'); }

my $tr = Net::IPTrie->new(version=>4);
isa_ok($tr, 'Net::IPTrie', 'Constructor');

my $n = $tr->add(address=>'10.0.0.0', prefix=>8);
isa_ok($n, 'Net::IPTrie::Node', 'Node Constructor');

# Root (default route)
my $r = $tr->add(address=>'0.0.0.0', prefix=>0);
is($r->address, '0.0.0.0', 'address');
is($r->iaddress, 0, 'iaddress');
is($r->prefix, 0, 'prefix');

is($n->address, '10.0.0.0', 'address');
is($n->iaddress, '167772160', 'iaddress');
is($n->prefix, '8', 'prefix');
is($n->parent->address, $r->address, 'root parent');

my $a = $tr->add(address=>'10.0.0.0', prefix=>24);
is($a->parent->address, $n->address, 'parent');

my $b = $tr->add(address=>'10.0.0.1');
is($b->parent->address, $a->address, 'parent');

my $p = $tr->find(address=>'10.0.0.1');
is($p->address, $b->address, 'find');

my $q = $tr->find(address=>'10.0.0.2');
is($q->address, $a->address, 'find');

# This is 10.0.0.7 in integer format
my $c = $tr->add(iaddress=>'167772167', data=>'blah');
is($c->parent->address, $a->address, 'parent');
is($c->data, 'blah', 'data');

# Traversal
my $list = ();
my $code = sub { push @$list, shift @_ };
my $count = $tr->traverse(code=>$code);

my $tlist = [$r, $n, $a, $b, $c];
is_deeply($tlist, $list, 'traverse');
is($count, 5, 'traverse count');

# Delete does not actually delete the node, but empties it
$a->delete();
is($a->address,  undef, 'delete');
is($a->iaddress, undef, 'delete');
is($a->prefix,   undef, 'delete');
is($a->data,     undef, 'delete');

# b's parent should now be $n, not $a
is($b->parent->address, $n->address, 'parent');

$b->delete();
my $s = $tr->find(address=>'10.0.0.1');
is($s->address, $n->address, 'find');

# IPv6 tests

my $tr6 = Net::IPTrie->new(version=>6);
isa_ok($tr, 'Net::IPTrie', 'Constructor');

my $n6 = $tr6->add(address=>'FEC0:468:D00::', prefix=>40);

my $a6 = $tr6->add(address=>'FEC0:468:D00::', prefix=>48);
is($a6->parent->address, $n6->address, 'parent');

my $b6 = $tr6->add(address=>'FEC0:468:D00:1::', prefix=>64);
is($b6->parent->address, $a6->address, 'parent');

my $c6 = $tr6->add(address=>'FEC0:468:D00:1::80DF:3C16', prefix=>128);
is($c6->parent->address, $b6->address, 'parent');
