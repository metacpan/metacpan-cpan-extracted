use strict;
use warnings;
use utf8;
use open qw( :std :utf8 );
use Test::More;
use Test::Exception;
use Test::Mock::Time;
use EV;
use Time::HiRes qw( sleep );

BEGIN {
    eval { Time::HiRes->import(qw( CLOCK_MONOTONIC clock_gettime )) };
    plan skip_all => 'Time::HiRes::clock_gettime(): unimplemented in this platform' if !exists &clock_gettime;
}
use Sub::Throttler::Rate::AnyEvent;


my ($throttle, $t);

my $Flush = 0;
{ no warnings 'redefine';
  sub Sub::Throttler::Limit::throttle_flush { $Flush++ }
  sub Sub::Throttler::Rate::AnyEvent::throttle_flush { $Flush++ }
  sub get_flush { my $flush = $Flush; $Flush = 0; return $flush }
}

sub used {
    my ($throttle, $key) = @_;
    return undef if !exists $throttle->{used}{$key};
    my $time = clock_gettime(CLOCK_MONOTONIC);
    $time -= $throttle->{period};
    if ($time < 0) {
        $time = 0;
    }
    my $rr = $throttle->{used}{$key};
    return 0+grep {$_ > $time} @{ $rr->{data} };
}

# - new
#   * значение limit по умолчанию 1
#   * значение period по умолчанию 1

$throttle = Sub::Throttler::Rate::AnyEvent->new;
ok $throttle->try_acquire('id1', 'key1', 1);
ok !$throttle->try_acquire('id2', 'key1', 1);
is $throttle->limit, 1,
    'limit = 1';

$t = EV::timer 1.1, 0, sub { EV::break };
EV::run;
ok $throttle->try_acquire('id2', 'key1', 1);
is $throttle->period, 1,
    'period = 1';

#   * при limit = 0 try_acquire не проходит

$throttle = Sub::Throttler::Rate::AnyEvent->new(limit => 0);
ok !$throttle->try_acquire('id1', 'key1', 1),
    'limit = 0';

#   * при limit = n try_acquire даёт выделить до n (включительно) ресурса

$throttle = Sub::Throttler::Rate::AnyEvent->new(limit => 10);
$throttle->try_acquire('id1', 'key1', 3);
$throttle->try_acquire('id2', 'key1', 3);
$throttle->try_acquire('id3', 'key1', 3);
ok $throttle->try_acquire('id4', 'key1', 1),
    'acquire = n';
ok !$throttle->try_acquire('id5', 'key1', 1),
    'attempt to acquire more than n';

#   * некорректные параметры

throws_ok { Sub::Throttler::Rate::AnyEvent->new('limit')      } qr/hash/;
throws_ok { Sub::Throttler::Rate::AnyEvent->new(limit => -2)  } qr/unsigned integer/;
throws_ok { Sub::Throttler::Rate::AnyEvent->new(limit => q{}) } qr/unsigned integer/;
throws_ok { Sub::Throttler::Rate::AnyEvent->new(duration => 1)} qr/bad param/;
throws_ok { Sub::Throttler::Rate::AnyEvent->new(duration => 1, limit => 1) } qr/bad param/;

#   * ресурсы освобождаются не когда текущее время кратно period, а через period

$t = EV::periodic 0, 0.5, 0, sub { EV::break };
EV::run;
$t = EV::timer 0.3, 0, sub { EV::break };
EV::run;
$throttle = Sub::Throttler::Rate::AnyEvent->new(period => 0.5);
$throttle->try_acquire('id1', 'key1', 1);
ok !$throttle->try_acquire('id2', 'key1', 1),
    'resource was not released (time not multi-periodic)';
$t = EV::timer 0.3, 0, sub { EV::break };
EV::run;
ok !$throttle->try_acquire('id2', 'key1', 1),
    'resource was not released (time after multi-periodic)';
$t = EV::timer 0.3, 0, sub { EV::break };
EV::run;
ok $throttle->try_acquire('id2', 'key1', 1),
    'resource released';

# - try_acquire
#   * исключение при $quantity <= 0

$throttle = Sub::Throttler::Rate::AnyEvent->new;
throws_ok { $throttle->try_acquire('id1', 'key1', -1) } qr/quantity must be positive/,
    '$quantity < 0';
