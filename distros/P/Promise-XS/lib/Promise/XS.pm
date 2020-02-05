package Promise::XS;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

Promise::XS - Fast promises in Perl

=head1 SYNOPSIS

    use Promise::XS ();

    my $deferred = Promise::XS::deferred();

    # Do one of these once you have the result of your operation:
    $deferred->resolve( 'foo', 'bar' );
    $deferred->reject( 'oh', 'no!' );

    # Give this to your caller:
    my $promise = $deferred->promise();

The following aggregator functions are exposed:

    # Resolves with a list of arrayrefs, one per promise.
    # Rejects with the results from the first rejected promise.
    my $all_p = Promise::XS::all( $promise1, $promise2, .. );

    # Resolves/rejects with the results from the first
    # resolved or rejected promise.
    my $race_p = Promise::XS::race( $promise3, $promise4, .. );

For compatibility with preexisting libraries, C<all()> may also be called
as C<collect()>.

The following also exist:

    my $pre_resolved_promise = Promise::XS::resolved('already', 'done');

    my $pre_rejected_promise = Promise::XS::rejected('it’s', 'bad');

All of C<Promise::XS>’s static functions may be exported at load time,
e.g., C<use Promise::XS qw(deferred)>.

=head1 DESCRIPTION

This module exposes a Promise interface with its major parts
implemented in XS for speed. It is a fork and refactor of
L<AnyEvent::XSPromises>. That module’s interface, a “bare-bones”
subset of that from L<Promises>, is retained.

=head1 STATUS

Breaking changes in this interface are unlikely; however, the implementation
is relatively untested since the fork. Your mileage may vary.

=head1 DIFFERENCES FROM ECMASCRIPT PROMISES

This library is built for compatibility with pre-existing Perl promise
libraries. It thus exhibits some salient differences from how
ECMAScript promises work:

=over

=item * Promise resolutions and rejections consist of I<lists>, not
single values.

=item * Neither the C<resolve()> method of deferred objects
nor the C<resolved()> convenience function define behavior when given
a promise object.

=item * The C<all()> and C<race()> functions accept a list of promises,
not a “scalar-array-thing” (ECMAScript “arrays” being what in Perl we
call “array references”). So whereas in ECMAScript you do:

    Promise.all( [ promise1, promise2 ] );

… in this library it’s:

    Promise::XS::all( $promise1, $promise2 );

=back

See L<Promise::ES6> for an interface that imitates ECMAScript promises
more closely.

=head1 EVENT LOOPS

This library, by default, uses no event loop. This is a perfectly usable
configuration; however, it’ll be a bit different from how promises usually
work in evented contexts (e.g., JavaScript) because callbacks will execute
immediately rather than at the end of the event loop as the Promises/A+
specification requires.

To achieve full Promises/A+ compliance it’s necessary to integrate with
an event loop interface. This library supports three such interfaces:

=over

=item * L<AnyEvent>:

    Promise::XS::use_event('AnyEvent');

=item * L<IO::Async> - note the need for an L<IO::Async::Loop> instance
as argument:

    Promise::XS::use_event('IO::Async', $loop_object);

=item * L<Mojo::IOLoop>:

    Promise::XS::use_event('Mojo::IOLoop');

=back

Note that all three of the above are event loop B<interfaces>. They
aren’t event loops themselves, but abstractions over various event loops.
See each one’s documentation for details about supported event loops.

B<REMINDER:> There’s no reason why promises I<need> an event loop; it
just satisfies the Promises/A+ convention.

=head1 MEMORY LEAK DETECTION

Any promise created while C<$Promise::XS::DETECT_MEMORY_LEAKS> is truthy
will throw a warning if it survives until global destruction.

=head1 SUBCLASSING

You can re-bless a L<Promise::XS::Promise> instance into a different class,
and C<then()>, C<catch()>, and C<finally()> will assign their newly-created
promise into that other class. (It follows that the other class must subclass
L<Promise::XS::Promise>.) This can be useful, e.g., for implementing
mid-flight controls like cancellation.

=head1 TODO

=over

=item * C<all()> and C<race()> should be implemented in XS,
as should C<resolved()> and C<rejected()>.

=back

=head1 KNOWN ISSUES

=over

=item * Interpreter-based threads may or may not work.

=item * This module interacts badly with Perl’s fork() implementation on
Windows. There may be a workaround possible, but none is implemented for now.

=back

=cut

use Exporter 'import';
our @EXPORT_OK= qw/all collect deferred resolved rejected/;

use Promise::XS::Loader ();
use Promise::XS::Deferred ();
use Promise::XS::Promise ();

our $DETECT_MEMORY_LEAKS;

use constant DEFERRAL_CR => {
    AnyEvent => \&Promise::XS::Deferred::set_deferral_AnyEvent,
    'IO::Async' => \&Promise::XS::Deferred::set_deferral_IOAsync,
    'Mojo::IOLoop' => \&Promise::XS::Deferred::set_deferral_Mojo,
};

# convenience
*deferred = *Promise::XS::Deferred::create;

sub use_event {
    my ($name, @args) = @_;

    if (my $cr = DEFERRAL_CR()->{$name}) {
        $cr->(@args);
    }
    else {
        die( __PACKAGE__ . ": unknown event engine: $name" );
    }
}

sub resolved {
    return deferred()->resolve(@_)->promise();
}

sub rejected {
    return deferred()->reject(@_)->promise();
}

#----------------------------------------------------------------------
# Aggregator functions

# Lifted from AnyEvent::XSPromises
sub all {
    my $remaining= 0+@_;
    my @values;
    my $failed= 0;
    my $then_what= deferred();
    my $pending= 1;
    my $i= 0;

    my $reject_now = sub {
        if (!$failed++) {
            $pending= 0;
            $then_what->reject(@_);
        }
    };

    for my $p (@_) {
        my $i = $i++;

        $p->then(
            sub {
                $values[$i]= \@_;
                if ((--$remaining) == 0) {
                    $pending= 0;
                    $then_what->resolve(@values);
                }
            },
            $reject_now,
        );
    }
    if (!$remaining && $pending) {
        $then_what->resolve(@values);
    }
    return $then_what->promise;
}

# Compatibility with other promise interfaces.
*collect = *all;

# Lifted from Promise::ES6
sub race {

    my $deferred = deferred();

    my $is_done;

    my $on_resolve_cr = sub {
        return if $is_done;
        $is_done = 1;

        $deferred->resolve(@_);

        # Proactively eliminate references:
        undef $deferred;
    };

    my $on_reject_cr = sub {
        return if $is_done;
        $is_done = 1;

        $deferred->reject(@_);

        # Proactively eliminate references:
        undef $deferred;
    };

    for my $given_promise (@_) {
        last if $is_done;

        $given_promise->then($on_resolve_cr, $on_reject_cr);
    }

    return $deferred->promise();
}

#----------------------------------------------------------------------

=head1 SEE ALSO

Besides L<AnyEvent::XSPromises> and L<Promises>, you may like L<Promise::ES6>,
which mimics L<ECMAScript’s “Promise” class|https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Promise> as much as possible.
It can even
(experimentally) use this module as a backend, which helps but is still
significantly slower than using this module directly.

=cut

1;
