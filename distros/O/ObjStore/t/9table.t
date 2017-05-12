#-*-perl-*-
use Test;
BEGIN { plan tests => 1 }

use ObjStore;
use lib './t';
use test;

&open_db;

#ObjStore::debug 'refcnt';

require ObjStore::Table2;
require ObjStore::Table;
require Row;

begin 'update', sub {
    my $john = $db->root('John');
    die "No john" if !$john;

    my $tbl = $john->{table} = new ObjStore::Table($john, 30);
    my $ar = $tbl->array;
    for (my $x=0; $x < 20; $x++) {
	my $r = new Row($tbl);
	$r->{f1} = $x ** 1;
	$r->{f2} = $x ** 2;
	$r->{f3} = ["This is big ".($x ** 3)];
	$ar->[$x] = $r;
    }
    $ar->[16] = $ar->[14];
    $ar->[23] = new Row($tbl);
    $ar->[23]{f3} = ['Empty'];

    $tbl->new_index('Field', 'e1', 'f1');
    $tbl->new_index('Field', 'e2', 'f2');
    $tbl->new_index('Field', 'long', 'f3->0');

    bless $tbl, 'ObjStore::Table2';
    #ok(! $tbl->iscorrupt(1)) or ObjStore::peek($tbl);

    $tbl->add(new Row($tbl));
    $tbl->remove($ar->[16]);

#    $tbl->rebuild_indices;
    #ok(! $tbl->iscorrupt(1)) or ObjStore::peek($tbl);
};
die if $@;

begin 'update', sub {
    my $john = $db->root('John');
    die "No john" if !$john;

    delete $john->{table};
};
die if $@;
