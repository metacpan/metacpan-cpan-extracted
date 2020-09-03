package RxPerl;
use 5.010;
use strict;
use warnings FATAL => 'all';

use RxPerl::Operators::Creation ':all';
use RxPerl::Operators::Pipeable ':all';

use Exporter 'import';
our @EXPORT_OK = (
    @RxPerl::Operators::Creation::EXPORT_OK,
    @RxPerl::Operators::Pipeable::EXPORT_OK,
);
our %EXPORT_TAGS = (all => \@EXPORT_OK);

our $VERSION = "v0.15.0";

1;
__END__

=encoding utf-8

=head1 NAME

RxPerl - an implementation of Reactive Extensions / rxjs for Perl

=head1 SYNOPSIS

=pod

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

=pod

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

=pod

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

=head1 DESCRIPTION

This module is an implementation of L<Reactive Extensions|http://reactivex.io/> in Perl. It replicates the
behavior of L<rxjs 6|https://www.npmjs.com/package/rxjs> which is the JavaScript implementation of ReactiveX.

Currently 26 of the 100+ operators in rxjs are implemented in this module.

=head1 EXPORTABLE FUNCTIONS

The code samples in this section assume $subscriber has been set to:

    $subscriber = {
        next     => sub {say "next: ", $_[0]},
        error    => sub {say "error: ", $_[0]},
        complete => sub {say "complete"},
    };

=head2 OBSERVABLE CREATION OPERATORS

Creation operators create and return an I<observable>. They are usually unicast, which means that when an
L</rx_interval> I<observable> is subscribed to three seperate times there will be three different & distinct recurring
intervals. Exceptions to this are with L<subjects|/rx_subject>, and that any observable can be transformed into a
L<multicasting|https://www.learnrxjs.io/learn-rxjs/operators/multicasting> one using the L</op_share> pipeable
operator (or by other similar operators).

The following list is the currently implemented creation operators with links to relevant rxjs documentation (which
should apply to RxPerl too).

=over

=item rx_concat

L<https://rxjs.dev/api/index/function/concat>

    # 10, 20, 30, 10, 20, 30, 40, complete
    rx_concat(
        rx_of(10, 20, 30),
        rx_of(10, 20, 30, 40),
    )->subscribe($subscsriber);

=item rx_defer

L<https://rxjs.dev/api/index/function/defer>

    # Suppose "int rand 10" here evaluates to 7. Then if after 7 seconds $special_var holds a true value,
    # output will be: 0, 1, 2, 3, 4, 5, 6, 10, 20, 30, complete, otherwise it will be:
    # 0, 1, 2, 3, 4, 5, 6, 40, 50, 60, complete.

    rx_concat(
        rx_interval(1)->pipe( op_take(int rand 10) ),
        rx_defer(sub {
            return $special_var ? rx_of(10, 20, 30) : rx_of(40, 50, 60)
        })
    )->subscribe($subscriber);

=item rx_EMPTY

L<https://rxjs.dev/api/index/const/EMPTY>

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

=item rx_from_event

L<https://rxjs.dev/api/index/function/fromEvent>

Currently, only instances of the L<Mojo::EventEmitter> class are allowed as the first argument of this function.

    # 4 seconds after Mojolicious hypnotoad is gracefully reloaded, websocket
    # connection will close

    sub websocket ($c) {
        rx_from_event($ioloop, 'finish')->pipe(
            op_delay(4),
        )->subscribe(
            next => sub { $c->finish },
        );
    }

=item rx_from_event_array

L<https://rxjs.dev/api/index/function/fromEvent>

Similar to: L</rx_from_event>.

Observables may emit at most one value per event, however L<Mojo::EventEmitter>'s are able to emit
more. So this function serves to pack all of them in an arrayref, and emit that as a single value instead.

=item rx_interval

L<https://rxjs.dev/api/index/function/interval>

Works like rxjs's "interval", except the parameter is in seconds instead of ms.

    # 0, 1, 2, ... every 0.7 seconds
    rx_interval(0.7)->subscribe($subscriber);

