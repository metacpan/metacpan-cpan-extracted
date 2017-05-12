use Mojo::Base -strict;

$ENV{MOJO_LOG_LEVEL} = 'debug';

use Test::More;
use Mojolicious::Lite;
use Test::Mojo;
use Mojolicious;

plugin 'DebugDumperHelper';

my $t   = Test::Mojo->new;
$t->app->log->path('/dev/null');
my $log = $t->app->debug(qw<Bite my shiny ass!>);

isa_ok($log, 'Mojo::Log');

my $m = Mojolicious->new();
if ($m->VERSION >= 6.47) {
    ok($log->is_level('debug'));
} else {
    ok($log->is_debug);
}

my $content = $log->history->[-1]->[-1];
like($content, qr/VAR DUMP.\[.  "Bite",.  "my",.  "shiny",.  "ass!".\]/s, "Log content");

done_testing();
