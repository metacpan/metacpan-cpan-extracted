use Mojo::Base -strict;
use Test::More;
use Test::Mojo;

BEGIN { $ENV{MOJO_MODE} = 'production' }
use Mojolicious::Lite;
note "MOJO_HOME=@{[app->home]}";
ok make_project_files(), 'created assets';

#$ENV{MOJO_WEBPACK_BUILD} = 1;    # set to "1" in case the source files changes
plugin webpack => {};
get '/'        => 'index';

my $t = Test::Mojo->new;
$t->get_ok('/')->status_is(200)->element_exists('script[src^="/asset/cool"]');
my $tag = $t->tx->res->dom->at('script');
$t->get_ok($tag->{src})->status_is(200)->header_is('Cache-Control', 'max-age=86400')
  ->content_like(qr{console\.log\(42\)});

done_testing;

sub make_project_files {
  my $assets = app->home->rel_file('assets');
  $assets->child('webpack.config.d')->make_path->child('custom.js')->spurt(<<'HERE');
module.exports = function(config) {
  config.entry = {
    'cool': './assets/cool-beans.js',
  };
};
HERE

  $assets->child('cool-beans.js')->spurt('console.log(42);');
}

__DATA__
@@ index.html.ep
%= asset "cool.js"
