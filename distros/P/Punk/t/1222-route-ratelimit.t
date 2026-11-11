#!perl
use strict;
use warnings;
use FindBin ();
# Prefer the sibling Hyperman build, for the reason t/1220-ratelimit.t gives:
# the abuse-control arena and ABI v3 land there first.
use Config;
use lib grep { -e "$_/auto/Hyperman/Hyperman.$Config{dlext}" } "$FindBin::Bin/../../Hyperman/blib/arch";
use lib grep { -e "$_/../arch/auto/Hyperman/Hyperman.$Config{dlext}" } "$FindBin::Bin/../../Hyperman/blib/lib";
use lib "$FindBin::Bin/lib";
use Test::More;
use Punk::Test;

# The `rate_limit` ROUTE option: one budget for one route, compiled into a
# guard at to_app rather than a hook that runs on everything.
#
# The counters live in Hyperman's shared arena, which a server maps before it
# forks. There is no server here, so the arena is mapped the way t/1220 maps
# it and the guards are driven against it.

BEGIN {
    eval { require Hyperman; 1 }
        or plan skip_all => 'Hyperman not available';
    plan skip_all => 'Hyperman ABI < 3 (no arena; build/install the local Hyperman)'
        unless Hyperman->can('_abi_version') && Hyperman::_abi_version() >= 3;
    Hyperman::_abi_selftest();   # maps the shared arena as a side effect
}

# Every case uses an address of its own: the arena outlives a request, so two
# cases sharing a client would spend one budget between them.
my $ip = 0;
sub client { return { REMOTE_ADDR => '198.51.100.' . ++$ip } }

{
    package RLRoute;
    use Punk;

    my $ok = sub { $_[0]->text('ok') };

    get  '/limited'   => $ok, { rate_limit => { limit => 2, window => 60 } };
    get  '/free'      => $ok;
    get  '/short'     => $ok, { rate_limit => 2 };
    get  '/off'       => $ok, { rate_limit => 0 };

    # one budget between two routes, which is what naming a tag is for
    my %auth = ( limit => 3, window => 60, tag => 'rl-test-auth' );
    post '/login'     => $ok, { rate_limit => \%auth };
    post '/register'  => $ok, { rate_limit => \%auth };

    get  '/by-header' => $ok,
        { rate_limit => { limit => 1, by => 'header:X-Api-Key' } };
    get  '/by-code'   => $ok,
        { rate_limit => { limit => 1, by => sub {
              return $_[0]->req->header('x-tenant');
          } } };

    # the ordering claim: a request over its budget is refused before the
    # body it would have had to parse
    post '/checked'   => $ok, {
        rate_limit => { limit => 1, window => 60 },
        validate   => { schema => { type       => 'object',
                                    required   => ['name'],
                                    properties => { name => { type => 'string' } } },
                        source => 'json' },
    };

    my $under = under '/api';
    $under->get('/thing' => $ok, { rate_limit => { limit => 1 } });
}

my $t = Punk::Test->new('RLRoute');

# ---- one route, one budget ---------------------------------------------------
{
    my $c = client();
    $t->get_ok('/limited', env => $c)->status_is(200, 'the first is allowed');
    $t->get_ok('/limited', env => $c)->status_is(200, 'and the second');
    $t->get_ok('/limited', env => $c)->status_is(429, 'the third is refused');
    $t->header_is('X-RateLimit-Limit', 2, 'the limit is reported');
    $t->header_is('X-RateLimit-Remaining', 0, 'and nothing is left');
    ok(defined $t->header('Retry-After'), 'and when to come back');
    $t->content_like(qr/rate limit exceeded/, 'the problem+json body');

    # the counter is this route's own
    $t->get_ok('/free', env => $c)
      ->status_is(200, 'a route with no budget is untouched by another one');
    $t->get_ok('/short', env => $c)
      ->status_is(200, 'and a route with its own budget has not spent it');
}

# ---- a different client has its own ------------------------------------------
{
    $t->get_ok('/limited', env => client())
      ->status_is(200, 'another address starts at zero');
}

