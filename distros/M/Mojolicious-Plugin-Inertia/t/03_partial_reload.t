use Test::More;
use Test::Mojo;
use Mojolicious::Lite;
use lib 'lib';

plugin 'Inertia' => {
    version => '1.0.0',
    layout  => '<div id="app" data-page="<%= $data_page %>"></div>'
};

get '/dashboard' => sub {
    my $c = shift;
    $c->inertia('Dashboard', {
        stats => { total => 100, active => 75 },
        users => [
            { id => 1, name => 'User 1' },
            { id => 2, name => 'User 2' }
        ],
        settings => { theme => 'dark', lang => 'en' }
    });
};

my $t = Test::Mojo->new;

# Test partial reload - request only 'stats' prop
$t->get_ok('/dashboard' => {
    'X-Inertia' => 'true',
    'X-Inertia-Partial-Data' => 'stats',
    'X-Inertia-Partial-Component' => 'Dashboard'
  })
  ->status_is(200)
  ->json_is('/component' => 'Dashboard')
  ->json_is('/props/stats/total' => 100)
  ->json_is('/props/stats/active' => 75)
  ->json_hasnt('/props/users')
  ->json_hasnt('/props/settings');

# Test partial reload - request multiple props
$t->get_ok('/dashboard' => {
    'X-Inertia' => 'true',
    'X-Inertia-Partial-Data' => 'stats,settings',
    'X-Inertia-Partial-Component' => 'Dashboard'
  })
  ->status_is(200)
  ->json_is('/component' => 'Dashboard')
  ->json_is('/props/stats/total' => 100)
  ->json_is('/props/settings/theme' => 'dark')
  ->json_hasnt('/props/users');

# Test full reload when no partial headers
$t->get_ok('/dashboard' => {'X-Inertia' => 'true'})
  ->status_is(200)
  ->json_is('/component' => 'Dashboard')
  ->json_is('/props/stats/total' => 100)
  ->json_is('/props/users/0/name' => 'User 1')
  ->json_is('/props/settings/theme' => 'dark');

done_testing();