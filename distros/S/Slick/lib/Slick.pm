package Slick;

use 5.036;

use Moo;
use Types::Standard qw(HashRef ArrayRef Int Str);
use Module::Runtime qw(require_module);
use Carp            qw(croak);
use URI::Query;
use Plack::Builder qw(builder enable);
use Plack::Request;
use Slick::Context;
use Slick::Events qw(EVENTS BEFORE_DISPATCH AFTER_DISPATCH);
use Slick::Error;
use Slick::Database;
use Slick::Cache;
use Slick::Methods qw(METHODS);
use Slick::Route;
use Slick::Router;
use Slick::RouteMap;
use Slick::Util;
use experimental qw(try);

no warnings qw(experimental::try);

our $VERSION = '0.006';

with 'Slick::EventHandler';
with 'Slick::RouteManager';

has port => (
    is      => 'ro',
    lazy    => 1,
    isa     => Int,
    default => sub { return 8000; }
);

has addr => (
    is      => 'ro',
    lazy    => 1,
    isa     => Str,
    default => sub { return '127.0.0.1'; }
);

has timeout => (
    is      => 'ro',
    lazy    => 1,
    isa     => Int,
    default => sub { return 120; }
);

has env => (
    is      => 'rw',
    isa     => Str,
    default => sub {
        return $ENV{SLICK_ENV} // $ENV{PLACK_ENV} // 'dev';
    }
);

has server => (
    is   => 'ro',
    lazy => 1
);

has dbs => (
    is      => 'ro',
    lazy    => 1,
    isa     => HashRef,
    default => sub { return {}; }
);

has caches => (
    is      => 'ro',
    lazy    => 1,
    isa     => HashRef,
    default => sub { return {}; }
);

has helpers => (
    is      => 'rw',
    isa     => HashRef,
    default => sub { return {}; }
);

has middlewares => (
    is      => 'ro',
    isa     => ArrayRef,
    default => sub { return []; }
);

