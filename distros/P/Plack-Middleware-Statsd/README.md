# NAME

Plack::Middleware::Statsd - send statistics to statsd

# VERSION

version v0.3.0

# SYNOPSIS

```perl
use Plack::Builder;
use Net::Statsd::Client;

builder {

  enable "Statsd",
    client      => Net::Statsd::Client->new( ... );

  ...

  sub {
    my ($env) = @_;

    # Send statistics via other middleware

    if (my $stats = $env->{'psgix.monitor.statsd'}) {

      $stats->increment('myapp.wibble');

    }


  };

};
```

# DESCRIPTION

This middleware gathers metrics from the application send sends them
to a statsd server.

# ATTRIBUTES

## client

This is a statsd client, such as an [Net::Statsd::Client](https://metacpan.org/pod/Net::Statsd::Client) object.

If one is omitted, then it will default to one defined in the
environment hash at `psgix.monitor.statsd`.

`psgix.monitor.statsd` will be set to the current client if it is not
set.

The only restriction on the client is that it has the same API as
[Net::Statsd::Client](https://metacpan.org/pod/Net::Statsd::Client) or similar modules, by supporting the following
methods:

- `increment`
- `timing_ms` or `timing`
- `set_add`

Other statsd client modules may be used via a wrapper class.

# METRICS

The following metrics are logged:

- `psgi.request.method.$METHOD`

    This increments a counter for the request method.

- `psgi.request.remote_addr`

    The remote address is added to the set.

- `psgi.request.content-length`

    The content-length of the request, if it is specified in the header.

    This is treated as a timing rather than a counter, so that statistics
    can be saved.

- `psgi.request.content-type.$TYPE.$SUBTYPE`

    A counter for the content type of request bodies is incremented, e.g.
    `psgi.request.content-type.application.x-www-form-urlencoded`.

    Any modifiers in the type, e.g. `charset`, will be ignored.

- `psgi.response.content-length`

    The content-length of the response, if it is specified in the header.

    This is treated as a timing rather than a counter, so that statistics
    can be saved.

- `psgi.response.content-type.$TYPE.$SUBTYPE`

    A counter for the content type is incremented, e.g. for a JPEG image,
    the counter `psgi.response.content-type.image.jpeg` is incremented.

    Any modifiers in the type, e.g. `charset`, will be ignored.

- `psgi.response.status.$CODE`

    A counter for the HTTP status code is incremented.

- `psgi.response.time`

    The response time, in ms (rounded up using `ceil`).

- `psgi.response.x-sendfile`

    This counter is incremented when the `X-Sendfile` header is added.

    The header is configured using the `plack.xsendfile.type` environment
    key, ortherwise the `HTTP_X_SENDFILE_TYPE` environment variable.

    See [Plack::Middleware::XSendfile](https://metacpan.org/pod/Plack::Middleware::XSendfile) for more information.

- `psgix.harakiri`

    This counter is incremented when the harakiri flag is set.

If you want to rename these, then you will need to use a wrapper
class for the ["client"](#client).

# EXAMPLES

## Using from Catalyst

You can access the configured statsd client from [Catalyst](https://metacpan.org/pod/Catalyst):

```perl
sub finalize {
  my $c = shift;

  if (my $statsd = $c->req->env->{'psgix.monitor.statsd'}) {
    ...


  }

  $c->next::method(@_);
}
```

# SEE ALSO

[Net::Statsd::Client](https://metacpan.org/pod/Net::Statsd::Client)

[Net::Statsd::Tiny](https://metacpan.org/pod/Net::Statsd::Tiny)

[PSGI](https://metacpan.org/pod/PSGI)

# SOURCE

The development version is on github at [https://github.com/robrwo/Plack-Middleware-Statsd](https://github.com/robrwo/Plack-Middleware-Statsd)
and may be cloned from [git://github.com/robrwo/Plack-Middleware-Statsd.git](git://github.com/robrwo/Plack-Middleware-Statsd.git)

# BUGS

Please report any bugs or feature requests on the bugtracker website
[https://github.com/robrwo/Plack-Middleware-Statsd/issues](https://github.com/robrwo/Plack-Middleware-Statsd/issues)

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

# AUTHOR

Robert Rothenberg <rrwo@cpan.org>

The initial development of this module was sponsored by Science Photo
Library [https://www.sciencephoto.com](https://www.sciencephoto.com).

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

```
The Artistic License 2.0 (GPL Compatible)
```
