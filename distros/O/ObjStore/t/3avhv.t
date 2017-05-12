#!./perl -w

use Test 1.03;
BEGIN {
    if ($] < 5.00450) { plan tests => 0; exit; }
    else { plan tests => 8 }
}

use lib "./t";
use test;
use strict;
ObjStore::fatal_exceptions(0);

&open_db;

package Test::AVHV1;
use base 'ObjStore::AVHV';
use fields qw(my name is bob);  #must be AFTER 'use base'
use vars qw($VERSION %FIELDS);
$VERSION = '0.00';

sub transform {
    my ($o) = @_;
    $o->fields::import('snork');
    ++$ObjStore::RUN_TIME;
}

package Test::AVHV2;
use base 'ObjStore::AVHV';
use fields qw(my pretty name is horsht);
use vars qw($VERSION);
$VERSION = '0.00';

package main;
use ObjStore;

#ObjStore::debug qw(wrap);

begin 'update', sub {
    ObjStore::AVHV::Fields::nuke_class_fields($db);

    my $john = $db->root('John');
#    ObjStore::debug qw(PANIC);
    my $o = Test::AVHV1->new($db);
    begin sub { $o->[0]{'my'} = 'bad'; };
    ok $@, '/READONLY/', $@;
    undef $@;
    $john->{avhv} = $o;
    $o->{'my'} = 1;
    $o->{'name'} = 2;
    $o->{'is'} = 3;
    $o->{'bob'} = 4;
#    ObjStore::peek($o);
};
die if $@;

begin 'update', sub {
    my $john = $db->root('John');
    my $o = $john->{avhv};
    my $cnt = $o->count;

    $o->transform();
    ok(! $o->is_evolved);
    $o->evolve();
    ok($o->is_evolved);

    bless $o, 'Test::AVHV2';
    ok($o->is_evolved);
    $o->evolve;
    ok($o->is_evolved);
    ok($o->{'my'} == 1 and
       $o->{'name'} == 2 and
       $o->{'is'} == 3);
    $o->{horsht} = 5;
    $o->{pretty} = 4;
    ok $o->{'name'}='changed', 'changed';

#    ObjStore::debug('PANIC');
#    warn join ' ', keys %$o;   #broken!

    # make sure traverse still works!
    #my $x = ObjStore::Index->new($o);
    #$x->configure(path => 'name');
    #$x->add($o);
    #begin sub { $o->{name} = "blamo" };
    #ok $@, '/READONLY/';

    # don't mess up z_peek.t by leaving 5.004_50 stuff in the database
    delete $john->{avhv};
};
die if $@;
