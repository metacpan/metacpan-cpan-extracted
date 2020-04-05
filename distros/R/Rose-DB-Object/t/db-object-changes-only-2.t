#!/usr/bin/perl -w

use strict;

use Test::More tests => 2 + (71 * 4);

require 't/test-lib.pl';
use_ok('Rose::DB::Object');
use_ok('Rose::DB::Object::Loader');

my $Include_Tables = '^(?:' . join('|', qw(rose_db_object_test)) . ')$';
$Include_Tables = qr($Include_Tables);

use Rose::DB::Object::Util qw(:all);

our $PG_HAS_CHKPASS;

my %Value =
(
  1  => 'varchar val',
  2  => 'char val',
  3  => 1,
  4  => 4.25,
  5  => '10111',
  6  => 78.25,
  7  => '1984-01-24',
  8  => '1999-05-20 03:04:05',
  9  => '2 years',
  10 => [ 5, 6 ],
  11 => 24,
  12 => '922337203685',
  13 => '1009539509',
);

my %Default =
(
  1  => 'varchar-def',
  2  => 'char def        ',
  3  => 1,
  4  => 1.25,
  5  => '00101',
  6  => 123.25,
  7  => '2001-02-03',
  8  => '2001-02-03 12:34:56',
  9  => '@ 2 months 5 days 3 seconds',
  10 => [ 3, 4 ],
  11 => 123,
  12 => '922337203685',
  13 => '1973-02',
);

my %Method =
(
  5  => 'to_Bin',
  7  => 'ymd',
  8  => sub { shift; shift->strftime('%Y-%m-%d %H:%M:%S') },
  9  => sub { shift->db->format_interval(shift) },
  13 => sub { shift; shift->strftime('%Y-%m') },
);

#
# Tests
#

foreach my $db_type (qw(pg mysql informix sqlite))
{
  unless(have_db($db_type))
  {
    SKIP: { skip("$db_type tests", 71) }
    next;
  }

  Rose::DB::Object::Metadata->unregister_all_classes;

  Rose::DB->default_type($db_type);

  my $class_prefix = 'My' . ucfirst($db_type);

  my $loader = 
    Rose::DB::Object::Loader->new(
    db_class       => 'Rose::DB',
    class_prefix   => $class_prefix,
    include_tables => $Include_Tables);

  $loader->make_classes;

  my $class = $class_prefix . '::RoseDbObjectTest';

  $class->meta->replace_column(c13 => { type => 'epoch' });
  $class->meta->replace_column(c13d => { type => 'epoch', default => 99539509 });

  $class->meta->initialize(replace_existing => 1);
  #print $class->meta->perl_class_definition;

  add_nonpersistent_columns_and_methods($class);

  my $num_cols = 14;

  foreach my $n (1 .. $num_cols)
  {
    my $col = "c$n";
    my $def = "c${n}d";

    SKIP:
    {
      skip("column $n", 5)  unless($class->meta->column($col));
    }

    next  unless($class->meta->column($col));

    my $o = $class->new;

    $o->save;

    ok(!has_modified_columns($o), "has_modified_columns $col 1 - $db_type");

    $o->$col($Value{$n});

    is_deeply([ modified_column_names($o) ], [ $col ], "modified column $col 1 - $db_type");

    foreach my $n (14 .. $num_cols)
    {
      my $col = "c$n";
      my $def = "c${n}d";

      next  unless($class->meta->column($col));

      my $val = $o->$col();
      $val = $o->$def();
    }

    is_deeply([ modified_column_names($o) ], [ $col ], "modified column $col 2 - $db_type");      

    #local $Rose::DB::Object::Debug = 1;
    $o->update(changes_only => 1);
    #local $Rose::DB::Object::Debug = 0;

    modify_nonpersistent_column_values($o);

    ok(!has_modified_columns($o), "has_modified_columns $col 2 - $db_type");

    $o = $class->new(id => $o->id)->load;

    if(ref $Default{$n})
    {
      is_deeply(scalar $o->$def(), $Default{$n}, "check default $def 1 - $db_type");
    }
    else
    {
      my $method = $Method{$n};

      my $value;

      if(defined $method)
      {
        if(ref $method eq 'CODE')
        {
          $value = $method->($o, $o->$def());
        }
        else
        {
          $value = $o->$def()->$method();
        }
      }
      else
      {
        $value = $o->$def;
      }

      if($db_type eq 'mysql' && $n == 2 && $o->db->database_version < 5_000_000)
      {
        $value .= '        '; # MySQL < 5 seems to mess up CHAR fields
      }

      if(defined $Default{$n})
      {
        ok($value =~ /^\+?$Default{$n}$/, "check default $def 1 - $db_type");
      }
      else
      {
        is($value, $Default{$n}, "check default $def 1 - $db_type");
      }
    }

    if($n == 14 && $db_type eq 'pg')
    {
      ok($o->c14d_is('xyzzy'), "chkpass default - $db_type");
    }
    elsif($n == 13 &&  $db_type eq 'pg' && !$PG_HAS_CHKPASS)
    {
      ok(1, "no chkpass - $db_type");
    }
    elsif($n == 1 && $db_type ne 'pg')
    {
      ok(1, "chkpass skipped - $db_type");
    }
  }
}

