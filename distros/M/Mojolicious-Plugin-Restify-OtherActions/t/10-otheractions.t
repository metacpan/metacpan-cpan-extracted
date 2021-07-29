use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

my $t = Test::Mojo->new('Test::Mojolicious::Plugin::Restify::OtherActions');

# call standard methods
$t->get_ok("/rest/test/2")->status_is(200)->content_is('read,2', "Original get element");
$t->get_ok("/rest/test")->status_is(200)->content_is('list,', "Original list call");

# call alternative methods
$t->get_ok("/rest/test/list/baz")->status_is(200)->json_is('/a' => 1, "Alternative method");
# with parameters
$t->get_ok("/rest/test/list/bac/2")->status_is(200)->json_is('/a' => 2, "with parameters");

done_testing();

package Test::Mojolicious::Plugin::Restify::OtherActions;
use Mojo::Base 'Mojolicious';

sub startup {
    my $self = shift;
    $self->secrets(["sssshhhhhh!"]);

    # Load the plugin
    $self->plugin('Restify::OtherActions');

    my $r = $self->routes;

    my $rest = $r->under('/rest')->to(namespace => 'rest', cb => sub {1});
    $self->restify->routes($rest, ['test']);
}

1;

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
sub list            {
    my $c = shift;
    my $query =  $c->stash('query');
    return $c->$query if ($query);
    $c->catchall('list')
}
sub read            { shift->catchall('read') }
sub update          { shift->catchall('update') }

sub name {
  my $self = shift;
  my $name = $self->stash->{controller};
  $name =~ s,^.*\-,,;
  return $name;
}

sub render_json {
	my $c		= shift;
	my $json	= shift;
	my $status	= shift || 200;
	$c->render(json => $json, status => $status)
}

1;

package rest::Test;
use Mojo::Base 'My::Mojo::App::Base';

sub baz {
    shift->render_json({a => 1});
}

sub bac {
    my $c = shift;
    $c->render_json({a => $c->stash('opt')});
}
