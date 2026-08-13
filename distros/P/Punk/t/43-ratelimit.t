#!perl
use strict;
use warnings;
use FindBin ();
# Prefer the sibling Hyperman build: the abuse-control arena + ABI v3 land there
# first, and an installed copy may still be v2. Harmless when it is already v3.
use lib "$FindBin::Bin/../../Hyperman/blib/lib";
use lib "$FindBin::Bin/../../Hyperman/blib/arch";
use lib "$FindBin::Bin/lib";
use Test::More;
use PunkTest;

# The counters and denylist live in Hyperman's shared arena, which the server
# maps before it forks. There is no server here, so we init the arena the way
# the ABI self-test does (a side effect of _abi_selftest) and drive the Punk
# side - the rate_limit keyword and the $c bridges - against it.
BEGIN {
    eval { require Hyperman; 1 }
        or plan skip_all => 'Hyperman not available';
    plan skip_all => 'Hyperman ABI < 3 (no arena; build/install the local Hyperman)'
        unless Hyperman->can('_abi_version') && Hyperman::_abi_version() >= 3;
    Hyperman::_abi_selftest();   # maps the shared arena as a side effect
}

# ---- the rate_limit keyword: 429 after the limit, with the headers ----------
{
    package RLApp;
    use Punk;
    rate_limit limit => 3, window => 60, by => 'ip';
    get '/' => sub { my ($c) = @_; $c->text('ok') };
    package main;
}
my $app = RLApp->to_app;
my %ip  = (env => { REMOTE_ADDR => '203.0.113.55' });

my @st = map { hit($app, %ip)->[0] } 1 .. 4;
is_deeply([ @st[0 .. 2] ], [ 200, 200, 200 ], 'the first three are allowed');
is($st[3], 429, 'the fourth is 429 Too Many Requests');

my $res = hit($app, %ip);          # still over
is($res->[0], 429, 'still limited past the window budget');
my %h = @{ $res->[1] };
ok(defined $h{'Retry-After'}, '...with Retry-After');
is($h{'X-RateLimit-Limit'},     3, '...X-RateLimit-Limit echoes the limit');
is($h{'X-RateLimit-Remaining'}, 0, '...X-RateLimit-Remaining is 0 when over');
ok($h{'X-RateLimit-Reset'} > time, '...X-RateLimit-Reset is in the future');

is(hit($app, env => { REMOTE_ADDR => '203.0.113.56' })->[0], 200,
   'a different client has its own budget');

# ---- key strategies: header, coderef, and a `for` prefix --------------------
{
    package RLApp2;
    use Punk;
    rate_limit for => '/api', by => 'header:X-Api-Key',
               limit => 2, window => 60, tag => 'api';
    rate_limit by => sub { my ($c) = @_; $c->env->{'HTTP_X_USER'} },
               limit => 2, window => 60, tag => 'user';
    get '/api/:x' => sub { my ($c) = @_; $c->text('api') };
    get '/open'   => sub { my ($c) = @_; $c->text('open') };
    package main;
}
my $app2 = RLApp2->to_app;

# header-keyed, scoped to /api: 2 then 429 for one key
my %k1 = (path => '/api/1', env => { HTTP_X_API_KEY => 'key-aaa', HTTP_X_USER => 'u1' });
my @a = map { hit($app2, %k1)->[0] } 1 .. 3;
is_deeply(\@a, [ 200, 200, 429 ], 'header-keyed limit under the /api prefix');
is(hit($app2, path => '/api/1',
       env => { HTTP_X_API_KEY => 'key-bbb', HTTP_X_USER => 'u2' })->[0], 200,
   'a different header value is a different budget');

# the coderef rule (by X-User) applies everywhere, including /open
my @b = map { hit($app2, path => '/open', env => { HTTP_X_USER => 'u9' })->[0] } 1 .. 3;
is_deeply(\@b, [ 200, 200, 429 ], 'coderef-keyed limit, not scoped to a prefix');

# a request missing the header/identity is allowed (cannot be keyed)
is(hit($app2, path => '/api/1', env => { HTTP_X_USER => 'anon' })->[0], 200,
   'no X-Api-Key on /api: that rule cannot key it, so it is allowed');

# ---- $c->rate_hit / block_ip / unblock_ip -----------------------------------
{
    my $c = Punk::Context->_build(
        { REMOTE_ADDR => '198.51.100.9', PATH_INFO => '/' }, undef, undef);

    my ($ok1, $rem1) = $c->rate_hit('unit-key', 2, 60);
    my ($ok2)        = $c->rate_hit('unit-key', 2, 60);
    my ($ok3, $rem3) = $c->rate_hit('unit-key', 2, 60);
    ok($ok1 && $ok2 && !$ok3, 'rate_hit is a fixed window (two ok, the third over)');
    is($rem1, 1, '...remaining decrements');
    is($rem3, 0, '...and floors at zero');

    is($c->block_ip('192.0.2.44', 60), 1, 'block_ip reports the block took');
    is($c->unblock_ip('192.0.2.44'),   1, 'unblock_ip too');
    is($c->block_ip, 1, 'block_ip defaults to this request REMOTE_ADDR');
    $c->unblock_ip;   # tidy the arena
}

# ---- fail open: with no arena/ABI, everything is allowed ---------------------
{
    local $ENV{PUNK_NO_HM_ABI} = 1;   # punk_hm() checks this on every call
    my $c = Punk::Context->_build({ REMOTE_ADDR => '198.51.100.10' }, undef, undef);

    my ($ok, $rem) = $c->rate_hit('x', 1, 60);
    ok($ok, 'rate_hit fails open with no ABI (allowed)');
    is($rem, 0, '...reporting limit-1 remaining');
    is($c->block_ip('1.2.3.4'), 0, 'block_ip is a no-op without the arena');

    my @s = map { hit($app, %ip)->[0] } 1 .. 6;
    is_deeply(\@s, [ (200) x 6 ], 'the rate_limit keyword fails open too');
}

done_testing;
