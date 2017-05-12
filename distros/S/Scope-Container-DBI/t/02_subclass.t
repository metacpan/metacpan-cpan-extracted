use strict;

package MySubDBI;

use base qw/DBI/;

package MySubDBI::db;
our @ISA = qw(DBI::db);

package MySubDBI::st;
our @ISA = qw(DBI::st);

package main;

use Test::More;
use Scope::Container::DBI;

local $Scope::Container::DBI::DBI_CLASS = 'MySubDBI';
my $dbh = Scope::Container::DBI->connect("dbi:SQLite::memory:","","");
ok($dbh);
is ref($dbh), 'MySubDBI::db';

done_testing;
