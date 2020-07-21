use Mojo::Base -strict;

use Test::More;
use Mojolicious::Lite;
use Test::Mojo;
use Mojo::File qw(curfile);
use lib curfile->sibling('lib')->to_string;
use TestUtils qw(webpush_config $ENDPOINT %userdb);

plugin 'ServiceWorker';
my $webpush = plugin 'WebPush' => webpush_config();

post '/login/:user_id' => sub {
  my $c = shift;
  $c->session(user_id => $c->stash('user_id'));
  $c->render(text => 'Hello ' . $c->stash('user_id'));
};

my $t = Test::Mojo->new;
subtest 'login' => sub {
  $t->post_ok('/login/bob')->status_is(200)->content_is('Hello bob');
};

my @SUBS = (
  [ { keys => {} }, qr/no endpoint/ ],
  [ { endpoint => '/push/bob/v2' }, qr/no keys/ ],
  [ { endpoint => '/push/bob/v2', keys => { p256dh => '' } }, qr/no auth/ ],
  [ { endpoint => '/push/bob/v2', keys => { auth => '' } }, qr/no p256dh/ ],
  [ { endpoint => '/push/bob/v2', keys => { auth => '', p256dh => '' } }, qr/^$/ ],
);
subtest 'validate' => sub {
  for (@SUBS) {
    eval { Mojolicious::Plugin::WebPush::validate_subs_info($_->[0]) };
    like $@, $_->[1];
  }
};

my $bob_data = { endpoint => '/push/bob/v2', keys => { auth => '', p256dh => '' } };
subtest 'save' => sub {
  $t->post_ok($ENDPOINT, json => {})
    ->status_is(500)->json_like('/errors/0/message', qr/no endpoint/)
    ->or(sub { diag explain $t->tx->res->body })
    ;
  $t->post_ok($ENDPOINT, json => $bob_data)
    ->status_is(200)->json_is({ data => { success => 1 } })
    ->or(sub { diag explain $t->tx->res->body })
    ;
  is_deeply $userdb{bob}, $bob_data;
};

subtest 'webpush.create_p' => sub {
  my $info;
  app->webpush->create_p('bill', $bob_data)->then(sub { $info = shift })->wait;
  isnt $info, undef;
  is_deeply $userdb{bill}, $bob_data;
  delete $userdb{bill};
};

subtest 'webpush.read_p' => sub {
  my $info;
  app->webpush->read_p('bob')->then(sub { $info = shift })->wait;
  is_deeply $info, $bob_data;
  my $temp = delete $userdb{bob};
  my $rej;
  app->webpush->read_p('bob')->then(undef, sub { $rej = shift })->wait;
  isnt $rej, undef;
  $userdb{bob} = $temp;
};

subtest 'webpush.delete_p' => sub {
  my $info;
  app->webpush->delete_p('bob')->then(sub { $info = shift })->wait;
  isnt $info, undef;
};

done_testing();
