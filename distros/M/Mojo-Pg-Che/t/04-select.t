use Mojo::Base -strict;

use Test::More;
use Mojo::Util qw(dumper);

plan skip_all => 'set env TEST_PG="dbname=<...>/<pg_user>/<passwd>" to enable this test' unless $ENV{TEST_PG};

my ($dsn, $user, $pw) = split m|[/]|, $ENV{TEST_PG};

use Mojo::Pg::Che;

my $class = 'Mojo::Pg::Che';

# 1
my $pg = $class->connect($dsn, $user, $pw, max_connections=>20);#{pg_enable_utf8 => 1,}

$pg->on(connection=>sub {$_[1]->do('set datestyle to "DMY, ISO";');});

subtest 'blocking pg select' => sub {
  my $r = $pg->selectrow_hashref('select now() as now',);
  like($r->{now}, qr/\d{4}-\d{2}-\d{2}/, 'blocking pg select');
};

subtest 'blocking db select' => sub {
  my $db = $pg->db;
  my $result = $db->selectrow_hashref('select now() as now',);
  like($result->{now}, qr/\d{4}-\d{2}-\d{2}/, 'blocking db select');
  
};

=pod
subtest 'attr Async=>1' => sub {
  my $sth = $pg->prepare('select now() as now, pg_sleep(?)');
  like $pg->selectrow_hashref($sth, undef, (1))->{now}, qr/\d{4}-\d{2}-\d{2}/, 'async sth pg selectrow_hashref';
  my $cb = $pg->selectrow_hashref($sth, {Async=>1}, ($_,));
  Mojo::IOLoop->start unless Mojo::IOLoop->is_running;
  like $$cb->()->hash->{now}, qr/\d{4}-\d{2}-\d{2}/, "right convert to async sth";
  #~ my @cb = ();
  #~ for (1..5) {
    #~ my $rand = rand;
    #~ push @cb, [(my $cb = $pg->selectrow_hashref('select now() as now, pg_sleep(?), ?::numeric as rand', {Async=>1}, (10-$_,$rand))), $rand];
  #~ }
  #~ Mojo::IOLoop->start unless Mojo::IOLoop->is_running;
  #~ for (@cb) {
    #~ my $r = ${$_->[0]}->()->fetchrow_hashref();
    #~ like $r->{now}, qr/\d{4}-\d{2}-\d{2}/, 'async sth pg selectrow_hashref';
    #~ is $r->{rand}, $_->[1], 'right result';
  #~ }
  
  #~ eval {local $sth; my $res = $pg->selectrow_hashref($sth, undef, (1))->{now};};
  #~ like $@, qr/.+/, 'blocking sth error after async query';
  
  #~ $sth->finish();
  $sth->{pg_async} = 0;
  like $pg->selectrow_hashref($sth, undef, (1))->{now}, qr/\d{4}-\d{2}-\d{2}/, 'right convert from async sth';
};
=cut

subtest 'blocking selectrow_array' => sub {
  my @result;
  for (142..144) {
    push @result, $pg->selectrow_array('select ?::int, 100', undef, ($_));
  }
  is scalar @result, 6, 'blocking pg selectrow_array';
};

#~ subtest 'async selectrow_arrayref' => sub {
  #~ my @cb;
  #~ ##~ my $sth = $pg->prepare('select ?::int, pg_sleep(1)', {Async=>1},);
  #~ for (142..144) {
    #~ push @cb, $pg->selectrow_arrayref('select ?::int, pg_sleep(1)', {Async=>1, Cached=>1,}, ($_));
  #~ }
  #~ Mojo::IOLoop->start unless Mojo::IOLoop->is_running;
  #~ is scalar @cb, 3*2, 'selectrow_arrayref';
#~ };


subtest 'blocking selectall_arrayref' => sub {
  my @result;
  my $sth = $pg->prepare('select ?::int, now()');
  for (142..144) {
    push @result, $pg->selectall_arrayref($sth, {Columns=>[1]}, ($_));
  }
  is scalar @result, 3, 'selectall_arrayref';
  is scalar @{$result[2][0]}, 1, 'selectall_arrayref Slice';
  #~ warn Dumper $result[2];
  like $result[0][0][0], qr/\d{4}-\d{2}-\d{2}/, 'selectall_arrayref slice column value';
};

#~ subtest 'async selectall_arrayref' => sub {
  #~ for (@{$pg->selectall_arrayref('select ?::int as c1, now() as c2', {Async=>1, Slice=>{},}, (568),)}) {
    #~ like $_->{c1}, qr/^\d{3}$/, 'selectall_arrayref Slice';
    #~ like $_->{c2}, qr/\d{4}-\d{2}-\d{2}/, 'selectall_arrayref slice column value';
  #~ }
#~ };


