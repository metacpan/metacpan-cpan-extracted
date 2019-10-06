use lib '.';
use t::Helper;

plan skip_all => 'TEST_NODE_MODULES=1' unless $ENV{TEST_NODE_MODULES} or $ENV{TEST_ALL};

$ENV{MOJO_WEBPACK_REINSTALL} = 1;

my $cwd = t::Helper->cwd('install-deps');

$ENV{MOJO_WEBPACK_BUILD} = $ENV{MOJO_WEBPACK_TEST_INTERNAL} = 1;
my $t = t::Helper->t(dependencies => {core => ['underscore'], js => []});
is +t::Helper->builder->_render_to_file($t->app, 'package.json')->[0], 'generated', 'generated package.json';

t::Helper->builder->dependencies->{core} = ['underscore'];
t::Helper->builder->dependencies->{js}   = [];
is +t::Helper->builder->_install_node_deps, 1, 'first run';
is +t::Helper->builder->_install_node_deps, 0, 'second run';

$t = t::Helper->t(dependencies => {core => ['underscore'], js => []}, process => [qw(js css)]);
is +t::Helper->builder->_render_to_file($t->app, 'package.json')->[0], 'custom', 'custom package.json';

t::Helper->builder->{process} = [qw(js css)];
is +t::Helper->builder->_install_node_deps, 3, 'more deps for css';
is +t::Helper->builder->_install_node_deps, 0, 'all done';

done_testing;
