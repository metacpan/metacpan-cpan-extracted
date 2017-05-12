package My::Mojo::App::Base;
use Mojo::Base 'Mojolicious::Controller';

sub catchall {
  my ($self, $msg) = @_;
  my $id = $self->stash($self->name . '_id') // '';
  $self->render(text => "$msg,$id");
}

sub resource_lookup {1}
sub create          { shift->catchall('create') }
sub delete          { shift->catchall('delete') }
sub list            { shift->catchall('list') }
sub read            { shift->catchall('read') }
sub update          { shift->catchall('update') }

sub name {
  my $self = shift;
  my $name = $self->stash->{controller};
  $name =~ s,^.*\-,,;
  return $name;
}

1;

package My::Mojo::App::Under;
use Mojo::Base 'Mojolicious::Controller';

sub foo_bar {
  1;
}

sub users {
  1;
}

1;

package My::Mojo::App::Attach;
use Mojo::Base 'Mojolicious::Controller';

sub authenticate {1}

1;

package My::Mojo::App::Attach::GlobalUsers;
use Mojo::Base 'My::Mojo::App::Base';

1;

package My::Mojo::App::Attach::GlobalUsers::Roles;
use Mojo::Base 'My::Mojo::App::Base';

sub read {
  my $self = shift;
  $self->render(
    text => join ",",
    'read', $self->stash('global_users_id'), $self->stash('roles_id')
  );
}

1;

package My::Mojo::App::A;
use Mojo::Base 'My::Mojo::App::Base';

sub read {
  my $self = shift;
  $self->render(text => join ",", 'read', $self->restify->current_id);
}

1;

package My::Mojo::App::A::B;
use Mojo::Base 'My::Mojo::App::Base';

sub read {
  my $self = shift;
  $self->render(text => join ",", 'read', $self->restify->current_id);
}

1;

package My::Mojo::App::A::B::C;
use Mojo::Base 'My::Mojo::App::Base';

sub read {
  my $self = shift;
  $self->render(text => join ",", 'read', $self->restify->current_id);
}

1;

package My::Mojo::App::FooBar;
use Mojo::Base 'My::Mojo::App::Base';

1;

package My::Mojo::App::FooBar::BarBar;
use Mojo::Base 'My::Mojo::App::Base';

1;

package My::Mojo::App::Invoices;
use Mojo::Base 'My::Mojo::App::Base';

1;

package My::Mojo::App::Messages;
use Mojo::Base 'My::Mojo::App::Base';

1;

package My::Mojo::App::Users;
use Mojo::Base 'My::Mojo::App::Base';

1;

package My::Mojo::App::Users::Roles;
use Mojo::Base 'My::Mojo::App::Base';

sub read {
  my $self = shift;
  $self->render(
    text => join ",",
    'read', $self->stash('users_id'), $self->stash('roles_id')
  );
}

1;

package My::Mojo::App::Withoutlookup;
use Mojo::Base 'My::Mojo::App::Base';

sub resource_lookup { shift->reply->not_found }

1;

package Test::Mojolicious::Plugin::Restify::ArrayRef;
use Mojo::Base 'Mojolicious';

sub startup {
  my $self = shift;
  $self->secrets(["sssshhhhhh!"]);

  # Load the plugin
  $self->plugin('Mojolicious::Plugin::Restify', {over => 'int'});

  # Router
  my $r = $self->routes;
  $r->namespaces(['My::Mojo::App']);

  # REST routes config
  my $rest_routes = [
    'a/b/c',
    'foo-bar',
    'foo-bar/bar-bar',
    'invoices',
    ['messages' => {over => 'uuid'}],
    'users',
    'users/roles',
    'users/roles/messages'
  ];

  # Test the restify helper
  $self->restify->routes($r, $rest_routes);

  # Attach nested routes to an existing route
  my $attach = $r->any('/attach')->under->to('attach#authenticate');
  $self->restify->routes(
    $attach,
    {'global-users' => {'roles' => undef}},
    {controller     => 'attach'}
  );

  # Collection test for specific options
  $r->collection('withoutlookup', resource_lookup => 0);
}

1;

package Test::Mojolicious::Plugin::Restify::HashRef;
use Mojo::Base 'Mojolicious';

