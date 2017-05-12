
# Demonstrate and test simple direct usage of Rose::DBx::RegistryConfig (even
# though it will usually be used through a "local" subclass)...

use strict;
use warnings;

use lib 'lib';

use Test::More tests => 8;
use Test::Deep;

#~~~~ ((( begin test initialization ))) ~~~~
use constant DOMAIN_CONFIG_PATH     => 't/config/domain_config.yaml';
use constant DEFAULT_DOMAIN         => 'default';
use constant DEFAULT_TYPE           => 'default';
use constant SELECT_SPECIES_QUERY   => q{
    SELECT id, name
    FROM species
    WHERE name = ?
};
use constant TEST_SELECT_VALUE      => 'Accipiter striatus';
#~~~~ ((( end test initialization ))) ~~~~

# Data sources used in the tests below...
my %DATA_SRC_ONE = ( domain => 'dev-local',  type => 'taxonomy' );
my %DATA_SRC_TWO = ( domain => 'dev-local',  type => 'art_gallery' );

# Import with data source auto-registration...
use Rose::DBx::RegistryConfig
    default_domain  => DEFAULT_DOMAIN,
    default_type    => DEFAULT_TYPE,
    domain_config   => DOMAIN_CONFIG_PATH;

# Save the registry parsed from DOMAIN_CONFIG...
# (it can be reused for multiple Rose::DBx::RegistryConfig subclasses)
my $registry = Rose::DBx::RegistryConfig->registry();

# Compare newly-created registry with the one parsed from DOMAIN_CONFIG upon import)
ok( my $independently_built_registry = Rose::DBx::RegistryConfig->conf2registry( domain_config => DOMAIN_CONFIG_PATH ),
    'build registry from file'
);
cmp_deeply( $independently_built_registry->dump(), $registry->dump(),
    'registry that constructor attached to the new object is identical to the one built independently using the same settings'
);
ok( my $db = Rose::DBx::RegistryConfig->new_or_cached( %DATA_SRC_ONE ),
    'initial call to Rose::DBx::RegistryConfig::new_or_cached()'
);
isa_ok( $db, 'Rose::DBx::RegistryConfig' );

# When new_or_cached() is called on a data source that has previously been used in
# a new_or_cached() call, cached object should be returned...
ok( my $db_cached = Rose::DBx::RegistryConfig->new_or_cached( %DATA_SRC_ONE ),
    'get PREVIOUSLY-CACHED Rose::DBx::RegistryConfig with new_or_cached()'
);
cmp_deeply( $db, shallow( $db_cached ),
    'new_or_cached() returns same (cached) RDB object as previously created'
);
# When new_or_cached() is called subsequent to initial call and using a data
# source that has not yet been used in a new_or_cached() call, new object
# should be created and cached...
ok( my $art_gallery_db = Rose::DBx::RegistryConfig->new_or_cached( %DATA_SRC_TWO ),
    'get NEW (NOT YET CACHED) Rose::DBx::RegistryConfig with new_or_cached()'
);
# Test executing some SQL inline...
my $selected = $db->dbh->selectrow_hashref( SELECT_SPECIES_QUERY, undef, TEST_SELECT_VALUE );
is( $selected->{name}, TEST_SELECT_VALUE,
    'SELECT from table using plain Rose::DBx::RegistryConfig object'
);

