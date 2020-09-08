# NAME

RxPerl - an implementation of Reactive Extensions / rxjs for Perl

# SYNOPSIS

    use RxPerl::AnyEvent ':all';
    use AnyEvent;

    sub make_subscriber ($i) {
        return {
            next     => sub {say "next #$i: ", $_[0]},
            error    => sub {say "error #$i: ", $_[0]},
            complete => sub {say "complete #$i"},
        };
    }

    my $o = rx_interval(0.7)->pipe(
        op_map(sub {$_[0] * 2}),
        op_take_until( rx_timer(5) ),
    );

    $o->subscribe(make_subscriber(1));

    AnyEvent->condvar->recv;

    use RxPerl::IOAsync ':all';
    use IO::Async::Loop;

    my $loop = IO::Async::Loop->new;
    RxPerl::IOAsync::set_loop($loop);

    sub make_subscriber ($i) {
        return {
            next     => sub {say "next #$i: ", $_[0]},
            error    => sub {say "error #$i: ", $_[0]},
            complete => sub {say "complete #$i"},
        };
    }

    my $o = rx_interval(0.7)->pipe(
        op_map(sub {$_[0] * 2}),
        op_take_until( rx_timer(5) ),
    );

    $o->subscribe(make_subscriber(1));

    $loop->run;

    use RxPerl::Mojo ':all';
    use Mojo::IOLoop;

    sub make_subscriber ($i) {
        return {
            next     => sub {say "next #$i: ", $_[0]},
            error    => sub {say "error #$i: ", $_[0]},
            complete => sub {say "complete #$i"},
        };
    }

    my $o = rx_interval(0.7)->pipe(
        op_map(sub {$_[0] * 2}),
        op_take_until( rx_timer(5) ),
    );

    $o->subscribe(make_subscriber(1));

    Mojo::IOLoop->start;

# DESCRIPTION

