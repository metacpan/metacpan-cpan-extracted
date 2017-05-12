#!perl
#
# Test config file in "home" directory

package My::HomeTest;

use parent 'Rose::DBx::MoreConfig';

__PACKAGE__->use_private_registry;

__PACKAGE__->register_db(
    domain   => 'test',
    type     => 'home_test',
    driver   => 'Generic',
    database => 'test_me_home'
);

__PACKAGE__->auto_load_fixups;

1;
