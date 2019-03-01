package Starch;
use 5.008001;
use strictures 2;
our $VERSION = '0.12';

use Starch::Factory;
use Moo::Object qw();

use namespace::clean;

sub new {
    my $class = shift;
    my $args = Moo::Object->BUILDARGS( @_ );

    my $plugins = delete( $args->{plugins} );
    my $factory = Starch::Factory->new(
        defined($plugins) ? (plugins=>$plugins) : (),
    );

    return $factory->manager_class->new(
        %$args,
        factory => $factory,
    );
}

1;
__END__

=head1 NAME

Starch - A framework independent HTTP session library.

=head1 DESCRIPTION

Welcome to Starch!

Starch solves the problems introduced when complex HTTP session libraries
are written as web framework built-ins.  When complex libraries like these
are tied directly into a web framework they become much more difficult to
test, difficult to debug, impossible to integrate with other languages, and
they lose the ability to be independent which is always a loss.

The prime example, and the reason this module was originally built, is
L<Catalyst::Plugin::Session> which has no business being so monolithic
and still being tied directly into L<Catalyst>.  Thus Starch was created
along with the super-thin glue L<Catalyst::Plugin::Starch>.

At its foundation Starch provides the ability to create state objects, store
them, update, and remove them.  Starch is extremely generic despite the
fact that it was built to fill the no-framework HTTP session need.  Out
of the box Starch is about states and their storage backend and can be
used for purposes that have nothing to do with HTTP or sessions.  So far
nobody has done this, but there is no reason that Starch couldn't be used
as the workhorse behind an object store, for example.

One of the strengths that Starch provides is very flexible storage backends.
L<Starch::Store> objects can be layered, prioritized, rate-limited, behaviors
can be changed with plugins, states can be easily migrated from one backend to
another, caching is super easy to setup, etc, etc.

Starch has several design philosophies:

=over

=item *

Is as fast as possible by limiting method calls, implementing
lazy-loading wherever it can be done, and using libraries which
exhibit run-time efficiencies which beat out their competitors.

=item *

Reduces data store reads and writes to just the most essential.

=item *

Is independent from any particular framework (such as Catalyst or
Plack).

=item *

Provides a straight-forward and powerful mechanism for customizing just
about any part of Starch via stores and plugin bundles.

=item *

Is easy to understand due to everything being well documented,
hyper-linked, and containing thorough examples and tests.

=item *

Low dependency overhead, and no XS dependencies in the core distribution.

=back

There are many L</ALTERNATIVES> to Starch to choose from, all of which
Starch was inspired from.

=head1 BASIC USAGE

When setting up you need to, at a minimum, define a store:

    use Starch;
    
    my $starch = Starch->new(
        store => { class=>'::Memory' },
    );

A store is a hash ref of arguments which are used for constructing the
store object.  A store object implements a very simple interface for
setting, getting, and removing state data.  Beyond defining the
store you will not be interacting with it as the L<Starch::State>
objects do all the store interaction for you.

When defining the store you must specify at least the C<class>
argument which determines the store class to use.  This class name
can be relative to C<Starch::Store> so that if you specify
C<::Memory>, as in the example above, it will be resolved to the
L<Starch::Store::Memory> class.  An absolute store class name
may be used without the leading C<::> if you have a custom store in
a different namespace.

Calling the C<new> method on the C<Starch> package actually returns
a L<Starch::Manager> object, so refer to its documentation for details
on what arguments you can pass.

Now that you have the C<$starch> object you can create a state object:

    my $state = $starch->state();

This creates a new L<Starch::State> object which you can then
interact with:

    $state->data->{some_key} = 'some_value';

The L<Starch::State/data> attribute is a writeable hash ref
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
L<Starch::Manager/state> method:

    my $state = $starch->state( $id );

And now you can access the data you previously saved:

    print $state->data->{some_key}; # "some_value"

Your framework integration, such as L<Catalyst::Plugin::Starch>,
will wrap up and hide away most of these details from you, but
it's still good to know what is happening behind the scenes.

