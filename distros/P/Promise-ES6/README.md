# NAME

Promise::ES6 - ES6-style promises in Perl

# SYNOPSIS

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

# DESCRIPTION

This module provides a Perl implementation of [promises](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Using_promises), a useful pattern
for coordinating asynchronous tasks.

Unlike most other promise implementations on CPAN, this module
mimics ECMAScript 6’s [Promise](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Promise)
interface. As the SYNOPSIS above shows, you can thus use patterns from
JavaScript in Perl with only minimal changes needed to accommodate language
syntax.

This is a rewrite of an earlier module, [Promise::Tiny](https://metacpan.org/pod/Promise::Tiny). It fixes several
bugs and superfluous dependencies in the original.

# INTERFACE NOTES

- Promise resolutions and rejections accept exactly one argument,
not a list.
- Unhandled rejections are reported via `warn()`. (See below
for details.)
- The Promises/A+ test suite avoids testing the case where an “executor”
function’s resolve callback itself receives another promise, e.g.:

        my $p = Promise::ES6->new( sub ($res) {
            $res->( Promise::ES6->resolve(123) );
        } );

    What will $p’s resolution value be? 123, or the promise that wraps it?

    This module favors conformity with the ES6 standard, which
    [indicates intent](https://www.ecma-international.org/ecma-262/6.0/#sec-promise-executor) that $p’s resolution value be 123.

# COMPATIBILITY

Right now this doesn’t try for interoperability with other promise
classes. If that’s something you want, make a feature request.

See [Promise::ES6::Future](https://metacpan.org/pod/Promise::ES6::Future) if you need to interact with [Future](https://metacpan.org/pod/Future).

# UNHANDLED REJECTIONS

As of version 0.05, unhandled rejections prompt a warning _only_ if one
of the following is true:

- 1) The unhandled rejection happens outside of the constructor.
- 2) The unhandled rejection happens via an uncaught exception
(even within the constructor).

# SYNCHRONOUS OPERATION

In JavaScript, the following …

    Promise.resolve().then( () => console.log(1) );
    console.log(2);

… will log `2` then `1` because JavaScript’s `then()` defers execution
of its callbacks until the end of the current iteration through JavaScript’s
event loop.

Perl, of course, has no built-in event loop. This module’s `then()` method,
thus, when called on a promise that is already
“settled” (i.e., not pending), will run the appropriate callback
_immediately_. That means that this:

    Promise::ES6->resolve(0)->then( sub { print 1 } );
    print 2;

… will print `12` instead of `21`.

This is an intentional divergence from
[the Promises/A+ specification](https://promisesaplus.com/#point-34).
A key advantage of this design is that Promise::ES6 instances can abstract
over whether a given function works synchronously or asynchronously.

If you want a Promises/A+-compliant implementation, look at
[Promise::ES6::IOAsync](https://metacpan.org/pod/Promise::ES6::IOAsync), [Promise::ES6::Mojo](https://metacpan.org/pod/Promise::ES6::Mojo),
[Promise::ES6::AnyEvent](https://metacpan.org/pod/Promise::ES6::AnyEvent), or one of the alternatives
that that module’s documentation suggests.

# CANCELLATION

Promises have never provided a standardized solution for cancellation—i.e.,
aborting an in-process operation. So, if you need this functionality, you’ll
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
a canceled query in the “pending” state or to resolve or reject it.
All things being equal, I feel the first approach is the most intuitive.

# MEMORY LEAKS

It’s easy to create inadvertent memory leaks using promises in Perl.
Here are a few “pointers” (heh) to bear in mind:

- As of version 0.07, any Promise::ES6 instances that are created while
`$Promise::ES6::DETECT_MEMORY_LEAKS` is set to a truthy value are
“leak-detect-enabled”, which means that if they survive until their original
process’s global destruction, a warning is triggered.
- If your application needs recursive promises (e.g., to poll
iteratively for completion of a task), the `current_sub` feature (i.e.,
`__SUB__`) may help you avoid memory leaks. In Perl versions that don’t
support this feature you can imitate it thus:

        use constant _has_current_sub => $^V ge v5.16.0;

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

# TODO

Currently rejections will defer until promises are resolved. This makes
no real sense and ought to change. Do not build anything that depends on
this behavior.

# SEE ALSO

If you’re not sure of what promises are, there are several good
introductions to the topic. You might start with
[this one](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Using_promises).

Promise::ES6 serves much the same role as [Future](https://metacpan.org/pod/Future) but exposes
a standard, minimal, cross-language API rather than a proprietary (large) one.

CPAN contains a number of other modules that implement promises. I think
mine is the nicest :), but YMMV. Enjoy!

# LICENSE & COPYRIGHT

Copyright 2019 Gasper Software Consulting.

This library is licensed under the same terms as Perl itself.
