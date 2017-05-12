package # hide
Test;
use Moose;

has stash => ( is => 'rw', isa => 'HashRef', traits => [qw(MergeHashRef)] );

package main;

use Test::More;

my $t = Test->new(stash => { foo => 'bar'});

is_deeply($t->stash, { foo => 'bar' });

ok($t->stash({ cat => 'mouse' }));

is_deeply($t->stash, { foo => 'bar', cat => 'mouse' });

ok($t->clear_stash);

ok($t->stash({ cat => 'mouse' }));

is_deeply($t->stash, { cat => 'mouse' });

ok($t->stash({ cat => { foo => 'bar'} }));

is_deeply($t->stash, { cat => { foo => 'bar' } });

ok($t->stash({ cat => { mouse => 'cat' } }));

is_deeply($t->stash, { cat => { mouse => 'cat', foo => 'bar' } });

ok($t->set_stash({ cat => 'mouse' }));

is_deeply($t->stash, { cat => 'mouse' });

done_testing;