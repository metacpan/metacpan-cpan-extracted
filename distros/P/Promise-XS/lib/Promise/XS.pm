package Promise::XS;

use strict;
use warnings;

our $VERSION;

BEGIN {
    $VERSION = '0.16';
}

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

=begin html

<a href='https://coveralls.io/github/FGasper/p5-Promise-XS?branch=master'><img src='https://coveralls.io/repos/github/FGasper/p5-Promise-XS/badge.svg?branch=master' alt='Coverage Status' /></a>

=end html

This module exposes a Promise interface with its major parts
implemented in XS for speed. It is a fork and refactor of
L<AnyEvent::XSPromises>. That module’s interface, a “bare-bones”
subset of that from L<Promises>, is retained.

=head1 STATUS

This module is stable, well-tested, and suitable for production use.

=head1 DIFFERENCES FROM ECMASCRIPT PROMISES

This library is built for compatibility with pre-existing Perl promise
libraries. It thus exhibits some salient differences from how
ECMAScript promises work:

=over

=item * Neither the C<resolve()> method of deferred objects
nor the C<resolved()> convenience function define behavior when given
a promise object.

=item * The C<all()> and C<race()> functions accept a list of promises,
not a “scalar-array-thing” (ECMAScript “arrays” being what in Perl we
call “array references”). So whereas in ECMAScript you do:

    Promise.all( [ promise1, promise2 ] );

… in this library it’s:

    Promise::XS::all( $promise1, $promise2 );

=item * Promise resolutions and rejections may contain multiple values.
(But see L</AVOID MULTIPLES> below.)

=back

See L<Promise::ES6> for an interface that imitates ECMAScript promises
more closely.

=head1 AVOID MULTIPLES

For compatibility with preexisting Perl promise libraries, Promise::XS
allows a promise to resolve or reject with multiple values. This behavior,
while eminently “perlish”, allows for some weird cases where the relevant
standards don’t apply: for example, what happens if multiple promises are
returned from a promise callback? Or even just a single promise plus extra
returns?

Promise::XS tries to help you catch such cases by throwing a warning
if multiple return values from a callback contain a promise as the
first member. For best results, though—and consistency with promise
implementations outside Perl—resolve/reject all promises with I<single>
values.

=head1 DIFFERENCES FROM L<Promises> ET AL.

=head2 Empty or uninitialized rejection values

Perl helpfully warns (under the C<warnings> pragma, anyhow) when you
C<die(undef)> since an uninitialized value isn’t useful as an error report
and likely indicates a problem in the error-handling logic.

Promise rejections fulfill the same role in asynchronous code that
exceptions do in synchronous code. Thus, Promise::XS mimics Perl’s behavior:
if a rejection value list lacks a defined value, a warning is thrown. This
can happen if the value list is either empty or contains exclusively
uninitialized values.

=head2 C<finally()>

This module implements ECMAScript’s C<finally()> interface, which differs
from that in some other Perl promise implementations.

Given the following …

    my $new = $p->finally( $callback );

=over

=item * C<$callback> receives I<no> arguments.

=item * If C<$callback> returns anything but a single, rejected promise,
C<$new> has the same status as C<$p>.

=item * If C<$callback> throws, or if it returns a single, rejected promise,
C<$new> is rejected with the relevant value(s).

=back

=head1 B<EXPERIMENTAL:> ASYNC/AWAIT SUPPORT

This module is L<Promise::AsyncAwait>-compatible.
Once you load that module you can do nifty stuff like:

    use Promise::AsyncAwait;

    async sub do_stuff {
        return 1 + await fetch_number_p();
    }

    my $one_plus_number = await do_stuff();

… which roughly equates to:

    sub do_stuff {
        return fetch_number_p()->then( sub { 1 + $foo } );
    }

    do_stuff->then( sub {
        $one_plus_number = shift;
    } );

=head1 EVENT LOOPS

By default this library uses no event loop. This is a generally usable
configuration; however, it’ll be a bit different from how promises usually
work in evented contexts (e.g., JavaScript) because callbacks will execute
immediately rather than at the end of the event loop as the Promises/A+
specification requires. Following this pattern facilitates use of recursive
promises without exceeding call stack limits.

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

=item * C<all()> and C<race()> should ideally be implemented in XS.

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

require XSLoader;
XSLoader::load('Promise::XS', $VERSION);

sub use_event {
    my ($name, @args) = @_;

    if (my $cr = DEFERRAL_CR()->{$name}) {
        $cr->(@args);
    }
    else {
        die( __PACKAGE__ . ": unknown event engine: $name" );
    }
}

# called from XS
sub _convert_to_our_promise {
    my $thenable = shift;
    my $deferred= Promise::XS::Deferred::create();
    my $called;

    local $@;
    eval {
        $thenable->then(sub {
            return if $called++;
            $deferred->resolve(@_);
        }, sub {
            return if $called++;
            $deferred->reject(@_);
        });
        1;
    } or do {
        my $error= $@;
        if (!$called++) {
            $deferred->reject($error);
        }
    };

    # This promise is purely internal, so let’s not warn
    # when its rejection is unhandled.
    $deferred->clear_unhandled_rejection();

    return $deferred->promise;
}

#----------------------------------------------------------------------
# Aggregator functions
sub all {
    return Promise::XS::Promise->all(@_);
}

sub race {
    return Promise::XS::Promise->race(@_);
}

# Compatibility with other promise interfaces.
*collect = *all;

#----------------------------------------------------------------------

=head1 SEE ALSO

Besides L<AnyEvent::XSPromises> and L<Promises>, you may like L<Promise::ES6>,
which mimics L<ECMAScript’s “Promise” class|https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Promise> as much as possible.
It can even
(experimentally) use this module as a backend, which helps but is still
significantly slower than using this module directly.

=cut

1;
