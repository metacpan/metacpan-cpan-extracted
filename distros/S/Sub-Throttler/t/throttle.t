use strict;
use warnings;
use utf8;
use open qw( :std :utf8 );
use Test::More;
use Test::Exception;
use Test::Mock::Time;

use Sub::Throttler qw( :ALL );
use Sub::Throttler::Limit;

use EV;

my (@Result, @Wait, $t);
my ($throttle, $throttle2);
my $obj = new();

sub new {
    return bless {};
}

my @DONE = ();
sub func {
    my $done = &throttle_me || return;
    my @p = @_;
    push @Result, $p[0];
    $done->(@DONE);
    return;
}

sub func_asap {
#     my $done = &throttle_me_asap || return;
    my ($p, $cb) = @_;
    push @Result, $p;
    $cb->();
#     $done->();
    return;
}
throttle_it_asap('func_asap');

sub method {
#     my $done = &throttle_me || return;
    my ($self, $p, $cb) = @_;
    push @Result, $p;
    ref $cb && $cb->();
#     $done->();
    return;
}
throttle_it('main::method');

sub method_asap {
    my $done = &throttle_me_asap || return;
    my ($self, @p) = @_;
    push @Result, $p[0];
    $done->();
    return;
}

sub _func_delay {
#     my $done = &throttle_me || return;
    my ($cb) = @_;
    my $t;
    $t = EV::timer 0.01, 0, sub {
#         $done->();
        $t = undef;
        $cb->();
    };
    return;
}
throttle_it('_func_delay');

sub func_delay {
    my @p = @_;
    _func_delay(sub {
        push @Result, $p[0];
    });
    return;
}

sub func_delay_done_cb {
    my $done = &throttle_me || return;
    my $t;
    $t = EV::timer 0.01, 0, done_cb($done, sub {
        my @p = @_;
        $t = undef;
        push @Result, $p[0];
    }, @_);
    return;
}

sub method_delay {
    my $done = &throttle_me || return;
    my $self = shift;
    my $t;
    $t = EV::timer 0.01, 0, done_cb($done, $self, '_method_delay', \$t, @_);
    return;
}

sub _method_delay {
    my ($self, $t, @p) = @_;
    $$t = undef;
    push @Result, $p[0];
}

sub top_func {
    my $done = &throttle_me || return;
    func('top_func');
    my @p = @_;
    push @Result, $p[0];
    $done->();
    return;
}

sub top_func_asap {
    my $done = &throttle_me_asap || return;
    func_asap('top_func_asap', sub{});
    my @p = @_;
    push @Result, $p[0];
    $done->();
    return;
}

sub top_func_delay {
    my $done = &throttle_me || return;
    my @p = @_;
    my $t;
    $t = EV::timer 0.05, 0, sub {
        $t = undef;
        push @Result, $p[0];
        $done->();
    };
    func('top_func');
    return;
}

sub top_method_delay {
    my $done = &throttle_me || return;
    my ($self, @p) = @_;
    my $t;
    $t = EV::timer 0.05, 0, done_cb($done, $self, sub {
        my ($self) = @_;
        $t = undef;
        push @Result, $p[0];
    });
    $self->method('top_method', sub{});
    return;
}

# - throttle_add()
#   * некорректные параметры:
#     - не 2 параметра

throws_ok { throttle_add() } qr/require 2 params/;

#     - первый не объект

throws_ok { throttle_add(undef, sub {}) } qr/throttle must be an object/;
throws_ok { throttle_add('qwe', sub {}) } qr/throttle must be an object/;
throws_ok { throttle_add(42, sub {}) } qr/throttle must be an object/;

#     - второй не ссылка на функцию

throws_ok { throttle_add(Sub::Throttler::Limit->new(), undef) } qr/target must be CODE/;
throws_ok { throttle_add(Sub::Throttler::Limit->new(), 'asd') } qr/target must be CODE/;
throws_ok { throttle_add(Sub::Throttler::Limit->new(), 42) } qr/target must be CODE/;
throws_ok { throttle_add(Sub::Throttler::Limit->new(), [1,2,3]) } qr/target must be CODE/;
throws_ok { throttle_add(Sub::Throttler::Limit->new(), {key1 => 1, key2 => 2}) } qr/target must be CODE/;

