use v5.26;
use warnings;

use Test2::V0;
use Mojolicious::Lite;

use experimental qw(signatures);

my $db_file = '/tmp/myapp.db';

plugin 'Migration::Sqitch' => {
  dsn       => "dbi:SQLite:dbname=$db_file",
  registry  => 'sqitch',
  directory => 't/schema',
  connectdb => sub($dsn, $u, $p) {DBI->connect(sprintf('DBI:%s:dbname=%s', $dsn->{driver}, $dsn->{params}->{dbname}))},
  initdb    => sub($dbh, $name) { },
  resetdb   => sub($dbh, $name) {unlink($db_file)}
};

unlink($db_file);    # start fresh

app->run_schema_initialization();

is(-f $db_file, 1, 'database file exists');

app->run_schema_initialization({reset => 1});

is(-f $db_file, undef, 'database file doesnt exist');

done_testing;
