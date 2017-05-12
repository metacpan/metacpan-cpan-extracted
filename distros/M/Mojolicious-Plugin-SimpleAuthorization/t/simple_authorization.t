use Mojo::Base -strict;

BEGIN {
  $ENV{MOJO_LOG_LEVEL} = 'error';
}

# Create a mojolicious lite app to simplify testing

use Mojolicious::Lite;

plugin 'SimpleAuthorization' => {
  superuser => sub { shift->{administrator} == 1 },
  on_assert_failure => sub {
    my $self = shift;
    $self->render(
      json   => {errors => [{message => 'Permission denied to resource.'}]},
      status => 403
    );
  }
};

under sub {
  my $self = shift;
  # Default user for tests. Attributes will be overwritten where necessary.
  $self->stash->{user} = {
    username      => 'paul.williams',
    password      => 'ihatekarl',
    administrator => 0,
  };
};

get '/assert_administrator_role' => sub {
  my $self = shift;
  $self->stash->{user}->{administrator} = 1;
  my $assert = $self->assert_user_roles('companies');
  $self->render(json => { assert => $assert });
};

get '/is_administrator' => sub {
  my $self = shift;
  $self->stash->{user}->{administrator} = 1;
  return unless my $assert = $self->assert_user_roles('companies');
  return unless $assert = $self->assert_user_roles('aaargh');
  # Assert should authorise all roles when administrator, regardless of if the
  # role exists or not.
  $self->render(json => { assert => $assert });
};

get '/is_not_administrator' => sub {
  my $self = shift;
  return unless my $assert = $self->assert_user_roles('companies');
  # This code shouldn't execute as they're not the administrator.
  $self->render(json => { assert => $assert });
};

get '/assert_user_role_greetings' => sub {
  my $self =  shift;
  $self->stash->{roles} = { 'greetings' => '1' };
  my $assert = $self->assert_user_roles('greetings');
  $self->render(json => { assert => $assert });
};

get '/assert_any_greetings_role' => sub {
  my $self =  shift;
  $self->stash->{roles} = { 'greetings.editor' => '1', 'greetings.read' => 1 };
  my $assert = $self->assert_user_roles([qw/greetings.editor greetings.update/]);
  $self->render(json => { assert => $assert });
};

get '/assert_user_role_that_doesnt_exist' => sub {
  my $self =  shift;
  $self->stash->{roles} = { 'greetings' => '1' };
  my $assert = $self->assert_user_roles('ohreally');
  $self->render(json => { assert => $assert });
};

get '/dont_raise_error_1' => sub {
  my $self = shift;
  my $assert = $self->check_user_roles('companies');
  $self->render(json => {assert => $assert});
};

get '/dont_raise_error_2' => sub {
  my $self = shift;
  $self->stash->{roles} = {'companies' => '1'};
  my $assert = $self->check_user_roles('companies');
  $self->render(json => {assert => $assert});
};

get '/will_raise_error' => sub {
  my $self = shift;
  my $assert = $self->assert_user_roles('companies');
  $self->render(json => {assert => $assert});
};

get '/user_defined_cb_good' => sub {
  my $self = shift;
  my $assert = $self->assert_user_roles('companies', sub { 1 });
  $self->render(json => {assert => $assert});
};

get '/user_defined_cb_bad' => sub {
  my $self = shift;
  $self->stash->{user}->{administrator} = 1;
  # Even though the user is an admin, this should return with a 403
  my $assert = $self->assert_user_roles('companies', sub { 0 });
  $self->render(json => {assert => 0});
};

get '/user_defined_cb_continue' => sub {
  my $self = shift;
  $self->stash->{user}->{administrator} = 1;
  my $assert = $self->assert_user_roles('companies', sub { undef });
  $self->render(json => {assert => $assert});
};

get '/user_defined_cb_user' => sub {
  my $self = shift;
  my $assert = $self->assert_user_roles('companies',
    sub { return 1 if shift->{username} eq 'paul.williams' });
  $self->render(json => {assert => $assert});
};

get '/user_defined_cb_user_bad' => sub {
  my $self = shift;
  my $assert = $self->assert_user_roles('companies',
    sub { return 1 if shift->{username} eq 'harry.seccombe' });
  $self->render(json => {assert => $assert});
};

get '/add_role_for_check' => sub {
  my $self = shift;
  my $assert = $self->check_user_roles(
    'you_shouldnt_have_this_role',
    sub {
      my ($user, $roles) = @_;
      $roles->{'you_shouldnt_have_this_role'}++;
      return undef;
    }
  );
  $self->render(json => {assert => $assert});
};

# Tests the lite app above.

use Test::More;
use Test::Mojo;

my $t = Test::Mojo->new;

$t->get_ok('/assert_administrator_role.json')->status_is(200)
  ->json_is('/assert' => 1);

$t->get_ok('/is_administrator.json')->status_is(200)->json_is('/assert' => 1);

$t->get_ok('/is_not_administrator.json')->status_is(403)->json_has('/errors')
  ->json_is('/errors/0/message' => 'Permission denied to resource.');

$t->get_ok('/assert_user_role_greetings.json')->status_is(200)
  ->json_is('/assert' => 1);

$t->get_ok('/assert_any_greetings_role.json')->status_is(200)
  ->json_is('/assert' => 1);

$t->get_ok('/assert_user_role_that_doesnt_exist.json')->status_is(403)
  ->json_is('/assert' => 0);

$t->get_ok('/dont_raise_error_1.json')->status_is(200)
  ->json_is('/assert' => 0);

$t->get_ok('/dont_raise_error_2.json')->status_is(200)
  ->json_is('/assert' => 1);

$t->get_ok('/will_raise_error.json')->status_is(403)->json_is('/assert' => 0);

$t->get_ok('/user_defined_cb_good.json')->status_is(200)
  ->json_is('/assert' => 1);

$t->get_ok('/user_defined_cb_bad.json')->status_is(403)
  ->json_is('/assert' => 0);

$t->get_ok('/user_defined_cb_continue.json')->status_is(200);

$t->get_ok('/user_defined_cb_user.json')->status_is(200)
  ->json_is('/assert' => 1);

$t->get_ok('/user_defined_cb_user_bad.json')->status_is(403)
  ->json_is('/assert' => 0);

$t->get_ok('/add_role_for_check.json')->status_is(200)
  ->json_is('/assert' => 1);

done_testing;
