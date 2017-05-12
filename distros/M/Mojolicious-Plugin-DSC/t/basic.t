use Test::More;
use Mojolicious::Lite;
use File::Basename qw(dirname);
use lib dirname(__FILE__) . '/lib';

#Suppress some warnings from DBIx::Simple::Class during tests.
local $SIG{__WARN__} = sub {
  if (
    $_[0] =~ /(redefined
         |SQL\sfrom|locate\sMemory\.pm\sin
         |Can't\slocate\sFoo.pm
         |"dbix"already\sexists,\sreplacing)/x
    )
  {
    my ($package, $filename, $line, $subroutine) = caller(1);
    ok($_[0], $subroutine . " warns '$1' OK");
  }
  else {
    warn @_;
  }
};


my $help_count = 1;
my $config     = {};
my $app        = app;
like(
  (eval { plugin 'DSC' }, $@),
  qr/Please choose and set a database driver/,
  ' no driver'
);
$config->{driver} = 'SQLite';
like((eval { plugin 'DSC', $config }, $@), qr'Please set "database"!', 'no database');
delete $app->renderer->helpers->{dbix};
$config->{database} = '%$#@';
like(
  (eval { plugin 'DSC', $config }, $@),
  qr'Please set "database"!',
  'Unparsable database name'
);
delete $app->renderer->helpers->{dbix};
$config->{database}     = ':memory:';
$config->{onconnect_do} = [''];
my $plugin = plugin('DSC', $config);
delete $app->renderer->helpers->{dbix};
my $generated_config = $plugin->config;
is_deeply(
  $generated_config,
  { database       => ':memory:',
    DEBUG          => 1,
    load_classes   => [],
    namespace      => 'Memory',
    dbh_attributes => {},
    driver         => 'SQLite',
    onconnect_do   => [],
    dbix_helper    => 'dbix',
    host           => 'localhost',
    dsn            => 'dbi:SQLite:database=:memory:;host=localhost',
    onconnect_do   => [''],
  },
  'default generated from minimal config'
);
$app->mode('production');    #mute debug messages;
$config = {
  driver           => 'SQLite',
  database         => ':memory:',
  postpone_connect => 1,
  password         => 'bla'
};
$config->{driver} = 'SQLite';

$generated_config = plugin('DSC', $config)->config;
delete $app->renderer->helpers->{dbix};

is_deeply(
  $generated_config,
  { database         => ':memory:',
    DEBUG            => '',
    load_classes     => [],
    namespace        => 'Memory',
    dbh_attributes   => {},
    driver           => $config->{driver},
    onconnect_do     => [],
    dbix_helper      => 'dbix',
    host             => 'localhost',
    dsn              => 'dbi:SQLite:database=:memory:;host=localhost',
    postpone_connect => $config->{postpone_connect},
    password         => $config->{password},
  },
  'default generated from minimal config in production'
);
delete $config->{dsn};
is(plugin('DSC', {%$config, port => 1234})->config->{port}, 1234, 'right port');
delete $app->renderer->helpers->{dbix};

is(plugin('DSC', {%$config, host => 'local'})->config->{host}, 'local', 'right host');
delete $app->renderer->helpers->{dbix};
is(plugin('DSC', {%$config, password => '***'})->config->{password},
  '***', 'right password');
delete $app->renderer->helpers->{dbix};
is(plugin('DSC', {%$config, namespace => 'Foo'})->config->{namespace},
  'Foo', 'no namespace Foo just warns');
delete $app->renderer->helpers->{dbix};

like(
  (eval { plugin('DSC', {dsn => 'bla'}) }, $@),
  qr/Can't parse DBI DSN/,
  'garbage dsn'
);

#warn app->dumper($generated_config);
$config->{dbix_helper} = $config->{dbix_helper} . $help_count++;
isa_ok(eval { plugin('DSC', $config) } || $@, 'Mojolicious::Plugin::DSC');

$config = {
  dsn          => 'dbi:SQLite:dbname=:memory:',
  load_classes => 'someclass',
  dbix_helper  => 'dbix_' . $help_count++
};


like(
  (eval { plugin 'DSC', $config }, $@),
  qr/must be an ARRAY reference /,
  'load_classes'
);
delete $config->{namespace};
$config->{load_classes} = ['My::User'];

#get namespace from dbname/$schema
is(plugin('DSC', $config)->config->{namespace}, 'Memory', 'namespace');
$config = {dsn => 'dbi:SQLite:dbname=:memory:', dbix_helper => 'dbix_' . $help_count++};

isa_ok(plugin('DSC', $config), 'Mojolicious::Plugin::DSC', 'proper dsn');


#$app->mode =~ m|^dev|
app->mode('production');
like(
  (eval { plugin 'DSC' }, $@),
  qr/Please choose and set a database driver/,
  ' no driver'
);

#dbh_attributes
like(
  (eval { plugin('DSC', {dbh_attributes => 'blah'}) }, $@),
  qr/must be a HASH reference/,
  ' dbh_attributes must be a HASH reference'
);

done_testing();
