use Mojo::Base -strict;

use Test::More;

plan skip_all => 'set env TEST_PG="DBI:Pg:dbname=<...>/<pg_user>/<passwd>" to enable this test' unless $ENV{TEST_PG};

my ($dsn, $user, $pw) = split m|[/]|, $ENV{TEST_PG};

use Mojo::Pg::Che;
use Mojo::IOLoop;
use Mojo::JSON 'true';

# 1
my $pg = Mojo::Pg::Che->connect($dsn, $user, $pw,);
my ($db, @all, @test);
#~ $pg->pubsub->on(reconnect => sub { $db = pop; warn "Reconnect: ", $db; });
$pg->pubsub->listen(
  pstest => sub {
    my ($pubsub, $payload) = @_;
    push @test, $payload;
    Mojo::IOLoop->next_tick(sub { $pubsub->pg->db->notify(pstest => 'stop') });
    Mojo::IOLoop->stop if $payload eq 'stop';
  }
);

#~ $db->on(notification => sub { push @all, [@_[1, 3]] });
$pg->pubsub->notify(pstest => '♥test♥');
Mojo::IOLoop->start;
is_deeply \@test, ['♥test♥', 'stop'], 'right messages';
#~ is_deeply \@all, [['pstest', '♥test♥'], ['pstest', 'stop']],
  'right notifications';

# JSON
$pg = Mojo::Pg::Che->connect($dsn, $user, $pw,);#Mojo::Pg->new($ENV{TEST_ONLINE});
my (@json, @raw);
#~ $pg->pubsub->on(reconnect => sub { $db = pop; warn "Reconnect: ", $db; });
$pg->pubsub->json('pstest')->listen(
  pstest => sub {
    my ($pubsub, $payload) = @_;
    push @json, $payload;
    #~ warn "Listen pstest json:", $payload // '<undef>';
    Mojo::IOLoop->stop if ref $payload eq 'HASH' && $payload->{msg} eq 'stop';
  }
);
$pg->pubsub->listen(
  pstest2 => sub {
    my ($pubsub, $payload) = @_;
    push @raw, $payload;
  }
);
#~ use Data::Dumper;

Mojo::IOLoop->next_tick(
  sub {
    $pg->db->notify(pstest => 'fail');
    
    #~ warn Dumper \@json;
    $pg->pubsub->notify('pstest')->notify(pstest => {msg => '♥works♥'})
      ->notify(pstest => [1, 2, 3])->notify(pstest => true)
      ->notify(pstest2 => '♥works♥')->notify(pstest => {msg => 'stop'});
  }
);
Mojo::IOLoop->start;
#~ warn Dumper \@json;
is_deeply \@json,
  [undef, undef, undef, {msg => '♥works♥'}, [1, 2, 3], true, {msg => 'stop'}],
  'right data structures';
is_deeply \@raw, ['♥works♥'], 'right messages';

# Unsubscribe
$pg = Mojo::Pg::Che->connect($dsn, $user, $pw,);#Mojo::Pg->new($ENV{TEST_ONLINE});
$db = undef;
$pg->pubsub->on(reconnect => sub { $db = pop; warn "Reconnect: ", $db; });
@all = @test = ();
my $first  = $pg->pubsub->listen(pstest => sub { push @test, pop });
my $second = $pg->pubsub->listen(pstest => sub { push @test, pop });
$db->on(notification => sub { push @all, [@_[1, 3]] });
$pg->pubsub->notify('pstest')->notify(pstest => 'first');
is_deeply \@test, ['', '', 'first', 'first'], 'right messages';
is_deeply \@all, [['pstest', ''], ['pstest', 'first']], 'right notifications';
$pg->pubsub->unlisten(pstest => $first)->notify(pstest => 'second');
is_deeply \@test, ['', '', 'first', 'first', 'second'], 'right messages';
is_deeply \@all, [['pstest', ''], ['pstest', 'first'], ['pstest', 'second']],
  'right notifications';
