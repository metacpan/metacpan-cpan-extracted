# can -*-perl-*- handle indices?

use Test;
BEGIN { plan tests => 5 }
use ObjStore;
use ObjStore::Config;
use lib './t';
use test;
#ObjStore::debug('bridge','refcnt');

&open_db;

begin 'update', sub {
    my $j = $db->root('John');
    my $db = $j->{db} = ObjStore::AV->new($j, 100);
    for (1..500) {
	my $r = ObjStore::HV->new($db,
			      { when => rand 400, priority => rand 400 });
	push @$db, $r;
    }
};

$Q1 = ObjStore::Index->new('transient', path => 'priority', unique => 0);
$Q2 = ObjStore::Index->new('transient', path => 'when', unique => 0);

for (1..4) {
    begin 'read', sub {
	my $db = $db->root('John')->{db};
	
	for my $d (@$db) {
	    $Q1->add($d->new_ref('transient','hard')) if rand > .2;
	    $Q2->add($d->new_ref('transient','hard')) if rand > .2;
	}

	my $rounds = int rand 500;
	while (@$Q2 and --$rounds > 0) {
	    my $z = $Q2->[0];
	    my $rz = $z->focus;
	    my $before = @$Q2;
	    $Q2->remove($z);
	    if ($before != 1+@$Q2) {
		warn 1;
	    }
	    $Q1->add($rz->new_ref('transient','hard'));
	}
	
	$rounds = int rand 500;
	while (@$Q1 and --$rounds > 0) {
	    my $before = @$Q1;
	    my $z = pop @$Q1;
	    if ($before != 1+@$Q1) {
		warn 1;
	    }
	    my $rz = $z->focus;
	    if (rand > .5) {
		$Q2->add($rz->new_ref('transient','hard'));
	    }
	}
    };
    ok 1;
}

begin 'update', sub {
    my $j = $db->root('John');
    delete $j->{db};
};
