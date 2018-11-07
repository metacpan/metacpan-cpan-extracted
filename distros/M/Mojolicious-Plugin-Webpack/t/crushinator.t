use Mojo::Base -strict;
use Mojo::File 'path';
use Test::More;

my $project_dir = path(path(path(__FILE__)->dirname)->dirname)->to_abs;
plan skip_all => $@ unless my $server_class = require($project_dir->child(qw(script crushinator)));

my $server = $server_class->new;

is $ENV{MOJO_WEBPACK_ARGS},  '',  'MOJO_WEBPACK_ARGS';
is $ENV{MOJO_WEBPACK_DEBUG}, '0', 'MOJO_WEBPACK_DEBUG';
is $ENV{MOJO_WEBPACK_LAZY},  1,   'MOJO_WEBPACK_LAZY';

is + ($server->parse_argv('my_app.pl'))[1], 'my_app.pl', 'arg my_app.pl';

for my $arg (qw(--backend -b)) {
  $server->parse_argv('my_app.pl', $arg => 'Poll');
  is $ENV{MOJO_MORBO_BACKEND}, 'Poll', "arg $arg";
}

for my $arg ('', qw(--help -h)) {
  eval { $server->parse_argv($arg) };
  like $@, qr{crushinator.*my_app}, "arg $arg";
}

for my $arg (qw(--listen -l)) {
  $server->parse_argv($arg => 'http://*:3000', $arg => 'https://*:3443', 'my_app.pl');
  is_deeply $server->daemon->listen, [qw(http://*:3000 https://*:3443)], "arg $arg";
}

for my $arg (qw(--mode -m)) {
  $server->parse_argv('my_app.pl', $arg => 'my_environment');
  is $ENV{MOJO_MODE}, 'my_environment', "arg $arg";
}

for my $arg (qw(--verbose -v)) {
  $server->parse_argv('my_app.pl', $arg);
  ok $ENV{MORBO_VERBOSE}, "arg $arg";
}

for my $arg (qw(--watch -w)) {
  $server->parse_argv('my_app.pl', $arg => 'bar', $arg => 'foo');
  is_deeply $server->backend->watch, [qw(bar foo)], "arg $arg";
}

done_testing;