=head1 EXPIRATION

Expiration can be specified globally when instantiating the L<Starch::Manager>
object, as well as per-state and per-store.  The expires value has various properties
and behaviors that are important to understand:

=over

=item *

The C<expires> field is always specified as the number of seconds before
the state will expire.

=item *

Setting C<expires> to C<0> generally disables expiration, but behavior
can be store-specific.  For example, often times caching stores assume no
expiration to mean the storage backend gets to pick when the expire the data.

=item *

The L<Starch::Manager> class accepts an C<expires> argument which is used
as the default expires for new state objects and used as the expiration
for cookies via L<Starch::Plugin::CookieArgs>.

=item *

States have an C<expires> argument which defaults to the value of
the global expires set in the L<Starch::Manager> object.  Each state
can then have their individual expire extended or reduced via the
L<Starch::State/set_expires> method.

=item *

Stores may have a C<max_expires> argument passed to them.  If the state's
expires is larger than the store's max_expires then the state's expires will
be replaced with the store's max_expires when writing the data to the store.

This is useful for when you have a caching store in front of your persistent
store and you'd like your sessions to expire out of the caching store, by
setting C<max_expires> on it, well before they will expire out of the
persistent store.

=back

=head1 LOGGING

Starch has built-in logging facilities via L<Log::Any>.  By default,
nothing is logged.  Various plugins and stores do use logging, such
as the L<Starch::Plugin::LogStoreExceptions> plugin.

If you do not set up a log adapter then these log messages will disappear
into the void.  Read the L<Log::Any> documentation for instructions on
configuring an adapter to capture the log output.

The L<Starch::Plugin::Trace> plugin adds a bunch of additional
logging output useful for development.

=head1 METHOD PROXIES

The Starch manager (L<Starch::Manager>) and stores support method proxies
out of the box for all arguments passed to them.  A method proxy is
an array ref which is lightly inspired by JSON references.  This array
ref must have the string C<&proxy> as the first value, a package name
as the second value, a method name as the third value, and any number
of arguments to pass to the method after that:

    [ '&proxy', $package, $method, @args ]

Method proxies are really useful when you are configuring Starch from
static configuration where you cannot dynamically pass a value from Perl.

An example from L<Starch::Store::CHI> illustrates how this works:

    my $starch = Starch->new(
        store => {
            class => '::CHI',
            chi => ['&proxy', 'My::CHI::Builder', 'get_chi'],
        },
    );

This will cause C<My::CHI::Builder> to be loaded, if it hasn't already, and then
C<My::CHI::Builder-E<gt>get_chi()> will be called and the return value used as
the value for the C<chi> argument.

Another practical example of using this is with L<DBI> where normally
you would end up making a separate connection to your database for states.
If your state database is the same database as you use for other things
it may make sense to use the same C<$dbh> for both so that you do not
double the number of connections you are making to your database.

Method proxies can be used with the manager and store objects at any point in
their arguments.  For example, if you have Perl code that builds the Starch
configuration from the ground up you could:

    my $starch = Starch->new(
        [ '&proxy', 'My::Starch::Config', 'get_config' ],
    );

Which will call C<get_config> on the C<My::Starch::Config> package and use its
return value as the arguments for instantiating the Starch object.

Method proxies are provided by L<MooX::MethodProxyArgs> and
L<Data::MethodProxy>; check those for more details.

=head1 PERFORMANCE

On a decently-specced developer laptop Starch adds, at most, one half of one
millisecond to every HTTP request.  This non-scientific benchmark was done using
the C<Memory> store and a contrived example of the typical use of a state as the
backend for an HTTP session.

Starch is meant to be as fast as possible while still being flexible.
Due to Starch avoiding dependencies, and having zero non-core XS dependencies,
there are still some areas which could be slightly faster.  At this time there
is one plugin which will provide a small performance gain L<Starch::Plugin::Sereal>.
Even then, the gain using this plugin will be in the order of a fraction of a
millisecond per each HTTP request.

