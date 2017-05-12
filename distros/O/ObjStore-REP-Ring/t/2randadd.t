# -*-perl-*-

use strict;
use Test; plan test => 1;
use ObjStore;
use ObjStore::REP::Ring;

my $o = ObjStore::REP::Ring::Index::new('ObjStore::Index', 'transient');
$o->configure(path => '0');

# ObjStore::debug('compare');

my @order = qw(

138 73 15 175 119 187 101 66 5 88 95 74 136 95 34 34 83 111 138 1 120 25 186 113 181 157 122 163 48 66 154 186 177 175 105 32 74 154 98 45 56 110 146 23 101 116 96 158 14 139 116 155 26 96 188 13 42 86 169 76 63 153 94 34 189 4 95 73 139

);

my @set;
for (1..200) {
#    my $elem = int shift @order;
    my $elem = int rand 200;
    $o->add([$elem]);
    $o->_debug1();
    push @set, $elem;
    my $got = join ' ', map { $_->[0] } @$o;
    my $expect = join ' ', sort { $a <=> $b } @set;
    if ($got ne $expect) {
	die "add[".join(' ', @set)."]\n$got\n$expect\n";
    }
}
ok 1;
