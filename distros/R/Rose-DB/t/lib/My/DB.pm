package My::DB;

use Rose::DB;
our @ISA = qw(Rose::DB);

__PACKAGE__->register_db(
  domain   => 'somedomain',
  type     => 'sometype',
  driver   => 'Pg',
  database => 'test',
  host     => 'localhost',
  username => 'postgres',
  password => '',
);

__PACKAGE__->register_db(
  domain   => 'otherdomain',
  type     => 'othertype',
  driver   => 'Pg',
  database => 'test2',
  host     => 'localhost',
  username => 'postgres',
  password => '',
);

__PACKAGE__->auto_load_fixups;

1;
