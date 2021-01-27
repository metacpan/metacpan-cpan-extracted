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

Currently 54 of the 100+ operators in rxjs are implemented in this module.

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

    Currently, only arrayrefs, promises, observables and strings are allowed as argument to this function.

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

- rx\_of

    [https://rxjs.dev/api/index/function/of](https://rxjs.dev/api/index/function/of)

        # 10, 20, 30, complete
        rx_of(10, 20, 30)->subscribe($observer);

- rx\_race

    [https://rxjs.dev/api/index/function/race](https://rxjs.dev/api/index/function/race)

        # 0, 10, 20, 30, ... (every 0.7 seconds)
        rx_race(
            rx_interval(1)->pipe( op_map(sub {$_[0] * 100}) ),
            rx_interval(0.7)->pipe( op_map(sub {$_[0] * 10) ),
        )->subscribe($observer);

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

## PIPEABLE OPERATORS

Pipeable operators (also referred to as "operators") are passed as arguments to the ["pipe"](#pipe) method of
observables. Their function is to take an observable, transform it somehow, then (similar to piped shell commands) pass
the result of the transformation to the next pipeable operator in the pipe, or return it to the user.

The following list is the currently implemented operators, with links to relevant rxjs documentation (which should apply to RxPerl
too).

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

- op\_catch\_error

    [https://rxjs.dev/api/operators/catchError](https://rxjs.dev/api/operators/catchError)

        # foo, foo, foo, complete
        rx_throw_error('foo')->pipe(
            op_catch_error(sub ($err, $caught) { rx_of($err, $err, $err) }),
        )->subscribe($observer);

- op\_concat\_map

    [https://rxjs.dev/api/operators/concatMap](https://rxjs.dev/api/operators/concatMap)

        # 0, 1, 2, 0, 1, 2, 0, 1, 2, complete
        rx_of(10, 20, 30)->pipe(
            op_concat_map(sub {
                rx_interval(1)->pipe(op_take(3)),
            }),
        )->subscribe($observer);

- op\_debounce\_time

    [https://rxjs.dev/api/operators/debounceTime](https://rxjs.dev/api/operators/debounceTime)

    Works like rxjs's "debounceTime", except the parameter is in seconds instead of ms.

        # 3, complete
        rx_of(1, 2, 3)->pipe(
            op_debounce_time(0.5),
        )->subscribe($observer);

- op\_delay

    [https://rxjs.dev/api/operators/delay](https://rxjs.dev/api/operators/delay)

    Works like rxjs's "delay", except the parameter is in seconds instead of ms.

        # (pause 11 seconds) 0, 1, 2, 3, ...
        rx_interval(1)->pipe(
            op_delay(10)
        )->subscribe($observer);

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

- op\_end\_with

    [https://rxjs.dev/api/operators/endWith](https://rxjs.dev/api/operators/endWith)

        # 0, 1, 2, 3, 100, 200, complete
        rx_of(0, 1, 2, 3)->pipe(
            op_end_with(100, 200),
        )->subscribe($observer);

- op\_exhaust\_map

    [https://rxjs.dev/api/operators/exhaustMap](https://rxjs.dev/api/operators/exhaustMap)

        # 0, 1, 2, complete
        rx_of(10, 20, 30)->pipe(
            op_exhaust_map(sub {
                rx_interval(1)->pipe( op_take(3) );
            }),
        )->subscribe($observer);

- op\_filter

    [https://rxjs.dev/api/operators/filter](https://rxjs.dev/api/operators/filter)

        # 0, 2, 4, 6, ... (every 1.4 seconds)
        rx_interval(0.7)->pipe(
            op_filter(sub {$_[0] % 2 == 0}),
        )->subscribe($observer);

        # 10, 36, 50, complete
        rx_of(10, 22, 36, 41, 50, 73)->pipe(
            op_filter(sub ($v, $idx) { $idx % 2 == 0 }),
        )->subscribe($observer);

- op\_finalize

    [https://rxjs.dev/api/operators/finalize](https://rxjs.dev/api/operators/finalize)

        # 1, 2, 3, complete, 'hi there'
        rx_of(1, 2, 3)->pipe(
            op_finalize(sub {print "hi there\n"}),
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

- op\_map

    [https://rxjs.dev/api/operators/map](https://rxjs.dev/api/operators/map)

        # 10, 11, 12, 13, ...
        rx_interval(1)->pipe(
            op_map(sub {$_[0] + 10}),
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

- op\_merge\_map

    [https://rxjs.dev/api/operators/mergeMap](https://rxjs.dev/api/operators/mergeMap)

        # 11, 21, 31, 12, 22, 32, 13, 23, 33, complete
        rx_of(10, 20, 30)->pipe(
            op_merge_map(sub ($x) {
                return rx_interval(1)->pipe(
                    op_map(sub ($y) {
                        return $x + $y + 1;
                    }),
                    op_take(3),
                );
            }),
        )->subscribe($observer);

- op\_multicast

    [https://rxjs.dev/api/operators/multicast](https://rxjs.dev/api/operators/multicast)

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

- op\_start\_with

    [https://rxjs.dev/api/operators/startWith](https://rxjs.dev/api/operators/startWith)

        # 100, 200, 0, 1, 2, 3, complete
        rx_of(0, 1, 2, 3)->pipe(
            op_start_with(100, 200),
        )->subscribe($observer);

- op\_switch\_map

    [https://rxjs.dev/api/operators/switchMap](https://rxjs.dev/api/operators/switchMap)

        # 1, 2, 3, 11, 12, 13, 21, 22, 23, 24, 25, 26, 27, ...
        my $o = rx_interval(2.5)->pipe( op_take(3) );

        $o->pipe(
            op_switch_map(sub ($x) {
                return rx_interval(0.7)->pipe(
                    op_map(sub ($y) { $x * 10 + $y + 1 }),
                );
            }),
        )->subscribe($observer);

- op\_take

    [https://rxjs.dev/api/operators/take](https://rxjs.dev/api/operators/take)

        # 0, 1, 2, 3, 4, complete
        rx_interval(1)->pipe(
            op_take(5),
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

- op\_throttle\_time

    [https://rxjs.dev/api/operators/throttleTime](https://rxjs.dev/api/operators/throttleTime)

    Works like rxjs's "throttleTime", except the parameter is in seconds instead of ms.

    At the moment, this function only accepts `duration` as parameter, not the configuration options that
    rxjs's throttleTime accepts.

        # 0, 3, 6, 9, 12, ...
        rx_interval(1)->pipe(
            op_throttle_time(2.1),
        )->subscribe($observer);

- op\_with\_latest\_from

    [https://rxjs.dev/api/operators/withLatestFrom](https://rxjs.dev/api/operators/withLatestFrom)

        # [0, 0], [1, 1], [2, 3], [3, 4], [4, 6], ...
        rx_interval(1)->pipe(
            op_with_latest_from(rx_interval(0.7)),
        )->subscribe($observer);

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

# NOTIFICATIONS FOR NEW VERSIONS

You can start receiving emails for new releases of this module, at [https://perlmodules.net](https://perlmodules.net).

# LICENSE

Copyright (C) Karelcom OÜ.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

KARJALA <karjala@cpan.org>
