# NAME

Net::Curl::Promiser - A Promise interface for [Net::Curl::Multi](https://metacpan.org/pod/Net::Curl::Multi)

# DESCRIPTION

This module wraps [Net::Curl::Multi](https://metacpan.org/pod/Net::Curl::Multi) to facilitate asynchronous
requests with Promise objects. Net::Curl::Promiser interfaces with
Net::Curl::Multi’s polling callbacks to simplify your task of coordinating
multiple concurrent requests.

[Net::Curl::Promiser](https://metacpan.org/pod/Net::Curl::Promiser) itself is a base class; you’ll need to provide
an interface to whatever event loop you use. See ["SUBCLASS INTERFACE"](#subclass-interface)
below.

This distribution provides the following as both demonstrations and
portable implementations:

- [Net::Curl::Promiser::Mojo](https://metacpan.org/pod/Net::Curl::Promiser::Mojo) (for [Mojolicious](https://metacpan.org/pod/Mojolicious))
- [Net::Curl::Promiser::AnyEvent](https://metacpan.org/pod/Net::Curl::Promiser::AnyEvent) (for [AnyEvent](https://metacpan.org/pod/AnyEvent))
- [Net::Curl::Promiser::IOAsync](https://metacpan.org/pod/Net::Curl::Promiser::IOAsync) (for [IO::Async](https://metacpan.org/pod/IO::Async))
- [Net::Curl::Promiser::Select](https://metacpan.org/pod/Net::Curl::Promiser::Select) (for manually-written
`select()` loops)

(See the distribution’s `/examples` directory for one based on Linux’s
`epoll`.)

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

# GENERAL-USE METHODS

The following are of interest to any code that uses this module:

## _CLASS_->new(@ARGS)

Instantiates this class. This creates an underlying
[Net::Curl::Multi](https://metacpan.org/pod/Net::Curl::Multi) object and calls the subclass’s `_INIT()`
method at the end, passing a reference to @ARGS.

(Most end classes of this module do not require @ARGS.)

## promise($EASY) = _OBJ_->add\_handle( $EASY )

A passthrough to the underlying [Net::Curl::Multi](https://metacpan.org/pod/Net::Curl::Multi) object’s
method of the same name, but the return is given as a Promise object.

That promise resolves with the passed-in $EASY object.
It rejects with either the error given to `fail_handle()` or the
error that [Net::Curl::Multi](https://metacpan.org/pod/Net::Curl::Multi) object’s `info_read()` returns.

**IMPORTANT:** As with libcurl itself, HTTP-level failures
(e.g., 4xx and 5xx responses) are **NOT** considered failures at this level.

## $obj = _OBJ_->fail\_handle( $EASY, $REASON )

Prematurely fails $EASY. The given $REASON will be the associated
Promise object’s rejection value.

## $obj = _OBJ_->setopt( … )

A passthrough to the underlying [Net::Curl::Multi](https://metacpan.org/pod/Net::Curl::Multi) object’s
method of the same name. Returns _OBJ_ to facilitate chaining.

`CURLMOPT_SOCKETFUNCTION` or `CURLMOPT_SOCKETDATA` are set internally;
any attempt to set them via this interface will prompt an error.

## $obj = _OBJ_->handles( … )

A passthrough to the underlying [Net::Curl::Multi](https://metacpan.org/pod/Net::Curl::Multi) object’s
method of the same name.

# EVENT LOOP METHODS

The following are needed only when you’re managing an event loop directly:

## $num = _OBJ_->get\_timeout()

Returns the underlying [Net::Curl::Multi](https://metacpan.org/pod/Net::Curl::Multi) object’s `timeout()`
value, with a suitable (positive) default substituted if that value is
less than 0.

(NB: This value is in _milliseconds_.)

This may not suit your needs; if you wish/need, you can handle timeouts
via the [CURLMOPT\_TIMERFUNCTION](https://metacpan.org/pod/Net::Curl::Multi#CURLMOPT_TIMERFUNCTION)
callback instead.

This should only be called (if it’s called at all) from event loop logic.

## $obj = _OBJ_->process( @ARGS )

Tell the underlying [Net::Curl::Multi](https://metacpan.org/pod/Net::Curl::Multi) object which socket events have
happened.

If, in fact, no events have happened, then this calls
`socket_action(CURL_SOCKET_TIMEOUT)` on the
[Net::Curl::Multi](https://metacpan.org/pod/Net::Curl::Multi) object (similar to `time_out()`).

Finally, this reaps whatever pending HTTP responses may be ready and
resolves or rejects the corresponding Promise objects.

This should only be called from event loop logic.

Returns _OBJ_.

## $is\_active = _OBJ_->time\_out();

Tell the underlying [Net::Curl::Multi](https://metacpan.org/pod/Net::Curl::Multi) object that a timeout happened,
and reap whatever pending HTTP responses may be ready.

Calls `socket_action(CURL_SOCKET_TIMEOUT)` on the
underlying [Net::Curl::Multi](https://metacpan.org/pod/Net::Curl::Multi) object. The return is the same as
that operation returns.

Since `process()` can also do the work of this function, a call to this
function is just an optimization.

This should only be called from event loop logic.

# SUBCLASS INTERFACE

**NOTE:** The distribution provides several ready-built end classes;
unless you’re managing your own event loop, you don’t need to concern
yourself with this.

To use Net::Curl::Promiser, you’ll need a subclass that defines
the following methods:

- `_INIT(\@ARGS)`: Called at the end of `new()`. Receives a reference
to the arguments given to `new()`.
- `_SET_POLL_IN($FD)`: Tells the event loop that the given file
descriptor is ready to read.
- `_SET_POLL_OUT($FD)`: Like `_SET_POLL_IN()` but for a write event.
- `_SET_POLL_INOUT($FD)`: Like `_SET_POLL_IN()` but registers
a read and write event simultaneously.
- `_STOP_POLL($FD)`: Tells the event loop that the given file
descriptor is finished.
- `_GET_FD_ACTION(\@ARGS)`: Receives a reference to the arguments
given to `process()` and returns a reference to a hash of
( $fd => $event\_mask ). $event\_mask is the sum of
`Net::Curl::Multi::CURL_CSELECT_IN()` and/or
`Net::Curl::Multi::CURL_CSELECT_OUT()`, depending on which events
are available.

**IMPORTANT:** Your event loop **MUST** **NOT** close file descriptors. This means
that, if you create Perl filehandles from the file descriptors, you need to
prevent Perl from closing the underlying file descriptors.

# EXAMPLES

See the distribution’s `/examples` directory.

# SEE ALSO

If you use [AnyEvent](https://metacpan.org/pod/AnyEvent), then [AnyEvent::XSPromises](https://metacpan.org/pod/AnyEvent::XSPromises) with
[AnyEvent::YACurl](https://metacpan.org/pod/AnyEvent::YACurl) may be a nicer fit for you.

# REPOSITORY

[https://github.com/FGasper/p5-Net-Curl-Promiser](https://github.com/FGasper/p5-Net-Curl-Promiser)

# LICENSE & COPYRIGHT

Copyright 2019-2020 Gasper Software Consulting.

This library is licensed under the same terms as Perl itself.