sub startup {
  my $self = shift;
  $self->secrets(["sssshhhhhh!"]);

  # Load the plugin
  $self->plugin('Mojolicious::Plugin::Restify', {over => 'int'});

  # Router
  my $r = $self->routes;
  $r->namespaces(['My::Mojo::App']);

  # REST routes config
  my $rest_routes = {
    'a' => {
        'b' => {
            'c' => undef
        }
    },
    'foo-bar'  => {
        'bar-bar' => undef
    },
    'invoices' => undef,
    'messages' => [undef, {over => 'uuid'}],
    'users' => {
        'roles' => undef,
        'messages' => undef
    },
  };

  # Test the restify helper
  $self->restify->routes($r, $rest_routes);

  # Attach nested routes to an existing route
  my $attach = $r->any('/attach')->under->to('attach#authenticate');
  $self->restify->routes(
    $attach,
    {'global-users' => {'roles' => undef}},
    {controller     => 'attach'}
  );

  # Collection test for specific options
  $r->collection('withoutlookup', resource_lookup => 0);
}

1;

package main;
use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

for my $app (
  'Test::Mojolicious::Plugin::Restify::ArrayRef',
  'Test::Mojolicious::Plugin::Restify::HashRef'
  )
{
  my $t = Test::Mojo->new($app);

  # /attach/users/*
  $t->get_ok('/attach/global-users')->status_is(200)->content_is('list,');
  $t->get_ok('/attach/global-users/1')->status_is(200)->content_is('read,1');
  $t->get_ok('/attach/global-users/1/roles')->status_is(200)
    ->content_is('list,');
  $t->get_ok('/attach/global-users/100/roles/500')->status_is(200)
    ->content_is('read,100,500');
  $t->get_ok('/attach/global-users/0')->status_is(200)->content_is('read,0');
  $t->get_ok('/attach/global-users/-1')->status_is(404);

  # /foo-bar
  $t->get_ok('/foo-bar')->status_is(200)->content_is('list,');
  $t->get_ok('/foo-bar/69')->status_is(200)->content_is('read,69');

  # /foo-bar/bar
  $t->get_ok('/foo-bar/69/bar-bar')->status_is(200)->content_is('list,');

  # /invoices
  $t->get_ok('/invoices')->status_is(200)->content_is('list,');
  $t->post_ok('/invoices')->status_is(200)->content_is('create,');
  $t->get_ok('/invoices/bad-int')->status_is(404);
  $t->get_ok('/invoices/69')->status_is(200)->content_is('read,69');
  $t->delete_ok('/invoices/69')->status_is(200)->content_is('delete,69');
  $t->put_ok('/invoices/69')->status_is(200)->content_is('update,69');

  # /messages
  $t->get_ok('/messages')->status_is(200)->content_is('list,');
  $t->post_ok('/messages')->status_is(200)->content_is('create,');
  $t->get_ok('/messages/bad-uuid')->status_is(404);
  $t->get_ok('/messages/8dd5c2a0-9d39-11e3-a5e2-0800200c9a66')->status_is(200)
    ->content_is('read,8dd5c2a0-9d39-11e3-a5e2-0800200c9a66');
  $t->get_ok('/messages/8dd5c2a09d3911e3a5e20800200c9a66')->status_is(200)
    ->content_is('read,8dd5c2a09d3911e3a5e20800200c9a66');
  $t->get_ok('/messages/8DD5C2A09D3911E3A5E20800200C9A66')->status_is(200)
    ->content_is('read,8DD5C2A09D3911E3A5E20800200C9A66');

  # /users/*
  $t->get_ok('/users')->status_is(200)->content_is('list,');
  $t->get_ok('/users/1')->status_is(200)->content_is('read,1');
  $t->get_ok('/users/1/roles')->status_is(200)->content_is('list,');
  $t->get_ok('/users/100/roles/500')->status_is(200)
    ->content_is('read,100,500');
  $t->get_ok('/users/0')->status_is(200)->content_is('read,0');
  $t->get_ok('/users/-1')->status_is(404);

  # collection options
  $t->get_ok('/withoutlookup/1')->status_is(200);

  # current_id test
  $t->get_ok('/a/1')->content_is('read,1');
  $t->get_ok('/a/1/b/2')->content_is('read,2');
  $t->get_ok('/a/1/b/2/c/3')->content_is('read,3');
}

done_testing();
