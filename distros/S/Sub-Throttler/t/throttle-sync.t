use strict;
use warnings;
use utf8;
use open qw( :std :utf8 );
use Test::More;
use Test::Exception;
use Test::Mock::Time;
use Time::HiRes qw( time sleep );

BEGIN {
    eval { Time::HiRes->import(qw( CLOCK_MONOTONIC clock_gettime )) };
    plan skip_all => 'Time::HiRes::clock_gettime(): unimplemented in this platform' if !exists &clock_gettime;
}

use Sub::Throttler qw( :ALL );
use Sub::Throttler::Limit;
use Sub::Throttler::Rate::AnyEvent;


my (@Result, $time);
my ($throttle, $throttle2);
my $prepare;
my $obj = new();

sub new {
    return bless {};
}

my @DONE = ();
sub func {
    my $done = &throttle_me_sync;
    my @p = @_;
    push @Result, $p[0];
    $done->(@DONE);
    return;
}

sub method {
#     my $done = &throttle_me_sync;
    my ($self, @p) = @_;
    push @Result, $p[0];
#     $done->();
    return;
}
throttle_it('main::method');

sub top_func {
    my $done = &throttle_me_sync;
    func('top_func');
    my @p = @_;
    push @Result, $p[0];
    $done->();
    return;
}

# - throttle_add()
#   * запускать:
#     - функцию
#     - метод объекта
#   * нет add() - ограничений нет

@Result = ();
func(10);
$obj->method(30);
is_deeply \@Result, [10,30],
    'func & method';

#   * один add() - ограничения есть

$throttle = Sub::Throttler::Rate::AnyEvent->new(period=>0.1)->apply_to(sub {
    return { key => 1 };
});

@Result = ();
$time = time;
func(10);
is_deeply \@Result, [10],
    'func';
is time, $time,
    'no delay';
$obj->method(30);
is_deeply \@Result, [10,30],
    'method';
is time, $time+0.1,
    'with delay';
sleep 0.1;

#   * несколько add() - учитываются все ограничения

$throttle2 = Sub::Throttler::Rate::AnyEvent->new(period=>0.5,limit=>2)->apply_to(sub {
    my ($this, $name, @p) = @_;
    if (!$this) {
        return { key => 1 };
    } else {
        return;
    }
});

@Result = ();
$time = time;
func(10);
is_deeply \@Result, [10],
    'func';
is time, $time,
    'no delay';
func(20);
is_deeply \@Result, [10,20],
    'func';
is time, $time+=0.1,
    'with small delay';
$obj->method(30);
is_deeply \@Result, [10,20,30],
    'method';
is time, $time+=0.1,
    'with small delay';
func(40);
is_deeply \@Result, [10,20,30,40],
    'func';
is time, $time+=0.3,
    'with long delay';
func(50);
is_deeply \@Result, [10,20,30,40,50],
    'func';
is time, $time+0.1,
    'with small delay';

#   * del($throttle2)
#     - ограничения есть только для $throttle

throttle_del($throttle2);

@Result = ();
$time = time;
func(10);
is_deeply \@Result, [10],
    'func';
is time, $time+=0.1,
    'with small delay';
func(20);
is_deeply \@Result, [10,20],
    'func';
is time, $time+=0.1,
    'with small delay';
func(30);
is_deeply \@Result, [10,20,30],
    'func';
is time, $time+=0.1,
    'with small delay';

#   * несколько add() с одинаковым объектом $throttle:
#     - $target-функции каждого add() срабатывают на разные цели

throttle_del();
$throttle = Sub::Throttler::Rate::AnyEvent->new(period=>0.1)
    ->apply_to_functions('func')
    ->apply_to_methods(ref $obj, 'method')
    ;

@Result = ();
$time = time;
func(10);
is_deeply \@Result, [10],
    'func';
is time, $time,
    'no delay';
$obj->method(20);
is_deeply \@Result, [10,20],
    'method';
is time, $time+=0.1,
    'with small delay';
func(30);
is_deeply \@Result, [10,20,30],
    'func';
is time, $time+=0.1,
    'with small delay';

#     - $target-функции каждого add() срабатывают на одинаковые цели с разными $key

$prepare = sub {
    Sub::Throttler::_reset();
    $throttle = Sub::Throttler::Limit->new
        ->apply_to(sub {
            my ($this, $name) = @_;
            return $name eq 'method' ? {key1=>1} : undef;
        })
        ->apply_to(sub {
            my ($this, $name) = @_;
            return $name eq 'method' ? {key2=>1} : undef;
        });
    @Result = ();
};

