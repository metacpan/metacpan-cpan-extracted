#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use File::Temp ();
use Punk::Cache;

# The cache front's and the two shipped backends' refusals, by message: a
# budget that is not a size in every spelling, a memory tier in front of a
# store that is not shared, a tier ttl of nothing, a backend name that is not
# one, a backend that is missing or lacks the contract, keys that are undef,
# empty or too long, a compute without code or whose code dies; and the sizes
# that are accepted, from 512M to a plain byte count.

my $root = File::Temp->newdir;
sub refuses {
    my ($re, $name, $code) = @_;
    my $e = '';
    eval { $code->(); 1 } or $e = $@;
    like($e, $re, $name);
}

# ---- the backends' constructors --------------------------------------------------
refuses(qr/Punk::Cache::Memory: max_bytes must be greater than zero/, 'a memory store with no budget', sub { Punk::Cache::Memory->new(max_bytes => 0) });
refuses(qr/Punk::Cache::File: need a `dir`/, 'a file store with no directory', sub { Punk::Cache::File->new(max_bytes => 1024) });
refuses(qr/Punk::Cache::File: max_bytes must be greater than zero/, 'a file store with no budget', sub { Punk::Cache::File->new(dir => "$root/a", max_bytes => 0) });
refuses(qr/lock_wait must be a finite number of seconds, zero or more/, 'a negative lock wait', sub { Punk::Cache::File->new(dir => "$root/b", max_bytes => 1024, lock_wait => -1) });
refuses(qr/lock_wait must be a finite number/, 'an infinite lock wait', sub { Punk::Cache::File->new(dir => "$root/c", max_bytes => 1024, lock_wait => 9**9**9) });
SKIP: {
    skip 'root may write anywhere', 1 if $> == 0;
    mkdir "$root/ww" or die;
    chmod 0777, "$root/ww";
    refuses(qr/is world-writable; the cache directory must be private/, 'a world-writable directory', sub { Punk::Cache::File->new(dir => "$root/ww", max_bytes => 1024) });
    chmod 0700, "$root/ww";
}
refuses(qr/is too long a path|cannot create/, 'a path too long for the store', sub { Punk::Cache::File->new(dir => "$root/" . ('x' x 5000), max_bytes => 1024) });

# ---- the front's options -----------------------------------------------------------
refuses(qr/max_bytes 'abc' is not a size \(try 64M, 512M, 2G, or a plain byte count\)/, 'a budget that is not a size', sub { Punk::Cache->new(memory => max_bytes => 'abc') });
refuses(qr/max_bytes '1\.' is not a size/, 'a trailing dot is not a number', sub { Punk::Cache->new(memory => max_bytes => '1.') });
refuses(qr/max_bytes '' is not a size/, 'an empty budget', sub { Punk::Cache->new(memory => max_bytes => '') });
refuses(qr/max_bytes '10 M x' is not a size/, 'trailing rubbish after the unit', sub { Punk::Cache->new(memory => max_bytes => '10 M x') });
refuses(qr/memory 'zz' is not a size/, 'a tier size that is not one', sub { Punk::Cache->new(file => dir => "$root/t1", max_bytes => '1M', memory => 'zz') });
refuses(qr/memory_ttl must be greater than zero/, 'a tier ttl of nothing', sub { Punk::Cache->new(file => dir => "$root/t2", max_bytes => '1M', memory => '64K', memory_ttl => 0) });
refuses(qr/`memory` is a tier in front of a SHARED store/, 'a tier in front of the memory store is refused', sub { Punk::Cache->new(memory => max_bytes => '1M', memory => '64K') });
refuses(qr/'Bad Name' is not a usable backend name/, 'a backend name that is not one', sub { Punk::Cache->new('Bad Name' => max_bytes => '1M') });
refuses(qr/unknown backend 'nosuchbackend'/, 'a backend that is not installed', sub { Punk::Cache->new(nosuchbackend => max_bytes => '1M') });
{
    package Punk::Cache::Halfway;
    sub new { bless {}, shift }
    sub get { }
    package main;
}
refuses(qr/is not a usable backend - it must implement/, 'a backend missing part of the contract', sub { Punk::Cache->new(halfway => max_bytes => '1M') });
{
    package Punk::Cache::Nothing;
    sub new { return }
    sub get { } sub set { } sub delete { } sub clear { } sub stats { }
    package main;
}
refuses(qr/Punk::Cache::Nothing->new returned nothing usable/, 'a backend whose constructor returns nothing', sub { Punk::Cache->new(nothing => max_bytes => '1M') });

for my $size ('512M', '2G', '1.5K', '64MB', ' 10 k ', '4096', '1.25 g') {
    my $c = eval { Punk::Cache->new(memory => max_bytes => $size) };
    ok($c, "'$size' is a size") or diag $@;
}

# ---- keys and compute ----------------------------------------------------------------
my $c = Punk::Cache->new(memory => max_bytes => '1M');
refuses(qr/a key must be defined/, 'an undef key', sub { $c->get(undef) });
refuses(qr/a key must not be empty/, 'an empty key', sub { $c->set('', 'v', 60) });
refuses(qr/a key is limited to \d+ bytes/, 'a key past the limit', sub { $c->get('k' x 5000) });
refuses(qr/Punk::Cache::compute: need a code reference/, 'compute without code', sub { $c->compute('k', 60, 'not code') });
refuses(qr/compute boom/, 'compute whose code dies passes the error up', sub { $c->compute('dies', 60, sub { die "compute boom\n" }) });
ok(!defined $c->get('dies'), 'and stores nothing for it');
is($c->compute('k', 60, sub { 'made' }), 'made', 'compute fills a miss');
is($c->compute('k', 60, sub { 'again' }), 'made', 'and serves the hit');
refuses(qr/Punk::Cache: not a cache handle/, 'a method on something that is not a handle', sub { Punk::Cache::get(bless(\(my $x = 0), 'Punk::Cache'), 'k') });

done_testing;
