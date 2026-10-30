#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use Punk::Plugin::MCP ();

my $P = 'Punk::Plugin::MCP';

# ---- the two tables ---------------------------------------------------------

my $v = Punk::Plugin::MCP::_abi_versions();
cmp_ok($v->{frj}, '>=', 1, 'the frj table is resolved');
cmp_ok($v->{jsf}, '>=', 1, 'the jsf table is resolved');

# Driven through the function pointers, the way every later phase uses them.
my $t = Punk::Plugin::MCP::_abi_selftest();
is($t->{decoded_hash}, 1, 'frj decode gives a hash');
is($t->{json}, '{"a":"x","b":[1,2,3]}', 'frj encode round-trips, canonical');
is($t->{valid},   1, 'jsf passes a valid document');
is($t->{invalid}, 0, 'jsf fails an invalid one');
cmp_ok($t->{errors}, '>=', 1, 'and collects its errors');

# ---- the version gate ---------------------------------------------------------

my $frj = $File::Raw::JSON::VERSION;
my $jsf = $JSON::Schema::Fast::VERSION;

eval { Punk::Plugin::MCP::_abi_check('File::Raw::JSON', 0) };
like($@, qr/^Punk::MCP needs File::Raw::JSON 0\.08 or later for its C ABI 1, and found File::Raw::JSON \Q$frj\E with C ABI 0 /,
    'an old frj table croaks naming the provider, its version and the ABI');

eval { Punk::Plugin::MCP::_abi_check('JSON::Schema::Fast', 0) };
like($@, qr/^Punk::MCP needs JSON::Schema::Fast 0\.10 or later for its C ABI 1, and found JSON::Schema::Fast \Q$jsf\E with C ABI 0 /,
    'an old jsf table croaks the same way');

eval { Punk::Plugin::MCP::_abi_check('File::Raw::JSON', undef) };
like($@, qr/and File::Raw::JSON is unusable \(version \Q$frj\E\): faked by t\/02/,
    'a missing table croaks with the reason');

ok(Punk::Plugin::MCP::_abi_check('File::Raw::JSON', 1),  'ABI 1 passes');
ok(Punk::Plugin::MCP::_abi_check('File::Raw::JSON', 99),
    'a newer ABI passes, the gate is >= and not ==');

# ---- random ids ----------------------------------------------------------------

my %seen;
my $bad = 0;
for (1 .. 1000) {
    my $id = Punk::Plugin::MCP::_rand_id();
    # 16 bytes is 128 bits: the 22nd character carries 2 bits and 4 zero bits,
    # so it is one of 16 characters. Anything else is an encoder off by a bit.
    $bad++ unless $id =~ /\A[A-Za-z0-9_-]{21}[AQgw]\z/;
    $seen{$id}++;
}
is($bad, 0, 'every id is 22 base64url characters with a well-formed tail');
is(scalar keys %seen, 1000, '1000 ids are 1000 distinct values');

# ---- calls into Perl -------------------------------------------------------------

{
    package Probe;
    sub new  { bless {}, shift }
    sub echo { my (undef, @a) = @_; return "@a" }
    sub boom { die "probe died\n" }
}

my $obj = Probe->new;
is_deeply([Punk::Plugin::MCP::_call('echo', $obj, 0, 'a', 'b')], [1, 'a b'],
    'a method call gives its value');
is_deeply([Punk::Plugin::MCP::_call(sub { "got @_" }, undef, 0, 1, 2)],
    [1, 'got 1 2'], 'a code call gives its value');
is_deeply([Punk::Plugin::MCP::_call(sub { (1, 2, 3) }, undef, 1)],
    [1, [1, 2, 3]], 'list context gives an array ref');
is_deeply([Punk::Plugin::MCP::_call(sub { (1, 2, 3) }, undef, 0)],
    [1, 3], 'scalar context gives the last value, as Perl does');
is_deeply([Punk::Plugin::MCP::_call(sub { return }, undef, 0)],
    [1, undef], 'no value is undef');

my @r = Punk::Plugin::MCP::_call('boom', $obj, 0);
is_deeply(\@r, [0, "probe died\n"], 'a die is caught and handed back');
@r = Punk::Plugin::MCP::_call('no_such', $obj, 0);
is($r[0], 0, 'a missing method is caught too');
like($r[1], qr/Can't locate object method "no_such"/, 'with perl\'s reason');
is_deeply([Punk::Plugin::MCP::_call('echo', $obj, 0, 'after')], [1, 'after'],
    'and the stacks are whole after a caught die');

