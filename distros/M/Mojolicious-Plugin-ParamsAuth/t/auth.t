use Test::More;
use Test::Mojo;
use Data::Dumper;
use Mojo::Parameters;

# Make sure sockets are working
plan skip_all => 'working sockets required for this test!'
  unless Mojo::IOLoop->new->generate_port;    # Test server

plan tests => 14;

# Lite app
use Mojolicious::Lite;

# Silence
app->log->level('error');

plugin 'params_auth';

get '/' => sub {
    my $self = shift;

    return $self->render(text => 'ok')
      if $self->params_auth(
              userinput => passinput =>
                sub { return 1 if "@_" eq 'username password' }
      );

    return $self->render(text => '', status => 401);
};

# Tests
my $t = Test::Mojo->new;

$t->get_ok('/')->status_is(401);
$t->get_ok('/?userinput=&passinput=')->status_is(401);
$t->get_ok('/?userinput=not&passinput=valid')->status_is(401);
$t->get_ok('/?userinput=username&passinput=password')->status_is(200)
  ->content_is('ok');

# Array params - take first parameter
$t->get_ok(
    '/?userinput=no&userinput=username&passinput=no&passinput=password')
  ->status_is(401);
$t->get_ok(
    '/?userinput=username&userinput=no&passinput=password&passinput=no')
  ->status_is(200)->content_is('ok');
