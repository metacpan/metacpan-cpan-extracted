#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use Punk::Test;

# The route options rate_limit and validate, refused at the keyword or at
# compile, by message: a `for` on a route, an option that is not one, a
# reference that is not a hashref, a count that is not positive, a limit
# that is not a count, a window that is not positive, a `by` that is a
# reference but not code or a word that is not ip or header:NAME, and a
# validate option that is not one; then the forms that are accepted, a
# header and a coderef `by` and a shared tag.

my $n = 0;
sub refuses {
    my ($re, $name, $route) = @_;
    my $pkg = 'OR' . ++$n;
    my $e = '';
    eval "package $pkg; use Punk; get '/x' => sub { \$_[0]->text('x') }, $route; $pkg->to_app; 1" or $e = $@;
    like($e, $re, $name);
}

refuses(qr/rate_limit on GET \/x takes no `for` - the route is the scope/, 'a for on a route option', q{{ rate_limit => { limit => 5, for => '/api' } }});
refuses(qr/unknown rate_limit option 'burst' on GET \/x/, 'an option that is not one', q{{ rate_limit => { limit => 5, burst => 2 } }});
refuses(qr/rate_limit on GET \/x takes a hashref of options or a count, not a ARRAY/, 'a list as the option', q{{ rate_limit => [ 5 ] }});
refuses(qr/rate_limit on GET \/x takes a positive count or a hashref of options, not 'many'/, 'a count that is not a number', q{{ rate_limit => 'many' }});
refuses(qr/rate_limit on GET \/x takes a positive count/, 'a negative count', q{{ rate_limit => -3 }});
refuses(qr/rate_limit limit on GET \/x is a count of requests/, 'a limit that is not a count', q{{ rate_limit => { limit => 'lots' } }});
refuses(qr/rate_limit window on GET \/x is a positive number of seconds/, 'a window of nothing', q{{ rate_limit => { limit => 5, window => 0 } }});
refuses(qr/rate_limit by on GET \/x is 'ip', 'header:NAME' or a coderef\b/, 'a by that is a reference but not code', q{{ rate_limit => { limit => 5, by => [] } }});
refuses(qr/rate_limit by on GET \/x is 'ip', 'header:NAME' or a coderef, not 'zone'/, 'a by that is a word that is not one', q{{ rate_limit => { limit => 5, by => 'zone' } }});
refuses(qr/unknown validate option 'bogus' on GET \/x/, 'a validate option that is not one', q{{ validate => { schema => { type => 'object' }, bogus => 1 } }});

{
    package ORok;
    use Punk;
    my $ok = sub { $_[0]->text('ok') };
    get '/key'  => $ok, { rate_limit => { limit => 2, window => 60, by => 'header:X-Api-Key' } };
    get '/code' => $ok, { rate_limit => { limit => 2, window => 60, by => sub { $_[0]->req->header('X-Who') // 'anon' } } };
    get '/a'    => $ok, { rate_limit => { limit => 2, window => 60, tag => 'shared-ab' } };
    get '/b'    => $ok, { rate_limit => { limit => 2, window => 60, tag => 'shared-ab' } };
    package main;
}
SKIP: {
    skip 'Hyperman with the arena ABI is needed for live counters', 6
        unless eval { require Hyperman; Hyperman->can('_abi_version') && Hyperman::_abi_version() >= 3 };
    Hyperman::_abi_selftest();
    my $t = Punk::Test->new('ORok');
    $t->get_ok('/key', headers => { 'X-Api-Key' => 'k1' })->status_is(200);
    $t->get_ok('/key', headers => { 'X-Api-Key' => 'k1' })->status_is(200);
    $t->get_ok('/key', headers => { 'X-Api-Key' => 'k1' })->status_is(429, 'the third request on one key is refused');
    $t->get_ok('/key', headers => { 'X-Api-Key' => 'k2' })->status_is(200, 'another key has its own budget');
    $t->get_ok('/code', headers => { 'X-Who' => 'me' })->status_is(200);
    $t->get_ok('/code', headers => { 'X-Who' => 'me' })->status_is(200);
    $t->get_ok('/code', headers => { 'X-Who' => 'me' })->status_is(429, 'a coderef names the caller');
    my %ip = (env => { REMOTE_ADDR => '198.51.100.77' });
    $t->get_ok('/a', %ip)->status_is(200);
    $t->get_ok('/b', %ip)->status_is(200);
    $t->get_ok('/a', %ip)->status_is(429, 'two routes sharing a tag spend one budget');
}

done_testing;
