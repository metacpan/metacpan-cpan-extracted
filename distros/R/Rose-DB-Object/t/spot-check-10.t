#!/usr/bin/perl -w

use strict;

use Test::More tests => 2 + (6 * 1);

BEGIN 
{
  require 't/test-lib.pl';
  use_ok('Rose::DB::Object::Loader');
  use_ok('Rose::DB::Object::Helpers');
}

our %Have;

#
# Tests
#

#$Rose::DB::Object::Manager::Debug = 1;

foreach my $db_type (qw(pg))
{
  SKIP:
  {
    skip("$db_type tests", 6)  unless($Have{$db_type});
  }

  next  unless($Have{$db_type});

  Rose::DB->default_type($db_type);

  my $class_prefix = ucfirst($db_type);

  my $loader = 
    Rose::DB::Object::Loader->new(
      db           => Rose::DB->new,
      class_prefix => $class_prefix);

  my @classes = 
    $loader->make_classes(include_tables => 
      [ qw(offering_levels offering_sequences offerings employee employer) ],
      include_map_class_relationships => 1);

  #foreach my $class (@classes)
  #{
  #  print $class->meta->perl_class_definition if($class->can('meta'));
  #}

  my $employer_class  = $class_prefix . '::Employer';
  my $offering_class = $class_prefix . '::Offering';
  my $offering_sequence_class = $class_prefix . '::OfferingSequence';
  my $offering_level_class    = $class_prefix . '::OfferingLevel';

  $employer_class->meta->column('data')->lazy(1);
  $employer_class->meta->column('data')->make_methods(replace_existing => 1);

  Rose::DB::Object::Manager->update_objects(
    set   => { name => { sql => 'upper(name)' } }, 
    where => [ name => 'Default Employer' ],
    object_class => $employer_class);

  Rose::DB::Object::Manager->update_objects(
    set   => { name => \q(name || 'x') }, 
    where => [ name => 'DEFAULT EMPLOYER' ],
    object_class => $employer_class);

  my $employer = $employer_class->new(company_code => 'TEST', data => "\0\1x\2\3");

  my @offerings =
  (
    {
      sort_order => 1,
      years      => 05,
      offering_sequences => 
      [
        {
          offering_levels => 
          [
            {
              catalog_level => 'C',
              catalog_code  => 'HZNO04',
            }
          ],
          sequence_number => 0,
          years           => 05,
          eid             => ''
        }
      ]
    },
    {
      sort_order => 2,
      years      => 10,
      offering_sequences => 
      [
        {
          offering_levels => 
          [
            {
              catalog_level => 'E',
              catalog_code  => 'HZNO04',
            }
          ],
          sequence_number => 0,
          years           => 10,
          eid             => ''
        }
      ]
    },
    {
      sort_order => 3,
      years      => 15,
      offering_sequences => 
      [
        {
          offering_levels => 
          [
            {
              catalog_level => 'H',
              catalog_code  => 'HZNO04',
            }
          ],
          sequence_number => 0,
          years           => 15,
          eid             => '',
        }
      ]
    },
    {
      sort_order => 5,
      years      => 25,
      offering_sequences => 
      [
        {
          offering_levels => 
          [
            {
              catalog_level => 'P',
              catalog_code  => 'HZNO04',
            }
          ],
          sequence_number => 0,
          years           => 25,
          eid             => '',
        }
      ]
    }
  );

  $employer->add_offerings(\@offerings);

  #$Rose::DB::Object::Debug = 1;
  #$Rose::DB::Object::Manager::Debug = 1;
  #$DB::single = 1;

  $employer->save;

  $employer = $employer_class->new(company_code => 'TEST')->load;

  is($employer->{'data'}, undef, "lazy bytea 1 - $db_type");
  is($employer->data, "\0\1x\2\3", "lazy bytea 2 - $db_type");
  $employer->data("\0\4x\3\1");

  $employer->save;

  my $employers = 
    Rose::DB::Object::Manager->get_objects(
      object_class => $employer_class,
      sort_by      => 'name');

  is_deeply([ map { scalar $_->Rose::DB::Object::Helpers::column_value_pairs } @$employers ],
  [
    {
      'name' => '',
      'company_code' => 'TEST',
      'data' => "\0\4x\3\1",
    },
    {
      'name' => 'DEFAULT EMPLOYERx',
      'company_code' => '',
      'data' => undef,
    }
  ],
  "employer check - $db_type");

  my $offerings = 
    Rose::DB::Object::Manager->get_objects(
      object_class => $offering_class,
      sort_by      => [ 'company_code', 'sort_order', 'years' ]);

  is_deeply([ map { scalar $_->Rose::DB::Object::Helpers::column_value_pairs } @$offerings ],
   [
     {
       'browse' => 1,
       'discrete_sequences' => 1,
       'sort_order' => '0',
       'years' => '05',
       'eid' => '',
       'company_code' => ''
     },
     {
       'browse' => 1,
       'discrete_sequences' => 1,
       'sort_order' => '0',
       'years' => '10',
       'eid' => '',
       'company_code' => ''
     },
     {
       'browse' => 1,
       'discrete_sequences' => 1,
       'sort_order' => '0',
       'years' => '15',
       'eid' => '',
       'company_code' => ''
     },
     {
       'browse' => 1,
       'discrete_sequences' => 1,
       'sort_order' => '1',
       'years' => '5',
       'eid' => '',
       'company_code' => 'TEST'
     },
     {
       'browse' => 1,
       'discrete_sequences' => 1,
       'sort_order' => '2',
       'years' => '10',
       'eid' => '',
       'company_code' => 'TEST'
     },
     {
       'browse' => 1,
       'discrete_sequences' => 1,
       'sort_order' => '3',
       'years' => '15',
       'eid' => '',
       'company_code' => 'TEST'
     },
     {
       'browse' => 1,
       'discrete_sequences' => 1,
       'sort_order' => '5',
       'years' => '25',
       'eid' => '',
       'company_code' => 'TEST'
     }
   ],
   "offering check - $db_type");

  my $offering_sequences = 
    Rose::DB::Object::Manager->get_objects(
      object_class => $offering_sequence_class,
      sort_by      => [ 'company_code', 'years' ]);

  is_deeply([ map { scalar $_->Rose::DB::Object::Helpers::column_value_pairs } @$offering_sequences ],
   [
     {
       'browse' => 1,
       'sequence_number' => '0',
       'years' => '05',
       'eid' => '',
       'company_code' => ''
     },
     {
       'browse' => 1,
       'sequence_number' => '0',
       'years' => '10',
       'eid' => '',
       'company_code' => ''
     },
     {
       'browse' => 1,
       'sequence_number' => '0',
       'years' => '15',
       'eid' => '',
       'company_code' => ''
     },
     {
       'browse' => 1,
       'sequence_number' => '0',
       'years' => '10',
       'eid' => '',
       'company_code' => 'TEST'
     },
     {
       'browse' => 1,
       'sequence_number' => '0',
       'years' => '15',
       'eid' => '',
       'company_code' => 'TEST'
     },
     {
       'browse' => 1,
       'sequence_number' => '0',
       'years' => '25',
       'eid' => '',
       'company_code' => 'TEST'
     },
     {
       'browse' => 1,
       'sequence_number' => '0',
       'years' => '5',
       'eid' => '',
       'company_code' => 'TEST'
     }
  ],
  "offering sequence check - $db_type");

  my $offering_levels = 
    Rose::DB::Object::Manager->get_objects(
      object_class => $offering_level_class,
      sort_by      => [ 'company_code', 'years' ]);

  is_deeply([ map { scalar $_->Rose::DB::Object::Helpers::column_value_pairs } @$offering_levels ],
   [
     {
       'browse' => 1,
       'sequence_number' => '0',
       'catalog_level' => 'E',
       'years' => '10',
       'eid' => '',
       'catalog_code' => 'HZNO04',
       'company_code' => 'TEST'
     },
     {
       'browse' => 1,
       'sequence_number' => '0',
       'catalog_level' => 'H',
       'years' => '15',
       'eid' => '',
       'catalog_code' => 'HZNO04',
       'company_code' => 'TEST'
     },
     {
       'browse' => 1,
       'sequence_number' => '0',
       'catalog_level' => 'P',
       'years' => '25',
       'eid' => '',
       'catalog_code' => 'HZNO04',
       'company_code' => 'TEST'
     },
     {
       'browse' => 1,
       'sequence_number' => '0',
       'catalog_level' => 'C',
       'years' => '5',
       'eid' => '',
       'catalog_code' => 'HZNO04',
       'company_code' => 'TEST'
     }
   ],
   "offering level check - $db_type");
}