has banner => (
    is      => 'rw',
    default => sub {
        return <<'EOB';
   _____ ___      __  
  / ___// (_)____/ /__  a'!   _,,_
  \__ \/ / / ___/ //_/    \\_/    \
 ___/ / / / /__/ ,<        \, /-( /'-,
/____/_/_/\___/_/|_|        //\ //\\
EOB
    }
);

sub _dispatch {
    my $self    = shift;
    my $request = Plack::Request->new(shift);

    my $context = Slick::Context->new( request => $request, );
    my $method  = lc( $request->method );

    for ( @{ $self->event_handlers->{ BEFORE_DISPATCH() } } ) {
        try { $_->( $self, $context ) // goto DONE; }
        catch ($e) {
            push $context->stash->{'slick.errors'}->@*, Slick::Error->new($e)
        };
    }

    my $route =
      $self->handlers->get( $context->request->request_uri, $method, $context );

    if ( defined $route ) {
        try { $route->dispatch( $self, $context ); }
        catch ($e) {
            push $context->stash->{'slick.errors'}->@*, Slick::Error->new($e)
        }
    }
    else {
        $context->status(405);
        $context->body('405 Method Not Supported');
    }

    for ( @{ $self->event_handlers->{ AFTER_DISPATCH() } } ) {
        try { $_->( $self, $context ) // goto DONE; }
        catch ($e) {
            push $context->stash->{'slick.errors'}->@*, Slick::Error->new($e);
        }
    }

  DONE:

    if ( $context->stash->{'slick.errors'}->@* && ( $self->env eq 'dev' ) ) {
        say $_->error for $context->stash->{'slick.errors'}->@*;
        $context->json(
            [ map { $_->to_hash } $context->stash->{'slick.errors'}->@* ] );
    }

    # HEAD requests only want headers.
    $context->body = [] if $method eq 'head';

    return $context->to_psgi;
}

sub BUILD {
    my $self = shift;

    return $self;
}

sub helper {
    my ( $self, $name, $helper ) = @_;

    if ( exists $self->helpers->{$name} ) {
        return $self->helpers->{$name};
    }

    return $self->helpers->{$name} = $helper;
}

sub middleware {
    my ( $self, @args ) = @_;

    push $self->middlewares->@*, [@args];

    return $self;
}

# Add a database or access an existing database:
#
# $slick->database('foo'); # Get's an existing database labeled 'foo'
#
# $slick->database(foo => 'postgresql://foo@bar:5432/mydb'); # Attempts to create a database labeled foo
sub database {
    my ( $self, $name, $conn ) = @_;

    if ( defined $conn ) {
        return $self->dbs->{$name} = Slick::Database->new( conn => $conn );
    }

    return $self->dbs->{$name} // undef;
}

sub cache {
    my ( $self, $name, @args ) = @_;

    if (@args) {
        return $self->caches->{$name} = Slick::Cache->new(@args);
    }

    return $self->caches->{$name} // undef;
}

# Runs the application with the server
sub run {
    my ( $self, %args ) = @_;

    my $server = $args{server} // 'HTTP::Server::PSGI';
    $self->{port} = $args{port} // 8000;
    $self->{addr} = $args{addr} // '127.0.0.1';

    require_module $server;

    if ( $self->env eq 'dev'
        || ( $self->env ne 'dev' && !$self->server ) )
    {
        $self->{server} = $server->new(
            host            => $self->addr,
            port            => $self->port,
            timeout         => $self->timeout,
            server_software => "Slick v$VERSION + $server"
        );
    }

    say "\n" . $self->banner;

    my ( $addr, $port ) = ( $self->addr, $self->port );
    say "Slick is listening on: http://$addr:$port\n";

    return $self->server->run( $self->app );
}

sub register {
    my $self   = shift;
    my $router = shift;

    croak qq{Router cannot be undef.} unless $router;

    $self->handlers->merge( $router->handlers, $router->event_handlers );

    return $self;
}

# This is for users who want to use plackup
sub app {
    my $self = shift;

    return builder {
        enable 'Plack::Middleware::AccessLog' => format => 'combined';
        enable $_->@* for $self->middlewares->@*;
        sub {
            return $self->_dispatch(@_);
        }
    };
}

1;

=encoding utf8

=head1 NAME

Slick

=head1 SYNOPSIS

Slick is an Object-Oriented Perl web-framework for building performant, and easy to refactor REST API's. 
Slick is built on top of L<DBI>, L<Plack>, and L<Moo> and fits somewhere in-between the realms of L<Dancer> and L<Mojolicious>.

Slick has everything you need to build a Database driven REST API, including built in support
for Database connections, Migrations, Event logic, and soon, route based Caching via Redis or Memcached. Since Slick is a Plack application,
you can also take advantage of swappable backends and Plack middlewares extremely simply.

Currently, Slick supports MySQL and PostgreSQL but there are plans to implement Oracle and MS SQL Server as well.

=head2 Examples

=head3 A Simple App

This is a simple example app that takes advantage of 2 databases,
has a migration, and also serves some JSON.

    use 5.036;

    use Slick;

    my $s = Slick->new;

    # Both MySQL and Postgres are supported databases
    # Slick will create the correct DB object based on the connection URI
    # [{mysql,postgres,postgresql}://][user[:[password]]@]host[:port][/schema]
    $s->database(my_db => 'postgresql://user:password@127.0.0.1:5432/schema');
    $s->database(corporate_db => 'mysql://corporate:secure_password@127.0.0.1:3306/schema');

    $s->database('my_db')->migration(
        'create_user_table', # id
        'CREATE TABLE user ( id SERIAL PRIMARY KEY AUTOINCREMENT, name TEXT, age INT );', #up
        'DROP TABLE user;' # down
    );

    $s->database('my_db')->migrate_up; # Migrates all pending migrations

    $s->get('/users/{id}' => sub {
        my $app = shift;
        my $context = shift;

        # Queries follow SQL::Abstract's notations
        my $user = $app->database('my_db')->select_one('user', { id => $context->params('id') });

        # Render the user hashref as JSON.
        $context->json($user);
    });

    $s->post('/users' => sub {
        my $app = shift;
        my $context = shift;

        my $new_user = $context->content; # Will be decoded from JSON, YAML, or URL encoded (See JSON::Tiny, YAML::Tiny, and URL::Encode)

        $app->database('my_db')->insert('user', $new_user);

        $context->json($new_user);
    });

    $s->run; # Run the application.

=head3 A Multi-file application

This is a multi-file application that uses L<Slick::Router>.

    ### INSIDE OF YOUR ROUTER MODULE lib/MyApp/ItemRouter.pm

    package MyApp::ItemRouter;

    use base qw(Slick::Router);

    my $router = __PACKAGE__->new(base => '/items');

    $router->get('/{id}' => sub {
        my ($app, $context) = @_;
        my $item = $app->database('items')->select_one({ id => $context->param('id') });
        $context->json($item);
    });

    $router->post('' => sub {
        my ($app, $context) = @_;
        my $new_item = $context->content;

        # Do some sort of validation
        if (not $app->helper('item_validator')->($new_item)) {
            $context->status(400)->json({ error => 'Bad Request' });
        } 
        else {
            $app->database('items')->insert('items', $new_item);
            $context->json($new_item);
        }
    });

    sub router {
        return $router;
    }

    1;

    ### INSIDE OF YOUR RUN SCRIPT 'app.pl'

    use 5.036;
    use lib 'lib';

    use Slick;
    use MyApp::ItemRouter;

    my $slick = Slick->new;

    $slick->helper(item_validator => sub {
        return exists shift->{name};
    });

    # Register as many routers as you want!
    $slick->register(MyApp::ItemRouter->router);

    $slick->run;

=head3 Running with plackup

If you wish to use C<plackup> you can change the final call to C<run> to a call to C<app>:

    $s->app;

Then simply run with plackup (substitue `my_app.psgi` with whatever your app is called):

    plackup -a my_app.psgi

=head3 Changing PSGI backend

Will run on the default L<HTTP::Server::PSGI>.

    $s->run;

Or,

In this example, running Slick with a L<Gazelle> backend on port C<8888> and address C<0.0.0.0>.

    $s->run(server => 'Gazelle', port => 8888, addr => '0.0.0.0'); 

=head3 Using Plack Middlewares

You can register more Plack middlewares with your application using the L<"middleware"> method.

    my $s = Slick->new;

    $s->middleware('Deflater')
    ->middleware('Session' => store => 'file')
    ->middleware('Debug', panels => [ qw(DBITrace Memory) ]);

    $s->run; # or $s->app depending on if you want to use plackup.

=head1 API

=head2 app

    $s->app;

Converts the L<Slick> application to a PSGI runnable app.

=head2 register

    my $router = Slick::Router->new(base => '/foo');
    
    $s->register($router);

Registers a L<Slick::Router> to the application. This includes calling C<merge> on the app's L<Slick::RouteMap>.

=head2 banner

    $s->banner;

Returns the L<Slick> banner.

You can overwrite the banner with something else if you like via:

    $s->{banner} = 'My Cool Banner!';

=head2 database

    $s->database(my_db => 'postgresql://foo:bar@127.0.0.1:5432/database');

Creates and registers a database to the L<Slick> instance. The connection string should
be a fully-qualified URI based DSN.

    $s->database('my_db');

Retrieves the database if it exists, otherwise returns C<undef>.

=head2 cache

    # See Redis and Cache::Memcached on CPAN for arguments

    # Create a Redis instance
    $s->cache(
        my_redis => type => 'redis',    # Slick Arguments
        server   => '127.0.0.1:6379'    # Redis arguments
    );

    # Create a Memcached instance
    $s->cache(
        my_memcached => type          => 'memcached',   # Slick Arguments
        servers      => ['127.0.0.1'] => debug => 1     # Cache::Memcached arguments
    );

Retrieves the cache if it exists, otherwise returns C<undef>. Basically L<"database"> but for caches.
Note type is a required argument, it should either be C<'redis'> or C<'memcached'>.

=head2 helper

    $s->helper(printer => sub { print "Hi!"; });

Registers a Perl object with the L<Slick> instance.

    $s->helper('printer')->();

Retrieves the helper from the L<Slick> instance if it exists, otherwise returns C<undef>.

=head2 middleware

    $s->middleware('Deflater');

Registers a L<Plack::Middleware> with the L<Slick> instance. Always returns the L<Slick> instance
so you can chain many middlewares in one sitting.

    $s->middleware('Deflater')
    ->middleware('Session' => store => 'file')
    ->middleware('Debug', panels => [ qw(DBITrace Memory) ]);

=head2 run

    $s->run;

Runs the L<Slick> application on port C<8000> and address C<127.0.0.1> atop L<HTTP::Server::PSGI> by default.

You can change this via parameters passed to the C<run> method:

    $s->run(
        server => 'Gazelle',
        port => 9999,
        addr => '0.0.0.0'
    );

=head2 get, post, put, patch, delete

Methods to handle requests to your server. Takes a location, and a C<CodeRef> that expects
two arguments, app (L<Slick>) and context (L<Slick::Context>).

    $s->get('/foo', sub {
        my ($app, $context) = @_;
        # ... do stuff
    });

You can also have path parameters that are replaced with the values in the URI:

    $s->get('/foo/{bar}', sub {
        my ($app, $context) = @_;
        $context->params('bar'); # Resolves to the parameters value.
        # ... do stuff
    });

You may also register local events for the route like so:

    $s->get('/foo/{bar}', sub {
        my ($app, $context) = @_;
        $context->params('bar'); # Resolves to the parameters value.
        # ... do stuff
    },
    { before_dispatch => [
         sub {
             my ($app, $context) = @_;
             # Do some before dispatch logic
         }
    ],
      after_dispatch => [
         sub {
             my ($app, $context) = @_;
             # Do some after dispatch logic
             return 1;
         }
    ]);

See L<Slick::Events> for a list of all of the events.

See L<Slick::Route> C<on> method for more information about route event handling.

See L<Slick::Context> for more ways to handle routing and HTTP lifecycles.

=head2 on

    $s->on(before_dispatch => sub {
        my ($app, $context) = @_;
        # do stuff before routing logic has been handled
        return 1;
    });

    $s->on(after_dispatch => sub {
        my ($app, $context) = @_;
        # do stuff after routing logic has been handled
        return 1;
    });

Registers an event listener globally across the entire application. If a registered event handler
returns a C<falsy> value, the route chain will stop and the current context will be returned as the response.

See L<Slick::Events> for a list of available events.

Inherited from L<Slick::EventHandler>.

=head1 See also

=over 2

=item * L<Slick::Router>

=item * L<Slick::Context>

=item * L<Slick::Database>

=item * L<Slick::DatabaseExecutor>

=item * L<Slick::DatabaseExecutor::MySQL>

=item * L<Slick::DatabaseExecutor::Pg>

=item * L<Slick::EventHandler>

=item * L<Slick::Events>

=item * L<Slick::Methods>

=item * L<Slick::RouteMap>

=item * L<Slick::Util>

=item * L<Slick::Error>

=back

=cut
