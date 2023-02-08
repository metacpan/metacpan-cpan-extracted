# NAME

RxPerl - an implementation of Reactive Extensions / rxjs for Perl

# SYNOPSIS

    # one of...:

    > cpanm RxPerl::AnyEvent
    > cpanm RxPerl::IOAsync
    > cpanm RxPerl::Mojo


    # ..and then (if installed RxPerl::Mojo, for example):

    use RxPerl::Mojo 'rx_interval', 'op_take'; # or ':all'
    use Mojo::IOLoop;

    rx_interval(1.4)->pipe(
        op_take(5),
    )->subscribe(sub { say "next: ", $_[0] });

    Mojo::IOLoop->start;

# NOTE

You probably want to install one of the three adapter modules for your project instead of this one:
[RxPerl::AnyEvent](https://metacpan.org/pod/RxPerl%3A%3AAnyEvent), [RxPerl::IOAsync](https://metacpan.org/pod/RxPerl%3A%3AIOAsync) or [RxPerl::Mojo](https://metacpan.org/pod/RxPerl%3A%3AMojo).

Each of these three modules adapts RxPerl to one of three event interfaces available in Perl ([AnyEvent](https://metacpan.org/pod/AnyEvent),
[IO::Async](https://metacpan.org/pod/IO%3A%3AAsync) and [Mojo::IOLoop](https://metacpan.org/pod/Mojo%3A%3AIOLoop)), so pick the one that corresponds to the event interface that your app uses.

The documentation in this POD applies to all three adapter modules as well.

# DESCRIPTION

This module is an implementation of [Reactive Extensions](http://reactivex.io/) in Perl. It replicates the
behavior of [rxjs 6](https://www.npmjs.com/package/rxjs) which is the JavaScript implementation of ReactiveX.

Currently 93 of the 100+ operators in rxjs are implemented in this module.

# EXPORTABLE FUNCTIONS

The code samples in this section assume `$observer` has been set to:

    $observer = {
        next     => sub {say "next: ", $_[0]},
        error    => sub {say "error: ", $_[0]},
        complete => sub {say "complete"},
    };

## OBSERVABLE CREATION OPERATORS

Creation operators create and return an _observable_. They are usually unicast, which means that when an
["rx\_interval"](#rx_interval) _observable_ is subscribed to three seperate times there will be three different & distinct recurring
intervals. Exceptions to this are with [subjects](#rx_subject) and that any observable can be transformed into a
[multicasting](https://www.learnrxjs.io/learn-rxjs/operators/multicasting) one using the ["op\_share"](#op_share) pipeable
operator (or by other similar operators).

The following list is the currently implemented creation operators with links to relevant rxjs documentation (which
should apply to RxPerl too).

- rx\_behavior\_subject

    [https://rxjs.dev/api/index/class/BehaviorSubject](https://rxjs.dev/api/index/class/BehaviorSubject)

        # 10, 20, 30, complete
        my $b_s = rx_behavior_subject->new(10);
        $b_s->subscribe($observer);
        $b_s->next(20);
        $b_s->next(30);
        $b_s->complete;

        # 20, 30, complete
        my $b_s = rx_behavior_subject->new(10);
        $b_s->next(20);
        $b_s->subscribe($observer);
        $b_s->next(30);
        $b_s->complete;

- rx\_combine\_latest

    [https://rxjs.dev/api/index/function/combineLatest](https://rxjs.dev/api/index/function/combineLatest)

        # [0, 0], [0, 1], [1, 1], [1, 2], [1, 3], ...
        rx_combine_latest([
            rx_interval(1),
            rx_interval(0.7),
        ])->subscribe($observer);

- rx\_concat

    [https://rxjs.dev/api/index/function/concat](https://rxjs.dev/api/index/function/concat)

        # 10, 20, 30, 10, 20, 30, 40, complete
        rx_concat(
            rx_of(10, 20, 30),
            rx_of(10, 20, 30, 40),
        )->subscribe($observer);

- rx\_defer

    [https://rxjs.dev/api/index/function/defer](https://rxjs.dev/api/index/function/defer)

        # Suppose "int rand 10" here evaluates to 7. Then if after 7 seconds $special_var holds a true value,
        # output will be: 0, 1, 2, 3, 4, 5, 6, 10, 20, 30, complete, otherwise it will be:
        # 0, 1, 2, 3, 4, 5, 6, 40, 50, 60, complete.

        rx_concat(
            rx_interval(1)->pipe( op_take(int rand 10) ),
            rx_defer(sub {
                return $special_var ? rx_of(10, 20, 30) : rx_of(40, 50, 60)
            })
        )->subscribe($observer);

- rx\_EMPTY

    [https://rxjs.dev/api/index/const/EMPTY](https://rxjs.dev/api/index/const/EMPTY)

        # complete
        rx_EMPTY->subscribe($observer);

        # 10, 20, 30, 40, 50, 60, complete
        rx_concat(
            rx_of(10, 20, 30),
            rx_EMPTY,
            rx_EMPTY,
            rx_EMPTY,
            rx_of(40, 50, 60),
        )->subscribe($observer);

- rx\_fork\_join

    [https://rxjs.dev/api/index/function/forkJoin](https://rxjs.dev/api/index/function/forkJoin)

        # [30, 3, 'c'], complete
        rx_fork_join([
            rx_of(10, 20, 30),
            rx_of(1, 2, 3),
            rx_of('a', 'b', 'c'),
        ])->subscribe($observer);

        # {x => 30, y => 3, z => 'c'}, complete
        rx_fork_join({
            x => rx_of(10, 20, 30),
            y => rx_of(1, 2, 3),
            z => rx_of('a', 'b', 'c'),
        })->subscribe($observer);

- rx\_from

    [https://rxjs.dev/api/index/function/from](https://rxjs.dev/api/index/function/from)

    Currently, only arrayrefs, promises, Futures, observables and strings are allowed as argument
    to this function.

        # 10, 20, 30, complete
        rx_from([10, 20, 30])->subscribe($observer);

- rx\_from\_event

    [https://rxjs.dev/api/index/function/fromEvent](https://rxjs.dev/api/index/function/fromEvent)

    Currently, only instances of the [Mojo::EventEmitter](https://metacpan.org/pod/Mojo%3A%3AEventEmitter) class are allowed as the first argument to this function.

        # 4 seconds after Mojolicious hypnotoad is gracefully reloaded, websocket
        # connection will close

        sub websocket ($c) {
            rx_from_event($ioloop, 'finish')->pipe(
                op_delay(4),
            )->subscribe({
                next => sub { $c->finish },
            });
        }

- rx\_from\_event\_array

    [https://rxjs.dev/api/index/function/fromEvent](https://rxjs.dev/api/index/function/fromEvent)

    Similar to: ["rx\_from\_event"](#rx_from_event).

    Observables may emit at most one value per event, however [Mojo::EventEmitter](https://metacpan.org/pod/Mojo%3A%3AEventEmitter)'s are able to emit
    more. So this function serves to pack all of them in an arrayref, and emit that as a single value instead.

- rx\_generate

    [https://rxjs.dev/api/index/function/generate](https://rxjs.dev/api/index/function/generate)

        # 2, 5, 10, 17, 26
        rx_generate(
            1, # initializer
            sub ($x) { $x <= 5 }, # check, and can also use $_ here
            sub ($x) { $x + 1 }, # iterate, and can also use $_ here
            sub ($x) { $x ** 2 + 1 }, # result selector (optional), and can also use $_ here
        )->subscribe($observer);

- rx\_iif

    [https://rxjs.dev/api/index/function/iif](https://rxjs.dev/api/index/function/iif)

        my $i;

        my $o = rx_iif(
            sub { $i > 5 },
            rx_of(1, 2, 3),
            rx_of(10, 20, 30),
        );

        $i = 4;
        # 10, 20, 30, complete
        $o->subscribe($observer);

        $i = 6;
        # 1, 2, 3, complete
        $o->subscribe($observer);

- rx\_interval

    [https://rxjs.dev/api/index/function/interval](https://rxjs.dev/api/index/function/interval)

    Works like rxjs's "interval", except the parameter is in seconds instead of ms.

        # 0, 1, 2, ... every 0.7 seconds
        rx_interval(0.7)->subscribe($observer);

- rx\_merge

    [https://rxjs.dev/api/index/function/merge](https://rxjs.dev/api/index/function/merge)

        # 0, 0, 1, 1, 2, 3, 2, 4, 3, ...
        rx_merge(
            rx_interval(0.7),
            rx_interval(1),
        )->subscribe($observer);

- rx\_NEVER

    [https://rxjs.dev/api/index/const/NEVER](https://rxjs.dev/api/index/const/NEVER)

        # 10, 20, 30 (and no complete)
        rx_concat(
            rx_of(10, 20, 30),
            rx_NEVER,
            rx_of(40, 50, 60),
        )->subscribe($observer);

- rx\_observable

    [https://rxjs.dev/api/index/class/Observable](https://rxjs.dev/api/index/class/Observable)

        # 0.578, 0.234, 0.678, ... (every 1 second)
        my $o = rx_observable->new(sub ($subscriber) {
            # your code goes here
            Mojo::IOLoop->recurring(1, sub {$subscriber->next(rand())});
        });

    Check the [guide to creating your own observables](https://metacpan.org/pod/RxPerl%3A%3AGuides%3A%3ACreatingObservables).

- rx\_of

    [https://rxjs.dev/api/index/function/of](https://rxjs.dev/api/index/function/of)

        # 10, 20, 30, complete
        rx_of(10, 20, 30)->subscribe($observer);

- rx\_on\_error\_resume\_next

    [https://rxjs.dev/api/index/function/onErrorResumeNext](https://rxjs.dev/api/index/function/onErrorResumeNext)

        # 1, 2, 3, 10, 20, 30, complete
        rx_on_error_resume_next(
            rx_of(1, 2, 3)->pipe( op_concat_with(rx_throw_error('foo')) ),
            rx_throw_error('bar'),
            rx_of(10, 20, 30),
            rx_throw_error('baz'),
        )->subscribe($observer);

- rx\_partition

    [https://rxjs.dev/api/index/function/partition](https://rxjs.dev/api/index/function/partition)

        # 1, 3, 5, 7, 9, 0, 2, 4, 6, 8, complete
        my $source = rx_interval(1)->pipe( op_take(10) );
        my ($o1, $o2) = rx_partition(
            $source,
            sub ($value, $index) { $value % 2 == 1 },
        );
        rx_concat($o1, $o2)->subscribe($observer);

- rx\_race

    [https://rxjs.dev/api/index/function/race](https://rxjs.dev/api/index/function/race)

        # 0, 10, 20, 30, ... (every 0.7 seconds)
        rx_race(
            rx_interval(1)->pipe( op_map(sub {$_[0] * 100}) ),
            rx_interval(0.7)->pipe( op_map(sub {$_[0] * 10) ),
        )->subscribe($observer);

- rx\_range

    [https://rxjs.dev/api/index/function/range](https://rxjs.dev/api/index/function/range)

        # 10, 11, 12, 13, 14, 15, 16, complete
        rx_range(10, 7)->subscribe($observer);

- rx\_replay\_subject

    [https://rxjs.dev/api/index/class/ReplaySubject](https://rxjs.dev/api/index/class/ReplaySubject)

    Works like rxjs's "replaySubject", except the `window_time` parameter is in seconds instead of ms.

        # 20, 30, 40, 50, complete
        my $rs = rx_replay_subject(2);
        $rs->next(10);
        $rs->next(20);
        $rs->next(30);
        $rs->subscribe($observer);
        $rs->next(40);
        $rs->next(50);
        $rs->complete;

        # or...
        my $rs = rx_replay_subject(2, 3); # params: buffer_size, window_time

- rx\_subject

    [https://rxjs.dev/api/index/class/Subject](https://rxjs.dev/api/index/class/Subject)

        # 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, complete
        my $subject = rx_subject->new;
        $subject->subscribe($observer);

        # elsewhere...
        $subject->next($_) for 1 .. 10;
        $subject->complete;

- rx\_throw\_error

    [https://rxjs.dev/api/index/function/throwError](https://rxjs.dev/api/index/function/throwError)

        # 0, 1, 2, 3, error: foo
        rx_concat(
            rx_interval(1)->pipe( op_take(4) ),
            rx_throw_error('foo'),
        )->subscribe($observer);

- rx\_timer

    [https://rxjs.dev/api/index/function/timer](https://rxjs.dev/api/index/function/timer)

    Works like rxjs's "timer", except the parameter is in seconds instead of ms.

        # (pause 10 seconds) 0, complete
        rx_timer(10)->subscribe($observer);

        # (pause 10 seconds) 0, 1, 2, 3, ... (every 1 second)
        rx_timer(10, 1)->subscribe($observer);

- rx\_zip

    [https://rxjs.dev/api/index/function/zip](https://rxjs.dev/api/index/function/zip)

        # [0, 0, 0], [1, 1, 1], [2, 2, 2], complete
        rx_zip(
            rx_interval(0.7)->pipe( op_take(3) ),
            rx_interval(1),
            rx_interval(2),
        )->subscribe($observer);

## PIPEABLE OPERATORS

Pipeable operators (also referred to as "operators") are passed as arguments to the ["pipe"](#pipe) method of
observables. Their function is to take an observable, transform it somehow, then (similar to piped shell commands) pass
the result of the transformation to the next pipeable operator in the pipe, or return it to the user.

The following list is the currently implemented operators, with links to relevant rxjs documentation (which should
apply to RxPerl too).

- op\_audit

    [https://rxjs.dev/api/operators/audit](https://rxjs.dev/api/operators/audit)

        # 1, 3, 5, 7, 9, ...
        rx_interval(0.7)->pipe(
            op_audit(sub ($val) { rx_timer(1) }),
        )->subscribe($observer);

- op\_audit\_time

    [https://rxjs.dev/api/operators/auditTime](https://rxjs.dev/api/operators/auditTime)

    Works like rxjs's "auditTime", except the parameter is in seconds instead of ms.

        # 30, complete
        rx_concat(
            rx_of(10, 20, 30),
            rx_EMPTY->pipe( op_delay(5) ),
        )->pipe(
            op_audit_time(1),
        )->subscribe($observer);

- op\_buffer

    [https://rxjs.dev/api/operators/buffer](https://rxjs.dev/api/operators/buffer)

        # [0, 1, 2], [3, 4, 5], [6, 7, 8, 9], ...
        rx_interval(0.3)->pipe(
            op_buffer(rx_interval(1.001)),
        )->subscribe($observer);

- op\_buffer\_count

    [https://rxjs.dev/api/operators/bufferCount](https://rxjs.dev/api/operators/bufferCount)

        # [10, 20, 30], [40, 50], complete
        rx_of(10, 20, 30, 40, 50)->pipe(
            op_buffer_count(3),
        )->subscribe($observer);

        # [10, 20, 30], [20, 30, 40], [30, 40, 50], [40, 50], [50], complete
        rx_of(10, 20, 30, 40, 50)->pipe(
            op_buffer_count(3, 1),
        )->subscribe($observer);

- op\_buffer\_time

    Works like rxjs's "bufferTime", except the parameter is in seconds instead of ms.

    [https://rxjs.dev/api/operators/bufferTime](https://rxjs.dev/api/operators/bufferTime)

        # [0], [1], [2, 3], [4], [5, 6], [7]...
        rx_interval(0.7)->pipe(
            op_buffer_time(1),
        )->subscribe($observer);

- op\_catch\_error

    [https://rxjs.dev/api/operators/catchError](https://rxjs.dev/api/operators/catchError)

        # foo, foo, foo, complete
        rx_throw_error('foo')->pipe(
            op_catch_error(sub ($err, $caught) { rx_of($err, $err, $err) }),
        )->subscribe($observer);

- op\_combine\_latest\_with

    [https://rxjs.dev/api/operators/combineLatestWith](https://rxjs.dev/api/operators/combineLatestWith)

    Similar to rx\_combine\_latest, but as a pipeable operator.

        # [0, 0, -5], [0, 1, -5], [10, 1, -5], [10, 2, -5], [10, 3, -5], [20, 3, -5], ...
        rx_interval(1)->pipe(
            op_map(sub { $_ * 10 }),
            op_combine_latest_with(
                rx_interval(0.7),
                rx_of(-5),
            ),
            op_take(10),
        )->subscribe($observer);

- op\_concat\_all

    [https://rxjs.dev/api/operators/concatAll](https://rxjs.dev/api/operators/concatAll)

        # 0, 1, 2, 0, 1, 2, 0, 1, complete
        rx_interval(0.7)->pipe(
            op_map(sub { rx_interval(1)->pipe( op_take(3) ) }),
            op_concat_all(),
            op_take(10),
        )->subscribe($observer);

- op\_concat\_map

    [https://rxjs.dev/api/operators/concatMap](https://rxjs.dev/api/operators/concatMap)

        # 0, 1, 2, 0, 1, 2, 0, 1, 2, complete
        rx_of(10, 20, 30)->pipe(
            op_concat_map(sub ($val, $idx) {
                rx_interval(1)->pipe(op_take(3)), # can also use $_ here instead of $val
            }),
        )->subscribe($observer);

- op\_concat\_with

    [https://rxjs.dev/api/operators/concatWith](https://rxjs.dev/api/operators/concatWith)

        # 0, 1, 2, 3, 4, 5, 6, 7, 8, complete
        rx_of(0, 1, 2)->pipe(
            op_concat_with(
                rx_of(3, 4, 5),
                rx_of(6, 7, 8),
            ),
        )->subscribe($observer);

- op\_count

    [https://rxjs.dev/api/operators/count](https://rxjs.dev/api/operators/count)

        # 3, complete
        rx_of(0, 1, 2)->pipe(
            op_count(),
        )->subscribe($observer);

        # 3, complete
        rx_of(0, 1, 2, 3, 4, 5, 6)->pipe(
            op_count(sub { $_[0] % 2 == 1 }), # can also use $_ here
        )->subscribe($observer);

        # 4, complete
        rx_of(1, 1, 1, 1, 1, 1, 1)->pipe(
            op_count(sub ($value, $idx) { $idx % 2 == 0 }),
        );

- op\_debounce

    [https://rxjs.dev/api/operators/debounce](https://rxjs.dev/api/operators/debounce)

        # 3, complete
        rx_of(1, 2, 3)->pipe(
            op_debounce(sub ($val) { rx_timer(0.5) }),
        )->subscribe($observer);

- op\_debounce\_time

    [https://rxjs.dev/api/operators/debounceTime](https://rxjs.dev/api/operators/debounceTime)

    Works like rxjs's "debounceTime", except the parameter is in seconds instead of ms.

        # 3, complete
        rx_of(1, 2, 3)->pipe(
            op_debounce_time(0.5),
        )->subscribe($observer);

- op\_default\_if\_empty

    [https://rxjs.dev/api/operators/defaultIfEmpty](https://rxjs.dev/api/operators/defaultIfEmpty)

        # 42, complete
        rx_timer(0.7)->pipe(
            op_ignore_elements(),
            op_default_if_empty(42),
        )->subscribe($observer);

- op\_delay

    [https://rxjs.dev/api/operators/delay](https://rxjs.dev/api/operators/delay)

    Works like rxjs 7's "delay", except the parameter is in seconds instead of ms.

        # (pause 11 seconds) 0, 1, 2, 3, ...
        rx_interval(1)->pipe(
            op_delay(10)
        )->subscribe($observer);

    Note: Just as in rxjs 7, the complete event will not be delayed, so don't do this:

        rx_EMPTY->pipe( op_delay(2) )

    Do this instead, to achieve the expected effect:

        rx_timer(2)->pipe( op_ignore_elements() )

- op\_distinct\_until\_changed

    [https://rxjs.dev/api/operators/distinctUntilChanged](https://rxjs.dev/api/operators/distinctUntilChanged)

        # 10, undef, 20, 30, [], [], complete
        rx_of(10, 10, undef, undef, 20, 20, 20, 30, 30, [], [])->pipe(
            op_distinct_until_changed(),
        )->subscribe($observer);

        # {name => 'Peter', grade => 'A'}, {name => 'Mary', grade => 'B'}, complete
        rx_of(
            {name => 'Peter', grade => 'A'},
            {name => 'Peter', grade => 'B'},
            {name => 'Mary', grade => 'B'},
            {name => 'Mary', grade => 'A'},
        )->pipe(
            op_distinct_until_changed(sub {
                return $_[0]->{name} eq $_[1]->{name};
            }),
        )->subscribe($observer);

- op\_distinct\_until\_key\_changed

    [https://rxjs.dev/api/operators/distinctUntilKeyChanged](https://rxjs.dev/api/operators/distinctUntilKeyChanged)

        # {name => 'Peter', grade => 'A'}, {name => 'Mary', grade => 'B'}, complete
        rx_of(
            {name => 'Peter', grade => 'A'},
            {name => 'Peter', grade => 'B'},
            {name => 'Mary', grade => 'B'},
            {name => 'Mary', grade => 'A'},
        )->pipe(
            op_distinct_until_key_changed('name'),
        )->subscribe($observer);

- op\_element\_at

    [https://rxjs.dev/api/operators/elementAt](https://rxjs.dev/api/operators/elementAt)

        # 2, complete
        rx_interval(0.7)->pipe(
            op_take(5),
            op_element_at(2, 9),
        )->subscribe($observer);

- op\_end\_with

    [https://rxjs.dev/api/operators/endWith](https://rxjs.dev/api/operators/endWith)

        # 0, 1, 2, 3, 100, 200, complete
        rx_of(0, 1, 2, 3)->pipe(
            op_end_with(100, 200),
        )->subscribe($observer);

- op\_every

    [https://rxjs.dev/api/operators/every](https://rxjs.dev/api/operators/every)

    Works like rxjs's "every", except it emits 1 or 0 instead of true of false.

        # 0, complete
        rx_of(5, 10, 15, 18, 20)->pipe(
            op_every(sub ($value, $idx) { $value % 5 == 0 }),
        )->subscribe($observer);

- op\_exhaust\_all

    [https://rxjs.dev/api/operators/exhaustAll](https://rxjs.dev/api/operators/exhaustAll)

        # 0, 1, 2, 3, 0, 1, 2, 3, complete
        rx_interval(3)->pipe(
            op_take(3),
            op_map(sub { rx_interval(1)->pipe( op_take(4) ) }),
            op_exhaust_all(),
        )->subscribe($observer);

- op\_exhaust\_map

    [https://rxjs.dev/api/operators/exhaustMap](https://rxjs.dev/api/operators/exhaustMap)

        # 0, 1, 2, complete
        rx_of(10, 20, 30)->pipe(
            op_exhaust_map(sub ($val, $idx) {
                rx_interval(1)->pipe( op_take(3) ); # can also use $_ here instead of $val
            }),
        )->subscribe($observer);

- op\_filter

    [https://rxjs.dev/api/operators/filter](https://rxjs.dev/api/operators/filter)

    You can use `$_` instead of `$_[0]` inside this operator's callback.

        # 0, 2, 4, 6, ... (every 1.4 seconds)
        rx_interval(0.7)->pipe(
            op_filter(sub {$_[0] % 2 == 0}),
        )->subscribe($observer);

        # 0, 2, 4, 6, ... (every 1.4 seconds)
        rx_interval(0.7)->pipe(
            op_filter(sub {$_ % 2 == 0}),
        )->subscribe($observer);

        # 10, 36, 50, complete
        rx_of(10, 22, 36, 41, 50, 73)->pipe(
            op_filter(sub ($v, $idx) { $idx % 2 == 0 }),
        )->subscribe($observer);

- op\_finalize

    [https://rxjs.dev/api/operators/finalize](https://rxjs.dev/api/operators/finalize)

    _Note:_ Observe, in the second example below, that the order of execution of
    the finalize callbacks obeys the rxjs v7 order ('f1' first) rather than the rxjs v6
    order ('f2' first).

        # 1, 2, 3, complete, 'hi there'
        rx_of(1, 2, 3)->pipe(
            op_finalize(sub { say "hi there" }),
        )->subscribe($observer);

        # 0, f1, f2
        my $s; $s = rx_interval(1)->pipe(
            op_finalize(sub { say "f1" }),
            op_finalize(sub { say "f2" }),
        )->subscribe(sub {
            say $_[0];
            $s->unsubscribe;
        });

- op\_find

    [https://rxjs.dev/api/operators/find](https://rxjs.dev/api/operators/find)

        # 7, complete
        rx_interval(0.7)->pipe(
            op_find(sub ($val, $idx) { $val == 7 }), # can also use $_ here
        )->subscribe($observer);

        # undef, complete
        rx_interval(0.7)->pipe(
            op_take(5),
            op_find(sub { $_ == 7 }),
        )->subscribe($observer);

- op\_find\_index

    [https://rxjs.dev/api/operators/findIndex](https://rxjs.dev/api/operators/findIndex)

        # 7, complete
        rx_interval(0.7)->pipe(
            op_map(sub { $_ * 2 }),
            op_find_index(sub ($val, $idx) { $val == 14 }), # can also use $_ here
        )->subscribe($observer);

        # -1, complete
        rx_interval(0.7)->pipe(
            op_take(5),
            op_find_index(sub { $_ == 7 }),
        )->subscribe($observer);

- op\_first

    [https://rxjs.dev/api/operators/first](https://rxjs.dev/api/operators/first)

        # (pause 7 seconds) 6, complete
        rx_interval(1)->pipe(
            op_first(sub { $_[0] > 5 }),
        )->subscribe($observer);

        # 0, complete
        rx_interval(0.7)->pipe(
            op_first(),
        )->subscribe($observer);

- op\_group\_by

    [https://rxjs.dev/api/operators/groupBy](https://rxjs.dev/api/operators/groupBy)

        # [0, 2, 4], [1, 3], complete
        rx_interval(0.7)->pipe(
            op_take(5),
            op_group_by(sub { $_[0] % 2 }), # can also use $_ here
            op_merge_map(sub ($g, @) {
                return $g->pipe(
                    op_reduce(sub ($acc, $cur) { [@$acc, $cur] }, []),
                );
            ),
        )->subscribe($observer);

    _Note:_ This implementation of this operator is a little bit buggy, and may result in
    resource leaks. For example, this will keep running forever:

        my $subscription = rx_interval(0.7)->pipe(
            op_group_by(sub { $_ % 2 }),
        );

        Mojo::IOLoop->timer(5, sub {
            say "timer expired";
            $subscription->unsubscribe;
        });

- op\_ignore\_elements

    [https://rxjs.dev/api/operators/ignoreElements](https://rxjs.dev/api/operators/ignoreElements)

        # (pause 3 seconds) complete
        rx_interval(1)->pipe(
            op_take(3),
            op_ignore_elements(),
        )->subscribe($observer);

        # (pause 3 seconds) error: foo
        rx_concat(
            rx_interval(1)->pipe(op_take(3)),
            rx_throw_error('foo'),
        )->pipe(
            op_ignore_elements(),
        )->subscribe($observer);

- op\_is\_empty

    [https://rxjs.dev/api/operators/isEmpty](https://rxjs.dev/api/operators/isEmpty)

    Works like rxjs's "isEmpty", except it emits 1 or 0 instead of true or false.

        # (pause 1 second) 0, complete
        rx_interval(1)->pipe(
            op_is_empty(),
        )->subscribe($observer);

        # (pause 2 seconds) 1, complete
        rx_timer(2)->pipe(
            op_ignore_elements(),
            op_is_empty(),
        )->subscribe($observer);

- op\_last

    [https://rxjs.dev/api/operators/last](https://rxjs.dev/api/operators/last)

        # 6, complete
        rx_of(5, 6, 7)->pipe(
            op_last(sub ($val, $idx) { $val % 2 == 0 }), # can also use $_ here
        )->subscribe($observer);

        # 9, complete
        rx_EMPTY->pipe(
            op_last(undef, 9), # predicate, default
        )->subscribe($observer);

        # error: no last value found
        rx_EMPTY->pipe( op_last )->subscribe($observer);

- op\_map

    [https://rxjs.dev/api/operators/map](https://rxjs.dev/api/operators/map)

    You can use `$_` instead of `$_[0]` inside this operator's callback.

        # 10, 11, 12, 13, ...
        rx_interval(1)->pipe(
            op_map(sub {$_[0] + 10}),
        )->subscribe($observer);

        # 10, 11, 12, 13, ...
        rx_interval(1)->pipe(
            op_map(sub {$_ + 10}),
        )->subscribe($observer);

        # 10-0, 20-1, 30-2, complete
        rx_of(10, 20, 30)->pipe(
            op_map(sub ($v, $idx) { "$v-$idx" }),
        )->subscribe($observer);

- op\_map\_to

    [https://rxjs.dev/api/operators/mapTo](https://rxjs.dev/api/operators/mapTo)

        # 123, 123, 123, ... (every 1 second)
        rx_interval(1)->pipe(
            op_map_to(123),
        )->subscribe($observer);

- op\_max

    [https://rxjs.dev/api/operators/max](https://rxjs.dev/api/operators/max)

        # 20, complete
        rx_of(10, 20, 15)->pipe(
            op_max(),
        )->subscribe($observer);

        # { a => 20 }, complete
        rx_of(
            { a => 10 },
            { a => 20 },
            { a => 15 },
        )->pipe(
            op_max(sub ($x, $y) { $x->{a} <=> $y->{a} }),
        )->subscribe($observer);

- op\_merge\_all

    [https://rxjs.dev/api/operators/mergeAll](https://rxjs.dev/api/operators/mergeAll)

        # 0, 1, 0, 2, 1, 3, 2, 0, 3, 1, 0, ...
        rx_interval(1)->pipe(
            op_map(sub { rx_interval(0.7)->pipe(op_take(4)) }),
            op_merge_all(2),
        )->subscribe($observer);

- op\_merge\_map

    [https://rxjs.dev/api/operators/mergeMap](https://rxjs.dev/api/operators/mergeMap)

        # 11, 21, 31, 12, 22, 32, 13, 23, 33, complete
        rx_of(10, 20, 30)->pipe(
            op_merge_map(sub ($x, $idx) {
                return rx_interval(1)->pipe(
                    op_map(sub ($y, @) {
                        return $x + $y + 1;
                    }),
                    op_take(3),
                );
            }),
        )->subscribe($observer);

- op\_merge\_with

    [https://rxjs.dev/api/operators/mergeWith](https://rxjs.dev/api/operators/mergeWith)

        # 0, 0, 1, 1, 2, 3, 2, 4, 3, ...
        rx_interval(0.7)->pipe(
            rx_merge_with( rx_interval(1) ),
        )->subscribe($observer);

- op\_min

    [https://rxjs.dev/api/operators/min](https://rxjs.dev/api/operators/min)

        # 10, complete
        rx_of(20, 10, 15)->pipe(
            op_min(),
        )->subscribe($observer);

        # { a => 10 }, complete
        rx_of(
            { a => 20 },
            { a => 10 },
            { a => 15 },
        )->pipe(
            op_min(sub ($x, $y) { $x->{a} <=> $y->{a} }),
        )->subscribe($observer);

- op\_multicast

    [https://rxjs.dev/api/operators/multicast](https://rxjs.dev/api/operators/multicast)

- op\_on\_error\_resume\_next\_with

    [https://rxjs.dev/api/index/function/onErrorResumeNextWith](https://rxjs.dev/api/index/function/onErrorResumeNextWith)

        # 1, 2, 3, 10, 20, 30, complete
        rx_of(1, 2, 3)->pipe(
            op_concat_with( rx_throw_error('foo') ),
            op_on_error_resume_next_with(
                rx_throw_error('bar'),
                rx_of(10, 20, 30),
                rx_throw_error('baz'),
            ),
        )->subscribe($observer);

- op\_pairwise

    [https://rxjs.dev/api/operators/pairwise](https://rxjs.dev/api/operators/pairwise)

        # [0, 1], [1, 2], [2, 3], ...
        rx_interval(1)->pipe(
            op_pairwise,
        )->subscribe(sub {print Dumper($_[0])});

- op\_pluck

    [https://rxjs.dev/api/operators/pluck](https://rxjs.dev/api/operators/pluck)

        # Mary, Paul, undef, undef, undef, complete
        rx_of(
            {name => {first => 'Mary'}},
            {name => {first => 'Paul'}},
            {house => {first => 'Chicago'}},
            15,
            undef,
        )->pipe(
            op_pluck('name', 'first'),
        )->subscribe($observer);

- op\_race\_with

    [https://rxjs.dev/api/operators/raceWith](https://rxjs.dev/api/operators/raceWith)

        # 0, 1, 2, 3, 4, ... (every second)
        rx_interval(3)->pipe(
            op_race_with(
                rx_interval(2),
                rx_interval(1),
            ),
        )->subscribe($observer);

- op\_reduce

    [https://rxjs.dev/api/operators/reduce](https://rxjs.dev/api/operators/reduce)

        # (pause 6 seconds) 15, complete
        rx_interval(1)->pipe(
            op_take(6),
            op_reduce(sub ($acc, $value, $idx) { $acc + $value }, 0),
        )->subscribe($observer);

- op\_ref\_count

    [https://rxjs.dev/api/operators/refCount](https://rxjs.dev/api/operators/refCount)

- op\_repeat

    [https://rxjs.dev/api/operators/repeat](https://rxjs.dev/api/operators/repeat)

        # 10, 20, 30, 10, 20, 30, 10, 20, 30, complete
        rx_of(10, 20, 30)->pipe(
            op_repeat(3),
        )->subscribe($observer);

- op\_retry

    [https://rxjs.dev/api/operators/retry](https://rxjs.dev/api/operators/retry)

        # 10, 20, 30, 10, 20, 30, 10, 20, 30, error: foo
        rx_concat(
            rx_of(10, 20, 30),
            rx_throw_error('foo'),
        )->pipe(
            op_retry(2),
        )->subscribe($observer);

- op\_sample

    [https://rxjs.dev/api/operators/sample](https://rxjs.dev/api/operators/sample)

        # 0, 1, 3, 4, 6, 7, ...
        rx_interval(0.7)->pipe(
            op_sample(rx_interval(1)),
        )->subscribe($observer);

- op\_sample\_time

    [https://rxjs.dev/api/operators/sampleTime](https://rxjs.dev/api/operators/sampleTime)

    Works like rxjs's "sampleTime", except the parameter is in seconds instead of ms.

        # 0, 2, 3, 5, 6, 8, ...
        rx_interval(1)->pipe(
            op_sample_time(1.6),
        )->subscribe($observer);

- op\_scan

    [https://rxjs.dev/api/operators/scan](https://rxjs.dev/api/operators/scan)

        # 0, 1, 3, 6, 10, ...
        rx_interval(1)->pipe(
            op_scan(sub {
                my ($acc, $item) = @_;
                return $acc + $item;
            }, 0),
        )->subscribe($observer);

- op\_share

    [https://rxjs.dev/api/operators/share](https://rxjs.dev/api/operators/share)

        # t0, 0, 0, t1, 1, 1, t2, 2, 2, ...
        my $o = rx_interval(1)->pipe(
            op_tap(sub {say 't' . $_[0]}),
            op_share(),
        );

        $o->subscribe($observer1);
        $o->subscribe($observer2);

- op\_skip

    [https://rxjs.dev/api/operators/skip](https://rxjs.dev/api/operators/skip)

        # 40, 50, complete
        rx_of(10, 20, 30, 40, 50)->pipe(
            op_skip(3),
        )->subscribe($observer);

- op\_skip\_until

    [https://rxjs.dev/api/operators/skipUntil](https://rxjs.dev/api/operators/skipUntil)

        # (pause 4 seconds) 3, 4, 5, ...
        rx_interval(1)->pipe(
            op_skip_until( rx_timer(3.5) ),
        )->subscribe($observer);

- op\_skip\_while

    [https://rxjs.dev/api/operators/skipWhile](https://rxjs.dev/api/operators/skipWhile)

        # 5, 3, 7, 1, complete
        rx_of(1, 3, 5, 3, 7, 1)->pipe(
            op_skip_while(sub ($v, $idx) { $v < 4 }), # can also use $_ here
        )->subscribe($observer);

- op\_start\_with

    [https://rxjs.dev/api/operators/startWith](https://rxjs.dev/api/operators/startWith)

        # 100, 200, 0, 1, 2, 3, complete
        rx_of(0, 1, 2, 3)->pipe(
            op_start_with(100, 200),
        )->subscribe($observer);

- op\_switch\_all

    [https://rxjs.dev/api/operators/switchAll](https://rxjs.dev/api/operators/switchAll)

        # 0, 0, 0, 1, 2, 3, 4, complete
        rx_timer(0, 3)->pipe(
            op_take(3),
            op_map(sub { rx_interval(2)->pipe(op_take(5)) }),
            op_switch_all(),
        )->subscribe($observer);

- op\_switch\_map

    [https://rxjs.dev/api/operators/switchMap](https://rxjs.dev/api/operators/switchMap)

        # 1, 2, 3, 11, 12, 13, 21, 22, 23, 24, 25, 26, 27, ...
        my $o = rx_interval(2.5)->pipe( op_take(3) );

        $o->pipe(
            op_switch_map(sub ($x, $idx) {
                return rx_interval(0.7)->pipe(
                    op_map(sub ($y, $idx2) { $x * 10 + $y + 1 }),
                );
            }),
        )->subscribe($observer);

- op\_take

    [https://rxjs.dev/api/operators/take](https://rxjs.dev/api/operators/take)

        # 0, 1, 2, 3, 4, complete
        rx_interval(1)->pipe(
            op_take(5),
        )->subscribe($observer);

- op\_take\_last

    [https://rxjs.dev/api/operators/takeLast](https://rxjs.dev/api/operators/takeLast)

        # 3, 5, 6, complete
        rx_of(1, 2, 3, 5, 6)->pipe(
            op_take_last(3),
        )->subscribe($observer);

- op\_take\_until

    [https://rxjs.dev/api/operators/takeUntil](https://rxjs.dev/api/operators/takeUntil)

        # 0, 1, 2, 3, 4, complete
        rx_interval(1)->pipe(
            op_take_until( rx_timer(5.5) ),
        )->subscribe($observer);

- op\_take\_while

    [https://rxjs.dev/api/operators/takeWhile](https://rxjs.dev/api/operators/takeWhile)

        # 0, 1, 2, 3, 4, 5, complete
        rx_interval(1)->pipe(
            op_take_while(sub { $_[0] <= 5 }),
        )->subscribe($observer);

        # 0, 1, 2, 3, 4, 5, 6, complete
        rx_interval(1)->pipe(
            op_take_while(sub { $_[0] <= 5 }, 1),
        )->subscribe($observer);

- op\_tap

    [https://rxjs.dev/api/operators/tap](https://rxjs.dev/api/operators/tap)

        # foo0, 0, foo1, 1, foo2, 2, ...
        rx_interval(1)->pipe(
            op_tap(sub {say "foo$_[0]"}),
        )->subscribe($observer);

- op\_throttle

    [https://rxjs.dev/api/operators/throttle](https://rxjs.dev/api/operators/throttle)

        # 0, 2, 4, 6, 8, 10, ...
        rx_interval(0.7)->pipe(
            op_throttle(sub ($val) { rx_timer(1) }),
        )->subscribe($observer);

- op\_throttle\_time

    [https://rxjs.dev/api/operators/throttleTime](https://rxjs.dev/api/operators/throttleTime)

    Works like rxjs's "throttleTime", except the parameter is in seconds instead of ms.

    At the moment, this function only accepts `duration` as parameter, not the configuration options that
    rxjs's throttleTime accepts.

        # 0, 3, 6, 9, 12, ...
        rx_interval(1)->pipe(
            op_throttle_time(2.1),
        )->subscribe($observer);

- op\_throw\_if\_empty

    [https://rxjs.dev/api/operators/throwIfEmpty](https://rxjs.dev/api/operators/throwIfEmpty)

        # error: hello
        rx_timer(1)->pipe(
            op_ignore_elements(),
            op_throw_if_empty(sub { "hello" }),
        )->subscribe($observer);

        # 0, 1, 2, complete
        rx_interval(0.7)->pipe(
            op_take(3),
            op_throw_if_empty(sub { "hello" }),
        )->subscribe($observer);

- op\_to\_array

    [https://rxjs.dev/api/operators/toArray](https://rxjs.dev/api/operators/toArray)

        # [0, 1, 2, 3, 4], complete
        rx_interval(0.7)->pipe(
            op_take(5),
            op_to_array(),
        )->subscribe($observer);

- op\_with\_latest\_from

    [https://rxjs.dev/api/operators/withLatestFrom](https://rxjs.dev/api/operators/withLatestFrom)

        # [0, 0], [1, 1], [2, 3], [3, 4], [4, 6], ...
        rx_interval(1)->pipe(
            op_with_latest_from(rx_interval(0.7)),
        )->subscribe($observer);

- op\_zip\_with

    [https://rxjs.dev/api/operators/zipWith](https://rxjs.dev/api/operators/zipWith)

        # [0, 0, 0], [1, 1, 1], [2, 2, 2], complete
        rx_interval(0.7)->pipe(
            op_take(3),
            op_zip_with(
                rx_interval(1),
                rx_interval(2),
            ),
        )->subscribe($observer);

## PROMISE FUNCTIONS

These functions return a promise or a future, and require the existence of a user-selectable
promise library which is automatically loaded in runtime. The functions are borrowed from
rxjs 7, and remain experimental until rxjs 7 is finalized.

You can optionally set the type of promises returned by these functions with the
`RxPerl::AnyEvent->set_promise_class($promise_class)` class method, unless you're using
[RxPerl::AnyEvent](https://metacpan.org/pod/RxPerl%3A%3AAnyEvent), in which case it's mandatory.

By default the functions return a [Mojo::Promise](https://metacpan.org/pod/Mojo%3A%3APromise) object (when using with [RxPerl::Mojo](https://metacpan.org/pod/RxPerl%3A%3AMojo)),
or a [Future](https://metacpan.org/pod/Future) object (when using with [RxPerl::IOAsync](https://metacpan.org/pod/RxPerl%3A%3AIOAsync)).

- first\_value\_from

    Accepts an observable and returns a promise that resolves with the observable's first emitted value
    as soon as it gets emitted. If no value is emitted before the observable's completion, the promise
    is rejected.

        use RxPerl::AnyEvent ':all';
        RxPerl::AnyEvent->set_promise_class('Promise::ES6');

        my $o = ...; # an observable
        first_value_from($o)->then( ... );

- last\_value\_from

    Accepts an observable and returns a promise that resolves with the observable's last emitted value
    as soon as the observable completes. If no value is emitted before the observable's completion, the
    promise is rejected.

        use RxPerl::AnyEvent ':all';
        RxPerl::AnyEvent->set_promise_class('Promise::ES6');

        my $o = ...; # an observable
        last_value_from($o)->then( ... );

## OTHER FUNCTIONS

- is\_observable

    Returns true if the argument passed to it is an RxPerl Observable.

# OBSERVABLE METHODS

- subscribe

    [http://reactivex.io/rxjs/class/es6/Observable.js~Observable.html#instance-method-subscribe](http://reactivex.io/rxjs/class/es6/Observable.js~Observable.html#instance-method-subscribe)

        $o->subscribe(
            sub {say "next: $_[0]"},
            sub {say "error: $_[0]"},
            sub {say "complete"},
        );

        $o->subscribe(
            undef,
            sub {say "error: $_[0]"},
        );

        $o->subscribe({
            next => sub {say "next: $_[0]"},
            complete => sub {say "complete"},
        });

- pipe

    [http://reactivex.io/rxjs/class/es6/Observable.js~Observable.html#instance-method-pipe](http://reactivex.io/rxjs/class/es6/Observable.js~Observable.html#instance-method-pipe)

        # 2, 6, complete
        rx_interval(1)->pipe(
            op_take(5),
            op_filter(sub {$_[0] % 2 == 1}),
            op_map(sub {2 * $_[0]}),
        )->subscribe(...)

# CONNECTABLE OBSERVABLE METHODS

Connectable observables are a subclass of observables, which (like Subjects) are multicasting and can start emitting
even before anyone subscribes to them, by invoking a method. They are usually created and returned by the
["op\_multicast"](#op_multicast) pipeable operator.

- connect

    Makes the connectable observable start emitting.

        $o->connect;

# SUBJECT METHODS

Subjects multicast, and apart from being observables themselves (with their own subscribers), also have [next, error
and complete](#next-error-complete) methods of their own, so can be used as the observer argument to another
observable's subscribe method. That observable's events will then be "forwarded" to the subject's own subscribers,
as if next/error/complete had been called on the subject directly.

- next, error, complete

    Calling these methods manually will cause the subject's subscribers to receive the corresponding events.

Typically subjects don't emit anything on their own (as opposed to ["rx\_interval"](#rx_interval) et al), although it is possible to
create a subclass of Subject that behaves differently. An example is a queueing subject that accumulates
events from the observable it has been subscribed to, then emits all of them at once to the first subscriber that
subscribes to it.

# NAMING CONVENTIONS

To prevent naming collisions with Perl’s built-in functions (or the user’s own), as rxjs’s operators are often
small english words (such as `map`), the names of this module’s operators start with `rx_` or `op_`.

Functions that in the JS world would be imported from 'rxjs' have their corresponding RxPerl names prepended with
`rx_`, whereas functions imported from 'rxjs/operators' (namely pipeable opreators) start with `op_` in RxPerl.

    import {Observable, Subject, timer, interval} from 'rxjs';
    import {map, filter, delay} from 'rxjs/operators';

becomes:

    use RxPerl::IOAsync qw/
        rx_observable rx_subject rx_timer rx_interval
        op_map op_filter op_delay
    /;

# CAVEATS

Since the [rxjs implementation](https://rxjs.dev/api/) differs from the
[ReactiveX API](http://reactivex.io/documentation/operators.html) at a few points (as do most of the
[Rx\* libraries](http://reactivex.io/languages.html)), RxPerl chose to behave like rxjs rather than
ReactiveX to cater for web developers already familiar with rxjs.

# LEARNING RESOURCES

- [RxJS Top Ten - Code This, Not That](https://www.youtube.com/watch?v=ewcoEYS85Co)
- [Ultimate RxJS courses](https://ultimatecourses.com/courses/rxjs) _(paid)_
- [egghead RxJS courses](https://egghead.io/browse/libraries/rxjs) _(paid)_
- [Rx Marbles](https://rxmarbles.com/)

# SEE ALSO

- [Ryu](https://metacpan.org/pod/Ryu)

# NOTIFICATIONS FOR NEW RELEASES

You can start receiving emails for new releases of this module, at [https://perlmodules.net](https://perlmodules.net).

# COMMUNITY CODE OF CONDUCT

The Community Code of Conduct can be found [here](https://metacpan.org/pod/RxPerl%3A%3ACodeOfConduct).

# LICENSE

Copyright (C) 2020 Karelcom OÜ.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Alexander Karelas <karjala@cpan.org>
