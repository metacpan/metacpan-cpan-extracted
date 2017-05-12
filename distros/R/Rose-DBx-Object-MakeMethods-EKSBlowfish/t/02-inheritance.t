#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Data::Dumper qw(Dumper);
use Test::More 'no_plan';
use Test::Harness;
use Rose::DBx::TestDB;

BEGIN {
    use lib 't/lib';
    use lib 'lib';
}

our $db = Rose::DBx::TestDB->new;
my $r = $db->dbh->do(
    <<EOSQL
CREATE  TABLE "users" (
   "id" INTEGER PRIMARY KEY  AUTOINCREMENT  NOT NULL ,
   "name" VARCHAR NOT NULL  UNIQUE ,
   "password" VARCHAR NOT NULL
);
EOSQL
);

use_ok('DerivedUser') || print "Bail out!\n";
cmp_ok( $r, '==', '0E0', 'create testdb ok' );

my $username = 'HansTest';
my $password = 'I know';
my $user     = DerivedUser->new(
    db       => $db,
    name     => $username,
    password => $password,
);

diag Dumper $user if $ENV{HARNESS_VERBOSE};

$user->save;

cmp_ok( $user->id, '==', 1, 'create user in testdb ok' );

__END__
