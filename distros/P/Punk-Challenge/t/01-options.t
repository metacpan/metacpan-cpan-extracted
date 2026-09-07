#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Punk ();
use Punk::Plugin::Challenge ();

# Real Punk classes, not a hand-rolled Punk::App: `register` records onto the
# application, and a stand-in would prove nothing about what `plugin` hands
# it.

our %OPTS;
my $N = 0;

sub build {
    my (%o) = @_;
    my $pkg = 'ChalOpt' . ++$N;
    local %OPTS = %o;
    local $@;
    my $ok = eval "package $pkg; use Punk; plugin 'Challenge' => { \%main::OPTS }; 1";
    return ($pkg, $ok ? undef : $@);
}

sub opts_of { Punk::Plugin::Challenge::_opts($_[0]->punk_app) }

# ---- the secret is configuration and is never generated -------------------

{
    my ($pkg, $err) = build();
    like($err, qr/`secret` is required/, 'no secret croaks');
    like($err, qr/punk challenge key/, '  and the message names the command');
    is(opts_of($pkg), undef, '  and nothing was recorded on the application');
}

{
    my ($pkg, $err) = build(secret => '');
    like($err, qr/`secret` is required/, 'an empty secret is no secret');
    is(opts_of($pkg), undef, '  and nothing was minted in its place');
}

{
    my ($pkg, $err) = build(secret => []);
    like($err, qr/`secret` is required/, 'an empty list is no secret');
}

{
    my ($pkg, $err) = build(secret => [ '', undef ]);
    like($err, qr/`secret` is required/, 'a list of nothing is no secret');
}

{
    my ($pkg, $err) = build(secret => {});
    like($err, qr/`secret` must be a string or a list/, 'a hashref is refused');
}

{
    my ($pkg, $err) = build(secret => [ 'a', [] ]);
    like($err, qr/every `secret` must be a string/, 'a nested reference is refused');
}

# ---- a typo must not pass silently ----------------------------------------

{
    my ($pkg, $err) = build(secret => 'k', bitz => 20);
    like($err, qr/unknown option 'bitz'/, 'an unknown option croaks');
    like($err, qr/known: secret, prefix, bits/, '  naming what was available');
}

# ---- defaults --------------------------------------------------------------

{
    my ($pkg, $err) = build(secret => 'k');
    is($err, undef, 'a secret alone is a valid configuration') or diag $err;
    my $o = opts_of($pkg);
    is_deeply($o->{secret}, ['k'], 'one secret is stored as a list of one');
    is($o->{prefix},     '/challenge',  'prefix default');
    is($o->{bits},       16,            'bits default');
    is($o->{ttl},        3600,          'ttl default');
    is($o->{puzzle_ttl}, 300,           'puzzle_ttl default');
    is($o->{bind},       'prefix',      'bind default');
    is($o->{cookie},     '_clearance',  'cookie default');
    is_deeply($o->{exempt}, [],         'exempt default');
    ok(!defined $o->{render},           'render default');
    is($o->{assets},     1,             'assets default');
}

# ---- rotation keeps the order -----------------------------------------------

{
    my ($pkg, $err) = build(secret => [ 'new', 'old' ]);
    is($err, undef, 'a list of secrets is accepted');
    is_deeply(opts_of($pkg)->{secret}, [ 'new', 'old' ], '  in the order given');
}

# ---- each option's failure mode ---------------------------------------------

{
    my ($pkg, $err) = build(secret => 'k', bits => 0);
    like($err, qr/`bits` must be between 1 and 22/, 'bits 0 croaks');
    ($pkg, $err) = build(secret => 'k', bits => 23);
    like($err, qr/`bits` must be between 1 and 22/, 'bits 23 croaks');
    ($pkg, $err) = build(secret => 'k', bits => 'x');
    like($err, qr/`bits` must be a number/, 'bits x croaks');
    ($pkg, $err) = build(secret => 'k', bits => 22);
    is($err, undef, 'bits 22 is the ceiling and is accepted');
    is(opts_of($pkg)->{bits}, 22, '  and recorded');
}

{
    my ($pkg, $err) = build(secret => 'k', ttl => 0);
    like($err, qr/`ttl` must be between/, 'ttl 0 croaks');
    ($pkg, $err) = build(secret => 'k', puzzle_ttl => -1);
    like($err, qr/`puzzle_ttl` must be between/, 'puzzle_ttl -1 croaks');
}

{
    my ($pkg, $err) = build(secret => 'k', bind => 'header');
    like($err, qr/`bind` must be 'prefix', 'ip' or 'none'/, 'bind header croaks');
    for my $b (qw(prefix ip none)) {
        ($pkg, $err) = build(secret => 'k', bind => $b);
        is($err, undef, "bind $b is accepted");
        is(opts_of($pkg)->{bind}, $b, "  and recorded");
    }
}

{
    my ($pkg, $err) = build(secret => 'k', prefix => 'challenge');
    like($err, qr/`prefix` must be a rooted path/, 'a prefix without a slash croaks');
    ($pkg, $err) = build(secret => 'k', prefix => '/c/');
    is($err, undef, 'a trailing slash is accepted');
    is(opts_of($pkg)->{prefix}, '/c', '  and dropped');
    ($pkg, $err) = build(secret => 'k', prefix => '/c?x');
    like($err, qr/`prefix` must be a rooted path/, 'a query in the prefix croaks');
    ($pkg, $err) = build(secret => 'k', prefix => [ '/c' ]);
    like($err, qr/`prefix` must be a string/, 'a reference croaks');
}

{
    my ($pkg, $err) = build(secret => 'k', cookie => '');
    like($err, qr/`cookie` must not be empty/, 'an empty cookie name croaks');
    ($pkg, $err) = build(secret => 'k', cookie => 'a=b');
    like($err, qr/`cookie` must be a cookie name/, 'a cookie name with = croaks');
    ($pkg, $err) = build(secret => 'k', cookie => 'clr');
    is($err, undef, 'a plain cookie name is accepted');
    is(opts_of($pkg)->{cookie}, 'clr', '  and recorded');
}

{
    my ($pkg, $err) = build(secret => 'k', exempt => '/health');
    like($err, qr/`exempt` must be a list/, 'exempt as a string croaks');
    ($pkg, $err) = build(secret => 'k', exempt => [ 'health' ]);
    like($err, qr/'health' is not a rooted path/, 'an unrooted exempt croaks');
    ($pkg, $err) = build(secret => 'k', exempt => [ '/health', '/static' ]);
    is($err, undef, 'rooted exempt paths are accepted');
    is_deeply(opts_of($pkg)->{exempt}, [ '/health', '/static' ], '  and recorded');
}

{
    my $cb = sub { 1 };
    my ($pkg, $err) = build(secret => 'k', render => $cb);
    is($err, undef, 'a render coderef is accepted');
    is(opts_of($pkg)->{render}, $cb, '  and recorded as itself');
    ($pkg, $err) = build(secret => 'k', render => 'my_page');
    is($err, undef, 'a render method name is accepted');
    is(opts_of($pkg)->{render}, 'my_page', '  and recorded');
    ($pkg, $err) = build(secret => 'k', render => '');
    like($err, qr/`render` must be a coderef or a method name/, 'an empty render croaks');
    ($pkg, $err) = build(secret => 'k', render => {});
    like($err, qr/`render` must be a coderef or a method name/, 'a hashref render croaks');
}

{
    my ($pkg, $err) = build(secret => 'k', assets => 0);
    is($err, undef, 'assets 0 is accepted');
    is(opts_of($pkg)->{assets}, 0, '  and recorded');
}

done_testing;
