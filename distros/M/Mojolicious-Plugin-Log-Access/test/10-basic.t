use Mojo::Base -strict;
use Test::More;
use Mojolicious::Lite;
use Test::Mojo;

plugin 'Mojolicious::Plugin::Log::Access';

get '/' => sub { shift->render(text => 'Hello Mojo!') };

get '/scram' => sub { shift->redirect_to('/')->render(text => 'Redirecting!') };

# All of this is borrowed from Mojolicious

my $t = Test::Mojo->new;
my $log = '';
my $cb = $t->app->log->on(message => sub { $log .= pop });
$t->app->log->level('debug');
$t->get_ok('//127.0.0.1/')->status_is(200)->content_is('Hello Mojo!');
like $log, qr{127.0.0.1 \"/\" 200}, 'Right message';

$log = '';
$t->ua->max_redirects(0);
$t->app->log->level('info');
$t->get_ok('//127.0.0.1/scram')->status_is(302)->content_is('Redirecting!');
like $log, qr{127.0.0.1 \"/scram\" 302}, q{Right message under 'info'};

$log = '';
$t->ua->max_redirects(1);
$t->get_ok('//127.0.0.1/scram')->status_is(200)->content_is('Hello Mojo!');
like $log, qr{127.0.0.1 \"/scram\" 302}, q{Logged the redirect};
like $log, qr{127.0.0.1 \"/\" 200}, q{Logged the successful target get};
$t->app->log->unsubscribe(message => $cb);

done_testing();
