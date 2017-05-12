#!perl -T

use strict;
use warnings;

use Test::More tests => 10;

use Sub::Nary;

sub wat {
 wantarray ? (1, 2) : 1;
}

my $sn = Sub::Nary->new();

my $r = { 1 => 0.5, 2 => 0.5 };

is_deeply($sn->nary(\&wat), $r, 'first run, without cache');
isnt(keys %{$sn->{cache}}, 0, 'cache isn\'t empty');
is_deeply($sn->nary(\&wat), $r, 'second run, cached');
isnt(keys %{$sn->{cache}}, 0, 'cache isn\'t empty');

my $sn2 = $sn->flush();
is_deeply( [ defined $sn2, $sn2->isa('Sub::Nary') ], [ 1, 1 ], 'flush ');
is(keys %{$sn->{cache}}, 0, 'cache is empty');

is_deeply($sn->nary(\&wat), $r, 'third run, without cache');
isnt(keys %{$sn->{cache}}, 0, 'cache isn\'t empty');
is_deeply($sn->nary(\&wat), $r, 'fourth run, cached');
isnt(keys %{$sn->{cache}}, 0, 'cache isn\'t empty');
