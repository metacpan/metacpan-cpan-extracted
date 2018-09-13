#!/usr/bin/env perl
use strict;
use warnings;
use 5.020;
use lib 'lib';
use lib 'local/lib/perl5';

use Ordeal::Model::ChaCha20;

my $r = Ordeal::Model::ChaCha20->new(seed => 'ABCDEF');
my $s = Ordeal::Model::ChaCha20->new(seed => 'ABCDEF');
my $t = Ordeal::Model::ChaCha20->new(seed => 'GHIJKL');

say $_->int_rand(0, 1_000_000) for $r, $s, $t;

my $fr = $r->freeze;
my $fs = $s->freeze;
say 'OK' if $fr eq $fs;
say $_ for $fr, $fs, $t->freeze;

$t->restore($fr);

say $_->int_rand(0, 1_000_000) for $r, $s, $t;
