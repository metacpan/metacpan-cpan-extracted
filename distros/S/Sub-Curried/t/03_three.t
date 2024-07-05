#!/usr/bin/perl
use strict; use warnings;
use Data::Dumper;

use Test::More tests=>4;
use Test::Exception;

use Sub::Curried;

curry three ($one,$two,$three) { }

throws_ok { three(1,2,3,4) }    qr/three, expected 3 args but got 4/;
throws_ok { three(1)->(2,3,4) } qr/three, expected \d+ args but got \d+/;
throws_ok { three(1,2)->(3,4) } qr/three, expected \d+ args but got \d+/;
throws_ok { three(1,2,3)->(4) } qr/Can't use string \("3"\) as a subroutine ref/;

