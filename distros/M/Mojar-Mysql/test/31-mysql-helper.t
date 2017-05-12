# ============
# mysql-helper
# ============
use Mojo::Base -strict;
use Test::More;

my $mha;

subtest q{Basics} => sub {
  can_ok('T::Bclssr8w', qw(new connector dbh));
};

subtest q{connector} => sub {
  ok $mha = T::Bclssr8w->new, 'new';
  ok my $connector = $mha->connector, 'connector';
  isa_ok $connector, 'Mojar::Mysql::Connector', 'connector';
  ok $connector->can('connect'), 'and might be able to connect';

  is $connector->RaiseError, 0, 'contains correct hash value (RaiseError)';
  is $connector->AutoCommit, 0, 'contains correct hash value (AutoCommit)';
};

SKIP: {
  skip 'set TEST_MYSQL to enable this test (developer only!)', 1
    unless $ENV{TEST_MYSQL} || $ENV{TRAVIS};

subtest q{dbh} => sub {
  ok my $dbh = $mha->dbh, 'dbh';
  isa_ok $dbh, 'Mojar::Mysql::Connector::db', 'dbh';
  ok $dbh->can('ping'), 'and can ping';
  ok $dbh->ping, 'ping ok';

  ok $mha->dbh->do(q{SET @a = 2}), 'user variable';
  is $mha->dbh->selectrow_arrayref(q{SELECT @a})->[0], 2, 'same connection';
  # Simulate server timeout
  $SIG{__WARN__} = sub { 'ignore' };
  ok $mha->dbh(undef), 'undefine';
  ok ! defined($mha->dbh->selectrow_arrayref(q{SELECT @a})->[0]),
      'new connection';
};

};

done_testing();

package T::Bclssr8w;
use Mojo::Base -base;

use Mojar::Mysql::Connector (
  cnf => 'data/testmyappro_localhost',
  RaiseError => 0,
  AutoCommit => 0,
  -dbh => 1
);
