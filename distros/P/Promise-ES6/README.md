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

This is a rewrite of [Promise::Tiny](https://metacpan.org/pod/Promise::Tiny) that implements fixes for
certain bugs that proved hard to fix in the original code. This module
also removes superfluous dependencies on [AnyEvent](https://metacpan.org/pod/AnyEvent) and [Scalar::Util](https://metacpan.org/pod/Scalar::Util).

The interface is the same, except:

- Promise resolutions and rejections accept exactly one argument,
not a list. (This accords with the standard.)
- A `finally()` method is defined.

# COMPATIBILITY

Right now this doesn’t try for interoperability with other promise
classes. If that’s something you want, make a feature request.

# SEE ALSO

If you’re not sure of what promises are, there are several good
introductions to the topic. You might start with
[this one](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Using_promises).