This module is an implementation of [Reactive Extensions](http://reactivex.io/) in Perl. It replicates the
behavior of [rxjs 6](https://www.npmjs.com/package/rxjs) which is the JavaScript implementation of ReactiveX.

Currently 26 of the 100+ operators in rxjs are implemented in this module.

# EXPORTABLE FUNCTIONS

The code samples in this section assume $subscriber has been set to:

    $subscriber = {
        next     => sub {say "next: ", $_[0]},
        error    => sub {say "error: ", $_[0]},
        complete => sub {say "complete"},
    };

## OBSERVABLE CREATION OPERATORS

Creation operators create and return an _observable_. They are usually unicast, which means that when an
["rx\_interval"](#rx_interval) _observable_ is subscribed to three seperate times there will be three different & distinct recurring
intervals. Exceptions to this are with [subjects](#rx_subject), and that any observable can be transformed into a
[multicasting](https://www.learnrxjs.io/learn-rxjs/operators/multicasting) one using the ["op\_share"](#op_share) pipeable
operator (or by other similar operators).

The following list is the currently implemented creation operators with links to relevant rxjs documentation (which
should apply to RxPerl too).

- rx\_concat

    [https://rxjs.dev/api/index/function/concat](https://rxjs.dev/api/index/function/concat)

        # 10, 20, 30, 10, 20, 30, 40, complete
        rx_concat(
            rx_of(10, 20, 30),
            rx_of(10, 20, 30, 40),
        )->subscribe($subscsriber);

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
        )->subscribe($subscriber);

- rx\_EMPTY

    [https://rxjs.dev/api/index/const/EMPTY](https://rxjs.dev/api/index/const/EMPTY)

        # complete
        rx_EMPTY->subscribe($subscriber);

        # 10, 20, 30, 40, 50, 60, complete
        rx_concat(
            rx_of(10, 20, 30),
            rx_EMPTY,
            rx_EMPTY,
            rx_EMPTY,
            rx_of(40, 50, 60),
        )->subscribe($subscriber);

- rx\_from

    [https://rxjs.dev/api/index/function/from](https://rxjs.dev/api/index/function/from)

    Currently, only arrayrefs, promises, and observables are allowed as argument to this function.

        # 10, 20, 30, complete
        rx_from([10, 20, 30])->subscribe($subscriber);

- rx\_from\_event

    [https://rxjs.dev/api/index/function/fromEvent](https://rxjs.dev/api/index/function/fromEvent)

    Currently, only instances of the [Mojo::EventEmitter](https://metacpan.org/pod/Mojo%3A%3AEventEmitter) class are allowed as the first argument to this function.

        # 4 seconds after Mojolicious hypnotoad is gracefully reloaded, websocket
        # connection will close

        sub websocket ($c) {
            rx_from_event($ioloop, 'finish')->pipe(
                op_delay(4),
            )->subscribe(
                next => sub { $c->finish },
            );
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
        rx_interval(0.7)->subscribe($subscriber);

- rx\_merge

    [https://rxjs.dev/api/index/function/merge](https://rxjs.dev/api/index/function/merge)

        # 0, 0, 1, 1, 2, 2, 3, 4, 3, ...
        rx_merge(
            rx_interval(0.7),
            rx_interval(1),
        )->subscribe($subscriber);

- rx\_NEVER

    [https://rxjs.dev/api/index/const/NEVER](https://rxjs.dev/api/index/const/NEVER)

        # 10, 20, 30 (and no complete)
        rx_concat(
            rx_of(10, 20, 30),
            rx_NEVER,
            rx_of(40, 50, 60),
        )->subscribe($subscriber);

- rx\_observable

    [https://rxjs.dev/api/index/class/Observable](https://rxjs.dev/api/index/class/Observable)

        0.578, 0.234, 0.678, ... (every 1 second)
        my $o = rx_observable->new(sub ($subscriber) {
            # your code goes here
            Mojo::IOLoop->recurring(1, sub {$subscriber->next(rand())});
        });

- rx\_of

    [https://rxjs.dev/api/index/function/of](https://rxjs.dev/api/index/function/of)

        # 10, 20, 30, complete
        rx_of(10, 20, 30)->subscribe($subscriber);

- rx\_race

    [https://rxjs.dev/api/index/function/race](https://rxjs.dev/api/index/function/race)

        # 0, 10, 20, 30, ... (every 0.7 seconds)
        rx_race(
            rx_interval(1)->pipe( op_map(sub {$_[0] * 100}) ),
            rx_interval(0.7)->pipe( op_map(sub {$_[0] * 10) ),
        )->subscribe($subscriber);

- rx\_subject

    [https://rxjs.dev/api/index/class/Subject](https://rxjs.dev/api/index/class/Subject)

        my $subject = rx_subject->new;
        $subject->subscribe($subscriber);

        # elsewhere...
        $subject->next($_) for 1 .. 10;
        $subject->complete;

- rx\_throw\_error

    [https://rxjs.dev/api/index/function/throwError](https://rxjs.dev/api/index/function/throwError)

        # 0, 1, 2, 3, error: foo
        rx_concat(
            rx_interval(1)->pipe( op_take(4) ),
            rx_throw_error('foo'),
        )->subscribe($subscriber);

- rx\_timer

    [https://rxjs.dev/api/index/function/timer](https://rxjs.dev/api/index/function/timer)

    Works like rxjs's "timer", except the parameter is in seconds instead of ms.

        # (pause 10 seconds) 0, 1, 2, 3, ... (every 1 second)
        rx_timer(10, 1)->subscribe($subscriber);

        # (pause 10 seconds) 0, complete
        rx_timer(10)->subscriber($subscriber);

## PIPEABLE OPERATORS

Pipeable operators (also referred to as "operators") are passed as arguments to the ["pipe"](#pipe) method of
observables. Their function is to take an observable, transform it somehow, then (similar to piped shell commands) pass
the result of the transformation to the next pipeable operator in the pipe, or return it to the user.

The following list is the currently implemented operators, with links to relevant rxjs documentation (which should apply to RxPerl
too).

- op\_delay

    [https://rxjs.dev/api/operators/delay](https://rxjs.dev/api/operators/delay)

    Works like rxjs's "delay", except the parameter is in seconds instead of ms.

        # (pause 10 seconds) 0, 1, 2, 3
        rx_interval(1)->pipe( op_delay(10) )->subscribe($subscriber);

- op\_filter

    [https://rxjs.dev/api/operators/filter](https://rxjs.dev/api/operators/filter)

        # 0, 2, 4, 6, ... (every 1.4 seconds)
        rx_interval(0.7)->pipe(
            op_filter(sub {$_[0] % 2 == 0}),
        )->subscribe($subscriber);

- op\_map

    [https://rxjs.dev/api/operators/map](https://rxjs.dev/api/operators/map)

        # 10, 11, 12, 13, ...
        rx_interval(1)->pipe(
            op_map(sub {$_[0] + 10}),
        )->subscribe($subscriber);

- op\_map\_to

    [https://rxjs.dev/api/operators/mapTo](https://rxjs.dev/api/operators/mapTo)

        # 123, 123, 123, ... (every 1 second)
        rx_interval(1)->pipe(
            map_to(123),
        )->subscribe($subscriber);

- op\_multicast

    [https://rxjs.dev/api/operators/multicast](https://rxjs.dev/api/operators/multicast)

- op\_pairwise

    [https://rxjs.dev/api/operators/pairwise](https://rxjs.dev/api/operators/pairwise)

        # [0, 1], [1, 2], [2, 3], ...
        rx_interval(1)->pipe(
            op_pairwise,
        )->subscribe(sub {print Dumper($_[0])});

- op\_ref\_count

    [https://rxjs.dev/api/operators/refCount](https://rxjs.dev/api/operators/refCount)

- op\_scan

    [https://rxjs.dev/api/operators/scan](https://rxjs.dev/api/operators/scan)

- op\_share

    [https://rxjs.dev/api/operators/share](https://rxjs.dev/api/operators/share)

        # t0, 0, 0, t1, 1, 1, t2, 2, 2, ...
        my $o = rx_interval(1)->pipe(
            op_tap(sub {say 't' . $_[0]}),
            op_share(),
        );

        $o->subscribe($subscriber1);
        $o->subscribe($subscriber2);

- op\_start\_with

    [https://rxjs.dev/api/operators/startWith](https://rxjs.dev/api/operators/startWith)

        # 100, 200, 0, 1, 2, 3, complete
        rx_of(0, 1, 2, 3)->pipe(
            op_start_with(100, 200),
        )->subscribe($subscriber);

- switch\_map

    [https://rxjs.dev/api/operators/switchMap](https://rxjs.dev/api/operators/switchMap)

        # 1, 2, 3, 11, 12, 13, 21, 22, 23, 24, 25, 26, 27, ...
        my $o = rx_interval(2.5)->pipe( op_take(3) );

        $o->pipe(
            op_switch_map(sub ($x) {
                return rx_interval(0.7)->pipe(
                    op_map(sub ($y) { $x * 10 + $y + 1 }),
                );
            }),
        )->subscribe($subscriber);

- op\_take

    [https://rxjs.dev/api/operators/take](https://rxjs.dev/api/operators/take)

        # 0, 1, 2, 3, 4, complete
        rx_interval(1)->pipe(
            op_take(5),
        )->subscribe($subscriber);

- op\_take\_until

    [https://rxjs.dev/api/operators/takeUntil](https://rxjs.dev/api/operators/takeUntil)

        # 0, 1, 2, 3, 4, complete
        rx_interval(1)->pipe(
            op_take_until( rx_timer(5.5) ),
        )->subscribe($subscriber);

- op\_tap

    [https://rxjs.dev/api/operators/tap](https://rxjs.dev/api/operators/tap)

        # foo0, 0, foo1, 1, foo2, 2, ...
        rx_interval(1)->pipe(
            op_tap(sub {say "foo$_[0]"}),
        )->subscribe($subscriber);

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

        # 2, 6
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
and complete](#next-error-complete) methods of their own, so can be used as the subscriber argument to another
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

# GUIDE TO CREATING YOUR OWN CREATION & PIPEABLE OPERATORS

- If you need the upstream and downstreams subscribers to complete at the same time,
pass the entire contents of the downstream subscriber object to the upstream subscriber.
This will pass the \_subscription key as well, and that way you will not need to return a
request to unsubscribe from the upstream, from your observable declaration. Just like `op_map`
does with this line, and just returns then with `return;`:

        my $own_subscriber = { %$subscriber };

# TODO

- Fix the occasional bug
- Implement more operators, based on user requests

# SEE ALSO

- [Rx Marbles](https://rxmarbles.com/)
- [Ryu module's SEE ALSO section](https://metacpan.org/pod/Ryu#SEE-ALSO)

# LICENSE

Copyright (C) Karelcom OÜ.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

KARJALA Corp <karjala@cpan.org>
