use Mojo::Base -strict;
use Test::More;
use Mojo::DB::Connector;

note 'Test defaults with no $ENV';
my $connector = Mojo::DB::Connector->new;
is $connector->env_prefix, 'MOJO_DB_CONNECTOR_', 'MOJO_DB_CONNECTOR_ is default env_prefix';
is $connector->scheme, 'postgresql', 'postgresql is default scheme';
is $connector->userinfo, '', 'empty string is default userinfo';
is $connector->host, 'localhost', 'localhost is default host';
is $connector->port, 5432, '5432 is default port';
is $connector->database, '', 'empty string is default database';
is_deeply $connector->options, [], '[] is default options';
is $connector->url, undef, 'undef is default url';
is $connector->strict_mode, 1, '1 is default strict_mode';

note 'Test defaults with $ENV';
$ENV{MOJO_DB_CONNECTOR_SCHEME} = 'mariadb';
$ENV{MOJO_DB_CONNECTOR_USERINFO} = 'sri:s3cret';
$ENV{MOJO_DB_CONNECTOR_HOST} = 'batman.com';
$ENV{MOJO_DB_CONNECTOR_PORT} = '3306';
$ENV{MOJO_DB_CONNECTOR_DATABASE} = 'my_database';
$ENV{MOJO_DB_CONNECTOR_OPTIONS} = 'RaiseError=0&PrintError=1';
$ENV{MOJO_DB_CONNECTOR_STRICT_MODE} = 0;

my $env_connector = Mojo::DB::Connector->new;
is $env_connector->scheme, 'mariadb', 'mariadb is default scheme';
is $env_connector->userinfo, 'sri:s3cret', 'sri:s3cret is default userinfo';
is $env_connector->host, 'batman.com', 'batman.com is default host';
is $env_connector->port, 3306, '3306 is default port';
is $env_connector->database, 'my_database', 'my_database is default database';
is_deeply $env_connector->options, [RaiseError => 0, PrintError => 1], '[RaiseError => 0, PrintError => 1] is default options';
is $env_connector->url, undef, 'undef is default url';
is $env_connector->strict_mode, 0, '0 is default strict_mode';

note 'Test env_prefix with defaults';
$ENV{SECRET_PREFIX_SCHEME} = 'mysql';
$ENV{SECRET_PREFIX_USERINFO} = 'batman:s3cret';
$ENV{SECRET_PREFIX_HOST} = 'mojolicious.org';
$ENV{SECRET_PREFIX_PORT} = '1234';
$ENV{SECRET_PREFIX_DATABASE} = 'my_secret_database';
$ENV{SECRET_PREFIX_OPTIONS} = 'PrintError=1&RaiseError=0';
$ENV{SECRET_PREFIX_STRICT_MODE} = 0;

my $env_prefix_connector = Mojo::DB::Connector->new(env_prefix => 'SECRET_PREFIX_');
is $env_prefix_connector->scheme, 'mysql', 'mysql is default scheme';
is $env_prefix_connector->userinfo, 'batman:s3cret', 'batman:s3cret is default userinfo';
is $env_prefix_connector->host, 'mojolicious.org', 'mojolicious.org is default host';
is $env_prefix_connector->port, 1234, '1234 is default port';
is $env_prefix_connector->database, 'my_secret_database', 'my_secret_database is default database';
is_deeply $env_prefix_connector->options, [PrintError => 1, RaiseError => 0], '[PrintError => 1, RaiseError => 0] is default options';
is $env_prefix_connector->url, undef, 'undef is default url';
is $env_prefix_connector->strict_mode, 0, '0 is default strict_mode';

$ENV{URL_PREFIX_URL} = 'mariadb://sr1:s3kr1t@planetexpress.com:3000/orders?Human=Fry&Robot=Bender';
my $url_connector = Mojo::DB::Connector->new(env_prefix => 'URL_PREFIX_');
is $url_connector->scheme, 'mariadb', 'mariadb is default scheme';
is $url_connector->userinfo, 'sr1:s3kr1t', 'sr1:s3kr1t is default userinfo';
is $url_connector->host, 'planetexpress.com', 'planetexpress.com is default host';
is $url_connector->port, 3000, '3000 is default port';
is $url_connector->database, 'orders', 'orders is default database';
is_deeply $url_connector->options, [Human => 'Fry', Robot => 'Bender'], q{[Human => 'Fry', Robot => 'Bender'] is default options};
isa_ok $url_connector->url, 'Mojo::URL', 'url is a Mojo::URL';
is $url_connector->url->to_unsafe_string, $ENV{URL_PREFIX_URL}, 'expected unsafe URL';
is $url_connector->strict_mode, 1, '1 is default strict_mode';

done_testing;
