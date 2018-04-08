use Mojo::Base -strict;

use Test::More;

plan skip_all => 'set env TEST_PG="DBI:Pg:dbname=<...>/<pg_user>/<passwd>" to enable this test' unless $ENV{TEST_PG};

my ($dsn, $user, $pw) = split m|[/]|, $ENV{TEST_PG};

use Mojo::Pg::Che;

my $class = 'Mojo::Pg::Che';
my $results_class = 'Mojo::Pg::Che::Results';

# 1
my $pg = $class->connect($dsn, $user, $pw,)->max_connections(20);

$pg->on(connection=>sub {shift; shift->do('set datestyle to "DMY, ISO";');});

my $result;
$result = $pg->query('select now() as now',);

isa_ok($result, $results_class);
like($result->hash->{now}, qr/\d{4}-\d{2}-\d{2}/, 'now query ok');

for (13..17) {
  $result = $pg->query('select ?::date as d', undef, ("$_/06/2016"));
  like($result->hash->{d}, qr/2016-06-$_/, 'date query ok');
}


{
  my $sth = $pg->prepare('select ?::date as d');

  for (13..17) {
    $result = $pg->query($sth, undef, ("$_/06/2016"));
    like($result->hash->{d}, qr/2016-06-$_/, 'date sth ok');
  }
};



{
  my @results;
  my $cb = sub {
    my ($db, $err, $results) = @_;
    die $err if $err;
    push @results, $results;
  };

  $pg->query('select ?::date as d, pg_sleep(?::int)', {Cached=>1,}, ("$_/06/2016", 1), $cb)
    for (13..17);
  Mojo::IOLoop->start unless Mojo::IOLoop->is_running;
  like($_->hash->{d}, qr/2016-06-\d+/, 'date sth ok')
    for @results;
};

{

  my $cb = $pg->db->query('select pg_sleep(?::int), now() as now', {Async=>1}, 3);
  Mojo::IOLoop->start unless Mojo::IOLoop->is_running;
  like $$cb->()->hash->{now}, qr/\d{4}-\d{2}-\d{2}/, 'now non-block-query ok';

  my $die = 'OUH, BUHHH!';
  my $rc = $pg->query('select ?::date as d, pg_sleep(?::int)', undef, ("01/06/2016", 2), sub {die $die});

  my $sth = $pg->prepare('select 10/?::int');
  $result = eval { $pg->query($sth, undef, (0)) };
  like $@, qr/execute failed:/, 'handler err';
}
done_testing();