subtest 'async selectall_arrayref' => sub {
  my @result;
  my $cb = sub {
    my ($db, $err, $results) = @_;
    die $err if $err;
    push @result, $results;
  };
  #~ my $sth = $pg->prepare('select ?::int as c1, now() as c2, pg_sleep(1) as c3');
  # DBD::Pg::st execute failed: Cannot execute until previous async query has finished
  for (142..144) {
    $pg->selectall_arrayref('select ?::int as c1, now() as c2, pg_sleep(1) as c3', {}, ($_), $cb);
  }
  Mojo::IOLoop->start unless Mojo::IOLoop->is_running;
  is scalar @result, 3, 'selectall_arrayref';
  while (my $r = shift @result) {
    my $r = $r->fetchall_arrayref({});
    like $r->[0]{c1}, qr/^\d{3}$/, 'selectall_arrayref Slice';
    like $r->[0]{c2}, qr/\d{4}-\d{2}-\d{2}/, 'selectall_arrayref slice column value';
  }
};


subtest 'selectall_hashref' => sub {
  my @result = ();
  my $cb = sub {
    my ($db, $err, $results) = @_;
    die $err if $err;
    push @result, $results;
  };
  my $sql = 'select ?::int as "ид", ?::text as name, pg_sleep(1) as sleep';
  my $keyfield = 'ид';
  utf8::encode($keyfield);
  for (1..1) {
    my $r = $pg->selectall_hashref($sql, undef, {KeyField=>$keyfield}, ($_, 'foo'));
    is $r->{$_}{name}, 'foo', 'blocking selectall_hashref string';
  }
  my $sth = $pg->prepare($sql);
  for (1..1) {
    my $r = $pg->selectall_hashref($sth, $keyfield, undef, ($_, 'foo'));
    is $r->{$_}{name}, 'foo', 'blocking selectall_hashref sth';
  }
  #~ for (3..5) {
    #~ my $r = $pg->selectall_hashref($sql, undef, {KeyField=>$keyfield, Async=>1,}, ($_, 'bar'));
    #~ is $r->{$_}{name}, 'bar', 'async selectall_hashref string';
  #~ }
  for (17..17) {
    $pg->selectall_hashref($sql, undef, {Cached=>1,}, ($_, 'baz'), $cb);
    $pg->query($sql, {Cached=>1,}, ($_, 'baz'), $cb);
    $pg->selectrow_array($sql, {Cached=>1,}, ($_, 'baz'), $cb);
  }
  Mojo::IOLoop->start unless Mojo::IOLoop->is_running;
  is scalar @result, 3, 'async query cb  -attr';
  is $_->fetchall_hashref('name')->{baz}{name}, 'baz', 'async query result fetchall_hashref'
    for @result;
  
  @result = ();
  for (17..17) {
    $pg->selectall_hashref($sth, undef, {}, ($_, 'baz'), $cb);
    $pg->query($sth, {}, ($_, 'baz'), $cb);
    $pg->selectrow_array($sth, {}, ($_, 'baz'), $cb);
  }
  Mojo::IOLoop->start unless Mojo::IOLoop->is_running;
  is scalar @result, 3, 'async ';
  is $_->fetchall_hashref('name')->{baz}{name}, 'baz', 'async query result fetchall_hashref'
    for @result;

};

subtest 'prepare fetchcol_arrayref'=> sub {
  my $sql = 'select * FROM (VALUES(1, 200000, 1.2), (2, 400000, 1.4)) AS v (depno, target, increase);';
  my $sth = $pg->prepare($sql);
  my $res;
  my $cb = sub {
    my ($db, $err, $results) = @_;
    die $err if $err;
    $res =  $results;
  };
  #~ warn Dumper 
  $pg->selectcol_arrayref($sth, {Columns=>[2]}, $cb);
  Mojo::IOLoop->start unless Mojo::IOLoop->is_running;

  is $res->fetchcol_arrayref([2])->[1], '400000';
  #~ warn Dumper $res->fetchcol_arrayref([2]);
  eval {is $sth->{Database}->selectcol_arrayref($sth, {Columns=>[2],},)->[1], '400000'};
  like $@, qr/no statement executing/, 'blocking sth finished error after async query'
    if $@;
  
};

subtest 'selectrow_array'=> sub {
  my $now = $pg->selectrow_array('select now()');
  like $now, qr/\d{4}-\d{2}-\d{2}/, 'selectrow_array';
};


subtest 'select query fetch' => sub {
  my $row;
  my $cb = sub {
    my ($db, $err, $res) = @_;
    die $err if $err;
    $row = $res->fetchrow_hashref();
  };
  my $sth = $pg->prepare("select now() as now");
  $pg->select($sth, undef, $cb);
  Mojo::IOLoop->start unless Mojo::IOLoop->is_running;
  like $row->{now}, qr/\d{4}-\d{2}-\d{2}/, 'select+fetchrow_hashref';
  # повторно асинхрон sth
  $pg->query($sth, undef, $cb);
  Mojo::IOLoop->start unless Mojo::IOLoop->is_running;
  like $row->{now}, qr/\d{4}-\d{2}-\d{2}/, 'select+fetchrow_hashref';
};

#~ warn "\nпрошел: ", scalar @{$pg->{queue}};
#~ sleep 20;

done_testing();

