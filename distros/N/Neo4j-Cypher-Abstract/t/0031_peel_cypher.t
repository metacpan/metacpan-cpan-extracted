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
my @tests = (
  {
    done => 'cypher predicate with list',
    no_tree => 1,
    where =>  { -all => ['x', [1,2,3], {'x' => 3}] },
    stmt => 'all(x IN [1,2,3] WHERE (x = 3))',
  },
  {
    done => 'cypher predicate with list function',
    no_tree => 1,
    where =>  { -any => ['fred', {-labels => \'a'}, {'fred' => {-contains => 'boog'}}] },
    stmt => 'any(fred IN labels(a) WHERE (fred CONTAINS \'boog\'))'
   },
  {
    todo => 'reduce with function',
    no_tree => 1,
    where => { -reduce => [ totalAge => 0, n => { -nodes => \'p' },
			    \'totalAge + n.age' ] },
    stmt => 'reduce(totalAge = 0, n IN nodes(p) | totalAge + n.age)'
   },
  {
    todo => 'reduce with list',
    no_tree => 1,
    where => { -reduce => [ totalAge => 0, n => [\'a', \'b', \'c'],
			    \'totalAge + n.age' ] },
    stmt => 'reduce(totalAge = 0, n IN [a,b,c] | totalAge + n.age)'
    }  
);

test_peeler(@tests);

done_testing;


