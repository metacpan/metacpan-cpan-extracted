use Test::More;
use Test::Mojo;
use lib 'lib/';

use Mojolicious::Plugin::RESTRoutes;

#
# Test controllers with target methods
#
package Ive::Lost::My::Mojo::User;
use Mojo::Base 'Mojolicious::Controller';
sub catchall {
    my ($self, $msg) = @_;
    return $self->render(text => "$msg:".($self->param($self->param('idname')) || ''));
}
sub rest_list   { shift->catchall('list');   }
sub rest_create { shift->catchall('create'); }
sub rest_show   { shift->catchall('show');   }
sub rest_update { shift->catchall('update'); }
sub rest_remove { shift->catchall('remove'); }

package Ive::Lost::My::Mojo::Angst;
use Mojo::Base 'Ive::Lost::My::Mojo::User';

#
# Test Mojolicious app
#
package Test::Mojolicious::Plugin::RESTRoutes;
use Mojo::Base 'Mojolicious';

sub startup {
    my $self = shift;
    $self->secrets(["Victorias Secret"]);

    #$self->log( MojoX::Log::Log4perl->new() );

    my $public = $self->routes;
    $public->namespaces(['Ive::Lost::My::Mojo']);

    #
    # REST routes
    #
    $self->plugin('RESTRoutes');
    my $rt_api = $public->route('/api');
    # /api/users/
    $rt_api->rest_routes(name => 'user');
    $rt_api->rest_routes(name => 'angst', route => 'aengste', readonly => 1);
    # /api/systems/
    my $rt_fw = $rt_api->rest_routes(name => 'system', readonly => 1, controller => 'User');
        # /api/systems/xx/changes
        $rt_fw->rest_routes(name => 'change', readonly => 1, controller => 'User');
}

#
# Main test script
#
package main;

my $t = Test::Mojo->new('Test::Mojolicious::Plugin::RESTRoutes');

#use Mojolicious::Command::routes;
#use Mojo::Util qw(encode tablify);
#my $rows = [];
#Mojolicious::Command::routes::_walk($_, 0, $rows, 1) for @{$t->app->routes->children};
#diag encode('UTF-8', tablify($rows));

# users - valid
$t->get_ok('/api/users')->status_is(200)->content_is('list:', 'LIST route');
$t->post_ok('/api/users')->status_is(200)->content_is('create:', 'CREATE route');
$t->get_ok('/api/users/5')->status_is(200)->content_is('show:5', 'SHOW route');
$t->put_ok('/api/users/5')->status_is(200)->content_is('update:5', 'UPDATE route');
$t->delete_ok('/api/users/5')->status_is(200)->content_is('remove:5', 'REMOVE route');

# users - invalid
$t->put_ok('/api/users')->status_is(404, 'error if updating without ID');
$t->delete_ok('/api/users')->status_is(404, 'error if deleting without ID');
## custom route component name
$t->get_ok('/api/aengste')->status_is(200)->content_is('list:', 'LIST route');

# systems - valid
$t->get_ok('/api/systems')->status_is(200)->content_is('list:', 'LIST route in readonly mode');

#use Data::Dump qw(dump);
#diag dump($t->app->routes->lookup('show_system')->pattern->defaults);

$t->get_ok('/api/systems/5')->status_is(200)->content_is('show:5', 'SHOW route in readonly mode');

# systems - invalid
$t->post_ok('/api/systems')->status_is(404, 'no CREATE route in readonly mode');
$t->put_ok('/api/systems/5')->status_is(404, 'no UPDATE route in readonly mode');
$t->delete_ok('/api/systems/5')->status_is(404, 'no DELETE route in readonly mode');

# transfer stash from application into test context
my $stash;
$t->app->hook(after_dispatch => sub { $stash = shift->stash });

# systems/changes - valid
$t->get_ok('/api/systems/5/changes')->status_is(200)->content_is('list:5', 'LIST sub route');
$t->get_ok('/api/systems/5/changes/3')->status_is(200)->content_is('show:3', 'SHOW sub route');
$t->get_ok('/api/systems/testid')->status_is(200)->content_is('show:testid', 'non numeric ID');
$t->get_ok('/api/systems/testid/changes/3')->status_is(200)->content_is('show:3', 'non numeric ID in sub route');

is_deeply($stash->{'fm.ids'}, { system => "testid", change => 3 }, "\$c->stash('fm.ids') correctly set");

done_testing();
