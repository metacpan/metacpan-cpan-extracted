# -*-perl-*- is going global, I tell ya!
use Test;
BEGIN { plan tests => 3 }

package MyGSpot;
use ObjStore;
use base 'ObjStore::AV';
use vars qw($VERSION);
$VERSION = "0.5";

package main;

use strict;
use ObjStore ':ADV';
use lib './t';
use test;

&open_db;
begin 'update', sub {
    my $j = $db->root('John');
    die "no db" if !$j;

    my $s = new MyGSpot($j);
    my $g = $s->stash;
    $g->{color} = 'Pink';
    $g->{size} = 10;
};
die if $@;

begin sub {
    my $g = $db->stash('MyGSpot');
    ok($g->{color} eq 'Pink');
    ok($g->{size} == 10);
};
die if $@;
