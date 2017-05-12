# -*-perl-*-

use strict;
use Test; plan test => 7;
use ObjStore;
use ObjStore::REP::Ring;

my $o = ObjStore::REP::Ring::Index::new('ObjStore::Index', 'transient');
$o->configure(path => '0');

for (0..499) { push @$o, [$_] }
ok @$o, 500;

my $c = $o->new_cursor();
ok $c->focus == $o;
ok !defined $c->at;

$c->moveto(200);
ok $c->pos, 200;
ok $c->at->[0], 200;

# step forward
$c->moveto(-1);
ok $c->pos, -1;
my $at=-1;
while (1) {
    $c->step(1);
    ++$at;
    last if $at == @$o;
    die "keys mismatch at $at" if $at != $c->keys;
    die "pos mismatch at $at" if $at != $c->pos;
    die "step broke at $at (".$c->pos().")" if !$c->at;
    my $got = $c->at->[0];
    if ($got != $at) {
	die "step broke at $at ($got)";
    }
}

# step backward
$c->moveto(scalar @$o);
ok $c->pos, @$o;
$at=@$o;
while (1) {
    $c->step(-1);
    --$at;
    last if $at == -1;
    die "keys mismatch at $at" if $at != $c->keys;
    die "pos mismatch at $at" if $at != $c->pos;
    die "step broke at $at (".$c->pos().")" if !$c->at;
    my $got = $c->at->[0];
    if ($got != $at) {
	die "step broke at $at ($got)";
    }
}

