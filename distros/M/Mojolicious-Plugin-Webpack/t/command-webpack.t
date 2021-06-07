BEGIN {
  our $env = {};
  our $pid = 42;
  *CORE::GLOBAL::exec = sub { $env = {%$env, %ENV, exec => [@_]}; 0 };
  *CORE::GLOBAL::fork = sub { $env = {%$env, %ENV, fork => [@_]}; $pid++ };
  *CORE::GLOBAL::kill = sub { $env = {%$env, %ENV, kill => [@_]}; 0 };
}

use Mojo::Base -strict;
use Mojolicious::Command::Author::webpack;
use Test::More;

my $cmd = Mojolicious::Command::Author::webpack->new;
my $worker_pid;

is $Mojolicious::Command::Author::webpack::WORKER_PID, -1, 'worker pid is not set yet';
ok !$INC{'Mojo/Server/Morbo.pm'}, 'Mojo::Server::Morbo is not loaded yet';

$cmd->_morbo;
Mojo::Util::monkey_patch(
  'Mojo::Server::Morbo' => run => sub { $worker_pid = $Mojolicious::Command::Author::webpack::WORKER_PID });
ok $INC{'Mojo/Server/Morbo.pm'}, 'Mojo::Server::Morbo got loaded';

like $cmd->description, qr{Webpack},               'description';
like $cmd->usage,       qr{mojo webpack .*my_app}, 'usage';

ok !$worker_pid, 'worker pid';
eval { $cmd->run };
like $@, qr{exec mojo}, 'exec failed';
ok !$main::env->{fork}, 'not yet forked webpack';
is_deeply $main::env->{exec}, [mojo => webpack => $0], 'exec mojo webpack, since starting from application';

delete $main::env->{exec};
local $0 = 'mojo';
$cmd->run($0);
is_deeply $main::env->{fork}, [], 'forked webpack';
is_deeply $main::env->{kill}, [42], 'killed webpack';
ok !$main::env->{exec}, 'did not exec mojo webpack, since mojo is started';
is $worker_pid, $$, 'worker pid';

for my $arg (qw(--backend -b)) {
  $cmd->run('my_app.pl', $arg => 'Poll');
  is $ENV{MOJO_MORBO_BACKEND}, 'Poll', "arg $arg";
}

for my $arg ('', qw(--help -h)) {
  eval { $cmd->run($arg) };
  like $@, qr{mojo webpack.*my_app}, "arg $arg";
}

for my $arg (qw(--listen -l)) {
  $cmd->run($arg => 'http://*:3000', $arg => 'https://*:3443', 'my_app.pl');
  is_deeply $cmd->_morbo->daemon->listen, [qw(http://*:3000 https://*:3443)], "arg $arg";
}

for my $arg (qw(--mode -m)) {
  $cmd->run('my_app.pl', $arg => 'my_environment');
  is $ENV{MOJO_MODE}, 'my_environment', "arg $arg";
}

for my $arg (qw(--verbose -v)) {
  $cmd->run('my_app.pl', $arg);
  ok $ENV{MORBO_VERBOSE}, "arg $arg";
}

for my $arg (qw(--watch -w)) {
  $cmd->run('my_app.pl', $arg => 'bar', $arg => 'foo');
  is_deeply $cmd->_morbo->backend->watch, [qw(bar foo)], "arg $arg";
}

done_testing;
