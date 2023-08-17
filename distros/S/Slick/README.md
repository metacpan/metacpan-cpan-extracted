# [Slick](https://metacpan.org/pod/Slick)

Slick is an Object-Oriented Perl web-framework for building performant, and easy to refactor REST API's. 
Slick is built on top of [DBI](https://metacpan.org/pod/DBI), [Plack](https://metacpan.org/pod/Plack), 
and [Moo](https://metacpan.org/pod/Moo) and fits somewhere in-between the realms of Dancer and Mojo.

Slick has everything you need to build a Database driven REST API, including built in support
for Database connections, Migrations, and soon, route based Caching via Redis or Memcached. Since Slick is a Plack application,
you can also take advantage of swappable backends and Plack middlewares extremely simply.

Currently, Slick supports `MySQL` and `Postgres` but there are plans to implement `Oracle` and `MS SQL Server`.

## Philosophy

Slick is aiming to become a "Batteries Included" framework for building REST API's and Micro-Services in
Perl. This will include tooling for all sorts of Micro-Service concerns like Databases, Caching, Queues,
User-Agents, and much more.

### Goals

- [x] Database management (auto-enabled)
- [x] Migrations (auto-enabled)
- [ ] CLI
- [x] Caching via Redis (optional)
- [x] Caching via Memcached (optional)
- [ ] Sub-routine based caching for routes (optional)
- [ ] RabbitMQ built-ins (optional)
- [ ] AWS S3 support (optional)
- [ ] User-Agents, including Client API exports
- [ ] AWS SQS support (optional)

*Note*: All of these features excluding database stuff will be enabled optionally at run-time.

## Examples

### Single File App
```perl
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
    my $user = $app->database('my_db')->select_one('user', { id => $context->param('id') });

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
```

See the examples directory for this example.

### Multi-file Router App

```perl
### INSIDE lib/MyApp/ItemRouter.pm

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
    if (not $app->helper('item_validator')->validate($new_item)) {
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

### INSIDE OF YOUR RUN SCRIPT

use 5.036;
use lib 'lib';

use Slick;
use MyApp::ItemRouter;

my $slick = Slick->new;

$slick->register(MyApp::ItemRouter->router);

$slick->run;
```

See the examples directory for this example.

### Running with `plackup`

If you wish to use `plackup` you can change the final call to `run` to a call to `app`

```perl
$s->app;
```

Then simply run with plackup (substitue `my_app.psgi` with whatever your app is called):

```bash
plackup -a my_app.psgi
```

### Changing PSGI backend

Will run on the default [`HTTP::Server::PSGI`](https://metacpan.org/pod/HTTP::Server::PSGI).
```perl
$s->run;
```

or 

In this example, running Slick with a [`Gazelle`](https://metacpan.org/pod/Gazelle) backend on port `8888` and address `0.0.0.0`.
```perl
$s->run(server => 'Plack::Handler::Gazelle', port => 8888, addr => '0.0.0.0'); 
```

### Using Plack Middlewares

You can register more Plack middlewares with your application very easily!

```perl
my $s = Slick->new;

$s->middleware('Deflater')
  ->middleware('Session' => store => 'file')
  ->middleware('Debug', panels => [ qw(DBITrace Memory) ]);

$s->run; # or $s->app depending on if you want to use plackup.
```

## Managing Your Database(s)

Slick allows you to easily connect databases to your applications.

### Creating a database
```perl
my $s = Slick->new;
$s->database(my_postgres => 'postgresql://username:password@127.0.0.1:5432/db_name');
```

### Migrations

Migrations are built using the `migration` method on `Slick::Database`. You provide 1, an ID for the migration,
2, the runnable/happy side of the migrations, and 3, the down or reverse of the migration.

```perl
$s->database('my_postgres')
  ->migration('create_users_table',
  'CREATE TABLE users ( id INT PRIMARY KEY, name TEXT, age INT );',
  'DROP TABLE user;')
  ->migration('create_pets_table',
  'CREATE TABLE pets ( id INT PRIMARY KEY, name TEXT, owner INT FOREIGN KEY REFERENCES users (id) );',
  'DROP TABLE pets;');
```

### Queries

Queries in Slick are built with [`SQL::Abstract`](https://metacpan.org/pod/SQL::Abstract), and most of the heavy lifting
is done for you already!

```perl
my $users = $s->database('my_postgres')
              ->select('users', [ 'id', 'name' ]); # SELECT id, name FROM users;

my $user = $s->database('my_postgres')
             ->select_one('users', [ 'id', 'name', 'age' ], { id => 1 }); # SELECT id, name, age FROM users WHERE id = 1;
             
$s->database('my_postgres')
  ->insert('users', { name => 'Bob', age => 23 }); # INSERT INTO users (name, age) VALUES ('Bob', 23);
  
$s->database('my_postgres')
  ->update('users', { name => 'John' }, { id => 2 }); # UPDATE users SET name = 'John' WHERE id = 2;
```

If you can't do what you want with `SQL::Abstract` helpers, you can certainly do it with DBI!

```perl
$s->database('my_postgres')->dbi->execute('DROP TABLE users;');
```

## Caching

Slick supports caching using [`Memcached`](https://memcached.org) or [`Redis`](https://redis.io).

```perl
use 5.036;

use Slick;

my $s = Slick->new;

# See Redis and Cache::Memcached on CPAN for arguments

# Create a Redis instance
$s->cache(
    my_redis => type => 'redis',    # Slick Arguments
    server   => '127.0.0.1:6379'    # Cache::Memcached arguments
);

# Create a Memcached instance
$s->cache(
    my_memcached => type          => 'memcached',   # Slick Arguments
    servers      => ['127.0.0.1'] => debug => 1     # Cache::Memcached arguments
);

$s->cache('my_redis')->set( something => 'awesome' );

$s->get(
    '/foo' => sub {
        my ( $app, $context ) = @_;
        my $value = $app->cache('my_redis')->get('something');  # Use your cache
        return $context->text($value);
    }
);

$s->run;
```

## Deployment

Please follow a standard `Plack` application deployment. Reverse-proxying your application behind
[`NGiNX`](https://nginx.org) or [`Caddy`](https://caddyserver.com) and using [`Docker`](https://www.docker.com) can
drastically improve your deployment.

An example `Dockerfile` can be found in the examples directory.

## Contributing

Slick is open to any and all contributions.

**Code Standards**:

* Always format with the provided `.perltidyrc`
* Always use `Perl::Critic` set to severity `3`
* Unpack subroutine arguments using array-destructuring when there are greater than 2 arguments

## License

Slick is provided under the Artistic 2.0 license.
