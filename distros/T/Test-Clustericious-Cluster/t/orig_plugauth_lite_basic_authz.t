use strict;
use warnings;
use Test2::Bundle::More;
use Test::Mojo;
use Mojolicious::Lite;

plugin 'plug_auth_lite', {
  auth => sub {
    my($user, $pass) = @_;
    return 1;
  },
  authz => sub {
    my($user, $action, $resource) = @_;
    note "user = $user";
    note "action = $action";
    note "resource = $resource";
    return 1 if $user eq 'optimus'
             && $action eq 'open'
             && $resource eq '/matrix';
  }, 
};

my $t = Test::Mojo->new;

$t->get_ok('/')
  ->status_is(404);

$t->get_ok('/authz/user/optimus/open/matrix')
  ->status_is(200)
  ->content_is('ok');

$t->get_ok('/authz/user/galvatron/open/matrix')
  ->status_is(403)
  ->content_is('not ok');


done_testing;