BEGIN
{
  our %Have;

  #
  # PostgreSQL
  #

  my $dbh;

  eval 
  {
    $dbh = Rose::DB->new('pg_admin')->retain_dbh()
      or die Rose::DB->error;
  };

  if(!$@ && $dbh)
  {
    $Have{'pg'} = 1;
    $Have{'pg_with_schema'} = 1;

    # Drop existing tables and create schema, ignoring errors
    {
      local $dbh->{'RaiseError'} = 0;
      local $dbh->{'PrintError'} = 0;

      $dbh->do('DROP TABLE offering_levels CASCADE');
      $dbh->do('DROP TABLE offering_sequences CASCADE');
      $dbh->do('DROP TABLE offerings CASCADE');
      $dbh->do('DROP TABLE employee CASCADE');
      $dbh->do('DROP TABLE employer CASCADE');
    }

    my @sql =
    (
      <<"EOF",
CREATE OR REPLACE FUNCTION add_default_employee() RETURNS "trigger"
    AS '
BEGIN
    IF NEW.company_code IS NOT NULL THEN
        INSERT INTO
            employee (company_code, eid)
        VALUES (
            NEW.company_code,
            ''''
        );
    END IF;
    RETURN NEW;
END;
' LANGUAGE 'plpgsql';
EOF

      <<"EOF",
CREATE TABLE employer
(
  company_code  VARCHAR(6) DEFAULT '' NOT NULL PRIMARY KEY,
  name          VARCHAR(128) DEFAULT '' NOT NULL,
  data          BYTEA
)
EOF

      <<"EOF",
CREATE TRIGGER employer_default_employee
    AFTER INSERT ON employer
    FOR EACH ROW 
    EXECUTE PROCEDURE add_default_employee()
EOF

      <<"EOF",
CREATE TABLE employee 
(
  company_code VARCHAR(6) DEFAULT '' NOT NULL,
  eid          VARCHAR(9) DEFAULT '' NOT NULL,
  first_name   VARCHAR(15) DEFAULT '' NOT NULL,
  last_name    VARCHAR(25) DEFAULT '' NOT NULL,

  PRIMARY KEY (company_code, eid)
);
EOF

      <<"EOF",
ALTER TABLE employee ADD CONSTRAINT fk_employee_company_code 
  FOREIGN KEY (company_code) REFERENCES employer(company_code)
  ON UPDATE CASCADE ON DELETE RESTRICT
EOF

      <<"EOF",
INSERT INTO employer (company_code, name) VALUES ('', 'Default Employer')
EOF

      <<"EOF",
CREATE TABLE offerings 
(
  company_code        VARCHAR(6) DEFAULT '' NOT NULL,
  eid                 VARCHAR(9) DEFAULT '' NOT NULL,
  years               VARCHAR(2) DEFAULT '' NOT NULL,
  sort_order          SMALLINT DEFAULT 0 NOT NULL,
  browse              BOOLEAN DEFAULT true NOT NULL,
  discrete_sequences  BOOLEAN DEFAULT true NOT NULL,

  PRIMARY KEY (company_code, eid, years)
)
EOF

      <<"EOF",
ALTER TABLE offerings ADD CONSTRAINT fk_offering_employee 
  FOREIGN KEY (company_code, eid) REFERENCES employee(company_code, eid) 
  ON UPDATE CASCADE ON DELETE CASCADE
EOF

      <<"EOF",
ALTER TABLE offerings ADD CONSTRAINT fk_offering_company_code 
  FOREIGN KEY (company_code) REFERENCES employer(company_code) 
  ON UPDATE CASCADE ON DELETE CASCADE
EOF

      <<"EOF",
INSERT INTO offerings (company_code, eid, years) VALUES ('','','05')
EOF

      <<"EOF",
INSERT INTO offerings (company_code, eid, years) VALUES ('','','10')
EOF

      <<"EOF",
INSERT INTO offerings (company_code, eid, years) VALUES ('','','15')
EOF

      <<"EOF",
CREATE TABLE offering_sequences 
(
  company_code     VARCHAR(6) DEFAULT '' NOT NULL,
  eid              VARCHAR(9) DEFAULT '' NOT NULL,
  years            VARCHAR(2) DEFAULT '' NOT NULL,
  sequence_number  SMALLINT DEFAULT 0 NOT NULL,
  browse           BOOLEAN DEFAULT true NOT NULL,

  PRIMARY KEY (company_code, eid, years, sequence_number)
)
EOF

      <<"EOF",
ALTER TABLE offering_sequences ADD CONSTRAINT fk_offering_sequences 
  FOREIGN KEY (company_code, eid, years) REFERENCES offerings(company_code, eid, years) 
  ON UPDATE CASCADE ON DELETE CASCADE
EOF

      <<"EOF",
INSERT INTO offering_sequences (company_code, eid, years, sequence_number) VALUES ('','','05',0)
EOF

      <<"EOF",
INSERT INTO offering_sequences (company_code, eid, years, sequence_number) VALUES ('','','10',0)
EOF

      <<"EOF",
INSERT INTO offering_sequences (company_code, eid, years, sequence_number) VALUES ('','','15',0)
EOF

      <<"EOF",
CREATE TABLE offering_levels 
(
  company_code    VARCHAR(6) DEFAULT '' NOT NULL,
  eid             VARCHAR(9) DEFAULT '' NOT NULL,
  years           VARCHAR(2) DEFAULT '' NOT NULL,
  sequence_number SMALLINT DEFAULT 0 NOT NULL,
  catalog_code    VARCHAR(6) DEFAULT '' NOT NULL,
  catalog_level   VARCHAR(2) DEFAULT '' NOT NULL,
  browse          BOOLEAN DEFAULT true NOT NULL,

  PRIMARY KEY (company_code, eid, years, sequence_number, catalog_code, catalog_level)
)
EOF

      <<"EOF",
ALTER TABLE offering_levels ADD CONSTRAINT fk_offering_levels 
  FOREIGN KEY (company_code, eid, years, sequence_number) 
  REFERENCES offering_sequences(company_code, eid, years, sequence_number) 
  ON UPDATE CASCADE ON DELETE CASCADE
EOF
    );

    foreach my $sql (@sql)
    {
      local $dbh->{'PrintError'} = 0;
      eval { $dbh->do($sql) };

      if($@)
      {
        warn $@  unless($@ =~ /language "plpgsql" does not exist/);
        $Have{'pg'} = 0;
        $Have{'pg_with_schema'} = 0;
        last;
      }
    }

    $dbh->disconnect;
  }

}

END
{
  # Delete test table

  if($Have{'pg'})
  {
    # PostgreSQL
    my $dbh = Rose::DB->new('pg_admin')->retain_dbh()
      or die Rose::DB->error;

    $dbh->do('DROP TABLE offering_levels CASCADE');
    $dbh->do('DROP TABLE offering_sequences CASCADE');
    $dbh->do('DROP TABLE offerings CASCADE');
    $dbh->do('DROP TABLE employee CASCADE');
    $dbh->do('DROP TABLE employer CASCADE');

    $dbh->disconnect;
  }
}
