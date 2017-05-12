#!/usr/bin/perl -w

use strict;

use Test::More tests => 6;

BEGIN 
{
  require 't/test-lib.pl';
  use_ok('Rose::DB::Object');
  use_ok('Rose::DB::Object::Loader');
}

our %Have;

#
# Tests
#

foreach my $db_type (qw(mysql))
{
  SKIP:
  {
    skip("$db_type tests", 4)  unless($Have{$db_type});
  }

  next  unless($Have{$db_type});

  Rose::DB->default_type($db_type);

  my $class_prefix =  ucfirst($db_type);

  my $loader = 
    Rose::DB::Object::Loader->new(
      db           => Rose::DB->new,
      class_prefix => $class_prefix,
      include_tables => [ qw(users user_connections) ]);

  my @classes = $loader->make_classes;

  #foreach my $class (@classes)
  #{
  #  print $class->meta->perl_class_definition(braces => 'k&r', indent => 2)
  #    if($class->can('meta'));
  #}

  my $user_connection_class = $class_prefix . '::UserConnection';

  my @fks = sort { $a->name cmp $b->name } $user_connection_class->meta->foreign_keys;

  is_deeply(scalar $fks[0]->key_columns, { from_id => 'id' }, "fk 1.1 - $db_type");
  is($fks[0]->name, 'from', "fk 1.2 - $db_type");

  is_deeply(scalar $fks[1]->key_columns, { to_id => 'id' }, "fk 2.1 - $db_type");
  is($fks[1]->name, 'to', "fk 2.2 - $db_type");
}

BEGIN
{
  our %Have;

  my $dbh;

  #
  # MySQL
  #

  if(have_db('mysql') && mysql_supports_innodb())
  {
    $Have{'mysql'} = 1;

    $dbh = get_dbh('mysql_admin');

    # Drop existing tables, ignoring errors
    {
      local $dbh->{'RaiseError'} = 0;
      local $dbh->{'PrintError'} = 0;
      $dbh->do('DROP TABLE user_connections');
      $dbh->do('DROP TABLE users');
    }

    $dbh->do(<<"EOF");
CREATE TABLE users
(
  id    INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  name  VARCHAR(255) NOT NULL,

  UNIQUE(name)
)
ENGINE=InnoDB
EOF

    $dbh->do(<<"EOF");
create table user_connections
(
  id      INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  from_id INT UNSIGNED NOT NULL,
  to_id   INT UNSIGNED NOT NULL,

  UNIQUE KEY (from_id, to_id),
  KEY (to_id),

  CONSTRAINT FOREIGN KEY (from_id) REFERENCES users (id),
  CONSTRAINT FOREIGN KEY (to_id) REFERENCES users (id)
)
ENGINE=InnoDB;
EOF

    $dbh->disconnect;
  }
}

END
{
  # Delete test tables
  if($Have{'mysql'})
  {
    my $dbh = get_dbh('mysql_admin');
    $dbh->do('DROP TABLE user_connections');
    $dbh->do('DROP TABLE users');
    $dbh->disconnect;
  }
}
