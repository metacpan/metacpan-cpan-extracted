#!perl
#
# Test config file in module directory

package My::Dist::Test;

use parent 'Rose::DBx::MoreConfig';

__PACKAGE__->use_private_registry;

__PACKAGE__->register_db(
    domain   => 'test',
    type     => 'dist_test',
    driver   => 'Generic',
    database => 'test_me_dist'
);

__PACKAGE__->auto_load_fixups;

1;
