#!perl

use strict;
use warnings;

use Test::More;

plan tests => 8;

use_ok('SQL::ReservedWords');
use_ok('SQL::ReservedWords::DB2');
use_ok('SQL::ReservedWords::MySQL');
use_ok('SQL::ReservedWords::ODBC');
use_ok('SQL::ReservedWords::Oracle');
use_ok('SQL::ReservedWords::PostgreSQL');
use_ok('SQL::ReservedWords::SQLite');
use_ok('SQL::ReservedWords::SQLServer');