$pg->pubsub->unlisten(pstest => $second)->notify(pstest => 'third');
is_deeply \@test, ['', '', 'first', 'first', 'second'], 'right messages';
is_deeply \@all, [['pstest', ''], ['pstest', 'first'], ['pstest', 'second']],
  'right notifications';
@all = @test = ();
my $third  = $pg->pubsub->listen(pstest => sub { push @test, pop });
my $fourth = $pg->pubsub->listen(pstest => sub { push @test, pop });
$pg->pubsub->notify(pstest => 'first');
is_deeply \@test, ['first', 'first'], 'right messages';
$pg->pubsub->notify(pstest => 'second');
is_deeply \@test, ['first', 'first', 'second', 'second'], 'right messages';
$pg->pubsub->unlisten('pstest')->notify(pstest => 'third');
is_deeply \@test, ['first', 'first', 'second', 'second'], 'right messages';

# Reconnect while listening
$pg = Mojo::Pg::Che->connect($dsn, $user, $pw,);#Mojo::Pg->new($ENV{TEST_ONLINE});
my @dbhs = @test = ();
$pg->pubsub->on(reconnect => sub { push @dbhs, pop->dbh; warn "Reconnect: ", @dbhs; });
$pg->pubsub->listen(pstest => sub { push @test, pop });
ok $dbhs[0], 'database handle';
is_deeply \@test, [], 'no messages';
#~ {
  #~ local $dbhs[0]{Warn} = 0;
  #~ $pg->pubsub->on(
    #~ reconnect => sub { shift->notify(pstest => 'works'); Mojo::IOLoop->stop });
  #~ $pg->db->query('select pg_terminate_backend(?)', undef, $dbhs[0]{pg_pid});
  #~ Mojo::IOLoop->start;
  #~ ok $dbhs[1], 'database handle';
  #~ isnt $dbhs[0], $dbhs[1], 'different database handles';
  #~ is_deeply \@test, ['works'], 'right messages';
#~ };

# Reconnect while not listening
$pg = Mojo::Pg::Che->connect($dsn, $user, $pw,); #Mojo::Pg->new($ENV{TEST_ONLINE});
@dbhs = @test = ();
$pg->pubsub->on(reconnect => sub { push @dbhs, pop->dbh; warn "Reconnect: ", @dbhs; });
$pg->pubsub->notify(pstest => 'fail');
ok $dbhs[0], 'database handle';
is_deeply \@test, [], 'no messages';
#~ {
  #~ local $dbhs[0]{Warn} = 0;
  #~ $pg->pubsub->on(reconnect => sub { Mojo::IOLoop->stop });
  #~ $pg->db->query('select pg_terminate_backend(?)', undef, $dbhs[0]{pg_pid});
  #~ Mojo::IOLoop->start;
  #~ ok $dbhs[1], 'database handle';
  #~ isnt $dbhs[0], $dbhs[1], 'different database handles';
  #~ $pg->pubsub->listen(pstest => sub { push @test, pop });
  #~ $pg->pubsub->notify(pstest => 'works too');
  #~ is_deeply \@test, ['works too'], 'right messages';
#~ };

# Fork-safety
$pg = Mojo::Pg::Che->connect($dsn, $user, $pw,); #Mojo::Pg->new($ENV{TEST_ONLINE});
@dbhs = @test = ();
$pg->pubsub->on(reconnect => sub { push @dbhs, pop->dbh; warn "Reconnect: ", @dbhs; });
$pg->pubsub->listen(pstest => sub { push @test, pop });
ok $dbhs[0], 'database handle';
$pg->pubsub->notify(pstest => 'first');
is_deeply \@test, ['first'], 'right messages';
{
  local $$ = -23;
  $pg->pubsub->notify(pstest => 'second');
  ok $dbhs[1], 'database handle';
  isnt $dbhs[0], $dbhs[1], 'different database handles';
  is_deeply \@test, ['first'], 'right messages';
  $pg->pubsub->listen(pstest => sub { push @test, pop });
  $pg->pubsub->notify(pstest => 'third');
  ok !$dbhs[2], 'no database handle';
  is_deeply \@test, ['first', 'third'], 'right messages';
};

done_testing();