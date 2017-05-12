use Mojo::Base -strict;

use Test::More;
use Mojo::MySQL5;

# Defaults
my $url = Mojo::MySQL5->new->url;
is $url->dsn,      'dbi:mysql:dbname=test', 'right data source';
is $url->username, '',        'no username';
is $url->password, '',        'no password';
my $options = {};
is_deeply $url->options, $options, 'right options';

# Minimal connection string with database
$url = Mojo::MySQL5->new('mysql:///test1')->url;
is $url->dsn,      'dbi:mysql:dbname=test1', 'right data source';
is $url->username, '',                    'no username';
is $url->password, '',                    'no password';
$options = {
  utf8 => 1,
  found_rows => 1,
};
is_deeply $url->options, $options, 'right options';

# Minimal connection string with option
$url = Mojo::MySQL5->new('mysql://?PrintError=1')->url;
is $url->dsn,      'dbi:mysql:dbname=',  'right data source';
is $url->username, '',                   'no username';
is $url->password, '',                   'no password';
$options = {
  utf8 => 1,
  found_rows => 1,
  PrintError => 1,
};
is_deeply $url->options, $options, 'right options';

# Connection string with host and port
$url = Mojo::MySQL5->new('mysql://127.0.0.1:8080/test2')->url;
is $url->dsn, 'dbi:mysql:dbname=test2;host=127.0.0.1;port=8080',
  'right data source';
is $url->username, '', 'no username';
is $url->password, '', 'no password';
$options = {
  utf8 => 1,
  found_rows => 1,
};
is_deeply $url->options, $options, 'right options';

# Connection string username but without host
$url = Mojo::MySQL5->new('mysql://mysql@/test3')->url;
is $url->dsn,      'dbi:mysql:dbname=test3', 'right data source';
is $url->username, 'mysql',               'right username';
is $url->password, '',                    'no password';
$options = {
  utf8 => 1,
  found_rows => 1,
};
is_deeply $url->options, $options, 'right options';

# Connection string with unix domain socket and options
$url = Mojo::MySQL5->new(
  'mysql://x1:y2@%2ftmp%2fmysql.sock/test4?PrintError=1')->url;
is $url->dsn,      'dbi:mysql:dbname=test4;host=/tmp/mysql.sock', 'right data source';
is $url->username, 'x1',                                    'right username';
is $url->password, 'y2',                                    'right password';
$options = {
  utf8 => 1,
  found_rows => 1,
  PrintError => 1,
};
is_deeply $url->options, $options, 'right options';

# Connection string with lots of zeros
$url = Mojo::MySQL5->new('mysql://0:0@/0?PrintError=1')->url;
is $url->dsn,      'dbi:mysql:dbname=0', 'right data source';
is $url->username, '0',               'right username';
is $url->password, '0',               'right password';
$options = {
  utf8 => 1,
  found_rows => 1,
  PrintError => 1,
};
is_deeply $url->options, $options, 'right options';

done_testing();
