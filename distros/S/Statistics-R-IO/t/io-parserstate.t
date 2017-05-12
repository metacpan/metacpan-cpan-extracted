#!perl -T
use 5.010;
use strict;
use warnings FATAL => 'all';

use Test::More tests => 11;
use Test::Fatal;

use Statistics::R::IO::ParserState;

use Scalar::Util qw( refaddr );

my $state = Statistics::R::IO::ParserState->new(data => 'foobar');

## basic state sanity
is_deeply($state->data, ['f', 'o', 'o', 'b', 'a', 'r'],
    'split data');
is($state->at, 'f', 'starting at');
is($state->position, 0, 'starting position');
ok(!$state->eof, 'starting eof');

## state next
my $next_state = $state->next;
is_deeply($next_state,
          Statistics::R::IO::ParserState->new(data => 'foobar',
                                              position => 1,
                                              singletons => []), # bypass lazy attribute ctor
          "next");
is($next_state->at, 'o', 'next value');
is($next_state->position, 1, 'next position');
is_deeply($state,
          Statistics::R::IO::ParserState->new(data => 'foobar',
                                              position => 0, # bypass lazy attribute ctor
                                              singletons => []),
          "next doesn't mutate in place");


## state singletons stash
my $singleton = [ 457 ];
my $add_state = $state->add_singleton($singleton);
is_deeply($add_state->singletons,
          [ [ 457 ] ], 'add_singleton');
is_deeply($state->singletons,
          [], "add_singleton doesn't mutate the state");
is(refaddr($add_state->get_singleton(0)),
   refaddr $singleton,
   'add_singleton preserves reference identity');