=item rx_merge

L<https://rxjs.dev/api/index/function/merge>

    # 0, 0, 1, 1, 2, 2, 3, 4, 3, ...
    rx_merge(
        rx_interval(0.7),
        rx_interval(1),
    )->subscribe($subscriber);

=item rx_NEVER

L<https://rxjs.dev/api/index/const/NEVER>

    # 10, 20, 30 (and no complete)
    rx_concat(
        rx_of(10, 20, 30),
        rx_NEVER,
        rx_of(40, 50, 60),
    )->subscribe($subscriber);

=item rx_observable

L<https://rxjs.dev/api/index/class/Observable>

    0.578, 0.234, 0.678, ... (every 1 second)
    my $o = rx_observable->new(sub ($subscriber) {
        # your code goes here
        Mojo::IOLoop->recurring(1, sub {$subscriber->next(rand())});
    });

=item rx_of

L<https://rxjs.dev/api/index/function/of>

    # 10, 20, 30, complete
    rx_of(10, 20, 30)->subscribe($subscriber);

=item rx_race

L<https://rxjs.dev/api/index/function/race>

    # 0, 10, 20, 30, ... (every 0.7 seconds)
    rx_race(
        rx_interval(1)->pipe( op_map(sub {$_[0] * 100}) ),
        rx_interval(0.7)->pipe( op_map(sub {$_[0] * 10) ),
    )->subscribe($subscriber);

=item rx_subject

L<https://rxjs.dev/api/index/class/Subject>

    my $subject = rx_subject->new;
    $subject->subscribe($subscriber);

    # elsewhere...
    $subject->next($_) for 1 .. 10;
    $subject->complete;

=item rx_throw_error

L<https://rxjs.dev/api/index/function/throwError>

    # 0, 1, 2, 3, error: foo
    rx_merge(
        rx_throw_error('foo')->pipe( op_delay(4.5) ),
        rx_interval(1),
    )->subscribe($subscriber);

=item rx_timer

L<https://rxjs.dev/api/index/function/timer>

Works like rxjs's "timer", except the parameter is in seconds instead of ms.

    # (pause 10 seconds) 0, 1, 2, 3, ... (every 1 second)
    rx_timer(10, 1)->subscribe($subscriber);

    # (pause 10 seconds) 0, complete
    rx_timer(10)->subscriber($subscriber);

=back

=head2 PIPEABLE OPERATORS

Pipeable operators (also referred to as "operators") are passed as arguments to the L</pipe> method of
observables. Their function is to take an observable, transform it somehow, then (similar to piped shell commands) pass
the result of the transformation to the next pipeable operator in the pipe, or return it to the user.

The following list is the currently implemented operators, with links to relevant rxjs documentation (which should apply to RxPerl
too).

=over

=item op_delay

L<https://rxjs.dev/api/operators/delay>

    # (pause 10 seconds) 0, 1, 2, 3
    rx_interval(1)->pipe( op_delay(10) )->subscribe($subscriber);

=item op_filter

L<https://rxjs.dev/api/operators/filter>

    # 0, 2, 4, 6, ... (every 1.4 seconds)
    rx_interval(0.7)->pipe(
        op_filter(sub {$_[0] % 2 == 0}),
    )->subscribe($subscriber);

=item op_map

L<https://rxjs.dev/api/operators/map>

    # 10, 11, 12, 13, ...
    rx_interval(1)->pipe(
        op_map(sub {$_[0] + 10}),
    )->subscribe($subscriber);

=item op_map_to

L<https://rxjs.dev/api/operators/mapTo>

    # 123, 123, 123, ... (every 1 second)
    rx_interval(1)->pipe(
        map_to(123),
    )->subscribe($subscriber);

=item op_multicast

L<https://rxjs.dev/api/operators/multicast>

=item op_pairwise

L<https://rxjs.dev/api/operators/pairwise>

    # [0, 1], [1, 2], [2, 3], ...
    rx_interval(1)->pipe(
        op_pairwise,
    )->subscribe(sub {print Dumper($_[0])});

=item op_ref_count

L<https://rxjs.dev/api/operators/refCount>

=item op_scan

L<https://rxjs.dev/api/operators/scan>

=item op_share

L<https://rxjs.dev/api/operators/share>

=item op_take

L<https://rxjs.dev/api/operators/take>

    # 0, 1, 2, 3, 4, complete
    rx_interval(1)->pipe(
        op_take(5),
    )->subscribe($subscriber);

=item op_take_until

L<https://rxjs.dev/api/operators/takeUntil>

    # 0, 1, 2, 3, 4, complete
    rx_interval(1)->pipe(
        op_take_until( rx_timer(5.5) ),
    )->subscribe($subscriber);

=item op_tap

L<https://rxjs.dev/api/operators/tap>

    # foo0, 0, foo1, 1, foo2, 2, ...
    rx_interval(1)->pipe(
        op_tap(sub {say "foo$_[0]"}),
    )->subscribe($subscriber);

=back

=head1 OBSERVABLE METHODS

=over

=item subscribe

L<http://reactivex.io/rxjs/class/es6/Observable.js~Observable.html#instance-method-subscribe>

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

=item pipe

L<http://reactivex.io/rxjs/class/es6/Observable.js~Observable.html#instance-method-pipe>

    # 2, 6
    rx_interval(1)->pipe(
        op_take(5),
        op_filter(sub {$_[0] % 2 == 1}),
        op_map(sub {2 * $_[0]}),
    )->subscribe(...)


=back

=head1 CONNECTABLE OBSERVABLE METHODS

Connectable observables are a subclass of observables, which (like Subjects) are multicasting and can start emitting
even before anyone subscribes to them, by invoking a method. They are usually created and returned by the
L</op_multicast> pipeable operator.

=over

=item connect

Makes the connectable observable start emitting.

    $o->connect;

=back

=head1 SUBJECT METHODS

Subjects multicast, and apart from being observables themselves (with their own subscribers), also have L<next, error
and complete|/"next, error, complete"> methods of their own, so can be used as the subscriber argument to another
observable's subscribe method. That observable's events will then be "forwarded" to the subject's own subscribers,
as if next/error/complete had been called on the subject directly.

=over

=item next, error, complete

Calling these methods manually will cause the subject's subscribers to receive the corresponding events.

=back

Typically subjects don't emit anything on their own (as opposed to L</rx_interval> et al), although it is possible to
create a subclass of Subject that behaves differently. An example is a queueing subject that accumulates
events from the observable it has been subscribed to, then emits all of them at once to the first subscriber that
subscribes to it.

=head1 NAMING CONVENTIONS

To prevent naming collisions with Perl’s built-in functions (or the user’s own), as rxjs’s operators are often
small english words (such as C<map>), the names of this module’s operators start with C<rx_> or C<op_>.

Functions that in the JS world would be imported from 'rxjs' have their corresponding RxPerl names prepended with
C<rx_>, whereas functions imported from 'rxjs/operators' (namely pipeable opreators) start with C<op_> in RxPerl.

    import {Observable, Subject, timer, interval} from 'rxjs';
    import {map, filter, delay} from 'rxjs/operators';

becomes:

    use RxPerl::IOAsync qw/
        rx_observable rx_subject rx_timer rx_interval
        op_map op_filter op_delay
    /;

=head1 CAVEATS

Since the L<rxjs implementation|https://rxjs.dev/api/> differs from the
L<ReactiveX API|http://reactivex.io/documentation/operators.html> at a few points (as do most of the
L<Rx* libraries|http://reactivex.io/languages.html>), RxPerl chose to behave like rxjs rather than
ReactiveX to cater for web developers already familiar with rxjs.

=head1 TODO

=over

=item * Unhandled I<error> events ought to throw an exception

=item * Fix the occasional bug

=item * Short guide on how to create a creation or a pipeable operator

=back

=head1 LICENSE

Copyright (C) Karelcom OÜ.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

KARJALA Corp E<lt>karjala@cpan.orgE<gt>

=cut
