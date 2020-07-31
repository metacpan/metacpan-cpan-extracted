# NAME

Net::Curl::Promiser - Asynchronous [libcurl](https://curl.haxx.se/libcurl/), the easy way!

# DESCRIPTION

[Net::Curl::Multi](https://metacpan.org/pod/Net::Curl::Multi) is powerful but tricky to use: polling, callbacks,
timers, etc. This module does all of that for you and puts a Promise
interface on top of it, so asynchronous I/O becomes almost as simple as
synchronous I/O.

[Net::Curl::Promiser](https://metacpan.org/pod/Net::Curl::Promiser) itself is a base class; you’ll need to use
a subclass that works with your chosen event interface.

This distribution provides the following usable subclasses:

- [Net::Curl::Promiser::Mojo](https://metacpan.org/pod/Net::Curl::Promiser::Mojo) (for [Mojolicious](https://metacpan.org/pod/Mojolicious))
- [Net::Curl::Promiser::AnyEvent](https://metacpan.org/pod/Net::Curl::Promiser::AnyEvent) (for [AnyEvent](https://metacpan.org/pod/AnyEvent))
- [Net::Curl::Promiser::IOAsync](https://metacpan.org/pod/Net::Curl::Promiser::IOAsync) (for [IO::Async](https://metacpan.org/pod/IO::Async))
- [Net::Curl::Promiser::Select](https://metacpan.org/pod/Net::Curl::Promiser::Select) (for manually-written
`select()` loops)

If the event interface you want to use isn’t compatible with one of the
above, you’ll need to create your own [Net::Curl::Promiser](https://metacpan.org/pod/Net::Curl::Promiser) subclass.
This is undocumented but pretty simple; have a look at the ones above as
well as another based on Linux’s [epoll(7)](http://man.he.net/man7/epoll) in the distribution’s
`/examples`.

# MEMORY LEAK DETECTION

This module will, by default, `warn()` if its objects are `DESTROY()`ed
during Perl’s global destruction phase. To suppress this behavior, set
`$Net::Curl::Promiser::IGNORE_MEMORY_LEAKS` to a truthy value.

# PROMISE IMPLEMENTATION

This class’s default Promise implementation is [Promise::ES6](https://metacpan.org/pod/Promise::ES6).
You can use a different one by overriding the `PROMISE_CLASS()` method in
a subclass, as long as the substitute class’s `new()` method works the
same way as Promise::ES6’s (which itself follows the ECMAScript standard).

(NB: [Net::Curl::Promiser::Mojo](https://metacpan.org/pod/Net::Curl::Promiser::Mojo) uses [Mojo::Promise](https://metacpan.org/pod/Mojo::Promise) instead of
Promise::ES6.)

## **Experimental** [Promise::XS](https://metacpan.org/pod/Promise::XS) support

Try out experimental Promise::XS support by running with
`NET_CURL_PROMISER_PROMISE_ENGINE=Promise::XS` in your environment.
This will override `PROMISE_CLASS()`.

# DESIGN NOTES

Internally each instance of this class uses an instance of
[Net::Curl::Multi](https://metacpan.org/pod/Net::Curl::Multi) and an instance of [Net::Curl::Promiser::Backend](https://metacpan.org/pod/Net::Curl::Promiser::Backend).
(The latter, in turn, is subclassed to provide logic specific to
each event interface.) These are kept separate to avoid circular references.

# GENERAL-USE METHODS

The following are of interest to any code that uses this module:

## _CLASS_->new(@ARGS)

Instantiates this class, including creation of an underlying
[Net::Curl::Multi](https://metacpan.org/pod/Net::Curl::Multi) object.

## promise($EASY) = _OBJ_->add\_handle( $EASY )

A passthrough to the underlying [Net::Curl::Multi](https://metacpan.org/pod/Net::Curl::Multi) object’s
method of the same name, but the return is given as a Promise object.

That promise resolves with the passed-in $EASY object.
It rejects with either the error given to `fail_handle()` or the
error that [Net::Curl::Multi](https://metacpan.org/pod/Net::Curl::Multi) object’s `info_read()` returns.

**IMPORTANT:** As with libcurl itself, HTTP-level failures
(e.g., 4xx and 5xx responses) are **NOT** considered failures at this level.

## $obj = _OBJ_->cancel\_handle( $EASY )

Prematurely cancels $EASY. The associated promise will be abandoned
in pending state, never to resolve nor reject.

Returns _OBJ_.

## $obj = _OBJ_->fail\_handle( $EASY, $REASON )

Like `cancel_handle()` but rejects $EASY’s associated promise
with the given $REASON.

Returns _OBJ_.

## $obj = _OBJ_->setopt( … )

A passthrough to the underlying [Net::Curl::Multi](https://metacpan.org/pod/Net::Curl::Multi) object’s
method of the same name. Returns _OBJ_ to facilitate chaining.

This class requires control of certain [Net::Curl::Multi](https://metacpan.org/pod/Net::Curl::Multi) options;
if you attempt to set one of these here you’ll get an exception.

## $obj = _OBJ_->handles( … )

A passthrough to the underlying [Net::Curl::Multi](https://metacpan.org/pod/Net::Curl::Multi) object’s
method of the same name.

# EXAMPLES

See the distribution’s `/examples` directory.

# SEE ALSO

[Net::Curl::Simple](https://metacpan.org/pod/Net::Curl::Simple) implements a similar idea to this module but
doesn’t return promises. It has a more extensive interface that provides
a more “perlish” experience than [Net::Curl::Easy](https://metacpan.org/pod/Net::Curl::Easy).

If you use [AnyEvent](https://metacpan.org/pod/AnyEvent), then [AnyEvent::XSPromises](https://metacpan.org/pod/AnyEvent::XSPromises) with
[AnyEvent::YACurl](https://metacpan.org/pod/AnyEvent::YACurl) may be a nicer fit for you.

# REPOSITORY

[https://github.com/FGasper/p5-Net-Curl-Promiser](https://github.com/FGasper/p5-Net-Curl-Promiser)

# LICENSE & COPYRIGHT

Copyright 2019-2020 Gasper Software Consulting.

This library is licensed under the same terms as Perl itself.
