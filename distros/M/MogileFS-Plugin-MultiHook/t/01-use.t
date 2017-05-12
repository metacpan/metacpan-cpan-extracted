use Test::More tests => 5;

use MogileFS::Server;
use MogileFS::Config;

{
    local @ARGV = qw/--skipconfig --plugins MultiHook/;

    eval {
        MogileFS::Config->load_config;
    };
    ok(!$@);
    ok(MogileFS->can("global_hook"));
    ok(MogileFS::register_global_hook("test", sub { my $args = shift; $args->{test} += 1;  1; }));
    ok(MogileFS::register_global_hook("test", sub { my $args = shift; $args->{test} *= 2; 1; }));

    my $args = { test => 1 };
    MogileFS::run_global_hook("test", $args);
    is($args->{test}, 4);
}
