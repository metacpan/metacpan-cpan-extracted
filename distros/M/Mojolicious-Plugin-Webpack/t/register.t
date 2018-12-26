use lib '.';
use t::Helper;

my $cwd   = t::Helper->cwd;
my $t     = t::Helper->t;
my $asset = $t->app->asset;
is $asset->route->render({name => 'foo.js'}), '/asset/foo.js', 'route';
like $asset->assets_dir, qr{\bassets$},         'assets_dir';
like $asset->out_dir,    qr{\bpublic\W+asset$}, 'out_dir';

done_testing;
