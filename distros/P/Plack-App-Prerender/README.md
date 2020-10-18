# NAME

Plack::App::Prerender - a simple prerendering proxy for Plack

# VERSION

version v0.2.0

# SYNOPSIS

```perl
use CHI;
use Log::Log4perl qw/ :easy /;
use Plack::App::Prerender;

my $cache = CHI->new(
    driver   => 'File',
    root_dir => '/tmp/test-chi',
);

Log::Log4perl->easy_init($ERROR);

my $app = Plack::App::Prerender->new(
    rewrite => "http://www.example.com",
    cache   => $cache,
    wait    => 10,
)->to_app;
```

# DESCRIPTION

This is a PSGI application that acts as a simple prerendering proxy
for websites using Chrone.

This only supports GET requests, as this is intended as a proxy for
search engines that do not support AJAX-generated content.

# ATTRIBUTES

## mech

A [WWW::Mechanize::Chrome](https://metacpan.org/pod/WWW::Mechanize::Chrome) object. If omitted, a headless instance of
Chrome will be launched.

If you want to specify alternative options, you chould create your own
instance of WWW::Mechanize::Chrome and pass it to the constructor.

## rewrite

This can either be a base URL prefix string, or a code reference that
takes the PSGI `REQUEST_URI` and environment hash as arguments, and
returns a full URL to pass to ["mech"](#mech).

If the code reference returns `undef`, then the request will abort
with an HTTP 400.

If the code reference returns an array reference, then it assumes the
request is a Plack response and simply returns it.

This can be used for simple request validation.  For example,

```perl
use Robots::Validate v0.2.0;

sub validator {
  my ($path, $env) = @_;

  state $rv = Robots::Validate->new();

  unless ( $rv->validate( $env ) ) {
      if (my $logger = $env->{'psgix.logger'}) {
         $logger->( { level => 'warn', message => 'not a bot!' } );
      }
      return [ 403, [], [] ];
  }

  ...
}
```

## cache

This is the cache handling interface. See [CHI](https://metacpan.org/pod/CHI).

If no cache is specified (v0.2.0), then the result will not be cached.

## max\_age

This is the maximum time (in seconds) to cache content.  If the page
returns a `Cache-Control` header with a `max-age`, then that will be
used instead.

## request

This is a hash reference (since v0.2.0) of request headers to pass
through the proxy.  The keys are the request header fieldss, and the
values are the headers that will be passed to the ["rewrite"](#rewrite) URL.

Values of `1` will be a synonym for the same header, and false values
will mean that the header is skipped.

An array reference can be used to simply pass through a list of
headers unchanged.

It will default to the following headers:

- `X-Forwarded-For`
- `X-Forwarded-Host`
- `X-Forwarded-Port`
- `X-Forwarded-Proto`

The `User-Agent` is forwarded as `X-Forwarded-User-Agent`.

## response

This is a hash reference (since v0.2.0) of request headers to return
from the proxy.  The keys are the response header fields, and the
values are the headers that will be returned from the proxy.

Values of `1` will be a synonym for the same header, and false values
will mean that the header is skipped.

An array reference can be used to simply pass through a list of
headers unchanged.

It will default to the following headers:

- `Content-Type`
- `Expires`
- `Last-Modified`

## wait

The number of seconds to wait for new content to be loaded.

# LIMITATIONS

This does not support cache invalidation or screenshot rendering.

This only does the bare minimum necessary for proxying requests. You
may need additional middleware for reverse proxies, logging, or
security filtering.

# SEE ALSO

[Plack](https://metacpan.org/pod/Plack)

[WWW::Mechanize::Chrome](https://metacpan.org/pod/WWW::Mechanize::Chrome)

Rendertron [https://github.com/GoogleChrome/rendertron](https://github.com/GoogleChrome/rendertron)

# SOURCE

The development version is on github at [https://github.com/robrwo/perl-Plack-App-Prerender](https://github.com/robrwo/perl-Plack-App-Prerender)
and may be cloned from [git://github.com/robrwo/perl-Plack-App-Prerender.git](git://github.com/robrwo/perl-Plack-App-Prerender.git)

# BUGS

Please report any bugs or feature requests on the bugtracker website
[https://github.com/robrwo/perl-Plack-App-Prerender/issues](https://github.com/robrwo/perl-Plack-App-Prerender/issues)

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

# AUTHOR

Robert Rothenberg <rrwo@cpan.org>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Robert Rothenberg.

This is free software, licensed under:

```
The Artistic License 2.0 (GPL Compatible)
```
