use strict;
use warnings;

use lib 't/lib';

use Test::More tests => 6;

use constant DOMAIN_CONFIG_PATH => 't/config/domain_config.yaml';
my %DATA_SRC_ONE = ( domain => 'dev-local',  type => 'taxonomy' );

# Import with data source auto-registration...
use My::DB::Species
    domain_config   => DOMAIN_CONFIG_PATH;

ok( my $db = My::DB::Species->new_or_cached( %DATA_SRC_ONE ),
    'new_or_cached'
);
isa_ok( $db, 'My::DB::Species' );
isa_ok( $db, 'My::DB' );
isa_ok( $db, 'Rose::DBx::RegistryConfig' );
isa_ok( $db, 'Rose::DB' );

ok( my @species = $db->get_species_list(),
    'custom query in local subclass'
);
