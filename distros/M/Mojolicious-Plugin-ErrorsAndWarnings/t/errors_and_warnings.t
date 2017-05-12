use Mojo::Base -strict;

BEGIN {
  # Mutes the log output from Mojolicious::Lite
  $ENV{MOJO_LOG_LEVEL} = 'error';
}

# Create a mojolicious lite app to simplify testing.

use Mojolicious::Lite;

plugin 'Mojolicious::Plugin::ErrorsAndWarnings';

app->config({
  # Warnings and error codes
  codes => {
    # Default attrs set for undefined codes
    'default'            => {status => 400},

    # Global codes
    'not_found'          => {status => 404, message => 'Not found.'},
    'forbidden'          => {status => 403, message => 'Permission denied to resource.'},
    'method_not_allowed' => {status => 405, message => 'Method not allowed.'},

    # User codes
    'user_unauthorized'  => {status => 401, message => 'User unauthorized.'},
    'user_suspended'     => {status => 401, message => 'User suspended.'},
  },
});

# ERRORS
get '/defined_error' => sub {
  my $self = shift;
  $self->add_error('user_unauthorized');
  $self->render(json => { errors => $self->errors });
};

get '/error_not_defined' => sub {
  my $self = shift;
  $self->add_error('error_not_defined');

  $self->render(json => { errors => $self->errors });
};

get '/errors_without_errors' => sub {
  my $self = shift;
  $self->render(json => { errors => $self->errors });
};

get '/extra_attr' => sub {
  my $self = shift;
  $self->add_error('type_of_pie', pie => 'cheese');
  $self->render(json => { errors => $self->errors });
};

get '/override_code' => sub {
  my $self = shift;
  $self->add_error('override', code => 'overridden');
  $self->render(json => { errors => $self->errors });
};

# Tests the lite app above.

use Test::More;
use Test::Mojo;

my $stash;
my $t = Test::Mojo->new;
$t->app->hook(after_dispatch => sub { $stash = shift->stash });

# ERRORS
$t->get_ok('/defined_error')->status_is(200)->json_has('/errors')
  ->json_is('/errors/0/code' => 'user_unauthorized')
  ->json_is('/errors/0/status' => 401)
  ->json_is('/errors/0/message' => 'User unauthorized.');

$t->get_ok('/error_not_defined')->status_is(200)->json_has('/errors')
  ->json_is('/errors/0/status' => 400)
  ->json_is('/errors/0/code' => 'error_not_defined')
  ->json_hasnt('/errors/0/message');

$t->get_ok('/errors_without_errors')->status_is(200)->json_has('/errors');

$t->get_ok('/extra_attr')->status_is(200)->json_has('/errors')
  ->json_is('/errors/0/code' => 'type_of_pie')
  ->json_is('/errors/0/pie' => 'cheese');

$t->get_ok('/override_code')->status_is(200)->json_has('/errors')
  ->json_is('/errors/0/code' => 'overridden');

# WARNINGS
# Synonym for errors, no need to test.

done_testing;
