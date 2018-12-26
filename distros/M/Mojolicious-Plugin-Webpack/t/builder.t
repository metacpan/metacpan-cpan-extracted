use lib '.';
use t::Helper;

$ENV{MOJO_WEBPACK_BUILD} = $ENV{MOJO_WEBPACK_TEST_INTERNAL} = 1;
use Mojolicious::Lite;
plugin 'Webpack';

is_deeply + [sort keys %{t::Helper->builder->dependencies}], [qw(core css js sass vue)], 'dependencies';
is +t::Helper->builder->assets_dir, app->asset->assets_dir, 'assets_dir';
is +t::Helper->builder->out_dir,    app->asset->out_dir,    'out_dir';

my $env = t::Helper->builder->_webpack_environment;
is $env->{NODE_ENV},             'development',                            'NODE_ENV';
is $env->{WEBPACK_RULE_FOR_JS},  1,                                        'WEBPACK_RULE_FOR_JS';
is $env->{WEBPACK_SOURCE_MAPS},  1,                                        'WEBPACK_SOURCE_MAPS';
like $env->{WEBPACK_ASSETS_DIR}, qr{\bassets\W*$},                         'WEBPACK_ASSETS_DIR';
like $env->{WEBPACK_OUT_DIR},    qr{\bpublic\W+asset\W*$},                 'WEBPACK_OUT_DIR';
like $env->{WEBPACK_SHARE_DIR},  qr{\bMojolicious\W+Plugin\W+Webpack\W*$}, 'WEBPACK_SHARE_DIR';
ok !$env->{WEBPACK_RULE_FOR_CSS}, 'WEBPACK_RULE_FOR_CSS';

# TODO: Not sure if these variables should be documented or not
$ENV{WEBPACK_SHARE_DIR}   = '/what/ever';
$ENV{WEBPACK_SOURCE_MAPS} = '0';
$env                      = t::Helper->builder->_webpack_environment;
is $env->{WEBPACK_SOURCE_MAPS}, 0,            'WEBPACK_SOURCE_MAPS';
is $env->{WEBPACK_SHARE_DIR},   '/what/ever', 'WEBPACK_SHARE_DIR';

done_testing;
