package MyApp::Base;
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
  $name =~ s,^.*?\-,,;
  return $name;
}

1;

package MyApp::Accounts;
use Mojo::Base 'MyApp::Base';

1;

package MyApp::Accounts::Invoices;
use Mojo::Base 'MyApp::Base';

1;

package Test::Mojolicious::Plugin::Restify::Synopsis;
use Mojo::Base 'Mojolicious';

sub startup {
  my $self = shift;

  # imports the `collection' route shortcut and `restify' helpers
  $self->plugin('Restify', {over => 'int'});

  # add REST collection endpoints manually
#  my $r = $self->routes;
#  my $accounts = $r->collection('accounts');      # /accounts
#  $accounts->collection('invoices');              # /accounts/:accounts_id/invoices

  # or add the equivalent REST routes using the restify helper
  my $r = $self->routes;
  $r->namespaces(['MyApp']);
  $self->restify->routes($r, {accounts => {invoices => undef}});
}

1;

package main;
use Mojo::Base -strict;

use Test::Mojo;
use Test::More;

my $t = Test::Mojo->new('Test::Mojolicious::Plugin::Restify::Synopsis');

$t->get_ok('/accounts')->status_is(200);
$t->get_ok('/accounts/1')->status_is(200);
$t->get_ok('/accounts/1/invoices')->status_is(200);
$t->get_ok('/invoices')->status_is(404);

done_testing();

$t->app;
