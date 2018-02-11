package My::EventEmitter;
use Role::Tiny::With;
with 'Role::EventEmitter';

sub new { bless {}, shift }

package main;
use strict;
use warnings;
use Test::More;
use Test::Needs 'Future';

my $e = My::EventEmitter->new;

# One-time event
my $once;
my $f = $e->once_f('one_time')->on_done(sub { $once++ });
is scalar @{$e->subscribers('one_time')}, 1, 'one subscriber';
$e->unsubscribe(one_time => sub { });
is scalar @{$e->subscribers('one_time')}, 1, 'one subscriber';
$e->emit('one_time');
is $once, 1, 'event was emitted once';
is scalar @{$e->subscribers('one_time')}, 0, 'no subscribers';
$e->emit('one_time');
is $once, 1, 'event was not emitted again';
$e->emit('one_time');
is $once, 1, 'event was not emitted again';
$e->emit('one_time');
is $once, 1, 'event was not emitted again';
my $f2;
$f = $e->once_f('one_time')->on_done(sub {
  $f2 = shift->once_f('one_time')->on_done(sub { $once++ });
});
$e->emit('one_time');
is $once, 1, 'event was emitted once';
$e->emit('one_time');
is $once, 2, 'event was emitted again';
$e->emit('one_time');
is $once, 2, 'event was not emitted again';
$f = $e->once_f('one_time')->on_done(sub { $once = shift->has_subscribers('one_time') });
$e->emit('one_time');
ok !$once, 'no subscribers';

# Nested one-time events
$once = 0;
my $f3;
$f = $e->once_f('one_time')
  ->on_done(sub {
    $f2 = shift->once_f('one_time')
      ->on_done(sub {
        $f3 = shift->once_f('one_time')->on_done(sub { $once++ });
      }
    );
  }
);
is scalar @{$e->subscribers('one_time')}, 1, 'one subscriber';
$e->emit('one_time');
is $once, 0, 'only first event was emitted';
is scalar @{$e->subscribers('one_time')}, 1, 'one subscriber';
$e->emit('one_time');
is $once, 0, 'only second event was emitted';
is scalar @{$e->subscribers('one_time')}, 1, 'one subscriber';
$e->emit('one_time');
is $once, 1, 'third event was emitted';
is scalar @{$e->subscribers('one_time')}, 0, 'no subscribers';
$e->emit('one_time');
is $once, 1, 'event was not emitted again';
$e->emit('one_time');
is $once, 1, 'event was not emitted again';
$e->emit('one_time');
is $once, 1, 'event was not emitted again';

# One-time event used directly
$e = My::EventEmitter->new;
ok !$e->has_subscribers('foo'), 'no subscribers';
$once = 0;
$f = $e->once_f('foo')->on_done(sub { $once++ });
ok $e->has_subscribers('foo'), 'has subscribers';
$f->done;
is $once, 1, 'event was emitted once';
ok !$e->has_subscribers('foo'), 'no subscribers';

# Cancel
$e = My::EventEmitter->new;
my $counter;
$f = $e->once_f('foo')->on_done(sub { $counter++ });
$f->cancel;
is scalar @{$e->subscribers('foo')}, 0, 'no subscribers';
$e->emit('foo');
is $counter, undef, 'event was not emitted';

# Unsubscribe
$e = My::EventEmitter->new;
$f = $e->once_f('foo')->on_done(sub { $counter++ });
$e->unsubscribe(foo => $e->subscribers('foo')->[0]);
is scalar @{$e->subscribers('foo')}, 0, 'no subscribers';
ok $f->is_cancelled, 'future is cancelled';
$e->emit('foo');
is $counter, undef, 'event was not emitted';

# Unsubscribe all
$e = My::EventEmitter->new;
$f = $e->once_f('foo')->on_done(sub { $counter++ });
$e->unsubscribe('foo');
is scalar @{$e->subscribers('foo')}, 0, 'no subscribers';
ok $f->is_cancelled, 'future is cancelled';
$e->emit('foo');
is $counter, undef, 'event was not emitted';

done_testing();
