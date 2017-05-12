use Mojo::Base -strict;

BEGIN {
  # Mutes the log output from Mojolicious::Lite
  $ENV{MOJO_LOG_LEVEL} = 'error';
}

# Create a mojolicious lite app to simplify testing.

use Mojolicious::Lite;

plugin 'ErrorsAndWarnings';

app->config({
  # config_key attribute is `codes' by default
  codes => {
      # Default key/values merged for unmatched code names
    'default'            => {status => 400},

    # Global codes
    'forbidden'          => {status => 403, title => 'Permission denied to resource.'},
    'not_found'          => {status => 404, title => 'Not found.'},
    'method_not_allowed' => {status => 405, title => 'Method not allowed.'},
  },
});

get '/' => sub {
  my $c = shift;

  $c->add_error('not_found');
  $c->add_error('user_defined_err', foo => 'bar bar' );

  # {
  #    "errors": [
  #        {
  #            "code": "not_found",
  #            "status": 404,
  #            "message": "Not found."
  #        },
  #        {
  #            "code": "user_defined_err",
  #            "status": 400,
  #            "foo": "bar bar"
  #        }
  #    ]
  # }
  $c->render(json => { errors => $c->errors });
};

# Tests the lite app above.

use Test::More;
use Test::Mojo;

my $t = Test::Mojo->new;

$t->get_ok('/.json')->status_is(200)->json_has('/errors')
  ->json_is('/errors/0/status' => 404)
  ->json_is('/errors/0/code'   => 'not_found')
  ->json_is('/errors/0/title'  => 'Not found.')
  ->json_is('/errors/1/status' => 400)
  ->json_is('/errors/1/code'   => 'user_defined_err');

done_testing;
