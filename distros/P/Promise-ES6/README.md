# NAME

Promise::ES6 - ES6-style promises in Perl

# SYNOPSIS

    use Promise::ES6;

    # OPTIONAL. And see below for other options.
    Promise::ES6::use_event('IO::Async', $loop);

    my $promise = Promise::ES6->new( sub {
        my ($resolve_cr, $reject_cr) = @_;

        # ..
    } );

    my $promise2 = $promise->then( sub { .. }, sub { .. } );

    my $promise3 = $promise->catch( sub { .. } );

    my $promise4 = $promise->finally( sub { .. } );

    my $resolved = Promise::ES6->resolve(5);
    my $rejected = Promise::ES6->reject('nono');

    my $all_promise = Promise::ES6->all( \@promises );

    my $race_promise = Promise::ES6->race( \@promises );

    my $allsettled_promise = Promise::ES6->allSettled( \@promises );

# DESCRIPTION

<div>
    <a href='https://coveralls.io/github/FGasper/p5-Promise-ES6?branch=master'><img src='https://coveralls.io/repos/github/FGasper/p5-Promise-ES6/badge.svg?branch=master' alt='Coverage Status' /></a>
</div>

This module provides a Perl implementation of [promises](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Using_promises), a useful pattern
for coordinating asynchronous tasks.

Unlike most other promise implementations on CPAN, this module
mimics ECMAScript 6’s [Promise](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Promise)
interface. As the SYNOPSIS above shows, you can thus use patterns from
JavaScript in Perl with only minimal changes needed to accommodate language
syntax.

