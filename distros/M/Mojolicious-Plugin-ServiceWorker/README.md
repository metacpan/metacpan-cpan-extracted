# NAME

Mojolicious::Plugin::ServiceWorker - plugin to add a Service Worker

# SYNOPSIS

    # Mojolicious::Lite
    plugin 'ServiceWorker' => {
      route_sw => '/sw2.js',
      precache_urls => [
      ],
    };
    app->serviceworker->add_event_listener(push => <<'EOF');
    function(event) {
      if (event.data) {
        console.log('This push event has data: ', event.data.text());
      } else {
        console.log('This push event has no data.');
      }
    }
    EOF

# DESCRIPTION

[Mojolicious::Plugin::ServiceWorker](https://metacpan.org/pod/Mojolicious::Plugin::ServiceWorker) is a [Mojolicious](https://metacpan.org/pod/Mojolicious) plugin.

# METHODS

[Mojolicious::Plugin::ServiceWorker](https://metacpan.org/pod/Mojolicious::Plugin::ServiceWorker) inherits all methods from
[Mojolicious::Plugin](https://metacpan.org/pod/Mojolicious::Plugin) and implements the following new ones.

## register

    my $p = $plugin->register(Mojolicious->new, \%conf);

Register plugin in [Mojolicious](https://metacpan.org/pod/Mojolicious) application, returning the plugin
object. Takes a hash-ref as configuration, see ["OPTIONS"](#options) for keys.

# OPTIONS

## route\_sw

The service worker route. Defaults to `/serviceworker.js`. Note that
you need this to be in your app's top level, since the service worker
can only affect URLs at or below its "scope".

## debug

If a true value, `console.log` will be used to indicate various events
including SW caching choices.

## precache\_urls

An array-ref of URLs that are relative to the SW's scope to load into
the SW's cache on installation. The SW URL will always be added to this.

## network\_only

An array-ref of URLs. Any fetched URL in this list will never be cached,
and always fetched over the network.

## cache\_only

As above, except the matching URL will never be re-checked. Use only
where you cache-bust by including a hash in the filename.

## network\_first

As above, except the matching URL will be fetched from the network
every time and used if possible. The cached value will only be used if
that fails.

**Any URL not matching these three criteria** will be treated with a
"cache first" strategy, also known as "stale while revalidate": the cached
version will immediately by returned to the web client for performance,
but also fetched over the network and re-cached for freshness.

# HELPERS

## serviceworker.route

    my $route_name = $c->serviceworker->route;

The configured ["route\_sw"](#route_sw) route.

## serviceworker.config

    my $config = $c->serviceworker->config;

The SW configuration (a hash-ref). Keys: `debug`, `precache_urls`,
`network_only`, `cache_only`, `network_first`.

## serviceworker.add\_event\_listener

    my $config = $c->serviceworker->add_event_listener(push => <<'EOF');
    function(event) {
      if (event.data) {
        console.log('This push event has data: ', event.data.text());
      } else {
        console.log('This push event has no data.');
      }
    }
    EOF

Add to the service worker an event listener. Arguments are the event
name, and a JavaScript function expression that takes the correct args
for that event.

## serviceworker.event\_listeners

    my $listeners = $c->serviceworker->event_listeners;

Returns a hash-ref mapping event name to array-ref of function
expressions as above. `install` and `fetch` are provided by default.

# TEMPLATES

Various templates are available for including in the app's templates:

## serviceworker-install.html.ep

A snippet of JavaScript that will install the supplied service
worker. Include it within a `script` element:

    <script>
    %= include 'serviceworker-install'
    </script>

# SEE ALSO

[Mojolicious](https://metacpan.org/pod/Mojolicious), [Mojolicious::Guides](https://metacpan.org/pod/Mojolicious::Guides), [https://mojolicious.org](https://mojolicious.org).
