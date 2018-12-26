use lib '.';
use t::Helper;
use t::MyApp;

$ENV{MOJO_WEBPACK_BUILD} = $ENV{MOJO_WEBPACK_TEST_INTERNAL} = 1;

my $app = t::MyApp->new;
isa_ok($app->asset, 'Mojolicious::Plugin::Webpack');

note 'Generate shim';
my $shim = t::Helper->builder->_install_shim($app);
note "path=$shim";
ok -w $shim->dirname, 'plugin directory exists';
ok -r $shim, 'shim installed';

note 'Will load shim if available';
$app = t::MyApp->new;
isa_ok($app->asset, 't::MyApp::Plugin::Webpack');

my $shim_source = $shim->slurp;
unlike $shim_source, qr/plugin.*Webpack::Builder/,              'builder is not present';
unlike $shim_source, qr/ASSETPACK/,                             'assetpack is not present';
like $shim_source,   qr{See L<Mojolicious::Plugin::Webpack>\.}, 'reference';

note 'Will load from cpan if available';
$ENV{MOJO_WEBPACK_BUILD} = $ENV{MOJO_WEBPACK_TEST_INTERNAL} = 0;
$app = t::MyApp->new;
isa_ok($app->asset, 'Mojolicious::Plugin::Webpack');

ok unlink($shim), 'shim removed';

done_testing;