throws_ok { $throttle->try_acquire('id1', 'key1', 0) } qr/quantity must be positive/,
    '$quantity = 0';

#   * повторный запрос для тех же $id и $key кидает исключение

$throttle = Sub::Throttler::Rate::AnyEvent->new;
$throttle->try_acquire('id1', 'key1', 1);
throws_ok { $throttle->try_acquire('id1', 'key1', 1) } qr/already acquired/,
    'same $id and $key';

#   * возвращает истину/ложь в зависимости от того, удалось ли выделить
#     $quantity ресурсов для $key

$t = EV::periodic 0, 0.2, 0, sub { EV::break };
EV::run;
$throttle = Sub::Throttler::Rate::AnyEvent->new(limit => 5, period => 0.2);
ok $throttle->try_acquire('id1', 'key1', 4),
    'return true for $key';
ok !$throttle->try_acquire('id2', 'key1', 2),
    'return false for $key';

$t = EV::timer 0.1, 0, sub { EV::break };
EV::run;
ok !$throttle->try_acquire('id2', 'key1', 2);
$t = EV::timer 0.1, 0, sub { EV::break };
EV::run;
ok $throttle->try_acquire('id2', 'key1', 2);

#   (использовать {used} для контроля текущего значения)
#   * использовать разные значения $quantity так, чтобы последний try_acquire
#     попытался выделить:
#     - текущее значение меньше limit, выделяется ровно под limit

$throttle = Sub::Throttler::Rate::AnyEvent->new(limit => 5);
$throttle->try_acquire('id1', 'key1', 3);
is used($throttle, 'key1'), 3,
    'used';
ok $throttle->try_acquire('id2', 'key1', 2),
    'value < limit, acquiring to limit';
is used($throttle,'key1'), 5;

#     - текущее значение меньше limit, выделяется больше limit

$throttle = Sub::Throttler::Rate::AnyEvent->new(limit => 5);
$throttle->try_acquire('id1', 'key1', 3);
ok !$throttle->try_acquire('id2', 'key1', 3),
    'value < limit, acquiring above limit';
is used($throttle,'key1'), 3;

#     - текущее значение равно limit, выделяется 1

$throttle = Sub::Throttler::Rate::AnyEvent->new(limit => 5);
$throttle->try_acquire('id1', 'key1', 5);
ok !$throttle->try_acquire('id2', 'key1', 1),
    'value = limit, acquire 1';

#   * под разные $key ресурсы выделяются независимо

$throttle = Sub::Throttler::Rate::AnyEvent->new(limit => 5);
ok $throttle->try_acquire('id1', 'key1', 5);
ok $throttle->try_acquire('id1', 'key2', 5),
    'different $key are independent';

#   * увеличиваем текущий limit()
#     - проходят try_acquire, которые до этого не проходили

$throttle = Sub::Throttler::Rate::AnyEvent->new(limit => 5);
$throttle->try_acquire('id1', 'key1', 4);
ok !$throttle->try_acquire('id2', 'key1', 4);
$throttle->limit(10);
ok $throttle->try_acquire('id2', 'key1', 4),
    'increase current limit()';

#   * уменьшить текущий limit()
#     - не проходят try_acquire, которые до этого бы прошли

$throttle = Sub::Throttler::Rate::AnyEvent->new(limit => 10);
$throttle->try_acquire('id1', 'key1', 4);
$throttle->limit(5);
ok !$throttle->try_acquire('id2', 'key1', 4),
    'decrease current limit()';

# - release, release_unused
#   * кидает исключение если для $id нет выделенных ресурсов

$throttle = Sub::Throttler::Rate::AnyEvent->new;
throws_ok { $throttle->release('id1') } qr/not acquired/,
    'no acquired resourced for $id';
throws_ok { $throttle->release_unused('id1') } qr/not acquired/,
    'no acquired resourced for $id';

#   (использовать {used} для контроля текущего значения)
#   * release не освобождает ресурсы, release_unused освобождает
#     все ресурсы ($key+$quantity), выделенные для $id, если вызывается
#     в тот же период времени, когда они были захвачены
#     - под $id был выделен один $key, период тот же

