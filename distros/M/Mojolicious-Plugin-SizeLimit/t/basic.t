use Mojo::Base -strict;

use Test::More;
use Mojo::IOLoop;
use Mojolicious::Lite;
use Test::Mojo;

require Mojolicious::Plugin::SizeLimit;

my ($total, $shared) = Mojolicious::Plugin::SizeLimit::check_size();

unless (ok $total, "OS ($^O) is supported") {
    done_testing();
    exit 0;
}

my ($p, $v);

if ($shared) {
    $p = 'max_unshared_size';
    $v = int(($total - $shared) / 2);
}
else {
    # no information available for shared (Solaris)
    $p = 'max_process_size';
    $v = int($total / 2);
}

plugin 'SizeLimit', $p => $v, check_interval => 2, report_level => 'info';

get '/' => sub {
  my $c = shift;
  $c->render(text => $$);
};

my $t = Test::Mojo->new;

my $stopped = 0;

Mojo::IOLoop->singleton->on(finish => sub { $stopped = 1 });

ok !$stopped, "worker is alive";

$t->get_ok('/')
    ->status_is(200)
    ->content_is($$);

ok !$stopped, "worker is alive";

$t->get_ok('/')
    ->status_is(200)
    ->content_is($$)
    ->header_is(Connection => 'close')
    ->or(
        sub {
            my ($size, $shared) = Mojolicious::Plugin::SizeLimit::check_size($t->app);
            diag "plugin 'SizeLimit', $p => '$v', check_interval => 2;";
            diag "current size = $size, shared = $shared";
        }
    );

ok $stopped, "worker is stopped";

done_testing();
