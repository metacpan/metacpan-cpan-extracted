#-*-perl-*-
use Test 1.03;
BEGIN { plan tests=>3 }

use strict;
use ObjStore;
use lib './t';
use test;
Carp->import('verbose');

#ObjStore::debug('refcnt');

&open_db;
begin 'update', sub {
    my $j = $db->root('John');

    my $h = $$j{heap} = ObjStore::REP::Splash::Heap::new('ObjStore::Index', $j->segment_of, 20);
    $h->configure(path => '0', ascending => 1);

    my @cards = map { [$_] } (1..50,1..25,1..25);
    while (@cards) {
	my $at = splice @cards, int(rand(@cards)), 1;
	$h->add($at);
	$h->verify_heap;
    }
    ok 1;
    while (@$h) {
	my $next = $h->[0]->HOLD;
	if (shift @$h != $next) {
	    warn "$next->[0] out of order";
	}
	$h->verify_heap;
    }
    ok 1;
};
die if $@;

package ObjStore::Index;

sub verify_heap {
    my ($tbl) = @_;
    return if @$tbl < 2;
    my $conf = $tbl->configure;
    my $path = $conf->[1];
    return warn "no path" if !$path;
    for (my $x=0; $x < @$tbl; $x++) {
	my $jx = $x*2+1;
	last if $jx >= @$tbl;
	my $kx = $jx+1;
	if ($kx < @$tbl) {
	    $jx = $kx if $tbl->[$jx][0] < $tbl->[$kx][0]
	}
	if ($tbl->[$x][0] > $tbl->[$jx][0]) {
	    my $e1 = $tbl->[$x];
	    $e1 = $e1->focus if $e1->can('focus');
	    my $e2 = $tbl->[$jx];
	    $e2 = $e2->focus if $e2->can('focus');
	    require ObjStore::Peeker;
	    warn "$x: ". ObjStore::Peeker->Peek($e1);
	    warn "$jx: ". ObjStore::Peeker->Peek($e2);
	}
    }
}
