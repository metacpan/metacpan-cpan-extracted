#!perl
use 5.014;
use strict;
use warnings;
use Test::More;

BEGIN {
    plan skip_all => "the ?-> operator requires perl 5.38+ (have $])"
        unless "$]" >= 5.038;
}

use Syntax::Infix::OptionalChain;

plan tests => 20;

{
    package Account;
    sub new     { my ($c, %a) = @_; bless { %a }, $c }
    sub name    { $_[0]{name} }
    sub profile { $_[0]{profile} }     # may return a plain hashref
    sub roles   { $_[0]{roles} }       # may return a plain arrayref
}

my $acct = Account->new(
    name    => 'ada',
    profile => { city => 'London', tags => [qw/math engines/] },
    roles   => [ 'admin', { kind => 'editor' } ],
);

# --- blessed object -> method call -----------------------------------------
is($acct ?-> name, 'ada', 'blessed object: bareword is a method call');

# --- HASH ref -> element; ARRAY ref -> element -----------------------------
my $href = { city => 'Paris' };
is($href ?-> city, 'Paris', 'HASH ref: bareword is a hash key');

my $aref = [ 'zero', 'one', 'two' ];
is($aref ?-> 0, 'zero', 'ARRAY ref: bareword integer is an index');
is($aref ?-> 2, 'two',  'ARRAY ref: another index');

# --- mixed chains: object -> hashref -> arrayref -> value ------------------
is($acct ?-> profile ?-> city, 'London',
    'object -> method -> hash key');
is($acct ?-> profile ?-> tags ?-> 1, 'engines',
    'object -> method -> hash key -> array index');
is($acct ?-> roles ?-> 1 ?-> kind, 'editor',
    'object -> method -> array index -> hash key');

# --- short-circuit on undef at any position --------------------------------
my $empty;
is($empty ?-> name, undef, 'undef at the head short-circuits');

my $acct2 = Account->new(name => 'grace');   # no profile, no roles
is($acct2 ?-> profile ?-> city, undef,
    'a missing link (undef method result) short-circuits the rest');
is($acct2 ?-> roles ?-> 0 ?-> kind, undef,
    'short-circuit through a missing array');

# --- combines with // for defaults -----------------------------------------
is($acct2 ?-> profile ?-> city // 'unknown', 'unknown',
    'missing chain falls back via //');
is($acct ?-> profile ?-> city // 'unknown', 'London',
    '// default not used when the value is present');

# --- absent key / out-of-range index are undef (natural), not errors -------
is($href ?-> nope, undef, 'absent hash key is undef');
is($aref ?-> 99, undef, 'out-of-range array index is undef');

is_deeply($href, { city => 'Paris' }); 

# --- navigating into a defined, un-navigable value is an error -------------
my $err = !eval { my $s = 'plain string'; $s ?-> whatever; 1 };
ok($err, 'navigating into a non-reference scalar croaks');
like($@, qr/cannot navigate/, '... with a clear message');

# --- a blessed object lacking the method falls through to structural access -
# Account is a blessed hashref, so a name with no matching method reads the
# underlying hash instead.
my $acct3 = Account->new(name => 'ada', _internal => 99);
is($acct3?->_internal, 99,
    'blessed object without a matching method falls through to hash access');
is($acct3 ?-> totally_absent, undef,
    '... and an absent key is undef (the method/key is optional too)');

# --- a blessed ref that is neither hash nor array, with no method, croaks ---
my $err2 = !eval { my $o = bless sub { }, 'Weird'; $o ?-> nope; 1 };
ok($err2, 'blessed non-hash/array without the method croaks');
