#!perl
#
# Test config file via $ENV{ROSEDBRC}

package My::EnvTest;

use parent 'Rose::DBx::MoreConfig';

use FindBin;
use File::Spec;

__PACKAGE__->use_private_registry;

__PACKAGE__->register_db(
    domain   => 'test',
    type     => 'env_test',
    driver   => 'Generic',
    database => 'test_me_env'
);

local $ENV{ROSEDBRC} = File::Spec->catfile( $FindBin::Bin, 'lib', '.rosedbrc' );
__PACKAGE__->auto_load_fixups;

1;
