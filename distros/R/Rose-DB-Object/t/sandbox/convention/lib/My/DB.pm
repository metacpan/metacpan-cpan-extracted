# Rose::DB subclass to handle the db connection
package My::DB;
use strict;
use base 'Rose::DB';

__PACKAGE__->use_private_registry;

My::DB->register_db
(
  type     => 'default',
  domain   => 'default',
  driver   => 'Pg',
  database => 'test',
  username => 'postgres',
);

1;