$throttle = Sub::Throttler::Rate::AnyEvent->new(limit => 2);
$throttle->try_acquire('id1', 'key1', 1);
$throttle->try_acquire('id2', 'key2', 2);
ok !$throttle->try_acquire('id3', 'key1', 2);
ok !$throttle->try_acquire('id3', 'key2', 1);
is used($throttle,'key1'), 1;
$throttle->release_unused('id1');
is used($throttle,'key1'), undef;
ok $throttle->try_acquire('id3', 'key1', 2);
ok !$throttle->try_acquire('id3', 'key2', 1);
is used($throttle,'key2'), 2;
$throttle->release('id2');
is used($throttle,'key2'), 2;
ok !$throttle->try_acquire('id3', 'key2', 1);

#     - под $id был выделен один $key, период другой

$throttle = Sub::Throttler::Rate::AnyEvent->new(limit => 2, period => 0.1);
$throttle->try_acquire('id1', 'key1', 1);
$throttle->try_acquire('id2', 'key2', 2);
ok !$throttle->try_acquire('id3', 'key1', 2);
ok !$throttle->try_acquire('id3', 'key2', 1);
is used($throttle,'key1'), 1;
is used($throttle,'key2'), 2;
$t = EV::timer 0.11, 0, sub { EV::break };
EV::run;
is used($throttle,'key1'), undef;
is used($throttle,'key2'), undef;
lives_ok  { $throttle->release_unused('id1') };
throws_ok { $throttle->release_unused('id1') } qr/not acquired/;
lives_ok  { $throttle->release('id2') };
throws_ok { $throttle->release('id2') } qr/not acquired/;
is used($throttle,'key1'), undef;
is used($throttle,'key2'), undef;

#     - под $id было выделено несколько $key, период тот же

$throttle = Sub::Throttler::Rate::AnyEvent->new(limit => 5);
$throttle->try_acquire('id1', 'key1', 1);
$throttle->try_acquire('id1', 'key2', 2);
$throttle->try_acquire('id1', 'key3', 3);
$throttle->try_acquire('id2', 'key4', 4);
$throttle->try_acquire('id2', 'key5', 5);
ok !$throttle->try_acquire('id3', 'key1', 5);
ok !$throttle->try_acquire('id3', 'key2', 4);
ok !$throttle->try_acquire('id3', 'key3', 3);
ok !$throttle->try_acquire('id3', 'key4', 2);
ok !$throttle->try_acquire('id3', 'key5', 1);
$throttle->release('id1');
ok !$throttle->try_acquire('id3', 'key1', 5);
ok !$throttle->try_acquire('id3', 'key2', 4);
ok !$throttle->try_acquire('id3', 'key3', 3);
ok !$throttle->try_acquire('id3', 'key4', 2);
ok !$throttle->try_acquire('id3', 'key5', 1);
$throttle->release_unused('id2');
ok $throttle->try_acquire('id3', 'key4', 2);
ok $throttle->try_acquire('id3', 'key5', 1);

#     - под $id было выделено несколько $key, период другой

$throttle = Sub::Throttler::Rate::AnyEvent->new(limit => 5, period => 0.01);
$throttle->try_acquire('id1', 'key1', 1);
$throttle->try_acquire('id1', 'key2', 2);
$throttle->try_acquire('id1', 'key3', 3);
$throttle->try_acquire('id2', 'key4', 4);
$throttle->try_acquire('id2', 'key5', 5);
ok !$throttle->try_acquire('id3', 'key1', 5);
ok !$throttle->try_acquire('id3', 'key2', 4);
ok !$throttle->try_acquire('id3', 'key3', 3);
ok !$throttle->try_acquire('id3', 'key4', 2);
ok !$throttle->try_acquire('id3', 'key5', 1);
is used($throttle,'key1'), 1;
is used($throttle,'key2'), 2;
is used($throttle,'key3'), 3;
is used($throttle,'key4'), 4;
is used($throttle,'key5'), 5;
$t = EV::timer 0.015, 0, sub { EV::break };
EV::run;
is used($throttle,'key1'), undef;
is used($throttle,'key2'), undef;
is used($throttle,'key3'), undef;
is used($throttle,'key4'), undef;
is used($throttle,'key5'), undef;
lives_ok  { $throttle->release('id1') };
throws_ok { $throttle->release('id1') } qr/not acquired/;
lives_ok  { $throttle->release_unused('id2') };
throws_ok { $throttle->release_unused('id2') } qr/not acquired/;
is used($throttle,'key1'), undef;
is used($throttle,'key2'), undef;
is used($throttle,'key3'), undef;
is used($throttle,'key4'), undef;
is used($throttle,'key5'), undef;

