use strict;
use warnings;
use utf8;
use open qw( :std :utf8 );
use Test::More;
use Test::Exception;

use Sub::Throttler::Limit;


my ($throttle, $t);

my $Flush = 0;
{ no warnings 'redefine';
  sub Sub::Throttler::Limit::throttle_flush { $Flush++ }
}

# - new
#   * значение limit по умолчанию 1

$throttle = Sub::Throttler::Limit->new;
ok $throttle->try_acquire('id1', 'key1', 1);
ok !$throttle->try_acquire('id2', 'key1', 1);
is $throttle->limit, 1,
    'limit = 1';

#   * при limit = 0 try_acquire не проходит

$throttle = Sub::Throttler::Limit->new(limit => 0);
ok !$throttle->try_acquire('id1', 'key1', 1),
    'limit = 0';

#   * при limit = n try_acquire даёт выделить до n (включительно) ресурса

$throttle = Sub::Throttler::Limit->new(limit => 10);
$throttle->try_acquire('id1', 'key1', 3);
$throttle->try_acquire('id2', 'key1', 3);
$throttle->try_acquire('id3', 'key1', 3);
ok $throttle->try_acquire('id4', 'key1', 1),
    'acquire = n';
ok !$throttle->try_acquire('id5', 'key1', 1),
    'attempt to acquire more, then n';

#   * некорректные параметры

throws_ok { Sub::Throttler::Limit->new('limit')         } qr/hash/;
throws_ok { Sub::Throttler::Limit->new(limit => -2)     } qr/unsigned integer/;
throws_ok { Sub::Throttler::Limit->new(limit => q{})    } qr/unsigned integer/;
throws_ok { Sub::Throttler::Limit->new(period => 1)     } qr/bad param/;
throws_ok { Sub::Throttler::Limit->new(period => 1, limit => 1) } qr/bad param/;

# - try_acquire
#   * исключение при $quantity <= 0

$throttle = Sub::Throttler::Limit->new;
throws_ok { $throttle->try_acquire('id1', 'key1', -1) } qr/quantity must be positive/,
    '$quantity < 0';
throws_ok { $throttle->try_acquire('id1', 'key1', 0) } qr/quantity must be positive/,
    '$quantity = 0';

#   * повторный запрос для тех же $id и $key кидает исключение

$throttle = Sub::Throttler::Limit->new;
$throttle->try_acquire('id1', 'key1', 1);
throws_ok { $throttle->try_acquire('id1', 'key1', 1) } qr/already acquired/,
    'same $id and $key';

#   * возвращает истину/ложь в зависимости от того, удалось ли выделить
#     $quantity ресурсов для $key

$throttle = Sub::Throttler::Limit->new(limit => 5);
ok $throttle->try_acquire('id1', 'key1', 4),
    'return true for $key';
ok !$throttle->try_acquire('id2', 'key1', 2),
    'return false for $key';

#   (использовать {used} для контроля текущего значения)
#   * использовать разные значения $quantity так, чтобы последний try_acquire
#     попытался выделить:
#     - текущее значение меньше limit, выделяется ровно под limit

$throttle = Sub::Throttler::Limit->new(limit => 5);
$throttle->try_acquire('id1', 'key1', 3);
is $throttle->{used}{key1}, 3,
    'used';
ok $throttle->try_acquire('id2', 'key1', 2),
    'value < limit, acquiring to limit';
is $throttle->{used}{key1}, 5;

#     - текущее значение меньше limit, выделяется больше limit

$throttle = Sub::Throttler::Limit->new(limit => 5);
$throttle->try_acquire('id1', 'key1', 3);
ok !$throttle->try_acquire('id2', 'key1', 3),
    'value < limit, acquiring above limit';
is $throttle->{used}{key1}, 3;

#     - текущее значение равно limit, выделяется 1

$throttle = Sub::Throttler::Limit->new(limit => 5);
$throttle->try_acquire('id1', 'key1', 5);
ok !$throttle->try_acquire('id2', 'key1', 1),
    'value = limit, acquire 1 more';

#   * под разные $key ресурсы выделяются независимо

$throttle = Sub::Throttler::Limit->new(limit => 5);
ok $throttle->try_acquire('id1', 'key1', 5);
ok $throttle->try_acquire('id1', 'key2', 5),
    'different $key are independent';

#   * увеличиваем текущий limit()
#     - проходят try_acquire, которые до этого не проходили

