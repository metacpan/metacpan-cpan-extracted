#!/usr/bin/env perl

use 5.042.2;
no source::encoding;
use warnings FATAL => 'all';
use autodie ':default';
use Devel::Confess;
use DDP {output => 'STDOUT', array_max => 10, show_memsize => 1};
use Stats::LikeR;
use Test::More;
use Test::LeakTrace; # incompatible with Devel::Cover

no_leaks_ok {
    eval { read_table('t/HepatitisCdata.csv', 'output.type' => 'hoa') };
} 'read_table: basic with no memory leaks with hash of array' unless $INC{'Devel/Cover.pm'};
