use Mojolicious::Lite;

any '/' => { text => 'Hello World'};

use Test::More;
use Test::Mojo;

use Mojo::Phantom;

my $t = Test::Mojo->new;

my $phantom = Mojo::Phantom->new(
  base => $t->ua->server->nb_url,
);

subtest 'invoke CORE::die' => sub {
  my ($error, $status);
  my $cb = sub { (undef, $error, $status) = @_ };
  my $proc = $phantom->execute_url('/', <<'  JS', $cb);
    perl('ok', 1, 'dummy test from javascript');
    perl('CORE::die', "argh\n");
    //while (1) { i++ }
    perl('fail', "don't get here");
  JS

  my $closed = 0;
  $proc->on(close => sub { $closed++; Mojo::IOLoop->stop });
  Mojo::IOLoop->start;
  ok $closed, 'emitted the close event';

  chomp($error);
  is $error, 'argh', 'got the right error';
};

subtest 'js side error' => sub {
  my ($error, $status);
  my $cb = sub { (undef, $error, $status) = @_ };
  my $proc = $phantom->execute_url('/', <<'  JS', $cb);
    perl('ok', 1, 'dummy test from javascript');
    page.evaluate(function(){
      window.dozNotExistz();
    });
    perl('fail', "don't get here");
  JS

  my $closed = 0;
  $proc->on(close => sub { $closed++; Mojo::IOLoop->stop });
  Mojo::IOLoop->start;
  ok $closed, 'emitted the close event';

  chomp($error);
  like $error, qr/PHANTOM ERROR.*dozNotExistz/, 'got the right error';
};

subtest 'stream exception' => sub {
  my ($error, $status);
  my $cb = sub { (undef, $error, $status) = @_ };
  my $proc = $phantom->execute_url('/', <<'  JS', $cb);
    perl('ok', 1, 'dummy test which does not actually occur');
    perl('fail', "don't get here");
  JS

  $proc->unsubscribe('read')->on(read => sub { shift->stream->emit(error => 'argh') });
  my $closed = 0;
  $proc->on(close => sub { $closed++; Mojo::IOLoop->stop });
  Mojo::IOLoop->start;
  ok $closed, 'emitted the close event';

  chomp($error);
  is $error, 'argh', 'got the right error';
};

done_testing;

