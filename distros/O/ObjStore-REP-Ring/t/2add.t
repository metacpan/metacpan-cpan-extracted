# -*-perl-*-

use strict;
use Test; plan test => 3;
use ObjStore;
use ObjStore::REP::Ring;

my $o = ObjStore::REP::Ring::Index::new('ObjStore::Index', 'transient');
$o->configure(path => '0');

for (1..10) { $o->add([$_]); }
ok(join('', map { $_->[0] } @$o), '12345678910');

@$o=();
for (my $x=10; $x > 0; $x--) { $o->add([$x]); }
ok(join('', map { $_->[0] } @$o), '12345678910');

# add
sub setup {
    my $o = ObjStore::REP::Ring::Index::new('ObjStore::Index', 'transient');
    $o->configure(path => '0');
    for (1..200) { push @$o, [$_] }
    $o;
}

for my $t (0..200) {
    $o = setup();
#    warn $o->_percent_filled();
    for (1..2) { $o->add([$t,"add$_"]); }
    my @got = map { @$_ == 1? $_->[0] : "$_->[1]-$_->[0]" } @$o;
#    warn $o->_percent_filled();
    #warn join(' ', @got);
    for my $c (0..201) {
	if ($c < $t) {
	    die "$got[$c] != $c" if $got[$c] != $c+1;
	} elsif ($c == $t) {
	    die "$got[$c] ne 'add'" if $got[$c] !~ m/^add1/;
	} elsif ($c == $t+1) {
	    die "$got[$c] ne 'add'" if $got[$c] !~ m/^add2/;
	} else {
	    die "$got[$c] != $c - 2" if $got[$c] != $c - 1;
	}
    }
}
ok 1;
