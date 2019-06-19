use Test2::V0;
use Test::LeakTrace qw(no_leaks_ok);
use Promises qw(collect);
use Promises::Channel qw(channel);

no_leaks_ok {
  my $ch = channel
    limit => 5;

  isa_ok $ch, 'Promises::Channel';
  is $ch->size, 0, 'size initially 0';
  ok $ch->is_empty, 'initially empty';
  ok !$ch->is_full, 'not initially full';
  ok !$ch->is_shutdown, 'is_shutdown initially false';

  my $put_count = 0;
  my $get_count = 0;
  my @items = 1 .. 10;
  my @out;

  collect(
      map {
        $ch->get->then(sub {
          my ($ch, $item) = @_;
          push @out, $item;
          ++$get_count;
        })
      } @items
    )
    ->then(sub { is $get_count, 10, '10 items retrieved' })
    ->then(sub { is \@out, \@items, 'retrieved expected items' })
    ->catch(sub { ok 0, "get failed with: @_" });

  collect(map { $ch->put($_)->then(sub { ++$put_count }) } @items)
    ->then(sub { is $put_count, 10, '10 items added' })
    ->catch(sub { ok 0, "put failed with: @_" });

  my $shutdown = 0;
  $ch->on_shutdown
      ->then(sub { $shutdown = 1; });
  $ch->shutdown;
  ok $ch->is_shutdown, 'is_shutdown true after shutdown';
  ok $shutdown, 'on_shutdown promise has been resolved after shutdown';

  $ch->get->then(
    sub {
      my ($ch, $item) = @_;
      is $item, U, 'get resolved with undef after shutdown';
    },
    sub { ok 0, 'get rejected after shutdown' },
  );
};

done_testing;
