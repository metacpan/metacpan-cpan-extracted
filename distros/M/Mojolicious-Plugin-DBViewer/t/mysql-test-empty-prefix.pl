use Mojolicious::Lite;

use FindBin;
use lib "lib";
use Mojolicious::Plugin::DBViewer;

plugin(
  'DBViewer',
  prefix => '',
  dsn => 'dbi:mysql:database=dbix_custom',
  user => 'dbix_custom',
  password => 'dbix_custom',
  site_title => 'Web DB Viewer'
);

app->start;

