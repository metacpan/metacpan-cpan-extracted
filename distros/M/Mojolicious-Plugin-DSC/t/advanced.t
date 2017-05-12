use Mojo::Base -strict;
use lib qw(t/lib);

use Test::More;

use Mojolicious::Lite;
use Test::Mojo;
use Data::Dumper;
use File::Temp qw(tmpnam);

my $ddbix = tmpnam();
my $ydbix = tmpnam();

#Suppress some warnings from DBIx::Simple::Class during tests.
local $SIG{__WARN__} = sub {
  if (
    $_[0] =~ /(passphrase|redefined
         |SQL\sfrom)/x
    )
  {
    my ($package, $filename, $line, $subroutine) = caller(1);
    ok($_[0], $subroutine . " warns '$1' OK");
  }
  else {
    warn @_;
  }
};

app->mode('production');    #mute debug messages;

my $config = {
  database       => ':memory:',
  DEBUG          => 0,
  namespace      => 'My',
  load_classes   => ['Groups'],
  dbh_attributes => {sqlite_unicode => 1},
  driver         => 'SQLite',
  onconnect_do   => [
    sub {
      shift->dbh->sqlite_create_function('upper', 1, sub { return uc(shift) });
    }
  ],
  dbix_helper => 'ddbix',
  dsn         => 'dbi:SQLite:database=' . $ddbix
};


my $my_groups_table = <<"TAB";
CREATE TABLE my_groups (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  "group" VARCHAR(12),
  "is' enabled" INT DEFAULT 0
  )
TAB

my $users_table = <<"TAB";
CREATE TABLE users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  group_id INT default 1,
  login_name VARCHAR(12),
  login_password VARCHAR(100)
  )
TAB
delete $config->{load_classes};
ok(plugin('DSC', $config));
for (qw(User Groups)) {
  ok($INC{"My/$_.pm"}, $INC{"My/$_.pm"} . ' is loaded');
}
$config->{load_classes} = ['My::User', 'Groups'];

isa_ok(plugin('DSC', $config), 'Mojolicious::Plugin::DSC');
is(app->ddbix->query("SELECT UPPER('тест')")->array->[0],
  'ТЕСТ', 'onconnect_do works');
ok(app->ddbix->dbh->do($users_table),     'app->ddbix->dbh->do works');
ok(app->ddbix->dbh->do($my_groups_table), 'app->ddbix->dbh->do works2');

ok(app->ddbix->query('INSERT INTO my_groups ("group") VALUES(?)', 'pojo'),
  'app->ddbix->query works');

my $group = My::Groups->find(1);
is($group->id, 1, 'Group 1 found');
my $user = My::User->new(
  group_id       => $group->id,
  login_name     => 'петър',
  login_password => 'secretpass12'
);
$user->save;
is($user->id, 1, 'User 1 saved');


#additional dbix
my $your_config = {
  namespace    => 'Your',
  load_classes => ['User'],
  user         => 'me',
  dbix_helper  => 'your_dbix',
  dsn          => 'dbi:SQLite:database=' . $ddbix,

  # plug-in should be able to work with non-array, single statement configuration.
  onconnect_do =>
    'CREATE TEMP TABLE IF NOT EXISTS Variables ( key TEXT PRIMARY KEY, value TEXT )',
};

my $your_dbix = plugin('DSC', $your_config);
ok((eval { app->your_dbix } || $@) =~ /DBIx/, 'another schema loaded');
isnt(app->your_dbix, app->ddbix, 'two schemas loaded');

# If the table was created at connect, then the table exists and we can select from it.
is(app->your_dbix->query("SELECT count(*) FROM Variables")->array->[0],
  '0', 'non-ref onconnect_do works');

get '/' => sub {
  my $self = shift;
  my $group_row =
    $self->ddbix->query('SELECT * FROM my_groups WHERE "group"=?', $group->group);
  $self->render(
    text => 'Hello ' . $user->login_name . ' from group ' . $group->group . '!');
};

post '/edit/user' => sub {
  my $c    = shift;
  my $user = My::User->find($c->param('id'));
  $user->login_password($c->param('login_password'));
  $user->save;
  $c->render(text => 'New password for user '
      . $user->login_name . ' is '
      . $user->login_password);
};

my $t = Test::Mojo->new;
$t->get_ok('/')->status_is(200);
$t->content_is('Hello ' . $user->login_name . ' from group ' . $group->group . '!');

$t->post_ok('/edit/user', form => {id => 1, login_password => 'alabala123'})
  ->status_is(200)->content_is('New password for user петър is alabala123');

# Let's see if exceptions are thrown, as they should. It's never a good idea to ignore errors.

my $your_bad_config_1 = {
  namespace    => 'Your',
  load_classes => [],       # This includes "Your::Bad" that has broken constructor.
  user         => 'me',
  dbix_helper => 'your_bad_dbix_1',
  dsn         => 'dbi:SQLite:database=' . $ddbix,
};
my $your_bad_dbix_1 = eval { return plugin('DSC', $your_bad_config_1); };
like($@, qr/Does not compute/, 'Exception about "Bad" class thrown properly');

my $your_bad_config_3 = {
  namespace    => 'Very',
  load_classes => ["Bad"],
  user         => 'me',
  dbix_helper  => 'your_bad_dbix_3',
  dsn          => 'dbi:SQLite:database=' . $ddbix,
};
my $your_bad_dbix_3 = eval { return plugin('DSC', $your_bad_config_3); };
like(
  $@,
  qr/Does not load/,
  'Exception about "Bad" class thrown properly (by namespace)'
);

done_testing;

