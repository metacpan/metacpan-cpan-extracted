use Test::More;
use lib '../lib';
use lib 't';
use lib '..';
use v5.10;
use Try::Tiny;
use t::PeelerTest;
use strict;

our $peeler;
isa_ok $peeler, 'Neo4j::Cypher::Abstract::Peeler';

$peeler->{config}{bind} = 0;
$peeler->{config}{anon_placeholder} = '?';
my @tests = (
     {
        done => 'manage literal + binds',
        where => {
            foo => \["IN (?, ?)", 22, 33],
            bar => [-and =>  \["> ?", 44], \["< ?", 55] ],
        },
        stmt => "( (bar > ? AND bar < ?) AND foo IN (?, ?) )",
        bind => [44, 55, 22, 33],
    },
  {
    done  => 'manage literal + bind',
       where => \[ 'foo = ?','bar' ],
       stmt => "(foo = ?)",
       bind => [ "bar" ],
   },
 
);

test_peeler(@tests);

done_testing;