#   * уменьшить текущий limit()
#     - после release текущее значение всё ещё >= limit, и try_acquire не проходит

$throttle = Sub::Throttler::Rate::AnyEvent->new(limit => 5);
$throttle->try_acquire('id1', 'key1', 1);
$throttle->try_acquire('id2', 'key2', 2);
sleep 0.01; # needed because of Test::Mock::Time to make sure different acquires for 'key2' happens at different times
$throttle->try_acquire('id3', 'key1', 4);
$throttle->try_acquire('id3', 'key2', 3);
$throttle->limit(3);
$throttle->release('id1');
ok !$throttle->try_acquire('id1', 'key1', 1);
$throttle->release_unused('id2');
ok !$throttle->try_acquire('id2', 'key2', 1);

# - при освобождении ресурсов вызывается Sub::Throttler::throttle_flush()
#   * только release_unused вызывает Sub::Throttler::throttle_flush()

$Flush = 0;
$throttle = Sub::Throttler::Rate::AnyEvent->new(limit => 5);
$throttle->try_acquire('id1', 'key1', 5);
$throttle->try_acquire('id2', 'key2', 5);
$throttle->release('id1');
is $Flush, 0;
$throttle->release_unused('id2');
is $Flush, 1;

#   * Sub::Throttler::throttle_flush() вызывается через period после
#     захвата ресурсов (а значит они были освобождены через period)

get_flush();
$throttle = Sub::Throttler::Rate::AnyEvent->new(period => 0.5);
$throttle->try_acquire('id1', 'key1', 1);
$t = EV::timer 0.51, 0, sub { EV::break };
EV::run;
ok get_flush(),
    'resource was acquired: throttle_flush() called after period';
$t = EV::timer 0.5, 0, sub { EV::break };
EV::run;
ok !get_flush(),
    'resource was not acquired: throttle_flush() not called after period';
$throttle->try_acquire('id1', 'key2', 1);
$t = EV::timer 0.1, 0, sub { EV::break };
EV::run;
ok !get_flush(),
    'first resource was acquired: throttle_flush() not called yet';
$throttle->try_acquire('id1', 'key3', 1);
$t = EV::timer 0.3, 0, sub { EV::break };
EV::run;
ok !get_flush(),
    'second resource was acquired: throttle_flush() not called yet';
$t = EV::timer 0.1, 0, sub { EV::break };
EV::run;
ok get_flush(),
    'first resource was released: throttle_flush() called after first period';
$t = EV::timer 0.1, 0, sub { EV::break };
EV::run;
ok get_flush(),
    'second resource was released: throttle_flush() called after second period';
$throttle->try_acquire('id1', 'key4', 2);
$t = EV::timer 0.5, 0, sub { EV::break };
EV::run;
ok !get_flush(),
    'resource failed to acquire: throttle_flush() not called after period';

#   * watcher deactivates when all resources released

$throttle->try_acquire('id1', 'key4', 1);
$throttle->release('id1');
$t = EV::timer 0.4, 0, sub { EV::break };
ok EV::run,
    'watcher is active because resources was not released yet';
$t = EV::timer 0.1, 0, sub { EV::break };
ok !EV::run,
    'watcher is inactive because there are no acquired resources';

# - limit
#   * при увеличении limit() вызывается Sub::Throttler::throttle_flush

$throttle = Sub::Throttler::Rate::AnyEvent->new(limit => 5);
$Flush = 0;
$throttle->limit(3);
is $Flush, 0;
$throttle->limit(4);
is $Flush, 1;

#   * chaining

is $throttle->limit(4), $throttle;

#   * при уменьшении limit() в течении period может использоваться
#     максимальный из предыдущих limit использовавшихся в течении
#     текущего period

$throttle = Sub::Throttler::Rate::AnyEvent->new(limit => 10, period => 0.1);
ok $throttle->try_acquire('id1','key',2),
    'acquired 2 (2/10)';
