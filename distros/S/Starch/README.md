# NAME

Starch - A framework independent HTTP session library.

# DESCRIPTION

Welcome to Starch!

Starch solves the problems introduced when complex HTTP session libraries
are written as web framework built-ins.  When complex libraries like these
are tied directly into a web framework they become much more difficult to
test, difficult to debug, impossible to integrate with other languages, and
they lose the ability to be independent which is always a loss.

The prime example, and the reason this module was originally built, is
[Catalyst::Plugin::Session](https://metacpan.org/pod/Catalyst::Plugin::Session) which has no business being so monolithic
and still being tied directly into [Catalyst](https://metacpan.org/pod/Catalyst).  Thus Starch was created
along with the super-thin glue [Catalyst::Plugin::Starch](https://metacpan.org/pod/Catalyst::Plugin::Starch).

At its foundation Starch provides the ability to create state objects, store
them, update, and remove them.  Starch is extremely generic despite the
fact that it was built to fill the no-framework HTTP session need.  Out
of the box Starch is about states and their storage backend and can be
used for purposes that have nothing to do with HTTP or sessions.  So far
nobody has done this, but there is no reason that Starch couldn't be used
as the workhorse behind an object store, for example.

One of the strengths that Starch provides is very flexible storage backends.
[Starch::Store](https://metacpan.org/pod/Starch::Store) objects can be layered, prioritized, rate-limited, behaviors
can be changed with plugins, states can be easily migrated from one backend to
another, caching is super easy to setup, etc, etc.

Starch has several design philosophies:

- Is as fast as possible by limiting method calls, implementing
lazy-loading wherever it can be done, and using libraries which
exhibit run-time efficiencies which beat out their competitors.
- Reduces data store reads and writes to just the most essential.
- Is independent from any particular framework (such as Catalyst or
Plack).
- Provides a straight-forward and powerful mechanism for customizing just
about any part of Starch via stores and plugin bundles.
- Is easy to understand due to everything being well documented,
hyper-linked, and containing thorough examples and tests.
- Low dependency overhead, and no XS dependencies in the core distribution.

There are many ["ALTERNATIVES"](#alternatives) to Starch to choose from, all of which
Starch was inspired from.

# BASIC USAGE

When setting up you need to, at a minimum, define a store:

    use Starch;
    
    my $starch = Starch->new(
        store => { class=>'::Memory' },
    );

A store is a hash ref of arguments which are used for constructing the
store object.  A store object implements a very simple interface for
setting, getting, and removing state data.  Beyond defining the
store you will not be interacting with it as the [Starch::State](https://metacpan.org/pod/Starch::State)
objects do all the store interaction for you.

When defining the store you must specify at least the `class`
argument which determines the store class to use.  This class name
can be relative to `Starch::Store` so that if you specify
`::Memory`, as in the example above, it will be resolved to the
[Starch::Store::Memory](https://metacpan.org/pod/Starch::Store::Memory) class.  An absolute store class name
may be used without the leading `::` if you have a custom store in
a different namespace.

Calling the `new` method on the `Starch` package actually returns
a [Starch::Manager](https://metacpan.org/pod/Starch::Manager) object, so refer to its documentation for details
on what arguments you can pass.

Now that you have the `$starch` object you can create a state object:

    my $state = $starch->state();

This creates a new [Starch::State](https://metacpan.org/pod/Starch::State) object which you can then
interact with:

    $state->data->{some_key} = 'some_value';

The ["data" in Starch::State](https://metacpan.org/pod/Starch::State#data) attribute is a writeable hash ref
which can contain any data you want.  This is the data which will
be stored by, and retrieved from, the store.  Once you're done
making changes to the data, call save:

    $state->save();

This stores the state data in the store.

Each state gets assigned a state ID automatically, unless you specify a custom
one when creating the state, which can be used to retrieve the state data at a
later time.  The state ID is a randomly generated SHA-1 hex digest.

    my $id = $state->id();

To retrieve a previously saved state pass the state ID to the
["state" in Starch::Manager](https://metacpan.org/pod/Starch::Manager#state) method:

    my $state = $starch->state( $id );

And now you can access the data you previously saved:

    print $state->data->{some_key}; # "some_value"

Your framework integration, such as [Catalyst::Plugin::Starch](https://metacpan.org/pod/Catalyst::Plugin::Starch),
will wrap up and hide away most of these details from you, but
it's still good to know what is happening behind the scenes.

# EXPIRATION

Expiration can be specified globally when instantiating the [Starch::Manager](https://metacpan.org/pod/Starch::Manager)
object, as well as per-state and per-store.  The expires value has various properties
and behaviors that are important to understand:

- The `expires` field is always specified as the number of seconds before
the state will expire.
- Setting `expires` to `0` generally disables expiration, but behavior
can be store-specific.  For example, often times caching stores assume no
expiration to mean the storage backend gets to pick when to expire the data.
- The [Starch::Manager](https://metacpan.org/pod/Starch::Manager) class accepts an `expires` argument which is used
as the default expires for new state objects and used as the expiration
for cookies via [Starch::Plugin::CookieArgs](https://metacpan.org/pod/Starch::Plugin::CookieArgs).
- States have an `expires` argument which defaults to the value of
the global expires set in the [Starch::Manager](https://metacpan.org/pod/Starch::Manager) object.  Each state
can then have their individual expire extended or reduced via the
["set\_expires" in Starch::State](https://metacpan.org/pod/Starch::State#set_expires) method.
- Stores may have a `max_expires` argument passed to them.  If the state's
expires is larger than the store's max\_expires then the state's expires will
be replaced with the store's max\_expires when writing the data to the store.

    This is useful for when you have a caching store in front of your persistent
    store and you'd like your sessions to expire out of the caching store, by
    setting `max_expires` on it, well before they will expire out of the
    persistent store.

# LOGGING

Starch has built-in logging facilities via [Log::Any](https://metacpan.org/pod/Log::Any).  By default,
nothing is logged.  Various plugins and stores do use logging, such
as the [Starch::Plugin::LogStoreExceptions](https://metacpan.org/pod/Starch::Plugin::LogStoreExceptions) plugin.

If you do not set up a log adapter then these log messages will disappear
into the void.  Read the [Log::Any](https://metacpan.org/pod/Log::Any) documentation for instructions on
configuring an adapter to capture the log output.

The [Starch::Plugin::Trace](https://metacpan.org/pod/Starch::Plugin::Trace) plugin adds a bunch of additional
logging output useful for development.

# METHOD PROXIES

The Starch manager ([Starch::Manager](https://metacpan.org/pod/Starch::Manager)) and stores support method proxies
out of the box for all arguments passed to them.  A method proxy is
an array ref which is lightly inspired by JSON references.  This array
ref must have the string `&proxy` as the first value, a package name
as the second value, a method name as the third value, and any number
of arguments to pass to the method after that:

    [ '&proxy', $package, $method, @args ]

Method proxies are really useful when you are configuring Starch from
static configuration where you cannot dynamically pass a value from Perl.

An example from [Starch::Store::CHI](https://metacpan.org/pod/Starch::Store::CHI) illustrates how this works:

    my $starch = Starch->new(
        store => {
            class => '::CHI',
            chi => ['&proxy', 'My::CHI::Builder', 'get_chi'],
        },
    );

This will cause `My::CHI::Builder` to be loaded, if it hasn't already, and then
`My::CHI::Builder->get_chi()` will be called and the return value used as
the value for the `chi` argument.

Another practical example of using this is with [DBI](https://metacpan.org/pod/DBI) where normally
you would end up making a separate connection to your database for states.
If your state database is the same database as you use for other things
it may make sense to use the same `$dbh` for both so that you do not
double the number of connections you are making to your database.

Method proxies can be used with the manager and store objects at any point in
their arguments.  For example, if you have Perl code that builds the Starch
configuration from the ground up you could:

    my $starch = Starch->new(
        [ '&proxy', 'My::Starch::Config', 'get_config' ],
    );

Which will call `get_config` on the `My::Starch::Config` package and use its
return value as the arguments for instantiating the Starch object.

Method proxies are provided by [MooX::MethodProxyArgs](https://metacpan.org/pod/MooX::MethodProxyArgs) and
[Data::MethodProxy](https://metacpan.org/pod/Data::MethodProxy); check those for more details.

# PERFORMANCE

On a decently-specced developer laptop Starch adds, at most, one half of one
millisecond to every HTTP request.  This non-scientific benchmark was done using
the `Memory` store and a contrived example of the typical use of a state as the
backend for an HTTP session.

Starch is meant to be as fast as possible while still being flexible.
Due to Starch avoiding dependencies, and having zero non-core XS dependencies,
there are still some areas which could be slightly faster.  At this time there
is one plugin which will provide a small performance gain [Starch::Plugin::Sereal](https://metacpan.org/pod/Starch::Plugin::Sereal).
Even then, the gain using this plugin will be in the order of a fraction of a
millisecond per each HTTP request.

Starch has gone through the wringer with respect to performance and there just are
not many performance gains to be eked out of Starch.  Instead, you'll
likely find that your time in Starch is primarily spent in your store.
So, when setting up Starch, picking a store is the most important
decision you can make with respect to performance.

# STORES

These stores are included with the Starch distribution:

- [Starch::Store::Layered](https://metacpan.org/pod/Starch::Store::Layered)
- [Starch::Store::Memory](https://metacpan.org/pod/Starch::Store::Memory)

These stores are distributed separately on CPAN:

- [Starch::Store::Amazon::DynamoDB](https://metacpan.org/pod/Starch::Store::Amazon::DynamoDB)
- [Starch::Store::Catalyst::Plugin::Session](https://metacpan.org/pod/Starch::Store::Catalyst::Plugin::Session)
- [Starch::Store::CHI](https://metacpan.org/pod/Starch::Store::CHI) - This store is a meta-store which provides
access to many other stores such as [CHI::Driver::Redis](https://metacpan.org/pod/CHI::Driver::Redis),
[CHI::Driver::BerkleyDB](https://metacpan.org/pod/CHI::Driver::BerkleyDB), [CHI::Driver::File](https://metacpan.org/pod/CHI::Driver::File), [CHI::Driver::FastMmap](https://metacpan.org/pod/CHI::Driver::FastMmap),
[CHI::Driver::Memcached](https://metacpan.org/pod/CHI::Driver::Memcached), and [CHI::Driver::CacheCache](https://metacpan.org/pod/CHI::Driver::CacheCache).
- [Starch::Store::DBI](https://metacpan.org/pod/Starch::Store::DBI)
- [Starch::Store::DBIx::Connector](https://metacpan.org/pod/Starch::Store::DBIx::Connector)

More third-party stores can be found on
[meta::cpan](https://metacpan.org/search?q=Starch%3A%3AStore).

# PLUGINS

Plugins alter the behavior of the manager ([Starch::Manager](https://metacpan.org/pod/Starch::Manager)),
state ([Starch::State](https://metacpan.org/pod/Starch::State)), and store ([Starch::Store](https://metacpan.org/pod/Starch::Store))
objects.  To use a plugin pass the `plugins` argument when
creating your Starch object:

    my $starch = Starch->new(
        plugins => ['::Trace'],
        store => { ... },
        ...,
    );

These plugins are included with the Starch distribution:

- [Starch::Plugin::AlwaysLoad](https://metacpan.org/pod/Starch::Plugin::AlwaysLoad)
- [Starch::Plugin::CookieArgs](https://metacpan.org/pod/Starch::Plugin::CookieArgs)
- [Starch::Plugin::DisableStore](https://metacpan.org/pod/Starch::Plugin::DisableStore)
- [Starch::Plugin::LogStoreExceptions](https://metacpan.org/pod/Starch::Plugin::LogStoreExceptions)
- [Starch::Plugin::RenewExpiration](https://metacpan.org/pod/Starch::Plugin::RenewExpiration)
- [Starch::Plugin::ThrottleStore](https://metacpan.org/pod/Starch::Plugin::ThrottleStore)
- [Starch::Plugin::Trace](https://metacpan.org/pod/Starch::Plugin::Trace)

These plugins are distributed separately on CPAN:

- [Starch::Plugin::Net::Statsd](https://metacpan.org/pod/Starch::Plugin::Net::Statsd)
- [Starch::Plugin::SecureStateID](https://metacpan.org/pod/Starch::Plugin::SecureStateID)
- [Starch::Plugin::Sereal](https://metacpan.org/pod/Starch::Plugin::Sereal)
- [Starch::Plugin::TimeoutStore](https://metacpan.org/pod/Starch::Plugin::TimeoutStore)

More third-party plugins can be found on
[meta::cpan](https://metacpan.org/search?q=Starch%3A%3APlugin).

# INTEGRATIONS

The following Starch integrations are available:

- [Catalyst::Plugin::Starch](https://metacpan.org/pod/Catalyst::Plugin::Starch)

Integrations for [Plack](https://metacpan.org/pod/Plack), [Dancer2](https://metacpan.org/pod/Dancer2), [Mojolicious](https://metacpan.org/pod/Mojolicious), etc will
be developed as needed by the people that need them.

# EXTENDING

Starch can be extended by plugins and stores.  See [Starch::Extending](https://metacpan.org/pod/Starch::Extending)
for instructions on writing your own.

# ALTERNATIVES

- [CGI::Session](https://metacpan.org/pod/CGI::Session)
- [Data::Session](https://metacpan.org/pod/Data::Session)
- [HTTP::Session](https://metacpan.org/pod/HTTP::Session)
- [Catalyst::Plugin::Session](https://metacpan.org/pod/Catalyst::Plugin::Session)
- [Plack::Middleware::Session](https://metacpan.org/pod/Plack::Middleware::Session)
- [Dancer::Session](https://metacpan.org/pod/Dancer::Session)
- [Mojolicious::Sessions](https://metacpan.org/pod/Mojolicious::Sessions)
- [MojoX::Session](https://metacpan.org/pod/MojoX::Session)

# SUPPORT

Please submit bugs and feature requests to the
Starch GitHub issue tracker:

[https://github.com/bluefeet/Starch/issues](https://github.com/bluefeet/Starch/issues)

# AUTHORS

    Aran Clary Deltac <bluefeet@gmail.com>
    Arthur Axel "fREW" Schmidt <frioux+cpan@gmail.com>
    Jonathan Scott Duff <duff@pobox.com>
    Ismail Kerim <ismail.kerim@assurant.com>

# ACKNOWLEDGEMENTS

Thanks to [ZipRecruiter](https://www.ziprecruiter.com/)
for encouraging their employees to contribute back to the open
source ecosystem.  Without their dedication to quality software
development this distribution would not exist.

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
