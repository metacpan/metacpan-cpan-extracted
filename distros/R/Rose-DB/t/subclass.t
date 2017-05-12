#!/usr/bin/perl -w

use strict;

use Test::More tests => 13;

BEGIN 
{
  use_ok('Rose::DB');

  require 't/test-lib.pl';

  # Pg
  My::DB2->register_db(
    domain   => 'default',
    type     => 'pg',
    driver   => 'Pg',
    database => 'test',
    host     => 'localhost',
    username => 'postgres',
  );

  # Oracle
  My::DB2->register_db(
    domain   => 'default',
    type     => 'oracle',
    driver   => 'oracle',
    database => 'test',
    host     => 'localhost',
    username => '',
    password => '',
  );

  # MySQL
  My::DB2->register_db(
    domain   => 'default',
    type     => 'mysql',
    driver   => 'mysql',
    database => 'test',
    host     => 'localhost',
    username => 'root',
  );

  # Informix
  My::DB2->register_db(
    domain   => 'test',
    type     => 'informix',
    driver   => 'Informix',
    database => 'test@test',
  );
}

my $db = My::DB2->new(domain => 'test', type => 'pg');
ok($db->isa('My::DB2::Pg'), 'My::DB2::Pg 1');
is($db->subclass_special_pg, 'PG', 'My::DB2::Pg 2');

$db = My::DB2->new(domain => 'test', type => 'oracle');
ok($db->isa('My::DB2::Oracle'), 'My::DB2::Oracle 1');
is($db->subclass_special_oracle, 'ORACLE', 'My::DB2::Oracle 2');

$db = My::DB2->new(domain => 'test', type => 'mysql');
ok($db->isa('My::DB2::MySQL'), 'My::DB2::MySQL 1');
is($db->subclass_special_mysql, 'MYSQL', 'My::DB2::MySQL 2');

$db = My::DB2->new(domain => 'test', type => 'informix');
ok($db->isa('My::DB2::Informix'), 'My::DB2::Informix 1');
is($db->subclass_special_informix, 'INFORMIX', 'My::DB2::Informix 2');

eval { $db = My::DBReg->new(domain => 'test', type => 'mysql') };
ok($@, 'My::DBReg no such db');

$db = My::DBReg->new(domain => 'test', type => 'pg_sub');
ok($db->isa('My::DBReg'), 'My::DBReg isa My::DBReg');
ok($db->isa('Rose::DB'), 'My::DBReg isa Rose::DB');
ok($db->isa('Rose::DB::Pg'), 'My::DBReg isa Rose::DB::Pg');
