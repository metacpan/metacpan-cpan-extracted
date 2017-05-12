# Test broken -*-perl-*- refs
use Test;
BEGIN { plan tests => 23, todo => [22] }

use strict;
use ObjStore;
use ObjStore::Config;
use lib './t';
use test;

package noref_test;
use test;
use vars qw($VERSION @ISA $norefs);
$VERSION = '0';
@ISA = 'ObjStore::AV';

sub new {
    my $o = shift->SUPER::new(@_);
    $o->[0] = 'ok';
    $o;
}

$norefs = 0;
sub NOREFS {
    my $o = shift;
    ++$norefs;
    if ($main::saver->[0]) {
	$main::saver->[1] = $o;
    }
}

package main;
use vars qw($saver);

#ObjStore::debug qw(bridge txn);
#use Devel::Peek;

&open_db;

my $tsave;
my ($safe, $unsafe);

my $tdb = ObjStore::open($ObjStore::Config::TMP_DBDIR."/toast", 'update', 0666);
begin sub {
    ok(@{[$tdb->get_all_roots]} == 0);
};
die if $@;
ok($tdb->get_host_name eq $db->get_host_name);
ok($tdb->get_pathname =~ m/toast/) or warn $tdb->get_pathname;

begin('update', sub {
    my $j = $db->root('John');
    $j->{toast} = {};

    my $toast = $tdb->root("junk", [1,2]);
    
    for my $where ($j, 'transient') {
	for my $type ('safe', 'unsafe') {
	    my $r = $toast->new_ref($where, $type);
	    ok(! $r->deleted);
	    ok($r->get_database->get_id eq $tdb->get_id);
	    if (ref $where) {
		$j->{toast}{$type} = $r;
	    } else {
		$tsave->{$type} = $r;
	    }
	}
    }

    $safe = $tsave->{safe}->dump;
    $unsafe = $tsave->{unsafe}->dump;

    #norefs
    $saver = ObjStore::AV->new($db);
    $saver->[0] = 1;
    new noref_test($db);
    ok $saver->[1]->_refcnt, 1;
    ok $saver->[1][0], 'ok';
    undef $saver;
});
die if $@;

ok($noref_test::norefs == 2);

begin sub {
    my $j = $db->root('John');

    ok(!$tsave->{safe}->deleted && !$tsave->{unsafe}->deleted);

    for my $o (ObjStore::Ref->load($safe, $tdb)->focus,
	       ObjStore::Ref->load($unsafe, $tdb)->focus) {
	ok($o == $tdb->root('junk'));
    }
};
die if $@;

begin('update', sub {
    $tdb->destroy_root("junk");

    my $j = $db->root('John');

    ok($tsave->{safe}->deleted);
    ok($j->{toast}{safe}->deleted);

    begin sub { $tsave->{safe}->focus };
    ok($@ =~ m/err_reference_not_found/s) or warn $@;
    begin sub { $j->{toast}{safe}->focus };
    ok($@ =~ m/err_reference_not_found/s) or warn $@;

    delete $j->{'toast'};
});
die if $@;

eval { $tdb->destroy; };
ok(! $@);

$tdb->_destroy;
