
=head1 DESCRIPTION

This tests the Mojolicious::Plugin::DBIC class

=cut

use Mojo::Base -strict;
use Test::More;
use Test::Mojo;
use FindBin qw( $Bin );
use lib "$Bin/lib";

$ENV{MOJO_HOME} = $Bin;

# Schema from config, just DSN
my $t = Test::Mojo->new( 'Mojolicious', {
    dbic => { schema => { 'Local::Schema' => 'dbi:SQLite::memory:' } },
} );
$t->app->plugin( 'DBIC' );
my $schema;
eval { $schema = $t->app->schema };
ok !$@, 'schema helper lives' or diag $@;
isa_ok $schema, 'Local::Schema', 'schema object returned';

ok grep( { $_ eq 'Mojolicious::Plugin::DBIC::Controller' } @{ $t->app->routes->namespaces } ),
    'controller namespace is added';

# Schema from config, connect() args
$t = Test::Mojo->new( 'Mojolicious', {
    dbic => {
        schema => {
            'Local::Schema' => [
                'dbi:SQLite::memory:', undef, undef, { RaiseError => 1 },
            ],
        },
    },
} );
$t->app->plugin( 'DBIC' );
eval { $schema = $t->app->schema };
ok !$@, 'schema helper lives' or diag $@;
isa_ok $schema, 'Local::Schema', 'schema object returned';
is_deeply $schema->storage->connect_info,
    [ 'dbi:SQLite::memory:', undef, undef, { RaiseError => 1 } ],
    'connect info is correct';

# Schema override from plugin
$t = Test::Mojo->new( 'Mojolicious', {
    dbic => { schema => { 'Local::Schema' => 'dbi:SQLite::memory:' } },
} );
my $given_schema = Local::Schema->connect(
    'dbi:SQLite::memory:', undef, undef,
    { RaiseError => 1 },
);
$t->app->plugin( 'DBIC', { schema => $given_schema } );
eval { $schema = $t->app->schema };
ok !$@, 'schema helper lives' or diag $@;
isa_ok $schema, 'Local::Schema', 'schema object returned';
is_deeply $schema->storage->connect_info,
    [ 'dbi:SQLite::memory:', undef, undef, { RaiseError => 1 } ],
    'connect info is correct';

# Unknown schema class
$t = Test::Mojo->new( 'Mojolicious', {
    dbic => { schema => { 'Local::NotASchema' => 'dbi:SQLite::memory:' } },
} );
$t->app->plugin( 'DBIC' );
eval { $schema = $t->app->schema };
ok $@, 'schema helper dies';
like $@, qr{Unable to load schema class Local::NotASchema:},
    'error is correct and contains schema class';

# Unknown schema config type
$t = Test::Mojo->new( 'Mojolicious', {
    dbic => { schema => [ 'Local::Schema' => 'dbi:SQLite::memory:' ] },
} );
$t->app->plugin( 'DBIC' );
eval { $schema = $t->app->schema };
ok $@, 'schema helper dies';
like $@, qr{Unknown DBIC schema config. Must be schema object or HASH, not ARRAY},
    'error is correct and contains what ref type we got';


done_testing;