# A die with no G_EVAL propagates to the caller, and leaves things usable.
eval { Punk::Plugin::MCP::_call_plain(sub { die "plain\n" }) };
is($@, "plain\n", 'the plain call lets a die through');
is(Punk::Plugin::MCP::_call_plain(sub { "ok @_" }, 'x'), 'ok x',
    'and the plain call works after one');

# Growth: a result that reallocates the stack, and arguments that do. The
# XSUB must re-derive SP before it pushes, and pmcp_call must copy argv out
# of the stack before its EXTEND moves it.
@r = Punk::Plugin::MCP::_call(sub { (1 .. 100_000) }, undef, 1);
is($r[0], 1, 'a 100000-value result comes back');
is(scalar @{ $r[1] }, 100_000, 'whole');
is($r[1][-1], 100_000, 'in order');
is(scalar @r, 2, 'and the XSUB pushed exactly two values');

my @many = (1 .. 50_000);
@r = Punk::Plugin::MCP::_call(sub { my $s = 0; $s += $_ for @_; $s }, undef, 0, @many);
is_deeply(\@r, [1, 1_250_025_000], '50000 arguments arrive intact');
@r = Punk::Plugin::MCP::_call(sub { scalar @_ }, undef, 0, (1 .. 9));
is_deeply(\@r, [1, 9], 'nine arguments, past the inline buffer');

# The same growth in a fresh process, where the first reallocation happens.
{
    my @inc = map { "-I$_" } grep { !ref } @INC;
    my $code = 'use Punk::Plugin::MCP (); '
             . 'my @r = Punk::Plugin::MCP::_call(sub { (1 .. 200_000) }, undef, 1); '
             . 'print scalar(@r), " ", $r[0], " ", scalar(@{$r[1]}), " ", $r[1][-1];';
    open my $fh, '-|', $^X, @inc, '-e', $code or die "cannot run $^X: $!";
    my $out = do { local $/; <$fh> };
    close $fh;
    is($out, '2 1 200000 200000', 'the first reallocation, in a fresh process');
}

# ---- require -------------------------------------------------------------------

is_deeply([Punk::Plugin::MCP::_require('File::Spec')], [1, undef],
    'require loads a module');
@r = Punk::Plugin::MCP::_require('No::Such::Module::Here');
is($r[0], 0, 'require of a missing module fails');
like($r[1], qr{Can't locate No/Such/Module/Here\.pm}, 'with the reason');

# ---- closures ------------------------------------------------------------------

my $cv = Punk::Plugin::MCP::_closure('captured');
is(ref $cv, 'CODE', 'a closure is a code ref');
is($cv->(), 'captured', 'and returns its capture');

{
    package Witness;
    our $gone = 0;
    sub new     { bless {}, shift }
    sub DESTROY { $gone++ }
}
{
    my $w = Witness->new;
    my $c = Punk::Plugin::MCP::_closure($w);
    undef $w;
    is($Witness::gone, 0, 'the closure keeps its capture alive');
    is(ref $c->(), 'Witness', 'and hands it back');
    undef $c;
}
is($Witness::gone, 1, 'freeing the closure frees the capture');

# ---- croak_sv ------------------------------------------------------------------

eval { Punk::Plugin::MCP::_croak_sv("plain") };
like($@, qr/\Aplain at \S*02-abi\.t line \d+\.\n\z/,
    'a string without a newline gains the location');
eval { Punk::Plugin::MCP::_croak_sv("whole\n") };
is($@, "whole\n", 'a string with one is raised as is');
my $err = bless { code => 7 }, 'My::Error';
eval { Punk::Plugin::MCP::_croak_sv($err) };
is(ref $@, 'My::Error', 'a blessed exception stays blessed');
is($@, $err, 'and is the same object');

# ---- predicates ----------------------------------------------------------------

ok(Punk::Plugin::MCP::_is_array([]),  'an array ref is an array');
ok(!Punk::Plugin::MCP::_is_array({}), 'a hash ref is not');
ok(!Punk::Plugin::MCP::_is_array(undef), 'nor is undef');

done_testing;
