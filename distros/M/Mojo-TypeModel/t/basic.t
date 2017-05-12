use Mojo::Base -strict;

use Mojolicious;
use Test::More;
use Test::Mojo;

{
  package Local::Model;
  use Mojo::Base 'Mojo::TypeModel';

  has config => sub { {} };

  sub copies { state $copies = [qw/config/] }

  sub types { state $types = { user => 'Local::Model::User' } }
}

{
  package Local::Model::User;

  use Mojo::Base 'Local::Model';

  sub user_exists {
    my ($self, $user) = @_;
    return exists $self->config->{users}{$user};
  }
}

my $model = Local::Model->new(
  config => {users => {bender => 1}},
);

isa_ok $model, 'Local::Model';
isa_ok $model, 'Mojo::TypeModel';
isa_ok $model, 'Mojo::Base';

subtest 'direct user model use' => sub {
  my $user_model = $model->model('user');

  isa_ok $user_model, 'Local::Model::User';
  isa_ok $user_model, 'Local::Model';
  isa_ok $user_model, 'Mojo::TypeModel';
  isa_ok $user_model, 'Mojo::Base';

  is_deeply $user_model->config, {users => {bender => 1}}, 'data copied';
  ok $user_model->user_exists('bender'), 'model method works as expected';
  ok !$user_model->user_exists('leela'), 'model method works as expected';
};

subtest 'direct user model use with override' => sub {
  my $user_model = $model->model('user', config => {users => {leela => 1}});

  is_deeply $user_model->config, {users => {leela => 1}}, 'data overriden';
  ok !$user_model->user_exists('bender'), 'model method works as expected';
  ok $user_model->user_exists('leela'), 'model method works as expected';
};

subtest 'direct user model use with undef override' => sub {
  my $user_model = $model->model('user', config => undef);

  ok ! defined $user_model->config, 'data overridden';
};


subtest plugin => sub {
  my $app = Mojolicious->new;
  $app->plugin(TypeModel => { base => $model });
  $app->routes->get('/user/:user' => sub {
    my $c = shift;
    my $exists = $c->model->user->user_exists($c->stash('user'));
    $c->rendered($exists ? 200 : 404);
  });

  my $t = Test::Mojo->new($app);
  $t->get_ok('/user/bender')->status_is(200);
  $t->get_ok('/user/leela')->status_is(404);
};

done_testing;

