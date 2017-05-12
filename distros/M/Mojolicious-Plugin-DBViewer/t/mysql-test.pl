use Mojolicious::Lite;

use FindBin;
use lib "lib";
use Mojolicious::Plugin::DBViewer;

plugin(
  'DBViewer',
  dsn => 'dbi:mysql:database=dbix_custom',
  user => 'dbix_custom',
  password => 'dbix_custom'
);

get '/' => {text => 'a'};

app->start;

