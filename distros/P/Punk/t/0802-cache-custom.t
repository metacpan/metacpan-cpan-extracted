#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use lib 't/lib';
use PCConform;
use Punk::Cache;

# A backend from outside this distribution.
#
# Pluggable is a claim, and this is where it is tested rather than asserted:
# Punk::Cache::Custom is plain Perl, written from the documented contract, and
# it goes through the `cache` keyword and the conformance battery on exactly
# the same terms as the two shipped stores.

# ---- the naming convention ---------------------------------------------------
# A short backend name resolves to Punk::Cache::<Name>, which is how 'memory'
# and 'file' already work - so a custom store is configured the same way, with
# no registration step to forget and nothing in Punk to edit.
{
    my $c = Punk::Cache->new(custom => max_bytes => '1M');
    isa_ok($c->backend, 'Punk::Cache::Custom',
        "'custom' resolves to Punk::Cache::Custom");

    $c->set('k', 'v');
    is($c->get('k'), 'v', 'and the store works through the front end');
}

# A class given in full is taken as it stands, for a backend that does not
# want to live under Punk::Cache::.
{
    my $c = Punk::Cache->new('Punk::Cache::Custom', max_bytes => '1M');
    isa_ok($c->backend, 'Punk::Cache::Custom', 'a full class name is used as given');
}

# ---- what happens when it is not there ---------------------------------------
{
    my $err = do { local $@; eval { Punk::Cache->new('nosuch') }; $@ };
    like($err, qr/Punk::Cache::Nosuch/,
        'an unknown backend names the CLASS it looked for - which is the one '
      . 'piece of information needed to fix it');
    like($err, qr/memory/, 'and still mentions the shipped ones');

    $err = do { local $@; eval { Punk::Cache->new('/etc/passwd') }; $@ };
    like($err, qr/not a usable backend name/,
        'a backend name that is a path is refused before it reaches require');
}

# ---- the contract is checked at construction, not at first use ---------------
{
    package Bad::Store;
    sub new    { bless {}, shift }
    sub get    { }
    sub set    { }
    sub delete { }
    sub clear  { }
    # no stats

    package main;
    my $err = do { local $@; eval { Punk::Cache->new('Bad::Store') }; $@ };
    like($err, qr/must implement stats/,
        'a backend missing a contract method is refused AT BOOT, naming the '
      . 'method - not on the first request that happens to call it');
}

# ---- a backend declared inline, with no .pm to load --------------------------
{
    package Inline::Store;
    sub new    { bless { h => {} }, shift }
    sub get    { $_[0]{h}{ $_[1] } }
    sub set    { $_[0]{h}{ $_[1] } = $_[2]; 1 }
    sub delete { defined delete $_[0]{h}{ $_[1] } ? 1 : 0 }
    sub clear  { %{ $_[0]{h} } = (); 1 }
    sub stats  { (entries => scalar keys %{ $_[0]{h} }) }

    package main;
    my $c = Punk::Cache->new('Inline::Store');
    $c->set('k', 'v');
    is($c->get('k'), 'v',
        'a backend declared in the application file works - there is no .pm '
      . 'to find, and that is legitimate rather than an error');
}

# ---- the keyword -------------------------------------------------------------
{
    package CustomApp;
    use Punk;
    use lib 't/lib';

    cache 'custom', max_bytes => '1M';

    get '/hit' => sub {
        my ($c) = @_;
        $c->text($c->cache->compute('k', 60, sub { 'computed' }));
    };

    package main;
    my $app = CustomApp->to_app;
    isa_ok(CustomApp->punk_app->{cache}{default}->backend, 'Punk::Cache::Custom',
        "cache 'custom' builds a Punk::Cache::Custom store");

    my $res = $app->({ REQUEST_METHOD => 'GET', PATH_INFO => '/hit',
                       'psgi.input' => undef, 'psgi.errors' => \*STDERR });
    is($res->[2][0], 'computed', 'and compute runs through it');
}

# ---- a ready-made object through the keyword ---------------------------------
# This one was silently wrong: the keyword ignored a reference, so the store
# handed to it was dropped and a FILE cache was built instead - a backend
# swapped out underneath an application that had asked for a specific one.
{
    package ObjApp;
    use Punk;
    use lib 't/lib';

    cache(Punk::Cache::Custom->new(max_bytes => 65_536));

    package main;
    ObjApp->to_app;
    my $store = ObjApp->punk_app->{cache}{default};
    isa_ok($store->backend, 'Punk::Cache::Custom',
        'the OBJECT handed to the keyword is the one that ends up in the app');
    my %s = $store->backend->stats;
    is($s{max_bytes}, 65_536,
        'with its own configuration intact, not a default from a store it '
      . 'was quietly replaced by');
}

# ---- a named custom store ----------------------------------------------------
{
    package NamedApp;
    use Punk;
    use lib 't/lib';

    cache pages => { backend => 'custom', max_bytes => '2M' };

    package main;
    NamedApp->to_app;
    my $store = NamedApp->punk_app->{cache}{pages};
    isa_ok($store->backend, 'Punk::Cache::Custom', 'a NAMED custom store');
    my %s = $store->backend->stats;
    is($s{max_bytes}, 2 * 1024 * 1024, 'and its options reached it');
}

# ---- the battery -------------------------------------------------------------
# The same assertions the shipped stores answer. A third-party backend passing
# them unmodified is what makes the contract a contract: it was written down,
# somebody else implemented it, and the behaviour came out identical.
conformance(sub { Punk::Cache::Custom->new(@_) }, 'custom');

done_testing;