This is a rewrite of an earlier module, [Promise::Tiny](https://metacpan.org/pod/Promise::Tiny). It fixes several
bugs and superfluous dependencies in the original.

# STATUS

This module is in use in production and, backed by a pretty extensive
set of regression tests, may be considered stable.

# INTERFACE NOTES

- Promise resolutions and rejections accept exactly one argument,
not a list.
- Unhandled rejections are reported via `warn()`. (See below
for details.)
- Undefined or empty rejection values trigger a warning.
This provides the same value as Perl’s own warning on `die(undef)`.
- The [Promises/A+ test suite](https://github.com/promises-aplus/promises-tests) avoids testing the case where an “executor”
function’s resolve callback itself receives another promise, e.g.:

        my $p = Promise::ES6->new( sub ($res) {
            $res->( Promise::ES6->resolve(123) );
        } );

    What will $p’s resolution value be? 123, or the promise that wraps it?

    This module favors conformity with the ES6 standard, which
    [indicates intent](https://www.ecma-international.org/ecma-262/6.0/#sec-promise-executor) that $p’s resolution value be 123.

# COMPATIBILITY

This module considers any object that has a `then()` method to be a promise.
Note that, in the case of [Future](https://metacpan.org/pod/Future), this will yield a “false-positive”, as
Future is not compatible with promises.

(See [Promise::ES6::Future](https://metacpan.org/pod/Promise::ES6::Future) for more tools to interact with [Future](https://metacpan.org/pod/Future).)

# **EXPERIMENTAL:** ASYNC/AWAIT SUPPORT

This module implements [Future::AsyncAwait::Awaitable](https://metacpan.org/pod/Future::AsyncAwait::Awaitable). This lets you do
nifty stuff like:

    use Future::AsyncAwait;

    async sub do_stuff {
        my $foo = await fetch_number_p();

        # NB: The real return is a promise that provides this value:
        return 1 + $foo;
    }

    my $one_plus_number = await do_stuff();

… which roughly equates to:

    sub do_stuff {
        return fetch_number_p()->then( sub { 1 + $foo } );
    }

    do_stuff->then( sub {
        $one_plus_number = shift;
    } );

# UNHANDLED REJECTIONS

This module’s handling of unhandled rejections has changed over time.
The current behavior is: if any rejected promise is DESTROYed without first
having received a catch callback, a warning is thrown.

# SYNCHRONOUS VS. ASYNCHRONOUS OPERATION

In JavaScript, the following …

    Promise.resolve().then( () => console.log(1) );
    console.log(2);

… will log `2` then `1` because JavaScript’s `then()` defers execution
of its callbacks until between iterations through JavaScript’s event loop.

Perl, of course, has no built-in event loop. This module accommodates that by
implementing **synchronous** promises by default rather than asynchronous ones.
This means that all promise callbacks run _immediately_ rather than between
iterations of an event loop. As a result, this:

    Promise::ES6->resolve(0)->then( sub { print 1 } );
    print 2;

… will print `12` instead of `21`.

One effect of this is that Promise::ES6, in its default configuration, is
agnostic regarding event loop interfaces: no special configuration is needed
for any specific event loop. In fact, you don’t even _need_ an event loop
at all, which might be useful for abstracting over whether a given
function works synchronously or asynchronously.

The disadvantage of synchronous promises—besides not being _quite_ the same
promises that we expect from JS—is that recursive promises can exceed
call stack limits. For example, the following (admittedly contrived) code:

    my @nums = 1 .. 1000;

    sub _remove {
        if (@nums) {
            Promise::ES6->resolve(shift @nums)->then(\&_remove);
        }
    }

    _remove();

… will eventually fail because it will reach Perl’s call stack size limit.

That problem probably won’t affect most applications. The best way to
avoid it, though, is to use asynchronous promises, à la JavaScript.

To do that, first choose one of the following event interfaces:

- [IO::Async](https://metacpan.org/pod/IO::Async)
- [AnyEvent](https://metacpan.org/pod/AnyEvent)
- [Mojo::IOLoop](https://metacpan.org/pod/Mojo::IOLoop) (part of [Mojolicious](https://metacpan.org/pod/Mojolicious))

Then, before you start creating promises, do this:

    Promise::ES6::use_event('AnyEvent');

… or:

    Promise::ES6::use_event('Mojo::IOLoop');

… or:

    Promise::ES6::use_event('IO::Async', $loop);

That’s it! Promise::ES6 instances will now work asynchronously rather than
synchronously.

Note that this changes Promise::ES6 _globally_. In IO::Async’s case, it
won’t increase the passed-in [IO::Async::Loop](https://metacpan.org/pod/IO::Async::Loop) instance’s reference count,
but if that loop object goes away, Promise::ES6 won’t work until you call
`use_event()` again.

**IMPORTANT:** For the best long-term scalability and flexibility,
your code should work with either synchronous or asynchronous promises.

# CANCELLATION

Promises have never provided a standardized solution for cancellation—i.e.,
aborting an in-process operation. If you need this functionality, then, you’ll
have to implement it yourself. Two ways of doing this are:

- Subclass Promise::ES6 and provide cancellation logic in that
subclass. See [DNS::Unbound::AsyncQuery](https://metacpan.org/pod/DNS::Unbound::AsyncQuery)’s implementation for an
example of this.
- Implement the cancellation on a request object that your
“promise-creator” also consumes. This is probably the more straightforward
approach but requires that there
be some object or ID besides the promise that uniquely identifies the action
to be canceled. See [Net::Curl::Promiser](https://metacpan.org/pod/Net::Curl::Promiser) for an example of this approach.

You’ll need to decide if it makes more sense for your application to leave
a canceled query in the “pending” state or to “settle” (i.e., resolve or
reject) it. All things being equal, I feel the first approach is the most
intuitive, while the latter ends up being “cleaner”.

Of note: [Future](https://metacpan.org/pod/Future) implements native cancellation.

# MEMORY LEAKS

It’s easy to create inadvertent memory leaks using promises in Perl.
Here are a few “pointers” (heh) to bear in mind:

- Any Promise::ES6 instances that are created while
`$Promise::ES6::DETECT_MEMORY_LEAKS` is set to a truthy value are
“leak-detect-enabled”, which means that if they survive until their original
process’s global destruction, a warning is triggered. You should normally
enable this flag in a development environment.
- If your application needs recursive promises (e.g., to poll
iteratively for completion of a task), the `current_sub` feature (i.e.,
`__SUB__`) may help you avoid memory leaks. In Perl versions that don’t
support this feature (i.e., anything pre-5.16) you can imitate it thus:

        use constant _has_current_sub => eval "use feature 'current_sub'";

        use if _has_current_sub(), feature => 'current_sub';

        my $cb;
        $cb = sub {
            my $current_sub = do {
                no strict 'subs';
                _has_current_sub() ? __SUB__ : eval '$cb';
            };
        }

    Of course, it’s better if you can avoid doing that. :)

- Garbage collection before Perl 5.18 seems to have been buggy.
If you work with such versions and end up chasing leaks,
try manually deleting as many references/closures as possible. See
`t/race_success.t` for a notated example.

    You may also (counterintuitively, IMO) find that this:

        my ($resolve, $reject);

        my $promise = Promise::ES6->new( sub { ($resolve, $reject) = @_ } );

        # … etc.

    … works better than:

        my $promise = Promise::ES6->new( sub {
            my ($resolve, $reject) = @_;

            # … etc.
        } );

# SEE ALSO

If you’re not sure of what promises are, there are several good
introductions to the topic. You might start with
[this one](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Using_promises).

[Promise::XS](https://metacpan.org/pod/Promise::XS) is my refactor of [AnyEvent::XSPromises](https://metacpan.org/pod/AnyEvent::XSPromises). It’s a lot like
this library but implemented mostly in XS for speed.

[Promises](https://metacpan.org/pod/Promises) is another pure-Perl Promise implementation.

[Future](https://metacpan.org/pod/Future) fills a role similar to that of promises. Much of the IO::Async
ecosystem assumes (or strongly encourages) its use.

CPAN contains a number of other modules that implement promises. I think
mine are the nicest :), but YMMV. Enjoy!

# LICENSE & COPYRIGHT

Copyright 2019-2021 Gasper Software Consulting.

This library is licensed under the same terms as Perl itself.
