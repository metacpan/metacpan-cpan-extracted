#!/usr/bin/perl -w

use strict;

use Test::More tests => 2 + (1 * 1);

BEGIN 
{
  require 't/test-lib.pl';
  use_ok('Rose::DB');
  use_ok('Rose::DB::Object::Loader');
}

our %Have;

our @Tables = qw(attribute_types datatypes);
our $Include_Tables = join('|', @Tables);

#
# Tests
#

my $i = 1;

foreach my $db_type (qw(mysql))
{
  SKIP:
  {
    skip("$db_type tests", 1)  unless($Have{$db_type});
  }

  next  unless($Have{$db_type});

  $i++;


  my $class_prefix = ucfirst($db_type);

  #$Rose::DB::Object::Metadata::Debug = 1;

  my $db = Rose::DB->new($db_type);

  my $loader = 
    Rose::DB::Object::Loader->new(
      db           => $db,
      class_prefix => $class_prefix);

  # This call used to die prior to 0.7663
  my @classes = $loader->make_classes(include_tables => $Include_Tables);

  is(scalar @classes, 4, "make_classes - $db_type");

  #foreach my $class (@classes)
  #{
  #  if($class->can('meta'))
  #  {
  #    print $class->meta->perl_class_definition;
  #  }
  #  else
  #  {
  #    print $class->perl_class_definition;
  #  }
  #}

  #$DB::single = 1;
  #$Rose::DB::Object::Debug = 1;
}

BEGIN
{
  our %Have;

  my $dbh;

  #
  # MySQL
  #

  eval 
  {
    my $db = Rose::DB->new('mysql_admin');
    $dbh = $db->retain_dbh or die Rose::DB->error;

    die "MySQL version too old"  unless($db->database_version >= 4_000_000);

    # Drop existing tables, ignoring errors
    {
      local $dbh->{'RaiseError'} = 0;
      local $dbh->{'PrintError'} = 0;

      $dbh->do('ALTER TABLE attribute_types DROP FOREIGN KEY attribute_types_ibfk_1');
      $dbh->do('ALTER TABLE datatypes DROP FOREIGN KEY datatypes_ibfk_1');
      $dbh->do('DROP TABLE attribute_types CASCADE');
      $dbh->do('DROP TABLE datatypes CASCADE');
    }

    # Foreign key stuff requires InnoDB support
    $dbh->do(<<"EOF");
CREATE TABLE attribute_types
(
  id           BIGINT(20) UNSIGNED NOT NULL auto_increment,
  name         VARCHAR(255) NOT NULL,
  table_name   VARCHAR(255) NOT NULL,
  datatype_id  BIGINT(20) UNSIGNED NOT NULL,

  PRIMARY KEY (id),
  KEY name (name),
  KEY datatype_id (datatype_id)
)
ENGINE=InnoDB DEFAULT CHARSET=latin1 AUTO_INCREMENT=1
EOF

    # MySQL will silently ignore the "ENGINE=InnoDB" part and create
    # a MyISAM table instead.  MySQL is evil!  Now we have to manually
    # check to make sure an InnoDB table was really created.
    my $db_name = $db->database;
    my $sth = $dbh->prepare("SHOW TABLE STATUS FROM `$db_name` LIKE ?");
    $sth->execute('attribute_types');
    my $info = $sth->fetchrow_hashref;

    no warnings 'uninitialized';
    unless(lc $info->{'Type'} eq 'innodb' || lc $info->{'Engine'} eq 'innodb')
    {
      die "Missing InnoDB support";
    }
  };

  if(!$@ && $dbh)
  {
    $Have{'mysql'} = 1;

    $dbh->do(<<"EOF");
CREATE TABLE datatypes
(
  id      BIGINT(20) UNSIGNED NOT NULL AUTO_INCREMENT,
  name    VARCHAR(255) NOT NULL,
  format  VARCHAR(255) NOT NULL default '.*',

  PRIMARY KEY (id),
  UNIQUE KEY name (name)
)
ENGINE=InnoDB DEFAULT CHARSET=latin1 AUTO_INCREMENT=1
EOF

$dbh->do(<<"EOF");
ALTER TABLE attribute_types ADD CONSTRAINT attribute_types_ibfk_1 
  FOREIGN KEY (datatype_id) REFERENCES datatypes (id)
EOF

$dbh->do(<<"EOF");
ALTER TABLE datatypes ADD CONSTRAINT datatypes_ibfk_1 
  FOREIGN KEY (id) REFERENCES attribute_types (datatype_id) 
  ON DELETE CASCADE ON UPDATE NO ACTION
EOF

    $dbh->disconnect;
  }
}

END
{
  # Delete test table

  if($Have{'mysql'})
  {
    # MySQL
    my $dbh = Rose::DB->new('mysql_admin')->retain_dbh()
      or die Rose::DB->error;

    $dbh->do('ALTER TABLE attribute_types DROP FOREIGN KEY attribute_types_ibfk_1');
    $dbh->do('ALTER TABLE datatypes DROP FOREIGN KEY datatypes_ibfk_1');
    $dbh->do('DROP TABLE attribute_types CASCADE');
    $dbh->do('DROP TABLE datatypes CASCADE');

    $dbh->disconnect;
  }
}