$throttle = Sub::Throttler::Limit->new(limit => 5);
$throttle->try_acquire('id1', 'key1', 4);
ok !$throttle->try_acquire('id2', 'key1', 4);
$throttle->limit(10);
ok $throttle->try_acquire('id2', 'key1', 4),
    'increase current limit()';

#   * уменьшить текущий limit()
#     - не проходят try_acquire, которые до этого бы прошли

$throttle = Sub::Throttler::Limit->new(limit => 10);
$throttle->try_acquire('id1', 'key1', 4);
$throttle->limit(5);
ok !$throttle->try_acquire('id2', 'key1', 4),
    'decrease current limit()';

# - release, release_unused
#   * кидает исключение если для $id нет выделенных ресурсов

$throttle = Sub::Throttler::Limit->new;
throws_ok { $throttle->release('id1') } qr/not acquired/,
    'no acquired resources for $id';
throws_ok { $throttle->release_unused('id1') } qr/not acquired/,
    'no acquired resources for $id';

#   (использовать {used} для контроля текущего значения)
#   * освобождают все ресурсы ($key+$quantity), выделенные для $id
#     - под $id был выделен один $key

$throttle = Sub::Throttler::Limit->new(limit => 2);
$throttle->try_acquire('id1', 'key1', 1);
$throttle->try_acquire('id2', 'key2', 2);
ok !$throttle->try_acquire('id3', 'key1', 2);
ok !$throttle->try_acquire('id3', 'key2', 1);
is $throttle->{used}{key1}, 1;
$throttle->release_unused('id1');
is $throttle->{used}{key1}, undef;
ok $throttle->try_acquire('id3', 'key1', 2);
ok !$throttle->try_acquire('id3', 'key2', 1);
is $throttle->{used}{key2}, 2;
$throttle->release('id2');
is $throttle->{used}{key2}, undef;
ok $throttle->try_acquire('id3', 'key2', 1);

#     - под $id было выделено несколько $key

$throttle = Sub::Throttler::Limit->new(limit => 5);
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
ok $throttle->try_acquire('id3', 'key1', 5);
ok $throttle->try_acquire('id3', 'key2', 4);
ok $throttle->try_acquire('id3', 'key3', 3);
ok !$throttle->try_acquire('id3', 'key4', 2);
ok !$throttle->try_acquire('id3', 'key5', 1);
$throttle->release_unused('id2');
ok $throttle->try_acquire('id3', 'key4', 2);
ok $throttle->try_acquire('id3', 'key5', 1);

#   * уменьшить текущий limit()
#     - после release текущее значение всё ещё >= limit, и try_acquire не проходит

$throttle = Sub::Throttler::Limit->new(limit => 5);
$throttle->try_acquire('id1', 'key1', 1);
$throttle->try_acquire('id2', 'key2', 2);
$throttle->try_acquire('id3', 'key1', 4);
$throttle->try_acquire('id3', 'key2', 3);
$throttle->limit(3);
$throttle->release('id1');
ok !$throttle->try_acquire('id1', 'key1', 1);
$throttle->release_unused('id2');
ok !$throttle->try_acquire('id2', 'key2', 1);

#   * вызывают Sub::Throttler::throttle_flush()
$Flush = 0;
$throttle = Sub::Throttler::Limit->new(limit => 5);
$throttle->try_acquire('id1', 'key1', 5);
$throttle->try_acquire('id2', 'key2', 5);
$throttle->release('id1');
is $Flush, 1;
$throttle->release_unused('id2');
is $Flush, 2;

# - limit
#   * при увеличении limit() вызывается Sub::Throttler::throttle_flush

$throttle = Sub::Throttler::Limit->new(limit => 5);
$Flush = 0;
$throttle->limit(3);
is $Flush, 0;
$throttle->limit(4);
is $Flush, 1;

#   * chaining

is $throttle->limit(4), $throttle;

# - apply_to
#   * некорректные параметры:
#     - не 2 параметра

$throttle = Sub::Throttler::Limit->new;
throws_ok { $throttle->apply_to() } qr/require 2 params/;

#     - второй не ссылка на функцию

throws_ok { $throttle->apply_to(undef) } qr/target must be CODE/;
throws_ok { $throttle->apply_to('asd') } qr/target must be CODE/;
throws_ok { $throttle->apply_to(42) } qr/target must be CODE/;
throws_ok { $throttle->apply_to([1,2,3]) } qr/target must be CODE/;
throws_ok { $throttle->apply_to({key1 => 1, key2 => 2}) } qr/target must be CODE/;


done_testing();