#   * запускать:
#     - функцию
#     - метод объекта
#   * нет add() - ограничений нет

@Result = ();
func(10);
func_delay(20);
$obj->method(30, sub{});
$obj->method_delay(40);
is_deeply \@Result, [10,30],
    'func & method';
$t = EV::timer 0.01, 0, sub { EV::break };
EV::run;
is_deeply \@Result, [10,30,20,40],
    'func_delay & method_delay';

#   * один add() - ограничения есть

$throttle = Sub::Throttler::Limit->new->apply_to(sub {
    return { key => 2 };
});

@Result = ();
func(10);
func_delay(20);
$obj->method(30, sub{});
$obj->method_delay(40);
is_deeply \@Result, [],
    'nobody run yet';

$throttle->limit(2);
is_deeply \@Result, [10],
    'func';
$t = EV::timer 0.01, 0, sub { EV::break };
EV::run;
is_deeply \@Result, [10,30,20],
    'func_delay, method';
$t = EV::timer 0.01, 0, sub { EV::break };
EV::run;
is_deeply \@Result, [10,30,20,40],
    'method_delay';

#   * несколько add() - учитываются все ограничения

$throttle2 = Sub::Throttler::Limit->new->apply_to(sub {
    my ($this, $name, @p) = @_;
    if (!$this) {
        return { key => 2 };
    } else {
        return;
    }
});

@Result = ();
func(10);
func_delay(20);
$obj->method(30, sub{});
$obj->method_delay(40);
is_deeply \@Result, [30],
    'method';
$t = EV::timer 0.01, 0, sub { EV::break };
EV::run;
is_deeply \@Result, [30,40],
    'method_delay';

$throttle2->limit(2);
is_deeply \@Result, [30,40,10],
    'func';
$t = EV::timer 0.01, 0, sub { EV::break };
EV::run;
is_deeply \@Result, [30,40,10,20],
    'func_delay';

#   * del($throttle2)
#     - срабатывает throttle_flush()

$throttle2->limit(1);

@Result = ();
func(10);
is_deeply \@Result, [],
    'nobody run yet';

throttle_del($throttle2);

is_deeply \@Result, [10],
    'func';

#     - ограничения есть только для $throttle

$throttle->limit(1);

@Result = ();
func(10);
func_delay(20);
$obj->method(30, sub{});
$obj->method_delay(40);
is_deeply \@Result, [],
    'nobody run yet';

$throttle->limit(2);
is_deeply \@Result, [10],
    'func';
$t = EV::timer 0.01, 0, sub { EV::break };
EV::run;
is_deeply \@Result, [10,30,20],
    'func_delay, method';
$t = EV::timer 0.01, 0, sub { EV::break };
EV::run;
is_deeply \@Result, [10,30,20,40],
    'method_delay';

#   * несколько add() с одинаковым объектом $throttle:
#     - $target-функции каждого add() срабатывают на разные цели

throttle_del();
$throttle = Sub::Throttler::Limit->new
    ->apply_to_functions('_func_delay')
    ->apply_to_methods(ref $obj, 'method_delay')
    ;

@Result = ();
func_delay(20);
$obj->method_delay(40);
is_deeply \@Result, [],
    'nobody run yet';
$t = EV::timer 0.01, 0, sub { EV::break };
EV::run;
is_deeply \@Result, [20],
    'func_delay';
$t = EV::timer 0.01, 0, sub { EV::break };
EV::run;
is_deeply \@Result, [20,40],
    'method_delay';

#     - $target-функции каждого add() срабатывают на одинаковые цели с разными $key

throttle_del();
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

$throttle->{used}{key1} = 1;
$throttle->{used}{key2} = 1;
throttle_flush();
$obj->method(10, sub{});
is_deeply \@Result, [],
    'no key1 & no key2';

