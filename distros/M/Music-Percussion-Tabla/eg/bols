#!/usr/bin/env perl
use strict;
use warnings;

use Music::Percussion::Tabla ();

my $bpm = shift || 260;

my $t = Music::Percussion::Tabla->new(
    file   => "$0.mid",
    bpm    => $bpm,
    volume => 127,
);

$t->tun;
$t->rest($t->quarter);
$t->ta;
$t->tun;
$t->tin;
$t->tin;
$t->tun;
$t->ta;
$t->te;
$t->te;
$t->ta;
$t->tun;
$t->ta;
$t->tun;
$t->ta;
$t->tun;
$t->tun;
$t->tin;
$t->tin;
$t->ta;
$t->ta;
$t->rest($t->whole);

$t->ta;
$t->tun;
$t->tun;
$t->ta;
$t->ta;
$t->tun;
$t->tun;
$t->ta;
$t->ta;
$t->te;
$t->te;
$t->ta;
$t->ta;
$t->tin;
$t->tin;
$t->ta;
$t->rest($t->whole);

$t->ga;
$t->te;
$t->ka;
$t->ga;
$t->rest($t->quarter);
$t->ka;
$t->ta;
$t->rest($t->quarter);
$t->ta;
$t->ga;
$t->ta;
$t->ka;
$t->ta;
$t->ka;
$t->tu;
$t->ta;
$t->ta;
$t->ga;
$t->ta;
$t->tin;
$t->ta;
$t->ka;
$t->ga;
$t->te;
$t->ta;
$t->rest($t->whole);

for my $i (1 .. 3) {
    $t->ta;
    $t->ta;
    $t->tun;
    $t->ga;
    $t->rest($t->quarter);
}

$t->play_with_timidity;