Starch has gone through the wringer with respect to performance and there just are
not many performance gains to be eked out of Starch.  Instead, you'll
likely find that your time in Starch is primarily spent in your store.
So, when setting up Starch, picking a store is the most important
decision you can make with respect to performance.

=head1 STORES

These stores are included with the Starch distribution:

=over

=item *

L<Starch::Store::Layered>

=item *

L<Starch::Store::Memory>

=back

These stores are distributed separately on CPAN:

=over

=item *

L<Starch::Store::Amazon::DynamoDB>

=item *

L<Starch::Store::Catalyst::Plugin::Session>

=item *

L<Starch::Store::CHI> - This store is a meta-store which provides
access to many other stores such as L<CHI::Driver::Redis>,
L<CHI::Driver::BerkleyDB>, L<CHI::Driver::File>, L<CHI::Driver::FastMmap>,
L<CHI::Driver::Memcached>, and L<CHI::Driver::CacheCache>.

=item *

L<Starch::Store::DBI>

=item *

L<Starch::Store::DBIx::Connector>

=back

More third-party stores can be found on
L<meta::cpan|https://metacpan.org/search?q=Starch%3A%3AStore>.

=head1 PLUGINS

Plugins alter the behavior of the manager (L<Starch::Manager>),
state (L<Starch:State>), and store (L<Starch::Store>)
objects.  To use a plugin pass the C<plugins> argument when
creating your Starch object:

    my $starch = Starch->new(
        plugins => ['::Trace'],
        store => { ... },
        ...,
    );

These plugins are included with the Starch distribution:

=over

=item *

L<Starch::Plugin::AlwaysLoad>

=item *

L<Starch::Plugin::CookieArgs>

=item *

L<Starch::Plugin::DisableStore>

=item *

L<Starch::Plugin::LogStoreExceptions>

=item *

L<Starch::Plugin::RenewExpiration>

=item *

L<Starch::Plugin::ThrottleStore>

=item *

L<Starch::Plugin::Trace>

=back

These plugins are distributed separately on CPAN:

=over

=item *

L<Starch::Plugin::Net::Statsd>

=item *

L<Starch::Plugin::SecureStateID>

=item *

L<Starch::Plugin::Sereal>

=item *

L<Starch::Plugin::TimeoutStore>

=back

More third-party plugins can be found on
L<meta::cpan|https://metacpan.org/search?q=Starch%3A%3APlugin>.

=head1 INTEGRATIONS

The following Starch integrations are available:

=over

=item *

L<Catalyst::Plugin::Starch>

=back

Integrations for L<Plack>, L<Dancer2>, L<Mojolicious>, etc will
be developed as needed by the people that need them.

=head1 EXTENDING

Starch can be extended by plugins and stores.  See L<Starch::Extending>
for instructions on writing your own.

=head1 ALTERNATIVES

=over

=item *

L<CGI::Session>

=item *

L<Data::Session>

=item *

L<HTTP::Session>

=item *

L<Catalyst::Plugin::Session>

=item *

L<Plack::Middleware::Session>

=item *

L<Dancer::Session>

=item *

L<Mojolicious::Sessions>

=item *

L<MojoX::Session>

=back

=head1 SUPPORT

Please submit bugs and feature requests to the Starch GitHub issue tracker:

L<https://github.com/bluefeet/Starch/issues>

=head1 AUTHORS

Aran Clary Deltac E<lt>bluefeet@gmail.comE<gt>

Arthur Axel "fREW" Schmidt E<lt>frioux+cpan@gmail.comE<gt>

Jonathan Scott Duff E<lt>duff@pobox.comE<gt>

Ismail Kerim E<lt>ismail.kerim@assurant.comE<gt>

=head1 ACKNOWLEDGEMENTS

Thanks to L<ZipRecruiter|https://www.ziprecruiter.com/>
for encouraging their employees to contribute back to the open
source ecosystem.  Without their dedication to quality software
development this distribution would not exist.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

