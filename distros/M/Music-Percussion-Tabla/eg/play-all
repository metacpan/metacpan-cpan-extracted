#!/usr/bin/env perl
use strict;
use warnings;

use Music::Percussion::Tabla ();

my $t = Music::Percussion::Tabla->new(
    file   => "$0.mid",
    bpm    => 100,
    volume => 127,
);
#warn __PACKAGE__,' L',__LINE__,' ',$t->soundfont,"\n";exit;

my @patches = (60 .. 88);

for my $p (@patches) {
    print "Patch: $p\n";
    $t->note($t->quarter, $p) for 1 .. $t->beats;
    $t->rest($t->half);
}

$t->play_with_timidity;