BEGIN
{
  require 't/test-lib.pl';

  #
  # PostgreSQL
  #

  if(have_db('pg_admin'))
  {
    my $dbh = get_dbh('pg_admin');

    # Drop existing tables, ignoring errors
    {
      local $dbh->{'RaiseError'} = 0;
      local $dbh->{'PrintError'} = 0;
      $dbh->do('DROP TABLE rose_db_object_test');
    }

    our $PG_HAS_CHKPASS = pg_has_chkpass();

    $dbh->do(<<"EOF");
CREATE TABLE rose_db_object_test
(
  id    SERIAL NOT NULL PRIMARY KEY,
  c1    VARCHAR(255),
  c1d   VARCHAR(255) DEFAULT 'varchar-def',
  c2    CHAR(16),
  c2d   CHAR(16) DEFAULT 'char def',
  c3    BOOLEAN,
  c3d   BOOLEAN DEFAULT 't',
  c4    FLOAT,
  c4d   FLOAT DEFAULT 1.25,
  c5    BIT(5),
  c5d   BIT(5) DEFAULT B'00101',
  c6    DECIMAL(10,2),
  c6d   DECIMAL(10,2) DEFAULT 123.25,
  c7    DATE,
  c7d   DATE DEFAULT '2001-02-03',
  c8    TIMESTAMP,
  c8d   TIMESTAMP DEFAULT '2001-02-03 12:34:56',
  c9    INTERVAL(6),
  c9d   INTERVAL(6) DEFAULT '2 months 5 days 3 seconds',
  c10   INT[],
  c10d  INT[] DEFAULT '{3,4}',
  c11   INT,
  c11d  INT DEFAULT 123,
  c12   BIGINT,
  c12d  BIGINT DEFAULT 922337203685,
  c13   INT,
  c13d  INT DEFAULT 99539509

  @{[ $PG_HAS_CHKPASS ? q(, c14 CHKPASS, c14d CHKPASS DEFAULT 'xyzzy') : '' ]}
)
EOF

    $dbh->disconnect;
  }

  #
  # MySQL
  #

  my $db_version;

  eval
  {
    my $dbh = get_dbh('mysql_admin');

    local $dbh->{'RaiseError'} = 0;
    local $dbh->{'PrintError'} = 0;
    $dbh->do('DROP TABLE rose_db_object_test');
  };

  if(have_db('mysql_admin'))
  {
    my $db  = get_db('mysql_admin');
    my $dbh = $db->retain_dbh;

    my $bool_columns = ($db->database_version >= 5_000_000) ?
        qq(c3    BOOLEAN,\n  c3d   BOOLEAN DEFAULT 1,) : '';

    $dbh->do(<<"EOF");
CREATE TABLE rose_db_object_test
(
  id    INT AUTO_INCREMENT PRIMARY KEY,
  c1    VARCHAR(255),
  c1d   VARCHAR(255) DEFAULT 'varchar-def',
  c2    CHAR(16),
  c2d   CHAR(16) DEFAULT 'char def',
  $bool_columns
  c4    FLOAT,
  c4d   FLOAT DEFAULT 1.25,
  c6    DECIMAL(10,2),
  c6d   DECIMAL(10,2) DEFAULT 123.25,
  c7    DATE,
  c7d   DATE DEFAULT '2001-02-03',
  c8    DATETIME,
  c8d   DATETIME DEFAULT '2001-02-03 12:34:56',
  c11   INT,
  c11d  INT DEFAULT 123,
  c12   BIGINT,
  c12d  BIGINT DEFAULT 922337203685,
  c13   INT,
  c13d  INT DEFAULT 99539509
)
EOF

    $dbh->disconnect;
  }

  #
  # Informix
  #

  if(have_db('informix_admin'))
  {
    my $dbh = get_dbh('informix_admin');

    # Drop existing tables, ignoring errors
    {
      local $dbh->{'RaiseError'} = 0;
      local $dbh->{'PrintError'} = 0;
      $dbh->do('DROP TABLE rose_db_object_test');
    }

    $dbh->do(<<"EOF");
CREATE TABLE rose_db_object_test
(
  id    SERIAL NOT NULL PRIMARY KEY,
  c1    VARCHAR(255),
  c1d   VARCHAR(255) DEFAULT 'varchar-def',
  c2    CHAR(16),
  c2d   CHAR(16) DEFAULT 'char def',
  c3    BOOLEAN,
  c3d   BOOLEAN DEFAULT 't',
  c6    DECIMAL(10,2),
  c6d   DECIMAL(10,2) DEFAULT 123.25,
  c7    DATE,
  c7d   DATE DEFAULT '02/03/2001',
  -- DBD::Informix can't handle this default value, apparently...
  -- c8    DATETIME YEAR TO SECOND,
  -- c8d   DATETIME YEAR TO SECOND DEFAULT DATETIME(2001-02-03 12:34:56) YEAR TO SECOND,
  c11   INT,
  c11d  INT DEFAULT 123,
  c12   INT8,
  c12d  INT8 DEFAULT 922337203685,
  c13   INT,
  c13d  INT DEFAULT 99539509
)
EOF

    $dbh->disconnect;
  }

  #
  # SQLite
  #

  if(have_db('sqlite_admin'))
  {
    my $dbh = get_dbh('sqlite_admin');

    # Drop existing tables, ignoring errors
    {
      local $dbh->{'RaiseError'} = 0;
      local $dbh->{'PrintError'} = 0;
      $dbh->do('DROP TABLE rose_db_object_test');
    }

    $dbh->do(<<"EOF");
CREATE TABLE rose_db_object_test
(
  id    INTEGER PRIMARY KEY AUTOINCREMENT,
  c1    VARCHAR(255),
  c1d   VARCHAR(255) DEFAULT 'varchar-def',
  c2    CHAR(16),
  c2d   CHAR(16) DEFAULT 'char def',
  c3    BOOLEAN,
  c3d   BOOLEAN DEFAULT 1,
  c4    REAL,
  c4d   REAL DEFAULT '1.25',
  c6    REAL,
  c6d   REAL DEFAULT '123.25',
  c7    DATE,
  c7d   DATE DEFAULT '2001-02-03',
  c8    DATETIME,
  c8d   DATETIME DEFAULT '2001-02-03 12:34:56',
  c11   INT,
  c11d  INT DEFAULT 123,
  c12   BIGINT,
  c12d  BIGINT DEFAULT 922337203685,
  c13   INT,
  c13d  INT DEFAULT 99539509
)
EOF

    $dbh->disconnect;
  }
}

END
{
  # Delete test tables

  if(have_db('pg_admin'))
  {
    my $dbh = get_dbh('pg_admin');

    $dbh->do('DROP TABLE rose_db_object_test');

    $dbh->disconnect;
  }

  if(have_db('mysql_admin'))
  {
    my $dbh = get_dbh('mysql_admin');

    $dbh->do('DROP TABLE rose_db_object_test');

    $dbh->disconnect;
  }

  if(have_db('informix_admin'))
  {
    my $dbh = get_dbh('informix_admin');

    $dbh->do('DROP TABLE rose_db_object_test');

    $dbh->disconnect;
  }

  if(have_db('sqlite_admin'))
  {
    my $dbh = get_dbh('sqlite_admin');

    $dbh->do('DROP TABLE rose_db_object_test');

    $dbh->disconnect;
  }
}