&$prepare;
$throttle->{used}{key1} = 1;
$throttle->{used}{key2} = 1;
throws_ok { local $SIG{__WARN__}=sub{}; $obj->method(10) } qr/unable to acquire/;

&$prepare;
$throttle->{used}{key1} = 0;
$throttle->{used}{key2} = 1;
throws_ok { local $SIG{__WARN__}=sub{}; $obj->method(10) } qr/unable to acquire/;

&$prepare;
$throttle->{used}{key1} = 1;
$throttle->{used}{key2} = 0;
throws_ok { local $SIG{__WARN__}=sub{}; $obj->method(10) } qr/unable to acquire/;

&$prepare;
$throttle->{used}{key1} = 0;
$throttle->{used}{key2} = 0;
lives_ok { $obj->method(10) };
is_deeply \@Result, [10],
    'key1 & key2';

#     - $target-функции каждого add() срабатывают на одинаковые цели с одинаковыми $key

throttle_del();
$throttle = Sub::Throttler::Limit->new
    ->apply_to_methods($obj, 'method')
    ->apply_to_methods($obj, 'method');

throws_ok { wait_err(); $obj->method(10) } qr/already acquired/,
    'same key';
get_warn(); Sub::Throttler::_reset();

#   * $target-функции корректно получают информацию о цели:

my @Target;
throttle_del();
Sub::Throttler::Limit->new->apply_to(sub {
    @Target = @_;
    return undef;
});

#     - функция

func();
is_deeply \@Target, [q{}, 'main::func'],
    'func';

#     - метод объекта

$obj->method();
is_deeply \@Target, [$obj, 'method'],
    'method';

#     - параметры функции/метода объекта

func(10,20);
is_deeply \@Target, [q{}, 'main::func', 10,20 ],
    'param. func';

$obj->method(30,40);
is_deeply \@Target, [$obj, 'method', 30,40],
    'param. method';

#   * $target-функции возвращают:
#     - ()

throttle_del();
$throttle = Sub::Throttler::Limit->new;
throttle_add($throttle, sub {
    return;
});

@Result = ();

$throttle->limit(0);
func(10);
is_deeply \@Result, [10],
    'return ()';

#     - undef

throttle_del();
$throttle = Sub::Throttler::Limit->new;
throttle_add($throttle, sub {
    return undef;
});

@Result = ();

$throttle->limit(0);
func(10);
is_deeply \@Result, [10],
    'return undef';

#     - {}

throttle_del();
$throttle = Sub::Throttler::Limit->new;
throttle_add($throttle, sub {
    return {};
});

@Result = ();

$throttle->limit(0);
func(10);
is_deeply \@Result, [10],
    'return {}';

#     - '' => 1

$prepare = sub {
    Sub::Throttler::_reset();
    $throttle = Sub::Throttler::Limit->new;
    throttle_add($throttle, sub {
        return { '' => 1 };
    });
    @Result = ();
};

&$prepare;
$throttle->{used}{''} = 1;
throws_ok { local $SIG{__WARN__}=sub{}; func(10) } qr/unable to acquire/;
&$prepare;
$throttle->{used}{''} = 0;
lives_ok { func(10) };
is_deeply \@Result, [10];

#     - $key => $quantity

$prepare = sub {
    Sub::Throttler::_reset();
    $throttle = Sub::Throttler::Limit->new;
    throttle_add($throttle, sub {
        return { key => 2 };
    });
    @Result = ();
};

&$prepare;
$throttle->{used}{key} = 1;
throws_ok { local $SIG{__WARN__}=sub{}; func(10) } qr/unable to acquire/;
&$prepare;
$throttle->limit(3);
lives_ok { func(10) };
is_deeply \@Result, [10];

#     - $key1 => $quantity1, ...

$prepare = sub {
    Sub::Throttler::_reset();
    $throttle = Sub::Throttler::Limit->new(limit => 5);
    throttle_add($throttle, sub {
        return { key1=>1, key2=>2, key3=>3 };
    });
    @Result = ();
};

&$prepare;
$throttle->{used}{key1} = 5;
throws_ok { local $SIG{__WARN__}=sub{}; func(10) } qr/unable to acquire/,
    'no key1 of 3 keys';
&$prepare;
$throttle->{used}{key2} = 4;
$throttle->{used}{key1} = 4;
throws_ok { local $SIG{__WARN__}=sub{}; func(10) } qr/unable to acquire/,
    'no key2 of 3 keys';