ok $throttle->try_acquire('id2','key',3),
    'acquired 3 (5/10)';
sleep 0.01; # needed because of Test::Mock::Time to make sure different acquires for 'key' happens at different times
ok $throttle->try_acquire('id3','key',5),
    'acquired 5 (10/10)';
$throttle->limit(5);
ok !$throttle->try_acquire('id4','key',1),
    'failed to acquire 1 (11/5)';
$throttle->release_unused('id1');
$throttle->release_unused('id2');
ok !$throttle->try_acquire('id4','key',1),
    'failed to acquire 1 (11/5)';

$throttle = Sub::Throttler::Rate::AnyEvent->new(limit => 10, period => 0.1);
ok $throttle->try_acquire('id1','key',5),
    'acquired 5 (5/10)';
ok $throttle->try_acquire('id2','key',3),
    'acquired 3 (8/10)';
ok $throttle->try_acquire('id3','key',2),
    'acquired 2 (10/10)';
ok !$throttle->try_acquire('id4','key',1),
    'failed to acquire 1 (11/10)';
$throttle->limit(5);
ok !$throttle->try_acquire('id4','key',1),
    'failed to acquire 1 (11/5)';
$throttle->release_unused('id3');
ok $throttle->try_acquire('id3','key',2),
    'acquired 2 (10/5)';
$throttle->limit(2);
ok !$throttle->try_acquire('id4','key',1),
    'failed to acquire 1 (11/2)';
$throttle->release_unused('id3');
ok $throttle->try_acquire('id3','key',2),
    'acquired 2 (10/2)';
ok !$throttle->try_acquire('id4','key',1),
    'failed to acquire 1 (11/2)';
sleep 0.1;
ok $throttle->try_acquire('id4','key',2),
    'acquired 2 (2/2)';
ok !$throttle->try_acquire('id5','key',1),
    'failed to acquire 1 (3/2)';

# - period
#   * изменение period срабатывает сразу

undef $throttle;
get_flush();

$t = EV::periodic 0, 0.5, 0, sub { EV::break };
EV::run;
$throttle = Sub::Throttler::Rate::AnyEvent->new(period => 0.5);
is $throttle->period, 0.5,
    'period set to 0.5';
$throttle->try_acquire('id1', 'key1', 1);
$t = EV::timer 0.3, 0, sub { EV::break };
EV::run;
ok !get_flush(),
    'period > 0.3';
$t = EV::timer 0.3, 0, sub { EV::break };
EV::run;
ok get_flush(),
    'period < 0.6';

$t = EV::periodic 0, 0.1, 0, sub { EV::break };
EV::run;
$throttle->try_acquire('id1', 'key2', 1);
$throttle->period(0.1);
is $throttle->period, 0.1,
    'set period to 0.1';
$t = EV::timer 0.3, 0, sub { EV::break };
EV::run;
ok get_flush(),
    'period < 0.3';

$t = EV::periodic 0, 0.5, 0, sub { EV::break };
EV::run;
$throttle->try_acquire('id1', 'key3', 1);
$throttle->period(0.5);
is $throttle->period, 0.5,
    'set period to 0.5';
ok used($throttle, 'key3');
$t = EV::timer 0.3, 0, sub { EV::break };
EV::run;
ok used($throttle, 'key3'),
    'period > 0.3';
$t = EV::timer 0.3, 0, sub { EV::break };
EV::run;
ok !used($throttle, 'key3'),
    'period < 0.6';

#   * chaining

is $throttle->period(0.5), $throttle;

# - apply_to
#   * некорректные параметры:
#     - не 2 параметра

$throttle = Sub::Throttler::Rate::AnyEvent->new;
throws_ok { $throttle->apply_to() } qr/require 2 params/;

#     - второй не ссылка на функцию

throws_ok { $throttle->apply_to(undef) } qr/target must be CODE/;
throws_ok { $throttle->apply_to('asd') } qr/target must be CODE/;
throws_ok { $throttle->apply_to(42) } qr/target must be CODE/;
throws_ok { $throttle->apply_to([1,2,3]) } qr/target must be CODE/;
throws_ok { $throttle->apply_to({key1 => 1, key2 => 2}) } qr/target must be CODE/;


done_testing();