$throttle->{used}{key1} = 0;
$throttle->{used}{key2} = 1;
throttle_flush();
is_deeply \@Result, [],
    'key1 & no key2';

$throttle->{used}{key1} = 1;
$throttle->{used}{key2} = 0;
throttle_flush();
is_deeply \@Result, [],
    'no key1 & key2';

$throttle->{used}{key1} = 0;
$throttle->{used}{key2} = 0;
throttle_flush();
is_deeply \@Result, [10],
    'key1 & key2';

#     - $target-функции каждого add() срабатывают на одинаковые цели с одинаковыми $key

throttle_del();
$throttle = Sub::Throttler::Limit->new
    ->apply_to_methods($obj, 'method')
    ->apply_to_methods($obj, 'method');
 
throws_ok { wait_err(); $obj->method(10, sub{}) } qr/already acquired/,
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

throttle_del();
$throttle = Sub::Throttler::Limit->new;
throttle_add($throttle, sub {
    return { '' => 1 };
});

@Result = ();
$throttle->{used}{''} = 1;
throttle_flush();
func(10);
is_deeply \@Result, [],
    'return {""=>1}';
$throttle->{used}{''} = 0;
throttle_flush();
is_deeply \@Result, [10];

#     - $key => $quantity

throttle_del();
$throttle = Sub::Throttler::Limit->new;
throttle_add($throttle, sub {
    return { key => 2 };
});

@Result = ();
$throttle->{used}{key} = 1;
throttle_flush();
func(10);
is_deeply \@Result, [],
    'return {key=>2}';
$throttle->limit(3);
is_deeply \@Result, [10];

#     - $key1 => $quantity1, ...

throttle_del();
$throttle = Sub::Throttler::Limit->new(limit => 5);
throttle_add($throttle, sub {
    return { key1=>1, key2=>2, key3=>3 };
});

@Result = ();
$throttle->{used}{key1} = 5;
throttle_flush();
func(10);
is_deeply \@Result, [],
    'no key1 of 3 keys';
$throttle->{used}{key2} = 4;
$throttle->{used}{key1} = 4;
throttle_flush();
is_deeply \@Result, [],
    'no key2 of 3 keys';
$throttle->{used}{key3} = 3;
$throttle->{used}{key2} = 3;
throttle_flush();
is_deeply \@Result, [],
    'no key3 of 3 keys';
$throttle->{used}{key3} = 2;
throttle_flush();
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

# - throttle_me и throttle_me_asap
#   * использовать в:
#     - функции
#     - методе объекта
#   * функции использующие throttle_me_asap добавляются в "срочную" очередь

throttle_del();
$throttle = Sub::Throttler::Limit->new;
throttle_add($throttle, sub {
    return { key => 2 };
});

@Result = ();
func(10);
func_asap(20, sub{});
$obj->method(30, sub{});
$obj->method_asap(40);
$throttle->limit(2);
is_deeply \@Result, [20,40,10,30],
    'func_asap, method_asap, func, method';

#   * функции использующие throttle_me_asap добавляются в конец "срочной" очереди

throttle_del();
$throttle = Sub::Throttler::Limit->new(limit => 0);
throttle_add($throttle, sub {
        return { key => 1 };
});

@Result = ();
func_asap(10, sub{});
$obj->method_asap(20);
func_asap(30, sub{});
$obj->method_asap(40);
is_deeply \@Result, [];
$throttle->limit(1);
is_deeply \@Result, [10,20,30,40],
    'func_asap, method_asap, func_asap, method_asap';

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

#   * если объект удаляется в то время, как его метод находится в очереди,
#     то метод вызываться не должен и должен быть вызван его $done->()

$obj = new();
throttle_del();
$throttle = Sub::Throttler::Limit->new;
throttle_add($throttle, sub {
    return { key => 2 };
});

@Result = ();
$obj->method(10, sub{});
func(20);
$obj->method_asap(30);
wait_err();
$obj = undef;
$throttle->limit(2);
is_deeply \@Result, [20],
    'func, no obj';