# ---- the count shorthand -----------------------------------------------------
{
    my $c = client();
    $t->get_ok('/short', env => $c)->status_is(200, 'shorthand: one');
    $t->get_ok('/short', env => $c)->status_is(200, 'shorthand: two');
    $t->get_ok('/short', env => $c)
      ->status_is(429, 'rate_limit => N is N in the default window');
}

# ---- 0 is what a route says by saying nothing --------------------------------
{
    my $c = client();
    $t->get_ok('/off', env => $c)->status_is(200) for 1 .. 4;
    $t->status_is(200, 'rate_limit => 0 declares no budget at all');
}

# ---- a tag shares one budget across routes -----------------------------------
{
    my $c = client();
    $t->post_ok('/login',    env => $c)->status_is(200, 'shared: login');
    $t->post_ok('/register', env => $c)->status_is(200, 'shared: register');
    $t->post_ok('/login',    env => $c)->status_is(200, 'shared: login again');
    $t->post_ok('/register', env => $c)
      ->status_is(429, 'a tag spends one budget across every route naming it');
}

# ---- by => header ------------------------------------------------------------
{
    $t->get_ok('/by-header', env => client(),
               headers => { 'X-Api-Key' => 'key-one' })
      ->status_is(200, 'by header: the first');
    $t->get_ok('/by-header', env => client(),
               headers => { 'X-Api-Key' => 'key-one' })
      ->status_is(429, 'the same key is the same caller, whatever the address');
    $t->get_ok('/by-header', env => client(),
               headers => { 'X-Api-Key' => 'key-two' })
      ->status_is(200, 'and another key is another caller');
}

# ---- by => coderef -----------------------------------------------------------
{
    $t->get_ok('/by-code', env => client(),
               headers => { 'X-Tenant' => 'acme' })
      ->status_is(200, 'by coderef: the first');
    $t->get_ok('/by-code', env => client(),
               headers => { 'X-Tenant' => 'acme' })
      ->status_is(429, 'the coderef names the caller');
    $t->get_ok('/by-code', env => client(),
               headers => { 'X-Tenant' => 'other' })
      ->status_is(200, 'and a different one has its own budget');
}

# ---- before validate ---------------------------------------------------------
{
    my $c = client();
    $t->post_ok('/checked', env => $c, json => { name => 'ok' })
      ->status_is(200, 'a valid body inside the budget');
    $t->post_ok('/checked', env => $c, json => { name => 'ok' })
      ->status_is(429, 'over the budget, with a body that would have passed');
    $t->post_ok('/checked', env => $c, json => { nope => 1 })
      ->status_is(429,
        'a request over its budget is refused before its body is validated');
}

# ---- under a scope -----------------------------------------------------------
{
    my $c = client();
    $t->get_ok('/api/thing', env => $c)->status_is(200, 'scoped: allowed');
    $t->get_ok('/api/thing', env => $c)
      ->status_is(429, 'a scope prefix reaches the compiled record too');
}

# ---- what the option refuses at boot -----------------------------------------

my @bad = (
    [ 'an unknown key' => "{ limit => 1, nope => 1 }",
      qr/unknown rate_limit option 'nope'/ ],
    [ 'for'            => "{ limit => 1, for => '/x' }",
      qr/takes no `for`/ ],
    [ 'a bad by'       => "{ by => 'session' }",
      qr/rate_limit by on GET \/x is/ ],
    [ 'a bad window'   => "{ window => 0 }",
      qr/window on GET \/x is a positive number/ ],
    [ 'a word'         => "'lots'",
      qr/takes a positive count or a hashref/ ],
    [ 'an arrayref'    => "[ 1 ]",
      qr/takes a hashref of options or a count/ ],
);
my $n = 0;
for my $case (@bad) {
    my ($what, $spell, $want) = @$case;
    $n++;
    eval qq{
        package RLBad$n;
        use Punk;
        get '/x' => sub { 1 }, { rate_limit => $spell };
        __PACKAGE__->to_app;
        1;
    };
    like($@, $want, "$what croaks at boot");
}

done_testing;
