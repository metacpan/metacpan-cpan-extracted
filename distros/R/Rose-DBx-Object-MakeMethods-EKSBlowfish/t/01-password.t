#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Data::Dumper qw(Dumper);
use Test::More;
use Test::Harness;
use Rose::DBx::TestDB;

BEGIN {
    use lib 't/lib';
    use lib 'lib';
}

plan tests => 9;


our $db = Rose::DBx::TestDB->new;

use_ok( 'User' ) || print "Bail out!\n";

my $r = $db->dbh->do(<<EOSQL

CREATE  TABLE "users" (
   "id" INTEGER PRIMARY KEY  AUTOINCREMENT  NOT NULL ,
   "name" VARCHAR NOT NULL  UNIQUE ,
   "password" VARCHAR NOT NULL
);

EOSQL
);

cmp_ok($r,'==','0E0','create testdb ok');

my $username = 'HansTest';
my $password = 'I know';
my $user = User->new(
   db => $db,
   name => $username,
   password => $password,
);
$user->save;

diag Dumper $user if $ENV{HARNESS_VERBOSE};
cmp_ok($user->id,'==',1,'create user in testdb ok');

subtest 'empty password' => sub {

   my $user = User->new(
      db => $db,
      name => $username,
   )->load;

   is( $user->password_is(undef),0,'undef password');
   is( $user->password_is(''),0,'empty password');

};

subtest 'wrong password' => sub {

   my $user = User->new(
      db => $db,
      name => $username,
   )->load;

   is( $user->password_is('anything'),0,'wrong password');

};

subtest 'check password' => sub {

   my $cmp_user = User->new(
      db => $db,
      name => $username,
   )->load;

   is( $cmp_user->password_is($password ),1,'password matched');
   is( $cmp_user->password_is('anything'),0,'password mismatched');

   $password = 'Yes I know';
   $cmp_user->password($password);
   $cmp_user->save;

   is( $cmp_user->password_is($password ),1,'password matched');
   is( $cmp_user->password_is('anything'),0,'password mismatched');

};

subtest 'check password starting with $' => sub {

   my $cmp_user = User->new(
      db => $db,
      name => $username,
   )->load;

   is( $cmp_user->password_is($password ),1,'password matched');
   is( $cmp_user->password_is('anything'),0,'password mismatched');

   $password = '$Yes I know';
   $cmp_user->password($password);
   $cmp_user->save;

   is( $cmp_user->password_is($password ),1,'password matched');
   is( $cmp_user->password_is('anything'),0,'password mismatched');

};

subtest 'check password starting with a eks signature' => sub {

   my $cmp_user = User->new(
      db => $db,
      name => $username,
   )->load;

   is( $cmp_user->password_is($password ),1,'password matched');
   is( $cmp_user->password_is('anything'),0,'password mismatched');

   $password = '$2a$12$Yes I know';
   $cmp_user->password($password);
   $cmp_user->save;

   is( $cmp_user->password_is($password ),1,'password matched');
   is( $cmp_user->password_is('anything'),0,'password mismatched');

};

subtest 'check password starting with another eks signature' => sub {

   my $cmp_user = User->new(
      db => $db,
      name => $username,
   )->load;

   is( $cmp_user->password_is($password ),1,'password matched');
   is( $cmp_user->password_is('anything'),0,'password mismatched');

   $password = '$2$12$Yes I know';
   $cmp_user->password($password);
   $cmp_user->save;

   is( $cmp_user->password_is($password ),1,'password matched');
   is( $cmp_user->password_is('anything'),0,'password mismatched');

};
done_testing;

__END__
