use Mojo::Base -strict;

use Test::More;

plan skip_all => 'set env TEST_PG="DBI:Pg:dbname=<...>/<pg_user>/<passwd>" to enable this test' unless $ENV{TEST_PG};

my ($dsn, $user, $pw) = split m|[/]|, $ENV{TEST_PG};

use Mojo::Pg::Che;
use Scalar::Util 'refaddr';

my $class = 'Mojo::Pg::Che';
my $results_class = 'Mojo::Pg::Che::Results';

# 1
my $pg = $class->connect($dsn, $user, $pw, max_connections=>20, debug=>0,);

#~ $pg->pg->on(connection=>sub { my ($pg, $dbh) = @_; warn "Mojo::PG---connection ",$dbh; $dbh->do('set datestyle to "DMY, ISO";');});
$pg->on(connection=>sub { $_[1]->do('set datestyle to "DMY, ISO";'); });#warn "connection --- ", @_; 


{
  my $res = $pg->query('select now() as now',);

  isa_ok($res, $results_class);
  like($res->hash->{now}, qr/\d{4}-\d{2}-\d{2}/, 'now query ok');

  for (11..17) {
    my $res = $pg->query('select ?::date as d', undef, ("$_/06/2016"));
    like($res->hash->{d}, qr/2016-06-$_/, 'date query ok');
  }
};


{
  my $sth = $pg->prepare('select ?::date as d');
  my $dbh = $sth->{Database};

  for (11..17) {
    my $res = $pg->query($sth, undef, ("$_/06/2016"));
    like($res->hash->{d}, qr/2016-06-$_/, 'date sth ok');
    cmp_ok(refaddr($dbh), '==', refaddr($res->db->dbh), 'one dbh');
  }
};

{# один sth для асинхр+синхр
  my @results;
  my $cb = sub {
    my ($db, $err, $results) = @_;
    die $err if $err;
    push @results, $results;
  };
  my $sth = $pg->prepare('select ?::date as d');
  #~ $pg->debug(1);

  $pg->query($sth, undef, ("$_/06/2016"), $cb)
    for (13..17);
  Mojo::IOLoop->start unless Mojo::IOLoop->is_running;
  like($_->hash->{d}, qr/2016-06-\d+/, 'date sth ok')
    for @results;
  #~ warn "\n -- sth pg_async_status=$sth->{pg_async_status}; $sth->{pg_async}", "dbh pg_async_status=", $sth->{Database}->{pg_async_status};
  #~ warn "\n --- pool: ". @{$pg->{queue}};
  $sth->{pg_async}=0;
  my $res = $pg->select($sth, undef, ("22/12/2018"));
  #~ warn %{$res->hash}, %{$res->hash};
  like($res->hash->{d}, qr/2018-12-22/, 'date sth ok');
};

{
  my @results;
  my $cb = sub {
    my ($db, $err, $results) = @_;
    die $err if $err;
    push @results, $results;
  };

  $pg->query('select ?::date as d, pg_sleep(?::int)', {Cached=>1,}, ("$_/06/2016", $_), $cb)#
    for (1..7);
  Mojo::IOLoop->start unless Mojo::IOLoop->is_running;
  like($_->hash->{d}, qr/2016-06-\d+/, 'date sth ok')
    for @results;
};

{# сам Mojo::Pg
  my @results;
  my $cb = sub {
    my ($db, $err, $results) = @_;
    die $err if $err;
    push @results, $results;
  };

  $pg->pg->db->query('select ?::date as d, pg_sleep(?::int)',("$_/06/2016", $_), $cb)# {Cached=>1,}, 
    for (1..7);
  Mojo::IOLoop->start unless Mojo::IOLoop->is_running;
  like($_->hash->{d}, qr/2016-06-\d+/, 'date sth ok')
    for @results;
};

{

  #~ my $cb = $pg->db->query('select pg_sleep(?::int), now() as now', {Async=>1}, 3);
  #~ Mojo::IOLoop->start unless Mojo::IOLoop->is_running;
  #~ like $$cb->()->hash->{now}, qr/\d{4}-\d{2}-\d{2}/, 'now non-block-query ok';

  my $die = 'OUH, BUHHH!';
  my $rc = $pg->query('select ?::date as d, pg_sleep(?::int)', undef, ("01/06/2016", 2), sub {die $die});

  my $sth = $pg->prepare('select 10/?::int');
  my $res = eval { $pg->query($sth, undef, (0)) };
  like $@, qr/execute failed:/, 'handler err';
}
done_testing();