&$prepare;
$throttle->{used}{key3} = 3;
$throttle->{used}{key2} = 3;
throws_ok { local $SIG{__WARN__}=sub{}; func(10) } qr/unable to acquire/,
    'no key3 of 3 keys';
&$prepare;
$throttle->{used}{key3} = 2;
lives_ok { func(10) };
is_deeply \@Result, [10],
    '3 keys of 3 keys';

#     - некорректный результат: SCALAR, ARRAYREF или CODEREF

throttle_del();
throttle_add(Sub::Throttler::Limit->new, sub {
    return 0;
});

throws_ok { wait_err(); func() } qr/HASHREF/;
get_warn(); Sub::Throttler::_reset();

throttle_del();
throttle_add(Sub::Throttler::Limit->new, sub {
    return q{};
});

throws_ok { wait_err(); func() } qr/HASHREF/;
get_warn(); Sub::Throttler::_reset();

throttle_del();
throttle_add(Sub::Throttler::Limit->new, sub {
    return 'key';
});

throws_ok { wait_err(); func() } qr/HASHREF/;
get_warn(); Sub::Throttler::_reset();

throttle_del();
throttle_add(Sub::Throttler::Limit->new, sub {
    return ['key',1];
});

throws_ok { wait_err(); func() } qr/HASHREF/;
get_warn(); Sub::Throttler::_reset();

throttle_del();
throttle_add(Sub::Throttler::Limit->new, sub {
    return sub{};
});

throws_ok { wait_err(); func() } qr/HASHREF/;
get_warn(); Sub::Throttler::_reset();

#     - некорректный результат: $quantity не положительное число

throttle_del();
throttle_add(Sub::Throttler::Limit->new, sub {
    return {key1=>-1};
});

throws_ok { wait_err(); func() } qr/quantity must be positive/;
get_warn(); Sub::Throttler::_reset();

throttle_del();
throttle_add(Sub::Throttler::Limit->new, sub {
    return {key1=>0};
});

throws_ok { wait_err(); func() } qr/quantity must be positive/;
get_warn(); Sub::Throttler::_reset();

throttle_del();
throttle_add(Sub::Throttler::Limit->new, sub {
    return {key1=>'five'};
});

throws_ok { wait_err(); func() } qr/quantity must be positive/;
get_warn(); Sub::Throttler::_reset();

throttle_del();
throttle_add(Sub::Throttler::Limit->new, sub {
    return {key1=>\1};
});

throws_ok { wait_err(); func() } qr/bad quantity/;
get_warn(); Sub::Throttler::_reset();

throttle_del();
throttle_add(Sub::Throttler::Limit->new, sub {
    return {key1=>[]};
});

throws_ok { wait_err(); func() } qr/bad quantity/;
get_warn(); Sub::Throttler::_reset();

throttle_del();
throttle_add(Sub::Throttler::Limit->new, sub {
    return {key1=>{}};
});

throws_ok { wait_err(); func() } qr/bad quantity/;
get_warn(); Sub::Throttler::_reset();

throttle_del();
throttle_add(Sub::Throttler::Limit->new, sub {
    return {key1=>sub {}};
});

throws_ok { wait_err(); func() } qr/bad quantity/;
get_warn(); Sub::Throttler::_reset();

throttle_del();
throttle_add(Sub::Throttler::Limit->new(limit=>2), sub {
    return {key1=>1,key2=>-1,key3=>2};
});

throws_ok { wait_err(); func() } qr/quantity must be positive/;
get_warn(); Sub::Throttler::_reset();

throttle_del();
throttle_add(Sub::Throttler::Limit->new(limit=>2), sub {
    return {key1=>1,key2=>0,key3=>2};
});

throws_ok { wait_err(); func() } qr/quantity must be positive/;
get_warn(); Sub::Throttler::_reset();

throttle_del();
throttle_add(Sub::Throttler::Limit->new(limit=>2), sub {
    return {key1=>1,key2=>'five',key3=>2};
});

throws_ok { wait_err(); func() } qr/quantity must be positive/;
get_warn(); Sub::Throttler::_reset();

# - throttle_me
#   * использовать в:
#     - функции
#     - методе объекта
#   * нельзя использовать в анонимных функциях

my $func = sub {
    my $done = &throttle_me || return;
    my @p = @_;
    push @Result, $p[0];
    $done->();
    return;
};

@Result = ();
throws_ok { $func->() } qr/anonymous function/;

