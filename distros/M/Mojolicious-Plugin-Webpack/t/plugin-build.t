use Mojo::Base -strict;
use Mojo::File qw(path);
use Test::More;
use Test::Mojo;

BEGIN {
  require Mojo::Alien::npm;
  plan skip_all => 'TEST_WEBPACK=1' unless $ENV{TEST_WEBPACK} or $ENV{TEST_ALL};
  note sprintf 'work_dir=%s', Mojo::Alien::npm->_setup_working_directory;
  $ENV{MOJO_HOME} = path->to_string;
  note "MOJO_HOME=$ENV{MOJO_HOME}";

  note 'Build the development assets once by setting MOJO_WEBPACK_BUILD=1';
  $ENV{MOJO_WEBPACK_BUILD} = 1;
  $ENV{MOJO_MODE}          = 'development';
}

use Mojolicious::Lite;
ok make_project_files(), 'created assets';
plugin webpack => {process => [qw(js)]};
get '/'        => 'index';

my $t = Test::Mojo->new;
$t->get_ok('/')->status_is(200)->element_exists('script[src="/asset/plugin-build-t.development.js"]');
$t->get_ok('/asset/plugin-build-t.development.js')->status_is(200)->header_is('Cache-Control', 'no-cache')
  ->content_like(qr{console\.log\(42\)});

done_testing;

sub make_project_files {
  app->home->rel_file('assets')->make_path->child('index.js')->spurt('console.log(42);');
}

__DATA__
@@ index.html.ep
# The default entrypoint will have "name" from package.json
%= asset 'plugin-build-t.js'
