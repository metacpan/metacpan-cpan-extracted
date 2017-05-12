# set -*-perl-*-
use Test;
BEGIN { plan tests => 7 }

use strict;
use ObjStore;
use lib './t';
use test;
require ObjStore::Set;  # not quite dead yet!

#ObjStore::_debug qw(bridge);
#ObjStore::disable_auto_class_loading();

&open_db;
for my $rep (10, 100) {
    begin 'update', sub {
	my $john = $db->root('John');
	die "No database" if !$john;
    
	my $set = $john->{c} = new ObjStore::Set($db, $rep);
	$set->add({ joe => 1 }, { bob => 2 }, { ed => 3 });

	my (@k,@v,@set);
	for (my $o = $set->first; $o; $o = $set->next) {
	    $o->HOLD;
	    push(@set, $o);
	    push(@k, keys %$o);
	    for (values %$o) { push(@v, $_); }
	}
	@k = sort @k;
	@v = sort @v;
	ok(@k==3 and $k[0] eq 'bob' and $k[1] eq 'ed' and $k[2] eq 'joe' and
	    @v==3 and $v[0] == 1 and $v[1] == 2 and $v[2] == 3) or do {
	    warn join(' ', @k);
	    warn join(' ', @v);
	};

	my $yuk = pop @set;
	$set->rm($yuk);
	ok(! $set->contains($yuk));
	$set->add($yuk);
	ok($set->contains($yuk));

	delete $john->{c};
    };
    die if $@;
};
