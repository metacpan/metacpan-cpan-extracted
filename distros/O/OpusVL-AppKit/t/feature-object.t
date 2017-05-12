use Test::More;
use OpusVL::AppKit::Plugin::AppKit::FeatureList;
use Catalyst::Action;
use Test::Differences;
use Cache::FastMmap;

my $feature = OpusVL::AppKit::Plugin::AppKit::FeatureList->new;

my $action = Catalyst::Action->new(
    class => 'TestApp::Controller::ExtensionA',
    name => 'home',
    namespace => 'extensiona',
    attributes => {
        AppKitFeature => [ 'Extension A' ],
        Args => [],
        AppKitRolesAllowed => [ 'Administrator' ],
        Path => [ 'extensionsa' ],
    },
    reverse => 'extensiona/home',
);
$feature->add_action('app', $action);

my $features = $feature->feature_list;
eq_or_diff $features, { 'app' => {'Extension A' => [] }}, 'Checking feature list';

$feature->set_roles_allowed('app/Extension A', [ qw/Admin Supervisor/ ]);
eq_or_diff $feature->roles_allowed_for_action($action->reverse), [ qw/Admin Supervisor/ ], 'Check roles for action';
$features = $feature->feature_list;
eq_or_diff $features, { app => { 'Extension A' => [ qw/Admin Supervisor/ ] }}, 'Checking feature list';

my $action2 = Catalyst::Action->new(
    class => 'TestApp::Controller::ExtensionA',
    name => 'list',
    namespace => 'extensiona',
    attributes => {
        AppKitFeature => [ 'Extension A' ],
        Args => [],
        AppKitRolesAllowed => [ 'Administrator' ],
        Path => [ 'extensionsa' ],
    },
    reverse => 'extensiona/list',
);
$feature->add_action('app', $action2);
$features = $feature->feature_list;
eq_or_diff $features, { app => { 'Extension A' => [ qw/Admin Supervisor/ ] } }, 'Checking feature list';
eq_or_diff $feature->roles_allowed_for_action($action->reverse), [ qw/Admin Supervisor/ ], 'Check roles for action';
eq_or_diff $feature->roles_allowed_for_action($action2->reverse), [ qw/Admin Supervisor/ ], 'Check roles for action';
eq_or_diff $feature->feature_list('Admin'), { app => {'Extension A' => 1} }, 'Checking role filtering';
eq_or_diff $feature->feature_list('Administrator'), { app => { 'Extension A' => 0} }, 'Checking role filtering';

# now check we can cache the object and use it.
note 'cache test';

my $cache = Cache::FastMmap->new;
$cache->set('test', $feature);

my $f = $cache->get('test');
$features = $f->feature_list;
eq_or_diff $features, { app => { 'Extension A' => [ qw/Admin Supervisor/ ] }}, 'Checking feature list';
eq_or_diff $f->roles_allowed_for_action($action->reverse), [ qw/Admin Supervisor/ ], 'Check roles for action';
eq_or_diff $f->roles_allowed_for_action($action2->reverse), [ qw/Admin Supervisor/ ], 'Check roles for action';

my $action3 = Catalyst::Action->new(
    class => 'TestApp::Controller::ExtensionA',
    name => 'list',
    namespace => 'extensiona',
    attributes => {
        AppKitFeature => [ 'Extension B' ],
        Args => [],
        AppKitRolesAllowed => [ 'Administrator' ],
        Path => [ 'extensionsb' ],
    },
    reverse => 'extensionb/list',
);
$feature->add_action('app', $action3);
$features = $feature->feature_list;
eq_or_diff $features, { app => { 'Extension B' => [], 'Extension A' => [ qw/Admin Supervisor/ ] } }, 'Checking feature list';

done_testing;

