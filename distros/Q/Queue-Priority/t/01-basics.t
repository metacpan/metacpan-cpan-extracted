use strict;
use warnings;
use Test::More;
use List::Util qw( shuffle );

my $class = 'Queue::Priority';

use_ok $class, 'use';

my $q = new_ok $class, [ 4 ];
ok $q->is_empty,      'initial state: is_empty';
ok !$q->is_full,      'initial state: is_full';
ok !$q->is_shutdown,  'initial state: is_shutdown';
ok !defined $q->peek, 'initial state: peek';

eval { $q->insert( undef ) };
ok defined $@, 'insert croaks when item is undef';
like $@, qr/cannot insert undef/, 'expected error';

for ( 1 .. 4 ) {
  cmp_ok $q->insert( $_ ), '==', $_, "insert $_";
}

eval { $q->insert( 0 ) };
ok defined $@, 'insert croaks when full';
like $@, qr/queue is full/, 'expected error';

for ( 1 .. 4 ) {
  cmp_ok $q->remove, '==', $_, "remove $_";
}

ok $q->shutdown, 'shut down';
eval { $q->insert( 0 ) };
ok defined $@, 'insert croaks when shut down';
like $@, qr/queue is shut down/, 'expected error';

# TODO random ints in list, test removed item > previous
subtest ordering => sub {
  $q = new_ok $class, [ 20 ];

  for ( 1 .. 20 ) {
    my @list = 1 .. 20;
    my @shuffled = shuffle @list;

    foreach ( @shuffled ) {
      ok $q->insert( $_ ), "insert (random order): $_";
    }

    foreach ( @list ) {
      cmp_ok $q->remove, '==', $_, "remove in sorted order $_";
    }
  }
};

done_testing;
