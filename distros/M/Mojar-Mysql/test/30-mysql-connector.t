# ============
# mysql-connector
# ============
use Mojo::Base -strict;
use Test::More;

use Mojar::Mysql::Connector (
  RaiseError => 0,
  AutoCommit => 0
);

subtest q{Class defaults} => sub {
  is_deeply [sort keys %{ Mojar::Mysql::Connector->Defaults }],
            [qw(AutoCommit RaiseError)], 'keys';
  is +(Mojar::Mysql::Connector->Defaults->{AutoCommit}), 0, '->{AutoCommit}';
  is +(Mojar::Mysql::Connector->Defaults->{RaiseError}), 0, '->{RaiseError}';

  ok +(Mojar::Mysql::Connector->Defaults->{RaiseError} = 1),
      '->{RaiseError} = 1';
  is +(Mojar::Mysql::Connector->Defaults->{RaiseError}), 1, '->{RaiseError}';

  ok +(Mojar::Mysql::Connector->Defaults({RaiseError => 0, AutoCommit => 1})),
      'complete assignment';
  is +(Mojar::Mysql::Connector->Defaults->{RaiseError}), 0, '->{RaiseError}';
  is +(Mojar::Mysql::Connector->Defaults->{AutoCommit}), 1, '->{AutoCommit}';
};

my $mc;

subtest q{Object defaults} => sub {
  ok $mc = Mojar::Mysql::Connector->new, 'new';
  is_deeply [sort keys %$mc],
            [qw(AutoCommit RaiseError)], 'keys';
  is $mc->RaiseError, 0, 'RaiseError';
  is $mc->AutoCommit, 1, 'AutoCommit';

  is $mc->PrintWarn, 0, 'PrintWarn';
  is_deeply [sort keys %$mc],
            [qw(AutoCommit PrintWarn RaiseError)], 'keys';

  is +(Mojar::Mysql::Connector->Defaults->{RaiseError}), 0, 'class defaults';
  delete $mc->{Defaults};
};

subtest q{Cloned object} => sub {
  ok $mc->user('tester'), '->user()';
  is $mc->user, 'tester', '->user';
  ok +(Mojar::Mysql::Connector->Defaults->{port} = 123), '->{port} =';

  ok my $mc0 = $mc->new, 'clone';
  is_deeply [sort keys %$mc0],
            [qw(AutoCommit PrintWarn RaiseError port user)], 'keys';
  is $mc0->user, 'tester', 'clone:user';
  is $mc0->port, 123, 'clone:port';
  ok $mc0->user('bart'), '->user()';
  is $mc0->user, 'bart', 'clone:user';
  is $mc->user, 'tester', 'orig:user';
};

subtest q{dsn} => sub {
  ok my $p = [ $mc->dsn ], 'object ->dsn';
  is_deeply $p, ['DBI:mysql:;port=123', 'tester', undef,
                 {AutoCommit => 1, PrintError => 0, PrintWarn => 0,
                  RaiseError => 0, TraceLevel => 0, mysql_enable_utf8 => 1,
                  mysql_auto_reconnect => 0}],
              'expected values';

  ok @$p = $mc->dsn(TraceLevel => 2), 'object ->dsn';
  is_deeply $p, ['DBI:mysql:;port=123', 'tester', undef,
                 {AutoCommit => 1, PrintError => 0, PrintWarn => 0,
                  RaiseError => 0, TraceLevel => 2, mysql_enable_utf8 => 1,
                  mysql_auto_reconnect => 0}],
              'expected values';
  is $mc->TraceLevel, 0, 'TraceLevel';
};

SKIP: {
  skip 'set TEST_MYSQL to enable this test (developer only!)', 2
    unless $ENV{TEST_MYSQL} || $ENV{TRAVIS};

my $dbh;

subtest q{connect} => sub {
  ok $dbh = DBI->connect(
    q{DBI:mysql:test_myapp;host=localhost;port=3306},
    'testmyappro', 'x8UUgrr_r',
    { RaiseError => 1 }
  ), 'DBI dsn connect';
  ok $dbh->ping, 'ping';

  ok $dbh = Mojar::Mysql::Connector->connect(
    q{DBI:mysql:test_myapp;host=localhost;port=3306},
    'testmyappro', 'x8UUgrr_r',
    { RaiseError => 1 }
  ), 'M::M::C dsn connect';
  ok $dbh->ping, 'ping';

  ok $dbh = Mojar::Mysql::Connector->connect(
    q{DBI:mysql:;host=localhost;port=3306},
    'testmyappro', 'x8UUgrr_r',
    { RaiseError => 1 }
  ), 'M::M::C dsn connect without schema';
  ok $dbh->ping, 'ping';

  ok $dbh = Mojar::Mysql::Connector->connect(
    schema => 'test_myapp',
    user => 'testmyappro',
    password => 'x8UUgrr_r'), 'param connect';
  ok $dbh->ping, 'ping';

  ok $dbh = Mojar::Mysql::Connector->connect(
    user => 'testmyappro',
    password => 'x8UUgrr_r'), 'param connect without schema';
  ok $dbh->ping, 'ping';

  ok $dbh = Mojar::Mysql::Connector->connect(
    cnfdir => 'data',
    cnf => 'testmyappro_localhost',
    schema => 'test_myapp'), 'param connect via credentials file';
  ok $dbh->ping, 'ping';
};

subtest q{Shorthands} => sub {
  ok @{$dbh->schemata} > 1, 'found multiple schemata';
  is scalar(@{ $dbh->schemata('test_myapp') }), 1, 'found expected schema';

  ok $dbh->tables_and_views('test_myapp'), 'got something for tables & views';

  ok @{$dbh->real_tables} > 1, 'found multiple tables';
  ok @{ $dbh->real_tables('test_myapp') } > 1, 'found multiple tables';
  is scalar(@{ $dbh->real_tables('test_myapp', 'f%') }), 1, 'found one table';
  is $dbh->real_tables('test_myapp', 'f%')->[0], 'foo', 'found expected table';

  is scalar(@{ $dbh->views('test_myapp') }), 0, 'found no tables';

  ok my $i = $dbh->indices('test_myapp', 'foo'), 'got indices';
  is scalar(@$i), 3, 'found three indices';
};

};

done_testing();