SKIP: {
    skip 'Sub::Util 1.40 not installed', 1 if !eval { require Sub::Util; Sub::Util->VERSION('1.40'); Sub::Util->import('set_subname') };
    set_subname('deanonimized', $func);
    throws_ok { $func->() } qr/anonymous function/;
}

#   * поддержка ссылок на функции

sub funcref {
    my $done = &throttle_me || return;
    my @p = @_;
    push @Result, $p[0];
    $done->();
    return;
};

$func = \&funcref;
lives_ok { $func->(50) };
lives_ok { $func->(60) };
is_deeply \@Result, [50,60],
    'coderef';

# - $done->( () or TRUE )
#   * освобождает все ресурсы через release()

package Sub::Throttler::Test;
use parent 'Sub::Throttler::Limit';
sub release         { push @Result, 'release';        return shift->SUPER::release(@_);        }
sub release_unused  { push @Result, 'release_unused'; return shift->SUPER::release_unused(@_); }
package main;

throttle_del();
throttle_add(Sub::Throttler::Test->new, sub {
    return { key => 1 };
});

@Result = ();
@DONE = (1);
func(10);
is_deeply \@Result, [10,'release'],
    '$done->() -> release()';

@Result = ();
@DONE = (-1,-2);
func(10);
is_deeply \@Result, [10,'release'],
    '$done->() -> release()';

@Result = ();
@DONE = ('done');
func(10);
is_deeply \@Result, [10,'release'],
    '$done->() -> release()';

@Result = ();
@DONE = ();
func(10);
is_deeply \@Result, [10,'release'],
    '$done->() -> release()';

# - $done->( FALSE )
#   * освобождает все ресурсы через release_unused()

@Result = ();
@DONE = (undef);
func(20);
is_deeply \@Result, [20,'release_unused'],
    '$done->(0) -> release_unused()';

@Result = ();
@DONE = (undef,1);
func(20);
is_deeply \@Result, [20,'release_unused'],
    '$done->(0) -> release_unused()';

@Result = ();
@DONE = (q{});
func(20);
is_deeply \@Result, [20,'release_unused'],
    '$done->(0) -> release_unused()';

@Result = ();
@DONE = (0);
func(20);
is_deeply \@Result, [20,'release_unused'],
    '$done->(0) -> release_unused()';

# - Sub::Throttler::throttle_flush()
#   * вызовы throttle_flush в процессе работы throttle_flush заменяются
#     одним, отложенным до завершения текущего (через tail recursion)

{
    no warnings 'redefine';
    my $orig_flush = \&Sub::Throttler::throttle_flush;
    *Sub::Throttler::throttle_flush = sub { push @Result, 'flush'; return $orig_flush->(@_) };
    *Sub::Throttler::Limit::throttle_flush = *Sub::Throttler::throttle_flush;
}

throttle_del();
$throttle = Sub::Throttler::Limit->new;
throttle_add($throttle, sub {
    return { key => 1 };
});

$obj = new();

#     - если запускаемая из throttle_flush функция/метод сразу вызовет $done->()

@Result = ();
func(10);
is_deeply \@Result, [10,'flush'],
    'func from throttle_flush immediately calls $done->()';

@Result = ();
$obj->method(20);
is_deeply \@Result, [20,'flush'],
    'method from throttle_flush immediately calls $done->()';

#     - если запускаемая из throttle_flush функция/метод запустит другие
#       зашейперённые функции/методы

throttle_del();
$throttle = Sub::Throttler::Rate::AnyEvent->new(limit=>2);
throttle_add($throttle, sub {
    return { key => 1 };
});

@Result = ();
$time = time;
top_func(10);
is_deeply \@Result, ['top_func',10],
    'top_func, func';
is time, $time,
    'no delay';


done_testing();


### Intercept warn/die/carp/croak messages
# wait_err();
# … test here …
# like get_warn(), qr/…/;
# like get_die(),  qr/…/;

my ($DieMsg, $WarnMsg);

sub wait_err {
    $DieMsg = $WarnMsg = q{};
    $::SIG{__WARN__} = sub { $WarnMsg .= $_[0] };
    $::SIG{__DIE__}  = sub { $DieMsg  .= $_[0] };
}

sub get_warn {
    $::SIG{__DIE__} = $::SIG{__WARN__} = undef;
    return $WarnMsg;
}

sub get_die {
    $::SIG{__DIE__} = $::SIG{__WARN__} = undef;
    return $DieMsg;
}

