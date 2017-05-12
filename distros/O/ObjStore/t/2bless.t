# This is obviously -*-perl-*- don'tcha-think?
use Test;
BEGIN { plan tests => 24, todo => [8,20]; }

package Winner;
use vars qw($VERSION);
$VERSION = "1.00";

package main;

use strict;
use Carp;
use ObjStore ':ADV';
use lib './t';
use test;

#ObjStore::debug 'PANIC';

require PTest;
require TestDB;
$db = new TestDB(test_db(), 'update');
ok(ref $db eq 'TestDB');

# fold duplicated code XXX

sub _isa {
    no strict 'refs';
    my ($o, $c, $loop) = @_;
    my $err=0;
    $loop ||= 0;
    die "recursion $c" if $loop++ > 100;
    if (! $o->isa($c)) {
	warn "$o is not a $c\n";
	$err++;
    }
    for my $c (@{"$c\::ISA"}) { $err += _isa($o, $c, $loop); }
    $err;
}

sub isa_matches {
    no strict 'refs';
    my ($o) = @_;
    my $class = ref $o;
    my $err=0;
    for my $c (@{"$class\::ISA"}) { $err += _isa($o, $c); }
    !$err;
}

sub isa_test {
    no strict 'refs';
    my ($o) = @_;
    my $pkg = blessed($o);

    my $bs1 = $o->_blessto_slot->HOLD;
    bless $o, blessed($o);
    my $bs2 = $o->_blessto_slot;
    ok($bs1 == $bs2);

    push(@{"$pkg\::ISA"}, 'Winner'); ++ $ObjStore::RUN_TIME;
    ok(! $o->isa('Winner'));
    ok($o->UNIVERSAL::isa('Winner'));
    bless $o, $pkg;
    bless $o, $pkg;
    $bs2 = $o->_blessto_slot;
#    ObjStore::peek($bs2);
    ok($bs1 != $bs2);
    ok(isa_matches($o));

    pop @{"$pkg\::ISA"}; ++ $ObjStore::RUN_TIME;
    ok($o->isa('Winner'));
    ok(! $o->UNIVERSAL::isa('Winner')); #ISA cache broken
    bless $o, $pkg;
    bless $o, $pkg;
    ok(isa_matches($o));
}

begin 'update', sub {
    $db->get_INC->[0] = "./t"; #XXX nuke
    $db->sync_INC;

    isa_test($db);

    my $j = $db->root('John');
    die "john not found" if !$j;
    
    # basic bless
    my $phash = bless {}, 'Bogus';
    my $p1 = bless $phash, 'PTest';
    my $transient = "$p1";
    ok(ref $p1 eq 'PTest') or warn $p1;
    
    $j->{obj} = bless $p1, 'PTest';
    ok("$j->{obj}" ne $transient) or warn $transient;
    ok(ref $j->{obj} eq 'PTest') or warn $j->{obj};

    $j->{obj} = new PTest($db);
    ok(ref $j->{obj} eq 'PTest');

    # object - changing @ISA
    my $o = $db->root('John')->{obj};
    isa_test($o);
};
die if $@;

begin sub {
    my $j = $db->root('John');
    my $o = $j->{obj};
    ok(ref($o) eq 'PTest');
    ok($o->bonk);
};
die if $@;
