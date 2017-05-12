
# Demonstrate and test the capability of Rose::DBx::RegistryConfig to
# recognize novel "data source namespace" designs using a subclass that
# overrides the default DOMAIN_PARSER...

use strict;
use warnings;

use lib 't/lib';

use Test::More tests => 3;

use constant DOMAIN_CONFIG_PATH => 't/config/domain_config_sqlite.yaml';
use constant TAXONOMY_DBNAME    => 't/db/taxonomy.sqlite';

use_ok( 'My::DB' );

ok( my $independently_built_registry = My::DB->conf2registry(
        domain_config   => DOMAIN_CONFIG_PATH,
    ),
    'build registry from file'
);
is( $independently_built_registry->entry(
        domain => 'dev-local-sqlite',
        type => 'taxonomy'
    )->database( ),
    TAXONOMY_DBNAME,
    'properly assumed database name default according to example SQLite rules'
);