is get_warn(), q{},
    '$done->() was called';

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

# - done_cb($done, $cb, @params)
#   * $done->() вызывается перед $object->method(@params)

@Result = ();
func_delay_done_cb(25);
is_deeply \@Result, [];
$t = EV::timer 0.01, 0, sub { EV::break };
EV::run;
is_deeply \@Result, ['release', 25],
    '$done->() called before $cb->(@params)';

# - done_cb($done, $object, 'method', @params)
#   * $done->() вызывается перед $object->method(@params)

$obj = new();

@Result = ();
$obj->method_delay(30);
is_deeply \@Result, [];
$t = EV::timer 0.01, 0, sub { EV::break };
EV::run;
is_deeply \@Result, ['release', 30],
    '$done->() called before $object->method(@params)';

#   * $done->() вызывается даже если $object удалён и method вызван не будет

@Result = ();
$obj->method_delay(40);
$obj = undef;
is_deeply \@Result, [];
$t = EV::timer 0.01, 0, sub { EV::break };
EV::run;
is_deeply \@Result, ['release'],
    '$done->(), no $obj';

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
is_deeply \@Result, ['flush', 10, 'flush', 'flush'],
    'func from throttle_flush immediately calls $done->()';

@Result = ();
$obj->method(20, sub{});
is_deeply \@Result, ['flush', 20, 'flush', 'flush'],
    'method from throttle_flush immediately calls $done->()';

#     - если запускаемая из throttle_flush функция/метод запустит другие
#       зашейперённые функции/методы

$throttle->limit(2);
@Result = ();
top_func_delay(30);
is_deeply \@Result, ['flush','flush','flush','top_func','flush','flush'];
$t = EV::timer 0.03, 0, sub { EV::break };
EV::run;
is_deeply \@Result, ['flush','flush','flush','top_func','flush','flush'];
$t = EV::timer 0.02, 0, sub { EV::break };
EV::run;
is_deeply \@Result, ['flush','flush','flush','top_func','flush','flush',30,'flush'];

@Result = ();
$obj->top_method_delay(40);
is_deeply \@Result, ['flush','flush','flush','top_method','flush','flush'];
$t = EV::timer 0.03, 0, sub { EV::break };
EV::run;
is_deeply \@Result, ['flush','flush','flush','top_method','flush','flush'];
$t = EV::timer 0.02, 0, sub { EV::break };
EV::run;
is_deeply \@Result, ['flush','flush','flush','top_method','flush','flush','flush',40];

#   * если в очереди задача, для которой нужны несколько ресурсов, часть
#     из которых доступна, а часть нет (т.е. throttle_flush будет вызывать
#     release_unused), убедиться что throttle_flush не будет бесконечно запускаться
#     по таймеру

throttle_del();
$throttle = Sub::Throttler::Limit->new;
throttle_add($throttle, sub {
    return { key1 => 1, key2 => 1 };
});

$throttle->{used}{key2} = 1;
throttle_flush();
@Result = ();
func(10);
@Wait = @Result == 1 ? ['flush'] : ['flush','flush']; # depends on resource acquiring order
is_deeply \@Result, @Wait;
$t = EV::timer 0.01, 0, sub { EV::break };
EV::run;
is_deeply \@Result, @Wait;
$t = EV::timer 0.01, 0, sub { EV::break };
EV::run;
is_deeply \@Result, @Wait;
$throttle->{used}{key2} = 0;
throttle_flush();

#   * если в процессе работы throttle_flush в очередь (любую) добавляются новые
#     задачи, то они должны добавиться в конец очередей

throttle_del();
$throttle = Sub::Throttler::Limit->new(limit => 0);
throttle_add($throttle, sub {
    return { key => 1 };
});

@Result = ();
top_func(10);
func(20);
top_func_asap(30);
func_asap(40, sub{});
$throttle->limit(1);
@Result = grep {$_ ne 'flush'} @Result;
is_deeply \@Result, [30,40,10,20,'top_func_asap','top_func'];


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

